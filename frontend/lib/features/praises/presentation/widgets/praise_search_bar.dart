import 'package:flutter/material.dart';

/// Barra de busca mobile-first para praises
class PraiseSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String?) onTagFilter;
  final String? selectedTagId;

  const PraiseSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onTagFilter,
    this.selectedTagId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Campo de busca
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Buscar louvores...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: onSearch,
            textInputAction: TextInputAction.search,
          ),

          // Filtros (tags) - TODO: Implementar quando tiver provider de tags
          // Por enquanto, apenas placeholder
          if (selectedTagId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Chip(
                    label: const Text('Tag selecionada'),
                    onDeleted: () => onTagFilter(null),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
