package com.turbolink.turbolink_app

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import java.util.UUID

/**
 * Handles Flutter MethodChannel calls for file transfers and pushes
 * progress updates to EventChannel sinks.
 *
 * Transfer lifecycle:
 *  1. Flutter calls "sendFile" with {peerId, filePath, fileName, fileSizeBytes}
 *  2. We create a [FileTransferEngine.sendFile] job
 *  3. Progress updates are pushed to the per-transfer EventChannel
 *  4. The full transfer list is pushed to the "all transfers" EventChannel
 *
 * Internally maintains a [transferList] that mirrors what Dart expects.
 */
class TransferHandler(
    private val activity: Activity,
    private val scope: CoroutineScope,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "TransferHandler"
    }

    private val engine = FileTransferEngine(scope)

    // Master list of all transfers (active + completed).
    private val transferList = mutableListOf<Map<String, Any>>()

    // ── EventChannel stream handlers ─────────────────────────────────

    /** Per-transfer progress sink. */
    val progressStreamHandler = object : EventChannel.StreamHandler {
        var sink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            sink = events
        }

        override fun onCancel(arguments: Any?) {
            sink = null
        }
    }

    /** Full transfer-list sink ("all transfers"). */
    val allTransfersStreamHandler = object : EventChannel.StreamHandler {
        var sink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            sink = events
            // Emit current state immediately on subscribe.
            emitAllTransfers()
        }

        override fun onCancel(arguments: Any?) {
            sink = null
        }
    }

    // ── MethodChannel handler ────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sendFile" -> {
                val peerId = call.argument<String>("peerId") ?: ""
                val peerName = call.argument<String>("peerName") ?: ""
                val filePath = call.argument<String>("filePath") ?: ""
                val fileName = call.argument<String>("fileName") ?: ""
                val fileSizeBytes = call.argument<Number>("fileSizeBytes")?.toLong() ?: 0L

                if (filePath.isBlank() || fileName.isBlank()) {
                    result.error("INVALID_ARG", "filePath and fileName required", null)
                    return
                }

                val transferId = UUID.randomUUID().toString()
                startSend(transferId, peerId, peerName, filePath, fileName, fileSizeBytes)
                result.success(transferId)
            }

            "cancelTransfer" -> {
                val transferId = call.argument<String>("transferId") ?: ""
                cancelTransfer(transferId)
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    // ── Internal ─────────────────────────────────────────────────────

    private fun startSend(
        transferId: String,
        peerId: String,
        peerName: String,
        filePath: String,
        fileName: String,
        fileSizeBytes: Long,
    ) {
        // Add to master list as "active".
        val entry = mutableMapOf<String, Any>(
            "id" to transferId,
            "fileName" to fileName,
            "fileSizeBytes" to fileSizeBytes,
            "progress" to 0.0,
            "speedBytesPerSec" to 0.0,
            "status" to "active",
            "direction" to "sending",
            "peerId" to peerId,
            "peerName" to peerName,
        )
        transferList.add(entry)
        emitAllTransfers()

        engine.sendFile(
            transferId = transferId,
            filePath = filePath,
            fileName = fileName,
            fileSizeBytes = fileSizeBytes,
            peerAddress = null, // Will be resolved by the P2P connection info.
            onProgress = { bytesTransferred, totalBytes, speedBps ->
                val progress = bytesTransferred.toDouble() / totalBytes.toDouble()
                updateTransfer(transferId, progress, speedBps, "active")

                // Push per-transfer progress event.
                val progressMap = mapOf(
                    "id" to transferId,
                    "progress" to progress,
                    "speedBytesPerSec" to speedBps,
                    "status" to "active",
                )
                progressStreamHandler.sink?.success(progressMap)
            },
            onComplete = {
                updateTransfer(transferId, 1.0, 0.0, "completed")
                val completeMap = mapOf(
                    "id" to transferId,
                    "progress" to 1.0,
                    "speedBytesPerSec" to 0.0,
                    "status" to "completed",
                )
                progressStreamHandler.sink?.success(completeMap)
                Log.d(TAG, "[$transferId] Transfer complete")
            },
            onError = { errorMsg ->
                updateTransfer(transferId, 0.0, 0.0, "failed")
                val errorMap = mapOf(
                    "id" to transferId,
                    "progress" to 0.0,
                    "speedBytesPerSec" to 0.0,
                    "status" to "failed",
                    "error" to errorMsg,
                )
                progressStreamHandler.sink?.success(errorMap)
                Log.e(TAG, "[$transferId] Transfer failed: $errorMsg")
            },
        )
    }

    private fun cancelTransfer(transferId: String) {
        engine.cancelTransfer(transferId)
        updateTransfer(transferId, 0.0, 0.0, "failed")
    }

    private fun updateTransfer(
        transferId: String,
        progress: Double,
        speed: Double,
        status: String,
    ) {
        val idx = transferList.indexOfFirst { (it["id"] as? String) == transferId }
        if (idx >= 0) {
            val updated = transferList[idx].toMutableMap()
            updated["progress"] = progress
            updated["speedBytesPerSec"] = speed
            updated["status"] = status
            transferList[idx] = updated
            emitAllTransfers()
        }
    }

    private fun emitAllTransfers() {
        activity.runOnUiThread {
            allTransfersStreamHandler.sink?.success(transferList.toList())
        }
    }

    // ── Cleanup ──────────────────────────────────────────────────────

    fun cleanup() {
        engine.cancelAll()
        transferList.clear()
    }
}
