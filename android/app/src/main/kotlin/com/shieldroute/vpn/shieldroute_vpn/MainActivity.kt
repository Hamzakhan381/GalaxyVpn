package com.shieldroute.vpn.shieldroute_vpn

import android.Manifest
import android.app.ActivityManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.provider.Settings
import com.axevpn.flutter.openvpn.AxeVPNFlutterPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL = "com.galaxyvpn/native_engine"
        private const val EVENT_CHANNEL = "com.galaxyvpn/events"
        private const val VPN_REQUEST_CODE = 1024
        private const val NOTIFICATION_REQUEST_CODE = 1025

        /** Under ~3 GB of RAM (Android reports a little less than installed). */
        private const val LOW_END_RAM_BYTES = 3_200_000_000L
    }

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingNotificationResult: MethodChannel.Result? = null

    private var vpnPluginAttached = false
    private val vpnPluginWaiters = mutableListOf<MethodChannel.Result>()

    private val isLowEndDevice: Boolean by lazy {
        val am = getSystemService(ActivityManager::class.java)
        val memory = ActivityManager.MemoryInfo().also { am?.getMemoryInfo(it) }
        am?.isLowRamDevice == true || memory.totalMem in 1 until LOW_END_RAM_BYTES
    }

    /**
     * Budget GPUs often ship Vulkan drivers that stall Flutter's first frame,
     * leaving the app on Android's launch screen. OpenGL ES is the reliable
     * path there, and lazy shader setup spreads the GPU's start-up work out.
     */
    override fun getFlutterShellArgs(): FlutterShellArgs {
        val args = super.getFlutterShellArgs()
        if (isLowEndDevice) {
            args.add("--impeller-backend=opengles")
            args.add("--impeller-lazy-shader-mode")
        }
        return args
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Plugins are registered here rather than by super's generated
        // registrant: the VPN plugin loads several native libraries and boots
        // WireGuard's Go runtime when attached, which on the main thread kept
        // low-end phones on the launch screen. It attaches once that work has
        // finished on a background thread.
        flutterEngine.plugins.add(SharedPreferencesPlugin())
        attachVpnPluginInBackground(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    GalaxyVpnService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    GalaxyVpnService.eventSink = null
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
                        val intent = Intent(this, GalaxyVpnService::class.java)
                            .setAction(GalaxyVpnService.ACTION_CONNECT)
                            .putExtra(GalaxyVpnService.EXTRA_HOSTNAME, call.argument<String>("hostname"))
                            .putExtra(GalaxyVpnService.EXTRA_ADDRESS, call.argument<String>("address"))
                            .putExtra(GalaxyVpnService.EXTRA_PORT, call.argument<Int>("port") ?: 443)
                            .putExtra(GalaxyVpnService.EXTRA_USERNAME, call.argument<String>("username"))
                            .putExtra(GalaxyVpnService.EXTRA_PASSWORD, call.argument<String>("password"))
                            .putExtra(GalaxyVpnService.EXTRA_SERVER_NAME, call.argument<String>("serverName"))
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "disconnect" -> {
                        if (GalaxyVpnService.currentState != "disconnected") {
                            startService(
                                Intent(this, GalaxyVpnService::class.java)
                                    .setAction(GalaxyVpnService.ACTION_DISCONNECT),
                            )
                        }
                        result.success(true)
                    }
                    "getState" -> result.success(GalaxyVpnService.currentState)
                    // Completes once the OpenVPN plugin is attached.
                    "waitForVpnEngine" -> {
                        if (vpnPluginAttached) result.success(true) else vpnPluginWaiters.add(result)
                    }
                    // Android's VPN screen, where Always-on VPN and "Block
                    // connections without VPN" (the system kill switch) live.
                    "openVpnSettings" -> {
                        val opened = runCatching {
                            startActivity(Intent(Settings.ACTION_VPN_SETTINGS))
                        }.isSuccess || runCatching {
                            startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS))
                        }.isSuccess
                        result.success(opened)
                    }
                    // Back on the home screen: keep the app (and its engine)
                    // alive in the background instead of finishing it, so
                    // reopening is instant and shows the live connection.
                    "moveToBackground" -> result.success(moveTaskToBack(true))
                    // Phones with little memory get lighter animations.
                    "isLowEndDevice" -> result.success(isLowEndDevice)
                    // Android 13+ hides the connection notification (and its
                    // Disconnect action) until this is granted.
                    "requestNotificationPermission" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            result.success(true)
                        } else if (pendingNotificationResult != null) {
                            result.success(false)
                        } else {
                            pendingNotificationResult = result
                            requestPermissions(
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                NOTIFICATION_REQUEST_CODE,
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun attachVpnPluginInBackground(engine: FlutterEngine) {
        Thread({
            // Initialising the plugin class runs its System.loadLibrary calls;
            // GoBackend (created on attach) loads and boots WireGuard's Go
            // runtime, so preload that library here too.
            runCatching { Class.forName(AxeVPNFlutterPlugin::class.java.name) }
            runCatching { System.loadLibrary("wg-go") }
            runOnUiThread {
                if (isDestroyed) return@runOnUiThread
                runCatching { engine.plugins.add(AxeVPNFlutterPlugin()) }
                    .onFailure { android.util.Log.e("MainActivity", "VPN plugin attach failed", it) }
                vpnPluginAttached = true
                vpnPluginWaiters.forEach { it.success(true) }
                vpnPluginWaiters.clear()
            }
        }, "vpn-plugin-init").start()
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
    ) {
        if (requestCode == NOTIFICATION_REQUEST_CODE) {
            pendingNotificationResult?.success(
                grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
            )
            pendingNotificationResult = null
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
