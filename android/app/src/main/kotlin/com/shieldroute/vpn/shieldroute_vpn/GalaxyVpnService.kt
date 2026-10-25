package com.shieldroute.vpn.shieldroute_vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.net.ConnectException
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import javax.net.ssl.SSLException

/**
 * Foreground VpnService running an [SstpTunnel] to a VPN Gate relay.
 *
 * Controlled with started intents ([ACTION_CONNECT] / [ACTION_DISCONNECT]) so the
 * tunnel outlives the activity. State and traffic are reported to Flutter through
 * [eventSink] as `{type: state|metrics, ...}` maps.
 */
class GalaxyVpnService : VpnService() {

    companion object {
        private const val TAG = "GalaxyVpnService"
        private const val NOTIFICATION_CHANNEL_ID = "galaxy_vpn_tunnel"
        private const val NOTIFICATION_ID = 1001

        const val ACTION_CONNECT = "com.galaxyvpn.action.CONNECT"
        const val ACTION_DISCONNECT = "com.galaxyvpn.action.DISCONNECT"
        const val EXTRA_HOSTNAME = "hostname"
        const val EXTRA_ADDRESS = "address"
        const val EXTRA_PORT = "port"
        const val EXTRA_USERNAME = "username"
        const val EXTRA_PASSWORD = "password"
        const val EXTRA_SERVER_NAME = "serverName"

        /** Set on the main thread by [MainActivity]. */
        @Volatile
        var eventSink: EventChannel.EventSink? = null

        @Volatile
        var currentState: String = "disconnected"
            private set

        private val mainHandler = Handler(Looper.getMainLooper())

        private fun emit(event: Map<String, Any>) {
            mainHandler.post { eventSink?.success(event) }
        }
    }

    private var tunnel: SstpTunnel? = null
    private var serverName = ""
    private var connectedAt = 0L

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_CONNECT -> {
                serverName = intent.getStringExtra(EXTRA_SERVER_NAME) ?: "VPN relay"
                startForegroundCompat(buildNotification("Connecting to $serverName…"))
                startTunnel(
                    SstpTunnel.Config(
                        hostname = intent.getStringExtra(EXTRA_HOSTNAME) ?: "",
                        address = intent.getStringExtra(EXTRA_ADDRESS) ?: "",
                        port = intent.getIntExtra(EXTRA_PORT, 443),
                        username = intent.getStringExtra(EXTRA_USERNAME) ?: "vpn",
                        password = intent.getStringExtra(EXTRA_PASSWORD) ?: "vpn",
                        sessionName = serverName,
                    ),
                )
            }
            ACTION_DISCONNECT -> stopTunnel()
        }
        return START_NOT_STICKY
    }

    private fun startTunnel(config: SstpTunnel.Config) {
        tunnel?.stop()
        emitState("connecting")

        lateinit var session: SstpTunnel
        session = SstpTunnel(this, config, object : SstpTunnel.Listener {
            override fun onConnected(assignedIp: String) {
                if (tunnel !== session) return
                connectedAt = SystemClock.elapsedRealtime()
                Log.i(TAG, "SSTP tunnel up via ${config.hostname} ($assignedIp)")
                notify(buildNotification("Connected to $serverName"))
                emitState("connected")
            }

            override fun onTraffic(bytesIn: Long, bytesOut: Long) {
                if (tunnel !== session || connectedAt == 0L) return
                val seconds = (SystemClock.elapsedRealtime() - connectedAt) / 1000
                emit(
                    mapOf(
                        "type" to "metrics",
                        "byteIn" to bytesIn,
                        "byteOut" to bytesOut,
                        "duration" to "%02d:%02d".format(seconds / 60, seconds % 60),
                    ),
                )
            }
        })
        tunnel = session
        connectedAt = 0L

        Thread({
            var failure: Pair<String, String>? = null
            try {
                session.run()
                if (!session.wasStopped) failure = "dropped" to "The relay closed the connection."
            } catch (e: Exception) {
                if (!session.wasStopped) {
                    Log.w(TAG, "SSTP tunnel failed: $e")
                    failure = describe(e)
                }
            }
            mainHandler.post { onTunnelEnded(session, failure) }
        }, "sstp-session").apply { isDaemon = true; start() }
    }

    private fun onTunnelEnded(session: SstpTunnel, failure: Pair<String, String>?) {
        // A newer session replaced this one; it owns the state now.
        if (tunnel !== session) return
        tunnel = null
        connectedAt = 0L
        if (failure != null) {
            emitState("error", failure.second, failure.first)
        } else {
            emitState("disconnected")
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun stopTunnel() {
        val session = tunnel
        if (session == null) {
            emitState("disconnected")
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        emitState("disconnecting")
        session.stop()
    }

    /**
     * Maps a failure to (code, message). `unreachable` means no TCP connection
     * could be made at all, so retrying the same endpoint is pointless.
     */
    private fun describe(e: Exception): Pair<String, String> = when (e) {
        is SstpTunnel.SstpException -> "rejected" to (e.message ?: "The relay rejected the connection.")
        is SSLException -> "tls" to "Secure handshake with the relay failed."
        is SocketTimeoutException ->
            (if (e.message?.contains("failed to connect") == true) "unreachable" else "timeout") to
                "The relay did not respond in time."
        is ConnectException -> "unreachable" to "The relay refused the connection."
        is UnknownHostException -> "unreachable" to "The relay address could not be resolved."
        else -> "failed" to "Connection to the relay failed (${e.javaClass.simpleName})."
    }

    private fun emitState(state: String, error: String? = null, code: String? = null) {
        currentState = state
        val event = mutableMapOf<String, Any>("type" to "state", "state" to state)
        if (error != null) event["error"] = error
        if (code != null) event["code"] = code
        emit(event)
    }

    // ── Notification ────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "VPN connection",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows while Galaxy VPN is protecting your connection"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): Notification {
        val openApp = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val disconnect = PendingIntent.getService(
            this, 1, Intent(this, GalaxyVpnService::class.java).setAction(ACTION_DISCONNECT),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        @Suppress("DEPRECATION")
        return builder
            .setContentTitle("Galaxy VPN")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(openApp)
            .addAction(Notification.Action.Builder(null, "Disconnect", disconnect).build())
            .setOngoing(true)
            .build()
    }

    private fun notify(notification: Notification) {
        getSystemService(NotificationManager::class.java)?.notify(NOTIFICATION_ID, notification)
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onRevoke() {
        Log.w(TAG, "VPN permission revoked by the system.")
        stopTunnel()
        super.onRevoke()
    }

    override fun onDestroy() {
        val session = tunnel
        tunnel = null
        if (session != null) {
            session.stop()
            emitState("disconnected")
        }
        super.onDestroy()
    }
}
