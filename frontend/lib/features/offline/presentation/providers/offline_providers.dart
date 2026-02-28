import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/storage/catalog_cache.dart';
import '../../../../core/storage/providers.dart';

/// Item simples de material kind (id + nome) da API
class MaterialKindItem {
  final String id;
  final String name;

  MaterialKindItem({required this.id, required this.name});
}

/// Lista de material kinds (cache frio 24h, depois API coldigom para "Baixar por tipo")
final materialKindsFromApiProvider =
    FutureProvider<List<MaterialKindItem>>((ref) async {
  final cached = CatalogCache.getMaterialKinds();
  if (cached != null && cached.isNotEmpty) {
    return cached
        .map((e) => MaterialKindItem(
              id: e['id'] ?? '',
              name: e['name'] ?? '',
            ))
        .where((e) => e.id.isNotEmpty)
        .toList();
  }
  final client = ref.read(coldigomClientProvider);
  final response = await client.get<List<dynamic>>('/api/v1/material-kinds/');
  if (response.data == null) return [];
  final list = <MaterialKindItem>[];
  final toCache = <Map<String, String>>[];
  for (final raw in response.data!) {
    if (raw is! Map<String, dynamic>) continue;
    final id = raw['id'] as String?;
    final name = raw['name'] as String? ?? '';
    if (id != null && id.isNotEmpty) {
      list.add(MaterialKindItem(id: id, name: name));
      toCache.add({'id': id, 'name': name});
    }
  }
  if (toCache.isNotEmpty) {
    await CatalogCache.setMaterialKinds(toCache);
  }
  return list;
});
