package com.turbolink.turbolink_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * TurboLink entry point. Registers the MethodChannel/EventChannel handlers
 * that bridge Agent 2's Flutter UI to the native Kotlin backend.
 *
 * Lifecycle: creates a [SupervisorJob]-backed [CoroutineScope] so that
 * any in-flight coroutine (discovery, transfer) is cancelled cleanly when
 * the Activity is destroyed.
 */
class MainActivity : FlutterActivity() {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private lateinit var discoveryHandler: DiscoveryHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ── Discovery channels ───────────────────────────────────────
        val discoveryMethod = MethodChannel(messenger, "turbolink/discovery")
        val discoveryEvent = EventChannel(messenger, "turbolink/discovery/peers")

        discoveryHandler = DiscoveryHandler(this, scope)
        discoveryMethod.setMethodCallHandler(discoveryHandler)
        discoveryEvent.setStreamHandler(discoveryHandler)
    }

    override fun onDestroy() {
        if (::discoveryHandler.isInitialized) discoveryHandler.cleanup()
        scope.cancel()
        super.onDestroy()
    }
}
