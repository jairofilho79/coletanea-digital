import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../config/app_config.dart';
import '../storage/providers.dart';
import 'global_audio_state.dart';

final globalAudioPlayerProvider =
    NotifierProvider<GlobalAudioPlayerNotifier, GlobalAudioState>(
  GlobalAudioPlayerNotifier.new,
);

class GlobalAudioPlayerNotifier extends Notifier<GlobalAudioState> {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  static const Duration _seekStep = Duration(seconds: 5);

  @override
  GlobalAudioState build() {
    ref.onDispose(() {
      _disposePlayer();
    });
    return const GlobalAudioState();
  }

  void _disposePlayer() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _player?.dispose();
    _player = null;
  }

  AudioPlayer get _requirePlayer {
    final p = _player;
    if (p == null) throw StateError('Player not initialized');
    return p;
  }

  String _buildDownloadUrl(String materialId) {
    final baseUrl = AppConfig.coldigomApiBaseUrl;
    return '$baseUrl/api/v1/praise-materials/$materialId/download';
  }

  /// Carrega e inicia a reprodução. Se já houver outra faixa, substitui.
  Future<void> loadAndPlay({
    required String materialId,
    required String materialPath,
    required String displayName,
    String? praiseName,
    String? materialKindName,
  }) async {
    _disposePlayer();
    state = GlobalAudioState(
      track: CurrentAudioTrack(
        materialId: materialId,
        materialPath: materialPath,
        displayName: displayName,
        praiseName: praiseName,
        materialKindName: materialKindName,
      ),
      isLoading: true,
    );

    final player = AudioPlayer();
    _player = player;

    void updateState({
      Duration? position,
      Duration? duration,
      bool? isPlaying,
      bool? isLoading,
      String? error,
    }) {
      state = GlobalAudioState(
        track: state.track,
        position: position ?? state.position,
        duration: duration ?? state.duration,
        isPlaying: isPlaying ?? state.isPlaying,
        isLoading: isLoading ?? state.isLoading,
        error: error ?? state.error,
      );
    }

    _subscriptions.add(player.playerStateStream.listen((s) {
      updateState(isPlaying: s.playing);
    }));
    _subscriptions.add(player.durationStream.listen((d) {
      if (d != null) updateState(duration: d);
    }));
    _subscriptions.add(player.positionStream.listen((p) {
      updateState(position: p);
    }));

    try {
      if (!kIsWeb) {
        final cacheService = ref.read(materialCacheServiceProvider);
        final cached = cacheService.getCachedMaterial(materialId);
        if (cached != null && await cached.exists()) {
          await player.setFilePath(cached.path);
          updateState(isLoading: false);
          await player.play();
          return;
        }
      }

      final url = _buildDownloadUrl(materialId);
      await player.setUrl(url);
      updateState(isLoading: false);
      await player.play();
    } catch (e) {
      updateState(isLoading: false, error: 'Erro ao carregar áudio: $e');
    }
  }

  /// Para e remove a faixa atual. O player é destruído.
  void close() {
    _disposePlayer();
    state = const GlobalAudioState();
  }

  Future<void> togglePlayPause() async {
    if (!state.hasTrack) return;
    try {
      final p = _requirePlayer;
      if (state.isPlaying) {
        await p.pause();
      } else {
        if (p.processingState == ProcessingState.completed) {
          await p.seek(Duration.zero);
        }
        await p.play();
      }
    } catch (e) {
      state = GlobalAudioState(
        track: state.track,
        position: state.position,
        duration: state.duration,
        isPlaying: state.isPlaying,
        isLoading: false,
        error: 'Erro: $e',
      );
    }
  }

  Future<void> seekForward() async {
    if (!state.hasTrack) return;
    final newPosition = state.position + _seekStep;
    final target = newPosition < state.duration ? newPosition : state.duration;
    await _requirePlayer.seek(target);
  }

  Future<void> seekBackward() async {
    if (!state.hasTrack) return;
    final newPosition = state.position - _seekStep;
    final target = newPosition > Duration.zero ? newPosition : Duration.zero;
    await _requirePlayer.seek(target);
  }

  Future<void> seek(Duration position) async {
    if (!state.hasTrack) return;
    await _requirePlayer.seek(position);
  }

  /// Retry após erro (recarrega a mesma faixa).
  Future<void> retry() async {
    final t = state.track;
    if (t == null) return;
    await loadAndPlay(
      materialId: t.materialId,
      materialPath: t.materialPath,
      displayName: t.displayName,
      praiseName: t.praiseName,
      materialKindName: t.materialKindName,
    );
  }
}
