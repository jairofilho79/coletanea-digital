import 'package:flutter/foundation.dart';
import '../../data/datasources/translation_remote_datasource.dart';
import '../../data/datasources/translation_local_datasource.dart';
import '../../data/models/translation_dto.dart';

/// Serviço de traduções com cache em memória e persistente
class TranslationService {
  final TranslationRemoteDataSource _remoteDataSource;
  final TranslationLocalDataSource _localDataSource;
  
  // Cache em memória: Map<entityId, translatedName>
  final Map<String, String> _materialKindTranslations = {};
  final Map<String, String> _praiseTagTranslations = {};
  final Map<String, String> _materialTypeTranslations = {};
  
  bool _isLoaded = false;
  String? _loadedLanguageCode;

  TranslationService(this._remoteDataSource, this._localDataSource);

  /// Código de idioma usado na API (coldigom tem en-US, pt-BR, etc.)
  static String _apiLanguageCode(String languageCode) {
    if (languageCode == 'en') return 'en-US';
    return languageCode;
  }

  /// Carrega todas as traduções para um idioma
  Future<void> loadTranslations(String languageCode) async {
    // Se já carregou para este idioma, não precisa carregar novamente
    if (_isLoaded && _loadedLanguageCode == languageCode) {
      return;
    }

    try {
      // Limpa cache anterior se mudou de idioma
      if (_loadedLanguageCode != null && _loadedLanguageCode != languageCode) {
        _materialKindTranslations.clear();
        _praiseTagTranslations.clear();
        _materialTypeTranslations.clear();
      }

      final apiLang = _apiLanguageCode(languageCode);
      // Tenta carregar do cache local primeiro (mesma chave do idioma do app)
      final cachedMaterialKinds = _localDataSource.getCachedTranslations(languageCode, 'material_kind');
      final cachedPraiseTags = _localDataSource.getCachedTranslations(languageCode, 'praise_tag');
      final cachedMaterialTypes = _localDataSource.getCachedTranslations(languageCode, 'material_type');

      List<MaterialKindTranslationDto> materialKindTranslations;
      List<PraiseTagTranslationDto> praiseTagTranslations;
      List<MaterialTypeTranslationDto> materialTypeTranslations;

      // Só usa cache se existir e tiver dados (cache vazio = refetch para pegar seeds novos)
      final hasValidMaterialKindsCache = cachedMaterialKinds != null && cachedMaterialKinds.isNotEmpty;
      if (hasValidMaterialKindsCache &&
          cachedPraiseTags != null &&
          cachedMaterialTypes != null) {
        // Converte cache para DTOs (apenas para popular cache em memória)
        materialKindTranslations = cachedMaterialKinds.entries.map((e) => 
          MaterialKindTranslationDto(
            id: '',
            materialKindId: e.key,
            languageCode: languageCode,
            translatedName: e.value,
          )
        ).toList();
        
        praiseTagTranslations = cachedPraiseTags.entries.map((e) => 
          PraiseTagTranslationDto(
            id: '',
            praiseTagId: e.key,
            languageCode: languageCode,
            translatedName: e.value,
          )
        ).toList();
        
        materialTypeTranslations = cachedMaterialTypes.entries.map((e) => 
          MaterialTypeTranslationDto(
            id: '',
            materialTypeId: e.key,
            languageCode: languageCode,
            translatedName: e.value,
          )
        ).toList();
      } else {
        // Busca da API (usa código normalizado: en -> en-US)
        final results = await Future.wait([
          _remoteDataSource.getMaterialKindTranslations(apiLang),
          _remoteDataSource.getPraiseTagTranslations(apiLang),
          _remoteDataSource.getMaterialTypeTranslations(apiLang),
        ]);

        materialKindTranslations = results[0] as List<MaterialKindTranslationDto>;
        praiseTagTranslations = results[1] as List<PraiseTagTranslationDto>;
        materialTypeTranslations = results[2] as List<MaterialTypeTranslationDto>;

        // Salva no cache local
        final materialKindMap = {
          for (final t in materialKindTranslations) t.materialKindId: t.translatedName
        };
        final praiseTagMap = {
          for (final t in praiseTagTranslations) t.praiseTagId: t.translatedName
        };
        final materialTypeMap = {
          for (final t in materialTypeTranslations) t.materialTypeId: t.translatedName
        };

        await Future.wait([
          _localDataSource.cacheTranslations(languageCode, materialKindMap, 'material_kind'),
          _localDataSource.cacheTranslations(languageCode, praiseTagMap, 'praise_tag'),
          _localDataSource.cacheTranslations(languageCode, materialTypeMap, 'material_type'),
        ]);
      }

      // Popula cache em memória
      for (final translation in materialKindTranslations) {
        _materialKindTranslations[translation.materialKindId] = translation.translatedName;
      }

      for (final translation in praiseTagTranslations) {
        _praiseTagTranslations[translation.praiseTagId] = translation.translatedName;
      }

      for (final translation in materialTypeTranslations) {
        _materialTypeTranslations[translation.materialTypeId] = translation.translatedName;
      }

      debugPrint('Cache de traduções populado: ${_materialKindTranslations.length} material kinds, ${_praiseTagTranslations.length} tags, ${_materialTypeTranslations.length} material types para idioma $languageCode');

      _isLoaded = true;
      _loadedLanguageCode = languageCode;
    } catch (e, st) {
      // Em caso de erro, mantém o estado anterior; os métodos helper usam o fallback
      debugPrint('TranslationService.loadTranslations erro: $e');
      debugPrint('$st');
    }
  }

  /// Obtém o nome traduzido de um Material Kind
  /// Retorna o nome traduzido se disponível, senão retorna o fallback
  String getMaterialKindName(String materialKindId, String fallbackName) {
    final translated = _materialKindTranslations[materialKindId];
    if (translated == null) {
      debugPrint('Tradução não encontrada para materialKindId: $materialKindId, usando fallback: $fallbackName');
    }
    return translated ?? fallbackName;
  }

  /// Obtém o nome traduzido de uma Praise Tag
  /// Retorna o nome traduzido se disponível, senão retorna o fallback
  String getPraiseTagName(String tagId, String fallbackName) {
    return _praiseTagTranslations[tagId] ?? fallbackName;
  }

  /// Obtém o nome traduzido de um Material Type
  /// Retorna o nome traduzido se disponível, senão retorna o fallback
  String getMaterialTypeName(String materialTypeId, String fallbackName) {
    return _materialTypeTranslations[materialTypeId] ?? fallbackName;
  }

  /// Limpa o cache (útil para testes ou mudança de idioma)
  void clearCache() {
    _materialKindTranslations.clear();
    _praiseTagTranslations.clear();
    _materialTypeTranslations.clear();
    _isLoaded = false;
    _loadedLanguageCode = null;
  }
}
