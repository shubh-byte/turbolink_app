/**
 * fec_interface.h — Abstract FEC (Forward Error Correction) Interface
 *
 * Defines the common interface that both Reed-Solomon and RaptorQ
 * implementations must satisfy. The engine selects between them at
 * runtime via tl_set_fec_mode().
 *
 * Terminology:
 *   - Block:  A 1MB chunk of the file (after compression + encryption).
 *   - Symbol: A FEC-encoded fragment of a block (~1400 bytes, MTU-safe).
 *   - K:      Number of source symbols per block.
 *   - N:      Total symbols (source + repair) per block. N >= K.
 *   - Any K of the N symbols can reconstruct the original block.
 */

#ifndef TURBOLINK_FEC_INTERFACE_H
#define TURBOLINK_FEC_INTERFACE_H

#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ── FEC Symbol ───────────────────────────────────────────────────── */

typedef struct {
    uint32_t index;         /* Symbol index (0..N-1)                 */
    uint16_t len;           /* Actual data length                    */
    uint8_t* data;          /* Symbol data (caller-owned buffer)     */
} tl_fec_symbol_t;

/* ── FEC Encoder ──────────────────────────────────────────────────── */

/**
 * Encode a data block into FEC symbols.
 *
 * @param block_data   Input data block.
 * @param block_len    Length of the data block.
 * @param symbol_size  Target symbol size (~1400 for UDP MTU).
 * @param repair_ratio Extra repair symbols as a fraction (e.g., 0.5 = 50% extra).
 * @param out_symbols  Output array of symbols (caller must free).
 * @param out_count    Output: number of symbols generated.
 * @return 0 on success, -1 on error.
 */
typedef int (*tl_fec_encode_fn)(
    const uint8_t*    block_data,
    size_t            block_len,
    uint16_t          symbol_size,
    float             repair_ratio,
    tl_fec_symbol_t** out_symbols,
    uint32_t*         out_count
);

/**
 * Decode FEC symbols back into the original data block.
 *
 * @param symbols       Array of received symbols (any K of N suffice).
 * @param symbol_count  Number of received symbols.
 * @param symbol_size   Symbol size used during encoding.
 * @param block_len     Expected original block length.
 * @param out_data      Output buffer for decoded block (must be >= block_len).
 * @return 0 on success, -1 if insufficient symbols.
 */
typedef int (*tl_fec_decode_fn)(
    const tl_fec_symbol_t* symbols,
    uint32_t               symbol_count,
    uint16_t               symbol_size,
    size_t                 block_len,
    uint8_t*               out_data
);

/* ── FEC VTable ───────────────────────────────────────────────────── */

typedef struct {
    const char*      name;     /* "Reed-Solomon" or "RaptorQ"       */
    tl_fec_encode_fn encode;
    tl_fec_decode_fn decode;
} tl_fec_vtable_t;

/* Implemented in reed_solomon_fec.h and raptorq_fec.h */
extern const tl_fec_vtable_t TL_FEC_REED_SOLOMON_VTABLE;
extern const tl_fec_vtable_t TL_FEC_RAPTORQ_VTABLE;

/* ── Helpers ──────────────────────────────────────────────────────── */

static inline void tl_fec_free_symbols(tl_fec_symbol_t* symbols, uint32_t count) {
    if (!symbols) return;
    for (uint32_t i = 0; i < count; i++) {
        free(symbols[i].data);
    }
    free(symbols);
}

#ifdef __cplusplus
}
#endif

#endif /* TURBOLINK_FEC_INTERFACE_H */
