import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_bar_title_with_logo.dart';
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

  void _showCreateListaDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  fontSize: 16,
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
                  fontSize: 16,
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
            onPressed: () => Navigator.pop(context),
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
                await ref.read(listaRepositoryProvider).createLista(
                      name: nameController.text,
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                    );
                ref.invalidate(listasProvider);
                if (context.mounted) {
                  Navigator.pop(context);
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
