import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/praise.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/storage/metadata_cache_service.dart';

/// Data source local para praises (cache via MetadataCacheService + Hive para tags legado)
class PraiseLocalDataSource {
  static const String _praiseTagsListKey = 'praise_tags_list';
  static const String _praiseTagsLastUpdateKey = 'praise_tags_last_update';

  Box get _box => HiveService.praisesBox;

  /// Salva lista de praises no cache (cada item com version e TTL 24h)
  Future<void> cachePraises(List<Praise> praises) async {
    for (final p in praises) {
      final version = p.updatedAt.toUtc().toIso8601String();
      await MetadataCacheService.putItem(
        MetadataCacheType.praise,
        p.id,
        _praiseToJson(p),
        version,
      );
    }
  }

  /// Obtém lista de praises do cache (sempre do cache; revalidação em background)
  List<Praise>? getCachedPraises() {
    final list = MetadataCacheService.getAll(MetadataCacheType.praise);
    if (list.isEmpty) return null;
    try {
      final praises = list
          .map((json) => _praiseFromJson(json))
          .whereType<Praise>()
          .toList();
      praises.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return praises;
    } catch (e) {
      return null;
    }
  }

  /// Salva um praise individual no cache
  Future<void> cachePraise(Praise praise) async {
    final version = praise.updatedAt.toUtc().toIso8601String();
    await MetadataCacheService.putItem(
      MetadataCacheType.praise,
      praise.id,
      _praiseToJson(praise),
      version,
    );
  }

  /// Obtém um praise do cache
  Praise? getCachedPraise(String id) {
    final data = MetadataCacheService.getItem(MetadataCacheType.praise, id);
    if (data == null) return null;
    try {
      return _praiseFromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Cache frio: salva lista de tags (TTL 24h via MetadataCacheService)
  Future<void> cachePraiseTags(List<PraiseTag> tags) async {
    for (final t in tags) {
      final payload = {'id': t.id, 'name': t.name};
      final version = _hashIdName(t.id, t.name);
      await MetadataCacheService.putItem(
        MetadataCacheType.praiseTag,
        t.id,
        payload,
        version,
      );
    }
    await _box.put(_praiseTagsLastUpdateKey, DateTime.now().toIso8601String());
  }

  static String _hashIdName(String id, String name) {
    final bytes = utf8.encode('$id:$name');
    return sha256.convert(bytes).toString();
  }

  /// Cache frio: obtém tags do cache (sempre do cache se houver dados)
  List<PraiseTag>? getCachedPraiseTags() {
    final list = MetadataCacheService.getAll(MetadataCacheType.praiseTag);
    if (list.isEmpty) return null;
    try {
      return list
          .map((e) {
            final id = e['id'] as String?;
            final name = e['name'] as String? ?? '';
            if (id == null || id.isEmpty) return null;
            return PraiseTag(id: id, name: name);
          })
          .whereType<PraiseTag>()
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Cache frio: tags válidas se temos dados (revalidação em background)
  bool isPraiseTagsCacheValid() {
    return MetadataCacheService.hasAny(MetadataCacheType.praiseTag);
  }

  /// Limpa o cache de praises e tags no MetadataCacheService
  Future<void> clearCache() async {
    await MetadataCacheService.removeAll(MetadataCacheType.praise);
    await MetadataCacheService.removeAll(MetadataCacheType.praiseTag);
    await _box.delete(_praiseTagsListKey);
    await _box.delete(_praiseTagsLastUpdateKey);
  }

  /// Verifica se há cache de praises (sempre servir cache; revalidação atualiza em background)
  bool isCacheValid() {
    return MetadataCacheService.hasAny(MetadataCacheType.praise);
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
