/// Entidade de domínio para Playlist de Materiais de uma Sala
/// Representa a playlist de materiais de um participante em uma sala
class PlaylistMateriais {
  final String salaId;
  final String participanteId; // Identificador do participante (local no MVP)
  final List<MaterialNaPlaylist> materiais; // Lista ordenada de materiais
  final DateTime updatedAt;

  PlaylistMateriais({
    required this.salaId,
    required this.participanteId,
    this.materiais = const [],
    required this.updatedAt,
  });

  /// Adiciona um material à playlist
  PlaylistMateriais addMaterial(MaterialNaPlaylist material) {
    final newMateriais = List<MaterialNaPlaylist>.from(materiais);
    newMateriais.add(material);
    return PlaylistMateriais(
      salaId: salaId,
      participanteId: participanteId,
      materiais: newMateriais,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove um material da playlist
  PlaylistMateriais removeMaterial(String materialId) {
    final newMateriais = materiais.where((m) => m.materialId != materialId).toList();
    return PlaylistMateriais(
      salaId: salaId,
      participanteId: participanteId,
      materiais: newMateriais,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove todos os materiais de um louvor específico
  PlaylistMateriais removeMateriaisDoPraise(String praiseId) {
    final newMateriais = materiais.where((m) => m.praiseId != praiseId).toList();
    return PlaylistMateriais(
      salaId: salaId,
      participanteId: participanteId,
      materiais: newMateriais,
      updatedAt: DateTime.now(),
    );
  }

  /// Retorna a playlist ordenada conforme a ordem dos louvores
  /// [praiseOrder] é uma lista de IDs de praises na ordem desejada
  List<MaterialNaPlaylist> getPlaylistOrdenada(List<String> praiseOrder) {
    final ordered = <MaterialNaPlaylist>[];
    
    // Para cada louvor na ordem especificada
    for (final praiseId in praiseOrder) {
      // Buscar todos os materiais desse louvor mantendo a ordem relativa atual
      final materiaisDoPraise = materiais
          .where((m) => m.praiseId == praiseId)
          .toList();
      ordered.addAll(materiaisDoPraise);
    }
    
    return ordered;
  }
}

/// Material na playlist de uma sala
class MaterialNaPlaylist {
  final String materialId; // ID do material
  final String praiseId; // ID do praise de origem
  final String nomeMaterial; // Nome do material (cache)
  final String nomePraise; // Nome do praise (cache)
  final String tipoMaterial; // 'pdf' ou 'lyrics'

  MaterialNaPlaylist({
    required this.materialId,
    required this.praiseId,
    required this.nomeMaterial,
    required this.nomePraise,
    required this.tipoMaterial,
  });

  /// Nome para exibição: "Nome do Material - Nome do Praise"
  String get displayName => '$nomeMaterial - $nomePraise';
}
