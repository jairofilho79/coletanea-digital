import '../../../praises/domain/entities/praise.dart';
import '../../../listas/domain/entities/lista.dart';

/// Entidade de domínio para Sala
/// Sala = lista de praises (compartilhada) + lista de materiais por participante (offline)
class Sala {
  final String id;
  final String name;
  final String? description;
  final List<PraiseListItem> praises; // Lista de praises ordenável (compartilhada)
  final DateTime createdAt;
  final DateTime updatedAt;

  Sala({
    required this.id,
    required this.name,
    this.description,
    this.praises = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Adiciona um praise à sala
  Sala addPraise(Praise praise, {int? position}) {
    final newPraises = List<PraiseListItem>.from(praises);
    final item = PraiseListItem(praise: praise, order: position ?? praises.length);
    if (position != null && position < newPraises.length) {
      newPraises.insert(position, item);
      for (int i = position + 1; i < newPraises.length; i++) {
        newPraises[i] = PraiseListItem(
          praise: newPraises[i].praise,
          order: i,
        );
      }
    } else {
      newPraises.add(item);
    }
    return Sala(
      id: id,
      name: name,
      description: description,
      praises: newPraises,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove um praise da sala
  Sala removePraise(String praiseId) {
    final newPraises = praises.where((item) => item.praise.id != praiseId).toList();
    for (int i = 0; i < newPraises.length; i++) {
      newPraises[i] = PraiseListItem(
        praise: newPraises[i].praise,
        order: i,
      );
    }
    return Sala(
      id: id,
      name: name,
      description: description,
      praises: newPraises,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Reordena os praises na sala
  Sala reorderPraises(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= praises.length ||
        newIndex < 0 || newIndex >= praises.length) {
      return this;
    }

    final newPraises = List<PraiseListItem>.from(praises);
    final item = newPraises.removeAt(oldIndex);
    newPraises.insert(newIndex, item);

    for (int i = 0; i < newPraises.length; i++) {
      newPraises[i] = PraiseListItem(
        praise: newPraises[i].praise,
        order: i,
      );
    }

    return Sala(
      id: id,
      name: name,
      description: description,
      praises: newPraises,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Lista de materiais de um participante (offline, local)
class MaterialList {
  final String salaId;
  final String praiseId;
  final List<String> materialIds; // IDs dos materiais na ordem desejada
  final DateTime updatedAt;

  MaterialList({
    required this.salaId,
    required this.praiseId,
    this.materialIds = const [],
    required this.updatedAt,
  });

  MaterialList addMaterial(String materialId, {int? position}) {
    final newMaterials = List<String>.from(materialIds);
    if (position != null && position < newMaterials.length) {
      newMaterials.insert(position, materialId);
    } else {
      newMaterials.add(materialId);
    }
    return MaterialList(
      salaId: salaId,
      praiseId: praiseId,
      materialIds: newMaterials,
      updatedAt: DateTime.now(),
    );
  }

  MaterialList removeMaterial(String materialId) {
    final newMaterials = materialIds.where((id) => id != materialId).toList();
    return MaterialList(
      salaId: salaId,
      praiseId: praiseId,
      materialIds: newMaterials,
      updatedAt: DateTime.now(),
    );
  }

  MaterialList reorderMaterials(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= materialIds.length ||
        newIndex < 0 || newIndex >= materialIds.length) {
      return this;
    }

    final newMaterials = List<String>.from(materialIds);
    final item = newMaterials.removeAt(oldIndex);
    newMaterials.insert(newIndex, item);

    return MaterialList(
      salaId: salaId,
      praiseId: praiseId,
      materialIds: newMaterials,
      updatedAt: DateTime.now(),
    );
  }
}
