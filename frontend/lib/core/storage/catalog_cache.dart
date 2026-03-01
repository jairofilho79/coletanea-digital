import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'metadata_cache_service.dart';

/// Cache frio para listas de catálogo (material-kinds) via MetadataCacheService (TTL 24h, revalidação por version).
class CatalogCache {
  static String _versionFromIdName(String id, String name) {
    final bytes = utf8.encode('$id:$name');
    return sha256.convert(bytes).toString();
  }

  /// Salva lista de material kinds no cache (cada item com version e TTL 24h)
  static Future<void> setMaterialKinds(List<Map<String, String>> list) async {
    for (final e in list) {
      final id = e['id'] ?? '';
      final name = e['name'] ?? '';
      if (id.isEmpty) continue;
      final payload = {'id': id, 'name': name};
      final version = _versionFromIdName(id, name);
      await MetadataCacheService.putItem(
        MetadataCacheType.materialKind,
        id,
        payload,
        version,
      );
    }
  }

  /// Retorna material kinds do cache (sempre do cache se houver dados; revalidação em background)
  static List<Map<String, String>>? getMaterialKinds() {
    final list = MetadataCacheService.getAll(MetadataCacheType.materialKind);
    if (list.isEmpty) return null;
    return list
        .map((e) => {
              'id': (e['id'] as String?) ?? '',
              'name': (e['name'] as String?) ?? '',
            })
        .where((e) => e['id']!.isNotEmpty)
        .toList();
  }
}
