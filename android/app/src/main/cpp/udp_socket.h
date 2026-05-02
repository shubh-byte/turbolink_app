/**
 * udp_socket.h — Full-Duplex UDP Socket Manager
 *
 * Manages non-blocking UDP sockets for simultaneous send and receive.
 * Uses epoll on Android/Linux for efficient event-driven I/O.
 *
 * Design:
 *   - One socket per transfer direction (send/receive).
 *   - Non-blocking mode: sendto/recvfrom never block the engine.
 *   - Configurable send pacing to avoid overwhelming the Wi-Fi link.
 */

#ifndef TURBOLINK_UDP_SOCKET_H
#define TURBOLINK_UDP_SOCKET_H

#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "protocol.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int       fd;            /* Socket file descriptor               */
    uint16_t  local_port;    /* Local port (bound)                   */
    struct sockaddr_in peer; /* Remote peer address                  */
    int       is_bound;      /* 1 if bind() succeeded                */
} tl_udp_socket_t;

/**
 * Create and bind a UDP socket.
 *
 * @param sock  Output socket structure.
 * @param port  Port to bind to. 0 = let the OS choose.
 * @return 0 on success, -1 on error.
 */
static inline int tl_udp_create(tl_udp_socket_t* sock, uint16_t port) {
    memset(sock, 0, sizeof(*sock));

    sock->fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock->fd < 0) return -1;

    /* Enable address reuse for fast restart. */
    int opt = 1;
    setsockopt(sock->fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    /* Increase socket buffers to 4MB for high-throughput transfers. */
    int buf_size = 4 * 1024 * 1024;
    setsockopt(sock->fd, SOL_SOCKET, SO_SNDBUF, &buf_size, sizeof(buf_size));
    setsockopt(sock->fd, SOL_SOCKET, SO_RCVBUF, &buf_size, sizeof(buf_size));

    /* Bind to the specified port. */
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);

    if (bind(sock->fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(sock->fd);
        sock->fd = -1;
        return -1;
    }

    /* Get the actual bound port (useful when port=0). */
    socklen_t addr_len = sizeof(addr);
    getsockname(sock->fd, (struct sockaddr*)&addr, &addr_len);
    sock->local_port = ntohs(addr.sin_port);
    sock->is_bound = 1;

    return 0;
}

/**
 * Set the default peer address for sendto().
 */
static inline void tl_udp_set_peer(tl_udp_socket_t* sock,
                                     const char* ip, uint16_t port) {
    memset(&sock->peer, 0, sizeof(sock->peer));
    sock->peer.sin_family = AF_INET;
    sock->peer.sin_port = htons(port);
    inet_pton(AF_INET, ip, &sock->peer.sin_addr);
}

/**
 * Set the socket to non-blocking mode.
 */
static inline int tl_udp_set_nonblocking(tl_udp_socket_t* sock) {
    int flags = fcntl(sock->fd, F_GETFL, 0);
    if (flags < 0) return -1;
    return fcntl(sock->fd, F_SETFL, flags | O_NONBLOCK);
}

/**
 * Send a framed packet to the peer.
 *
 * @param sock         UDP socket.
 * @param transfer_id  Transfer identifier.
 * @param seq          Sequence number.
 * @param type         Frame type.
 * @param payload      Payload data.
 * @param payload_len  Payload length.
 * @return Bytes sent, or -1 on error.
 */
static inline ssize_t tl_udp_send_frame(tl_udp_socket_t* sock,
                                          uint32_t transfer_id,
                                          uint32_t seq,
                                          tl_frame_type_t type,
                                          const uint8_t* payload,
                                          uint16_t payload_len) {
    uint8_t buf[TL_MAX_PACKET];
    if (TL_HEADER_SIZE + payload_len > TL_MAX_PACKET) return -1;

    tl_write_header(buf, transfer_id, seq, type, payload_len);
    if (payload_len > 0) {
        memcpy(buf + TL_HEADER_SIZE, payload, payload_len);
    }

    return sendto(sock->fd, buf, TL_HEADER_SIZE + payload_len, 0,
                  (struct sockaddr*)&sock->peer, sizeof(sock->peer));
}

/**
 * Receive a packet from any sender.
 *
 * @param sock       UDP socket.
 * @param buf        Output buffer (must be >= TL_MAX_PACKET).
 * @param sender     Output: sender's address (may be NULL).
 * @return Bytes received, 0 if would block, -1 on error.
 */
static inline ssize_t tl_udp_recv(tl_udp_socket_t* sock,
                                    uint8_t* buf,
                                    struct sockaddr_in* sender) {
    struct sockaddr_in from;
    socklen_t from_len = sizeof(from);

    ssize_t n = recvfrom(sock->fd, buf, TL_MAX_PACKET, 0,
                         (struct sockaddr*)&from, &from_len);

    if (n < 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK) return 0;
        return -1;
    }

    if (sender) *sender = from;
    return n;
}

/**
 * Close the socket.
 */
static inline void tl_udp_close(tl_udp_socket_t* sock) {
    if (sock->fd >= 0) {
        close(sock->fd);
        sock->fd = -1;
    }
    sock->is_bound = 0;
}

#ifdef __cplusplus
}
#endif

#endif /* TURBOLINK_UDP_SOCKET_H */
