import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../providers/sala_providers.dart';
import '../../../listas/presentation/providers/lista_providers.dart';
import '../../../listas/presentation/widgets/reorderable_praise_list.dart';
import '../../../listas/domain/entities/lista.dart';
import '../../domain/entities/sala.dart';

/// Página de detalhes de uma sala com tabs (Louvores e Playlist)
class SalaDetailPage extends ConsumerStatefulWidget {
  final String salaId;

  const SalaDetailPage({
    super.key,
    required this.salaId,
  });

  @override
  ConsumerState<SalaDetailPage> createState() => _SalaDetailPageState();
}

class _SalaDetailPageState extends ConsumerState<SalaDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _nameDirty = false;
  bool _descriptionDirty = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveName(Sala? sala) async {
    if (sala == null || !_nameDirty) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await ref.read(salaRepositoryProvider).updateName(sala.id, name);
    _nameDirty = false;
    ref.invalidate(salaProvider(widget.salaId));
    ref.invalidate(salasProvider);
  }

  Future<void> _saveDescription(Sala? sala) async {
    if (sala == null || !_descriptionDirty) return;
    await ref.read(salaRepositoryProvider).updateDescription(
          sala.id,
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
    _descriptionDirty = false;
    ref.invalidate(salaProvider(widget.salaId));
    ref.invalidate(salasProvider);
  }

  Future<void> _delete(Sala sala) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir sala'),
        content: Text(
          'Excluir a sala "${sala.name}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(salaRepositoryProvider).deleteSala(sala.id);
      ref.invalidate(salasProvider);
      if (mounted) context.go('/salas');
    }
  }

  @override
  Widget build(BuildContext context) {
    final salaAsync = ref.watch(salaProvider(widget.salaId));

    return salaAsync.when(
      data: (sala) {
        if (sala == null) {
          return Scaffold(
            appBar: AppBar(
              leading: RootDrawerScope.maybeOf(context) != null
                  ? IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => RootDrawerScope.of(context).openDrawer(),
                      tooltip: 'Menu',
                    )
                  : null,
              title: const Text('Sala'),
            ),
            body: const Center(child: Text('Sala não encontrada')),
          );
        }

        if (_nameController.text.isEmpty) {
          _nameController.text = sala.name;
        }
        if (_descriptionController.text.isEmpty) {
          _descriptionController.text = sala.description ?? '';
        }

        return Scaffold(
          appBar: AppBar(
            leading: RootDrawerScope.maybeOf(context) != null
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => RootDrawerScope.of(context).openDrawer(),
                    tooltip: 'Menu',
                  )
                : null,
            title: const Text('Detalhes da Sala'),
            actions: [
              IconButton(
                icon: Icon(sala.isFavorite ? Icons.star : Icons.star_border),
                color: sala.isFavorite ? Colors.amber : null,
                onPressed: () async {
                  await ref.read(salaRepositoryProvider).toggleFavorite(sala.id);
                  ref.invalidate(salaProvider(widget.salaId));
                  ref.invalidate(salasProvider);
                },
                tooltip: 'Favorito',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'delete') _delete(sala);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'delete', child: Text('Excluir sala')),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Louvores', icon: Icon(Icons.music_note)),
                Tab(text: 'Playlist', icon: Icon(Icons.queue_music)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildLouvoresTab(context, sala),
              _buildPlaylistTab(context, sala),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Sala')),
        body: Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildLouvoresTab(BuildContext context, Sala sala) {
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
                onSubmitted: (_) => _saveName(sala),
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
                onSubmitted: (_) => _saveDescription(sala),
              ),
              const SizedBox(height: 12),
              // Indicador visual se foi importado de uma lista
              if (sala.importedFromListaId != null)
                Builder(
                  builder: (context) {
                    final listaRepo = ref.read(listaRepositoryProvider);
                    final listaImportada = listaRepo.getListaById(sala.importedFromListaId!);
                    final nomeLista = listaImportada?.name ?? 'lista desconhecida';
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Importado da lista: $nomeLista',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue[700],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              // Botões sempre na mesma linha
              Row(
                children: [
                  // Botão "Adicionar louvores" - sempre 50%
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/praises?addToSala=${sala.id}'),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar louvores'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mostra "Importar lista" apenas se não houver louvores e não foi importado
                  if (sala.praises.isEmpty && sala.importedFromListaId == null)
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => _showImportListaDialog(context, sala),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Importar lista'),
                      ),
                    )
                  else ...[
                    // Quando há louvores ou foi importado: mostra "Limpar lista" (25%) + "Salvar como lista" (25%)
                    Expanded(
                      flex: 1,
                      child: FilledButton.icon(
                        onPressed: () => _handleClearPraises(context, sala),
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Limpar lista'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: FilledButton.icon(
                        onPressed: () => _handleSaveAsLista(context, sala),
                        icon: const Icon(Icons.save),
                        label: const Text('Salvar como lista'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ReorderablePraiseList(
            items: sala.praises,
            emptyMessage: 'Nenhum louvor na sala.',
            emptyActionLabel: 'Adicionar louvores',
            onEmptyActionPressed: () => context.push('/praises?addToSala=${sala.id}'),
            onReorder: (oldIndex, newIndex) async {
              await ref.read(salaRepositoryProvider).reorderPraises(
                    sala.id,
                    oldIndex,
                    newIndex,
                  );
              ref.invalidate(salaProvider(widget.salaId));
              ref.invalidate(salasProvider);
            },
            onRemove: (praiseId) async {
              await ref.read(salaRepositoryProvider).removePraise(sala.id, praiseId);
              ref.invalidate(salaProvider(widget.salaId));
              ref.invalidate(salasProvider);
              ref.invalidate(playlistMateriaisProvider(PlaylistParams(salaId: sala.id)));
            },
            onTap: (praise) => context.push('/praises/${praise.id}?salaId=${sala.id}'),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistTab(BuildContext context, Sala sala) {
    final playlistAsync = ref.watch(playlistMateriaisProvider(PlaylistParams(salaId: sala.id)));

    return playlistAsync.when(
      data: (materiais) {
        if (materiais.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nenhum material na playlist.'),
                const SizedBox(height: 8),
                Text(
                  'Adicione materiais clicando neles na tela de detalhes do louvor.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: materiais.length,
          itemBuilder: (context, index) {
            final material = materiais[index];
            final showDivider = index > 0 &&
                materiais[index - 1].praiseId != material.praiseId;

            return Column(
              children: [
                if (showDivider)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.amber.shade700,
                  ),
                ListTile(
                  title: Text(material.displayName),
                  subtitle: Text('Tipo: ${material.tipoMaterial}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () async {
                      final participanteId = await ref.read(participanteIdProvider.future);
                      await ref
                          .read(playlistMateriaisRepositoryProvider)
                          .removeMaterial(sala.id, participanteId, material.materialId);
                      ref.invalidate(playlistMateriaisProvider(PlaylistParams(salaId: sala.id)));
                    },
                    tooltip: 'Remover',
                  ),
                  onTap: () async {
                    final participanteId = await ref.read(participanteIdProvider.future);
                    final materialPath = ''; // TODO: obter path do material
                    if (material.tipoMaterial == 'pdf') {
                      if (context.mounted) {
                        context.push(
                          '/reader/pdf/${material.materialId}?path=$materialPath&name=${material.nomeMaterial}&salaId=${sala.id}&participanteId=$participanteId&materialIndex=$index',
                        );
                      }
                    } else if (material.tipoMaterial == 'lyrics') {
                      if (context.mounted) {
                        context.push(
                          '/reader/lyrics/${material.materialId}?path=$materialPath&name=${material.nomeMaterial}&salaId=${sala.id}&participanteId=$participanteId&materialIndex=$index',
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
    );
  }

  Future<void> _showImportListaDialog(BuildContext context, Sala sala) async {
    // Aguarda o carregamento das listas antes de abrir o dialog
    final listasAsync = ref.read(listasProvider);
    List<Lista> listas;
    
    if (listasAsync.hasValue) {
      listas = listasAsync.value ?? [];
    } else {
      // Se ainda não carregou, aguarda o carregamento
      listas = await ref.read(listasProvider.future);
    }
    
    if (listas.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma lista disponível para importar')),
        );
      }
      return;
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Importar lista'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, _) {
                // Usa watch dentro do dialog para garantir dados atualizados
                final listasAsync = ref.watch(listasProvider);
                return listasAsync.when(
                  data: (listasData) {
                    if (listasData.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhuma lista disponível para importar'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: listasData.length,
                      itemBuilder: (context, index) {
                        final lista = listasData[index];
                        return ListTile(
                          leading: const Icon(Icons.list),
                          title: Text(lista.name),
                          subtitle: Text('${lista.praises.length} louvor(es)'),
                          onTap: () async {
                            await ref.read(salaRepositoryProvider).importFromLista(sala.id, lista);
                            ref.invalidate(salaProvider(widget.salaId));
                            ref.invalidate(salasProvider);
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('${lista.praises.length} louvor(es) importado(s)'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Erro ao carregar listas: $e'),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleClearPraises(BuildContext context, Sala sala) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar lista'),
        content: const Text(
          'Remover todos os louvores desta sala? Esta ação também removerá todos os materiais da playlist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    
    if (ok == true && mounted) {
      await ref.read(salaRepositoryProvider).clearPraises(sala.id);
      // Invalida todos os providers relacionados
      ref.invalidate(salaProvider(widget.salaId));
      ref.invalidate(salasProvider);
      ref.invalidate(playlistMateriaisProvider(PlaylistParams(salaId: sala.id)));
      // Força refresh imediato para garantir que o estado está atualizado
      ref.refresh(salaProvider(widget.salaId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista de louvores limpa')),
        );
      }
    }
  }

  Future<void> _handleSaveAsLista(BuildContext context, Sala sala) async {
    // Se a sala foi importada de uma lista, mostra popup com duas opções
    if (sala.importedFromListaId != null) {
      await _showSaveAsListaOptionsDialog(context, sala);
    } else {
      // Se não foi importada, chama o dialog de criar nova lista
      await _showCreateListaFromSalaDialog(context, sala);
    }
  }

  Future<void> _showSaveAsListaOptionsDialog(BuildContext context, Sala sala) async {
    final listaRepo = ref.read(listaRepositoryProvider);
    final listaImportada = listaRepo.getListaById(sala.importedFromListaId!);
    
    if (listaImportada == null) {
      // Se a lista importada não existe mais, trata como nova lista
      await _showCreateListaFromSalaDialog(context, sala);
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salvar como lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta sala foi importada da lista "${listaImportada.name}".',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text('Escolha uma opção:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _showCreateListaFromSalaDialog(context, sala);
            },
            child: const Text('Salvar como nova lista'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final listaId = sala.importedFromListaId!;
                await ref.read(salaRepositoryProvider).overwriteImportedLista(sala.id);
                ref.invalidate(listasProvider);
                ref.invalidate(listaProvider(listaId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lista "${listaImportada.name}" atualizada com sucesso'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao atualizar lista: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Sobrescrever lista importada'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateListaFromSalaDialog(BuildContext context, Sala sala) async {
    final nameController = TextEditingController(text: sala.name);
    final descriptionController = TextEditingController(text: sala.description ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da lista',
                hintText: 'Ex: Louvores de domingo',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await ref.read(salaRepositoryProvider).saveAsLista(
                        salaId: sala.id,
                        name: nameController.text,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                      );
                  ref.invalidate(listasProvider);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lista criada com sucesso')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao criar lista: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}
