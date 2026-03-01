import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_bar_title_with_logo.dart';
import '../../../../core/widgets/app_dialog.dart';
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
        title: AppBarTitleWithLogo.text('Salas'),
      ),
      body: salas.when(
        data: (salasList) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: salasList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CriarSalaRapidaCard(
                  onTap: () => _criarSalaRapida(context, ref),
                );
              }
              final sala = salasList[index - 1];
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

  Future<void> _criarSalaRapida(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yyyy = now.year.toString();
    final HH = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final name = 'Sala rápida $dd/$mm/$yyyy $HH:$min';

    final sala = await ref.read(salaRepositoryProvider).createSala(
          name: name,
          description: null,
        );
    ref.invalidate(salasProvider);
    if (context.mounted) {
      context.push('/salas/${sala.id}');
    }
  }

  void _showCreateSalaDialog(BuildContext context, WidgetRef ref) async {
    final result = await AppDialog.input(
      context: context,
      title: 'Nova Sala',
      fields: [
        const AppDialogField(
          key: 'name',
          hint: 'Ex: Culto de domingo',
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
      await ref.read(salaRepositoryProvider).createSala(
            name: result['name']!,
            description: result['description']!.isEmpty ? null : result['description'],
          );
      ref.invalidate(salasProvider);
    }
  }
}

class _CriarSalaRapidaCard extends StatelessWidget {
  const _CriarSalaRapidaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const strokeWidth = 2.0;
    const radius = 12.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFF6B6B6B),
                strokeWidth: strokeWidth,
                borderRadius: radius,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 28,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Criar Sala Rápida',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
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

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final segment = metric.extractPath(
          distance,
          (distance + dashWidth).clamp(0, metric.length),
        );
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
