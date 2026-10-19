package com.shieldroute.vpn.shieldroute_vpn

import android.content.Intent
import android.net.VpnService
import android.os.Build
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    ShieldRouteVpnService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    ShieldRouteVpnService.eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepare" -> {
                        val intent = VpnService.prepare(this)
                        if (intent == null) {
                            result.success(true)
                        } else if (pendingPermissionResult != null) {
                            result.success(false)
                        } else {
                            pendingPermissionResult = result
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, VPN_REQUEST_CODE)
                        }
                    }
                    "connect" -> {
                        if (VpnService.prepare(this) != null) {
                            result.error("PERMISSION", "VPN permission has not been granted", null)
                            return@setMethodCallHandler
                        }
                        val intent = Intent(this, ShieldRouteVpnService::class.java)
                            .setAction(ShieldRouteVpnService.ACTION_CONNECT)
                            .putExtra(ShieldRouteVpnService.EXTRA_HOSTNAME, call.argument<String>("hostname"))
                            .putExtra(ShieldRouteVpnService.EXTRA_ADDRESS, call.argument<String>("address"))
                            .putExtra(ShieldRouteVpnService.EXTRA_PORT, call.argument<Int>("port") ?: 443)
                            .putExtra(ShieldRouteVpnService.EXTRA_USERNAME, call.argument<String>("username"))
                            .putExtra(ShieldRouteVpnService.EXTRA_PASSWORD, call.argument<String>("password"))
                            .putExtra(ShieldRouteVpnService.EXTRA_SERVER_NAME, call.argument<String>("serverName"))
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "disconnect" -> {
                        if (ShieldRouteVpnService.currentState != "disconnected") {
                            startService(
                                Intent(this, ShieldRouteVpnService::class.java)
                                    .setAction(ShieldRouteVpnService.ACTION_DISCONNECT),
                            )
                        }
                        result.success(true)
                    }
                    "getState" -> result.success(ShieldRouteVpnService.currentState)
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE) {
            pendingPermissionResult?.success(resultCode == RESULT_OK)
            pendingPermissionResult = null
        }
        // OpenVPN permission results (request code 24) are handled by the
        // axevpn_flutter plugin's own ActivityResultListener.
        super.onActivityResult(requestCode, resultCode, data)
    }
}
