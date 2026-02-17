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

/// Parâmetros para listagem de praises
/// Implementa == e hashCode para evitar loops infinitos no Riverpod
class PraiseListParams {
  final int skip;
  final int limit;
  final String? name;
  final String? tagId;
  final String sortBy;
  final String sortDirection;
  final String noNumber;
  final bool forceRefresh;

  PraiseListParams({
    this.skip = 0,
    this.limit = 100,
    this.name,
    this.tagId,
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
      sortBy,
      sortDirection,
      noNumber,
      forceRefresh,
    );
  }
}
