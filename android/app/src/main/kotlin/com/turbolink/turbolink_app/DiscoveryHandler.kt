package com.turbolink.turbolink_app

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Routes Flutter MethodChannel calls to the active discovery backend
 * (Wi-Fi Direct or Wi-Fi Aware) and pushes peer updates to the EventChannel.
 *
 * Modes:
 *  - "max_speed"    → [WifiDirectManager]  (Wi-Fi P2P, full bandwidth, drops internet)
 *  - "keep_internet"→ [WifiAwareManager]   (NAN interface, keeps station Wi-Fi)
 *
 * Default: Wi-Fi Direct ("max_speed").
 */
class DiscoveryHandler(
    private val activity: Activity,
    private val scope: CoroutineScope,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val TAG = "DiscoveryHandler"
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    // Peer update sink — pushed from WifiDirectManager / WifiAwareManager.
    private var eventSink: EventChannel.EventSink? = null

    // Active discovery backend.
    private var wifiDirectManager: WifiDirectManager? = null
    private var wifiAwareManager: WifiAwareManagerWrapper? = null

    private var currentMode = "max_speed" // or "keep_internet"

    // ── MethodChannel handler ────────────────────────────────────────
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setMode" -> {
                currentMode = call.argument<String>("mode") ?: "max_speed"
                Log.d(TAG, "Discovery mode set to: $currentMode")
                result.success(true)
            }

            "startDiscovery" -> {
                scope.launch {
                    if (!ensurePermissions()) {
                        result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                        return@launch
                    }
                    startDiscoveryInternal()
                    result.success(true)
                }
            }

            "stopDiscovery" -> {
                stopDiscoveryInternal()
                result.success(true)
            }

            "connectToPeer" -> {
                val peerId = call.argument<String>("peerId")
                if (peerId == null) {
                    result.error("INVALID_ARG", "peerId is required", null)
                    return
                }
                scope.launch {
                    val success = connectToPeerInternal(peerId)
                    result.success(success)
                }
            }

            "disconnectFromPeer" -> {
                val peerId = call.argument<String>("peerId")
                if (peerId == null) {
                    result.error("INVALID_ARG", "peerId is required", null)
                    return
                }
                disconnectFromPeerInternal(peerId)
                result.success(true)
            }

            "getConnectionInfo" -> {
                // Used by Dart FFI to get the IP address of the peer to start the C++ UDP socket.
                if (currentMode == "max_speed" && wifiDirectManager != null) {
                    wifiDirectManager?.requestConnectionInfo { info ->
                        if (info != null && info.groupOwnerAddress != null) {
                            val ip = info.groupOwnerAddress.hostAddress
                            val isServer = info.isGroupOwner
                            
                            val resultMap = mapOf(
                                "ip" to ip,
                                "port" to 42069, // Default UDP port
                                "isServer" to isServer,
                                "key" to null // Derived key placeholder
                            )
                            result.success(resultMap)
                        } else {
                            result.error("NO_CONNECTION", "No active P2P connection", null)
                        }
                    }
                } else {
                    // TODO: Implement Wi-Fi Aware IP resolution (requires NDP network request)
                    result.error("NOT_SUPPORTED", "Aware IP resolution not fully implemented", null)
                }
            }

            "openFileDescriptor" -> {
                val uriStr = call.argument<String>("uri")
                val mode = call.argument<String>("mode") ?: "r"
                if (uriStr == null) {
                    result.error("INVALID_ARG", "uri is required", null)
                    return
                }
                try {
                    val uri = android.net.Uri.parse(uriStr)
                    val fd = activity.contentResolver.openFileDescriptor(uri, mode)
                    if (fd != null) {
                        result.success(fd.detachFd()) // Pass the raw int FD to Dart FFI
                    } else {
                        result.error("FD_ERROR", "Failed to open file descriptor", null)
                    }
                } catch (e: Exception) {
                    result.error("FD_EXCEPTION", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    // ── EventChannel StreamHandler ───────────────────────────────────
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Log.d(TAG, "EventChannel listener attached")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.d(TAG, "EventChannel listener detached")
    }

    // ── Internal discovery logic ─────────────────────────────────────
    private fun startDiscoveryInternal() {
        stopDiscoveryInternal() // Clean up any previous session.

        val peerCallback = { peers: List<Map<String, Any>> ->
            activity.runOnUiThread {
                eventSink?.success(peers)
            }
        }

        when (currentMode) {
            "keep_internet" -> {
                wifiAwareManager = WifiAwareManagerWrapper(activity, scope, peerCallback)
                wifiAwareManager?.startDiscovery()
                Log.d(TAG, "Started Wi-Fi Aware discovery (Keep Internet)")
            }
            else -> {
                wifiDirectManager = WifiDirectManager(activity, scope, peerCallback)
                wifiDirectManager?.startDiscovery()
                Log.d(TAG, "Started Wi-Fi Direct discovery (Max Speed)")
            }
        }
    }

    private fun stopDiscoveryInternal() {
        wifiDirectManager?.stopDiscovery()
        wifiDirectManager = null
        wifiAwareManager?.stopDiscovery()
        wifiAwareManager = null
    }

    private suspend fun connectToPeerInternal(peerId: String): Boolean {
        return when (currentMode) {
            "keep_internet" -> wifiAwareManager?.connectToPeer(peerId) ?: false
            else -> wifiDirectManager?.connectToPeer(peerId) ?: false
        }
    }

    private fun disconnectFromPeerInternal(peerId: String) {
        when (currentMode) {
            "keep_internet" -> wifiAwareManager?.disconnectFromPeer(peerId)
            else -> wifiDirectManager?.disconnectFromPeer(peerId)
        }
    }

    // ── Permissions ──────────────────────────────────────────────────
    private fun ensurePermissions(): Boolean {
        val needed = mutableListOf<String>()

        // Location (required for Wi-Fi scanning on all API levels).
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED
        ) {
            needed.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }

        // NEARBY_WIFI_DEVICES (Android 13+, replaces location for Wi-Fi P2P).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.NEARBY_WIFI_DEVICES)
                != PackageManager.PERMISSION_GRANTED
            ) {
                needed.add(Manifest.permission.NEARBY_WIFI_DEVICES)
            }
        }

        if (needed.isEmpty()) return true

        ActivityCompat.requestPermissions(
            activity,
            needed.toTypedArray(),
            PERMISSION_REQUEST_CODE,
        )
        // For simplicity, return false so the caller retries after the user grants.
        // In production you'd use an ActivityResultLauncher callback.
        return false
    }

    // ── Cleanup ──────────────────────────────────────────────────────
    fun cleanup() {
        stopDiscoveryInternal()
        eventSink = null
    }
}
