import 'package:flutter/material.dart';
import '../../domain/entities/lista.dart';
import '../../../praises/domain/entities/praise.dart';

/// Lista reordenável de louvores. Usado em detalhes de Lista e de Sala.
class ReorderablePraiseList extends StatelessWidget {
  const ReorderablePraiseList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onRemove,
    required this.onTap,
    required this.emptyMessage,
    required this.emptyActionLabel,
    required this.onEmptyActionPressed,
  });

  final List<PraiseListItem> items;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function(String praiseId) onRemove;
  final void Function(Praise praise) onTap;
  final String emptyMessage;
  final String emptyActionLabel;
  final VoidCallback onEmptyActionPressed;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emptyMessage),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onEmptyActionPressed,
              icon: const Icon(Icons.add),
              label: Text(emptyActionLabel),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > items.length) {
          newIndex = items.length;
        }
        if (newIndex > oldIndex) newIndex--;
        await onReorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return _PraiseListTile(
          key: ValueKey('${item.praise.id}_${index}_${item.order}'),
          index: index,
          item: item,
          onRemove: () async => await onRemove(item.praise.id),
          onTap: () => onTap(item.praise),
        );
      },
    );
  }
}

class _PraiseListTile extends StatelessWidget {
  final int index;
  final PraiseListItem item;
  final Future<void> Function() onRemove;
  final VoidCallback onTap;

  const _PraiseListTile({
    super.key,
    required this.index,
    required this.item,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: key,
      leading: ReorderableDragStartListener(
        index: index,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: const Icon(Icons.drag_handle),
        ),
      ),
      title: Text(item.praise.displayName),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: onRemove,
        tooltip: 'Remover',
      ),
      onTap: onTap,
    );
  }
}
