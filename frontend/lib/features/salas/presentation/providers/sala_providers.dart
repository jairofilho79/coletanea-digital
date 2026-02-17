import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sala.dart';
import '../../domain/entities/playlist_material.dart';
import '../../data/repositories/sala_repository.dart';
import '../../data/repositories/playlist_materiais_repository.dart';
import '../../../../core/storage/hive_service.dart';
import 'package:uuid/uuid.dart';

/// Provider do repositório de salas
final salaRepositoryProvider = Provider<SalaRepository>((ref) {
  return SalaRepository();
});

/// Provider do repositório de playlist de materiais
final playlistMateriaisRepositoryProvider = Provider<PlaylistMateriaisRepository>((ref) {
  return PlaylistMateriaisRepository();
});

/// Provider para obter o ID do participante local
/// Gera um UUID na primeira execução e persiste no Hive
final participanteIdProvider = FutureProvider<String>((ref) async {
  const key = 'participante_id';
  final box = HiveService.settingsBox;
  
  String? participanteId = box.get(key);
  if (participanteId == null) {
    participanteId = const Uuid().v4();
    await box.put(key, participanteId);
  }
  
  return participanteId;
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

/// Provider para playlist de materiais ordenada
/// Retorna a playlist ordenada conforme a ordem dos praises na sala
final playlistMateriaisProvider = FutureProvider.family<List<MaterialNaPlaylist>, PlaylistParams>((ref, params) async {
  final playlistRepo = ref.watch(playlistMateriaisRepositoryProvider);
  final salaRepo = ref.watch(salaRepositoryProvider);
  final participanteId = await ref.watch(participanteIdProvider.future);
  
  final sala = salaRepo.getSalaById(params.salaId);
  if (sala == null) return [];
  
  final praiseOrder = sala.praises.map((p) => p.praise.id).toList();
  return playlistRepo.getPlaylistOrdenada(params.salaId, participanteId, praiseOrder);
});

/// Parâmetros para playlist de materiais
class PlaylistParams {
  final String salaId;
  
  PlaylistParams({required this.salaId});
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaylistParams && other.salaId == salaId;
  }
  
  @override
  int get hashCode => salaId.hashCode;
}
