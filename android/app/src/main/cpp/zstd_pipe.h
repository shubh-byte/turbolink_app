/**
 * zstd_pipe.h — Zstandard Streaming Compression/Decompression
 *
 * Thin wrapper around the zstd streaming API. Uses ZSTD_CCtx/ZSTD_DCtx
 * for stateful streaming so we can compress/decompress one block at a time
 * without buffering the entire file.
 *
 * Compression level 3 by default — fast enough to not bottleneck the
 * Wi-Fi Direct link (~250 Mbps) while still achieving ~2-3x compression
 * on typical files (documents, photos, app data).
 *
 * When TL_USE_ZSTD is not defined, all functions become no-ops that
 * just memcpy the data through (passthrough mode).
 */

#ifndef TURBOLINK_ZSTD_PIPE_H
#define TURBOLINK_ZSTD_PIPE_H

#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#ifdef TL_USE_ZSTD
#include <zstd.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define TL_ZSTD_LEVEL 3  /* Fast compression, good ratio */

/* ── Compression Context ──────────────────────────────────────────── */

typedef struct {
#ifdef TL_USE_ZSTD
    ZSTD_CCtx* cctx;
#else
    void* _unused;
#endif
} tl_compressor_t;

static inline int tl_compressor_init(tl_compressor_t* c) {
#ifdef TL_USE_ZSTD
    c->cctx = ZSTD_createCCtx();
    if (!c->cctx) return -1;
    ZSTD_CCtx_setParameter(c->cctx, ZSTD_c_compressionLevel, TL_ZSTD_LEVEL);
    return 0;
#else
    (void)c;
    return 0;
#endif
}

static inline void tl_compressor_free(tl_compressor_t* c) {
#ifdef TL_USE_ZSTD
    if (c->cctx) { ZSTD_freeCCtx(c->cctx); c->cctx = NULL; }
#else
    (void)c;
#endif
}

/**
 * Compress a block of data.
 *
 * @param c         Initialized compressor.
 * @param dst       Output buffer (must be >= tl_compress_bound(src_len)).
 * @param dst_cap   Capacity of output buffer.
 * @param src       Input data.
 * @param src_len   Input data length.
 * @return Compressed size, or 0 on error.
 */
static inline size_t tl_compress(tl_compressor_t* c,
                                  uint8_t* dst, size_t dst_cap,
                                  const uint8_t* src, size_t src_len) {
#ifdef TL_USE_ZSTD
    size_t result = ZSTD_compress2(c->cctx, dst, dst_cap, src, src_len);
    if (ZSTD_isError(result)) return 0;
    return result;
#else
    (void)c;
    if (dst_cap < src_len) return 0;
    memcpy(dst, src, src_len);
    return src_len;
#endif
}

/**
 * Get the maximum compressed size for a given input size.
 */
static inline size_t tl_compress_bound(size_t src_len) {
#ifdef TL_USE_ZSTD
    return ZSTD_compressBound(src_len);
#else
    return src_len;
#endif
}

/* ── Decompression Context ────────────────────────────────────────── */

typedef struct {
#ifdef TL_USE_ZSTD
    ZSTD_DCtx* dctx;
#else
    void* _unused;
#endif
} tl_decompressor_t;

static inline int tl_decompressor_init(tl_decompressor_t* d) {
#ifdef TL_USE_ZSTD
    d->dctx = ZSTD_createDCtx();
    if (!d->dctx) return -1;
    return 0;
#else
    (void)d;
    return 0;
#endif
}

static inline void tl_decompressor_free(tl_decompressor_t* d) {
#ifdef TL_USE_ZSTD
    if (d->dctx) { ZSTD_freeDCtx(d->dctx); d->dctx = NULL; }
#else
    (void)d;
#endif
}

/**
 * Decompress a block of data.
 *
 * @param d          Initialized decompressor.
 * @param dst        Output buffer.
 * @param dst_cap    Capacity of output buffer.
 * @param src        Compressed input.
 * @param src_len    Compressed input length.
 * @return Decompressed size, or 0 on error.
 */
static inline size_t tl_decompress(tl_decompressor_t* d,
                                    uint8_t* dst, size_t dst_cap,
                                    const uint8_t* src, size_t src_len) {
#ifdef TL_USE_ZSTD
    size_t result = ZSTD_decompressDCtx(d->dctx, dst, dst_cap, src, src_len);
    if (ZSTD_isError(result)) return 0;
    return result;
#else
    (void)d;
    if (dst_cap < src_len) return 0;
    memcpy(dst, src, src_len);
    return src_len;
#endif
}

#ifdef __cplusplus
}
#endif

#endif /* TURBOLINK_ZSTD_PIPE_H */
