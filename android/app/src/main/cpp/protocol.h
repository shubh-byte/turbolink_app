/**
 * protocol.h — TurboLink UDP Wire Protocol
 *
 * Frame layout for all datagrams:
 *
 *   [4 magic] [4 transfer_id] [4 seq_num] [1 type] [2 payload_len] [N payload]
 *
 * Total header: 15 bytes. Max payload: 65521 bytes (UDP max - header).
 * Practical payload: 1400 bytes to avoid IP fragmentation on Wi-Fi.
 *
 * Frame types:
 *   0x01  FILE_HEADER   Metadata: filename, file size, total blocks, FEC mode
 *   0x02  DATA_SYMBOL   One FEC symbol (data or repair) for a block
 *   0x03  ACK_BITMAP    Receiver → sender: bitmap of completed blocks
 *   0x04  CANCEL        Abort the transfer
 *   0x05  COMPLETE      All blocks received successfully
 *   0x06  HANDSHAKE     Initial connection establishment + key exchange
 */

#ifndef TURBOLINK_PROTOCOL_H
#define TURBOLINK_PROTOCOL_H

#include <stdint.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ── Constants ────────────────────────────────────────────────────── */

#define TL_MAGIC          0x544C4E4B   /* "TLNK" in ASCII               */
#define TL_MAX_PACKET     1472         /* Safe UDP payload (MTU 1500)    */
#define TL_HEADER_SIZE    15           /* Frame header size              */
#define TL_MAX_PAYLOAD    (TL_MAX_PACKET - TL_HEADER_SIZE)
#define TL_BLOCK_SIZE     (1024 * 1024) /* 1 MB logical block            */
#define TL_SYMBOL_SIZE    1400         /* FEC symbol size (< MTU)        */
#define TL_NONCE_SIZE     12           /* ChaCha20-Poly1305 nonce        */
#define TL_TAG_SIZE       16           /* Poly1305 auth tag              */
#define TL_KEY_SIZE       32           /* ChaCha20 key                   */

/* ── Frame Types ──────────────────────────────────────────────────── */

typedef enum {
    TL_FRAME_FILE_HEADER = 0x01,
    TL_FRAME_DATA_SYMBOL = 0x02,
    TL_FRAME_ACK_BITMAP  = 0x03,
    TL_FRAME_CANCEL      = 0x04,
    TL_FRAME_COMPLETE    = 0x05,
    TL_FRAME_HANDSHAKE   = 0x06,
} tl_frame_type_t;

/* ── FEC Modes ────────────────────────────────────────────────────── */

typedef enum {
    TL_FEC_REED_SOLOMON = 0,
    TL_FEC_RAPTORQ      = 1,
} tl_fec_mode_t;

/* ── Frame Header (packed, network byte order) ────────────────────── */

#pragma pack(push, 1)
typedef struct {
    uint32_t magic;          /* TL_MAGIC                              */
    uint32_t transfer_id;    /* Unique ID for this transfer           */
    uint32_t seq_num;        /* Monotonic sequence number             */
    uint8_t  type;           /* tl_frame_type_t                       */
    uint16_t payload_len;    /* Length of payload following this header*/
} tl_frame_header_t;
#pragma pack(pop)

/* ── File Header Payload ──────────────────────────────────────────── */

#pragma pack(push, 1)
typedef struct {
    int64_t  file_size;       /* Total file size in bytes             */
    uint32_t total_blocks;    /* Number of 1MB blocks                 */
    uint8_t  fec_mode;        /* tl_fec_mode_t                       */
    uint16_t filename_len;    /* Length of filename string            */
    /* followed by: char filename[filename_len]                       */
} tl_file_header_payload_t;
#pragma pack(pop)

/* ── Data Symbol Payload ──────────────────────────────────────────── */

#pragma pack(push, 1)
typedef struct {
    uint32_t block_index;     /* Which 1MB block this belongs to     */
    uint32_t symbol_index;    /* Symbol index within the block       */
    uint16_t symbol_len;      /* Actual data length of this symbol   */
    /* followed by: uint8_t data[symbol_len]                         */
} tl_data_symbol_payload_t;
#pragma pack(pop)

/* ── Utility: serialize/deserialize header ────────────────────────── */

static inline void tl_write_header(uint8_t* buf,
                                    uint32_t transfer_id,
                                    uint32_t seq_num,
                                    tl_frame_type_t type,
                                    uint16_t payload_len) {
    uint32_t magic = TL_MAGIC;
    memcpy(buf + 0,  &magic,       4);
    memcpy(buf + 4,  &transfer_id, 4);
    memcpy(buf + 8,  &seq_num,     4);
    buf[12] = (uint8_t)type;
    memcpy(buf + 13, &payload_len, 2);
}

static inline int tl_read_header(const uint8_t* buf, size_t len,
                                  tl_frame_header_t* out) {
    if (len < TL_HEADER_SIZE) return -1;
    memcpy(&out->magic,       buf + 0,  4);
    memcpy(&out->transfer_id, buf + 4,  4);
    memcpy(&out->seq_num,     buf + 8,  4);
    out->type = buf[12];
    memcpy(&out->payload_len, buf + 13, 2);
    if (out->magic != TL_MAGIC) return -1;
    return 0;
}

#ifdef __cplusplus
}
#endif

#endif /* TURBOLINK_PROTOCOL_H */
