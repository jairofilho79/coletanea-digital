import '../../../praises/domain/entities/praise.dart';

/// Entidade de domínio para Lista de Praises
class Lista {
  final String id;
  final String name;
  final String? description;
  final List<PraiseListItem> praises;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lista({
    required this.id,
    required this.name,
    this.description,
    this.praises = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Adiciona um praise à lista
  Lista addPraise(Praise praise, {int? position}) {
    final newPraises = List<PraiseListItem>.from(praises);
    final item = PraiseListItem(praise: praise, order: position ?? praises.length);
    if (position != null && position < newPraises.length) {
      newPraises.insert(position, item);
      // Reordena os itens seguintes
      for (int i = position + 1; i < newPraises.length; i++) {
        newPraises[i] = PraiseListItem(
          praise: newPraises[i].praise,
          order: i,
        );
      }
    } else {
      newPraises.add(item);
    }
    return Lista(
      id: id,
      name: name,
      description: description,
      praises: newPraises,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove um praise da lista
  Lista removePraise(String praiseId) {
    final newPraises = praises.where((item) => item.praise.id != praiseId).toList();
    // Reordena
    for (int i = 0; i < newPraises.length; i++) {
      newPraises[i] = PraiseListItem(
        praise: newPraises[i].praise,
        order: i,
      );
    }
    return Lista(
      id: id,
      name: name,
      description: description,
      praises: newPraises,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Reordena os praises na lista.
  /// [newIndex] pode ser igual a praises.length (arrastar para o final).
  Lista reorderPraises(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= praises.length || newIndex < 0) {
      return this;
    }

    final newPraises = List<PraiseListItem>.from(praises);
    final item = newPraises.removeAt(oldIndex);
    final insertIndex = newIndex > newPraises.length ? newPraises.length : newIndex;
    newPraises.insert(insertIndex, item);

    // Reordena todos os itens
    for (int i = 0; i < newPraises.length; i++) {
      newPraises[i] = PraiseListItem(
        praise: newPraises[i].praise,
        order: i,
      );
    }

    return Lista(
      id: id,
      name: name,
      description: description,
      praises: newPraises,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Item de uma lista (praise com ordem)
class PraiseListItem {
  final Praise praise;
  final int order;

  PraiseListItem({
    required this.praise,
    required this.order,
  });
}
