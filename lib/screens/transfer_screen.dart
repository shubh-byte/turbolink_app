import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/transfer.dart';
import '../core/di/service_locator.dart';
import '../core/theme/app_theme.dart';
import '../providers/transfer_provider.dart';
import '../widgets/transfer_progress.dart';

/// Transfer screen: shows all active, queued, and completed transfers.
///
/// Grouped into "Active" and "Completed" sections with live speed
/// readouts and arc progress indicators.
class TransferScreen extends ConsumerWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transfersStreamProvider);
    final tt = Theme.of(context).textTheme;

    return transfersAsync.when(
      data: (transfers) {
        final active = transfers
            .where((t) =>
                t.status == TransferStatus.active ||
                t.status == TransferStatus.queued)
            .toList();
        final completed = transfers
            .where((t) =>
                t.status == TransferStatus.completed ||
                t.status == TransferStatus.failed)
            .toList();

        if (transfers.isEmpty) {
          return _EmptyState();
        }

        return ListView(
          padding: const EdgeInsets.only(
            top: AppTheme.spacingMd,
            bottom: AppTheme.spacingXxl,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── Active transfers section ─────────────────────────────
            if (active.isNotEmpty) ...[
              _SectionHeader(
                title: 'ACTIVE',
                count: active.length,
                color: AppTheme.amber,
              ),
              ...active.map(
                (t) => TransferProgressCard(
                  transfer: t,
                  onCancel: () => ServiceLocator()
                      .transferService
                      .cancelTransfer(t.id),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // ── Completed transfers section ──────────────────────────
            if (completed.isNotEmpty) ...[
              _SectionHeader(
                title: 'HISTORY',
                count: completed.length,
                color: AppTheme.textTertiary,
              ),
              ...completed.map(
                (t) => TransferProgressCard(transfer: t),
              ),
            ],

            // ── Aggregate stats ──────────────────────────────────────
            if (transfers.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingLg),
              _StatsBar(transfers: transfers),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.cyan),
      ),
      error: (err, _) => Center(
        child: Text('Error: $err', style: tt.bodyMedium),
      ),
    );
  }
}

/// Empty state shown when there are no transfers.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated icon with glow.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.amberDim,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.amber.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.swap_vert_rounded,
              color: AppTheme.amber,
              size: 32,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'No transfers yet',
            style: tt.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Connect to a peer and send a file\nto start your first transfer.',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
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
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
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
              color: AppTheme.border,
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
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'TRANSFERRED',
            value: totalFormatted,
            color: AppTheme.cyan,
          ),
          Container(width: 0.5, height: 32, color: AppTheme.border),
          _StatItem(
            label: 'COMPLETED',
            value: '$completedCount',
            color: AppTheme.green,
          ),
          Container(width: 0.5, height: 32, color: AppTheme.border),
          _StatItem(
            label: 'TOTAL',
            value: '${transfers.length}',
            color: AppTheme.textSecondary,
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
