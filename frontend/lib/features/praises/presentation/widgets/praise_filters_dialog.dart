import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/praise_providers.dart';

/// Valores aplicados ao fechar o dialog com "Aplicar" ou "Limpar filtros".
class PraiseFiltersDialogResult {
  const PraiseFiltersDialogResult({
    this.tagId,
    this.tonality,
    this.rhythm,
    this.category,
    required this.sortBy,
    required this.searchInLyrics,
  });

  final String? tagId;
  final String? tonality;
  final String? rhythm;
  final String? category;
  final String sortBy;
  final bool searchInLyrics;
}

/// Dialog de filtros avançados: tag, tom, ritmo, categoria, ordenação e buscar na letra.
class PraiseFiltersDialog extends ConsumerStatefulWidget {
  const PraiseFiltersDialog({
    super.key,
    this.initialTagId,
    this.initialTonality,
    this.initialRhythm,
    this.initialCategory,
    this.initialSortBy = 'name',
    this.initialSearchInLyrics = false,
    required this.onApply,
  });

  final String? initialTagId;
  final String? initialTonality;
  final String? initialRhythm;
  final String? initialCategory;
  final String initialSortBy;
  final bool initialSearchInLyrics;
  final void Function(PraiseFiltersDialogResult result) onApply;

  static Future<void> show(
    BuildContext context, {
    String? initialTagId,
    String? initialTonality,
    String? initialRhythm,
    String? initialCategory,
    String initialSortBy = 'name',
    bool initialSearchInLyrics = false,
    required void Function(PraiseFiltersDialogResult result) onApply,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => PraiseFiltersDialog(
        initialTagId: initialTagId,
        initialTonality: initialTonality,
        initialRhythm: initialRhythm,
        initialCategory: initialCategory,
        initialSortBy: initialSortBy,
        initialSearchInLyrics: initialSearchInLyrics,
        onApply: onApply,
      ),
    );
  }

  @override
  ConsumerState<PraiseFiltersDialog> createState() => _PraiseFiltersDialogState();
}

class _PraiseFiltersDialogState extends ConsumerState<PraiseFiltersDialog> {
  late String? _tagId;
  late String _sortBy;
  late bool _searchInLyrics;
  final TextEditingController _tonalityController = TextEditingController();
  final TextEditingController _rhythmController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tagId = widget.initialTagId;
    _tonalityController.text = widget.initialTonality?.trim() ?? '';
    _rhythmController.text = widget.initialRhythm?.trim() ?? '';
    _categoryController.text = widget.initialCategory?.trim() ?? '';
    _sortBy = widget.initialSortBy;
    _searchInLyrics = widget.initialSearchInLyrics;
  }

  @override
  void dispose() {
    _tonalityController.dispose();
    _rhythmController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _apply() {
    final tonality = _tonalityController.text.trim();
    final rhythm = _rhythmController.text.trim();
    final category = _categoryController.text.trim();
    widget.onApply(PraiseFiltersDialogResult(
      tagId: _tagId,
      tonality: tonality.isEmpty ? null : tonality,
      rhythm: rhythm.isEmpty ? null : rhythm,
      category: category.isEmpty ? null : category,
      sortBy: _sortBy,
      searchInLyrics: _searchInLyrics,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  void _clearFilters() {
    widget.onApply(const PraiseFiltersDialogResult(
      tagId: null,
      tonality: null,
      rhythm: null,
      category: null,
      sortBy: 'name',
      searchInLyrics: false,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(praiseTagsProvider);

    return AlertDialog(
      title: const Text('Filtros avançados'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tag
              const Text('Tag', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              tagsAsync.when(
                data: (tags) {
                  final tagIds = tags.map((t) => t.id).toSet();
                  final selectedTagId = _tagId != null && tagIds.contains(_tagId) ? _tagId : null;
                  return DropdownButtonFormField<String?>(
                    initialValue: selectedTagId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('Todos'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                      ...tags.map((t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.name))),
                    ],
                    onChanged: (value) => setState(() => _tagId = value),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
                error: (_, _) => const Text('Erro ao carregar tags', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),

              // Tom (tonality)
              const Text('Tom', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Todos',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: _tonalityController,
              ),
              const SizedBox(height: 16),

              // Ritmo
              const Text('Ritmo', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Todos',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: _rhythmController,
              ),
              const SizedBox(height: 16),

              // Categoria
              const Text('Categoria', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Todos',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: _categoryController,
              ),
              const SizedBox(height: 16),

              // Ordenar por
              const Text('Ordenar por', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Nome')),
                  DropdownMenuItem(value: 'number', child: Text('Número (sem número por último)')),
                ],
                onChanged: (value) => setState(() => _sortBy = value ?? 'name'),
              ),
              const SizedBox(height: 16),

              // Buscar na letra
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _searchInLyrics,
                      onChanged: (value) => setState(() => _searchInLyrics = value ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _searchInLyrics = !_searchInLyrics),
                    child: Text('Buscar na letra', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Limpar filtros'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
