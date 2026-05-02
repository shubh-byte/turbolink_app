import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../backend/models/peer.dart';
import '../core/di/service_locator.dart';
import '../core/theme/app_theme.dart';
import '../providers/discovery_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/peer_card.dart';
import '../widgets/radar_painter.dart';

/// Home screen: peer discovery with radar visualization.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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

  Future<void> _connectToPeer(Peer peer) async {
    // Show confirmation dialog before connecting
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('LINK ESTABLISHMENT', style: GoogleFonts.unbounded(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to establish a secure link with:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    peer.deviceType == 'laptop' ? Icons.laptop_rounded : Icons.phone_android_rounded,
                    color: AppTheme.cyan,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(peer.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.cyan)),
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
            child: Text('ABORT', style: GoogleFonts.sourceCodePro(color: AppTheme.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('AUTHORIZE', style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticFeedback.lightImpact();
    ref.read(connectingPeerIdProvider.notifier).state = peer.id;
    await ServiceLocator().discoveryService.connectToPeer(peer.id);
    if (mounted) {
      ref.read(connectingPeerIdProvider.notifier).state = null;
    }
  }

  Future<void> _sendFileToPeer(Peer peer) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    ServiceLocator().transferService.sendFile(
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
            style: GoogleFonts.sourceCodePro(
              color: AppTheme.cyan,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: const BorderSide(color: AppTheme.cyan, width: 0.5),
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

    return Column(
      children: [
        // ── Radar section ────────────────────────────────────────────
        Expanded(
          flex: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Static background (rings)
              const RepaintBoundary(
                child: CustomPaint(
                  painter: StaticRadarPainter(),
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
                      _sendFileToPeer(peer);
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
                bottom: AppTheme.spacingMd,
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
                        decoration: const BoxDecoration(
                          color: AppTheme.cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SCANNING',
                        style: tt.labelMedium?.copyWith(
                          color: AppTheme.cyan,
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

        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          color: Theme.of(context).dividerColor,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingMd,
            AppTheme.spacingMd,
            AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Text('NEARBY', style: tt.labelMedium),
              const SizedBox(width: 8),
              peersAsync.when(
                data: (peers) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${peers.length}',
                    style: tt.labelSmall?.copyWith(color: AppTheme.cyan),
                  ),
                ),
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
                      const SizedBox(height: AppTheme.spacingSm),
                      Text('Searching for peers...', style: tt.bodyMedium),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
                physics: const BouncingScrollPhysics(),
                itemCount: peers.length,
                itemBuilder: (context, index) {
                  final peer = peers[index];
                  return PeerCard(
                    peer: peer,
                    isConnecting: connectingId == peer.id,
                    onConnect: () => _connectToPeer(peer),
                    onDisconnect: () => ServiceLocator().discoveryService.disconnectFromPeer(peer.id),
                    onSendFile: () => _sendFileToPeer(peer),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.cyan),
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
          children: peers.asMap().entries.map((entry) {
            final index = entry.key;
            final peer = entry.value;

            final distance = maxRadius * (1.0 - peer.signalStrength * 0.85);
            final angle = index * 2.399 + 0.5;

            final x = center.dx + distance * cos(angle) - 16;
            final y = center.dy + distance * sin(angle) - 16;

            return Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onTap: () => onTap(peer),
                child: _PeerDot(peer: peer),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PeerDot extends StatefulWidget {
  final Peer peer;
  const _PeerDot({required this.peer});

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
    final color = widget.peer.isConnected ? AppTheme.green : AppTheme.radarDot;
    final initial = widget.peer.name.isNotEmpty ? widget.peer.name[0] : '?';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _isVisible ? 1.0 : 0.0,
      curve: Curves.easeIn,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 400),
        scale: _isVisible ? 1.0 : 0.5,
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + _pulseController.value * 0.15;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
