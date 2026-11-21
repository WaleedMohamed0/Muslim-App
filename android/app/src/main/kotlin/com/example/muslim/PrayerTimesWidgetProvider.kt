package com.waleed.muslimapp

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.SystemClock
import android.util.TypedValue
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Calendar
import java.util.Locale

/** Renders the schedule calculated by Flutter. Native code only tracks time and formats it. */
class PrayerTimesWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(context, manager, it) }
        scheduleNextRefresh(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, manager, appWidgetId, newOptions)
        render(context, manager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == Intent.ACTION_DATE_CHANGED ||
            intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED ||
            intent.action == Intent.ACTION_BOOT_COMPLETED) refresh(context)
    }

    companion object {
        private const val PREFS = "prayer_times_widget_state"
        private val entries = listOf(
            "الفجر" to "fajr", "الشروق" to "sunrise", "الظهر" to "dhuhr",
            "العصر" to "asr", "المغرب" to "maghrib", "العشاء" to "isha",
        )
        private val cellIds = mapOf(
            "fajr" to (R.id.prayer_cell_fajr to (R.id.prayer_name_fajr to R.id.prayer_time_fajr)),
            "sunrise" to (R.id.prayer_cell_sunrise to (R.id.prayer_name_sunrise to R.id.prayer_time_sunrise)),
            "dhuhr" to (R.id.prayer_cell_dhuhr to (R.id.prayer_name_dhuhr to R.id.prayer_time_dhuhr)),
            "asr" to (R.id.prayer_cell_asr to (R.id.prayer_name_asr to R.id.prayer_time_asr)),
            "maghrib" to (R.id.prayer_cell_maghrib to (R.id.prayer_name_maghrib to R.id.prayer_time_maghrib)),
            "isha" to (R.id.prayer_cell_isha to (R.id.prayer_name_isha to R.id.prayer_time_isha)),
        )

        fun update(context: Context, values: Map<*, *>) {
            val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            (values["city"] as? String)?.trim()?.takeIf { it.isNotEmpty() }?.let {
                editor.putString("city", it)
            }
            entries.forEach { (_, key) ->
                val epoch = (values[key] as? Number)?.toLong() ?: return
            editor.putLong(key, epoch)
            }
            val fajr = values["fajr"] as? Number
            if (fajr != null) editor.putString("schedule_day", dayKey(fajr.toLong()))
            editor.putLong("saved_at", System.currentTimeMillis()).apply()
            refresh(context)
            scheduleNextRefresh(context)
        }

        fun refresh(context: Context) {
            advanceCachedSchedule(context)
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PrayerTimesWidgetProvider::class.java))
            ids.forEach { render(context, manager, it) }
            scheduleNextRefresh(context)
        }

        private fun scheduleNextRefresh(context: Context) {
            val alarm = context.getSystemService(AlarmManager::class.java) ?: return
            val intent = Intent(context, PrayerTimesWidgetTickReceiver::class.java)
            val pending = PendingIntent.getBroadcast(
                context, 8104, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val now = System.currentTimeMillis()
            val nextPrayer = listOf("fajr", "dhuhr", "asr", "maghrib", "isha")
                .map { prefs.getLong(it, 0L) }.firstOrNull { it > now }
            val midnight = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 1); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            }.timeInMillis
            val trigger = minOf(nextPrayer ?: Long.MAX_VALUE, midnight).coerceAtLeast(now + 60_000L)
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
        }

        private fun advanceCachedSchedule(context: Context) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val fajr = prefs.getLong("fajr", 0L)
            if (fajr <= 0L) return
            val currentDay = dayKey(System.currentTimeMillis())
            val savedDay = prefs.getString("schedule_day", dayKey(fajr)) ?: dayKey(fajr)
            if (savedDay >= currentDay) return
            val old = SimpleDateFormat("yyyyMMdd", Locale.US).parse(savedDay) ?: return
            val today = SimpleDateFormat("yyyyMMdd", Locale.US).parse(currentDay) ?: return
            val cursor = Calendar.getInstance().apply { time = old }
            val target = Calendar.getInstance().apply { time = today }
            var days = 0
            while (cursor.get(Calendar.YEAR) < target.get(Calendar.YEAR) ||
                cursor.get(Calendar.DAY_OF_YEAR) < target.get(Calendar.DAY_OF_YEAR)) {
                cursor.add(Calendar.DAY_OF_YEAR, 1)
                days++
            }
            if (days == 0) return
            val editor = prefs.edit()
            entries.forEach { (_, key) ->
                val epoch = prefs.getLong(key, 0L)
                if (epoch > 0L) editor.putLong(key, Calendar.getInstance().apply {
                    timeInMillis = epoch
                    add(Calendar.DAY_OF_YEAR, days)
                }.timeInMillis)
            }
            editor.putString("schedule_day", currentDay).apply()
        }

        private fun dayKey(epoch: Long): String = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date(epoch))

        private fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val options = manager.getAppWidgetOptions(id)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, MIN_WIDTH_DP)
                .coerceAtLeast(MIN_WIDTH_DP)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, MIN_HEIGHT_DP)
                .coerceAtLeast(MIN_HEIGHT_DP)
            val compact = minWidth < 300
            val cellNameSize = when {
                minWidth < 280 -> 10f
                minWidth < 360 -> 11f
                else -> 12f
            }
            val cellTimeSize = when {
                minWidth < 280 -> 11f
                minWidth < 360 -> 12f
                else -> 14f
            }
            val horizontalPadding = when {
                minWidth < 280 -> 8
                minWidth < 360 -> 12
                else -> 16
            }
            val verticalPadding = when {
                minHeight < 220 -> 4
                minHeight < 280 -> 7
                else -> 10
            }
            val density = context.resources.displayMetrics.density
            fun dp(value: Int): Int = (value * density).toInt()
            // RemoteViews text uses SP by default, which can grow beyond the space
            // reserved by launcher widget grids. PX keeps the chosen dp size stable
            // across system font scales while density still maps it to physical pixels.
            fun textPx(value: Float): Float = value * density

            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val times = entries.mapNotNull { (name, key) ->
                prefs.getLong(key, 0L).takeIf { it > 0 }?.let { Triple(name, key, it) }
            }
            val now = System.currentTimeMillis()
            val today = dayKey(now)
            val scheduleIsToday = times.firstOrNull()?.third?.let {
                SimpleDateFormat("yyyyMMdd", Locale.US).format(Date(it)) == today
            } == true
            val obligatoryTimes = times.filter { it.second != "sunrise" }
            val nextIndex = if (scheduleIsToday) obligatoryTimes.indexOfFirst { it.third > now } else -1
            val next = if (nextIndex >= 0) obligatoryTimes[nextIndex]
                else if (scheduleIsToday) obligatoryTimes.firstOrNull() else null
            val nextAt = next?.third?.let { if (it <= now) it + DAY_MS else it }
            val remaining = nextAt?.minus(now)?.coerceAtLeast(0L) ?: 0L
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget).apply {
                setViewPadding(
                    R.id.prayer_widget_root,
                    dp(horizontalPadding),
                    dp(verticalPadding),
                    dp(horizontalPadding),
                    dp(verticalPadding),
                )
                setTextViewTextSize(
                    R.id.prayer_widget_heading,
                    TypedValue.COMPLEX_UNIT_PX,
                    textPx(if (compact) 14f else 17f),
                )
                setTextViewTextSize(
                    R.id.prayer_widget_date,
                    TypedValue.COMPLEX_UNIT_PX,
                    textPx(if (minWidth < 280) 9f else 10f),
                )
                setTextViewTextSize(
                    R.id.prayer_widget_countdown_title,
                    TypedValue.COMPLEX_UNIT_PX,
                    textPx(if (compact) 11f else 13f),
                )
                setTextViewTextSize(R.id.prayer_widget_next_name, TypedValue.COMPLEX_UNIT_PX, textPx(if (compact) 15f else 18f))
                setTextViewTextSize(
                    R.id.prayer_widget_countdown,
                    TypedValue.COMPLEX_UNIT_PX,
                    textPx(if (compact) 15f else 18f),
                )
                setTextViewText(R.id.prayer_widget_countdown_title, "الصلاة القادمة")
                setTextViewText(R.id.prayer_widget_next_name, next?.first ?: "المواقيت غير متاحة")
                setChronometer(
                    R.id.prayer_widget_countdown,
                    SystemClock.elapsedRealtime() + remaining,
                    "%s",
                    nextAt != null,
                )
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                    setChronometerCountDown(R.id.prayer_widget_countdown, nextAt != null)
                }
                setViewVisibility(
                    R.id.prayer_widget_countdown,
                    if (nextAt == null) android.view.View.GONE else android.view.View.VISIBLE,
                )
                times.forEach { (name, key, epoch) ->
                    val (cellId, textIds) = cellIds.getValue(key)
                    val (nameId, timeId) = textIds
                    val selected = scheduleIsToday && name == next?.first
                    val time = if (scheduleIsToday) {
                        SimpleDateFormat("h:mm", Locale.getDefault()).format(Date(epoch))
                    } else "--:--"
                    setTextViewText(nameId, name)
                    setTextViewText(timeId, time)
                    setTextViewTextSize(nameId, TypedValue.COMPLEX_UNIT_PX, textPx(cellNameSize))
                    setTextViewTextSize(timeId, TypedValue.COMPLEX_UNIT_PX, textPx(cellTimeSize))
                    setTextColor(
                        nameId,
                        ContextCompat.getColor(
                            context,
                            if (selected) R.color.prayer_widget_accent else R.color.prayer_widget_secondary_text,
                        ),
                    )
                    setTextColor(
                        timeId,
                        ContextCompat.getColor(
                            context,
                            if (selected) R.color.prayer_widget_accent else R.color.prayer_widget_primary_text,
                        ),
                    )
                    setInt(
                        cellId,
                        "setBackgroundResource",
                        if (selected) R.drawable.prayer_widget_cell_highlight else R.drawable.prayer_widget_cell_background,
                    )
                }
                setTextViewText(R.id.prayer_widget_date, prefs.getString("city", null).orEmpty())
                setTextViewText(R.id.prayer_widget_day,
                    SimpleDateFormat("EEEE، d MMMM", Locale("ar")).format(Date()))
                val open = Intent(context, MainActivity::class.java).putExtra("notification_route", "prayer_times")
                val tap = PendingIntent.getActivity(context, 8105, open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.prayer_widget_root, tap)
            }
            manager.updateAppWidget(id, views)
        }

        private const val DAY_MS = 86_400_000L
        private const val MIN_WIDTH_DP = 180
        private const val MIN_HEIGHT_DP = 180
    }
}

class PrayerTimesWidgetTickReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = PrayerTimesWidgetProvider.refresh(context)
}
