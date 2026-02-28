/// DTOs para traduções da API do coldigom

/// DTO para tradução de Material Kind
class MaterialKindTranslationDto {
  final String id;
  final String materialKindId;
  final String languageCode;
  final String translatedName;

  MaterialKindTranslationDto({
    required this.id,
    required this.materialKindId,
    required this.languageCode,
    required this.translatedName,
  });

  factory MaterialKindTranslationDto.fromJson(Map<String, dynamic> json) {
    return MaterialKindTranslationDto(
      id: json['id'] as String,
      materialKindId: json['material_kind_id'] as String,
      languageCode: json['language_code'] as String,
      translatedName: json['translated_name'] as String,
    );
  }
}

/// DTO para tradução de Praise Tag
class PraiseTagTranslationDto {
  final String id;
  final String praiseTagId;
  final String languageCode;
  final String translatedName;

  PraiseTagTranslationDto({
    required this.id,
    required this.praiseTagId,
    required this.languageCode,
    required this.translatedName,
  });

  factory PraiseTagTranslationDto.fromJson(Map<String, dynamic> json) {
    return PraiseTagTranslationDto(
      id: json['id'] as String,
      praiseTagId: json['praise_tag_id'] as String,
      languageCode: json['language_code'] as String,
      translatedName: json['translated_name'] as String,
    );
  }
}

/// DTO para tradução de Material Type
class MaterialTypeTranslationDto {
  final String id;
  final String materialTypeId;
  final String languageCode;
  final String translatedName;

  MaterialTypeTranslationDto({
    required this.id,
    required this.materialTypeId,
    required this.languageCode,
    required this.translatedName,
  });

  factory MaterialTypeTranslationDto.fromJson(Map<String, dynamic> json) {
    return MaterialTypeTranslationDto(
      id: json['id'] as String,
      materialTypeId: json['material_type_id'] as String,
      languageCode: json['language_code'] as String,
      translatedName: json['translated_name'] as String,
    );
  }
}
