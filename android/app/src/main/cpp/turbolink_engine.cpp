/**
 * turbolink_engine.cpp — Main Engine Implementation
 *
 * Implements the core transfer logic, thread management, and the FFI bridge.
 */

#include "turbolink_engine.h"
#include "mmap_reader.h"
#include "zstd_pipe.h"
#include "crypto_pipe.h"
#include "fec_interface.h"
#include "reed_solomon_fec.h"
#include "raptorq_fec.h"
#include "udp_socket.h"

#include <pthread.h>
#include <map>
#include <mutex>
#include <atomic>
#include <android/log.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#define LOG_TAG "TurboLinkEngine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

/* ── Global State ─────────────────────────────────────────────────── */

static std::atomic<tl_fec_mode_t> g_fec_mode{TL_FEC_REED_SOLOMON};
static const float g_repair_ratio = 0.2f; /* 20% overhead for FEC */

struct TransferCtx {
    int32_t id;
    std::atomic<bool> active;
    std::atomic<double> progress;
    std::atomic<double> speed_bps;
    
    /* Thread handle */
    pthread_t thread;

    /* Callbacks */
    tl_progress_cb on_progress;
    tl_complete_cb on_complete;
    tl_error_cb    on_error;
    
    /* Send params */
    int fd;
    int64_t file_size;
    std::string file_name;
    std::string peer_ip;
    uint16_t peer_port;
    
    /* Recv params */
    uint16_t listen_port;
    std::string save_dir;
    
    /* Shared */
    uint8_t key[TL_KEY_SIZE];
};

static std::map<int32_t, TransferCtx*> g_transfers;
static std::mutex g_transfers_mutex;

/* ── Transfer Management ──────────────────────────────────────────── */

static TransferCtx* create_transfer(int32_t id) {
    std::lock_guard<std::mutex> lock(g_transfers_mutex);
    if (g_transfers.count(id)) return nullptr;
    
    TransferCtx* ctx = new TransferCtx();
    ctx->id = id;
    ctx->active = true;
    ctx->progress = 0.0;
    ctx->speed_bps = 0.0;
    g_transfers[id] = ctx;
    return ctx;
}

static void destroy_transfer(int32_t id) {
    std::lock_guard<std::mutex> lock(g_transfers_mutex);
    auto it = g_transfers.find(id);
    if (it != g_transfers.end()) {
        delete it->second;
        g_transfers.erase(it);
    }
}

static TransferCtx* get_transfer(int32_t id) {
    std::lock_guard<std::mutex> lock(g_transfers_mutex);
    auto it = g_transfers.find(id);
    return it != g_transfers.end() ? it->second : nullptr;
}

static const tl_fec_vtable_t* get_fec_impl() {
    if (g_fec_mode == TL_FEC_RAPTORQ) {
        return &TL_FEC_RAPTORQ_VTABLE;
    }
    return &TL_FEC_REED_SOLOMON_VTABLE;
}

/* ── Send Pipeline ────────────────────────────────────────────────── */

static void* send_thread_func(void* arg) {
    TransferCtx* ctx = (TransferCtx*)arg;
    LOGI("Send thread started for transfer %d", ctx->id);

    tl_udp_socket_t sock;
    if (tl_udp_create(&sock, 0) < 0) {
        if (ctx->on_error) ctx->on_error("Failed to create UDP socket");
        ctx->active = false;
        return nullptr;
    }
    tl_udp_set_peer(&sock, ctx->peer_ip.c_str(), ctx->peer_port);

    tl_mmap_t map;
    if (tl_mmap_open(&map, ctx->fd, ctx->file_size) < 0) {
        if (ctx->on_error) ctx->on_error("Failed to mmap file");
        tl_udp_close(&sock);
        ctx->active = false;
        return nullptr;
    }

    tl_compressor_t zstd;
    tl_compressor_init(&zstd);

    const tl_fec_vtable_t* fec = get_fec_impl();
    LOGI("Using FEC: %s", fec->name);

    /* 1. Send File Header */
    uint32_t total_blocks = (map.size + TL_BLOCK_SIZE - 1) / TL_BLOCK_SIZE;
    tl_file_header_payload_t header;
    header.file_size = map.size;
    header.total_blocks = total_blocks;
    header.fec_mode = g_fec_mode;
    header.filename_len = ctx->file_name.length();

    uint8_t header_buf[TL_MAX_PAYLOAD];
    memcpy(header_buf, &header, sizeof(header));
    memcpy(header_buf + sizeof(header), ctx->file_name.c_str(), header.filename_len);
    
    tl_udp_send_frame(&sock, ctx->id, 0, TL_FRAME_FILE_HEADER, 
                      header_buf, sizeof(header) + header.filename_len);

    /* 2. Process blocks */
    uint32_t seq_num = 1;
    int64_t bytes_sent = 0;

    size_t zstd_bound = tl_compress_bound(TL_BLOCK_SIZE);
    uint8_t* compressed_buf = (uint8_t*)malloc(zstd_bound);
    uint8_t* encrypted_buf  = (uint8_t*)malloc(zstd_bound + TL_TAG_SIZE);

    for (uint32_t block_idx = 0; block_idx < total_blocks && ctx->active; block_idx++) {
        int64_t block_len;
        const uint8_t* block_data = tl_mmap_get_block(&map, block_idx, TL_BLOCK_SIZE, &block_len);

        /* Step A: Compress */
        size_t comp_len = tl_compress(&zstd, compressed_buf, zstd_bound, block_data, block_len);
        
        /* Step B: Encrypt */
        uint8_t nonce[TL_NONCE_SIZE];
        tl_make_nonce(nonce, block_idx);
        size_t enc_len = tl_encrypt(encrypted_buf, compressed_buf, comp_len, ctx->key, nonce);

        /* Step C: FEC Encode */
        tl_fec_symbol_t* symbols = nullptr;
        uint32_t symbol_count = 0;
        fec->encode(encrypted_buf, enc_len, TL_SYMBOL_SIZE, g_repair_ratio, &symbols, &symbol_count);

        /* Step D: Send symbols */
        uint8_t payload_buf[TL_MAX_PAYLOAD];
        for (uint32_t i = 0; i < symbol_count && ctx->active; i++) {
            tl_data_symbol_payload_t sym_hdr;
            sym_hdr.block_index = block_idx;
            sym_hdr.symbol_index = symbols[i].index;
            sym_hdr.symbol_len = symbols[i].len;
            
            memcpy(payload_buf, &sym_hdr, sizeof(sym_hdr));
            memcpy(payload_buf + sizeof(sym_hdr), symbols[i].data, symbols[i].len);
            
            tl_udp_send_frame(&sock, ctx->id, seq_num++, TL_FRAME_DATA_SYMBOL,
                              payload_buf, sizeof(sym_hdr) + symbols[i].len);
            
            /* Add ~100us pacing to avoid overflowing network buffers */
            usleep(100); 
        }

        tl_fec_free_symbols(symbols, symbol_count);

        bytes_sent += block_len;
        ctx->progress = (double)bytes_sent / map.size;
        
        if (ctx->on_progress) {
            ctx->on_progress(bytes_sent, map.size, 0.0); // TODO: Calculate real speed
        }
    }

    /* 3. Send Complete */
    tl_udp_send_frame(&sock, ctx->id, seq_num++, TL_FRAME_COMPLETE, nullptr, 0);

    free(compressed_buf);
    free(encrypted_buf);
    tl_compressor_free(&zstd);
    tl_mmap_close(&map);
    tl_udp_close(&sock);

    LOGI("Send thread finished for transfer %d", ctx->id);
    ctx->active = false;
    return nullptr;
}

/* ── Receive Pipeline ─────────────────────────────────────────────── */

static void* recv_thread_func(void* arg) {
    TransferCtx* ctx = (TransferCtx*)arg;
    LOGI("Receive thread started for transfer %d", ctx->id);

    /* Receive logic will be fully implemented once UDP pacing is verified.
     * It mirrors the send pipeline in reverse:
     * recv_frame -> buffer symbols -> FEC decode block -> ChaCha20 decrypt 
     * -> ZSTD decompress -> write to MediaStore fd.
     */
     
    sleep(1); /* Placeholder for now */

    ctx->active = false;
    if (ctx->on_complete) ctx->on_complete("/sdcard/Download/received.file");
    return nullptr;
}

/* ── FFI Surface ──────────────────────────────────────────────────── */

extern "C" {

TL_EXPORT int32_t tl_engine_init(void) {
    LOGI("TurboLink Engine Initialized");
    return 0;
}

TL_EXPORT void tl_engine_shutdown(void) {
    tl_cancel_all();
    LOGI("TurboLink Engine Shutdown");
}

TL_EXPORT void tl_set_fec_mode(int32_t mode) {
    g_fec_mode = (tl_fec_mode_t)mode;
}

TL_EXPORT int32_t tl_get_fec_mode(void) {
    return g_fec_mode;
}

TL_EXPORT int32_t tl_send_file(
    int32_t transfer_id, int32_t fd, int64_t file_size, const char* file_name,
    const char* peer_ip, uint16_t peer_port, const uint8_t key[TL_KEY_SIZE],
    tl_progress_cb on_progress, tl_error_cb on_error
) {
    TransferCtx* ctx = create_transfer(transfer_id);
    if (!ctx) return -1;

    ctx->fd = fd;
    ctx->file_size = file_size;
    ctx->file_name = file_name;
    ctx->peer_ip = peer_ip;
    ctx->peer_port = peer_port;
    memcpy(ctx->key, key, TL_KEY_SIZE);
    ctx->on_progress = on_progress;
    ctx->on_error = on_error;

    if (pthread_create(&ctx->thread, nullptr, send_thread_func, ctx) != 0) {
        destroy_transfer(transfer_id);
        return -1;
    }
    pthread_detach(ctx->thread);
    return 0;
}

TL_EXPORT int32_t tl_receive_file(
    int32_t transfer_id, uint16_t listen_port, const char* save_dir,
    const uint8_t key[TL_KEY_SIZE], tl_progress_cb on_progress,
    tl_complete_cb on_complete, tl_error_cb on_error
) {
    TransferCtx* ctx = create_transfer(transfer_id);
    if (!ctx) return -1;

    ctx->listen_port = listen_port;
    ctx->save_dir = save_dir;
    memcpy(ctx->key, key, TL_KEY_SIZE);
    ctx->on_progress = on_progress;
    ctx->on_complete = on_complete;
    ctx->on_error = on_error;

    if (pthread_create(&ctx->thread, nullptr, recv_thread_func, ctx) != 0) {
        destroy_transfer(transfer_id);
        return -1;
    }
    pthread_detach(ctx->thread);
    return 0;
}

TL_EXPORT void tl_cancel_transfer(int32_t transfer_id) {
    TransferCtx* ctx = get_transfer(transfer_id);
    if (ctx) {
        ctx->active = false;
    }
}

TL_EXPORT void tl_cancel_all(void) {
    std::lock_guard<std::mutex> lock(g_transfers_mutex);
    for (auto& pair : g_transfers) {
        pair.second->active = false;
    }
}

TL_EXPORT int32_t tl_get_stats(int32_t transfer_id, double* out_progress, double* out_speed) {
    TransferCtx* ctx = get_transfer(transfer_id);
    if (!ctx) return -1;
    
    if (out_progress) *out_progress = ctx->progress;
    if (out_speed) *out_speed = ctx->speed_bps;
    return 0;
}

} // extern "C"
