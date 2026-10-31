package com.example.untitled8

import android.content.Intent
import android.Manifest
import android.app.AlarmManager
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val shareChannel = "com.muslim/quran_share"
    private val adhanChannel = "com.muslim/prayer_adhan"
    private var notificationPermissionResult: MethodChannel.Result? = null
    private val notificationPermissionRequest = 7401

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                    "openBatterySettings" -> openBatterySettings(result)
                    "saveSettings" -> saveSettings(call.arguments as? Map<*, *>, result)
                    "updateSchedule" -> updateSchedule(call.arguments as? Map<*, *>, result)
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

    private fun permissionStatus(): Map<String, Boolean> {
        val alarmManager = getSystemService(AlarmManager::class.java)
        val exactAlarms = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarmManager?.canScheduleExactAlarms() == true
        val notifications = NotificationManagerCompat.from(this).areNotificationsEnabled() &&
            (Build.VERSION.SDK_INT < 33 ||
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
        val powerManager = getSystemService(PowerManager::class.java)
        val batteryOptimized = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            powerManager?.isIgnoringBatteryOptimizations(packageName) != true
        return mapOf(
            "exactAlarms" to exactAlarms,
            "notifications" to notifications,
            "batteryOptimized" to batteryOptimized,
        )
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(null)
            return
        }
        notificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationPermissionRequest,
        )
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

    private fun openBatterySettings(result: MethodChannel.Result) {
        try {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            result.success(null)
        } catch (error: Exception) {
            result.error("BATTERY_SETTINGS", error.message, null)
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
