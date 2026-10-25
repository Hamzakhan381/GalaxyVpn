package com.shieldroute.vpn.shieldroute_vpn

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.axevpn.flutter.openvpn.AxeVPNFlutterPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val ENGINE_ID = "galaxy_vpn_engine"
        private const val METHOD_CHANNEL = "com.galaxyvpn/native_engine"
        private const val EVENT_CHANNEL = "com.galaxyvpn/events"
        private const val VPN_REQUEST_CODE = 1024
        private const val NOTIFICATION_REQUEST_CODE = 1025

        /** Under ~4 GB of RAM (Android reports a little less than installed). */
        private const val LOW_END_RAM_BYTES = 3_700_000_000L

        /** Fastest core below 2.05 GHz: budget SoCs (Unisoc T6xx, Helio G8x). */
        private const val LOW_END_MAX_CPU_KHZ = 2_050_000L

        private val mainHandler = Handler(Looper.getMainLooper())

        /** The visible activity, for calls that need one (dialogs, results). */
        private var current: MainActivity? = null

        private var pendingPermissionResult: MethodChannel.Result? = null
        private var pendingNotificationResult: MethodChannel.Result? = null
        private var vpnPluginAttached = false
        private val vpnPluginWaiters = mutableListOf<MethodChannel.Result>()

        @Volatile
        private var lowEndCache: Boolean? = null

        /**
         * Budget phone: little memory, or slow cores. Such phones get the
         * OpenGL ES renderer and lighter animations.
         */
        fun isLowEndDevice(context: Context): Boolean = lowEndCache ?: run {
            val am = context.getSystemService(ActivityManager::class.java)
            val memory = ActivityManager.MemoryInfo().also { am?.getMemoryInfo(it) }
            val maxCpuKhz = (0 until Runtime.getRuntime().availableProcessors()).maxOfOrNull { core ->
                runCatching {
                    File("/sys/devices/system/cpu/cpu$core/cpufreq/cpuinfo_max_freq")
                        .readText().trim().toLong()
                }.getOrDefault(0L)
            } ?: 0L
            (am?.isLowRamDevice == true ||
                memory.totalMem in 1 until LOW_END_RAM_BYTES ||
                maxCpuKhz in 1 until LOW_END_MAX_CPU_KHZ).also { lowEndCache = it }
        }
    }

    /**
     * Budget GPUs often ship Vulkan drivers that stall Flutter's first frame,
     * leaving the app on Android's launch screen. OpenGL ES is the reliable
     * path there, and lazy shader setup spreads the GPU's start-up work out.
     */
    override fun getFlutterShellArgs(): FlutterShellArgs {
        val args = super.getFlutterShellArgs()
        if (isLowEndDevice(this)) {
            args.add("--impeller-backend=opengles")
            args.add("--impeller-lazy-shader-mode")
        }
        return args
    }

    /**
     * One engine for the life of the process, reused by every activity. The
     * VPN service keeps the process alive after the app is swiped away; a new
     * engine there restarted the whole app from its splash (and under a
     * debugger never started at all), while the kept engine reopens instantly
     * on the live connection.
     */
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        FlutterEngineCache.getInstance().get(ENGINE_ID)?.let { return it }
        val engine = FlutterEngine(
            applicationContext,
            getFlutterShellArgs().toArray(),
            /* automaticallyRegisterPlugins = */ false,
        )
        // Registered here rather than by the generated registrant: the VPN
        // plugin loads several native libraries and boots WireGuard's Go
        // runtime when attached, which on the main thread kept low-end phones
        // on the launch screen. It attaches once that work has finished on a
        // background thread.
        engine.plugins.add(SharedPreferencesPlugin())
        attachVpnPluginInBackground(engine)
        setUpChannels(engine)
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        return engine
    }

    /** Plugins and channels are set up once, with the engine. */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {}

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        current = this
        super.onCreate(savedInstanceState)
    }

    override fun onResume() {
        super.onResume()
        current = this
    }

    override fun onDestroy() {
        if (current === this) current = null
        super.onDestroy()
    }

    private fun setUpChannels(engine: FlutterEngine) {
        val appContext = applicationContext
        EventChannel(engine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    GalaxyVpnService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    GalaxyVpnService.eventSink = null
                }
            })

        MethodChannel(engine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                val activity = current
                when (call.method) {
                    "prepare" -> {
                        val intent = VpnService.prepare(appContext)
                        if (intent == null) {
                            result.success(true)
                        } else if (activity == null || pendingPermissionResult != null) {
                            result.success(false)
                        } else {
                            pendingPermissionResult = result
                            @Suppress("DEPRECATION")
                            activity.startActivityForResult(intent, VPN_REQUEST_CODE)
                        }
                    }
                    "connect" -> {
                        if (VpnService.prepare(appContext) != null) {
                            result.error("PERMISSION", "VPN permission has not been granted", null)
                            return@setMethodCallHandler
                        }
                        val intent = Intent(appContext, GalaxyVpnService::class.java)
                            .setAction(GalaxyVpnService.ACTION_CONNECT)
                            .putExtra(GalaxyVpnService.EXTRA_HOSTNAME, call.argument<String>("hostname"))
                            .putExtra(GalaxyVpnService.EXTRA_ADDRESS, call.argument<String>("address"))
                            .putExtra(GalaxyVpnService.EXTRA_PORT, call.argument<Int>("port") ?: 443)
                            .putExtra(GalaxyVpnService.EXTRA_USERNAME, call.argument<String>("username"))
                            .putExtra(GalaxyVpnService.EXTRA_PASSWORD, call.argument<String>("password"))
                            .putExtra(GalaxyVpnService.EXTRA_SERVER_NAME, call.argument<String>("serverName"))
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            appContext.startForegroundService(intent)
                        } else {
                            appContext.startService(intent)
                        }
                        result.success(true)
                    }
                    "disconnect" -> {
                        if (GalaxyVpnService.currentState != "disconnected") {
                            appContext.startService(
                                Intent(appContext, GalaxyVpnService::class.java)
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
                        val launcher: Context = activity ?: appContext
                        fun open(action: String) = runCatching {
                            launcher.startActivity(
                                Intent(action).apply {
                                    if (launcher !is Activity) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                },
                            )
                        }.isSuccess
                        result.success(
                            open(Settings.ACTION_VPN_SETTINGS) || open(Settings.ACTION_WIRELESS_SETTINGS),
                        )
                    }
                    // Back on the home screen: keep the app alive in the
                    // background instead of finishing it.
                    "moveToBackground" -> result.success(activity?.moveTaskToBack(true) ?: false)
                    "isLowEndDevice" -> result.success(isLowEndDevice(appContext))
                    // Android 13+ hides the connection notification (and its
                    // Disconnect action) until this is granted.
                    "requestNotificationPermission" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                            appContext.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            result.success(true)
                        } else if (activity == null || pendingNotificationResult != null) {
                            result.success(false)
                        } else {
                            pendingNotificationResult = result
                            activity.requestPermissions(
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
            mainHandler.post {
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
