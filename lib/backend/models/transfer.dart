/// Data model for an active or completed file transfer.
///
/// Tracks progress (0.0 to 1.0), speed in bytes/sec, and status.
enum TransferStatus { queued, active, paused, completed, failed }

enum TransferDirection { sending, receiving }

class Transfer {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final double progress; // 0.0 to 1.0
  final double speedBytesPerSec;
  final TransferStatus status;
  final TransferDirection direction;
  final String peerId;
  final String peerName;

  const Transfer({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    this.progress = 0.0,
    this.speedBytesPerSec = 0.0,
    this.status = TransferStatus.queued,
    this.direction = TransferDirection.sending,
    required this.peerId,
    required this.peerName,
  });

  Transfer copyWith({
    double? progress,
    double? speedBytesPerSec,
    TransferStatus? status,
  }) {
    return Transfer(
      id: id,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      progress: progress ?? this.progress,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      status: status ?? this.status,
      direction: direction,
      peerId: peerId,
      peerName: peerName,
    );
  }

  /// Human-readable file size string.
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Human-readable speed string.
  String get speedFormatted {
    if (speedBytesPerSec < 1024) return '${speedBytesPerSec.toInt()} B/s';
    if (speedBytesPerSec < 1024 * 1024) {
      return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}
