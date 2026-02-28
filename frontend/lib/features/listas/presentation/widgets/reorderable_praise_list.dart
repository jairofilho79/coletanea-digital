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
    this.emptyInstruction,
    required this.emptyActionLabel,
    required this.onEmptyActionPressed,
  });

  final List<PraiseListItem> items;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function(String praiseId) onRemove;
  final void Function(Praise praise) onTap;
  final String emptyMessage;
  final String? emptyInstruction;
  final String emptyActionLabel;
  final VoidCallback onEmptyActionPressed;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
            if (emptyInstruction != null) ...[
              const SizedBox(height: 8),
              Text(
                emptyInstruction!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[400],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
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
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(
                      Icons.drag_handle,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.praise.displayName,
                    style: const TextStyle(
                      color: Color(0xFF5A2A2A),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'EB Garamond',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFFD4AF37),
                  onPressed: onRemove,
                  tooltip: 'Remover',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
