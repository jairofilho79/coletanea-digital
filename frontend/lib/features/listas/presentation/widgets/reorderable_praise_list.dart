import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/lista.dart';
import '../../../praises/domain/entities/praise.dart';
import '../../../praises/presentation/providers/translation_providers.dart';

/// Lista reordenável de louvores. Usado em detalhes de Lista e de Sala.
class ReorderablePraiseList extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
          ref: ref,
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
  final WidgetRef ref;
  final Future<void> Function() onRemove;
  final VoidCallback onTap;

  const _PraiseListTile({
    super.key,
    required this.index,
    required this.item,
    required this.ref,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ref.watch(translationsLoadedProvider);
    final translationService = ref.watch(translationServiceProvider);
    final praise = item.praise;

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.drag_handle,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        praise.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF5A2A2A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (praise.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: praise.tags.map((tag) {
                            final translatedName = translationService
                                .getPraiseTagName(tag.id, tag.name);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E6D3),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                translatedName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFFD4AF37),
                  onPressed: onRemove,
                  tooltip: 'Remover da lista',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
