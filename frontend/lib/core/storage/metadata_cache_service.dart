import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_service.dart';

/// TTL do cache de metadados: 24 horas
const Duration metadataCacheTtl = Duration(hours: 24);

/// Tipos de metadado suportados para cache com revalidação
enum MetadataCacheType {
  praise,
  praiseTag,
  materialKind,
}

/// Valor armazenado por item: payload + version + expiresAt
Map<String, dynamic> _storedValue({
  required Map<String, dynamic> payload,
  required String version,
  required String expiresAt,
}) =>
    {
      'payload': payload,
      'version': version,
      'expiresAt': expiresAt,
    };

/// Serviço de cache de metadados com TTL 24h e revalidação por version/hash.
/// Usa [HiveService.metadataBox] com prefixos de chave para não colidir com outros dados.
class MetadataCacheService {
  static const String _prefixPraise = 'meta_cache_praise_';
  static const String _prefixPraiseTag = 'meta_cache_praise_tag_';
  static const String _prefixMaterialKind = 'meta_cache_material_kind_';

  static Box get _box => HiveService.metadataBox;

  static String _key(MetadataCacheType type, String id) {
    switch (type) {
      case MetadataCacheType.praise:
        return '$_prefixPraise$id';
      case MetadataCacheType.praiseTag:
        return '$_prefixPraiseTag$id';
      case MetadataCacheType.materialKind:
        return '$_prefixMaterialKind$id';
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
    }
  }

  /// Salva um item no cache com version e expiresAt = now + 24h.
  static Future<void> putItem(
    MetadataCacheType type,
    String id,
    Map<String, dynamic> payload,
    String version,
  ) async {
    final expiresAt =
        DateTime.now().add(metadataCacheTtl).toUtc().toIso8601String();
    await _box.put(
      _key(type, id),
      _storedValue(payload: payload, version: version, expiresAt: expiresAt),
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

  /// Retorna true se existe pelo menos um item do tipo com expiresAt < now.
  /// Usado para decidir se deve disparar revalidação em background.
  static bool hasAnyExpired(MetadataCacheType type) {
    final prefix = _prefixFor(type);
    final now = DateTime.now().toUtc();
    for (final key in _box.keys) {
      final k = key.toString();
      if (!k.startsWith(prefix)) continue;
      final raw = _box.get(k);
      if (raw == null || raw is! Map) continue;
      final expiresAt = raw['expiresAt'];
      if (expiresAt is! String) continue;
      final t = DateTime.tryParse(expiresAt);
      if (t != null && t.isBefore(now)) return true;
    }
    return false;
  }

  /// Retorna true se existe pelo menos um item no cache deste tipo.
  static bool hasAny(MetadataCacheType type) {
    final prefix = _prefixFor(type);
    return _box.keys.any((k) => k.toString().startsWith(prefix));
  }

  /// Retorna o expiresAt mais antigo entre os itens do tipo (ou null se vazio).
  static DateTime? oldestExpiresAt(MetadataCacheType type) {
    final prefix = _prefixFor(type);
    DateTime? oldest;
    for (final key in _box.keys) {
      final k = key.toString();
      if (!k.startsWith(prefix)) continue;
      final raw = _box.get(k);
      if (raw == null || raw is! Map) continue;
      final expiresAt = raw['expiresAt'];
      if (expiresAt is! String) continue;
      final t = DateTime.tryParse(expiresAt);
      if (t != null && (oldest == null || t.isBefore(oldest))) oldest = t;
    }
    return oldest;
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
