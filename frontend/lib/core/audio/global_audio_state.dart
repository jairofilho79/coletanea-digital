/// Informações da faixa atual para exibição (drawer, app bar).
class CurrentAudioTrack {
  final String materialId;
  final String materialPath;
  final String displayName;
  final String? praiseName;
  final String? materialKindName;
  final String? materialKindId; // ID para tradução dinâmica

  const CurrentAudioTrack({
    required this.materialId,
    required this.materialPath,
    required this.displayName,
    this.praiseName,
    this.materialKindName,
    this.materialKindId,
  });
}

/// Estado do player global (usado pelo drawer e pela página de áudio).
class GlobalAudioState {
  final CurrentAudioTrack? track;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final String? error;

  const GlobalAudioState({
    this.track,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
  });

  bool get hasTrack => track != null;

  bool get isAtEnd =>
      duration.inMilliseconds > 0 && position >= duration;
}
