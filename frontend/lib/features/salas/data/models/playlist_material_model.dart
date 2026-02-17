import '../../domain/entities/playlist_material.dart';

/// Model para serialização Hive de PlaylistMateriais
class PlaylistMateriaisModel {
  static String getKey(String salaId, String participanteId) {
    return '$salaId:$participanteId';
  }

  static Map<String, dynamic> toJson(PlaylistMateriais playlist) {
    return {
      'sala_id': playlist.salaId,
      'participante_id': playlist.participanteId,
      'materiais': playlist.materiais.map((m) => {
        'material_id': m.materialId,
        'praise_id': m.praiseId,
        'nome_material': m.nomeMaterial,
        'nome_praise': m.nomePraise,
        'tipo_material': m.tipoMaterial,
      }).toList(),
      'updated_at': playlist.updatedAt.toIso8601String(),
    };
  }

  static PlaylistMateriais fromJson(Map<String, dynamic> json) {
    final materiaisJson = json['materiais'] as List<dynamic>? ?? [];
    final materiais = materiaisJson.map((e) {
      final m = e as Map<String, dynamic>;
      return MaterialNaPlaylist(
        materialId: m['material_id'] as String,
        praiseId: m['praise_id'] as String,
        nomeMaterial: m['nome_material'] as String,
        nomePraise: m['nome_praise'] as String,
        tipoMaterial: m['tipo_material'] as String,
      );
    }).toList();

    return PlaylistMateriais(
      salaId: json['sala_id'] as String,
      participanteId: json['participante_id'] as String,
      materiais: materiais,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
