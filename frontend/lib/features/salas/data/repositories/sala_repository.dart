import '../../domain/entities/sala.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../praises/domain/entities/praise.dart';
import '../../../listas/domain/entities/lista.dart';
import '../../../listas/data/repositories/lista_repository.dart';
import '../models/sala_model.dart';
import '../models/playlist_material_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Repositório local para salas (Hive)
class SalaRepository {
  final Box _box = HiveService.roomsBox;
  final Box _playlistBox = HiveService.playlistMateriaisBox;
  final _uuid = const Uuid();

  /// Cria uma nova sala
  Future<Sala> createSala({
    required String name,
    String? description,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final sala = Sala(
      id: id,
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
    );

    await _box.put(id, SalaModel.toJson(sala));
    return sala;
  }

  /// Obtém todas as salas
  List<Sala> getAllSalas() {
    final salas = <Sala>[];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data != null) {
        try {
          salas.add(SalaModel.fromJson(data as Map<String, dynamic>));
        } catch (e) {
          // Ignora entradas inválidas
        }
      }
    }
    return salas..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Obtém uma sala por ID
  Sala? getSalaById(String id) {
    final data = _box.get(id);
    if (data == null) {
      return null;
    }
    try {
      return SalaModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Atualiza uma sala
  Future<void> updateSala(Sala sala) async {
    await _box.put(sala.id, SalaModel.toJson(sala));
  }

  /// Deleta uma sala
  Future<void> deleteSala(String id) async {
    await _box.delete(id);
    // Remove todas as playlists de materiais dessa sala
    final keysToDelete = <String>[];
    for (final key in _playlistBox.keys) {
      final data = _playlistBox.get(key);
      if (data != null) {
        try {
          final playlist = PlaylistMateriaisModel.fromJson(data as Map<String, dynamic>);
          if (playlist.salaId == id) {
            keysToDelete.add(key as String);
          }
        } catch (e) {
          // Ignora
        }
      }
    }
    for (final key in keysToDelete) {
      await _playlistBox.delete(key);
    }
  }

  /// Adiciona um praise à sala
  Future<void> addPraise(String salaId, Praise praise, {int? position}) async {
    final sala = getSalaById(salaId);
    if (sala == null) return;
    
    final updated = sala.addPraise(praise, position: position);
    await updateSala(updated);
    
    // Reordena automaticamente a playlist de materiais
    await _reordenarPlaylistMateriais(salaId);
  }

  /// Remove um praise da sala (remove também todos os materiais desse louvor)
  Future<void> removePraise(String salaId, String praiseId) async {
    final sala = getSalaById(salaId);
    if (sala == null) return;
    
    final updated = sala.removePraise(praiseId);
    await updateSala(updated);
    
    // Remove todos os materiais desse louvor de todas as playlists
    await _removerMateriaisDoPraise(salaId, praiseId);
  }

  /// Remove todos os praises da sala (limpa a lista)
  Future<void> clearPraises(String salaId) async {
    final sala = getSalaById(salaId);
    if (sala == null) return;
    
    // Remove todos os materiais de todas as playlists dessa sala
    for (final key in _playlistBox.keys) {
      final data = _playlistBox.get(key);
      if (data != null) {
        try {
          final playlist = PlaylistMateriaisModel.fromJson(data as Map<String, dynamic>);
          if (playlist.salaId == salaId) {
            await _playlistBox.delete(key);
          }
        } catch (e) {
          // Ignora
        }
      }
    }
    
    // Limpa a lista de praises e remove o importedFromListaId.
    // Não usar copyWith(importedFromListaId: null) porque copyWith trata null como "manter valor".
    final updated = Sala(
      id: sala.id,
      name: sala.name,
      description: sala.description,
      praises: [],
      createdAt: sala.createdAt,
      updatedAt: DateTime.now(),
      isFavorite: sala.isFavorite,
      importedFromListaId: null, // explicitamente limpo
    );
    await updateSala(updated);
  }

  /// Reordena os praises na sala
  Future<void> reorderPraises(String salaId, int fromIndex, int toIndex) async {
    final sala = getSalaById(salaId);
    if (sala == null) return;
    
    final updated = sala.reorderPraises(fromIndex, toIndex);
    await updateSala(updated);
    
    // Reordena automaticamente a playlist de materiais
    await _reordenarPlaylistMateriais(salaId);
  }

  /// Importa todos os praises de uma lista para a sala
  Future<void> importFromLista(String salaId, Lista lista) async {
    final sala = getSalaById(salaId);
    if (sala == null) return;
    
    final updated = sala.importFromLista(lista);
    await updateSala(updated);
  }

  /// Atualiza o nome da sala
  Future<void> updateName(String salaId, String name) async {
    final sala = getSalaById(salaId);
    if (sala == null) return;
    
    final updated = sala.copyWith(name: name, updatedAt: DateTime.now());
    await updateSala(updated);
  }

  /// Atualiza a descrição da sala
  Future<void> updateDescription(String salaId, String? description) async {
    final sala = getSalaById(salaId);
    if (sala == null) return;
    
    final updated = sala.copyWith(description: description, updatedAt: DateTime.now());
    await updateSala(updated);
  }

  /// Alterna o favorito da sala
  Future<void> toggleFavorite(String salaId) async {
    final sala = getSalaById(salaId);
    if (sala == null) return;
    
    final updated = sala.copyWith(isFavorite: !sala.isFavorite, updatedAt: DateTime.now());
    await updateSala(updated);
  }

  /// Salva os praises da sala como uma nova lista
  /// Retorna o ID da lista criada
  Future<String> saveAsLista({
    required String salaId,
    required String name,
    String? description,
  }) async {
    final sala = getSalaById(salaId);
    if (sala == null) throw Exception('Sala não encontrada');
    
    // Importa ListaRepository para criar a lista
    final listaRepo = ListaRepository();
    final lista = await listaRepo.createLista(
      name: name,
      description: description,
    );
    
    // Adiciona todos os praises da sala à lista
    for (final item in sala.praises) {
      final currentLista = listaRepo.getListaById(lista.id);
      if (currentLista != null) {
        final updated = currentLista.addPraise(item.praise);
        await listaRepo.updateLista(updated);
      }
    }
    
    return lista.id;
  }

  /// Sobrescreve a lista importada com os praises atuais da sala
  Future<void> overwriteImportedLista(String salaId) async {
    final sala = getSalaById(salaId);
    if (sala == null || sala.importedFromListaId == null) {
      throw Exception('Sala não encontrada ou não foi importada de uma lista');
    }
    
    // Importa ListaRepository para atualizar a lista
    final listaRepo = ListaRepository();
    final lista = listaRepo.getListaById(sala.importedFromListaId!);
    if (lista == null) {
      throw Exception('Lista importada não encontrada');
    }
    
    // Remove todos os praises da lista e adiciona os da sala
    var updated = lista;
    for (final item in lista.praises) {
      updated = updated.removePraise(item.praise.id);
    }
    
    // Adiciona os praises da sala na ordem atual
    for (final item in sala.praises) {
      updated = updated.addPraise(item.praise);
    }
    
    await listaRepo.updateLista(updated);
  }

  /// Reordena automaticamente a playlist de materiais conforme a ordem dos praises
  Future<void> _reordenarPlaylistMateriais(String salaId) async {
    final sala = getSalaById(salaId);
    if (sala == null) return;
    
    // Atualiza todas as playlists dessa sala
    for (final key in _playlistBox.keys) {
      final data = _playlistBox.get(key);
      if (data != null) {
        try {
          final playlist = PlaylistMateriaisModel.fromJson(data as Map<String, dynamic>);
          if (playlist.salaId == salaId) {
            // A ordenação é feita na leitura, não precisa salvar novamente
            // Mas podemos garantir que está consistente
            await _playlistBox.put(key, PlaylistMateriaisModel.toJson(playlist));
          }
        } catch (e) {
          // Ignora
        }
      }
    }
  }

  /// Remove todos os materiais de um louvor específico de todas as playlists
  Future<void> _removerMateriaisDoPraise(String salaId, String praiseId) async {
    for (final key in _playlistBox.keys) {
      final data = _playlistBox.get(key);
      if (data != null) {
        try {
          final playlist = PlaylistMateriaisModel.fromJson(data as Map<String, dynamic>);
          if (playlist.salaId == salaId) {
            final updated = playlist.removeMateriaisDoPraise(praiseId);
            await _playlistBox.put(key, PlaylistMateriaisModel.toJson(updated));
          }
        } catch (e) {
          // Ignora
        }
      }
    }
  }
}
