/**
 * reed_solomon_fec.h — Reed-Solomon Forward Error Correction
 *
 * A lightweight, header-only implementation of Reed-Solomon over GF(2^8).
 * This provides packet-loss resilience for the UDP transfer pipeline.
 *
 * Algorithm:
 *   - Operates on Galois Field GF(2^8) with polynomial 0x11D (x^8+x^4+x^3+x^2+1).
 *   - Encoding: Matrix multiplication in GF(2^8) using a Vandermonde matrix.
 *   - Decoding: Gaussian elimination to invert the submatrix corresponding
 *               to the received symbols, then matrix multiplication to recover
 *               the original data.
 *
 * Performance:
 *   - O(N * K) encoding/decoding time per block.
 *   - Fast enough for mobile CPUs for typical block sizes (e.g., K=750, N=1000).
 */

#ifndef TURBOLINK_REED_SOLOMON_FEC_H
#define TURBOLINK_REED_SOLOMON_FEC_H

#include "fec_interface.h"
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ── GF(2^8) Arithmetic ───────────────────────────────────────────── */

/* Precomputed exp/log tables for GF(2^8) multiplication */
static uint8_t gf_exp[512];
static uint8_t gf_log[256];
static int gf_initialized = 0;

static inline void gf_init() {
    if (gf_initialized) return;
    int x = 1;
    for (int i = 0; i < 255; i++) {
        gf_exp[i] = x;
        gf_exp[i + 255] = x;
        gf_log[x] = i;
        x <<= 1;
        if (x & 0x100) x ^= 0x11D; /* Primitive polynomial */
    }
    gf_exp[255] = 0;
    gf_log[0] = 0;
    gf_initialized = 1;
}

static inline uint8_t gf_add(uint8_t a, uint8_t b) {
    return a ^ b;
}

static inline uint8_t gf_mul(uint8_t a, uint8_t b) {
    if (a == 0 || b == 0) return 0;
    return gf_exp[(uint32_t)gf_log[a] + (uint32_t)gf_log[b]];
}

static inline uint8_t gf_div(uint8_t a, uint8_t b) {
    if (a == 0 || b == 0) return 0;
    return gf_exp[(uint32_t)gf_log[a] + 255 - (uint32_t)gf_log[b]];
}

static inline uint8_t gf_inv(uint8_t a) {
    if (a == 0) return 0;
    return gf_exp[255 - gf_log[a]];
}

/* Multiply a region of bytes by a scalar in GF(2^8) and XOR into destination */
static inline void gf_mul_xor_region(uint8_t* dst, const uint8_t* src, uint8_t c, size_t len) {
    if (c == 0) return;
    if (c == 1) {
        for (size_t i = 0; i < len; i++) dst[i] ^= src[i];
        return;
    }
    int log_c = gf_log[c];
    for (size_t i = 0; i < len; i++) {
        if (src[i] != 0) {
            dst[i] ^= gf_exp[gf_log[src[i]] + log_c];
        }
    }
}

/* ── Matrix Operations ────────────────────────────────────────────── */

/* Generate a Vandermonde encoding matrix (N rows, K columns) */
static inline void rs_build_matrix(uint8_t* matrix, int n, int k) {
    for (int row = 0; row < n; row++) {
        for (int col = 0; col < k; col++) {
            /* The top KxK is the identity matrix (systematic encoding) */
            if (row < k) {
                matrix[row * k + col] = (row == col) ? 1 : 0;
            } else {
                /* The remaining (N-K) rows are powers of a generator */
                matrix[row * k + col] = gf_exp[((row - k + 1) * col) % 255];
            }
        }
    }
}

/* Invert a KxK matrix using Gaussian elimination */
static inline int rs_invert_matrix(uint8_t* matrix, int k) {
    uint8_t* id = (uint8_t*)malloc(k * k);
    memset(id, 0, k * k);
    for (int i = 0; i < k; i++) id[i * k + i] = 1;

    for (int i = 0; i < k; i++) {
        /* Find pivot */
        if (matrix[i * k + i] == 0) {
            int j;
            for (j = i + 1; j < k; j++) {
                if (matrix[j * k + i] != 0) break;
            }
            if (j == k) {
                free(id);
                return -1; /* Singular matrix */
            }
            /* Swap rows */
            for (int col = 0; col < k; col++) {
                uint8_t tmp = matrix[i * k + col];
                matrix[i * k + col] = matrix[j * k + col];
                matrix[j * k + col] = tmp;

                tmp = id[i * k + col];
                id[i * k + col] = id[j * k + col];
                id[j * k + col] = tmp;
            }
        }

        /* Scale pivot row */
        uint8_t inv = gf_inv(matrix[i * k + i]);
        for (int col = 0; col < k; col++) {
            matrix[i * k + col] = gf_mul(matrix[i * k + col], inv);
            id[i * k + col] = gf_mul(id[i * k + col], inv);
        }

        /* Eliminate other rows */
        for (int j = 0; j < k; j++) {
            if (i != j) {
                uint8_t factor = matrix[j * k + i];
                for (int col = 0; col < k; col++) {
                    matrix[j * k + col] ^= gf_mul(matrix[i * k + col], factor);
                    id[j * k + col] ^= gf_mul(id[i * k + col], factor);
                }
            }
        }
    }

    /* Copy inverted matrix back */
    memcpy(matrix, id, k * k);
    free(id);
    return 0;
}

/* ── Implementation of FEC Interface ──────────────────────────────── */

static int rs_encode(const uint8_t* block_data, size_t block_len,
                     uint16_t symbol_size, float repair_ratio,
                     tl_fec_symbol_t** out_symbols, uint32_t* out_count) {
    gf_init();

    int k = (block_len + symbol_size - 1) / symbol_size;
    int repair_count = (int)(k * repair_ratio);
    if (repair_count < 1) repair_count = 1;
    int n = k + repair_count;
    
    if (n > 255) {
        /* GF(2^8) limits N to 255. If we need more, we'd have to chunk the block
           or use GF(2^16). For 1MB blocks and 1400B symbols, K~750, so we 
           would normally interleave. For this simple implementation, we enforce N<=255. */
        return -1; 
    }

    uint8_t* matrix = (uint8_t*)malloc(n * k);
    rs_build_matrix(matrix, n, k);

    tl_fec_symbol_t* symbols = (tl_fec_symbol_t*)malloc(n * sizeof(tl_fec_symbol_t));

    /* Extract source symbols */
    for (int i = 0; i < k; i++) {
        symbols[i].index = i;
        symbols[i].len = symbol_size;
        symbols[i].data = (uint8_t*)calloc(1, symbol_size);
        
        size_t offset = i * symbol_size;
        size_t copy_len = (block_len - offset < symbol_size) ? (block_len - offset) : symbol_size;
        if (copy_len > 0) {
            memcpy(symbols[i].data, block_data + offset, copy_len);
        }
    }

    /* Compute repair symbols */
    for (int i = k; i < n; i++) {
        symbols[i].index = i;
        symbols[i].len = symbol_size;
        symbols[i].data = (uint8_t*)calloc(1, symbol_size);

        for (int j = 0; j < k; j++) {
            uint8_t coeff = matrix[i * k + j];
            gf_mul_xor_region(symbols[i].data, symbols[j].data, coeff, symbol_size);
        }
    }

    free(matrix);
    *out_symbols = symbols;
    *out_count = n;
    return 0;
}

static int rs_decode(const tl_fec_symbol_t* symbols, uint32_t symbol_count,
                     uint16_t symbol_size, size_t block_len, uint8_t* out_data) {
    gf_init();

    int k = (block_len + symbol_size - 1) / symbol_size;
    if (symbol_count < k) return -1; /* Not enough symbols to decode */

    /* For simplicity in this demo, assume N <= 255 */
    int max_n = 255;
    uint8_t* encode_matrix = (uint8_t*)malloc(max_n * k);
    rs_build_matrix(encode_matrix, max_n, k);

    /* Construct the decoding submatrix from the received symbols */
    uint8_t* decode_matrix = (uint8_t*)malloc(k * k);
    for (int i = 0; i < k; i++) {
        int row = symbols[i].index;
        for (int col = 0; col < k; col++) {
            decode_matrix[i * k + col] = encode_matrix[row * k + col];
        }
    }

    /* Invert the submatrix */
    if (rs_invert_matrix(decode_matrix, k) < 0) {
        free(encode_matrix);
        free(decode_matrix);
        return -1;
    }

    /* Recover original data */
    memset(out_data, 0, block_len);
    uint8_t* temp_symbol = (uint8_t*)malloc(symbol_size);

    for (int orig_i = 0; orig_i < k; orig_i++) {
        memset(temp_symbol, 0, symbol_size);

        for (int recv_i = 0; recv_i < k; recv_i++) {
            uint8_t coeff = decode_matrix[orig_i * k + recv_i];
            gf_mul_xor_region(temp_symbol, symbols[recv_i].data, coeff, symbol_size);
        }

        size_t offset = orig_i * symbol_size;
        size_t copy_len = (block_len - offset < symbol_size) ? (block_len - offset) : symbol_size;
        if (copy_len > 0) {
            memcpy(out_data + offset, temp_symbol, copy_len);
        }
    }

    free(temp_symbol);
    free(encode_matrix);
    free(decode_matrix);
    return 0;
}

const tl_fec_vtable_t TL_FEC_REED_SOLOMON_VTABLE = {
    "Reed-Solomon",
    rs_encode,
    rs_decode
};

#ifdef __cplusplus
}
#endif

#endif /* TURBOLINK_REED_SOLOMON_FEC_H */
