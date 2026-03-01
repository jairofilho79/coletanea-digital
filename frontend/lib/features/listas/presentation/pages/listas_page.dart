import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_bar_title_with_logo.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_shell.dart';
import '../providers/lista_providers.dart';
import '../widgets/lista_card.dart';

/// Página de listagem de listas (mobile-first)
class ListasPage extends ConsumerWidget {
  const ListasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listas = ref.watch(listasProvider);

    return Scaffold(
      appBar: AppBar(
        leading: RootDrawerScope.maybeOf(context) != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => RootDrawerScope.of(context).openDrawer(),
                tooltip: 'Menu',
              )
            : null,
        title: AppBarTitleWithLogo.text('Listas'),
      ),
      body: listas.when(
        data: (listasList) {
          if (listasList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma lista criada',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque no botão + para criar uma nova lista',
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
            itemCount: listasList.length,
            itemBuilder: (context, index) {
              final lista = listasList[index];
              return ListaCard(
                lista: lista,
                onTap: () => context.push('/listas/${lista.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Erro ao carregar listas'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Mostrar diálogo para criar nova lista
          _showCreateListaDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateListaDialog(BuildContext context, WidgetRef ref) async {
    final result = await AppDialog.input(
      context: context,
      title: 'Nova Lista',
      fields: [
        const AppDialogField(
          key: 'name',
          hint: 'Ex: Louvores de domingo',
          autofocus: true,
        ),
        const AppDialogField(
          key: 'description',
          hint: 'Lista de glorificação no dia 11/03/2017 para o casamento de...',
          maxLines: 2,
        ),
      ],
    );
    if (result != null && context.mounted) {
      await ref.read(listaRepositoryProvider).createLista(
            name: result['name']!,
            description: result['description']!.isEmpty ? null : result['description'],
          );
      ref.invalidate(listasProvider);
    }
  }
}
