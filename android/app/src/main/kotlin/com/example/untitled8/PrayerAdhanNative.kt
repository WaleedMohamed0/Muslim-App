package com.example.untitled8

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

internal object PrayerAdhanStorage {
    const val PREFS = "prayer_adhan_native"
    const val ALARMS = "alarms_json"
    const val ENABLED = "enabled"
    const val VOLUME = "volume"
    const val AUDIO_ID = "audio_id"
    const val CHANNEL_PLAYBACK = "adhan_playback"
    const val CHANNEL_REMINDER = "adhan_reminder"
}

internal object PrayerAlarmScheduler {
    private const val ACTION_ALARM = "com.example.untitled8.PRAYER_ALARM"

    fun canScheduleExactAlarms(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return false
        return alarmManager.canScheduleExactAlarms()
    }

    fun replaceSchedule(context: Context, alarms: JSONArray) {
        cancelScheduled(context)
        context.getSharedPreferences(PrayerAdhanStorage.PREFS, Context.MODE_PRIVATE)
            .edit().putString(PrayerAdhanStorage.ALARMS, alarms.toString()).apply()
        restore(context, reinterpretLocalTimes = false)
    }

    fun restore(context: Context, reinterpretLocalTimes: Boolean) {
        val prefs = context.getSharedPreferences(PrayerAdhanStorage.PREFS, Context.MODE_PRIVATE)
        val alarms = try {
            JSONArray(prefs.getString(PrayerAdhanStorage.ALARMS, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        cancelScheduled(context, alarms)
        if (!prefs.getBoolean(PrayerAdhanStorage.ENABLED, false)) return

        val now = System.currentTimeMillis()
        for (index in 0 until alarms.length()) {
            val item = alarms.optJSONObject(index) ?: continue
            val prayer = item.optString("prayer")
            if (!prefs.getBoolean("prayer_$prayer", true)) continue
            val at = if (reinterpretLocalTimes) localWallTime(item) else item.optLong("at")
            if (at <= now) continue
            scheduleOne(context, item, at, canScheduleExactAlarms(context))
        }
    }

    private fun localWallTime(item: JSONObject): Long {
        val calendar = Calendar.getInstance().apply {
            clear()
            set(Calendar.YEAR, item.optInt("year"))
            set(Calendar.MONTH, item.optInt("month") - 1)
            set(Calendar.DAY_OF_MONTH, item.optInt("day"))
            set(Calendar.HOUR_OF_DAY, item.optInt("hour"))
            set(Calendar.MINUTE, item.optInt("minute"))
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return calendar.timeInMillis
    }

    private fun scheduleOne(context: Context, item: JSONObject, at: Long, exact: Boolean) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val id = item.optString("id")
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = ACTION_ALARM
            data = Uri.parse("muslimadhan://prayer/$id")
            putExtra("id", id)
            putExtra("prayer", item.optString("prayer"))
            putExtra("exact", exact)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        try {
            if (exact) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            }
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        }
    }

    private fun cancelScheduled(context: Context) {
        val prefs = context.getSharedPreferences(PrayerAdhanStorage.PREFS, Context.MODE_PRIVATE)
        val alarms = try {
            JSONArray(prefs.getString(PrayerAdhanStorage.ALARMS, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        cancelScheduled(context, alarms)
    }

    private fun cancelScheduled(context: Context, alarms: JSONArray) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        for (index in 0 until alarms.length()) {
            val item = alarms.optJSONObject(index) ?: continue
            val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                action = ACTION_ALARM
                data = Uri.parse("muslimadhan://prayer/${item.optString("id")}")
            }
            val pending = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            ) ?: continue
            alarmManager.cancel(pending)
            pending.cancel()
        }
    }
}

class PrayerAlarmRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val reinterpret = intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED
        PrayerAlarmScheduler.restore(context, reinterpretLocalTimes = reinterpret)
    }
}

class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(PrayerAdhanStorage.PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(PrayerAdhanStorage.ENABLED, false)) return
        val prayer = intent.getStringExtra("prayer") ?: return
        if (!prefs.getBoolean("prayer_$prayer", true)) return

        val id = intent.getStringExtra("id") ?: return
        val lastId = prefs.getString("last_alarm_id", null)
        val lastAt = prefs.getLong("last_alarm_at", 0L)
        if (lastId == id && System.currentTimeMillis() - lastAt < 120_000L) return
        prefs.edit()
            .putString("last_alarm_id", id)
            .putLong("last_alarm_at", System.currentTimeMillis())
            .apply()

        if (!intent.getBooleanExtra("exact", false) ||
            !PrayerAlarmScheduler.canScheduleExactAlarms(context)
        ) {
            showInexactReminder(context, prayer)
            return
        }

        val serviceIntent = Intent(context, PrayerAdhanPlaybackService::class.java).apply {
            action = PrayerAdhanPlaybackService.ACTION_PLAY
            putExtra("prayer", prayer)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (_: Exception) {
            showInexactReminder(context, prayer)
        }
    }

    private fun showInexactReminder(context: Context, prayer: String) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    PrayerAdhanStorage.CHANNEL_REMINDER,
                    "تنبيهات مواقيت الصلاة",
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
        }
        val notification = NotificationCompat.Builder(context, PrayerAdhanStorage.CHANNEL_REMINDER)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle("حان وقت الصلاة")
            .setContentText("حان وقت صلاة $prayer")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        manager.notify(("reminder_$prayer").hashCode(), notification)
    }
}

class PrayerAdhanPlaybackService : Service() {
    private var player: MediaPlayer? = null
    private var focusRequest: AudioFocusRequest? = null
    private var audioManager: AudioManager? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createPlaybackChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopPlayback()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf(startId)
            }
            ACTION_TEST, ACTION_PLAY -> {
                val prayer = intent.getStringExtra("prayer") ?: ""
                val prefs = getSharedPreferences(PrayerAdhanStorage.PREFS, MODE_PRIVATE)
                if (intent.action == ACTION_PLAY &&
                    (!prefs.getBoolean(PrayerAdhanStorage.ENABLED, false) ||
                        !prefs.getBoolean("prayer_$prayer", true))
                ) {
                    stopSelf(startId)
                    return START_NOT_STICKY
                }
                startForeground(NOTIFICATION_ID, buildPlaybackNotification(prayer))
                val audioId = if (intent.action == ACTION_TEST) {
                    intent.getStringExtra("audio_id")
                } else {
                    null
                }
                playLocalAdhan(prefs.getFloat(PrayerAdhanStorage.VOLUME, .85f), audioId)
            }
            else -> stopSelf(startId)
        }
        return START_NOT_STICKY
    }

    private fun playLocalAdhan(volume: Float, previewAudioId: String? = null) {
        stopPlayer()
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        requestAudioFocus(attributes)
        try {
            player = MediaPlayer().apply {
                setAudioAttributes(attributes)
                setVolume(volume.coerceIn(0f, 1f), volume.coerceIn(0f, 1f))
                val prefs = getSharedPreferences(PrayerAdhanStorage.PREFS, MODE_PRIVATE)
                val audioId = previewAudioId
                    ?: prefs.getString(PrayerAdhanStorage.AUDIO_ID, "adhan_madinah")
                    ?: "adhan_madinah"
                val resourceId = resources.getIdentifier(audioId, "raw", packageName)
                    .takeIf { it != 0 } ?: R.raw.adhan_madinah
                resources.openRawResourceFd(resourceId).use { descriptor ->
                    setDataSource(
                        descriptor.fileDescriptor,
                        descriptor.startOffset,
                        descriptor.length,
                    )
                }
                setOnPreparedListener { it.start() }
                setOnCompletionListener {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
                setOnErrorListener { _, _, _ ->
                    stopPlayback()
                    true
                }
                prepareAsync()
            }
        } catch (_: Exception) {
            stopPlayback()
        }
    }

    private fun requestAudioFocus(attributes: AudioAttributes) {
        audioManager = getSystemService(AudioManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attributes)
                .setOnAudioFocusChangeListener { }
                .build()
            focusRequest = request
            audioManager?.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN)
        }
    }

    private fun stopPlayer() {
        try {
            player?.stop()
        } catch (_: Exception) {
        }
        player?.release()
        player = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
        }
    }

    private fun stopPlayback() {
        stopPlayer()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createPlaybackChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel(
                PrayerAdhanStorage.CHANNEL_PLAYBACK,
                "تشغيل الأذان",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { setSound(null, null) },
        )
    }

    private fun buildPlaybackNotification(prayer: String): Notification {
        val stopIntent = Intent(this, PrayerAdhanPlaybackService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            7302,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = NotificationCompat.Builder(this, PrayerAdhanStorage.CHANNEL_PLAYBACK)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(if (prayer.isBlank()) "اختبار الأذان" else "أذان صلاة $prayer")
            .setContentText("جارٍ تشغيل الأذان من الملف المحفوظ على الجهاز")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(0, "إيقاف", stopPendingIntent)
        return builder.build()
    }

    override fun onDestroy() {
        stopPlayer()
        super.onDestroy()
    }

    companion object {
        const val ACTION_PLAY = "com.example.untitled8.PLAY_ADHAN"
        const val ACTION_TEST = "com.example.untitled8.TEST_ADHAN"
        const val ACTION_STOP = "com.example.untitled8.STOP_ADHAN"
        private const val NOTIFICATION_ID = 7301
    }
}
