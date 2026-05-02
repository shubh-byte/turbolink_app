package com.turbolink.turbolink_app

import android.os.Environment
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.RandomAccessFile
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.channels.ServerSocketChannel
import java.nio.channels.SocketChannel

/**
 * Zero-Copy file transfer engine using [FileChannel.transferTo] and
 * [FileChannel.transferFrom].
 *
 * Key design:
 *  - [transferTo] bypasses user-space entirely: the kernel DMA's directly
 *    from the page cache to the NIC buffer (sendfile(2) on Linux/Android).
 *  - All I/O runs on [Dispatchers.IO] — the main thread is never blocked.
 *  - 8 MB chunk size balances progress-reporting granularity against
 *    syscall overhead.
 *  - Header format: [8 bytes fileSize | 2 bytes nameLen | N bytes fileName]
 *
 * This class is stateless per-transfer. Each send/receive call creates its
 * own NIO channels and cleans them up when done.
 */
class FileTransferEngine(private val scope: CoroutineScope) {

    companion object {
        private const val TAG = "FileTransferEngine"
        private const val CHUNK_SIZE = 8L * 1024 * 1024 // 8 MB
        private const val DOWNLOADS_DIR = "TurboLink"
    }

    // Active transfer jobs, keyed by transferId.
    private val activeJobs = mutableMapOf<String, Job>()

    /**
     * Send a file to a peer. Opens a [ServerSocketChannel], waits for the
     * receiver to connect, then streams the file using Zero-Copy I/O.
     *
     * @param transferId  Unique ID for this transfer.
     * @param filePath    Absolute path to the file to send.
     * @param fileName    Display name of the file.
     * @param fileSizeBytes  Size of the file in bytes.
     * @param peerAddress IP address of the receiving peer.
     * @param onProgress  Callback with (bytesTransferred, totalBytes, speedBps).
     * @param onComplete  Callback when transfer finishes successfully.
     * @param onError     Callback when transfer fails.
     *
     * @return The port number the server is listening on.
     */
    fun sendFile(
        transferId: String,
        filePath: String,
        fileName: String,
        fileSizeBytes: Long,
        peerAddress: String?,
        onProgress: (Long, Long, Double) -> Unit,
        onComplete: () -> Unit,
        onError: (String) -> Unit,
    ): Int {
        var serverPort = 0

        val job = scope.launch(Dispatchers.IO) {
            var serverChannel: ServerSocketChannel? = null
            var clientChannel: SocketChannel? = null
            var fileChannel: FileChannel? = null

            try {
                // 1. Open a non-blocking server socket on a random port.
                serverChannel = ServerSocketChannel.open()
                serverChannel.configureBlocking(true) // Block on accept only
                serverChannel.socket().reuseAddress = true
                serverChannel.bind(InetSocketAddress(0))
                serverPort = serverChannel.socket().localPort
                Log.d(TAG, "[$transferId] Server listening on port $serverPort")

                // 2. Accept the incoming connection from the receiver.
                clientChannel = serverChannel.accept()
                clientChannel.configureBlocking(true)
                Log.d(TAG, "[$transferId] Receiver connected")

                // 3. Send the header: fileSize(8) + nameLen(2) + name(N).
                val nameBytes = fileName.toByteArray(Charsets.UTF_8)
                val headerBuf = ByteBuffer.allocate(10 + nameBytes.size)
                headerBuf.putLong(fileSizeBytes)
                headerBuf.putShort(nameBytes.size.toShort())
                headerBuf.put(nameBytes)
                headerBuf.flip()
                while (headerBuf.hasRemaining()) {
                    clientChannel.write(headerBuf)
                }

                // 4. Zero-Copy transfer using FileChannel.transferTo().
                val raf = RandomAccessFile(filePath, "r")
                fileChannel = raf.channel
                var position = 0L
                var lastTime = System.nanoTime()
                var lastBytes = 0L

                while (position < fileSizeBytes && isActive) {
                    val toTransfer = minOf(CHUNK_SIZE, fileSizeBytes - position)

                    // transferTo() uses sendfile(2) — zero user-space copies.
                    val transferred = fileChannel.transferTo(
                        position, toTransfer, clientChannel,
                    )

                    position += transferred

                    // Calculate speed every chunk.
                    val now = System.nanoTime()
                    val elapsed = (now - lastTime) / 1_000_000_000.0
                    val bytesDelta = position - lastBytes
                    val speed = if (elapsed > 0) bytesDelta / elapsed else 0.0

                    lastTime = now
                    lastBytes = position

                    withContext(Dispatchers.Main) {
                        onProgress(position, fileSizeBytes, speed)
                    }
                }

                Log.d(TAG, "[$transferId] Send complete: $position bytes")
                withContext(Dispatchers.Main) { onComplete() }

            } catch (e: Exception) {
                Log.e(TAG, "[$transferId] Send failed", e)
                withContext(Dispatchers.Main) {
                    onError(e.message ?: "Unknown error")
                }
            } finally {
                fileChannel?.close()
                clientChannel?.close()
                serverChannel?.close()
                activeJobs.remove(transferId)
            }
        }

        activeJobs[transferId] = job

        // Spin-wait briefly for the port to be assigned (max ~100ms).
        val deadline = System.currentTimeMillis() + 200
        while (serverPort == 0 && System.currentTimeMillis() < deadline) {
            Thread.sleep(10)
        }
        return serverPort
    }

    /**
     * Receive a file from a peer. Connects to the sender's server socket,
     * reads the header, then writes the payload using Zero-Copy I/O.
     *
     * Files are saved to Downloads/TurboLink/.
     */
    fun receiveFile(
        transferId: String,
        senderAddress: String,
        senderPort: Int,
        onProgress: (Long, Long, Double) -> Unit,
        onComplete: (String) -> Unit,
        onError: (String) -> Unit,
    ) {
        val job = scope.launch(Dispatchers.IO) {
            var socketChannel: SocketChannel? = null
            var fileChannel: FileChannel? = null

            try {
                // 1. Connect to the sender's server socket.
                socketChannel = SocketChannel.open()
                socketChannel.configureBlocking(true)
                socketChannel.connect(InetSocketAddress(senderAddress, senderPort))
                Log.d(TAG, "[$transferId] Connected to sender $senderAddress:$senderPort")

                // 2. Read the header.
                val sizeBuf = ByteBuffer.allocate(8)
                readFully(socketChannel, sizeBuf)
                sizeBuf.flip()
                val fileSize = sizeBuf.long

                val lenBuf = ByteBuffer.allocate(2)
                readFully(socketChannel, lenBuf)
                lenBuf.flip()
                val nameLen = lenBuf.short.toInt()

                val nameBuf = ByteBuffer.allocate(nameLen)
                readFully(socketChannel, nameBuf)
                nameBuf.flip()
                val fileName = Charsets.UTF_8.decode(nameBuf).toString()

                Log.d(TAG, "[$transferId] Receiving: $fileName ($fileSize bytes)")

                // 3. Create the output file.
                val dir = File(
                    Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_DOWNLOADS
                    ),
                    DOWNLOADS_DIR,
                )
                dir.mkdirs()
                val outFile = File(dir, fileName)
                val raf = RandomAccessFile(outFile, "rw")
                fileChannel = raf.channel

                // 4. Zero-Copy receive using FileChannel.transferFrom().
                var position = 0L
                var lastTime = System.nanoTime()
                var lastBytes = 0L

                while (position < fileSize && isActive) {
                    val toTransfer = minOf(CHUNK_SIZE, fileSize - position)

                    val received = fileChannel.transferFrom(
                        socketChannel, position, toTransfer,
                    )

                    position += received

                    val now = System.nanoTime()
                    val elapsed = (now - lastTime) / 1_000_000_000.0
                    val bytesDelta = position - lastBytes
                    val speed = if (elapsed > 0) bytesDelta / elapsed else 0.0

                    lastTime = now
                    lastBytes = position

                    withContext(Dispatchers.Main) {
                        onProgress(position, fileSize, speed)
                    }
                }

                Log.d(TAG, "[$transferId] Receive complete: ${outFile.absolutePath}")
                withContext(Dispatchers.Main) { onComplete(outFile.absolutePath) }

            } catch (e: Exception) {
                Log.e(TAG, "[$transferId] Receive failed", e)
                withContext(Dispatchers.Main) {
                    onError(e.message ?: "Unknown error")
                }
            } finally {
                fileChannel?.close()
                socketChannel?.close()
                activeJobs.remove(transferId)
            }
        }

        activeJobs[transferId] = job
    }

    /** Cancel an active transfer by ID. */
    fun cancelTransfer(transferId: String) {
        activeJobs[transferId]?.cancel()
        activeJobs.remove(transferId)
        Log.d(TAG, "[$transferId] Transfer cancelled")
    }

    /** Cancel all active transfers (called during cleanup). */
    fun cancelAll() {
        activeJobs.values.forEach { it.cancel() }
        activeJobs.clear()
    }

    /** Read exactly [buffer.remaining()] bytes from the channel. */
    private fun readFully(channel: SocketChannel, buffer: ByteBuffer) {
        while (buffer.hasRemaining()) {
            val read = channel.read(buffer)
            if (read == -1) throw java.io.IOException("Unexpected end of stream")
        }
    }
}
