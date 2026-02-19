import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';

/// Data source local para traduções (Hive cache)
class TranslationLocalDataSource {
  Box get _box => HiveService.translationsBox;

  /// Salva traduções no cache
  /// [languageCode] código do idioma (ex: 'pt')
  /// [translations] mapa de entityId -> translatedName
  /// [type] tipo de tradução: 'material_kind', 'praise_tag', ou 'material_type'
  Future<void> cacheTranslations(
    String languageCode,
    Map<String, String> translations,
    String type,
  ) async {
    final key = _getCacheKey(languageCode, type);
    await _box.put(key, translations);
  }

  /// Obtém traduções do cache
  /// Retorna null se não encontrado
  Map<String, String>? getCachedTranslations(String languageCode, String type) {
    final key = _getCacheKey(languageCode, type);
    final data = _box.get(key);
    if (data == null) {
      return null;
    }
    try {
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
