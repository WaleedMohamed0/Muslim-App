package com.example.muslim

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Shader
import android.graphics.BitmapShader
import android.view.View
import android.view.KeyEvent
import android.widget.RemoteViews
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.PlaybackStateCompat
import java.util.Locale

/** A RemoteViews controller for the app's existing audio_service session. */
class QuranAudioWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            refresh(context)
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val state = readState(context)
        appWidgetIds.forEach { id -> render(context, manager, id, state) }
        ensureSessionSync(context, state)
    }

    companion object {
        private const val PREFS = "quran_audio_widget_state"
        private const val KEY_ACTIVE = "active"
        private const val KEY_PLAYING = "playing"
        private const val KEY_LOADING = "loading"
        private const val KEY_SURAH = "surah"
        private const val KEY_RECITER = "reciter"
        private const val KEY_SURAH_NUMBER = "surah_number"
        private const val KEY_PAGE_NUMBER = "page_number"
        private const val KEY_AYAH_NUMBER = "ayah_number"
        private const val KEY_VERSE_COUNT = "verse_count"
        private const val KEY_AVATAR_ASSET = "avatar_asset"
        private const val KEY_POSITION_MS = "position_ms"
        private const val KEY_DURATION_MS = "duration_ms"
        private val avatarCache = mutableMapOf<String, Bitmap?>()

        private const val MEDIA_BUTTON_RECEIVER =
            "com.ryanheise.audioservice.MediaButtonReceiver"

        fun update(context: Context, arguments: Map<*, *>) {
            val active = arguments[KEY_ACTIVE] as? Boolean ?: false
            // Flutter MethodChannel maps use camelCase; keep accepting the
            // former snake_case keys for stored/native callers.
            val surahNumber = (arguments["surahNumber"] as? Number)?.toInt()
                ?: (arguments[KEY_SURAH_NUMBER] as? Number)?.toInt()
                ?: 0
            val ayahNumber = (arguments["ayahNumber"] as? Number)?.toInt()
                ?: (arguments[KEY_AYAH_NUMBER] as? Number)?.toInt()
                ?: 1
            val pageNumber = (arguments["pageNumber"] as? Number)?.toInt()
                ?: (arguments[KEY_PAGE_NUMBER] as? Number)?.toInt()
                ?: 0
            val verseCount = (arguments["verseCount"] as? Number)?.toInt()
                ?: (arguments[KEY_VERSE_COUNT] as? Number)?.toInt()
                ?: 0
            val hasSurah = surahNumber in 1..114
            val before = readState(context)
            val hasPosition = arguments["positionMs"] is Number
            val hasDuration = arguments["durationMs"] is Number
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_ACTIVE, active)
                .putBoolean(KEY_PLAYING, active && (arguments[KEY_PLAYING] as? Boolean ?: false))
                .putBoolean(KEY_LOADING, active && (arguments[KEY_LOADING] as? Boolean ?: false))
                // Keep the most recent position after Stop so Play can resume it.
                // Keep the previous track through an early Flutter startup
                // snapshot, which can be empty before preferences are loaded.
                .putString(KEY_SURAH, if (hasSurah) arguments[KEY_SURAH] as? String ?: before.surah else before.surah)
                .putString(KEY_RECITER, if (hasSurah) arguments[KEY_RECITER] as? String ?: before.reciter else before.reciter)
                .putString(KEY_AVATAR_ASSET, if (hasSurah) arguments["reciterAvatarAsset"] as? String ?: before.avatarAsset else before.avatarAsset)
                .putInt(KEY_SURAH_NUMBER, if (hasSurah) surahNumber else before.surahNumber)
                .putInt(
                    KEY_PAGE_NUMBER,
                    if (!hasSurah) before.pageNumber
                    else pageNumber.takeIf { it in 1..604 } ?: before.pageNumber,
                )
                .putInt(KEY_AYAH_NUMBER, if (hasSurah) ayahNumber else before.ayahNumber)
                .putInt(KEY_VERSE_COUNT, if (hasSurah) verseCount else before.verseCount)
                .putLong(
                    KEY_POSITION_MS,
                    if (hasPosition && hasSurah) {
                        (arguments["positionMs"] as Number).toLong().coerceAtLeast(0L)
                    } else before.positionMs,
                )
                .putLong(
                    KEY_DURATION_MS,
                    if (hasDuration && active) {
                        (arguments["durationMs"] as Number).toLong().coerceAtLeast(0L)
                    } else before.durationMs,
                )
                .apply()
            refreshIfChanged(context, before, readState(context))
            if (active) {
                ensureSessionSync(context, readState(context))
            }
        }

        /** Sync state reported by the Android MediaSession after a widget tap. */
        fun updateTransportState(context: Context, active: Boolean, playing: Boolean) {
            val before = readState(context)
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_ACTIVE, active)
                .putBoolean(KEY_PLAYING, active && playing)
                .putBoolean(KEY_LOADING, false)
                .apply()
            refreshIfChanged(context, before, readState(context))
        }

        /** Persist the active MediaSession snapshot as the widget's state source. */
        fun updateFromMediaSession(
            context: Context,
            metadata: MediaMetadataCompat?,
            state: PlaybackStateCompat?,
        ) {
            val before = readState(context)
            val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            if (metadata != null) {
                val mediaId = metadata.getString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID).orEmpty()
                val displayTitle = metadata.getString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE)
                    ?: metadata.getString(MediaMetadataCompat.METADATA_KEY_TITLE)
                    ?: mediaId.substringAfter("quran:").substringBeforeLast(":")
                val surahName = displayTitle.removePrefix("سورة ").trim()
                val reciter = metadata.getString(MediaMetadataCompat.METADATA_KEY_ARTIST)
                    ?: metadata.getString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE)
                    ?: mediaId.substringAfterLast(":")
                val description = metadata.getString(MediaMetadataCompat.METADATA_KEY_DISPLAY_DESCRIPTION).orEmpty()
                val ayahNumber = metadata.getLong("ayahNumber").toInt()
                    .takeIf { it > 0 }
                    ?: Regex("\\d+").find(description)?.value?.toIntOrNull()
                val surahNumber = metadata.getLong("surahNumber").toInt()
                    .takeIf { it in 1..114 }
                    ?: Regex("surah:(\\d+)").find(mediaId)?.groupValues?.get(1)?.toIntOrNull()
                if (surahName.isNotBlank() && reciter.isNotBlank()) {
                    editor.putString(KEY_SURAH, surahName)
                    editor.putString(KEY_RECITER, reciter)
                    editor.putInt(KEY_SURAH_NUMBER, surahNumber ?: editorFallbackSurah(context))
                    if (ayahNumber != null && ayahNumber > 0) editor.putInt(KEY_AYAH_NUMBER, ayahNumber)
                    val mushafPageNumber = metadata.getLong("mushafPageNumber").toInt()
                    if (mushafPageNumber > 0) {
                        editor.putInt(KEY_PAGE_NUMBER, mushafPageNumber)
                    }
                    editor.putLong(KEY_DURATION_MS, metadata.getLong(MediaMetadataCompat.METADATA_KEY_DURATION).coerceAtLeast(0L))
                }
            }
            val playing = when (state?.state) {
                PlaybackStateCompat.STATE_PLAYING -> true
                PlaybackStateCompat.STATE_BUFFERING -> false
                // AudioService can publish STOPPED briefly while changing the
                // prepared source. With metadata still attached, keep the last
                // confirmed transport state; a real Stop clears the item.
                PlaybackStateCompat.STATE_NONE,
                PlaybackStateCompat.STATE_STOPPED ->
                    metadata != null && before.playing
                else -> false
            }
            val active = metadata != null
            editor.putBoolean(KEY_ACTIVE, active)
                .putBoolean(KEY_PLAYING, active && playing)
                .putBoolean(KEY_LOADING, state?.state == PlaybackStateCompat.STATE_BUFFERING)
            // A newly recreated MediaSession starts empty. Do not treat its
            // initial zero position as a real seek; keep the last native
            // snapshot until the restored player publishes a prepared state.
            if (state != null &&
                state.state != PlaybackStateCompat.STATE_NONE &&
                state.state != PlaybackStateCompat.STATE_STOPPED
            ) {
                editor.putLong(KEY_POSITION_MS, state.position.coerceAtLeast(0L))
            }
            editor.apply()
            refreshIfChanged(context, before, readState(context))
            if (!active) context.stopService(Intent(context, QuranWidgetSessionSyncService::class.java))
        }

        private fun editorFallbackSurah(context: Context): Int =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getInt(KEY_SURAH_NUMBER, 0)

        private fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, QuranAudioWidgetProvider::class.java)
            val state = readState(context)
            manager.getAppWidgetIds(component).forEach { id ->
                render(context, manager, id, state)
            }
            ensureSessionSync(context, state)
        }

        private fun ensureSessionSync(context: Context, state: WidgetState) {
            if (!state.active ||
                state.surahNumber !in 1..114 ||
                QuranWidgetSessionSyncService.isRunning
            ) {
                return
            }
            val intent = Intent(context, QuranWidgetSessionSyncService::class.java)
                .setAction(QuranWidgetSessionSyncService.ACTION_START)
            runCatching { context.startService(intent) }
        }

        /** Reattach the widget mirror after a media-button Play command. */
        fun requestSessionSync(context: Context) {
            ensureSessionSync(context, readState(context))
        }

        /**
         * Keep the transport controls stable during progress updates. Flutter
         * and the MediaSession both publish playback position; those updates
         * should touch only the timeline, not replace the Play/Pause button.
         */
        private fun refreshIfChanged(
            context: Context,
            before: WidgetState,
            after: WidgetState,
        ) {
            val sameTrack = before.hasSameTrack(after)
            val sameTransportIcon = before.playing == after.playing
            if (!sameTrack || before.active != after.active || !sameTransportIcon) {
                refresh(context)
                return
            }

            if (before.active != after.active ||
                before.loading != after.loading ||
                before.playing != after.playing ||
                before.ayahNumber != after.ayahNumber ||
                before.pageNumber != after.pageNumber
            ) {
                refreshStatus(context, after)
            }
            if (before.positionMs != after.positionMs ||
                before.durationMs != after.durationMs
            ) {
                refreshProgress(context, after)
            }
        }

        private fun refreshStatus(context: Context, state: WidgetState) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, QuranAudioWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            if (widgetIds.isEmpty()) return
            val views = RemoteViews(context.packageName, R.layout.quran_audio_widget).apply {
                setTextViewText(R.id.quran_widget_state, statusText(state))
                val readerIntent = readerPendingIntent(context, state)
                setOnClickPendingIntent(R.id.quran_widget_root, readerIntent)
                setOnClickPendingIntent(R.id.quran_widget_main_area, readerIntent)
                setOnClickPendingIntent(R.id.quran_widget_header, readerIntent)
                setOnClickPendingIntent(R.id.quran_widget_timeline, readerIntent)
            }
            widgetIds.forEach { id -> manager.partiallyUpdateAppWidget(id, views) }
        }

        private fun refreshProgress(context: Context, state: WidgetState) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, QuranAudioWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            if (widgetIds.isEmpty()) return

            val hasDuration = state.durationMs > 0L
            val boundedPosition = state.positionMs.coerceIn(
                0L,
                state.durationMs.coerceAtLeast(0L),
            )
            val progress = if (hasDuration) {
                ((boundedPosition * PROGRESS_MAX) / state.durationMs).toInt()
            } else {
                0
            }
            val views = RemoteViews(context.packageName, R.layout.quran_audio_widget).apply {
                setProgressBar(R.id.quran_widget_progress, PROGRESS_MAX, progress, false)
                setTextViewText(R.id.quran_widget_elapsed, formatTime(state.positionMs))
                setTextViewText(
                    R.id.quran_widget_remaining,
                    formatTime(state.durationMs),
                )
            }
            widgetIds.forEach { id -> manager.partiallyUpdateAppWidget(id, views) }
        }

        private data class WidgetState(
            val active: Boolean,
            val playing: Boolean,
            val loading: Boolean,
            val surah: String,
            val reciter: String,
            val surahNumber: Int,
            val pageNumber: Int,
            val ayahNumber: Int,
            val verseCount: Int,
            val avatarAsset: String,
            val positionMs: Long,
            val durationMs: Long,
        ) {
            fun hasSameTrack(other: WidgetState): Boolean =
                surah == other.surah &&
                    reciter == other.reciter &&
                    surahNumber == other.surahNumber &&
                    avatarAsset == other.avatarAsset
        }

        private fun readState(context: Context): WidgetState {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            return WidgetState(
                active = prefs.getBoolean(KEY_ACTIVE, false),
                playing = prefs.getBoolean(KEY_PLAYING, false),
                loading = prefs.getBoolean(KEY_LOADING, false),
                surah = prefs.getString(KEY_SURAH, "").orEmpty(),
                reciter = prefs.getString(KEY_RECITER, "").orEmpty(),
                surahNumber = prefs.getInt(KEY_SURAH_NUMBER, 0),
                pageNumber = prefs.getInt(KEY_PAGE_NUMBER, 0),
                ayahNumber = prefs.getInt(KEY_AYAH_NUMBER, 0),
                verseCount = prefs.getInt(KEY_VERSE_COUNT, 0),
                avatarAsset = prefs.getString(KEY_AVATAR_ASSET, "").orEmpty(),
                positionMs = prefs.getLong(KEY_POSITION_MS, 0L),
                durationMs = prefs.getLong(KEY_DURATION_MS, 0L),
            )
        }

        private fun render(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
            state: WidgetState,
        ) {
            val hasTrack = state.surahNumber in 1..114 && state.surah.isNotBlank()
            val views = RemoteViews(context.packageName, R.layout.quran_audio_widget)
            val avatar = loadCircularAvatar(context, state.avatarAsset)
            if (avatar == null) {
                views.setImageViewResource(
                    R.id.quran_widget_avatar,
                    R.drawable.quran_audio_widget_avatar_fallback,
                )
            } else {
                views.setImageViewBitmap(R.id.quran_widget_avatar, avatar)
            }
            views.setTextViewText(
                R.id.quran_widget_surah,
                if (hasTrack) "سورة ${state.surah}" else "القرآن الكريم",
            )
            views.setTextViewText(
                R.id.quran_widget_reciter,
                if (hasTrack && state.reciter.isNotBlank()) state.reciter
                else "افتح التطبيق لبدء التلاوة",
            )
            views.setTextViewText(
                R.id.quran_widget_state,
                statusText(state),
            )
            val hasDuration = state.durationMs > 0L
            val boundedPosition = state.positionMs.coerceIn(0L, state.durationMs.coerceAtLeast(0L))
            val progress = if (hasDuration) {
                ((boundedPosition * PROGRESS_MAX) / state.durationMs).toInt()
            } else {
                0
            }
            views.setProgressBar(R.id.quran_widget_progress, PROGRESS_MAX, progress, false)
            views.setTextViewText(
                R.id.quran_widget_elapsed,
                formatTime(state.positionMs),
            )
            views.setTextViewText(
                R.id.quran_widget_remaining,
                formatTime(state.durationMs),
            )
            views.setViewVisibility(
                R.id.quran_widget_timeline,
                if (hasTrack && hasDuration) View.VISIBLE else View.GONE,
            )
            // Keep Play available whenever a saved Quran track exists.
            views.setViewVisibility(
                R.id.quran_widget_play_pause,
                if (hasTrack) View.VISIBLE else View.GONE,
            )
            views.setViewVisibility(
                R.id.quran_widget_previous,
                if (hasTrack) View.VISIBLE else View.INVISIBLE,
            )
            views.setViewVisibility(
                R.id.quran_widget_next,
                if (hasTrack) View.VISIBLE else View.INVISIBLE,
            )
            views.setImageViewResource(
                R.id.quran_widget_play_pause,
                if (state.playing) R.drawable.quran_widget_pause
                else R.drawable.quran_widget_play,
            )
            views.setContentDescription(
                R.id.quran_widget_play_pause,
                if (state.playing) "إيقاف التلاوة مؤقتًا" else "استئناف التلاوة",
            )
            // The root owns the main-surface navigation action. Each playback
            // control below receives its own explicit PendingIntent after
            // this parent action, so controls remain independent.
            val readerIntent = readerPendingIntent(context, state)
            views.setOnClickPendingIntent(R.id.quran_widget_root, readerIntent)
            views.setOnClickPendingIntent(
                R.id.quran_widget_main_area,
                readerIntent,
            )
            views.setOnClickPendingIntent(
                R.id.quran_widget_header,
                readerIntent,
            )
            views.setOnClickPendingIntent(
                R.id.quran_widget_timeline,
                readerIntent,
            )
            if (hasTrack) {
                views.setOnClickPendingIntent(
                    R.id.quran_widget_play_pause,
                    widgetTransportPendingIntent(
                        context,
                        if (state.playing) QuranWidgetPlayReceiver.ACTION_PAUSE
                        else QuranWidgetPlayReceiver.ACTION_PLAY,
                        if (state.playing) 412 else 415,
                    ),
                )
            }
            if (hasTrack) {
                views.setOnClickPendingIntent(
                    R.id.quran_widget_previous,
                    actionPendingIntent(context, KeyEvent.KEYCODE_MEDIA_NEXT, 414),
                )
                views.setOnClickPendingIntent(
                    R.id.quran_widget_next,
                    actionPendingIntent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS, 416),
                )
            }
            manager.updateAppWidget(widgetId, views)
        }

        private fun readerPendingIntent(
            context: Context,
            state: WidgetState,
        ): PendingIntent {
            val hasSavedPosition =
                state.surahNumber in 1..114 && state.ayahNumber > 0
            val routeSurah = if (hasSavedPosition) state.surahNumber else 1
            val routeAyah = if (hasSavedPosition) state.ayahNumber else 1
            val routePage = state.pageNumber.takeIf { it in 1..604 } ?: 0
            val route = "quran_reader:$routeSurah:$routePage:$routeAyah"
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                // A widget tap is a direct reader entry point. Start a clean
                // task so an old Flutter Home route cannot remain above the
                // reader when Android reuses the app's existing task.
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TASK
                putExtra("notification_route", route)
                // Keep the destination as explicit typed extras as well as
                // the legacy route string. This survives Activity reuse and
                // lets the Flutter entry point restore all three coordinates.
                putExtra("surah_number", routeSurah)
                putExtra("page_number", routePage)
                putExtra("ayah_number", routeAyah)
                data = android.net.Uri.parse(
                    "muslim://quran-widget/$routeSurah/$routePage/$routeAyah",
                )
            }
            return PendingIntent.getActivity(
                context,
                411,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun actionPendingIntent(
            context: Context,
            keyCode: Int,
            requestCode: Int,
        ): PendingIntent {
            val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                component = ComponentName(context.packageName, MEDIA_BUTTON_RECEIVER)
                putExtra(
                    Intent.EXTRA_KEY_EVENT,
                    KeyEvent(KeyEvent.ACTION_DOWN, keyCode),
                )
            }
            return PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun widgetTransportPendingIntent(
            context: Context,
            action: String,
            requestCode: Int,
        ): PendingIntent {
            val intent = Intent(context, QuranWidgetPlayReceiver::class.java)
                .setAction(action)
            return PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun formatTime(milliseconds: Long): String {
            val totalSeconds = milliseconds.coerceAtLeast(0L) / 1000L
            val hours = totalSeconds / 3600L
            val minutes = (totalSeconds / 60L) % 60L
            val seconds = totalSeconds % 60L
            val westernDigits = if (hours > 0L) {
                String.format(Locale.ROOT, "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                String.format(Locale.ROOT, "%02d:%02d", totalSeconds / 60L, seconds)
            }
            return westernDigits.map { digit ->
                if (digit in '0'..'9') (digit.code + 0x0660 - 0x0030).toChar()
                else digit
            }.joinToString("")
        }

        private fun statusText(state: WidgetState): String = when {
            state.surahNumber !in 1..114 || state.surah.isBlank() ->
                "لا توجد تلاوة نشطة"
            state.loading -> "جارٍ تجهيز التلاوة"
            state.playing -> ayahStatus(state)
            state.active -> ayahStatus(state)
            else -> "متوقفة • ${ayahStatus(state)}"
        }

        private fun ayahStatus(state: WidgetState): String {
            val ayah = toArabicIndicDigits(state.ayahNumber)
            val count = state.verseCount
            return if (count > 0) "الآية $ayah من ${toArabicIndicDigits(count)}"
            else "الآية $ayah"
        }

        private fun toArabicIndicDigits(value: Int): String = value.toString().map { digit ->
            if (digit in '0'..'9') (digit.code + 0x0660 - 0x0030).toChar() else digit
        }.joinToString("")

        private fun loadCircularAvatar(context: Context, flutterAsset: String): Bitmap? {
            if (!flutterAsset.startsWith("assets/images/reciters/")) return null
            synchronized(avatarCache) {
                if (avatarCache.containsKey(flutterAsset)) return avatarCache[flutterAsset]
            }
            val source = runCatching {
                context.assets.open("flutter_assets/$flutterAsset").use {
                    BitmapFactory.decodeStream(it)
                }
            }.getOrNull()
            if (source == null) {
                synchronized(avatarCache) { avatarCache[flutterAsset] = null }
                return null
            }
            val dimension = 144
            val cropped = Bitmap.createBitmap(dimension, dimension, Bitmap.Config.ARGB_8888)
            val scale = maxOf(dimension / source.width.toFloat(), dimension / source.height.toFloat())
            val scaledWidth = source.width * scale
            val scaledHeight = source.height * scale
            val matrix = android.graphics.Matrix().apply {
                setScale(scale, scale)
                postTranslate((dimension - scaledWidth) / 2f, (dimension - scaledHeight) / 2f)
            }
            val shader = BitmapShader(source, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP).apply {
                setLocalMatrix(matrix)
            }
            Canvas(cropped).drawCircle(
                dimension / 2f,
                dimension / 2f,
                dimension / 2f,
                Paint(Paint.ANTI_ALIAS_FLAG).apply { this.shader = shader },
            )
            source.recycle()
            synchronized(avatarCache) { avatarCache[flutterAsset] = cropped }
            return cropped
        }

        private const val PROGRESS_MAX = 1000
    }
}
