import 'package:flutter/material.dart';
import '../../domain/entities/sala.dart';

/// Card mobile-first para exibir uma sala
class SalaCard extends StatelessWidget {
  final Sala sala;
  final VoidCallback? onTap;

  const SalaCard({
    super.key,
    required this.sala,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sala.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              if (sala.description != null && sala.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    sala.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sala.praises.length} louvor(es)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                    if (sala.isFavorite) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ],
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
