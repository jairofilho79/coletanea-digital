import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_bar_title_with_logo.dart';
import '../../../../core/widgets/app_shell.dart';
import '../providers/sala_providers.dart';
import '../../../listas/presentation/providers/lista_providers.dart';
import '../../../listas/presentation/widgets/reorderable_praise_list.dart';
import '../../../listas/domain/entities/lista.dart';
import '../../../praises/presentation/providers/translation_providers.dart';
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
              title: AppBarTitleWithLogo.text('Sala'),
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
            title: AppBarTitleWithLogo.text('Detalhes da Sala'),
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
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: const Color(0xFFD4AF37),
                  dividerTheme: const DividerThemeData(
                    color: Color(0xFFD4AF37),
                    thickness: 1,
                    space: 0,
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  color: const Color(0xFF4B2D2B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFFD4AF37),
                      width: 2,
                    ),
                  ),
                  onSelected: (v) {
                    if (v == 'delete') _delete(sala);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        'Excluir sala',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                  ],
                ),
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
        appBar: AppBar(title: AppBarTitleWithLogo.text('Sala')),
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
                style: const TextStyle(
                  color: Color(0xFF1A1A1A), // Texto preto ao digitar
                ),
                decoration: InputDecoration(
                  hintText: 'Ex: Culto de domingo',
                  hintStyle: const TextStyle(
                    color: Color(0xFF5A5A5A), // Placeholder cinza escuro
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5E6D3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD4AF37),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD4AF37),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFF4D03F),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => _nameDirty = true,
                onSubmitted: (_) => _saveName(sala),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A), // Texto preto ao digitar
                ),
                decoration: InputDecoration(
                  hintText: 'Lista de glorificação no dia 12/03/2017 para o casamento de...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF5A5A5A), // Placeholder cinza escuro
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5E6D3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD4AF37),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD4AF37),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFF4D03F),
                      width: 2,
                    ),
                  ),
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
            emptyInstruction: 'Toque no botão abaixo para adicionar louvores.',
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

  static IconData _getTipoMaterialIcon(String tipoMaterial) {
    switch (tipoMaterial.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'audio':
        return Icons.audiotrack;
      case 'lyrics':
      default:
        return Icons.text_snippet;
    }
  }

  static String _getTipoMaterialLabel(String tipoMaterial) {
    switch (tipoMaterial.toLowerCase()) {
      case 'pdf':
        return 'PDF';
      case 'audio':
        return 'Áudio';
      case 'lyrics':
      default:
        return 'Letra';
    }
  }

  Widget _buildPlaylistTab(BuildContext context, Sala sala) {
    final playlistAsync = ref.watch(playlistMateriaisProvider(PlaylistParams(salaId: sala.id)));
    // Garante que as traduções foram carregadas (para materiais antigos ou mudanças de idioma)
    ref.watch(translationsLoadedProvider);
    final translationService = ref.watch(translationServiceProvider);

    return playlistAsync.when(
      data: (materiais) {
        if (materiais.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.playlist_play,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum material na playlist.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adicione materiais clicando neles na tela de detalhes do louvor.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                      ),
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
            final showDivider = index == 0 ||
                materiais[index - 1].praiseId != material.praiseId;

            return Column(
              children: [
                if (showDivider)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            height: 1,
                            thickness: 2,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            material.nomePraise,
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            height: 1,
                            thickness: 2,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                Builder(
                  builder: (context) {
                    final materialName = material.materialKindId.isNotEmpty
                        ? translationService.getMaterialKindName(
                            material.materialKindId,
                            material.nomeMaterial,
                          )
                        : material.nomeMaterial;
                    final tipoIcon = _getTipoMaterialIcon(material.tipoMaterial);
                    final tipoLabel = _getTipoMaterialLabel(material.tipoMaterial);

                    return Container(
                      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
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
                          onTap: () async {
                            final participanteId = await ref.read(participanteIdProvider.future);
                            final materialPath = '';
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
                            } else if (material.tipoMaterial == 'audio') {
                              if (context.mounted) {
                                context.push(
                                  '/reader/audio/${material.materialId}?path=$materialPath&name=${material.nomeMaterial}&salaId=${sala.id}&participanteId=$participanteId&materialIndex=$index',
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        materialName,
                                        style: const TextStyle(
                                          color: Color(0xFF5A2A2A),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            tipoIcon,
                                            size: 18,
                                            color: const Color(0xFFD4AF37),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            tipoLabel,
                                            style: const TextStyle(
                                              color: Color(0xFF5A5A5A),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: const Color(0xFFD4AF37),
                                  onPressed: () async {
                                    final participanteId = await ref.read(participanteIdProvider.future);
                                    await ref
                                        .read(playlistMateriaisRepositoryProvider)
                                        .removeMaterial(sala.id, participanteId, material.materialId);
                                    ref.invalidate(playlistMateriaisProvider(PlaylistParams(salaId: sala.id)));
                                  },
                                  tooltip: 'Remover',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
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
          backgroundColor: const Color(0xFF4B2D2B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFFD4AF37),
              width: 2,
            ),
          ),
          title: const Text(
            'Importar lista',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontFamily: 'EB Garamond',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, _) {
                final listasAsync = ref.watch(listasProvider);
                return listasAsync.when(
                  data: (listasData) {
                    if (listasData.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Nenhuma lista disponível para importar',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: listasData.length,
                      itemBuilder: (context, index) {
                        final lista = listasData[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
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
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.list,
                                      color: const Color(0xFFD4AF37),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            lista.name,
                                            style: const TextStyle(
                                              color: Color(0xFF5A2A2A),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${lista.praises.length} louvor(es)',
                                            style: const TextStyle(
                                              color: Color(0xFF5A5A5A),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
                    child: Text(
                      'Erro ao carregar listas: $e',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Fechar',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
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
        backgroundColor: const Color(0xFF4B2D2B), // Fundo vermelho (marrom avermelhado escuro)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFFD4AF37), // Borda dourada
            width: 2,
          ),
        ),
        title: const Text(
          'Nova Lista',
          style: TextStyle(
            color: Color(0xFFD4AF37), // Texto dourado no título
            fontFamily: 'EB Garamond',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(
                color: Color(0xFF1A1A1A), // Texto preto ao digitar
              ),
              decoration: InputDecoration(
                hintText: 'Ex: Louvores de domingo',
                hintStyle: const TextStyle(
                  color: Color(0xFF5A5A5A), // Placeholder cinza escuro
                ),
                filled: true,
                fillColor: const Color(0xFFF5E6D3), // Fundo bege do input
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37), // Borda dourada
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37), // Borda dourada
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF4D03F), // Borda dourada clara quando focado
                    width: 2,
                  ),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: const TextStyle(
                color: Color(0xFF1A1A1A), // Texto preto ao digitar
              ),
              decoration: InputDecoration(
                hintText: 'Lista de glorificação no dia 11/03/2017 para o casamento de...',
                hintStyle: const TextStyle(
                  color: Color(0xFF5A5A5A), // Placeholder cinza escuro
                ),
                filled: true,
                fillColor: const Color(0xFFF5E6D3), // Fundo bege do input
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37), // Borda dourada
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37), // Borda dourada
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF4D03F), // Borda dourada clara quando focado
                    width: 2,
                  ),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFFD4AF37), // Texto dourado
              ),
            ),
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
