import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/models/transfer.dart';
import '../../core/theme_engine/base_theme.dart';
import '../../providers/transfer_provider.dart';
import '../widgets/transfer_progress.dart';

/// Base transfer screen: shows all active, queued, and completed transfers.
///
/// Grouped into "Active" and "Completed" sections with live speed
/// readouts and arc progress indicators.
class BaseTransferScreen extends ConsumerWidget {
  const BaseTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger haptics when a transfer completes
    ref.listen(transfersStreamProvider, (previous, next) {
      final prevList = previous?.value ?? [];
      final nextList = next.value ?? [];
      
      for (final nextT in nextList) {
        if (nextT.status == TransferStatus.completed) {
          final wasCompleted = prevList.any((t) => t.id == nextT.id && t.status == TransferStatus.completed);
          if (!wasCompleted) {
            HapticFeedback.heavyImpact();
          }
        }
      }
    });

    final transfersAsync = ref.watch(transfersStreamProvider);
    final tt = Theme.of(context).textTheme;
    final colors = BaseTheme.colors(context);

    return transfersAsync.when(
      data: (transfers) {
        final active = transfers
            .where((t) =>
                t.status == TransferStatus.active ||
                t.status == TransferStatus.paused ||
                t.status == TransferStatus.queued)
            .toList();
        final completed = transfers
            .where((t) =>
                t.status == TransferStatus.completed ||
                t.status == TransferStatus.failed)
            .toList();

        if (transfers.isEmpty) {
          return const _EmptyState();
        }

        return ListView(
          padding: const EdgeInsets.only(
            top: BaseTheme.spacingMd,
            bottom: BaseTheme.spacingXxl,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── Active transfers section ─────────────────────────────
            if (active.isNotEmpty) ...[
              _SectionHeader(
                title: 'ACTIVE',
                count: active.length,
                color: colors.secondaryGlow,
              ),
              ...active.map(
                (t) => TransferProgressCard(
                  transfer: t,
                  onCancel: () => ref.read(transferServiceProvider)
                      .cancelTransfer(t.id),
                  onPause: () => ref.read(transferServiceProvider)
                      .pauseTransfer(t.id),
                  onResume: () => ref.read(transferServiceProvider)
                      .resumeTransfer(t.id),
                ),
              ),
              const SizedBox(height: BaseTheme.spacingLg),
            ],

            // ── Completed transfers section ──────────────────────────
            if (completed.isNotEmpty) ...[
              _SectionHeader(
                title: 'HISTORY',
                count: completed.length,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              ...completed.map(
                (t) => TransferProgressCard(transfer: t),
              ),
            ],

            // ── Aggregate stats ──────────────────────────────────────
            if (transfers.isNotEmpty) ...[
              const SizedBox(height: BaseTheme.spacingLg),
              _StatsBar(transfers: transfers),
            ],
          ],
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: colors.primaryGlow),
      ),
      error: (err, _) => Center(
        child: Text('Error: $err', style: tt.bodyMedium),
      ),
    );
  }
}

/// Empty state shown when there are no transfers.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Technical HUD wireframe graphic
          const _HUDWireframe(),
          const SizedBox(height: BaseTheme.spacingLg),
          Text(
            'NO ACTIVE STREAMS',
            style: tt.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: BaseTheme.spacingSm),
          Text(
            'System idle. Connect to a peer node\nto begin data transmission.',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HUDWireframe extends StatefulWidget {
  const _HUDWireframe();

  @override
  State<_HUDWireframe> createState() => _HUDWireframeState();
}

class _HUDWireframeState extends State<_HUDWireframe> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 120),
          painter: _WireframePainter(
            progress: _controller.value,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _WireframePainter extends CustomPainter {
  final double progress;
  final Color color;

  _WireframePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw hexagonal wireframe
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Draw inner pulsing hexagon
    final pulseRadius = radius * (0.5 + 0.3 * sin(progress * 2 * pi).abs());
    final pulsePath = Path();
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + progress * pi / 3;
      final x = center.dx + pulseRadius * cos(angle);
      final y = center.dy + pulseRadius * sin(angle);
      if (i == 0) {
        pulsePath.moveTo(x, y);
      } else {
        pulsePath.lineTo(x, y);
      }
    }
    pulsePath.close();
    canvas.drawPath(pulsePath, paint..color = color.withValues(alpha: 0.6));

    // Draw outer segments
    final outerRadius = radius * 1.5;
    final segmentPaint = Paint()
      ..color = color.withValues(alpha: 0.2 + 0.4 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < 3; i++) {
      final startAngle = (i * 2 * pi / 3) + (progress * 2 * pi);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        pi / 4,
        false,
        segmentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WireframePainter oldDelegate) => true;
}

/// Section header with title, count badge, and divider.
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BaseTheme.spacingMd,
        vertical: BaseTheme.spacingSm,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: tt.labelMedium?.copyWith(color: color),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: tt.labelSmall?.copyWith(color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 0.5,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aggregate stats bar at the bottom of the transfer list.
class _StatsBar extends StatelessWidget {
  final List<Transfer> transfers;
  const _StatsBar({required this.transfers});

  @override
  Widget build(BuildContext context) {
    final colors = BaseTheme.colors(context);
    final totalBytes = transfers.fold<int>(
      0,
      (sum, t) => sum + (t.progress * t.fileSizeBytes).round(),
    );
    final completedCount =
        transfers.where((t) => t.status == TransferStatus.completed).length;

    // Format total bytes transferred.
    String totalFormatted;
    if (totalBytes < 1024 * 1024) {
      totalFormatted = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      totalFormatted =
          '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      totalFormatted =
          '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BaseTheme.spacingMd),
      padding: const EdgeInsets.all(BaseTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(BaseTheme.radiusMd),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'TRANSFERRED',
            value: totalFormatted,
            color: colors.primaryGlow,
          ),
          Container(width: 0.5, height: 32, color: Theme.of(context).dividerColor),
          _StatItem(
            label: 'COMPLETED',
            value: '$completedCount',
            color: colors.success,
          ),
          Container(width: 0.5, height: 32, color: Theme.of(context).dividerColor),
          _StatItem(
            label: 'TOTAL',
            value: '${transfers.length}',
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

/// Individual stat display.
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: tt.labelSmall),
      ],
    );
  }
}
