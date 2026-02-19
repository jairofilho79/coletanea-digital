// Utilitários para extração de video ID a partir de URLs ou strings do YouTube.

final _youtubeIdFromUrl = RegExp(
  r'(?:youtube\.com/(?:watch\?v=|embed/)|youtu\.be/)([a-zA-Z0-9_-]{11})(?:[&\s?#]|$)',
);
final _rawId = RegExp(r'^([a-zA-Z0-9_-]{11})$');

/// Extrai o ID do vídeo YouTube a partir de uma URL ou string.
///
/// Aceita:
/// - https://www.youtube.com/watch?v=VIDEO_ID
/// - https://youtube.com/embed/VIDEO_ID
/// - https://youtu.be/VIDEO_ID
/// - String de 11 caracteres (ID puro)
///
/// Retorna o ID (11 caracteres) ou null se não for possível extrair.
String? extractYoutubeVideoId(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final s = value.trim();
  final urlMatch = _youtubeIdFromUrl.firstMatch(s);
  if (urlMatch != null) return urlMatch.group(1);
  if (_rawId.hasMatch(s)) return s;
  return null;
}
