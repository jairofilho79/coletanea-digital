import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../listas/presentation/providers/lista_providers.dart';
import '../providers/praise_providers.dart';
import '../../domain/entities/praise.dart';

/// Página de detalhes de um praise (mobile-first)
class PraiseDetailPage extends ConsumerWidget {
  final String praiseId;

  const PraiseDetailPage({
    super.key,
    required this.praiseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final praiseAsync = ref.watch(praiseProvider(praiseId));

    return Scaffold(
      appBar: AppBar(
        leading: const BackButtonWithDrawerOnLongPress(),
        title: const Text('Detalhes do Louvor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Adicionar à lista',
            onPressed: () async {
              final praise = await ref.read(praiseProvider(praiseId).future);
              if (context.mounted) {
                _showAddToListaDialog(context, ref, praise);
              }
            },
          ),
        ],
      ),
      body: praiseAsync.when(
        data: (praise) => _buildContent(context, praise),
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
                'Erro ao carregar louvor',
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
                onPressed: () => context.pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showAddToListaDialog(BuildContext context, WidgetRef ref, Praise praise) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adicionar à lista'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (ctx, ref, _) {
              final listasAsync = ref.watch(listasProvider);
              return listasAsync.when(
                data: (listas) {
                  if (listas.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Nenhuma lista criada. Crie uma lista em "Listas".'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: listas.length,
                    itemBuilder: (context, index) {
                      final lista = listas[index];
                      final alreadyInList = lista.praises.any((e) => e.praise.id == praise.id);
                      return ListTile(
                        leading: const Icon(Icons.list),
                        title: Text(lista.name),
                        subtitle: Text(
                          alreadyInList ? 'Já está nesta lista' : '${lista.praises.length} louvor(es)',
                        ),
                        trailing: alreadyInList ? const Icon(Icons.check, color: Colors.green) : null,
                        onTap: alreadyInList
                            ? null
                            : () async {
                                final repo = ref.read(listaRepositoryProvider);
                                final current = repo.getListaById(lista.id);
                                if (current != null) {
                                  final updated = current.addPraise(praise);
                                  await repo.updateLista(updated);
                                  ref.invalidate(listaProvider(lista.id));
                                  ref.invalidate(listasProvider);
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Adicionado à lista "${lista.name}"')),
                                    );
                                  }
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Praise praise) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com nome e número
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    praise.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (praise.inReview)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Em revisão',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Informações adicionais
          if (praise.author != null ||
              praise.rhythm != null ||
              praise.tonality != null ||
              praise.category != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (praise.author != null)
                      _InfoRow(
                        icon: Icons.person,
                        label: 'Autor',
                        value: praise.author!,
                      ),
                    if (praise.rhythm != null)
                      _InfoRow(
                        icon: Icons.music_note,
                        label: 'Ritmo',
                        value: praise.rhythm!,
                      ),
                    if (praise.tonality != null)
                      _InfoRow(
                        icon: Icons.tune,
                        label: 'Tom',
                        value: praise.tonality!,
                      ),
                    if (praise.category != null)
                      _InfoRow(
                        icon: Icons.category,
                        label: 'Categoria',
                        value: praise.category!,
                      ),
                  ],
                ),
              ),
            ),

          // Tags
          if (praise.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: praise.tags.map((tag) {
                        return Chip(
                          label: Text(tag.name),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Materiais
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Materiais (${praise.materials.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (praise.materials.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          'Nenhum material disponível',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[400],
                              ),
                        ),
                      ),
                    )
                  else
                    ...praise.materials.map((material) {
                      return _MaterialTile(
                        material: material,
                        praiseName: praise.name,
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final PraiseMaterial material;
  final String praiseName;

  const _MaterialTile({
    required this.material,
    required this.praiseName,
  });

  IconData _getMaterialIcon() {
    final materialTypeName = material.materialType?.name.toLowerCase() ?? '';
    if (materialTypeName.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (materialTypeName.contains('audio')) {
      return Icons.audiotrack;
    } else if (materialTypeName.contains('text') ||
        materialTypeName.contains('lyric')) {
      return Icons.text_snippet;
    }
    return Icons.description;
  }

  Color _getMaterialColor(BuildContext context) {
    final materialTypeName = material.materialType?.name.toLowerCase() ?? '';
    if (materialTypeName.contains('pdf')) {
      return Colors.red;
    } else if (materialTypeName.contains('audio')) {
      return Colors.blue;
    } else if (materialTypeName.contains('text') ||
        materialTypeName.contains('lyric')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final materialKindName = material.materialKind?.name ?? 'Material';
    final materialTypeName = material.materialType?.name ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getMaterialColor(context).withValues(alpha: 0.1),
        child: Icon(
          _getMaterialIcon(),
          color: _getMaterialColor(context),
        ),
      ),
      title: Text(materialKindName),
      subtitle: Text(materialTypeName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Determinar a rota baseada no tipo de material
        final materialTypeName = material.materialType?.name.toLowerCase() ?? '';
        final path = material.path;
        
        // Verifica se o path parece ser texto (lyrics) em vez de arquivo
        // Textos geralmente são longos, não têm extensão de arquivo, e não contêm "/"
        final isLikelyText = path.length > 100 && 
                            !path.contains('.pdf') && 
                            !path.contains('.mp3') && 
                            !path.contains('/') &&
                            !path.contains('\\');
        
        String route;
        Map<String, String> queryParams = {
          'path': material.path,
          'name': '$praiseName - $materialKindName',
        };
        
        // Se parece ser texto, sempre usa leitor de letras
        if (isLikelyText || materialTypeName.contains('text') || materialTypeName.contains('lyric')) {
          route = '/reader/lyrics/${material.id}';
        } else if (materialTypeName.contains('pdf')) {
          // Só abre como PDF se realmente parece ser um arquivo PDF
          final extension = path.split('.').last.toLowerCase();
          if (extension == 'pdf' || path.contains('.pdf')) {
            route = '/reader/pdf/${material.id}';
          } else {
            // Se o tipo é PDF mas o path não tem extensão .pdf, pode ser texto
            route = '/reader/lyrics/${material.id}';
          }
        } else if (materialTypeName.contains('audio') ||
            ['mp3', 'wav', 'ogg', 'm4a'].contains(path.split('.').last.toLowerCase())) {
          route = '/reader/audio/${material.id}';
        } else {
          route = '/reader/lyrics/${material.id}';
        }

        // Incluir praiseName e materialKindName para o drawer do player de áudio
        if (route.contains('/reader/audio/')) {
          queryParams['praiseName'] = praiseName;
          queryParams['materialKindName'] = materialKindName;
        }
        final uri = Uri(
          path: route,
          queryParameters: queryParams,
        );
        context.push(uri.toString());
      },
    );
  }
}
