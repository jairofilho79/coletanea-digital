import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/lista.dart';
import '../../data/repositories/lista_repository.dart';

/// Provider do repositório de listas
final listaRepositoryProvider = Provider<ListaRepository>((ref) {
  return ListaRepository();
});

/// Provider para lista de listas
final listasProvider = FutureProvider<List<Lista>>((ref) async {
  final repository = ref.watch(listaRepositoryProvider);
  return repository.getAllListas();
});

/// Provider para uma lista específica
final listaProvider = FutureProvider.family<Lista?, String>((ref, id) async {
  final repository = ref.watch(listaRepositoryProvider);
  return repository.getListaById(id);
});
