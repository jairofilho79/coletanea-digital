import '../../domain/entities/sala.dart';
import '../../../praises/domain/entities/praise.dart';
import '../../../listas/domain/entities/lista.dart';

/// Model para serialização Hive de Sala
class SalaModel {
  static Map<String, dynamic> toJson(Sala sala) {
    return {
      'id': sala.id,
      'name': sala.name,
      'description': sala.description,
      'praises': sala.praises.map((item) => {
        'praise_id': item.praise.id,
        'order': item.order,
        'praise': {
          'id': item.praise.id,
          'name': item.praise.name,
          'number': item.praise.number,
        },
      }).toList(),
      'created_at': sala.createdAt.toIso8601String(),
      'updated_at': sala.updatedAt.toIso8601String(),
      'is_favorite': sala.isFavorite,
      'imported_from_lista_id': sala.importedFromListaId,
    };
  }

  static Sala fromJson(Map<String, dynamic> json) {
    final praisesJson = json['praises'] as List<dynamic>? ?? [];
    final now = DateTime.now();
    final praises = praisesJson.map<PraiseListItem>((e) {
      final item = e as Map<String, dynamic>;
      final order = item['order'] as int? ?? 0;
      final p = (item['praise'] as Map<String, dynamic>? ?? item);
      final praise = Praise(
        id: p['id'] as String,
        name: p['name'] as String? ?? '',
        number: p['number'] as int?,
        createdAt: now,
        updatedAt: now,
      );
      return PraiseListItem(praise: praise, order: order);
    }).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Sala(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      praises: praises,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isFavorite: json['is_favorite'] as bool? ?? false,
      importedFromListaId: json['imported_from_lista_id'] as String?,
    );
  }
}
