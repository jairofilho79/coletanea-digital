import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/changelog_api.dart';
import '../network/coldigom_client.dart';
import 'changelog_version_storage.dart';
import 'hive_service.dart';
import 'metadata_cache_service.dart';
import 'translation_cache_updater.dart';

/// Sincroniza o cache de metadados com o coldigom via Changelog API: version +
/// delta, aplicando created/updated/deleted por entidade. Uma única execução por
/// vez (lock). Se offline, não faz nada.
class MetadataRevalidationRunner {
  MetadataRevalidationRunner(
    this._changelogApi,
    this._client, [
    TranslationCacheUpdater? translationCache,
  ]) : _translationCache = translationCache;

  final ChangelogApi _changelogApi;
  final ColdigomClient _client;
  final TranslationCacheUpdater? _translationCache;

  bool _isSyncing = false;

  /// Executa sync se [isOnline]. Se já estiver sincronizando, ignora nova
  /// chamada. Usa exclusivamente changelog (sem TTL/manifest).
  Future<void> revalidateIfNeeded(bool isOnline) async {
    if (!isOnline) return;
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _syncWithChangelog();
    } catch (e, st) {
      debugPrint('MetadataRevalidationRunner: $e');
      debugPrint('$st');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncWithChangelog() async {
    final localVersion = ChangelogVersionStorage.getChangelogVersion();
    final sinceVersion = localVersion ?? 0;

    int currentVersion;
    try {
      final versionResponse = await _changelogApi.getVersion();
      currentVersion = versionResponse.currentVersion;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
    if (currentVersion == sinceVersion && localVersion != null) return;

    final ChangelogResponse response;
    try {
      response = await _changelogApi.getChangelog(sinceVersion: sinceVersion);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }

    final deduped = _deduplicateByEntity(response.changes);
    for (final entry in deduped) {
      await _applyChange(entry);
    }
    await ChangelogVersionStorage.setChangelogVersion(response.currentVersion);
  }

  /// Agrupa por (entity_type, entity_id) e mantém a entrada de maior version.
  static List<ChangelogEntry> deduplicateByEntity(List<ChangelogEntry> changes) {
    final byKey = <String, ChangelogEntry>{};
    for (final e in changes) {
      final key = '${e.entityType}:${e.entityId}';
      final existing = byKey[key];
      if (existing == null || e.version > existing.version) {
        byKey[key] = e;
      }
    }
    return byKey.values.toList();
  }

  List<ChangelogEntry> _deduplicateByEntity(List<ChangelogEntry> changes) =>
      MetadataRevalidationRunner.deduplicateByEntity(changes);

  Future<void> _applyChange(ChangelogEntry entry) async {
    final type = entry.entityType;
    final id = entry.entityId;
    final action = entry.action;

    if (action == 'deleted') {
      await _removeFromCache(type, id);
      return;
    }
    if (action == 'created' || action == 'updated') {
      await _fetchAndPut(type, id, entry.version);
    }
  }

  Future<void> _removeFromCache(String entityType, String id) async {
    if (entityType == 'praise_material') {
      await _refetchPraiseContainingMaterial(id);
      return;
    }
    if (entityType == 'language') {
      await _fetchAndStoreLanguages();
      return;
    }
    if (_isTranslationType(entityType)) {
      final cache = _translationCache;
      if (cache != null) {
        await cache.removeTranslationEntryForEntity(
          _translationTypeToCacheType(entityType),
          id,
        );
      }
      return;
    }
    final cacheType = _cacheTypeFor(entityType);
    if (cacheType == null) return;
    await MetadataCacheService.removeItem(cacheType, id);
  }

  bool _isTranslationType(String entityType) {
    return entityType == 'material_kind_translation' ||
        entityType == 'praise_tag_translation' ||
        entityType == 'material_type_translation';
  }

  String _translationTypeToCacheType(String entityType) {
    switch (entityType) {
      case 'material_kind_translation':
        return 'material_kind';
      case 'praise_tag_translation':
        return 'praise_tag';
      case 'material_type_translation':
        return 'material_type';
      default:
        return entityType;
    }
  }

  MetadataCacheType? _cacheTypeFor(String entityType) {
    switch (entityType) {
      case 'praise':
        return MetadataCacheType.praise;
      case 'praise_tag':
        return MetadataCacheType.praiseTag;
      case 'material_kind':
        return MetadataCacheType.materialKind;
      case 'material_type':
        return MetadataCacheType.materialType;
      case 'praise_material':
        return null;
      default:
        return null;
    }
  }

  Future<void> _fetchAndPut(String entityType, String id, int changelogVersion) async {
    if (entityType == 'praise_material') {
      await _fetchAndApplyPraiseMaterial(id);
      return;
    }
    if (_isTranslationType(entityType)) {
      await _fetchAndApplyTranslation(entityType, id);
      return;
    }
    if (entityType == 'language') {
      await _fetchAndStoreLanguages();
      return;
    }
    final cacheType = _cacheTypeFor(entityType);
    if (cacheType == null) return;
    final path = _endpointFor(entityType, id);
    if (path == null) return;
    try {
      final res = await _client.get<Map<String, dynamic>>(path);
      final payload = res.data;
      if (payload == null) return;
      final version = _versionFromPayload(entityType, payload, changelogVersion);
      await MetadataCacheService.putItem(cacheType, id, payload, version);
    } catch (e) {
      debugPrint('MetadataRevalidationRunner fetch $entityType $id: $e');
    }
  }

  /// GET /api/v1/translations/{type}/{entity_id} e faz merge no cache de traduções.
  Future<void> _fetchAndApplyTranslation(String entityType, String id) async {
    final updater = _translationCache;
    if (updater == null) return;
    final path = _translationEndpointFor(entityType, id);
    if (path == null) return;
    try {
      final res = await _client.get<dynamic>(path);
      final data = res.data;
      if (data == null) return;
      final type = _translationTypeToCacheType(entityType);
      if (data is Map<String, dynamic>) {
        _applyTranslationPayload(updater, type, data);
      } else if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            _applyTranslationPayload(updater, type, item);
          }
        }
      }
    } catch (e) {
      debugPrint('MetadataRevalidationRunner translation $entityType $id: $e');
    }
  }

  void _applyTranslationPayload(
    TranslationCacheUpdater updater,
    String type,
    Map<String, dynamic> payload,
  ) {
    final entityId = payload['material_kind_id']?.toString() ??
        payload['praise_tag_id']?.toString() ??
        payload['material_type_id']?.toString() ??
        payload['entity_id']?.toString();
    final languageCode = payload['language_code']?.toString();
    final translatedName = payload['translated_name']?.toString();
    if (entityId == null || entityId.isEmpty || languageCode == null) return;
    if (translatedName == null) return;
    updater.mergeTranslationEntry(
      languageCode,
      type,
      entityId,
      translatedName,
    );
  }

  String? _translationEndpointFor(String entityType, String id) {
    switch (entityType) {
      case 'material_kind_translation':
        return '/api/v1/translations/material-kinds/$id';
      case 'praise_tag_translation':
        return '/api/v1/translations/praise-tags/$id';
      case 'material_type_translation':
        return '/api/v1/translations/material-types/$id';
      default:
        return null;
    }
  }

  /// GET /api/v1/languages/ e guarda na metadata box (chave meta_cache_languages).
  Future<void> _fetchAndStoreLanguages() async {
    try {
      final res = await _client.get<dynamic>('/api/v1/languages/');
      final data = res.data;
      if (data == null) return;
      await HiveService.metadataBox.put('meta_cache_languages', data);
    } catch (e) {
      debugPrint('MetadataRevalidationRunner languages: $e');
    }
  }

  /// praise_material: busca material; se tiver praise_id, busca praise e atualiza cache.
  Future<void> _fetchAndApplyPraiseMaterial(String materialId) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/api/v1/praise-materials/$materialId',
      );
      final payload = res.data;
      if (payload == null) return;
      final praiseId = payload['praise_id']?.toString();
      if (praiseId == null || praiseId.isEmpty) return;
      final praiseRes = await _client.get<Map<String, dynamic>>(
        '/api/v1/praises/$praiseId',
      );
      final praisePayload = praiseRes.data;
      if (praisePayload == null) return;
      final version = praisePayload['updated_at']?.toString() ?? '';
      if (version.isEmpty) return;
      await MetadataCacheService.putItem(
        MetadataCacheType.praise,
        praiseId,
        praisePayload,
        version,
      );
    } catch (e) {
      debugPrint('MetadataRevalidationRunner praise_material $materialId: $e');
    }
  }

  /// Após deleted praise_material: acha um praise em cache que contenha o material e refetch.
  Future<void> _refetchPraiseContainingMaterial(String materialId) async {
    final praises = MetadataCacheService.getAll(MetadataCacheType.praise);
    for (final p in praises) {
      final materials = p['materials'];
      if (materials is! List) continue;
      final hasMaterial = materials.any((m) {
        if (m is! Map) return false;
        return m['id']?.toString() == materialId;
      });
      if (!hasMaterial) continue;
      final praiseId = p['id']?.toString();
      if (praiseId == null) continue;
      try {
        final res = await _client.get<Map<String, dynamic>>(
          '/api/v1/praises/$praiseId',
        );
        final payload = res.data;
        if (payload == null) continue;
        final version = payload['updated_at']?.toString() ?? '';
        if (version.isEmpty) continue;
        await MetadataCacheService.putItem(
          MetadataCacheType.praise,
          praiseId,
          payload,
          version,
        );
      } catch (e) {
        debugPrint('MetadataRevalidationRunner refetch praise $praiseId: $e');
      }
      return;
    }
  }

  String? _endpointFor(String entityType, String id) {
    switch (entityType) {
      case 'praise':
        return '/api/v1/praises/$id';
      case 'praise_tag':
        return '/api/v1/praise-tags/$id';
      case 'material_kind':
        return '/api/v1/material-kinds/$id';
      case 'material_type':
        return '/api/v1/material-types/$id';
      default:
        return null;
    }
  }

  String _versionFromPayload(
    String entityType,
    Map<String, dynamic> payload,
    int fallback,
  ) {
    if (entityType == 'praise') {
      final v = payload['updated_at']?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    if (entityType == 'praise_tag' ||
        entityType == 'material_kind' ||
        entityType == 'material_type') {
      final v = payload['version']?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return fallback.toString();
  }
}
