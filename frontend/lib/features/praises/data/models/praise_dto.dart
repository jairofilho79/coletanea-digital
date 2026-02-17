import '../../domain/entities/praise.dart';

/// DTO para resposta da API do coldigom
class PraiseDto {
  final String id;
  final String name;
  final int? number;
  final String? author;
  final String? rhythm;
  final String? tonality;
  final String? category;
  final String createdAt;
  final String updatedAt;
  final List<PraiseTagDto> tags;
  final List<PraiseMaterialDto> materials;
  final bool inReview;
  final String? inReviewDescription;

  PraiseDto({
    required this.id,
    required this.name,
    this.number,
    this.author,
    this.rhythm,
    this.tonality,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.materials = const [],
    this.inReview = false,
    this.inReviewDescription,
  });

  factory PraiseDto.fromJson(Map<String, dynamic> json) {
    return PraiseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as int?,
      author: json['author'] as String?,
      rhythm: json['rhythm'] as String?,
      tonality: json['tonality'] as String?,
      category: json['category'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => PraiseTagDto.fromJson(tag as Map<String, dynamic>))
              .toList() ??
          [],
      materials: (json['materials'] as List<dynamic>?)
              ?.map((material) =>
                  PraiseMaterialDto.fromJson(material as Map<String, dynamic>))
              .toList() ??
          [],
      inReview: json['in_review'] as bool? ?? false,
      inReviewDescription: json['in_review_description'] as String?,
    );
  }

  /// Converte DTO para entidade de domínio
  Praise toDomain() {
    return Praise(
      id: id,
      name: name,
      number: number,
      author: author,
      rhythm: rhythm,
      tonality: tonality,
      category: category,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      tags: tags.map((tag) => tag.toDomain()).toList(),
      materials: materials.map((material) => material.toDomain()).toList(),
      inReview: inReview,
      inReviewDescription: inReviewDescription,
    );
  }
}

class PraiseTagDto {
  final String id;
  final String name;

  PraiseTagDto({
    required this.id,
    required this.name,
  });

  factory PraiseTagDto.fromJson(Map<String, dynamic> json) {
    return PraiseTagDto(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  PraiseTag toDomain() {
    return PraiseTag(id: id, name: name);
  }
}

class PraiseMaterialDto {
  final String id;
  final String materialKindId;
  final String materialTypeId;
  final String path;
  final bool isOld;
  final String? oldDescription;
  final MaterialKindDto? materialKind;
  final MaterialTypeDto? materialType;

  PraiseMaterialDto({
    required this.id,
    required this.materialKindId,
    required this.materialTypeId,
    required this.path,
    this.isOld = false,
    this.oldDescription,
    this.materialKind,
    this.materialType,
  });

  factory PraiseMaterialDto.fromJson(Map<String, dynamic> json) {
    // O path pode ser uma string (caminho de arquivo) ou texto (para materiais do tipo text)
    final pathValue = json['path'];
    final path = pathValue is String ? pathValue : pathValue.toString();
    
    return PraiseMaterialDto(
      id: json['id'] as String,
      materialKindId: json['material_kind_id'] as String,
      materialTypeId: json['material_type_id'] as String,
      path: path,
      isOld: json['is_old'] as bool? ?? false,
      oldDescription: json['old_description'] as String?,
      materialKind: json['material_kind'] != null
          ? MaterialKindDto.fromJson(json['material_kind'] as Map<String, dynamic>)
          : null,
      materialType: json['material_type'] != null
          ? MaterialTypeDto.fromJson(json['material_type'] as Map<String, dynamic>)
          : null,
    );
  }

  PraiseMaterial toDomain() {
    return PraiseMaterial(
      id: id,
      materialKindId: materialKindId,
      materialTypeId: materialTypeId,
      path: path,
      isOld: isOld,
      oldDescription: oldDescription,
      materialKind: materialKind?.toDomain(),
      materialType: materialType?.toDomain(),
    );
  }
}

class MaterialKindDto {
  final String id;
  final String name;
  final String? icon;

  MaterialKindDto({
    required this.id,
    required this.name,
    this.icon,
  });

  factory MaterialKindDto.fromJson(Map<String, dynamic> json) {
    return MaterialKindDto(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }

  MaterialKind toDomain() {
    return MaterialKind(id: id, name: name, icon: icon);
  }
}

class MaterialTypeDto {
  final String id;
  final String name;

  MaterialTypeDto({
    required this.id,
    required this.name,
  });

  factory MaterialTypeDto.fromJson(Map<String, dynamic> json) {
    return MaterialTypeDto(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  MaterialType toDomain() {
    return MaterialType(id: id, name: name);
  }
}
