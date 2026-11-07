package com.example.muslim

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.KeyEvent

/** Sends widget transport commands to the app's single audio_service player. */
class QuranWidgetPlayReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val keyCode = when (intent.action) {
            ACTION_PLAY -> KeyEvent.KEYCODE_MEDIA_PLAY
            ACTION_PAUSE -> KeyEvent.KEYCODE_MEDIA_PAUSE
            else -> return
        }

        if (intent.action == ACTION_PLAY) {
            dispatchPlayUntilConfirmed(context, keyCode)
        } else {
            dispatch(context, keyCode)
        }
    }

    private fun dispatchPlayUntilConfirmed(context: Context, keyCode: Int) {
        val pending = goAsync()
        val handler = Handler(Looper.getMainLooper())
        var attempts = 0
        var finished = false
        lateinit var retry: Runnable

        fun finish() {
            if (finished) return
            finished = true
            handler.removeCallbacks(retry)
            pending.finish()
        }

        retry = Runnable {
            if (finished) return@Runnable
            val widgetState = context.getSharedPreferences(
                WIDGET_STATE_PREFERENCES,
                Context.MODE_PRIVATE,
            )
            if (widgetState.getBoolean(KEY_PLAYING, false)) {
                Log.i(TAG, "Widget playback confirmed by the shared player state")
                finish()
                return@Runnable
            }
            if (attempts >= MAX_PLAY_ATTEMPTS) {
                Log.e(TAG, "AudioService did not confirm widget Play")
                finish()
                return@Runnable
            }

            attempts++
            Log.i(TAG, "Dispatching widget Play attempt=$attempts")
            dispatch(context, keyCode)
            handler.postDelayed(retry, RETRY_INTERVAL_MS)
        }

        retry.run()
        handler.postDelayed({ finish() }, PLAY_TIMEOUT_MS)
    }

    private fun dispatch(context: Context, keyCode: Int) {
        val serviceIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            component = ComponentName(context.packageName, AUDIO_SERVICE_CLASS)
            putExtra(
                Intent.EXTRA_KEY_EVENT,
                KeyEvent(KeyEvent.ACTION_DOWN, keyCode),
            )
        }

        try {
            // A widget tap is user initiated. Start the declared media-playback
            // foreground service directly without launching the Flutter UI.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.i(TAG, "Dispatched media key=$keyCode to AudioService")
            QuranAudioWidgetProvider.requestSessionSync(context)
        } catch (error: Exception) {
            Log.e(TAG, "Could not dispatch widget media key=$keyCode to AudioService", error)
        }
    }

    companion object {
        const val ACTION_PLAY = "com.example.muslim.QURAN_WIDGET_PLAY"
        const val ACTION_PAUSE = "com.example.muslim.QURAN_WIDGET_PAUSE"
        private const val TAG = "QuranWidgetPlay"
        private const val AUDIO_SERVICE_CLASS =
            "com.ryanheise.audioservice.AudioService"
        private const val WIDGET_STATE_PREFERENCES = "quran_audio_widget_state"
        private const val KEY_PLAYING = "playing"
        private const val RETRY_INTERVAL_MS = 750L
        private const val MAX_PLAY_ATTEMPTS = 12
        private const val PLAY_TIMEOUT_MS = 10000L
    }
}
