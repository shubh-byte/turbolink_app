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
    private lateinit var transferHandler: TransferHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ── Discovery channels ───────────────────────────────────────
        val discoveryMethod = MethodChannel(messenger, "turbolink/discovery")
        val discoveryEvent = EventChannel(messenger, "turbolink/discovery/peers")

        discoveryHandler = DiscoveryHandler(this, scope)
        discoveryMethod.setMethodCallHandler(discoveryHandler)
        discoveryEvent.setStreamHandler(discoveryHandler)

        // ── Transfer channels ────────────────────────────────────────
        val transferMethod = MethodChannel(messenger, "turbolink/transfer")
        val transferProgress = EventChannel(messenger, "turbolink/transfer/progress")
        val transferAll = EventChannel(messenger, "turbolink/transfer/all")

        transferHandler = TransferHandler(this, scope)
        transferMethod.setMethodCallHandler(transferHandler)
        transferProgress.setStreamHandler(transferHandler.progressStreamHandler)
        transferAll.setStreamHandler(transferHandler.allTransfersStreamHandler)
    }

    override fun onDestroy() {
        if (::discoveryHandler.isInitialized) discoveryHandler.cleanup()
        if (::transferHandler.isInitialized) transferHandler.cleanup()
        scope.cancel()
        super.onDestroy()
    }
}
