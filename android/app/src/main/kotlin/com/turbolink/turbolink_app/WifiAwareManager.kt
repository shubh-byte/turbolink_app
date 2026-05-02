package com.turbolink.turbolink_app

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.NetworkSpecifier
import android.net.wifi.aware.AttachCallback
import android.net.wifi.aware.DiscoverySessionCallback
import android.net.wifi.aware.PeerHandle
import android.net.wifi.aware.PublishConfig
import android.net.wifi.aware.PublishDiscoverySession
import android.net.wifi.aware.SubscribeConfig
import android.net.wifi.aware.SubscribeDiscoverySession
import android.net.wifi.aware.WifiAwareManager
import android.net.wifi.aware.WifiAwareSession
import android.os.Build
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * "Keep Internet" discovery backend using Wi-Fi Aware (NAN).
 *
 * Wi-Fi Aware operates on the NAN (Neighbor Awareness Networking) interface,
 * which is separate from the station (STA) interface. This means the device
 * can discover and transfer files while staying connected to a regular Wi-Fi
 * network for internet access.
 *
 * Flow:
 *  1. Attach to the Wi-Fi Aware system service
 *  2. Publish a "turbolink" service and simultaneously subscribe
 *  3. On service discovered → add peer to the list
 *  4. On connect → create a NetworkSpecifier → request network
 */
class WifiAwareManagerWrapper(
    private val context: Context,
    private val scope: CoroutineScope,
    private val onPeersUpdated: (List<Map<String, Any>>) -> Unit,
) {

    companion object {
        private const val TAG = "WifiAwareManager"
        private const val SERVICE_NAME = "turbolink"
    }

    private val awareManager: WifiAwareManager? =
        context.getSystemService(Context.WIFI_AWARE_SERVICE) as? WifiAwareManager

    private var awareSession: WifiAwareSession? = null
    private var publishSession: PublishDiscoverySession? = null
    private var subscribeSession: SubscribeDiscoverySession? = null

    // Discovered peers: peerHandle hashCode → peer info.
    private val discoveredPeers = mutableMapOf<String, PeerInfo>()
    private val connectedPeerIds = mutableSetOf<String>()

    private data class PeerInfo(
        val id: String,
        val name: String,
        val handle: PeerHandle,
        val deviceType: String = "phone",
        val signalStrength: Double = 0.6,
    )

    // ── Public API ───────────────────────────────────────────────────

    fun startDiscovery() {
        if (awareManager == null) {
            Log.e(TAG, "Wi-Fi Aware not supported on this device")
            return
        }

        awareManager.attach(object : AttachCallback() {
            override fun onAttached(session: WifiAwareSession) {
                awareSession = session
                Log.d(TAG, "Attached to Wi-Fi Aware")
                publishService()
                subscribeToService()
            }

            override fun onAttachFailed() {
                Log.e(TAG, "Failed to attach to Wi-Fi Aware")
            }
        }, null)
    }

    fun stopDiscovery() {
        publishSession?.close()
        publishSession = null
        subscribeSession?.close()
        subscribeSession = null
        awareSession?.close()
        awareSession = null
        discoveredPeers.clear()
        Log.d(TAG, "Wi-Fi Aware discovery stopped")
    }

    suspend fun connectToPeer(peerId: String): Boolean {
        val peerInfo = discoveredPeers[peerId] ?: return false
        connectedPeerIds.add(peerId)
        emitPeers()

        // Send a connection-ack message to the peer.
        subscribeSession?.sendMessage(
            peerInfo.handle,
            0,
            "TURBOLINK_CONNECT".toByteArray(),
        )
        Log.d(TAG, "Connected to peer: ${peerInfo.name}")
        return true
    }

    fun disconnectFromPeer(peerId: String) {
        connectedPeerIds.remove(peerId)
        emitPeers()
        Log.d(TAG, "Disconnected from peer: $peerId")
    }

    /**
     * Gets the [PeerHandle] for a connected peer, needed by
     * [FileTransferEngine] to build a [NetworkSpecifier].
     */
    fun getPeerHandle(peerId: String): PeerHandle? {
        return discoveredPeers[peerId]?.handle
    }

    fun getSession(): WifiAwareSession? = awareSession
    fun getPublishSession(): PublishDiscoverySession? = publishSession

    // ── Internal ─────────────────────────────────────────────────────

    private fun publishService() {
        val config = PublishConfig.Builder()
            .setServiceName(SERVICE_NAME)
            .build()

        awareSession?.publish(config, object : DiscoverySessionCallback() {
            override fun onPublishStarted(session: PublishDiscoverySession) {
                publishSession = session
                Log.d(TAG, "Publish started")
            }

            override fun onMessageReceived(peerHandle: PeerHandle, message: ByteArray) {
                val msg = String(message)
                Log.d(TAG, "Message from peer: $msg")
                if (msg.startsWith("TURBOLINK_HELLO:")) {
                    val peerName = msg.removePrefix("TURBOLINK_HELLO:")
                    addPeer(peerHandle, peerName)
                }
            }
        }, null)
    }

    private fun subscribeToService() {
        val config = SubscribeConfig.Builder()
            .setServiceName(SERVICE_NAME)
            .setSubscribeType(SubscribeConfig.SUBSCRIBE_TYPE_PASSIVE)
            .build()

        awareSession?.subscribe(config, object : DiscoverySessionCallback() {
            override fun onSubscribeStarted(session: SubscribeDiscoverySession) {
                subscribeSession = session
                Log.d(TAG, "Subscribe started")

                // Announce our presence by sending a hello on the next
                // service-discovered callback.
            }

            override fun onServiceDiscovered(
                peerHandle: PeerHandle,
                serviceSpecificInfo: ByteArray?,
                matchFilter: List<ByteArray>?,
            ) {
                val deviceName = Build.MODEL ?: "TurboLink Device"
                subscribeSession?.sendMessage(
                    peerHandle,
                    0,
                    "TURBOLINK_HELLO:$deviceName".toByteArray(),
                )

                addPeer(peerHandle, "Nearby Device")
                Log.d(TAG, "Service discovered, sent hello")
            }

            override fun onMessageReceived(peerHandle: PeerHandle, message: ByteArray) {
                val msg = String(message)
                if (msg.startsWith("TURBOLINK_HELLO:")) {
                    val peerName = msg.removePrefix("TURBOLINK_HELLO:")
                    addPeer(peerHandle, peerName)
                }
            }
        }, null)
    }

    private fun addPeer(handle: PeerHandle, name: String) {
        val id = handle.hashCode().toString()
        if (!discoveredPeers.containsKey(id)) {
            discoveredPeers[id] = PeerInfo(
                id = id,
                name = name,
                handle = handle,
                signalStrength = 0.5 + (Math.random() * 0.4),
            )
            emitPeers()
        }
    }

    private fun emitPeers() {
        val serialized = discoveredPeers.values.map { peer ->
            mapOf<String, Any>(
                "id" to peer.id,
                "name" to peer.name,
                "deviceType" to peer.deviceType,
                "signalStrength" to peer.signalStrength,
                "isConnected" to connectedPeerIds.contains(peer.id),
            )
        }
        onPeersUpdated(serialized)
    }
}
