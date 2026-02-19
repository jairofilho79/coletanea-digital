import 'package:flutter/foundation.dart';
import '../models/translation_dto.dart';
import '../../../../core/network/coldigom_client.dart';

/// Data source remoto para traduções (coldigom API)
class TranslationRemoteDataSource {
  final ColdigomClient client;

  TranslationRemoteDataSource(this.client);

  /// Lista traduções de Material Kinds para um idioma
  Future<List<MaterialKindTranslationDto>> getMaterialKindTranslations(
    String languageCode,
  ) async {
    try {
      final response = await client.get<List<dynamic>>(
        '/api/v1/translations/material-kinds',
        queryParameters: {'language_code': languageCode},
      );

      if (response.data == null) {
        return [];
      }

      final translations = <MaterialKindTranslationDto>[];
      for (var json in response.data!) {
        try {
          translations.add(
            MaterialKindTranslationDto.fromJson(json as Map<String, dynamic>),
          );
        } catch (e) {
          debugPrint('Erro ao parsear tradução de material kind: $e');
        }
      }
      debugPrint('Traduções de material kinds carregadas: ${translations.length} para idioma $languageCode');
      return translations;
    } catch (e) {
      debugPrint('Erro ao buscar traduções de material kinds: $e');
      rethrow;
    }
  }

  /// Lista traduções de Praise Tags para um idioma
  Future<List<PraiseTagTranslationDto>> getPraiseTagTranslations(
    String languageCode,
  ) async {
    try {
      final response = await client.get<List<dynamic>>(
        '/api/v1/translations/praise-tags',
        queryParameters: {'language_code': languageCode},
      );

      if (response.data == null) {
        return [];
      }

      final translations = <PraiseTagTranslationDto>[];
      for (var json in response.data!) {
        try {
          translations.add(
            PraiseTagTranslationDto.fromJson(json as Map<String, dynamic>),
          );
        } catch (e) {
          debugPrint('Erro ao parsear tradução de praise tag: $e');
        }
      }
      return translations;
    } catch (e) {
      debugPrint('Erro ao buscar traduções de praise tags: $e');
      rethrow;
    }
  }

  /// Lista traduções de Material Types para um idioma
  Future<List<MaterialTypeTranslationDto>> getMaterialTypeTranslations(
    String languageCode,
  ) async {
    try {
      final response = await client.get<List<dynamic>>(
        '/api/v1/translations/material-types',
        queryParameters: {'language_code': languageCode},
      );

      if (response.data == null) {
        return [];
      }

      final translations = <MaterialTypeTranslationDto>[];
      for (var json in response.data!) {
        try {
          translations.add(
            MaterialTypeTranslationDto.fromJson(json as Map<String, dynamic>),
          );
        } catch (e) {
          debugPrint('Erro ao parsear tradução de material type: $e');
        }
      }
      return translations;
    } catch (e) {
      debugPrint('Erro ao buscar traduções de material types: $e');
      rethrow;
    }
  }
}
