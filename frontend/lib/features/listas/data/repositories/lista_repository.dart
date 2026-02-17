import '../../../praises/domain/entities/praise.dart';
import '../../domain/entities/lista.dart';
import '../../../../core/storage/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Repositório local para listas (Hive)
class ListaRepository {
  final Box _box = HiveService.listsBox;
  final _uuid = const Uuid();

  /// Cria uma nova lista
  Future<Lista> createLista({
    required String name,
    String? description,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final lista = Lista(
      id: id,
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    await _box.put(id, _listaToJson(lista));
    return lista;
  }

  /// Obtém todas as listas
  List<Lista> getAllListas() {
    final listas = <Lista>[];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data != null) {
        try {
          listas.add(_listaFromJson(data as Map<String, dynamic>));
        } catch (e) {
          // Ignora entradas inválidas
        }
      }
    }
    return listas..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Obtém uma lista por ID
  Lista? getListaById(String id) {
    final data = _box.get(id);
    if (data == null) {
      return null;
    }
    try {
      return _listaFromJson(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Atualiza uma lista
  Future<void> updateLista(Lista lista) async {
    await _box.put(lista.id, _listaToJson(lista));
  }

  /// Deleta uma lista
  Future<void> deleteLista(String id) async {
    await _box.delete(id);
  }

  Map<String, dynamic> _listaToJson(Lista lista) {
    return {
      'id': lista.id,
      'name': lista.name,
      'description': lista.description,
      'praises': lista.praises.map((item) => {
        'praise_id': item.praise.id,
        'order': item.order,
        'praise': {
          'id': item.praise.id,
          'name': item.praise.name,
          'number': item.praise.number,
        },
      }).toList(),
      'created_at': lista.createdAt.toIso8601String(),
      'updated_at': lista.updatedAt.toIso8601String(),
    };
  }

  Lista _listaFromJson(Map<String, dynamic> json) {
    final praisesJson = json['praises'] as List<dynamic>? ?? [];
    final now = DateTime.now();
    final praises = praisesJson.map((e) {
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
    return Lista(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      praises: praises,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
