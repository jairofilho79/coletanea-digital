import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/praise.dart';
import '../../data/repositories/praise_repository.dart';
import '../../data/datasources/praise_remote_datasource.dart';
import '../../data/datasources/praise_local_datasource.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/storage/providers.dart';

/// Provider do repositório de praises
final praiseRepositoryProvider = Provider<PraiseRepository>((ref) {
  final client = ref.watch(coldigomClientProvider);
  final metadataBox = ref.watch(metadataBoxProvider);

  // Inicializa box de praises se necessário
  if (!metadataBox.isOpen) {
    // Box será aberto pelo HiveService
  }

  return PraiseRepository(
    remoteDataSource: PraiseRemoteDataSource(client),
    localDataSource: PraiseLocalDataSource(),
  );
});

/// Provider para lista de tags (usado no dialog de filtros avançados)
final praiseTagsProvider = FutureProvider<List<PraiseTag>>((ref) async {
  final repository = ref.read(praiseRepositoryProvider);
  return repository.getPraiseTags();
});

/// Provider para lista de praises
/// Com == e hashCode implementados em PraiseListParams, evita loops infinitos
final praisesProvider = FutureProvider.family<List<Praise>, PraiseListParams>(
  (ref, params) async {
    final repository = ref.read(praiseRepositoryProvider);
    
    try {
      return await repository.getPraises(
        skip: params.skip,
        limit: params.limit,
        name: params.name,
        tagId: params.tagId,
        searchInLyrics: params.searchInLyrics,
        sortBy: params.sortBy,
        sortDirection: params.sortDirection,
        noNumber: params.noNumber,
        forceRefresh: params.forceRefresh,
      );
    } catch (e, stackTrace) {
      debugPrint('Erro ao buscar praises: $e');
      debugPrint('Stack trace: $stackTrace');

      final errorMsg = e.toString().toLowerCase();
      // Não rethrow em 429: evita novas requisições e botão "Tentar novamente" em loop
      if (errorMsg.contains('429') || errorMsg.contains('rate limit') || errorMsg.contains('muitas requisições')) {
        return <Praise>[];
      }
      // CORS/conexão/timeout: retorna lista vazia
      if (errorMsg.contains('cors') ||
          errorMsg.contains('connection') ||
          errorMsg.contains('timeout')) {
        return <Praise>[];
      }
      rethrow;
    }
  },
);

/// Provider para um praise específico
final praiseProvider = FutureProvider.family<Praise, String>(
  (ref, id) async {
    final repository = ref.watch(praiseRepositoryProvider);
    return repository.getPraiseById(id);
  },
);

/// Estado da listagem infinita de praises (lista acumulada + hasMore + isLoadingMore).
class PraisesInfiniteState {
  const PraisesInfiniteState({
    required this.items,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final AsyncValue<List<Praise>> items;
  final bool hasMore;
  final bool isLoadingMore;
}

/// Filtros para a listagem (family do provider infinito). == e hashCode para evitar recriação desnecessária.
class PraiseListFilters {
  const PraiseListFilters({
    this.name,
    this.tagId,
    this.tonality,
    this.rhythm,
    this.category,
    this.youtubeUrl,
    this.searchInLyrics = false,
    this.sortBy = 'name',
    this.noNumber = 'last',
  });

  final String? name;
  final String? tagId;
  /// Tom (ex.: C, Dm); null = todos
  final String? tonality;
  /// Ritmo; null = todos
  final String? rhythm;
  /// Categoria (ex.: Coletânea); null = todos
  final String? category;
  /// URL ou ID do vídeo YouTube para filtrar; null = não filtrar
  final String? youtubeUrl;
  final bool searchInLyrics;
  /// 'name' ou 'number'
  final String sortBy;
  /// 'first', 'last' ou 'hide' (usado quando sortBy == 'number'); 'last' = sem número por último
  final String noNumber;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PraiseListFilters &&
        other.name == name &&
        other.tagId == tagId &&
        other.tonality == tonality &&
        other.rhythm == rhythm &&
        other.category == category &&
        other.youtubeUrl == youtubeUrl &&
        other.searchInLyrics == searchInLyrics &&
        other.sortBy == sortBy &&
        other.noNumber == noNumber;
  }

  @override
  int get hashCode => Object.hash(name, tagId, tonality, rhythm, category, youtubeUrl, searchInLyrics, sortBy, noNumber);
}

const int _infinitePageSize = 20;

/// Notifier que mantém lista acumulada e carrega mais sob demanda.
class PraisesInfiniteNotifier extends Notifier<PraisesInfiniteState> {
  PraisesInfiniteNotifier(this.filters);
  final PraiseListFilters filters;

  @override
  PraisesInfiniteState build() {
    Future.microtask(() => loadInitial());
    return const PraisesInfiniteState(
      items: AsyncLoading(),
      hasMore: true,
      isLoadingMore: false,
    );
  }

  bool _isErrorRecoverable(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('429') || msg.contains('rate limit') || msg.contains('muitas requisições')) return true;
    if (msg.contains('cors') || msg.contains('connection') || msg.contains('timeout')) return true;
    return false;
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    state = const PraisesInfiniteState(
      items: AsyncLoading(),
      hasMore: true,
      isLoadingMore: false,
    );
    final repository = ref.read(praiseRepositoryProvider);
    try {
      final list = await repository.getPraises(
        skip: 0,
        limit: _infinitePageSize,
        name: filters.name,
        tagId: filters.tagId,
        tonality: filters.tonality,
        rhythm: filters.rhythm,
        category: filters.category,
        youtubeUrl: filters.youtubeUrl,
        searchInLyrics: filters.searchInLyrics,
        sortBy: filters.sortBy,
        sortDirection: 'asc',
        noNumber: filters.noNumber,
        forceRefresh: forceRefresh,
      );
      state = PraisesInfiniteState(
        items: AsyncData(list),
        hasMore: list.length >= _infinitePageSize,
        isLoadingMore: false,
      );
    } catch (e, stackTrace) {
      debugPrint('Erro ao carregar praises: $e');
      debugPrint('Stack trace: $stackTrace');
      if (_isErrorRecoverable(e)) {
        state = const PraisesInfiniteState(
          items: AsyncData([]),
          hasMore: false,
          isLoadingMore: false,
        );
      } else {
        state = PraisesInfiniteState(
          items: AsyncError(e, stackTrace),
          hasMore: true,
          isLoadingMore: false,
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    final current = state.items.value;
    if (current == null) return;
    state = PraisesInfiniteState(
      items: state.items,
      hasMore: state.hasMore,
      isLoadingMore: true,
    );
    final repository = ref.read(praiseRepositoryProvider);
    try {
      final next = await repository.getPraises(
        skip: current.length,
        limit: _infinitePageSize,
        name: filters.name,
        tagId: filters.tagId,
        tonality: filters.tonality,
        rhythm: filters.rhythm,
        category: filters.category,
        youtubeUrl: filters.youtubeUrl,
        searchInLyrics: filters.searchInLyrics,
        sortBy: filters.sortBy,
        sortDirection: 'asc',
        noNumber: filters.noNumber,
        forceRefresh: false,
      );
      // Evita duplicados se API/cache devolver a mesma página
      final currentIds = current.map((p) => p.id).toSet();
      final nextNew = next.where((p) => !currentIds.contains(p.id)).toList();
      final combined = [...current, ...nextNew];
      // Se veio resposta mas todos duplicados, não há mais páginas úteis
      final hasMoreNew = next.length >= _infinitePageSize && nextNew.isNotEmpty;
      state = PraisesInfiniteState(
        items: AsyncData(combined),
        hasMore: hasMoreNew,
        isLoadingMore: false,
      );
    } catch (e, stackTrace) {
      debugPrint('Erro ao carregar mais praises: $e');
      debugPrint('Stack trace: $stackTrace');
      state = PraisesInfiniteState(
        items: AsyncData(current),
        hasMore: state.hasMore,
        isLoadingMore: false,
      );
    }
  }
}

final praisesInfiniteProvider = NotifierProvider.autoDispose.family<
    PraisesInfiniteNotifier, PraisesInfiniteState, PraiseListFilters>(
  PraisesInfiniteNotifier.new,
);

/// Parâmetros para listagem de praises
/// Implementa == e hashCode para evitar loops infinitos no Riverpod
class PraiseListParams {
  final int skip;
  final int limit;
  final String? name;
  final String? tagId;
  final bool searchInLyrics;
  final String sortBy;
  final String sortDirection;
  final String noNumber;
  final bool forceRefresh;

  PraiseListParams({
    this.skip = 0,
    this.limit = 100,
    this.name,
    this.tagId,
    this.searchInLyrics = false,
    this.sortBy = 'name',
    this.sortDirection = 'asc',
    this.noNumber = 'last',
    this.forceRefresh = false,
  });

  PraiseListParams copyWith({
    int? skip,
    int? limit,
    String? name,
    String? tagId,
    bool? searchInLyrics,
    String? sortBy,
    String? sortDirection,
    String? noNumber,
    bool? forceRefresh,
  }) {
    return PraiseListParams(
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      name: name ?? this.name,
      tagId: tagId ?? this.tagId,
      searchInLyrics: searchInLyrics ?? this.searchInLyrics,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      noNumber: noNumber ?? this.noNumber,
      forceRefresh: forceRefresh ?? this.forceRefresh,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PraiseListParams &&
        other.skip == skip &&
        other.limit == limit &&
        other.name == name &&
        other.tagId == tagId &&
        other.searchInLyrics == searchInLyrics &&
        other.sortBy == sortBy &&
        other.sortDirection == sortDirection &&
        other.noNumber == noNumber &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode {
    return Object.hash(
      skip,
      limit,
      name,
      tagId,
      searchInLyrics,
      sortBy,
      sortDirection,
      noNumber,
      forceRefresh,
    );
  }
}
