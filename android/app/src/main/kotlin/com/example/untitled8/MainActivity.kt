package com.example.untitled8

import android.content.Intent
import android.Manifest
import android.app.AlarmManager
import android.hardware.GeomagneticField
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: AudioServiceActivity() {
    private val shareChannel = "com.muslim/quran_share"
    private val adhanChannel = "com.muslim/prayer_adhan"
    private val notificationNavigationChannel = "com.muslim/notification_navigation"
    private val qiblaCompassChannel = "com.muslim/qibla_compass"
    private val quranAudioWidgetChannel = "com.muslim/quran_audio_widget"
    private var notificationNavigation: MethodChannel? = null
    private var pendingNotificationRoute: String? = null
    private var notificationPermissionResult: MethodChannel.Result? = null
    private val notificationPermissionRequest = 7401

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        notificationNavigation = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationNavigationChannel,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "initialNotificationRoute") {
                    result.success(consumeNotificationRoute())
                } else {
                    result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, quranAudioWidgetChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateState" -> {
                        val arguments = call.arguments as? Map<*, *>
                        if (arguments == null) {
                            result.error("INVALID_WIDGET_STATE", "Widget state is required", null)
                        } else {
                            QuranAudioWidgetProvider.update(this, arguments)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, qiblaCompassChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "magneticDeclination") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                val altitude = call.argument<Double>("altitude") ?: 0.0
                if (latitude == null || longitude == null) {
                    result.error("INVALID_COORDINATES", "Valid coordinates are required", null)
                    return@setMethodCallHandler
                }
                try {
                    result.success(
                        GeomagneticField(
                            latitude.toFloat(),
                            longitude.toFloat(),
                            altitude.toFloat(),
                            System.currentTimeMillis(),
                        ).declination.toDouble(),
                    )
                } catch (error: Exception) {
                    result.error("DECLINATION_UNAVAILABLE", error.message, null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "shareText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val text = call.argument<String>("text")
                val title = call.argument<String>("title")
                if (text.isNullOrBlank()) {
                    result.error("INVALID_TEXT", "Text to share is required", null)
                    return@setMethodCallHandler
                }

                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, text)
                }
                startActivity(Intent.createChooser(intent, title))
                result.success(null)
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, adhanChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "permissionStatus" -> result.success(permissionStatus())
                    "requestNotificationPermission" -> requestNotificationPermission(result)
                    "requestExactAlarmPermission" -> requestExactAlarmPermission(result)
                    "openNotificationSettings" -> openNotificationSettings(result)
                    "openAppSettings" -> openAppSettings(result)
                    "saveSettings" -> saveSettings(call.arguments as? Map<*, *>, result)
                    "updateSchedule" -> updateSchedule(call.arguments as? Map<*, *>, result)
                    "getAdhanPlaybackState" -> result.success(PrayerAdhanPlaybackService.playbackState())
                    "getDailyReminders" -> result.success(DailyAzkarReminderScheduler.getSettings(this))
                    "saveDailyReminders" -> saveDailyReminders(call.arguments as? List<*>, result)
                    "previewAudio" -> {
                        val audioId = call.argument<String>("audioId")
                        if (audioId.isNullOrBlank() || !isBuiltInAdhan(audioId)) {
                            result.error("INVALID_ADHAN", "Unknown built-in Adhan", null)
                        } else {
                            startAdhanService(
                                PrayerAdhanPlaybackService.ACTION_TEST,
                                result,
                                audioId,
                            )
                        }
                    }
                    "stopAudio" -> startAdhanService(PrayerAdhanPlaybackService.ACTION_STOP, result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = notificationRouteFrom(intent)
        if (route != null) {
            pendingNotificationRoute = route
            notificationNavigation?.invokeMethod("openNotificationRoute", route)
        }
    }

    private fun notificationRouteFrom(source: Intent?): String? {
        val surahNumber = source?.getIntExtra("surah_number", 0) ?: 0
        val pageNumber = source?.getIntExtra("page_number", 0) ?: 0
        val ayahNumber = source?.getIntExtra("ayah_number", 0) ?: 0
        val explicitQuranPosition = if (surahNumber in 1..114 && ayahNumber > 0) {
            "quran_reader:$surahNumber:$pageNumber:$ayahNumber"
        } else {
            null
        }
        val rawRoute = explicitQuranPosition
            ?: source?.getStringExtra("notification_route")
            ?: routeFromDailyReminderUri(source?.data)
            ?: if (source?.getBooleanExtra("open_adhan_settings", false) == true) {
                "elazan_screen"
            } else {
                null
            }
        val route = if (rawRoute == "adhan_settings") "elazan_screen" else rawRoute
        if (route != "elazan_screen") return route
        val prayer = source?.getStringExtra("prayer")?.lowercase()
        return if (prayer.isNullOrBlank()) route else "$route:$prayer"
    }

    private fun routeFromDailyReminderUri(uri: Uri?): String? {
        if (uri?.scheme != "muslimapp" || uri.host != "notification") return null
        return when (uri.lastPathSegment) {
            "morning" -> "azkar_morning"
            "evening" -> "azkar_evening"
            "daily_wird" -> "daily_wird"
            else -> null
        }
    }

    private fun consumeNotificationRoute(): String? {
        val route = pendingNotificationRoute ?: notificationRouteFrom(intent)
        pendingNotificationRoute = null
        intent?.removeExtra("notification_route")
        intent?.removeExtra("open_adhan_settings")
        intent?.removeExtra("surah_number")
        intent?.removeExtra("page_number")
        intent?.removeExtra("ayah_number")
        return route
    }

    private fun permissionStatus(): Map<String, Boolean> {
        val alarmManager = getSystemService(AlarmManager::class.java)
        val exactAlarms = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarmManager?.canScheduleExactAlarms() == true
        val notifications = NotificationManagerCompat.from(this).areNotificationsEnabled() &&
            (Build.VERSION.SDK_INT < 33 ||
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
        val location = Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        return mapOf(
            "exactAlarms" to exactAlarms,
            "notifications" to notifications,
            "location" to location,
        )
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            val preferences = getSharedPreferences("device_permission_requests", MODE_PRIVATE)
            if (preferences.getBoolean("notifications_asked", false) &&
                !shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)
            ) {
                openNotificationSettings(result)
                return
            }
            preferences.edit().putBoolean("notifications_asked", true).apply()
            notificationPermissionResult = result
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                notificationPermissionRequest,
            )
            return
        }
        if (!NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            openNotificationSettings(result)
            return
        }
        if (Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(null)
            return
        }
    }

    private fun requestExactAlarmPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            getSystemService(AlarmManager::class.java)?.canScheduleExactAlarms() == true
        ) {
            result.success(null)
            return
        }
        try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
            result.success(null)
        } catch (error: Exception) {
            result.error("EXACT_ALARM_SETTINGS", error.message, null)
        }
    }

    private fun openNotificationSettings(result: MethodChannel.Result) {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(
                    Settings.EXTRA_APP_PACKAGE,
                    packageName,
                )
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).setData(
                    Uri.parse("package:$packageName"),
                )
            }
            startActivity(intent)
            result.success(null)
        } catch (error: Exception) {
            result.error("NOTIFICATION_SETTINGS", error.message, null)
        }
    }

    private fun openAppSettings(result: MethodChannel.Result) {
        try {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
            result.success(null)
        } catch (error: Exception) {
            result.error("APP_SETTINGS", error.message, null)
        }
    }

    private fun saveSettings(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val values = arguments ?: emptyMap<Any, Any>()
        val prefs = getSharedPreferences(PrayerAdhanStorage.PREFS, MODE_PRIVATE)
        val editor = prefs.edit()
            .putBoolean(PrayerAdhanStorage.ENABLED, values["enabled"] as? Boolean ?: false)
            .putFloat(PrayerAdhanStorage.VOLUME, (values["volume"] as? Number)?.toFloat() ?: .85f)
        val prayerValues = values["prayers"] as? Map<*, *>
        listOf("fajr", "dhuhr", "asr", "maghrib", "isha").forEach { prayer ->
            editor.putBoolean("prayer_$prayer", prayerValues?.get(prayer) as? Boolean ?: true)
        }
        val audioId = values["audioId"] as? String ?: "adhan_madinah"
        editor.putString(PrayerAdhanStorage.AUDIO_ID, audioId)
            .remove("audio_path")
            .remove("audio_name")
        editor.apply()
        PrayerAlarmScheduler.restore(this, reinterpretLocalTimes = false)
        result.success(null)
    }

    private fun updateSchedule(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val rawAlarms = arguments?.get("alarms") as? List<*> ?: emptyList<Any>()
        val alarms = JSONArray()
        rawAlarms.forEach { raw ->
            val values = raw as? Map<*, *> ?: return@forEach
            val json = JSONObject()
            values.forEach { (key, value) -> if (key != null && value != null) json.put(key.toString(), value) }
            alarms.put(json)
        }
        PrayerAlarmScheduler.replaceSchedule(this, alarms)
        result.success(null)
    }

    private fun saveDailyReminders(arguments: List<*>?, result: MethodChannel.Result) {
        if (arguments == null) {
            result.error("INVALID_REMINDERS", "Reminder settings are required", null)
            return
        }
        try {
            DailyAzkarReminderScheduler.save(this, arguments)
            result.success(DailyAzkarReminderScheduler.getSettings(this))
        } catch (error: Exception) {
            result.error("REMINDER_SCHEDULE", error.message, null)
        }
    }

    private fun startAdhanService(
        action: String,
        result: MethodChannel.Result,
        audioId: String? = null,
    ) {
        try {
            val serviceIntent = Intent(this, PrayerAdhanPlaybackService::class.java).apply {
                this.action = action
                audioId?.let { putExtra("audio_id", it) }
            }
            if (action == PrayerAdhanPlaybackService.ACTION_STOP) stopService(serviceIntent)
            else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(serviceIntent)
            else startService(serviceIntent)
            result.success(null)
        } catch (error: Exception) {
            result.error("ADHAN_SERVICE", error.message, null)
        }
    }

    private fun isBuiltInAdhan(audioId: String): Boolean =
        resources.getIdentifier(audioId, "raw", packageName) != 0

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationPermissionRequest) {
            notificationPermissionResult?.success(
                grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
            )
            notificationPermissionResult = null
        }
    }
}
