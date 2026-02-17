import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../providers/sala_providers.dart';
import '../widgets/sala_card.dart';

/// Página de listagem de salas (mobile-first)
class SalasPage extends ConsumerWidget {
  const SalasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salas = ref.watch(salasProvider);

    return Scaffold(
      appBar: AppBar(
        leading: RootDrawerScope.maybeOf(context) != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => RootDrawerScope.of(context).openDrawer(),
                tooltip: 'Menu',
              )
            : null,
        title: const Text('Salas'),
      ),
      body: salas.when(
        data: (salasList) {
          if (salasList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.meeting_room,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma sala criada',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque no botão + para criar uma nova sala',
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
            itemCount: salasList.length,
            itemBuilder: (context, index) {
              final sala = salasList[index];
              return SalaCard(
                sala: sala,
                onTap: () => context.push('/salas/${sala.id}'),
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
              Text('Erro ao carregar salas'),
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
          _showCreateSalaDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateSalaDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Sala'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da sala',
                hintText: 'Ex: Culto de domingo',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref.read(salaRepositoryProvider).createSala(
                      name: nameController.text,
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                    );
                ref.invalidate(salasProvider);
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
