import 'dart:async';
import 'package:flutter/material.dart';

/// Barra de busca mobile-first para praises.
/// Debounce de 1s na digitação; ao limpar o campo dispara onSearch('') imediatamente.
/// Filtros avançados (tag, tom, ritmo, ordenação, letra) ficam no dialog aberto por [onAdvancedTap].
/// [onSearchOnline] força busca na API (label "Online"); ordem dos botões: Limpar → Online → Filtros.
class PraiseSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final FocusNode? focusNode;
  /// Abre o dialog de filtros avançados. Se null, o botão de avançados não é exibido.
  final VoidCallback? onAdvancedTap;
  /// Força busca online (API). Se não null, exibe botão com ícone global (label "Online").
  final VoidCallback? onSearchOnline;

  const PraiseSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.focusNode,
    this.onAdvancedTap,
    this.onSearchOnline,
  });

  @override
  State<PraiseSearchBar> createState() => _PraiseSearchBarState();
}

class _PraiseSearchBarState extends State<PraiseSearchBar> {
  static const _debounceDuration = Duration(seconds: 1);
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    if (value.isEmpty) {
      widget.onSearch('');
      return;
    }
    _debounceTimer = Timer(_debounceDuration, () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (context, value, child) {
          final hasClear = value.text.isNotEmpty;
          final hasOnline = widget.onSearchOnline != null;
          final hasFilter = widget.onAdvancedTap != null;
          final hasAnySuffix = hasClear || hasOnline || hasFilter;
          Widget? suffixIcon;
          if (hasAnySuffix) {
            suffixIcon = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasClear)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        _debounceTimer?.cancel();
                        widget.onSearch('');
                      },
                      tooltip: 'Limpar',
                    ),
                  ),
                if (hasOnline)
                  IconButton(
                    icon: const Icon(Icons.public),
                    onPressed: widget.onSearchOnline,
                    tooltip: 'Online',
                  ),
                if (hasFilter)
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: widget.onAdvancedTap,
                    tooltip: 'Filtros avançados',
                  ),
              ],
            );
          }
          // Constante para garantir que border-radius seja idêntico em todos os lugares
          const double borderRadius = 12.0;
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                // Sombra dourada brilhante - múltiplas camadas para efeito de luz reluzente
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 32,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: const TextStyle(
                color: Color(0xFF1A1A1A), // Texto preto ao digitar (contraste com fundo bege)
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar louvores...',
                hintStyle: const TextStyle(
                  color: Color(0xFF5A5A5A), // Placeholder cinza escuro para contraste adequado com fundo bege
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                suffixIcon: suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
            ),
          );
        },
      ),
    );
  }
}
