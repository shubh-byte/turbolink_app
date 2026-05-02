import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../backend/models/peer.dart';
import '../../core/theme_engine/base_theme.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/navigation_provider.dart';
import '../widgets/peer_card.dart';
import '../widgets/radar_painter.dart';

/// Base home screen: peer discovery with radar visualization.
///
/// All UI aesthetics extend this class. The visual differences come
/// from the active TurboColors ThemeExtension, not from different code.
class BaseHomeScreen extends ConsumerStatefulWidget {
  const BaseHomeScreen({super.key});

  @override
  ConsumerState<BaseHomeScreen> createState() => _BaseHomeScreenState();
}

class _BaseHomeScreenState extends ConsumerState<BaseHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  Future<void> _disconnectFromPeer(Peer peer) async {
    final colors = BaseTheme.colors(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('TERMINATE LINK', style: Theme.of(context).textTheme.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to disconnect from:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    peer.deviceType == 'laptop' ? Icons.laptop_rounded : Icons.phone_android_rounded,
                    color: colors.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(peer.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.error)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DISCONNECT'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      await ref.read(discoveryServiceProvider).disconnectFromPeer(peer.id);
    }
  }

  Future<void> _disconnectAllPeers(List<Peer> connectedPeers) async {
    final colors = BaseTheme.colors(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('TERMINATE ALL LINKS', style: Theme.of(context).textTheme.headlineMedium),
        content: Text(
          'This will sever all ${connectedPeers.length} active links. Active transfers may be interrupted.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DISCONNECT ALL'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.heavyImpact();
      for (final peer in connectedPeers) {
        await ref.read(discoveryServiceProvider).disconnectFromPeer(peer.id);
      }
    }
  }

  Future<void> _connectToPeer(Peer peer) async {
    final colors = BaseTheme.colors(context);
    // Show confirmation dialog before connecting
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('LINK ESTABLISHMENT', style: Theme.of(context).textTheme.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to establish a secure link with:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryGlow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.primaryGlow.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    peer.deviceType == 'laptop' ? Icons.laptop_rounded : Icons.phone_android_rounded,
                    color: colors.primaryGlow,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(peer.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.primaryGlow)),
                        Text('SIGNAL: ${(peer.signalStrength * 100).toInt()}%', style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ABORT', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryGlow,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('AUTHORIZE', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticFeedback.lightImpact();
    ref.read(connectingPeerIdProvider.notifier).state = peer.id;
    await ref.read(discoveryServiceProvider).connectToPeer(peer.id);
    if (mounted) {
      ref.read(connectingPeerIdProvider.notifier).state = null;
    }
  }

  Future<void> _sendFileToPeer(Peer peer) async {
    final colors = BaseTheme.colors(context);
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    ref.read(transferServiceProvider).sendFile(
      peerId: peer.id,
      peerName: peer.name,
      filePath: file.path ?? '',
      fileName: file.name,
      fileSizeBytes: file.size,
    );

    // Switch to TRANSFERS tab
    ref.read(navigationProvider.notifier).state = 1;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'TRANSFER INITIATED: ${file.name}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.primaryGlow,
              letterSpacing: 1.2,
            ),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BaseTheme.radiusMd),
            side: BorderSide(color: colors.primaryGlow, width: 0.5),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final peersAsync = ref.watch(discoveryStreamProvider);
    final connectingId = ref.watch(connectingPeerIdProvider);
    final tt = Theme.of(context).textTheme;
    final colors = BaseTheme.colors(context);

    return Column(
      children: [
        // ── Radar section ────────────────────────────────────────────
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(24.0), // Increased safety margin for "Deep Space" orbits
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none, // Allow peers to orbit outside
              children: [
                // Static background (rings)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: StaticRadarPainter(colors: colors),
                    size: Size.infinite,
                  ),
                ),

                // Rotating sweep
                AnimatedBuilder(
                  animation: _sweepController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: SweepPainter(
                        sweepAngle: _sweepController.value * 2 * pi,
                        colors: colors,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),

                // Peer dots
                peersAsync.when(
                  data: (peers) => _PeerDots(
                    peers: peers,
                    onTap: (peer) {
                      if (peer.isConnected) {
                        _disconnectFromPeer(peer);
                      } else {
                        _connectToPeer(peer);
                      }
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),

                // "SCANNING" label
                Positioned(
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _sweepController,
                    builder: (context, child) {
                      final opacity = (sin(_sweepController.value * 2 * pi) + 1) / 2;
                      return Opacity(
                        opacity: 0.4 + opacity * 0.6,
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.primaryGlow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SCANNING',
                          style: tt.labelMedium?.copyWith(
                            color: colors.primaryGlow,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Removed Divider to create a seamless transition

        Padding(
          padding: const EdgeInsets.fromLTRB(
            BaseTheme.spacingMd,
            BaseTheme.spacingMd,
            BaseTheme.spacingMd,
            BaseTheme.spacingSm,
          ),
          child: Row(
            children: [
              Text('NEARBY', style: tt.labelMedium),
              const SizedBox(width: 8),
              peersAsync.when(
                data: (peers) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primaryGlow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${peers.length}',
                    style: tt.labelSmall?.copyWith(color: colors.primaryGlow),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const Spacer(),
              peersAsync.when(
                data: (peers) {
                  final connected = peers.where((p) => p.isConnected).toList();
                  if (connected.isEmpty) return const SizedBox.shrink();
                  return TextButton.icon(
                    onPressed: () => _disconnectAllPeers(connected),
                    icon: Icon(Icons.link_off_rounded, size: 16, color: colors.error),
                    label: Text(
                      'DISCONNECT ALL',
                      style: tt.labelSmall?.copyWith(color: colors.error, fontWeight: FontWeight.bold),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        Expanded(
          flex: 5,
          child: peersAsync.when(
            data: (peers) {
              if (peers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        size: 40,
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: BaseTheme.spacingSm),
                      Text('Searching for peers...', style: tt.bodyMedium),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: BaseTheme.spacingLg),
                physics: const BouncingScrollPhysics(),
                itemCount: peers.length,
                itemBuilder: (context, index) {
                  final peer = peers[index];
                  return PeerCard(
                    peer: peer,
                    isConnecting: connectingId == peer.id,
                    onConnect: () => _connectToPeer(peer),
                    onDisconnect: () => _disconnectFromPeer(peer),
                    onSendFile: () => _sendFileToPeer(peer),
                  );
                },
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: colors.primaryGlow),
            ),
            error: (err, _) => Center(
              child: Text('Discovery error: $err', style: tt.bodyMedium),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeerDots extends StatelessWidget {
  final List<Peer> peers;
  final ValueChanged<Peer> onTap;

  const _PeerDots({required this.peers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final maxRadius = min(constraints.maxWidth, constraints.maxHeight) / 2;

        return Stack(
          clipBehavior: Clip.none, // Allow dots to float in Deep Space
          children: peers.asMap().entries.map((entry) {
            final index = entry.key;
            final peer = entry.value;

            // Signal strength maps to radius. 0.0 is edge, 1.0 is center.
            // We allow them to go beyond the rings (signalStrength < 0.1)
            final distance = maxRadius * (1.1 - peer.signalStrength * 0.95);
            final angle = index * 2.399 + 0.5;

            final x = center.dx + distance * cos(angle) - 16;
            final y = center.dy + distance * sin(angle) - 16;

            final isDeepSpace = peer.signalStrength < 0.15;

            return Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onTap: isDeepSpace ? null : () => onTap(peer),
                child: _PeerDot(peer: peer, allPeers: peers),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

String _getPeerInitial(Peer peer, List<Peer> allPeers) {
  final name = peer.name.trim();
  if (name.isEmpty) return '?';
  
  final sameInitialPeers = allPeers.where((p) => p.name.isNotEmpty && p.name[0].toUpperCase() == name[0].toUpperCase()).toList();
  
  if (sameInitialPeers.length <= 1) return name[0].toUpperCase();
  
  // Collision detected. Try two letters if it's a multi-word name.
  final parts = name.split(RegExp(r'\s+'));
  if (parts.length > 1 && parts[1].isNotEmpty) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  
  if (name.length > 1) {
    // Check if the two-letter version is also a collision
    final twoLetter = name.substring(0, 2).toUpperCase();
    final sameTwoLetterPeers = allPeers.where((p) => p.name.length >= 2 && p.name.substring(0, 2).toUpperCase() == twoLetter).toList();
    if (sameTwoLetterPeers.length <= 1) return twoLetter;
  }
  
  // Last resort: Initial + unique index in the current scan results
  final index = sameInitialPeers.indexOf(peer) + 1;
  return '${name[0].toUpperCase()}$index';
}

class _PeerDot extends StatefulWidget {
  final Peer peer;
  final List<Peer> allPeers;
  const _PeerDot({required this.peer, required this.allPeers});

  @override
  State<_PeerDot> createState() => _PeerDotState();
}

class _PeerDotState extends State<_PeerDot> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        HapticFeedback.lightImpact(); // Haptic on discovery
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseTheme.colors(context);
    final isDeepSpace = widget.peer.signalStrength < 0.15;
    
    // Deep Space Styling: Fade and Desaturate when outside main rings
    final baseColor = widget.peer.isConnected ? colors.success : colors.primaryGlow;
    final color = isDeepSpace 
        ? Color.lerp(baseColor, Colors.grey.withValues(alpha: 0.5), 0.7)!
        : baseColor;
    
    final opacity = isDeepSpace ? 0.4 : 1.0;
    final scaleMult = isDeepSpace ? 0.8 : (widget.peer.isConnected ? 1.2 : 1.0);
    
    final initial = _getPeerInitial(widget.peer, widget.allPeers);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: _isVisible ? opacity : 0.0,
      curve: Curves.easeInOut,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 600),
        scale: _isVisible ? scaleMult : 0.5,
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseValue = _pulseController.value;
            final scale = 1.0 + pulseValue * (isDeepSpace ? 0.05 : 0.15);
            
            return Stack(
              alignment: Alignment.center,
              children: [
                // Secondary pulsing ring for connected peers
                if (widget.peer.isConnected && !isDeepSpace)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.secondaryGlow.withValues(alpha: 0.3 * (1 - pulseValue)),
                        width: 2.0,
                      ),
                    ),
                  ),
                
                Transform.scale(
                  scale: scale, 
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: widget.peer.isConnected ? 0.8 : 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.peer.isConnected ? color : color.withValues(alpha: 0.8), 
                        width: widget.peer.isConnected ? 2.5 : 1.5,
                      ),
                      boxShadow: isDeepSpace ? null : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: widget.peer.isConnected ? 12 : 8,
                          spreadRadius: widget.peer.isConnected ? 2 : 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: widget.peer.isConnected ? Theme.of(context).colorScheme.surface : color,
                          fontSize: widget.peer.isConnected ? 14 : 12, 
                          fontWeight: FontWeight.w900,
                          shadows: widget.peer.isConnected ? null : (isDeepSpace ? null : [
                            Shadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
