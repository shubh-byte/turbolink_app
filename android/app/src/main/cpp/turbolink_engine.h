/**
 * turbolink_engine.h — Public C API for the TurboLink Native Engine
 *
 * This is the FFI surface that Dart calls into. All functions use C linkage
 * to prevent C++ name mangling, making them accessible via DynamicLibrary.
 *
 * Thread safety: Each transfer runs on its own thread. The engine maintains
 * a ConcurrentHashMap of active transfers internally.
 *
 * Memory: All buffers are owned by the engine. Dart passes pointers to
 * pre-allocated buffers where noted.
 */

#ifndef TURBOLINK_ENGINE_H
#define TURBOLINK_ENGINE_H

#include <stdint.h>
#include "protocol.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Ensure symbols are exported and not stripped by the linker. */
#define TL_EXPORT __attribute__((visibility("default"))) __attribute__((used))

/* ── Callback typedefs ────────────────────────────────────────────── */

/**
 * Progress callback. Called from the engine's I/O thread.
 * @param bytes_done  Bytes transferred so far.
 * @param bytes_total Total file size.
 * @param speed_bps   Current speed in bytes/sec.
 */
typedef void (*tl_progress_cb)(int64_t bytes_done, int64_t bytes_total,
                                double speed_bps);

/**
 * Completion callback for receive operations.
 * @param saved_path  Null-terminated path where the file was saved.
 */
typedef void (*tl_complete_cb)(const char* saved_path);

/**
 * Error callback.
 * @param error_msg  Null-terminated error description.
 */
typedef void (*tl_error_cb)(const char* error_msg);

/* ── Engine Lifecycle ─────────────────────────────────────────────── */

/** Initialize the engine. Call once at app startup. Returns 0 on success. */
TL_EXPORT int32_t tl_engine_init(void);

/** Shut down the engine. Cancels all active transfers. */
TL_EXPORT void tl_engine_shutdown(void);

/* ── Configuration ────────────────────────────────────────────────── */

/**
 * Set the FEC mode for subsequent transfers.
 * @param mode  0 = Reed-Solomon, 1 = RaptorQ
 */
TL_EXPORT void tl_set_fec_mode(int32_t mode);

/**
 * Get the current FEC mode.
 * @return 0 = Reed-Solomon, 1 = RaptorQ
 */
TL_EXPORT int32_t tl_get_fec_mode(void);

/* ── Send ─────────────────────────────────────────────────────────── */

/**
 * Send a file to a peer over UDP.
 *
 * The full pipeline: mmap → zstd compress → ChaCha20-Poly1305 encrypt
 *                    → FEC encode → UDP send.
 *
 * This function spawns a background thread and returns immediately.
 *
 * @param transfer_id  Unique ID assigned by the caller.
 * @param fd           File descriptor (from Android ContentResolver).
 * @param file_size    Size of the file in bytes.
 * @param file_name    Display name of the file.
 * @param peer_ip      IPv4 address of the receiver (dotted notation).
 * @param peer_port    UDP port of the receiver.
 * @param key          32-byte ChaCha20 encryption key.
 * @param on_progress  Progress callback (may be NULL).
 * @param on_error     Error callback (may be NULL).
 * @return 0 on success (thread launched), negative on error.
 */
TL_EXPORT int32_t tl_send_file(
    int32_t     transfer_id,
    int32_t     fd,
    int64_t     file_size,
    const char* file_name,
    const char* peer_ip,
    uint16_t    peer_port,
    const uint8_t key[TL_KEY_SIZE],
    tl_progress_cb on_progress,
    tl_error_cb    on_error
);

/* ── Receive ──────────────────────────────────────────────────────── */

/**
 * Start listening for an incoming file transfer on the given UDP port.
 *
 * The full pipeline: UDP recv → FEC decode → ChaCha20-Poly1305 decrypt
 *                    → zstd decompress → write to disk.
 *
 * This function spawns a background thread and returns immediately.
 *
 * @param transfer_id  Unique ID assigned by the caller.
 * @param listen_port  UDP port to listen on.
 * @param save_dir     Directory path to save the received file.
 * @param key          32-byte ChaCha20 decryption key.
 * @param on_progress  Progress callback (may be NULL).
 * @param on_complete  Completion callback with saved path (may be NULL).
 * @param on_error     Error callback (may be NULL).
 * @return 0 on success (thread launched), negative on error.
 */
TL_EXPORT int32_t tl_receive_file(
    int32_t     transfer_id,
    uint16_t    listen_port,
    const char* save_dir,
    const uint8_t key[TL_KEY_SIZE],
    tl_progress_cb on_progress,
    tl_complete_cb on_complete,
    tl_error_cb    on_error
);

/* ── Transfer Control ─────────────────────────────────────────────── */

/** Cancel an active transfer by ID. */
TL_EXPORT void tl_cancel_transfer(int32_t transfer_id);

/** Cancel all active transfers. */
TL_EXPORT void tl_cancel_all(void);

/**
 * Get transfer statistics.
 * @param transfer_id  Transfer to query.
 * @param out_progress Pointer to receive progress (0.0 - 1.0).
 * @param out_speed    Pointer to receive speed in bytes/sec.
 * @return 0 if transfer found, -1 if not.
 */
TL_EXPORT int32_t tl_get_stats(int32_t transfer_id,
                                double* out_progress,
                                double* out_speed);

#ifdef __cplusplus
}
#endif

#endif /* TURBOLINK_ENGINE_H */
