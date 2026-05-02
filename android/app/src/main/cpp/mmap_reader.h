/**
 * mmap_reader.h — Zero-Copy File Access via Memory Mapping
 *
 * Maps a file into virtual memory using mmap(). The kernel handles
 * paging data from disk/cache transparently — no read() syscalls,
 * no user-space buffer copies.
 *
 * Usage:
 *   tl_mmap_t map;
 *   if (tl_mmap_open(&map, fd, file_size) == 0) {
 *       // map.data points to the file contents
 *       // Access map.data[0..map.size-1]
 *       tl_mmap_close(&map);
 *   }
 *
 * On Android, the fd comes from ContentResolver.openFileDescriptor().
 */

#ifndef TURBOLINK_MMAP_READER_H
#define TURBOLINK_MMAP_READER_H

#include <stdint.h>
#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint8_t* data;    /* Pointer to memory-mapped file data       */
    int64_t  size;    /* File size in bytes                        */
    int      fd;      /* File descriptor (NOT owned, don't close)  */
} tl_mmap_t;

/**
 * Map a file into memory.
 *
 * @param map   Output structure.
 * @param fd    Open file descriptor (read-only).
 * @param size  File size in bytes. Pass 0 to auto-detect via lseek.
 * @return 0 on success, -1 on error (check errno).
 */
static inline int tl_mmap_open(tl_mmap_t* map, int fd, int64_t size) {
    if (size <= 0) {
        /* Auto-detect file size. */
        size = lseek(fd, 0, SEEK_END);
        if (size < 0) return -1;
        lseek(fd, 0, SEEK_SET);
    }

    void* ptr = mmap(NULL, (size_t)size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (ptr == MAP_FAILED) return -1;

    /* Advise the kernel we'll read sequentially — enables aggressive
     * read-ahead, which can double throughput on spinning disks and
     * improves eMMC/UFS performance on phones. */
    madvise(ptr, (size_t)size, MADV_SEQUENTIAL);

    map->data = (uint8_t*)ptr;
    map->size = size;
    map->fd   = fd;
    return 0;
}

/**
 * Unmap the file from memory.
 * Does NOT close the file descriptor.
 */
static inline void tl_mmap_close(tl_mmap_t* map) {
    if (map->data && map->data != MAP_FAILED) {
        munmap(map->data, (size_t)map->size);
        map->data = NULL;
        map->size = 0;
    }
}

/**
 * Get a pointer to a specific block within the mapped file.
 *
 * @param map          The memory-mapped file.
 * @param block_index  Block number (0-based).
 * @param block_size   Size of each block.
 * @param out_len      Output: actual bytes in this block (may be < block_size
 *                     for the last block).
 * @return Pointer to the block data, or NULL if out of range.
 */
static inline const uint8_t* tl_mmap_get_block(const tl_mmap_t* map,
                                                 uint32_t block_index,
                                                 int64_t block_size,
                                                 int64_t* out_len) {
    int64_t offset = (int64_t)block_index * block_size;
    if (offset >= map->size) return NULL;

    int64_t remaining = map->size - offset;
    *out_len = (remaining < block_size) ? remaining : block_size;
    return map->data + offset;
}

#ifdef __cplusplus
}
#endif

#endif /* TURBOLINK_MMAP_READER_H */
