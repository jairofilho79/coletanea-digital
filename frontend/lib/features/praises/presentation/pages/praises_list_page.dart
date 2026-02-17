import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../listas/presentation/providers/lista_providers.dart';
import '../../../salas/presentation/providers/sala_providers.dart';
import '../providers/praise_providers.dart';
import '../widgets/praise_card.dart';
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
  String? _searchQuery;
  String? _selectedTagId;
  int _currentPage = 0;
  final int _pageSize = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
      _currentPage = 0;
    });
  }

  void _onTagFilter(String? tagId) {
    setState(() {
      _selectedTagId = tagId;
      _currentPage = 0;
    });
  }

  void _refresh() {
    setState(() {
      _currentPage = 0;
    });
    // Força refresh do provider
    final params = PraiseListParams(
      skip: 0,
      limit: _pageSize,
      name: _searchQuery,
      tagId: _selectedTagId,
      forceRefresh: true,
    );
    ref.invalidate(praisesProvider(params));
  }

  @override
  Widget build(BuildContext context) {
    final params = PraiseListParams(
      skip: _currentPage * _pageSize,
      limit: _pageSize,
      name: _searchQuery,
      tagId: _selectedTagId,
    );

    // Usa ref.read em vez de ref.watch para evitar rebuilds infinitos
    // e só atualiza quando necessário (via refresh)
    final praisesAsync = ref.watch(praisesProvider(params));

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
        title: Text(
          widget.addToListaId != null
              ? 'Adicionar louvor à lista'
              : widget.addToSala != null
                  ? 'Adicionar louvor à sala'
                  : 'Coletânea Digital',
        ),
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
          // Barra de busca
          PraiseSearchBar(
            controller: _searchController,
            onSearch: _onSearch,
            onTagFilter: _onTagFilter,
            selectedTagId: _selectedTagId,
          ),

          // Lista de praises
          Expanded(
            child: praisesAsync.when(
              data: (praises) {
                if (praises.isEmpty) {
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
                          _searchQuery != null || _selectedTagId != null
                              ? 'Nenhum louvor encontrado'
                              : 'Nenhum louvor disponível',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[400],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final refreshParams = params.copyWith(forceRefresh: true);
                    ref.invalidate(praisesProvider(refreshParams));
                    await ref.read(praisesProvider(refreshParams).future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: praises.length,
                    itemBuilder: (context, index) {
                      final praise = praises[index];
                      return PraiseCard(
                        praise: praise,
                        onTap: () async {
                          if (widget.addToListaId != null) {
                            final repo = ref.read(listaRepositoryProvider);
                            final lista = repo.getListaById(widget.addToListaId!);
                            if (lista != null) {
                              // Verifica se o louvor já está na lista
                              final existingIndex = lista.praises.indexWhere(
                                (item) => item.praise.id == praise.id,
                              );
                              
                              if (existingIndex != -1) {
                                // Louvor já existe na lista
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
                                // Adiciona o louvor à lista
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
