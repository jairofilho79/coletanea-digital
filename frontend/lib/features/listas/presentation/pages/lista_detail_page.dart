import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../providers/lista_providers.dart';
import '../widgets/reorderable_praise_list.dart';
import '../../domain/entities/lista.dart';

/// Página de detalhes de uma lista (nome, descrição, louvores)
class ListaDetailPage extends ConsumerStatefulWidget {
  final String listaId;

  const ListaDetailPage({
    super.key,
    required this.listaId,
  });

  @override
  ConsumerState<ListaDetailPage> createState() => _ListaDetailPageState();
}

class _ListaDetailPageState extends ConsumerState<ListaDetailPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _nameDirty = false;
  bool _descriptionDirty = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveName(Lista? lista) async {
    if (lista == null || !_nameDirty) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final updatedLista = Lista(
      id: lista.id,
      name: name,
      description: lista.description,
      praises: lista.praises,
      createdAt: lista.createdAt,
      updatedAt: DateTime.now(),
    );
    await ref.read(listaRepositoryProvider).updateLista(updatedLista);
    _nameDirty = false;
    ref.invalidate(listaProvider(widget.listaId));
    ref.invalidate(listasProvider);
  }

  Future<void> _saveDescription(Lista? lista) async {
    if (lista == null || !_descriptionDirty) return;
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final updatedLista = Lista(
      id: lista.id,
      name: lista.name,
      description: description,
      praises: lista.praises,
      createdAt: lista.createdAt,
      updatedAt: DateTime.now(),
    );
    await ref.read(listaRepositoryProvider).updateLista(updatedLista);
    _descriptionDirty = false;
    ref.invalidate(listaProvider(widget.listaId));
    ref.invalidate(listasProvider);
  }

  @override
  Widget build(BuildContext context) {
    final listaAsync = ref.watch(listaProvider(widget.listaId));

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

          // Sincroniza os controllers apenas se não houver mudanças pendentes
          if (!_nameDirty && _nameController.text != lista.name) {
            _nameController.text = lista.name;
          }
          if (!_descriptionDirty && _descriptionController.text != (lista.description ?? '')) {
            _descriptionController.text = lista.description ?? '';
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _nameDirty = true,
                      onSubmitted: (_) => _saveName(lista),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (_) => _descriptionDirty = true,
                      onSubmitted: (_) => _saveDescription(lista),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.push('/praises?addToLista=${lista.id}'),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar louvor'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ReorderablePraiseList(
                  items: lista.praises,
                  emptyMessage: 'Nenhum louvor nesta lista.',
                  emptyActionLabel: 'Adicionar louvor',
                  onEmptyActionPressed: () => context.push('/praises?addToLista=${lista.id}'),
                  onReorder: (oldIndex, newIndex) async {
                    final newLista = lista.reorderPraises(oldIndex, newIndex);
                    await ref.read(listaRepositoryProvider).updateLista(newLista);
                    ref.invalidate(listaProvider(widget.listaId));
                    ref.invalidate(listasProvider);
                  },
                  onRemove: (praiseId) async {
                    final updatedLista = lista.removePraise(praiseId);
                    await ref.read(listaRepositoryProvider).updateLista(updatedLista);
                    ref.invalidate(listaProvider(widget.listaId));
                    ref.invalidate(listasProvider);
                  },
                  onTap: (praise) => context.push('/praises/${praise.id}'),
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
