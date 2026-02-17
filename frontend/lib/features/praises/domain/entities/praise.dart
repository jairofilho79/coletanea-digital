/// Entidade de domínio para Praise
class Praise {
  final String id;
  final String name;
  final int? number;
  final String? author;
  final String? rhythm;
  final String? tonality;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PraiseTag> tags;
  final List<PraiseMaterial> materials;
  final bool inReview;
  final String? inReviewDescription;

  Praise({
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

  /// Nome para exibição (com número se disponível)
  String get displayName {
    if (number != null) {
      return '$number - $name';
    }
    return name;
  }
}

/// Tag de um Praise
class PraiseTag {
  final String id;
  final String name;

  PraiseTag({
    required this.id,
    required this.name,
  });
}

/// Material de um Praise
class PraiseMaterial {
  final String id;
  final String materialKindId;
  final String materialTypeId;
  final String path;
  final bool isOld;
  final String? oldDescription;
  final MaterialKind? materialKind;
  final MaterialType? materialType;

  PraiseMaterial({
    required this.id,
    required this.materialKindId,
    required this.materialTypeId,
    required this.path,
    this.isOld = false,
    this.oldDescription,
    this.materialKind,
    this.materialType,
  });
}

/// Material Kind
class MaterialKind {
  final String id;
  final String name;
  final String? icon;

  MaterialKind({
    required this.id,
    required this.name,
    this.icon,
  });
}

/// Material Type
class MaterialType {
  final String id;
  final String name;

  MaterialType({
    required this.id,
    required this.name,
  });
}
