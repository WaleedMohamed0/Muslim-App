package com.example.muslim

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.view.KeyEvent

/** Sends widget transport commands to the app's single audio_service player. */
class QuranWidgetPlayReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TOGGLE) return
        dispatch(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
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
            // A widget tap is user initiated. Start AudioService directly
            // without launching the Flutter UI; its handler resolves the
            // toggle against the current player state.
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
        const val ACTION_TOGGLE = "com.example.muslim.QURAN_WIDGET_TOGGLE"
        private const val TAG = "QuranWidgetPlay"
        private const val AUDIO_SERVICE_CLASS =
            "com.ryanheise.audioservice.AudioService"
    }
}
