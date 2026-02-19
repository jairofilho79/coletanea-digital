import '../../domain/entities/praise.dart';
import '../datasources/praise_remote_datasource.dart';
import '../datasources/praise_local_datasource.dart';

/// Repositório para praises (offline-first)
class PraiseRepository {
  final PraiseRemoteDataSource remoteDataSource;
  final PraiseLocalDataSource localDataSource;

  PraiseRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Lista praises (offline-first: tenta cache primeiro, depois API)
  Future<List<Praise>> getPraises({
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
    bool forceRefresh = false,
  }) async {
    // Busca por letra só existe na API: não usar cache quando searchInLyrics
    // skip > 0 (paginação "carregar mais"): cache só tem primeira página, deve ir à API
    // sortBy != 'name': cache foi preenchido com ordem por nome; ordenação por número exige API
    // tonality/rhythm/category/youtubeUrl: filtros só existem na API; não usar cache quando aplicados
    final useCache = !forceRefresh &&
        !searchInLyrics &&
        skip == 0 &&
        sortBy == 'name' &&
        tonality == null &&
        rhythm == null &&
        category == null &&
        youtubeUrl == null &&
        localDataSource.isCacheValid();
    if (useCache) {
      final cached = localDataSource.getCachedPraises();
      if (cached != null && cached.isNotEmpty) {
        // Aplica filtros locais se necessário
        var filtered = cached;
        if (name != null && name.isNotEmpty) {
          filtered = filtered
              .where((p) => p.name.toLowerCase().contains(name.toLowerCase()))
              .toList();
        }
        if (tagId != null && tagId.isNotEmpty) {
          filtered = filtered
              .where((p) => p.tags.any((tag) => tag.id == tagId))
              .toList();
        }
        // Aplica paginação (só primeira página veio do cache)
        final start = skip;
        final end = (start + limit).clamp(0, filtered.length);
        return filtered.sublist(start, end);
      }
    }

    // Busca da API
    try {
      final dtos = await remoteDataSource.getPraises(
        skip: skip,
        limit: limit,
        name: name,
        tagId: tagId,
        tonality: tonality,
        rhythm: rhythm,
        category: category,
        youtubeUrl: youtubeUrl,
        searchInLyrics: searchInLyrics,
        sortBy: sortBy,
        sortDirection: sortDirection,
        noNumber: noNumber,
      );

      final praises = dtos.map((dto) => dto.toDomain()).toList();

      // Salva no cache só a primeira página, ordenada por nome, sem filtros tom/ritmo/youtube
      if (skip == 0 &&
          name == null &&
          tagId == null &&
          sortBy == 'name' &&
          tonality == null &&
          rhythm == null &&
          category == null &&
          youtubeUrl == null) {
        await localDataSource.cachePraises(praises);
      }

      return praises;
    } catch (e) {
      // Se falhar e tiver cache, retorna do cache
      final cached = localDataSource.getCachedPraises();
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  /// Obtém um praise por ID (offline-first)
  Future<Praise> getPraiseById(String id, {bool forceRefresh = false}) async {
    // Tenta cache primeiro
    if (!forceRefresh) {
      final cached = localDataSource.getCachedPraise(id);
      if (cached != null) {
        return cached;
      }
    }

    // Busca da API
    try {
      final dto = await remoteDataSource.getPraiseById(id);
      final praise = dto.toDomain();

      // Salva no cache
      await localDataSource.cachePraise(praise);

      return praise;
    } catch (e) {
      // Se falhar e tiver cache, retorna do cache
      final cached = localDataSource.getCachedPraise(id);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  /// Limpa o cache
  Future<void> clearCache() async {
    await localDataSource.clearCache();
  }

  /// Lista todas as tags de praise (sempre da API)
  Future<List<PraiseTag>> getPraiseTags() async {
    final dtos = await remoteDataSource.getPraiseTags();
    return dtos.map((dto) => dto.toDomain()).toList();
  }
}
