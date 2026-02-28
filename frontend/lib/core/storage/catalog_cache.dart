import 'package:hive_flutter/hive_flutter.dart';

import 'hive_service.dart';

/// TTL do cache frio de catálogos (material-kinds, etc.): 24 horas
const Duration catalogCacheTtl = Duration(hours: 24);

const String _keyMaterialKinds = 'catalog_material_kinds';
const String _keyMaterialKindsAt = 'catalog_material_kinds_at';

/// Cache frio para listas de catálogo (material-kinds, etc.) — reduz chamadas à API.
class CatalogCache {
  static Box get _box => HiveService.settingsBox;

  /// Salva lista de material kinds (lista de mapas com id e name)
  static Future<void> setMaterialKinds(List<Map<String, String>> list) async {
    await _box.put(_keyMaterialKinds, list);
    await _box.put(_keyMaterialKindsAt, DateTime.now().toIso8601String());
  }

  /// Retorna material kinds do cache se ainda válido; caso contrário null.
  static List<Map<String, String>>? getMaterialKinds() {
    final at = _box.get(_keyMaterialKindsAt);
    if (at == null) return null;
    try {
      final t = DateTime.tryParse(at as String);
      if (t == null || DateTime.now().difference(t) > catalogCacheTtl) {
        return null;
      }
    } catch (e) {
      return null;
    }
    final data = _box.get(_keyMaterialKinds);
    if (data == null) return null;
    try {
      return (data as List<dynamic>)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    } catch (e) {
      return null;
    }
  }
}
