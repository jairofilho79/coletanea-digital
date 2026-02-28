import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';

/// TTL do cache frio de traduções: 24 horas (renovar só em refresh explícito ou após esse tempo)
const Duration _translationsCacheTtl = Duration(hours: 24);

/// Data source local para traduções (Hive cache com TTL longo - cache frio)
class TranslationLocalDataSource {
  Box get _box => HiveService.translationsBox;

  /// Salva traduções no cache com timestamp
  /// [languageCode] código do idioma (ex: 'pt')
  /// [translations] mapa de entityId -> translatedName
  /// [type] tipo de tradução: 'material_kind', 'praise_tag', ou 'material_type'
  Future<void> cacheTranslations(
    String languageCode,
    Map<String, String> translations,
    String type,
  ) async {
    final key = _getCacheKey(languageCode, type);
    await _box.put(key, {
      'data': translations,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Obtém traduções do cache se ainda válidas (dentro do TTL)
  /// Retorna null se não encontrado ou expirado
  Map<String, String>? getCachedTranslations(String languageCode, String type) {
    final key = _getCacheKey(languageCode, type);
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = raw as Map<dynamic, dynamic>;
      final cachedAtStr = map['cachedAt'] as String?;
      final data = map['data'];
      if (cachedAtStr == null || data == null) return null;
      final cachedAt = DateTime.tryParse(cachedAtStr);
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > _translationsCacheTtl) {
        return null;
      }
      return Map<String, String>.from(data as Map);
    } catch (e) {
      return null;
    }
  }

  /// Limpa cache de um idioma específico ou todos se languageCode for null
  Future<void> clearCache(String? languageCode) async {
    if (languageCode == null) {
      // Limpa todo o cache de traduções
      await _box.clear();
    } else {
      // Limpa apenas traduções do idioma específico
      final types = ['material_kind', 'praise_tag', 'material_type'];
      for (final type in types) {
        final key = _getCacheKey(languageCode, type);
        await _box.delete(key);
      }
    }
  }

  /// Gera chave de cache no formato: 'translations:{languageCode}:{type}'
  String _getCacheKey(String languageCode, String type) {
    return 'translations:$languageCode:$type';
  }
}
