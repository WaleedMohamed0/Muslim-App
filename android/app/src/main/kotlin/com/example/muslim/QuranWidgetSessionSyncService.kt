package com.example.muslim

import android.app.Service
import android.content.ComponentName
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.PlaybackStateCompat

/** Mirrors the existing audio_service MediaSession into the home-screen widget. */
class QuranWidgetSessionSyncService : Service() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var browser: MediaBrowserCompat? = null
    private var controller: MediaControllerCompat? = null
    private var callback: MediaControllerCompat.Callback? = null
    private var connectionPending = false
    private val reconnect = Runnable { connectToSession() }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Android restarts START_STICKY services with a null Intent after
        // reclaiming the process. The old process's Playing flag is no longer
        // authoritative: render a stopped transport immediately, retain the
        // saved track/position, and then reconcile against the live session.
        if (intent == null) {
            QuranAudioWidgetProvider.updateTransportState(
                this,
                active = false,
                playing = false,
            )
            connectToSession()
        } else if (intent.action == ACTION_START) {
            connectToSession()
        }
        return START_STICKY
    }

    private fun connectToSession() {
        if (connectionPending || browser?.isConnected == true) return
        connectionPending = true
        val mediaService = ComponentName(
            this,
            "com.ryanheise.audioservice.AudioService",
        )
        val connectionCallback = object : MediaBrowserCompat.ConnectionCallback() {
            override fun onConnected() {
                connectionPending = false
                val sessionToken = browser?.sessionToken
                if (sessionToken == null) {
                    releaseConnection()
                    scheduleReconnect()
                    return
                }
                runCatching {
                    MediaControllerCompat(this@QuranWidgetSessionSyncService, sessionToken)
                }.onSuccess { mediaController ->
                    controller = mediaController
                    val stateCallback = object : MediaControllerCompat.Callback() {
                        override fun onPlaybackStateChanged(state: PlaybackStateCompat?) {
                            syncSnapshot()
                        }

                        override fun onMetadataChanged(metadata: android.support.v4.media.MediaMetadataCompat?) {
                            syncSnapshot()
                        }
                    }
                    callback = stateCallback
                    mediaController.registerCallback(stateCallback, mainHandler)
                    mainHandler.removeCallbacks(reconnect)
                    syncSnapshot()
                }.onFailure {
                    scheduleReconnect()
                }
            }

            override fun onConnectionFailed() {
                connectionPending = false
                QuranAudioWidgetProvider.updateTransportState(
                    this@QuranWidgetSessionSyncService,
                    active = false,
                    playing = false,
                )
                scheduleReconnect()
            }

            override fun onConnectionSuspended() {
                connectionPending = false
                releaseConnection()
                QuranAudioWidgetProvider.updateTransportState(
                    this@QuranWidgetSessionSyncService,
                    active = false,
                    playing = false,
                )
                scheduleReconnect()
            }
        }

        browser = runCatching {
            MediaBrowserCompat(this, mediaService, connectionCallback, null)
        }.getOrNull()
        if (browser == null) {
            connectionPending = false
            scheduleReconnect()
            return
        }
        runCatching { browser?.connect() }.onFailure {
            connectionPending = false
            scheduleReconnect()
        }
    }

    private fun syncSnapshot() {
        val mediaController = controller ?: return
        QuranAudioWidgetProvider.updateFromMediaSession(
            this,
            mediaController.metadata,
            mediaController.playbackState,
        )
    }

    private fun scheduleReconnect() {
        mainHandler.removeCallbacks(reconnect)
        mainHandler.postDelayed(reconnect, RECONNECT_INTERVAL_MS)
    }

    private fun releaseConnection() {
        callback?.let { registered ->
            runCatching { controller?.unregisterCallback(registered) }
        }
        callback = null
        controller = null
        browser?.let { connected ->
            runCatching { if (connected.isConnected) connected.disconnect() }
        }
        browser = null
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(reconnect)
        releaseConnection()
        isRunning = false
        super.onDestroy()
    }

    companion object {
        @Volatile
        var isRunning: Boolean = false
            private set

        const val ACTION_START = "com.example.muslim.QURAN_WIDGET_SYNC_START"
        private const val RECONNECT_INTERVAL_MS = 5000L
    }
}
