import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/praise.dart';
import '../../../../core/storage/hive_service.dart';

/// TTL do cache frio de catálogos (tags, etc.): 24 horas
const Duration _catalogCacheTtl = Duration(hours: 24);

/// Data source local para praises (Hive cache)
class PraiseLocalDataSource {
  static const String _cacheKeyPrefix = 'praise_';
  static const String _listCacheKey = 'praises_list';
  static const String _lastUpdateKey = 'praises_last_update';
  static const String _praiseTagsListKey = 'praise_tags_list';
  static const String _praiseTagsLastUpdateKey = 'praise_tags_last_update';

  Box get _box => HiveService.praisesBox;

  /// Salva lista de praises no cache
  Future<void> cachePraises(List<Praise> praises) async {
    final cacheData = praises.map((praise) => _praiseToJson(praise)).toList();
    await _box.put(_listCacheKey, cacheData);
    await _box.put(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Obtém lista de praises do cache
  List<Praise>? getCachedPraises() {
    final cacheData = _box.get(_listCacheKey);
    if (cacheData == null) {
      return null;
    }

    try {
      return (cacheData as List<dynamic>)
          .map((json) => _praiseFromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Salva um praise individual no cache
  Future<void> cachePraise(Praise praise) async {
    await _box.put('$_cacheKeyPrefix${praise.id}', _praiseToJson(praise));
  }

  /// Obtém um praise do cache
  Praise? getCachedPraise(String id) {
    final data = _box.get('$_cacheKeyPrefix$id');
    if (data == null) {
      return null;
    }

    try {
      return _praiseFromJson(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Cache frio: salva lista de tags (TTL 24h)
  Future<void> cachePraiseTags(List<PraiseTag> tags) async {
    final list = tags.map((t) => {'id': t.id, 'name': t.name}).toList();
    await _box.put(_praiseTagsListKey, list);
    await _box.put(_praiseTagsLastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Cache frio: obtém tags do cache se ainda válido
  List<PraiseTag>? getCachedPraiseTags() {
    if (!isPraiseTagsCacheValid()) return null;
    final data = _box.get(_praiseTagsListKey);
    if (data == null) return null;
    try {
      return (data as List<dynamic>)
          .map((e) => PraiseTag(
                id: (e as Map)['id'] as String,
                name: (e['name'] as String?) ?? '',
              ))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Cache frio: tags válidas se dentro do TTL (24h)
  bool isPraiseTagsCacheValid() {
    final at = _box.get(_praiseTagsLastUpdateKey);
    if (at == null) return false;
    try {
      final t = DateTime.tryParse(at as String);
      return t != null && DateTime.now().difference(t) < _catalogCacheTtl;
    } catch (e) {
      return false;
    }
  }

  /// Limpa o cache de praises
  Future<void> clearCache() async {
    await _box.delete(_listCacheKey);
    await _box.delete(_lastUpdateKey);
    await _box.delete(_praiseTagsListKey);
    await _box.delete(_praiseTagsLastUpdateKey);
    // Remove praises individuais
    final keys = _box.keys
        .where((key) => key.toString().startsWith(_cacheKeyPrefix))
        .toList();
    for (final key in keys) {
      await _box.delete(key);
    }
  }

  /// Verifica se o cache está válido (menos de 1 hora)
  bool isCacheValid() {
    final lastUpdate = _box.get(_lastUpdateKey);
    if (lastUpdate == null) {
      return false;
    }

    try {
      final lastUpdateTime = DateTime.parse(lastUpdate as String);
      final now = DateTime.now();
      return now.difference(lastUpdateTime).inHours < 1;
    } catch (e) {
      return false;
    }
  }

  /// Converte Praise para JSON
  Map<String, dynamic> _praiseToJson(Praise praise) {
    return {
      'id': praise.id,
      'name': praise.name,
      'number': praise.number,
      'author': praise.author,
      'rhythm': praise.rhythm,
      'tonality': praise.tonality,
      'category': praise.category,
      'created_at': praise.createdAt.toIso8601String(),
      'updated_at': praise.updatedAt.toIso8601String(),
      'tags': praise.tags.map((tag) => {'id': tag.id, 'name': tag.name}).toList(),
      'materials': praise.materials.map((material) => {
        'id': material.id,
        'material_kind_id': material.materialKindId,
        'material_type_id': material.materialTypeId,
        'path': material.path,
        'is_old': material.isOld,
        'old_description': material.oldDescription,
      }).toList(),
      'in_review': praise.inReview,
      'in_review_description': praise.inReviewDescription,
    };
  }

  /// Converte JSON para Praise
  Praise _praiseFromJson(Map<String, dynamic> json) {
    return Praise(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as int?,
      author: json['author'] as String?,
      rhythm: json['rhythm'] as String?,
      tonality: json['tonality'] as String?,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => PraiseTag(
                    id: tag['id'] as String,
                    name: tag['name'] as String,
                  ))
              .toList() ??
          [],
      materials: (json['materials'] as List<dynamic>?)
              ?.map((material) => PraiseMaterial(
                    id: material['id'] as String,
                    materialKindId: material['material_kind_id'] as String,
                    materialTypeId: material['material_type_id'] as String,
                    path: material['path'] as String,
                    isOld: material['is_old'] as bool? ?? false,
                    oldDescription: material['old_description'] as String?,
                  ))
              .toList() ??
          [],
      inReview: json['in_review'] as bool? ?? false,
      inReviewDescription: json['in_review_description'] as String?,
    );
  }
}
