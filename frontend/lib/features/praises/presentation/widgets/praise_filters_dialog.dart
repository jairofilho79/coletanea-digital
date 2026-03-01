import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../providers/praise_providers.dart';
import '../providers/translation_providers.dart';

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

  static const _labelStyle = TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const _inputDecoration = InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(praiseTagsProvider);

    return AppDialog(
      title: 'Filtros avançados',
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tag', style: _labelStyle),
              const SizedBox(height: 4),
              tagsAsync.when(
                data: (tags) {
                  ref.watch(translationsLoadedProvider);
                  final translationService = ref.watch(translationServiceProvider);
                  final tagIds = tags.map((t) => t.id).toSet();
                  final selectedTagId = _tagId != null && tagIds.contains(_tagId) ? _tagId : null;
                  return DropdownButtonFormField<String?>(
                    initialValue: selectedTagId,
                    decoration: _inputDecoration,
                    dropdownColor: AppTheme.cardColor,
                    style: const TextStyle(color: AppTheme.textDark),
                    hint: const Text('Todos'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                      ...tags.map((t) {
                        final translatedName = translationService.getPraiseTagName(t.id, t.name);
                        return DropdownMenuItem<String?>(
                          value: t.id,
                          child: Text(translatedName),
                        );
                      }),
                    ],
                    onChanged: (value) => setState(() => _tagId = value),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                error: (_, __) => const Text(
                  'Erro ao carregar tags',
                  style: TextStyle(color: Color(0xFFFF6B6B)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tom', style: _labelStyle),
              const SizedBox(height: 4),
              TextField(
                controller: _tonalityController,
                style: const TextStyle(color: AppTheme.textDark),
                decoration: _inputDecoration.copyWith(hintText: 'Todos'),
              ),
              const SizedBox(height: 16),
              const Text('Ritmo', style: _labelStyle),
              const SizedBox(height: 4),
              TextField(
                controller: _rhythmController,
                style: const TextStyle(color: AppTheme.textDark),
                decoration: _inputDecoration.copyWith(hintText: 'Todos'),
              ),
              const SizedBox(height: 16),
              const Text('Categoria', style: _labelStyle),
              const SizedBox(height: 4),
              TextField(
                controller: _categoryController,
                style: const TextStyle(color: AppTheme.textDark),
                decoration: _inputDecoration.copyWith(hintText: 'Todos'),
              ),
              const SizedBox(height: 16),
              const Text('Ordenar por', style: _labelStyle),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: _inputDecoration,
                dropdownColor: AppTheme.cardColor,
                style: const TextStyle(color: AppTheme.textDark),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Nome')),
                  DropdownMenuItem(
                    value: 'number',
                    child: Text('Número (sem número por último)'),
                  ),
                ],
                onChanged: (value) => setState(() => _sortBy = value ?? 'name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _searchInLyrics,
                      onChanged: (value) => setState(() => _searchInLyrics = value ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: AppTheme.primaryColor,
                      checkColor: AppTheme.backgroundColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _searchInLyrics = !_searchInLyrics),
                    child: const Text(
                      'Buscar na letra',
                      style: TextStyle(color: Colors.white),
                    ),
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
          child: const Text(
            'Limpar filtros',
            style: TextStyle(color: AppTheme.primaryColor),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppTheme.primaryColor),
          ),
        ),
        ElevatedButton(
          onPressed: _apply,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
