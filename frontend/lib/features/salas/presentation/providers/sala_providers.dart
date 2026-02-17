import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sala.dart';
import '../../data/repositories/sala_repository.dart';

/// Provider do repositório de salas
final salaRepositoryProvider = Provider<SalaRepository>((ref) {
  return SalaRepository();
});

/// Provider para lista de salas
final salasProvider = FutureProvider<List<Sala>>((ref) async {
  final repository = ref.watch(salaRepositoryProvider);
  return repository.getAllSalas();
});

/// Provider para uma sala específica
final salaProvider = FutureProvider.family<Sala?, String>((ref, id) async {
  final repository = ref.watch(salaRepositoryProvider);
  return repository.getSalaById(id);
});
