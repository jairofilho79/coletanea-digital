import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/audio/global_audio_player_provider.dart';
import '../../../../core/audio/global_audio_state.dart';
import '../../../../core/widgets/app_bar_title_with_logo.dart';
import '../../../../core/widgets/app_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leitor de áudio: usa o player global. Voltar apenas sai da tela (player continua).
/// Botão X fecha o player e sai da tela.
class AudioReaderPage extends ConsumerStatefulWidget {
  final String materialId;
  final String materialPath;
  final String? materialName;
  final String? praiseName;
  final String? materialKindName;
  final String? materialKindId;

  const AudioReaderPage({
    super.key,
    required this.materialId,
    required this.materialPath,
    this.materialName,
    this.praiseName,
    this.materialKindName,
    this.materialKindId,
  });

  @override
  ConsumerState<AudioReaderPage> createState() => _AudioReaderPageState();
}

class _AudioReaderPageState extends ConsumerState<AudioReaderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTrackLoaded());
  }

  void _ensureTrackLoaded() {
    final state = ref.read(globalAudioPlayerProvider);
    final displayName = widget.materialName ?? 'Áudio';
    if (!state.hasTrack || state.track!.materialId != widget.materialId) {
      ref.read(globalAudioPlayerProvider.notifier).loadAndPlay(
            materialId: widget.materialId,
            materialPath: widget.materialPath,
            displayName: displayName,
            praiseName: widget.praiseName,
            materialKindName: widget.materialKindName,
            materialKindId: widget.materialKindId,
          );
    }
  }

  void _closePlayerAndPop() {
    ref.read(globalAudioPlayerProvider.notifier).close();
    if (mounted) context.pop();
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalAudioPlayerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButtonWithDrawerOnLongPress(),
        title: AppBarTitleWithLogo(
          title: Text(state.track?.displayName ?? widget.materialName ?? 'Áudio'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Fechar player',
            onPressed: _closePlayerAndPop,
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(GlobalAudioState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando áudio...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(globalAudioPlayerProvider.notifier)
                    .retry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final notifier = ref.read(globalAudioPlayerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: Colors.amber.shade300,
              inactiveTrackColor: Colors.grey.shade600,
              thumbColor: Colors.amber.shade300,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: state.duration.inMilliseconds > 0
                  ? (state.position.inMilliseconds /
                          state.duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0,
              onChanged: state.duration.inMilliseconds > 0
                  ? (v) {
                      final pos = Duration(
                        milliseconds: (v * state.duration.inMilliseconds)
                            .round(),
                      );
                      notifier.seek(pos);
                    }
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(state.position),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white),
                ),
                Text(
                  _formatDuration(state.duration),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                iconSize: 40,
                onPressed: notifier.seekBackward,
                icon: const Icon(Icons.replay_5),
                tooltip: 'Voltar 5s',
              ),
              const SizedBox(width: 24),
              IconButton.filled(
                iconSize: 56,
                onPressed: notifier.togglePlayPause,
                icon: Icon(
                  state.isAtEnd
                      ? Icons.replay
                      : (state.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
                ),
                tooltip: state.isAtEnd
                    ? 'Recomeçar'
                    : (state.isPlaying ? 'Pausar' : 'Reproduzir'),
              ),
              const SizedBox(width: 24),
              IconButton.filled(
                iconSize: 40,
                onPressed: notifier.seekForward,
                icon: const Icon(Icons.forward_5),
                tooltip: 'Avançar 5s',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
