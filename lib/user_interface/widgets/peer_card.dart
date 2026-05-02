import 'dart:math';
import 'package:flutter/material.dart';
import '../../backend/models/peer.dart';
import '../../core/theme_engine/base_theme.dart';

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
    final colors = BaseTheme.colors(context);
    final isOutOfRange = peer.signalStrength < 0.15;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isOutOfRange ? 0.6 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(
          horizontal: BaseTheme.spacingMd,
          vertical: BaseTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: peer.isConnected ? colors.primaryGlow.withValues(alpha: 0.1) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(BaseTheme.radiusMd),
          border: Border.all(
            color: peer.isConnected
                ? colors.primaryGlow.withValues(alpha: 0.3)
                : Theme.of(context).dividerColor,
            width: peer.isConnected ? 1.0 : 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(BaseTheme.radiusMd),
            onTap: isOutOfRange ? null : (peer.isConnected ? onSendFile : onConnect),
            child: Padding(
              padding: const EdgeInsets.all(BaseTheme.spacingMd),
              child: Row(
                children: [
                  // Device icon with glow.
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: peer.isConnected
                          ? colors.primaryGlow.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(BaseTheme.radiusSm),
                    ),
                    child: Icon(
                      _deviceIcon,
                      color: peer.isConnected
                          ? colors.primaryGlow
                          : Theme.of(context).iconTheme.color?.withValues(alpha: isOutOfRange ? 0.4 : 1.0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: BaseTheme.spacingMd),
  
                  // Name + signal bar.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          peer.name,
                          style: tt.titleMedium?.copyWith(
                            color: peer.isConnected
                                ? colors.primaryGlow
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: isOutOfRange ? 0.5 : 1.0),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _SignalBar(strength: peer.signalStrength, activeColor: isOutOfRange ? Colors.grey : colors.primaryGlow),
                      ],
                    ),
                  ),
  
                  // Action button.
                  if (isConnecting)
                    _HUDLoader(color: colors.primaryGlow)
                  else if (isOutOfRange)
                    _ActionChip(
                      label: 'OUT OF RANGE',
                      color: Colors.grey.withValues(alpha: 0.5),
                      onTap: () {},
                    )
                  else if (peer.isConnected) ...[
                    _ActionChip(
                      label: 'DISCONNECT',
                      color: colors.error.withValues(alpha: 0.6),
                      onTap: onDisconnect,
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      label: 'SEND',
                      color: colors.secondaryGlow,
                      onTap: onSendFile,
                    ),
                  ] else
                    _ActionChip(
                      label: 'LINK',
                      color: colors.primaryGlow,
                      onTap: onConnect,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom HUD-themed loader for connecting state.
class _HUDLoader extends StatefulWidget {
  final Color color;
  const _HUDLoader({required this.color});

  @override
  State<_HUDLoader> createState() => _HUDLoaderState();
}

class _HUDLoaderState extends State<_HUDLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
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
        return SizedBox(
          width: 24,
          height: 24,
          child: CustomPaint(
            painter: _HUDLoaderPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _HUDLoaderPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HUDLoaderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 3 rotating segments
    for (var i = 0; i < 3; i++) {
      final startAngle = (i * 2 * pi / 3) + (progress * 2 * pi);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        pi / 3,
        false,
        paint,
      );
    }

    // Draw inner pulsing dot
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.5 + 0.5 * sin(progress * 2 * pi).abs())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _HUDLoaderPainter oldDelegate) => true;
}

/// Tiny signal strength bar: 5 segments that fill based on [strength].
class _SignalBar extends StatelessWidget {
  final double strength;
  final Color activeColor;
  
  const _SignalBar({required this.strength, required this.activeColor});

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
                ? activeColor.withValues(alpha: 0.8)
                : Theme.of(context).dividerColor,
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
          borderRadius: BorderRadius.circular(BaseTheme.radiusSm),
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
