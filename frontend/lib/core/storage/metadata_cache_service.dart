import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_service.dart';

/// Tipos de metadado suportados para cache (sync via changelog).
enum MetadataCacheType {
  praise,
  praiseTag,
  materialKind,
  materialType,
}

/// Valor armazenado por item: payload + version (atualização só via changelog).
Map<String, dynamic> _storedValue({
  required Map<String, dynamic> payload,
  required String version,
}) =>
    {
      'payload': payload,
      'version': version,
    };

/// Serviço de cache de metadados (atualização exclusivamente via changelog).
/// Usa [HiveService.metadataBox] com prefixos de chave para não colidir com outros dados.
class MetadataCacheService {
  static const String _prefixPraise = 'meta_cache_praise_';
  static const String _prefixPraiseTag = 'meta_cache_praise_tag_';
  static const String _prefixMaterialKind = 'meta_cache_material_kind_';
  static const String _prefixMaterialType = 'meta_cache_material_type_';

  static Box get _box => HiveService.metadataBox;

  static String _key(MetadataCacheType type, String id) {
    switch (type) {
      case MetadataCacheType.praise:
        return '$_prefixPraise$id';
      case MetadataCacheType.praiseTag:
        return '$_prefixPraiseTag$id';
      case MetadataCacheType.materialKind:
        return '$_prefixMaterialKind$id';
      case MetadataCacheType.materialType:
        return '$_prefixMaterialType$id';
    }
  }

  static String _prefixFor(MetadataCacheType type) {
    switch (type) {
      case MetadataCacheType.praise:
        return _prefixPraise;
      case MetadataCacheType.praiseTag:
        return _prefixPraiseTag;
      case MetadataCacheType.materialKind:
        return _prefixMaterialKind;
      case MetadataCacheType.materialType:
        return _prefixMaterialType;
    }
  }

  /// Salva um item no cache com version.
  static Future<void> putItem(
    MetadataCacheType type,
    String id,
    Map<String, dynamic> payload,
    String version,
  ) async {
    await _box.put(
      _key(type, id),
      _storedValue(payload: payload, version: version),
    );
  }

  /// Retorna o payload do item se existir (não remove por expiração; sempre serve cache).
  static Map<String, dynamic>? getItem(MetadataCacheType type, String id) {
    final raw = _box.get(_key(type, id));
    if (raw == null || raw is! Map) return null;
    try {
      final payload = raw['payload'];
      if (payload is! Map<String, dynamic>) return null;
      return Map<String, dynamic>.from(payload);
    } catch (e) {
      debugPrint('MetadataCacheService.getItem parse error: $e');
      return null;
    }
  }

  /// Retorna a version armazenada do item, ou null se não existir.
  static String? getStoredVersion(MetadataCacheType type, String id) {
    final raw = _box.get(_key(type, id));
    if (raw == null || raw is! Map) return null;
    final v = raw['version'];
    return v is String ? v : null;
  }

  /// Retorna todos os payloads do tipo, em qualquer ordem (quem chama pode ordenar).
  static List<Map<String, dynamic>> getAll(MetadataCacheType type) {
    final prefix = _prefixFor(type);
    final keys = _box.keys
        .where((k) => k.toString().startsWith(prefix))
        .map((k) => k.toString())
        .toList();
    final out = <Map<String, dynamic>>[];
    for (final k in keys) {
      final raw = _box.get(k);
      if (raw == null || raw is! Map) continue;
      try {
        final payload = raw['payload'];
        if (payload is! Map<String, dynamic>) continue;
        out.add(Map<String, dynamic>.from(payload));
      } catch (_) {}
    }
    return out;
  }

  /// Remove um item do cache (somente após o novo ter sido baixado com sucesso).
  static Future<void> removeItem(MetadataCacheType type, String id) async {
    await _box.delete(_key(type, id));
  }

  /// Retorna true se existe pelo menos um item no cache deste tipo.
  static bool hasAny(MetadataCacheType type) {
    final prefix = _prefixFor(type);
    return _box.keys.any((k) => k.toString().startsWith(prefix));
  }

  /// Remove todos os itens do tipo do cache (ex.: clear de praises).
  static Future<void> removeAll(MetadataCacheType type) async {
    final prefix = _prefixFor(type);
    final keys = _box.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    for (final k in keys) {
      await _box.delete(k);
    }
  }
}
