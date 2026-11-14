package com.example.muslim

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

private object AdhanTiming {
    private const val TAG = "AdhanTiming"

    fun log(stage: String, scheduledAt: Long = 0L) {
        val now = System.currentTimeMillis()
        val scheduled = if (scheduledAt > 0L) " scheduledAt=$scheduledAt deltaMs=${now - scheduledAt}" else ""
        Log.i(TAG, "$stage at=$now elapsedRealtime=${android.os.SystemClock.elapsedRealtime()}$scheduled")
    }

    fun failure(stage: String, error: Throwable, scheduledAt: Long = 0L) {
        val now = System.currentTimeMillis()
        val scheduled = if (scheduledAt > 0L) " scheduledAt=$scheduledAt deltaMs=${now - scheduledAt}" else ""
        Log.e(TAG, "$stage at=$now elapsedRealtime=${android.os.SystemClock.elapsedRealtime()}$scheduled error=${error.javaClass.simpleName}: ${error.message}", error)
    }
}

internal object PrayerAdhanStorage {
    const val PREFS = "prayer_adhan_native"
    const val ALARMS = "alarms_json"
    const val ENABLED = "enabled"
    const val VOLUME = "volume"
    const val AUDIO_ID = "audio_id"
    const val CHANNEL_PLAYBACK = "adhan_playback"
    const val CHANNEL_ALERT = "adhan_prayer_alert"
    const val CHANNEL_CALL_REMINDER = "adhan_call_reminder"
}

/** Converts the stable prayer identifiers used by scheduling into Arabic labels. */
private fun prayerNameArabic(prayer: String): String = when (prayer.lowercase()) {
    "fajr" -> "الفجر"
    "dhuhr" -> "الظهر"
    "asr" -> "العصر"
    "maghrib" -> "المغرب"
    "isha" -> "العشاء"
    else -> prayer
}

private fun elAzanPendingIntent(context: Context, prayer: String): PendingIntent {
    val launchIntent = Intent(context, MainActivity::class.java).apply {
        action = "com.example.muslim.OPEN_ELAZAN_SCREEN"
        putExtra("notification_route", "elazan_screen")
        putExtra("prayer", prayer)
        addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )
    }
    return PendingIntent.getActivity(
        context,
        "open_elazan_${prayer.lowercase()}".hashCode(),
        launchIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

/** Daily Azkar and Wird reminders share the existing local AlarmManager setup. */
internal object DailyAzkarReminderScheduler {
    private const val PREFS = "daily_azkar_reminders"
    private const val SETTINGS = "settings_json"
    private const val ACTION_REMINDER = "com.example.muslim.DAILY_REMINDER"
    // Use a new channel id so installs that already created the old default-
    // importance channel receive the updated heads-up alert behavior.
    private const val CHANNEL = "daily_azkar_reminders_alerts"

    private data class Reminder(
        val id: String,
        val route: String,
        val title: String,
        val message: String,
        val hour: Int,
        val minute: Int,
        val enabled: Boolean,
    )

    fun getSettings(context: Context): List<Map<String, Any>> {
        restore(context)
        return readReminders(context).map { reminder ->
            mapOf(
                "id" to reminder.id,
                "route" to reminder.route,
                "title" to reminder.title,
                "message" to reminder.message,
                "hour" to reminder.hour,
                "minute" to reminder.minute,
                "enabled" to reminder.enabled,
                "scheduled" to isScheduled(context, reminder),
            )
        }
    }

    fun save(context: Context, values: List<*>) {
        cancelAll(context)
        val array = JSONArray()
        values.forEach { raw ->
            val item = raw as? Map<*, *> ?: return@forEach
            val json = JSONObject()
            item.forEach { (key, value) ->
                if (key != null && value != null) json.put(key.toString(), value)
            }
            array.put(json)
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(SETTINGS, array.toString())
            .apply()
        restore(context)
    }

    fun restore(context: Context) {
        readReminders(context).forEach { reminder ->
            cancel(context, reminder.id)
            if (reminder.enabled) scheduleNext(context, reminder)
        }
    }

    fun deliver(context: Context, id: String) {
        val reminder = readReminders(context).firstOrNull { it.id == id } ?: return
        if (!reminder.enabled) return
        showNotification(context, reminder)
        scheduleNext(context, reminder)
    }

    private fun readReminders(context: Context): List<Reminder> {
        val defaults = JSONArray()
            .put(reminderJson("morning", "azkar_morning", "أذكار الصباح", "صباح الخير 🌿 حان وقت أذكار الصباح، ابدأ يومك بذكر الله.", 7, 0))
            .put(reminderJson("evening", "azkar_evening", "أذكار المساء", "لا تنسَ أذكار المساء، حصّن يومك بذكر الله.", 17, 0))
            .put(reminderJson("daily_wird", "daily_wird", "وردك اليومي", "حان وقت وردك اليومي، اجعل لنفسك نصيبًا من القرآن والذكر.", 21, 0))
            .put(reminderJson("salawat_morning", "salawat", "الصلاة على النبي ﷺ", "لا تنسَ الصلاة على النبي ﷺ ❤️", 10, 0, true))
            .put(reminderJson("salawat_evening", "salawat", "الصلاة على النبي ﷺ", "اجعل لسانك رطبًا بالصلاة على النبي ﷺ.", 18, 0, true))
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(SETTINGS, defaults.toString()) ?: defaults.toString()
        return try {
            val array = JSONArray(raw)
            val reminders = (0 until array.length()).mapNotNull { index ->
                val json = array.optJSONObject(index) ?: return@mapNotNull null
                val id = json.optString("id")
                if (id.isBlank()) return@mapNotNull null
                Reminder(
                    id = id,
                    route = json.optString("route", "daily_wird"),
                    title = json.optString("title", "تذكير يومي"),
                    message = json.optString("message", "حان وقت وردك اليومي."),
                    hour = json.optInt("hour", 9).coerceIn(0, 23),
                    minute = json.optInt("minute", 0).coerceIn(0, 59),
                    enabled = json.optBoolean("enabled", false),
                )
            }.toMutableList()
            val knownIds = reminders.map { it.id }.toSet()
            listOf(
                reminderJson("salawat_morning", "salawat", "الصلاة على النبي ﷺ", "لا تنسَ الصلاة على النبي ﷺ ❤️", 10, 0, true),
                reminderJson("salawat_evening", "salawat", "الصلاة على النبي ﷺ", "اجعل لسانك رطبًا بالصلاة على النبي ﷺ.", 18, 0, true),
            ).forEach { json ->
                val id = json.optString("id")
                if (id !in knownIds) reminders.add(
                    Reminder(id, json.optString("route"), json.optString("title"), json.optString("message"), json.optInt("hour"), json.optInt("minute"), json.optBoolean("enabled")),
                )
            }
            reminders
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun reminderJson(
        id: String,
        route: String,
        title: String,
        message: String,
        hour: Int,
        minute: Int,
        enabled: Boolean = false,
    ) = JSONObject()
        .put("id", id)
        .put("route", route)
        .put("title", title)
        .put("message", message)
        .put("hour", hour)
        .put("minute", minute)
        .put("enabled", enabled)

    private fun scheduleNext(context: Context, reminder: Reminder) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val now = Calendar.getInstance()
        val trigger = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, reminder.hour)
            set(Calendar.MINUTE, reminder.minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (!after(now)) add(Calendar.DAY_OF_YEAR, 1)
        }
        val pending = alarmIntent(context, reminder.id, PendingIntent.FLAG_UPDATE_CURRENT)
            ?: return
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    trigger.timeInMillis,
                    pending,
                )
            } else {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    trigger.timeInMillis,
                    pending,
                )
            }
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                trigger.timeInMillis,
                pending,
            )
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putLong("scheduled_${reminder.id}", trigger.timeInMillis).apply()
    }

    private fun isScheduled(context: Context, reminder: Reminder): Boolean {
        if (!reminder.enabled) return false
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val nextAt = prefs.getLong("scheduled_${reminder.id}", 0L)
        return nextAt > System.currentTimeMillis() &&
            alarmIntent(context, reminder.id, PendingIntent.FLAG_NO_CREATE) != null
    }

    private fun cancelAll(context: Context) {
        readReminders(context).forEach { cancel(context, it.id) }
    }

    private fun cancel(context: Context, id: String) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val pending = alarmIntent(context, id, PendingIntent.FLAG_NO_CREATE) ?: return
        alarmManager.cancel(pending)
        pending.cancel()
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove("scheduled_$id").apply()
    }

    private fun alarmIntent(context: Context, id: String, flag: Int): PendingIntent? {
        val intent = Intent(context, DailyAzkarReminderReceiver::class.java).apply {
            action = ACTION_REMINDER
            data = Uri.parse("muslimapp://daily-reminder/$id")
            putExtra("reminder_id", id)
        }
        val flags = if (flag == PendingIntent.FLAG_NO_CREATE) {
            flag or PendingIntent.FLAG_IMMUTABLE
        } else {
            flag or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getBroadcast(context, id.hashCode(), intent, flags)
    }

    private fun showNotification(context: Context, reminder: Reminder) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL,
                    "تذكيرات الأذكار والورد",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "تنبيهات بارزة لتذكيرات الأذكار والورد"
                    setShowBadge(false)
                },
            )
        }
        val openIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.example.muslim.OPEN_DAILY_REMINDER"
            data = Uri.parse("muslimapp://notification/${reminder.id}")
            // Older saved reminder settings may contain a stale/missing route.
            // The reminder id is stable and unambiguously identifies the page.
            putExtra(
                "notification_route",
                when (reminder.id) {
                    "morning" -> "azkar_morning"
                    "evening" -> "azkar_evening"
                    "daily_wird" -> "daily_wird"
                    "salawat_morning", "salawat_evening" -> "salawat"
                    else -> reminder.route
                },
            )
            // Reuse the running activity when possible so onNewIntent can
            // route the tap. On a cold start Android creates MainActivity
            // with this same intent and Flutter consumes it at startup.
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        val contentIntent = PendingIntent.getActivity(
            context,
            ("route_${reminder.id}").hashCode(),
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val salawatMessages = listOf(
            "لا تنسَ الصلاة على النبي ﷺ ❤️",
            "اجعل لسانك رطبًا بالصلاة على النبي ﷺ.",
            "اللهم صلِّ وسلم على نبينا محمد ﷺ.",
            "أكثروا من الصلاة على النبي ﷺ.",
            "دقيقة من وقتك، صلِّ فيها على النبي ﷺ.",
        )
        val message = if (reminder.route == "salawat") {
            val day = Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
            salawatMessages[(day + reminder.id.hashCode().ushr(1)) % salawatMessages.size]
        } else reminder.message
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(reminder.title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setContentIntent(contentIntent)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .build()
        try {
            manager.notify(reminder.id.hashCode(), notification)
        } catch (_: SecurityException) {
            // Notifications may be disabled in system settings.
        }
    }
}

class DailyAzkarReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("reminder_id") ?: return
        DailyAzkarReminderScheduler.deliver(context, id)
    }
}

internal object PrayerAlarmScheduler {
    private const val ACTION_ALARM = "com.example.muslim.PRAYER_ALARM"

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
            // Prayer alerts need exact delivery during Doze without presenting
            // themselves as a system alarm clock to the user.
            if (canScheduleExactAlarms(context)) scheduleOne(context, item, at)
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

    private fun scheduleOne(context: Context, item: JSONObject, at: Long) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val id = item.optString("id")
        fun alarmPendingIntent(): PendingIntent {
            val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                action = ACTION_ALARM
                data = Uri.parse("muslimadhan://prayer/$id")
                putExtra("id", id)
                putExtra("prayer", item.optString("prayer"))
                putExtra("exact", true)
                putExtra("scheduled_at", at)
            }
            return PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
        try {
            AdhanTiming.log("alarm_schedule prayer=${item.optString("prayer")}", at)
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                at,
                alarmPendingIntent(),
            )
        } catch (_: SecurityException) {
            // Exact access may have been revoked between the permission check
            // and scheduling. Do not silently degrade to a delayed alarm.
        }
    }

    fun rescheduleEarly(context: Context, intent: Intent, prayer: String, at: Long) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        if (!canScheduleExactAlarms(context)) return
        val pending = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        try {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                at,
                pending,
            )
        } catch (_: SecurityException) {
            // Permission can be revoked after the check; never fire early.
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
        DailyAzkarReminderScheduler.restore(context)
    }
}

class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val scheduledAt = intent.getLongExtra("scheduled_at", 0L)
        AdhanTiming.log("receiver_onReceive prayer=${intent.getStringExtra("prayer")}", scheduledAt)
        val prefs = context.getSharedPreferences(PrayerAdhanStorage.PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(PrayerAdhanStorage.ENABLED, false)) {
            AdhanTiming.log("receiver_skip reason=adhan_disabled", scheduledAt)
            return
        }
        val prayer = intent.getStringExtra("prayer") ?: run {
            AdhanTiming.log("receiver_skip reason=missing_prayer", scheduledAt)
            return
        }
        if (!prefs.getBoolean("prayer_$prayer", true)) {
            AdhanTiming.log("receiver_skip prayer=$prayer reason=prayer_disabled", scheduledAt)
            return
        }

        val id = intent.getStringExtra("id") ?: run {
            AdhanTiming.log("receiver_skip prayer=$prayer reason=missing_alarm_id", scheduledAt)
            return
        }
        if (scheduledAt > 0L && System.currentTimeMillis() < scheduledAt) {
            AdhanTiming.log("receiver_reschedule_early prayer=$prayer", scheduledAt)
            PrayerAlarmScheduler.rescheduleEarly(context, intent, prayer, scheduledAt)
            return
        }
        val lastId = prefs.getString("last_alarm_id", null)
        val lastAt = prefs.getLong("last_alarm_at", 0L)
        val lastScheduledAt = prefs.getLong("last_alarm_scheduled_at", 0L)
        val sameScheduledDelivery = scheduledAt > 0L && lastScheduledAt == scheduledAt
        if (lastId == id && sameScheduledDelivery &&
            System.currentTimeMillis() - lastAt < 120_000L
        ) {
            AdhanTiming.log("receiver_skip prayer=$prayer reason=duplicate id=$id", scheduledAt)
            return
        }

        if (isPhoneCallActive(context)) {
            markAlarmHandled(prefs, id, scheduledAt)
            AdhanTiming.log("receiver_call_active prayer=$prayer", scheduledAt)
            showCallReminder(context, prayer)
            return
        }

        if (!intent.getBooleanExtra("exact", false)) {
            markAlarmHandled(prefs, id, scheduledAt)
            AdhanTiming.log("receiver_non_exact prayer=$prayer", scheduledAt)
            showPrayerAlert(context, prayer, exact = false)
            return
        }

        val serviceIntent = Intent(context, PrayerAdhanPlaybackService::class.java).apply {
            action = PrayerAdhanPlaybackService.ACTION_PLAY
            putExtra("prayer", prayer)
            putExtra("scheduled_at", scheduledAt)
            putExtra("alarm_id", id)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            markAlarmHandled(prefs, id, scheduledAt)
            AdhanTiming.log("receiver_service_start_requested prayer=$prayer id=$id", scheduledAt)
        } catch (error: Exception) {
            AdhanTiming.failure("receiver_service_start_failed prayer=$prayer id=$id", error, scheduledAt)
            showPrayerAlert(context, prayer, exact = false)
        }
    }

    private fun markAlarmHandled(
        prefs: android.content.SharedPreferences,
        id: String,
        scheduledAt: Long,
    ) {
        prefs.edit()
            .putString("last_alarm_id", id)
            .putLong("last_alarm_at", System.currentTimeMillis())
            .putLong("last_alarm_scheduled_at", scheduledAt)
            .apply()
    }

    private fun showPrayerAlert(context: Context, prayer: String, exact: Boolean) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    PrayerAdhanStorage.CHANNEL_ALERT,
                    "تنبيهات الأذان",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "تنبيه بارز عند دخول وقت الصلاة"
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                },
            )
        }
        val message = if (exact) {
            "حان وقت الصلاة"
        } else {
            "حان وقت الصلاة. يلزم السماح بالمنبهات الدقيقة لتشغيل الأذان صوتيًا."
        }
        val notification = NotificationCompat.Builder(context, PrayerAdhanStorage.CHANNEL_ALERT)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle("أذان صلاة ${prayerNameArabic(prayer)}")
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setContentIntent(elAzanPendingIntent(context, prayer))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setSilent(true)
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(("prayer_alert_$prayer").hashCode(), notification)
        } catch (_: SecurityException) {
            // Notification permission can be denied independently of alarm access.
        }
    }

    private fun showCallReminder(context: Context, prayer: String) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    PrayerAdhanStorage.CHANNEL_CALL_REMINDER,
                    "تنبيهات الصلاة أثناء المكالمات",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                },
            )
        }
        val notification = NotificationCompat.Builder(context, PrayerAdhanStorage.CHANNEL_CALL_REMINDER)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle("أذان صلاة ${prayerNameArabic(prayer)}")
            .setContentIntent(elAzanPendingIntent(context, prayer))
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .setVibrate(null)
            .setSound(null)
            .setAutoCancel(true)
            .build()
        manager.notify(("call_reminder_$prayer").hashCode(), notification)
    }

    private fun isPhoneCallActive(context: Context): Boolean {
        val mode = context.getSystemService(AudioManager::class.java)?.mode
        // Android exposes telephony and VoIP calls through these audio modes,
        // so detecting calls does not require READ_PHONE_STATE.
        return mode == AudioManager.MODE_RINGTONE ||
            mode == AudioManager.MODE_IN_CALL ||
            mode == AudioManager.MODE_IN_COMMUNICATION
    }
}

class PrayerAdhanPlaybackService : Service() {
    private var player: MediaPlayer? = null
    private var screenWakeLock: PowerManager.WakeLock? = null
    private var focusRequest: AudioFocusRequest? = null
    private var audioManager: AudioManager? = null
    private var alarmVolumeObserver: ContentObserver? = null
    private var observedStreamVolumes: Map<Int, Int>? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        AdhanTiming.log("service_onCreate")
        serviceInstance = this
        createPlaybackChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val scheduledAt = intent?.getLongExtra("scheduled_at", 0L) ?: 0L
        AdhanTiming.log("service_onStartCommand action=${intent?.action} startId=$startId flags=$flags", scheduledAt)
        when (intent?.action) {
            ACTION_STOP -> {
                stopPlayback()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf(startId)
            }
            ACTION_TEST, ACTION_PLAY -> {
                val prayer = intent.getStringExtra("prayer") ?: ""
                val scheduledAt = intent.getLongExtra("scheduled_at", 0L)
                val alarmId = intent.getStringExtra("alarm_id")
                val prefs = getSharedPreferences(PrayerAdhanStorage.PREFS, MODE_PRIVATE)
                if (intent.action == ACTION_PLAY &&
                    (!prefs.getBoolean(PrayerAdhanStorage.ENABLED, false) ||
                        !prefs.getBoolean("prayer_$prayer", true))
                ) {
                    AdhanTiming.log("service_skip prayer=$prayer reason=settings_disabled startId=$startId", scheduledAt)
                    clearAlarmDedup(alarmId)
                    stopSelf(startId)
                    return START_NOT_STICKY
                }
                try {
                    startForeground(notificationId(prayer), buildPlaybackNotification(prayer))
                    AdhanTiming.log("service_foreground_started prayer=$prayer startId=$startId", scheduledAt)
                } catch (error: Exception) {
                    AdhanTiming.failure("service_foreground_start_failed prayer=$prayer startId=$startId", error, scheduledAt)
                    clearAlarmDedup(alarmId)
                    stopSelf(startId)
                    return START_NOT_STICKY
                }
                val audioId = if (intent.action == ACTION_TEST) {
                    intent.getStringExtra("audio_id")
                } else {
                    null
                }
                val scheduledPrayer = prayer.takeIf { intent.action == ACTION_PLAY }
                playLocalAdhan(
                    prefs.getFloat(PrayerAdhanStorage.VOLUME, .85f),
                    audioId,
                    scheduledPrayer,
                    scheduledAt,
                    alarmId,
                )
            }
            else -> stopSelf(startId)
        }
        return START_NOT_STICKY
    }

    private fun playLocalAdhan(
        volume: Float,
        previewAudioId: String? = null,
        scheduledPrayer: String? = null,
        scheduledAt: Long = 0L,
        alarmId: String? = null,
    ) {
        stopPlayer()
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        try {
            val focusResult = requestAudioFocus(attributes)
            AdhanTiming.log("audio_focus_request prayer=${scheduledPrayer ?: "preview"} result=$focusResult", scheduledAt)
            val prefs = getSharedPreferences(PrayerAdhanStorage.PREFS, MODE_PRIVATE)
            val audioId = previewAudioId
                ?: prefs.getString(PrayerAdhanStorage.AUDIO_ID, "adhan_madinah")
                ?: "adhan_madinah"
            val lookedUpResourceId = resources.getIdentifier(audioId, "raw", packageName)
            if (lookedUpResourceId == 0) {
                throw IllegalStateException("No bundled Adhan resource for audioId=$audioId")
            }
            val resourceId = lookedUpResourceId
            AdhanTiming.log("mediaPlayer_initialize prayer=${scheduledPrayer ?: "preview"} audioId=$audioId resourceId=$resourceId volume=$volume", scheduledAt)
            player = MediaPlayer().apply {
                setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                setAudioAttributes(attributes)
                setVolume(volume.coerceIn(0f, 1f), volume.coerceIn(0f, 1f))
                resources.openRawResourceFd(resourceId).use { descriptor ->
                    setDataSource(
                        descriptor.fileDescriptor,
                        descriptor.startOffset,
                        descriptor.length,
                    )
                }
                setOnPreparedListener { preparedPlayer ->
                    AdhanTiming.log("mediaPlayer_onPrepared prayer=${scheduledPrayer ?: "preview"} current=${preparedPlayer === player}", scheduledAt)
                    if (preparedPlayer !== player) {
                        AdhanTiming.log("mediaPlayer_prepared_stale_callback prayer=${scheduledPrayer ?: "preview"}", scheduledAt)
                        return@setOnPreparedListener
                    }
                    try {
                        preparedPlayer.start()
                        val alarmVolume = audioManager?.getStreamVolume(AudioManager.STREAM_ALARM) ?: 1
                        val isPlaying = preparedPlayer.isPlaying
                        AdhanTiming.log("mediaPlayer_started prayer=${scheduledPrayer ?: "preview"} isPlaying=$isPlaying alarmVolume=$alarmVolume", scheduledAt)
                        registerAlarmVolumeObserver(alarmVolume)
                        if (scheduledPrayer != null && volume > 0f && alarmVolume > 0 && isPlaying) {
                            wakeScreenForAdhan()
                        }
                        activePrayer = scheduledPrayer?.takeIf { volume > 0f && alarmVolume > 0 && isPlaying }
                    } catch (error: Exception) {
                        AdhanTiming.failure("mediaPlayer_start_failed prayer=${scheduledPrayer ?: "preview"}", error, scheduledAt)
                        clearAlarmDedup(alarmId)
                        stopPlayback()
                    }
                }
                setOnCompletionListener {
                    AdhanTiming.log("mediaPlayer_completed prayer=${scheduledPrayer ?: "preview"}", scheduledAt)
                    activePrayer = null
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
                setOnErrorListener { _, what, extra ->
                    AdhanTiming.failure("mediaPlayer_error prayer=${scheduledPrayer ?: "preview"} what=$what extra=$extra", IllegalStateException("MediaPlayer error what=$what extra=$extra"), scheduledAt)
                    clearAlarmDedup(alarmId)
                    stopPlayback()
                    true
                }
                AdhanTiming.log("mediaPlayer_prepareAsync prayer=${scheduledPrayer ?: "preview"}", scheduledAt)
                prepareAsync()
            }
        } catch (error: Exception) {
            AdhanTiming.failure("mediaPlayer_setup_failed prayer=${scheduledPrayer ?: "preview"}", error, scheduledAt)
            clearAlarmDedup(alarmId)
            stopPlayback()
        }
    }

    private fun clearAlarmDedup(alarmId: String?) {
        if (alarmId.isNullOrBlank()) return
        val prefs = getSharedPreferences(PrayerAdhanStorage.PREFS, MODE_PRIVATE)
        if (prefs.getString("last_alarm_id", null) == alarmId) {
            prefs.edit()
                .remove("last_alarm_id")
                .remove("last_alarm_at")
                .remove("last_alarm_scheduled_at")
                .apply()
            AdhanTiming.log("alarm_dedup_cleared id=$alarmId")
        }
    }

    /** Briefly wakes the display for the lock screen when scheduled Adhan starts. */
    @Suppress("DEPRECATION")
    private fun wakeScreenForAdhan() {
        releaseScreenWakeLock()
        val powerManager = getSystemService(PowerManager::class.java) ?: return
        val wakeLock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
            "MuslimApp:AdhanScreenWake",
        )
        screenWakeLock = wakeLock
        // The timeout bounds the screen-on request even if the service is interrupted.
        runCatching { wakeLock.acquire(5_000L) }
            .onFailure { screenWakeLock = null }
    }

    private fun releaseScreenWakeLock() {
        screenWakeLock?.let { wakeLock ->
            if (wakeLock.isHeld) wakeLock.release()
        }
        screenWakeLock = null
    }

    private fun requestAudioFocus(attributes: AudioAttributes): Int {
        audioManager = getSystemService(AudioManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attributes)
                .setOnAudioFocusChangeListener { change ->
                    AdhanTiming.log("audio_focus_change change=$change")
                }
                .build()
            focusRequest = request
            return audioManager?.requestAudioFocus(request) ?: AudioManager.AUDIOFOCUS_REQUEST_FAILED
        } else {
            @Suppress("DEPRECATION")
            return audioManager?.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN)
                ?: AudioManager.AUDIOFOCUS_REQUEST_FAILED
        }
    }

    private fun stopPlayer() {
        releaseScreenWakeLock()
        unregisterAlarmVolumeObserver()
        activePrayer = null
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

    /** Watches the streams Android may route hardware volume keys to while Adhan is active. */
    private fun registerAlarmVolumeObserver(initialVolume: Int) {
        unregisterAlarmVolumeObserver()
        val streams = VOLUME_KEY_STREAMS
        val manager = audioManager ?: return
        // Capture after playback is prepared so setup-time/internal volume state
        // is the baseline and cannot be mistaken for a hardware key press.
        observedStreamVolumes = streams.associateWith { stream ->
            if (stream == AudioManager.STREAM_ALARM) initialVolume
            else manager.getStreamVolume(stream)
        }
        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                val manager = audioManager ?: return
                val currentVolumes = streams.associateWith { stream ->
                    runCatching { manager.getStreamVolume(stream) }.getOrDefault(-1)
                }
                val previousVolumes = observedStreamVolumes
                observedStreamVolumes = currentVolumes
                // Settings may emit several notifications for one key press.
                // Update the snapshot first, then stop once on the first real change.
                if (previousVolumes != null && currentVolumes.any { (stream, volume) ->
                        volume >= 0 && previousVolumes[stream] != volume
                    } && runCatching { player?.isPlaying == true }.getOrDefault(false)
                ) {
                    stopPlayback()
                }
            }
        }
        alarmVolumeObserver = observer
        contentResolver.registerContentObserver(Settings.System.CONTENT_URI, true, observer)
    }

    private fun unregisterAlarmVolumeObserver() {
        alarmVolumeObserver?.let { observer ->
            runCatching { contentResolver.unregisterContentObserver(observer) }
        }
        alarmVolumeObserver = null
        observedStreamVolumes = null
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
        manager.createNotificationChannel(
            NotificationChannel(
                PrayerAdhanStorage.CHANNEL_ALERT,
                "تنبيهات الأذان",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "تنبيه بارز عند دخول وقت الصلاة"
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            },
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
        val channel = if (prayer.isBlank()) {
            PrayerAdhanStorage.CHANNEL_PLAYBACK
        } else {
            PrayerAdhanStorage.CHANNEL_ALERT
        }
        val builder = NotificationCompat.Builder(this, channel)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(
                if (prayer.isBlank()) "الأذان"
                else "أذان صلاة ${prayerNameArabic(prayer)}",
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(
                if (prayer.isBlank()) null else elAzanPendingIntent(this, prayer),
            )
            .addAction(android.R.drawable.ic_media_pause, "إيقاف الأذان", stopPendingIntent)
        return builder.build()
    }

    override fun onDestroy() {
        AdhanTiming.log("service_onDestroy")
        unregisterAlarmVolumeObserver()
        stopPlayer()
        if (serviceInstance === this) serviceInstance = null
        super.onDestroy()
    }

    companion object {
        const val ACTION_PLAY = "com.example.muslim.PLAY_ADHAN"
        const val ACTION_TEST = "com.example.muslim.TEST_ADHAN"
        const val ACTION_STOP = "com.example.muslim.STOP_ADHAN"
        private const val NOTIFICATION_ID = 7301
        private val VOLUME_KEY_STREAMS = intArrayOf(
            AudioManager.STREAM_ALARM,
            AudioManager.STREAM_MUSIC,
            AudioManager.STREAM_RING,
            AudioManager.STREAM_SYSTEM,
            AudioManager.STREAM_NOTIFICATION,
        )

        private fun notificationId(prayer: String): Int =
            if (prayer.isBlank()) NOTIFICATION_ID else "prayer_alert_$prayer".hashCode()

        @Volatile
        private var activePrayer: String? = null

        @Volatile
        private var serviceInstance: PrayerAdhanPlaybackService? = null

        fun playbackState(): Map<String, Any> {
            val service = serviceInstance
            val prayer = activePrayer
            val playing = prayer != null && service != null && runCatching {
                service.player?.isPlaying == true &&
                    (service.audioManager?.getStreamVolume(AudioManager.STREAM_ALARM) ?: 1) > 0
            }.getOrDefault(false)
            return mapOf(
                "playing" to playing,
                "prayer" to if (playing) prayer.orEmpty() else "",
            )
        }

        fun stopForVisibleVolumeKey(): Boolean {
            val service = serviceInstance ?: return false
            val isPlaying = runCatching { service.player?.isPlaying == true }.getOrDefault(false)
            if (!isPlaying) return false
            service.stopPlayback()
            return true
        }
    }
}
