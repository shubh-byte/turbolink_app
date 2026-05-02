import 'dart:math';
import 'package:flutter/material.dart';
import '../../backend/models/transfer.dart';
import '../../core/theme_engine/base_theme.dart';

/// A single transfer progress card with an arc progress indicator,
/// speed readout, and file metadata.
class TransferProgressCard extends StatelessWidget {
  final Transfer transfer;
  final VoidCallback? onCancel;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const TransferProgressCard({
    super.key,
    required this.transfer,
    this.onCancel,
    this.onPause,
    this.onResume,
  });

  Color _statusColor(BuildContext context) {
    final colors = BaseTheme.colors(context);
    switch (transfer.status) {
      case TransferStatus.active:
        return colors.secondaryGlow;
      case TransferStatus.paused:
        return Colors.orangeAccent;
      case TransferStatus.completed:
        return colors.success;
      case TransferStatus.failed:
        return colors.error;
      case TransferStatus.queued:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }

  Color _statusBgColor(BuildContext context) {
    final colors = BaseTheme.colors(context);
    switch (transfer.status) {
      case TransferStatus.active:
        return colors.secondaryGlowDim;
      case TransferStatus.paused:
        return Colors.orangeAccent.withValues(alpha: 0.1);
      case TransferStatus.completed:
        return colors.primaryGlowDim;
      case TransferStatus.failed:
        return colors.errorDim;
      case TransferStatus.queued:
        return Theme.of(context).cardTheme.color!;
    }
  }

  String get _statusLabel {
    switch (transfer.status) {
      case TransferStatus.active:
        return '${(transfer.progress * 100).toInt()}%';
      case TransferStatus.paused:
        return 'PAUSED';
      case TransferStatus.completed:
        return 'DONE';
      case TransferStatus.failed:
        return 'FAIL';
      case TransferStatus.queued:
        return 'WAIT';
    }
  }

  IconData get _directionIcon {
    return transfer.direction == TransferDirection.sending
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = _statusColor(context);
    final bgColor = _statusBgColor(context);
    final colors = BaseTheme.colors(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: BaseTheme.spacingMd,
        vertical: BaseTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(BaseTheme.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BaseTheme.spacingMd),
        child: Row(
          children: [
            // Arc progress indicator.
            SizedBox(
              width: 52,
              height: 52,
              child: CustomPaint(
                painter: _ArcProgressPainter(
                  progress: transfer.progress,
                  color: color,
                ),
                child: Center(
                  child: Icon(
                    _directionIcon,
                    color: color,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: BaseTheme.spacingMd),

            // File name + peer + speed.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transfer.fileName,
                    style: tt.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transfer.direction == TransferDirection.sending ? "→" : "←"} ${transfer.peerName}',
                    style: tt.bodySmall,
                  ),
                  if (transfer.status == TransferStatus.active || transfer.status == TransferStatus.paused) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          transfer.status == TransferStatus.paused ? 'SYSTEM PAUSED' : transfer.speedFormatted,
                          style: tt.labelLarge?.copyWith(
                            color: transfer.status == TransferStatus.paused ? Colors.orangeAccent : colors.secondaryGlow,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          transfer.fileSizeFormatted,
                          style: tt.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status label + controls.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusLabel,
                    style: tt.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                if ((transfer.status == TransferStatus.active || transfer.status == TransferStatus.paused)) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pause/Resume button
                      _ControlBtn(
                        icon: transfer.status == TransferStatus.paused 
                          ? Icons.play_arrow_rounded 
                          : Icons.pause_rounded,
                        onTap: transfer.status == TransferStatus.paused ? onResume : onPause,
                      ),
                      const SizedBox(width: 12),
                      // Cancel button
                      _ControlBtn(
                        icon: Icons.close_rounded,
                        onTap: onCancel,
                        color: colors.error.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _ControlBtn({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: (color ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Draws a circular arc progress indicator.
class _ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 3;

    // Background arc.
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc.
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcProgressPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}
