import 'dart:async';
import 'package:flutter/material.dart';

/// Barra de busca mobile-first para praises.
/// Debounce de 1s na digitação; ao limpar o campo dispara onSearch('') imediatamente.
/// Filtros avançados (tag, tom, ritmo, ordenação, letra) ficam no dialog aberto por [onAdvancedTap].
class PraiseSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final FocusNode? focusNode;
  /// Abre o dialog de filtros avançados. Se null, o botão de avançados não é exibido.
  final VoidCallback? onAdvancedTap;

  const PraiseSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.focusNode,
    this.onAdvancedTap,
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
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, child) {
              Widget? suffixIcon;
              if (value.text.isNotEmpty && widget.onAdvancedTap != null) {
                suffixIcon = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        _debounceTimer?.cancel();
                        widget.onSearch('');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: widget.onAdvancedTap,
                      tooltip: 'Filtros avançados',
                    ),
                  ],
                );
              } else if (value.text.isEmpty && widget.onAdvancedTap != null) {
                suffixIcon = IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: widget.onAdvancedTap,
                  tooltip: 'Filtros avançados',
                );
              } else if (value.text.isNotEmpty) {
                suffixIcon = IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    _debounceTimer?.cancel();
                    widget.onSearch('');
                  },
                );
              }
              return TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar louvores...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: suffixIcon,
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
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
              );
            },
          ),
        ],
      ),
    );
  }
}
