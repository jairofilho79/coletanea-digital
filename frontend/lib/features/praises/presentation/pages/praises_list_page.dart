import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../../core/widgets/app_bar_title_with_logo.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../listas/presentation/providers/lista_providers.dart';
import '../../../salas/presentation/providers/sala_providers.dart';
import '../providers/praise_providers.dart';
import '../widgets/praise_card.dart';
import '../widgets/praise_filters_dialog.dart';
import '../widgets/praise_search_bar.dart';

/// Página de listagem de praises (mobile-first).
/// Se [addToListaId] for informado, ao tocar num louvor ele é adicionado a essa lista e a tela fecha.
/// Se [addToSala] for informado, ao tocar num louvor ele é adicionado a essa sala e a tela fecha.
class PraisesListPage extends ConsumerStatefulWidget {
  final String? addToListaId;
  final String? addToSala;

  const PraisesListPage({super.key, this.addToListaId, this.addToSala});

  @override
  ConsumerState<PraisesListPage> createState() => _PraisesListPageState();
}

class _PraisesListPageState extends ConsumerState<PraisesListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _searchQuery;
  String? _selectedTagId;
  String? _selectedTonality;
  String? _selectedRhythm;
  String? _selectedCategory;
  bool _searchInLyrics = false;
  /// 'name' ou 'number' (por número = sem número por último)
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
  }

  void _openFiltersDialog() {
    PraiseFiltersDialog.show(
      context,
      initialTagId: _selectedTagId,
      initialTonality: _selectedTonality,
      initialRhythm: _selectedRhythm,
      initialCategory: _selectedCategory,
      initialSortBy: _sortBy,
      initialSearchInLyrics: _searchInLyrics,
      onApply: (result) {
        setState(() {
          _selectedTagId = result.tagId;
          _selectedTonality = result.tonality;
          _selectedRhythm = result.rhythm;
          _selectedCategory = result.category;
          _sortBy = result.sortBy;
          _searchInLyrics = result.searchInLyrics;
        });
      },
    );
  }

  bool get _hasActiveFilters =>
      _searchQuery != null ||
      _selectedTagId != null ||
      _selectedTonality != null ||
      _selectedRhythm != null ||
      _selectedCategory != null;

  void _refresh() {
    final youtubeId = _searchQuery != null ? extractYoutubeVideoId(_searchQuery!) : null;
    // Se for link/ID do YouTube, filtrar só por youtube_url; senão filtrar por name (evita buscar nome contendo URL)
    final filters = PraiseListFilters(
      name: youtubeId != null ? null : _searchQuery,
      tagId: _selectedTagId,
      tonality: _selectedTonality,
      rhythm: _selectedRhythm,
      category: _selectedCategory,
      youtubeUrl: youtubeId != null ? _searchQuery : null,
      searchInLyrics: _searchInLyrics,
      sortBy: _sortBy,
      noNumber: _sortBy == 'number' ? 'last' : 'last',
    );
    ref.read(praisesInfiniteProvider(filters).notifier).loadInitial(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final youtubeId = _searchQuery != null ? extractYoutubeVideoId(_searchQuery!) : null;
    // Se for link/ID do YouTube, filtrar só por youtube_url; senão filtrar por name
    final filters = PraiseListFilters(
      name: youtubeId != null ? null : _searchQuery,
      tagId: _selectedTagId,
      tonality: _selectedTonality,
      rhythm: _selectedRhythm,
      category: _selectedCategory,
      youtubeUrl: youtubeId != null ? _searchQuery : null,
      searchInLyrics: _searchInLyrics,
      sortBy: _sortBy,
      noNumber: _sortBy == 'number' ? 'last' : 'last',
    );
    final infiniteState = ref.watch(praisesInfiniteProvider(filters));
    final notifier = ref.read(praisesInfiniteProvider(filters).notifier);

    return Scaffold(
      appBar: AppBar(
        leading: (widget.addToListaId != null || widget.addToSala != null)
            ? const BackButtonWithDrawerOnLongPress()
            : (RootDrawerScope.maybeOf(context) != null
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => RootDrawerScope.of(context).openDrawer(),
                    tooltip: 'Menu',
                  )
                : null),
        title: widget.addToListaId != null
            ? AppBarTitleWithLogo.text('Adicionar louvor à lista')
            : widget.addToSala != null
                ? AppBarTitleWithLogo.text('Adicionar louvor à sala')
                : const AppLogo(),
        actions: [
          if (widget.addToListaId == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Atualizar',
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.addToListaId != null || widget.addToSala != null)
            Material(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.addToListaId != null
                            ? 'Toque em um louvor para adicionar à lista'
                            : 'Toque em um louvor para adicionar à sala',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Barra de busca (filtros avançados no botão à direita)
          PraiseSearchBar(
            controller: _searchController,
            onSearch: _onSearch,
            focusNode: _searchFocusNode,
            onAdvancedTap: _openFiltersDialog,
            onSearchOnline: _refresh,
          ),

          // Lista de praises
          Expanded(
            child: infiniteState.items.when(
              data: (praises) {
                if (praises.isEmpty) {
                  final message = _hasActiveFilters
                      ? 'Nenhum louvor encontrado'
                      : 'Nenhum louvor disponível';
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[400],
                              ),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.public, size: 20),
                            label: const Text('Buscar online'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final itemCount = praises.length + 1;
                return RefreshIndicator(
                  onRefresh: () => notifier.loadInitial(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index == praises.length) {
                        if (infiniteState.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        if (infiniteState.hasMore) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(praisesInfiniteProvider(filters).notifier)
                                    .loadMore(),
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                label: const Text('Carregar mais'),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final praise = praises[index];
                      return PraiseCard(
                        praise: praise,
                        onTap: () async {
                          if (widget.addToListaId != null) {
                            final repo = ref.read(listaRepositoryProvider);
                            final lista = repo.getListaById(widget.addToListaId!);
                            if (lista != null) {
                              final existingIndex = lista.praises.indexWhere(
                                (item) => item.praise.id == praise.id,
                              );
                              if (existingIndex != -1) {
                                final position = existingIndex + 1;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'O louvor "${praise.displayName}" já se encontra na lista, na posição $position',
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } else {
                                final newLista = lista.addPraise(praise);
                                await repo.updateLista(newLista);
                                ref.invalidate(listaProvider(widget.addToListaId!));
                                ref.invalidate(listasProvider);
                                if (context.mounted) {
                                  context.pop();
                                }
                              }
                            }
                          } else if (widget.addToSala != null) {
                            final repo = ref.read(salaRepositoryProvider);
                            await repo.addPraise(widget.addToSala!, praise);
                            ref.invalidate(salaProvider(widget.addToSala!));
                            ref.invalidate(salasProvider);
                            if (context.mounted) {
                              context.pop();
                            }
                          } else {
                            context.push('/praises/${praise.id}');
                          }
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar louvores',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
