import '../../domain/entities/sala.dart';
import '../../../../core/storage/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Repositório local para salas (Hive)
class SalaRepository {
  final Box _box = HiveService.roomsBox;
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
    );

    await _box.put(id, _salaToJson(sala));
    return sala;
  }

  /// Obtém todas as salas
  List<Sala> getAllSalas() {
    final salas = <Sala>[];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data != null) {
        try {
          salas.add(_salaFromJson(data as Map<String, dynamic>));
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
      return _salaFromJson(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Atualiza uma sala
  Future<void> updateSala(Sala sala) async {
    await _box.put(sala.id, _salaToJson(sala));
  }

  /// Deleta uma sala
  Future<void> deleteSala(String id) async {
    await _box.delete(id);
  }

  Map<String, dynamic> _salaToJson(Sala sala) {
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
    };
  }

  Sala _salaFromJson(Map<String, dynamic> json) {
    return Sala(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      praises: [], // TODO: Carregar praises completos
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
