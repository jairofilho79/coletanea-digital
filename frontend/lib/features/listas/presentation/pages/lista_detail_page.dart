import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../providers/lista_providers.dart';
import '../../../praises/domain/entities/praise.dart';

/// Página de detalhes de uma lista (nome, descrição, louvores)
class ListaDetailPage extends ConsumerWidget {
  final String listaId;

  const ListaDetailPage({
    super.key,
    required this.listaId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listaAsync = ref.watch(listaProvider(listaId));

    return Scaffold(
      appBar: AppBar(
        leading: RootDrawerScope.maybeOf(context) != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => RootDrawerScope.of(context).openDrawer(),
                tooltip: 'Menu',
              )
            : null,
        title: const Text('Detalhe da lista'),
      ),
      body: listaAsync.when(
        data: (lista) {
          if (lista == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Lista não encontrada',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => context.go('/listas'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar para listas'),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/praises?addToLista=${lista.id}'),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar louvor'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lista.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (lista.description != null &&
                        lista.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        lista.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[400],
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.music_note, size: 18, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          '${lista.praises.length} louvor(es)',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[400],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (lista.praises.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum louvor nesta lista',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[400],
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Segure e arraste para reordenar',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[400],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            proxyDecorator: (child, index, animation) {
                              return Material(
                                color: Colors.transparent,
                                child: child,
                              );
                            },
                            itemCount: lista.praises.length,
                            onReorder: (oldIndex, newIndex) async {
                              if (newIndex > lista.praises.length) {
                                newIndex = lista.praises.length;
                              }
                              if (newIndex > oldIndex) newIndex--;
                              final newLista = lista.reorderPraises(oldIndex, newIndex);
                              await ref.read(listaRepositoryProvider).updateLista(newLista);
                              ref.invalidate(listaProvider(listaId));
                              ref.invalidate(listasProvider);
                            },
                            itemBuilder: (context, index) {
                              final item = lista.praises[index];
                              return _PraiseListTile(
                                key: ValueKey(item.praise.id),
                                index: index,
                                praise: item.praise,
                                onTap: () => context.push('/praises/${item.praise.id}'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Erro ao carregar a lista'),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.go('/listas'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para listas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PraiseListTile extends StatelessWidget {
  final int index;
  final Praise praise;
  final VoidCallback? onTap;

  const _PraiseListTile({
    super.key,
    required this.index,
    required this.praise,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        title: Text(praise.name),
        subtitle: praise.number != null
            ? Text('Nº ${praise.number}')
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
