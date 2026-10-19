package com.shieldroute.vpn.shieldroute_vpn

import android.content.ComponentName
import android.content.Intent
import android.content.ServiceConnection
import android.net.VpnService
import android.os.IBinder
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL = "com.shieldroute.vpn/native_engine"
        private const val EVENT_CHANNEL = "com.shieldroute.vpn/events"
        private const val VPN_REQUEST_CODE = 1024
    }

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingConnectResult: MethodChannel.Result? = null
    private var pendingConnectArgs: Map<*, *>? = null

    private var vpnService: ShieldRouteVpnService? = null
    private var isServiceBound = false

    private var eventSink: EventChannel.EventSink? = null

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            val localBinder = binder as? ShieldRouteVpnService.LocalBinder
            vpnService = localBinder?.getService()
            isServiceBound = true
            vpnService?.setEventSink(eventSink)

            // If we had a pending connect, execute it now
            val args = pendingConnectArgs
            val result = pendingConnectResult
            pendingConnectArgs = null
            pendingConnectResult = null
            if (args != null && result != null) {
                doConnect(args, result)
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            vpnService = null
            isServiceBound = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    vpnService?.setEventSink(events)
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    vpnService?.setEventSink(null)
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepare" -> {
                        val intent = VpnService.prepare(this)
                        if (intent != null) {
                            pendingPermissionResult = result
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, VPN_REQUEST_CODE)
                        } else {
                            result.success(true)
                        }
                    }
                    "connect" -> {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("INVALID_ARGS", "Missing connection arguments", null)
                            return@setMethodCallHandler
                        }
                        if (!isServiceBound) {
                            pendingConnectArgs = args
                            pendingConnectResult = result
                            bindVpnService()
                        } else {
                            doConnect(args, result)
                        }
                    }
                    "disconnect" -> {
                        if (isServiceBound) {
                            vpnService?.disconnectVpn()
                        }
                        result.success(true)
                    }
                    "getState" -> {
                        val state = vpnService?.getConnectionState() ?: "disconnected"
                        result.success(state)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun bindVpnService() {
        val intent = Intent(this, ShieldRouteVpnService::class.java)
        bindService(intent, serviceConnection, BIND_AUTO_CREATE)
    }

    private fun doConnect(args: Map<*, *>, result: MethodChannel.Result) {
        val serverHost = args["serverHost"] as? String ?: ""
        val serverName = args["serverName"] as? String ?: "VPN Server"
        val countryCode = args["countryCode"] as? String ?: "US"

        try {
            vpnService?.connectVpn(serverHost, serverName, countryCode)
            result.success(true)
        } catch (e: Exception) {
            result.error("CONNECT_FAILED", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE) {
            val granted = resultCode == RESULT_OK
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null

            // If permission granted and there's a pending connect, proceed
            if (granted) {
                val args = pendingConnectArgs
                val result = pendingConnectResult
                pendingConnectArgs = null
                pendingConnectResult = null
                if (args != null && result != null) {
                    if (!isServiceBound) {
                        pendingConnectArgs = args
                        pendingConnectResult = result
                        bindVpnService()
                    } else {
                        doConnect(args, result)
                    }
                }
            }
        }

        if (requestCode == 24) {
            OpenVPNFlutterPlugin.connectWhileGranted(resultCode == RESULT_OK)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        if (isServiceBound) {
            unbindService(serviceConnection)
            isServiceBound = false
        }
        super.onDestroy()
    }
}
