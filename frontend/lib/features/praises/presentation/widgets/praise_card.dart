import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/praise.dart';
import '../providers/translation_providers.dart';

/// Card mobile-first para exibir um praise
class PraiseCard extends ConsumerWidget {
  final Praise praise;
  final VoidCallback? onTap;

  const PraiseCard({
    super.key,
    required this.praise,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome e número
              Row(
                children: [
                  Expanded(
                    child: Text(
                      praise.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (praise.inReview)
                    Container(
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
                ],
              ),

              // Informações adicionais
              if (praise.author != null ||
                  praise.rhythm != null ||
                  praise.tonality != null ||
                  praise.category != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (praise.author != null)
                        _InfoChip(
                          icon: Icons.person,
                          label: praise.author!,
                        ),
                      if (praise.rhythm != null)
                        _InfoChip(
                          icon: Icons.music_note,
                          label: praise.rhythm!,
                        ),
                      if (praise.tonality != null)
                        _InfoChip(
                          icon: Icons.tune,
                          label: praise.tonality!,
                        ),
                      if (praise.category != null)
                        _InfoChip(
                          icon: Icons.category,
                          label: praise.category!,
                        ),
                    ],
                  ),
                ),

              // Tags
              if (praise.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: praise.tags.take(3).map((tag) {
                      // Garante que as traduções foram carregadas
                      ref.watch(translationsLoadedProvider);
                      final translationService = ref.watch(translationServiceProvider);
                      final translatedName = translationService.getPraiseTagName(tag.id, tag.name);
                      return Builder(
                        builder: (context) => Chip(
                        label: Text(
                          translatedName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodyMedium?.color, // Mesmo cinza escuro das propriedades
                            fontWeight: FontWeight.w600, // Mais grosso
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Theme.of(context).cardColor,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2, // Borda mais grossa
                        ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Materiais disponíveis
              if (praise.materials.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${praise.materials.length} ${praise.materials.length < 2 ? 'material' : 'materiais'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600, // Mais grosso
                ),
          ),
        ),
      ],
    );
  }
}
