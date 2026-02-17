import '../../domain/entities/playlist_material.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/playlist_material_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Repositório local para playlist de materiais (Hive)
class PlaylistMateriaisRepository {
  final Box _box = HiveService.playlistMateriaisBox;

  /// Obtém ou cria a playlist de materiais para um participante em uma sala
  PlaylistMateriais getOrCreatePlaylist(String salaId, String participanteId) {
    final key = PlaylistMateriaisModel.getKey(salaId, participanteId);
    final data = _box.get(key);
    
    if (data != null) {
      try {
        return PlaylistMateriaisModel.fromJson(data as Map<String, dynamic>);
      } catch (e) {
        // Se houver erro, cria nova
      }
    }
    
    return PlaylistMateriais(
      salaId: salaId,
      participanteId: participanteId,
      materiais: const [],
      updatedAt: DateTime.now(),
    );
  }

  /// Salva a playlist de materiais
  Future<void> savePlaylist(PlaylistMateriais playlist) async {
    final key = PlaylistMateriaisModel.getKey(playlist.salaId, playlist.participanteId);
    await _box.put(key, PlaylistMateriaisModel.toJson(playlist));
  }

  /// Obtém a playlist ordenada conforme a ordem dos praises na sala
  /// [praiseOrder] é uma lista de IDs de praises na ordem desejada
  List<MaterialNaPlaylist> getPlaylistOrdenada(
    String salaId,
    String participanteId,
    List<String> praiseOrder,
  ) {
    final playlist = getOrCreatePlaylist(salaId, participanteId);
    return playlist.getPlaylistOrdenada(praiseOrder);
  }

  /// Adiciona um material à playlist
  Future<void> addMaterial(
    String salaId,
    String participanteId,
    MaterialNaPlaylist material,
  ) async {
    final playlist = getOrCreatePlaylist(salaId, participanteId);
    final updated = playlist.addMaterial(material);
    await savePlaylist(updated);
  }

  /// Remove um material da playlist
  Future<void> removeMaterial(
    String salaId,
    String participanteId,
    String materialId,
  ) async {
    final playlist = getOrCreatePlaylist(salaId, participanteId);
    final updated = playlist.removeMaterial(materialId);
    await savePlaylist(updated);
  }

  /// Remove todos os materiais de um louvor específico
  Future<void> removeMateriaisDoPraise(
    String salaId,
    String participanteId,
    String praiseId,
  ) async {
    final playlist = getOrCreatePlaylist(salaId, participanteId);
    final updated = playlist.removeMateriaisDoPraise(praiseId);
    await savePlaylist(updated);
  }

  /// Obtém todos os materiais de uma playlist (sem ordenação)
  List<MaterialNaPlaylist> getAllMateriais(String salaId, String participanteId) {
    final playlist = getOrCreatePlaylist(salaId, participanteId);
    return playlist.materiais;
  }
}
