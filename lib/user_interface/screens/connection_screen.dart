import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../backend/models/peer.dart';
import '../../backend/models/transfer.dart';
import '../../core/theme_engine/base_theme.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/mock_mode_provider.dart';
import '../../providers/discovery_provider.dart';
import '../widgets/transfer_progress.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  final Peer peer;
  const ConnectionScreen({super.key, required this.peer});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  bool _isPickerActive = false;

  @override
  void initState() {
    super.initState();
    // Start listening for files via the FFI layer.
    ref.read(transferServiceProvider).startListeningForFiles(widget.peer);
  }

  Future<void> _sendFile() async {
    if (_isPickerActive) return;

    final isMock = ref.read(mockModeProvider);
    _isPickerActive = true;
    FilePickerResult? result;

    try {
      result = await FilePicker.pickFiles(withReadStream: isMock);
    } on PlatformException catch (e) {
      debugPrint('[TurboLink] FilePicker error: ${e.code} - ${e.message}');
      return;
    } finally {
      _isPickerActive = false;
    }

    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    ref.read(transferServiceProvider).sendFile(
      peerId: widget.peer.id,
      peerName: widget.peer.name,
      fileUri: file.identifier ?? file.path ?? '',
      fileName: file.name,
      fileSizeBytes: file.size,
    );

    if (isMock) {
      FilePicker.clearTemporaryFiles();
    }
  }

  void _disconnect() {
    ref.read(discoveryServiceProvider).disconnectFromPeer(widget.peer.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseTheme.colors(context);
    final allTransfers = ref.watch(transfersStreamProvider).value ?? [];
    
    // Filter transfers only for this specific peer.
    final peerTransfers = allTransfers.where((t) => t.peerId == widget.peer.id).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.peer.isConnected ? colors.success : colors.error,
                boxShadow: widget.peer.isConnected ? [
                  BoxShadow(color: colors.success.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)
                ] : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.peer.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.link_off_rounded, color: colors.error),
            onPressed: _disconnect,
            tooltip: 'Disconnect',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: peerTransfers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CONNECTION ESTABLISHED',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      letterSpacing: 2.0,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Both of you can now select and send files simultaneously.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(BaseTheme.spacingLg),
              itemCount: peerTransfers.length,
              itemBuilder: (context, index) {
                final t = peerTransfers[index];
                final isSending = t.direction == TransferDirection.sending;

                return Align(
                  alignment: isSending ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.only(bottom: BaseTheme.spacingLg),
                    child: TransferProgressCard(
                      transfer: t,
                      onCancel: () => ref.read(transferServiceProvider).cancelTransfer(t.id),
                      onPause: () => ref.read(transferServiceProvider).pauseTransfer(t.id),
                      onResume: () => ref.read(transferServiceProvider).resumeTransfer(t.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sendFile,
        backgroundColor: colors.primaryGlow,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('SEND FILE', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
