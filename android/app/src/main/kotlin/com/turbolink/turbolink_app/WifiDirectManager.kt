package com.turbolink.turbolink_app

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * "Max Speed" discovery backend using Wi-Fi Direct (Wi-Fi P2P).
 *
 * Wi-Fi Direct creates a dedicated P2P group, giving maximum throughput
 * at the cost of the station (internet) Wi-Fi connection. The kernel
 * uses its own P2P interface (p2p0 / p2p-wlan0-0), so the underlying
 * channel is fully dedicated to TurboLink traffic.
 *
 * Flow:
 *  1. [startDiscovery] -> [WifiP2pManager.discoverPeers]
 *  2. System broadcasts [WIFI_P2P_PEERS_CHANGED_ACTION]
 *  3. We call [requestPeers] and push the list to [onPeersUpdated]
 *  4. [connectToPeer] builds a [WifiP2pConfig] and calls [manager.connect]
 */
class WifiDirectManager(
    private val context: Context,
    private val scope: CoroutineScope,
    private val onPeersUpdated: (List<Map<String, Any>>) -> Unit,
) {

    companion object {
        private const val TAG = "WifiDirectManager"
    }

    private val manager: WifiP2pManager =
        context.getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager

    private val channel: WifiP2pManager.Channel =
        manager.initialize(context, context.mainLooper, null)

    private val connectedDeviceAddresses = mutableSetOf<String>()
    private var latestDevices: List<WifiP2pDevice> = emptyList()
    private var receiver: BroadcastReceiver? = null

    // ── Public API ───────────────────────────────────────────────────

    @SuppressLint("MissingPermission")
    fun startDiscovery() {
        registerReceiver()
        manager.discoverPeers(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.d(TAG, "Peer discovery started")
            }
            override fun onFailure(reason: Int) {
                Log.e(TAG, "Peer discovery failed: reason=$reason")
            }
        })
    }

    fun stopDiscovery() {
        manager.stopPeerDiscovery(channel, null)
        unregisterReceiver()
        latestDevices = emptyList()
        Log.d(TAG, "Peer discovery stopped")
    }

    @SuppressLint("MissingPermission")
    suspend fun connectToPeer(peerId: String): Boolean {
        val device = latestDevices.find { it.deviceAddress == peerId }
            ?: return false

        return suspendCancellableCoroutine { cont ->
            val config = WifiP2pConfig().apply {
                deviceAddress = device.deviceAddress
            }
            manager.connect(channel, config, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    connectedDeviceAddresses.add(device.deviceAddress)
                    emitPeers()
                    Log.d(TAG, "Connected to ${device.deviceName}")
                    if (cont.isActive) cont.resume(true)
                }
                override fun onFailure(reason: Int) {
                    Log.e(TAG, "Connect failed: reason=$reason")
                    if (cont.isActive) cont.resume(false)
                }
            })
        }
    }

    fun disconnectFromPeer(peerId: String) {
        connectedDeviceAddresses.remove(peerId)
        manager.removeGroup(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                emitPeers()
                Log.d(TAG, "Disconnected from $peerId")
            }
            override fun onFailure(reason: Int) {
                Log.w(TAG, "Remove group failed: reason=$reason")
            }
        })
    }

    /**
     * Returns connection info (group owner IP, etc.) for active P2P link.
     * Used by [FileTransferEngine] to resolve the peer's address.
     */
    @SuppressLint("MissingPermission")
    fun requestConnectionInfo(callback: (WifiP2pInfo?) -> Unit) {
        manager.requestConnectionInfo(channel) { info -> callback(info) }
    }

    // ── Internal ─────────────────────────────────────────────────────

    @SuppressLint("MissingPermission")
    private fun registerReceiver() {
        val filter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
        }

        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                when (intent.action) {
                    WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                        manager.requestPeers(channel) { list: WifiP2pDeviceList ->
                            latestDevices = list.deviceList.toList()
                            emitPeers()
                        }
                    }
                    WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                        manager.requestPeers(channel) { list: WifiP2pDeviceList ->
                            latestDevices = list.deviceList.toList()
                            emitPeers()
                        }
                    }
                    WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                        val state = intent.getIntExtra(
                            WifiP2pManager.EXTRA_WIFI_STATE,
                            WifiP2pManager.WIFI_P2P_STATE_DISABLED,
                        )
                        if (state != WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                            Log.w(TAG, "Wi-Fi P2P is disabled")
                        }
                    }
                }
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
    }

    private fun unregisterReceiver() {
        receiver?.let {
            try { context.unregisterReceiver(it) }
            catch (_: IllegalArgumentException) { /* already unregistered */ }
        }
        receiver = null
    }

    /** Serialise peers as List<Map> for the Dart EventChannel. */
    private fun emitPeers() {
        val serialized = latestDevices.map { device ->
            mapOf<String, Any>(
                "id" to device.deviceAddress,
                "name" to (device.deviceName.ifBlank { "Unknown Device" }),
                "deviceType" to inferDeviceType(device),
                "signalStrength" to estimateSignalStrength(device),
                "isConnected" to connectedDeviceAddresses.contains(device.deviceAddress),
            )
        }
        onPeersUpdated(serialized)
    }

    /** Heuristic signal strength from device status (P2P has no RSSI). */
    private fun estimateSignalStrength(device: WifiP2pDevice): Double {
        return when (device.status) {
            WifiP2pDevice.CONNECTED -> 0.95
            WifiP2pDevice.INVITED -> 0.8
            WifiP2pDevice.AVAILABLE -> 0.6
            WifiP2pDevice.FAILED -> 0.2
            else -> 0.4
        }
    }

    /** Best-effort device type inference from primary device type string. */
    private fun inferDeviceType(device: WifiP2pDevice): String {
        val pdt = device.primaryDeviceType ?: return "phone"
        return when {
            pdt.contains("10-") -> "phone"
            pdt.contains("7-")  -> "tablet"
            pdt.contains("1-")  -> "laptop"
            else -> "phone"
        }
    }
}
