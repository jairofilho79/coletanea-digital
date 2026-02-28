/// Progresso do download em lote por material kind
class OfflineDownloadProgress {
  final int completed;
  final int total;
  final int failed;
  final int skipped;
  final int bytesDownloaded;
  final String? message;

  const OfflineDownloadProgress({
    required this.completed,
    required this.total,
    this.failed = 0,
    this.skipped = 0,
    this.bytesDownloaded = 0,
    this.message,
  });

  double get percentage => total > 0 ? (completed + failed + skipped) / total : 0.0;
}

/// Resultado final do download em lote
class OfflineDownloadResult {
  final int completed;
  final int failed;
  final int skipped;
  final int total;
  final List<String> errors;

  const OfflineDownloadResult({
    required this.completed,
    required this.failed,
    required this.skipped,
    required this.total,
    this.errors = const [],
  });
}
