import 'package:flutter/material.dart';
import '../backend/models/peer.dart';
import '../core/theme/app_theme.dart';

/// A single peer device card shown in the list view below the radar.
///
/// Displays device name, type icon, signal strength bar, and connection
/// status with a connect/disconnect action button.
class PeerCard extends StatelessWidget {
  final Peer peer;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onSendFile;

  const PeerCard({
    super.key,
    required this.peer,
    this.isConnecting = false,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSendFile,
  });

  IconData get _deviceIcon {
    switch (peer.deviceType) {
      case 'tablet':
        return Icons.tablet_android_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      default:
        return Icons.phone_android_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: peer.isConnected ? AppTheme.cyanDim : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: peer.isConnected
              ? AppTheme.cyan.withValues(alpha: 0.3)
              : AppTheme.border,
          width: peer.isConnected ? 1.0 : 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: peer.isConnected ? onSendFile : onConnect,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                // Device icon with glow.
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: peer.isConnected
                        ? AppTheme.cyan.withValues(alpha: 0.15)
                        : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    _deviceIcon,
                    color: peer.isConnected
                        ? AppTheme.cyan
                        : AppTheme.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),

                // Name + signal bar.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer.name,
                        style: tt.titleMedium?.copyWith(
                          color: peer.isConnected
                              ? AppTheme.cyan
                              : AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _SignalBar(strength: peer.signalStrength),
                    ],
                  ),
                ),

                // Action button.
                if (isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.cyan,
                    ),
                  )
                else if (peer.isConnected)
                  _ActionChip(
                    label: 'SEND',
                    color: AppTheme.amber,
                    onTap: onSendFile,
                  )
                else
                  _ActionChip(
                    label: 'LINK',
                    color: AppTheme.cyan,
                    onTap: onConnect,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny signal strength bar: 5 segments that fill based on [strength].
class _SignalBar extends StatelessWidget {
  final double strength;
  const _SignalBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final threshold = (i + 1) / 5;
        final active = strength >= threshold;
        return Container(
          width: 6,
          height: 4 + (i * 2.0),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.cyan.withValues(alpha: 0.8)
                : AppTheme.border,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

/// Small labeled action chip used on peer cards.
class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontSize: 11,
                letterSpacing: 2,
              ),
        ),
      ),
    );
  }
}
