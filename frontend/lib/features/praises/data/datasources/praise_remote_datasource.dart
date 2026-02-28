import 'package:flutter/foundation.dart';
import '../models/praise_dto.dart';
import '../../../../core/network/coldigom_client.dart';

/// Data source remoto para praises (coldigom API)
class PraiseRemoteDataSource {
  final ColdigomClient client;

  PraiseRemoteDataSource(this.client);

  /// Lista praises com paginação e filtros
  Future<List<PraiseDto>> getPraises({
    int skip = 0,
    int limit = 100,
    String? name,
    String? tagId,
    String? tonality,
    String? rhythm,
    String? category,
    String? youtubeUrl,
    bool searchInLyrics = false,
    String sortBy = 'name',
    String sortDirection = 'asc',
    String noNumber = 'last',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        'sort_by': sortBy,
        'sort_direction': sortDirection,
        'no_number': noNumber,
      };

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      if (tagId != null && tagId.isNotEmpty) {
        queryParams['tag_id'] = tagId;
      }

      if (tonality != null && tonality.isNotEmpty) {
        queryParams['tonality'] = tonality;
      }

      if (rhythm != null && rhythm.isNotEmpty) {
        queryParams['rhythm'] = rhythm;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
        queryParams['youtube_url'] = youtubeUrl;
      }

      if (searchInLyrics) {
        queryParams['search_in_lyrics'] = true;
      }

      final response = await client.get<List<dynamic>>(
        '/api/v1/praises/',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        return [];
      }

      // Parse com tratamento de erros individual
      final praises = <PraiseDto>[];
      for (var json in response.data!) {
        try {
          praises.add(PraiseDto.fromJson(json as Map<String, dynamic>));
        } catch (e) {
          // Log erro mas continua processando outros itens
          debugPrint('Erro ao parsear praise: $e');
          debugPrint('JSON: $json');
        }
      }
      
      return praises;
    } catch (e) {
      debugPrint('Erro ao buscar praises: $e');
      throw Exception('Erro ao buscar praises: $e');
    }
  }

  /// Lista todas as tags de praise (GET /api/v1/praise-tags/)
  Future<List<PraiseTagDto>> getPraiseTags() async {
    try {
      final response = await client.get<List<dynamic>>(
        '/api/v1/praise-tags/',
      );

      if (response.data == null) {
        return [];
      }

      final tags = <PraiseTagDto>[];
      for (var json in response.data!) {
        try {
          tags.add(PraiseTagDto.fromJson(json as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Erro ao parsear tag: $e');
        }
      }
      return tags;
    } catch (e) {
      debugPrint('Erro ao buscar tags: $e');
      rethrow;
    }
  }

  /// Obtém um praise por ID
  Future<PraiseDto> getPraiseById(String id) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        '/api/v1/praises/$id',
      );

      if (response.data == null) {
        throw Exception('Praise não encontrado');
      }

      return PraiseDto.fromJson(response.data!);
    } catch (e) {
      throw Exception('Erro ao buscar praise: $e');
    }
  }
}
