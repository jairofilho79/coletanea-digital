import 'package:flutter/foundation.dart';

import '../network/coldigom_client.dart';
import 'metadata_cache_service.dart';

/// Executa revalidação do cache de metadados em background: busca manifesto,
/// compara versions, baixa apenas itens alterados e substitui no cache só após sucesso.
/// Não remove metadado antes de ter o novo; se offline, não faz nada.
class MetadataRevalidationRunner {
  MetadataRevalidationRunner(this._client);

  final ColdigomClient _client;

  static const String _manifestPath = '/api/v1/metadata/manifest';

  /// Executa revalidação se [isOnline] for true. Se offline, retorna sem alterar cache.
  /// Só busca manifesto se o cache tiver algum item expirado (ou não tiver dados).
  Future<void> revalidateIfNeeded(bool isOnline) async {
    if (!isOnline) return;

    final shouldRun = MetadataCacheType.values.any((t) =>
        MetadataCacheService.hasAnyExpired(t) || !MetadataCacheService.hasAny(t));
    if (!shouldRun) return;

    try {
      final response =
          await _client.get<Map<String, dynamic>>(_manifestPath);
      final data = response.data;
      if (data == null) return;

      final praises = _listFrom(data, 'praises');
      final praiseTags = _listFrom(data, 'praise_tags');
      final materialKinds = _listFrom(data, 'material_kinds');

      await _revalidatePraises(praises);
      await _revalidatePraiseTags(praiseTags);
      await _revalidateMaterialKinds(materialKinds);
    } catch (e, st) {
      debugPrint('MetadataRevalidationRunner: $e');
      debugPrint('$st');
    }
  }

  List<Map<String, dynamic>> _listFrom(Map<String, dynamic> data, String key) {
    final raw = data[key];
    if (raw is! List) return [];
    return raw
        .where((e) => e is Map<String, dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static const int _bulkPageSize = 200;

  Future<void> _revalidatePraises(List<Map<String, dynamic>> manifestItems) async {
    final hasAny = MetadataCacheService.hasAny(MetadataCacheType.praise);
    if (!hasAny && manifestItems.length > _bulkPageSize) {
      await _bulkFetchPraises();
      return;
    }
    for (final item in manifestItems) {
      final id = item['id']?.toString();
      final version = item['version']?.toString();
      if (id == null || id.isEmpty || version == null) continue;

      final stored = MetadataCacheService.getStoredVersion(
        MetadataCacheType.praise,
        id,
      );
      if (stored == version) continue;

      try {
        final response = await _client.get<Map<String, dynamic>>(
          '/api/v1/praises/$id',
        );
        final payload = response.data;
        if (payload == null) continue;

        final versionFromPayload = payload['updated_at']?.toString() ?? version;
        await MetadataCacheService.putItem(
          MetadataCacheType.praise,
          id,
          payload,
          versionFromPayload,
        );
      } catch (e) {
        debugPrint('MetadataRevalidationRunner praise $id: $e');
      }
    }
  }

  /// Primeira carga: busca praises em páginas em vez de um a um.
  Future<void> _bulkFetchPraises() async {
    int skip = 0;
    while (true) {
      final response = await _client.get<List<dynamic>>(
        '/api/v1/praises/',
        queryParameters: {'skip': skip, 'limit': _bulkPageSize, 'sort_by': 'name'},
      );
      final data = response.data;
      if (data == null || data.isEmpty) break;
      for (final raw in data) {
        if (raw is! Map<String, dynamic>) continue;
        final payload = Map<String, dynamic>.from(raw);
        final id = payload['id']?.toString();
        final version = payload['updated_at']?.toString();
        if (id == null || id.isEmpty || version == null) continue;
        await MetadataCacheService.putItem(
          MetadataCacheType.praise,
          id,
          payload,
          version,
        );
      }
      if (data.length < _bulkPageSize) break;
      skip += _bulkPageSize;
    }
  }

  Future<void> _revalidatePraiseTags(
    List<Map<String, dynamic>> manifestItems,
  ) async {
    for (final item in manifestItems) {
      final id = item['id']?.toString();
      final version = item['version']?.toString();
      if (id == null || id.isEmpty || version == null) continue;

      final stored = MetadataCacheService.getStoredVersion(
        MetadataCacheType.praiseTag,
        id,
      );
      if (stored == version) continue;

      try {
        final response = await _client.get<Map<String, dynamic>>(
          '/api/v1/praise-tags/$id',
        );
        final payload = response.data;
        if (payload == null) continue;

        final versionFromPayload = payload['version']?.toString() ?? version;
        await MetadataCacheService.putItem(
          MetadataCacheType.praiseTag,
          id,
          payload,
          versionFromPayload,
        );
      } catch (e) {
        debugPrint('MetadataRevalidationRunner praise_tag $id: $e');
      }
    }
  }

  Future<void> _revalidateMaterialKinds(
    List<Map<String, dynamic>> manifestItems,
  ) async {
    for (final item in manifestItems) {
      final id = item['id']?.toString();
      final version = item['version']?.toString();
      if (id == null || id.isEmpty || version == null) continue;

      final stored = MetadataCacheService.getStoredVersion(
        MetadataCacheType.materialKind,
        id,
      );
      if (stored == version) continue;

      try {
        final response = await _client.get<Map<String, dynamic>>(
          '/api/v1/material-kinds/$id',
        );
        final payload = response.data;
        if (payload == null) continue;

        final versionFromPayload = payload['version']?.toString() ?? version;
        await MetadataCacheService.putItem(
          MetadataCacheType.materialKind,
          id,
          payload,
          versionFromPayload,
        );
      } catch (e) {
        debugPrint('MetadataRevalidationRunner material_kind $id: $e');
      }
    }
  }
}
