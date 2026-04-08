import 'package:flutter/material.dart';

/// Barra de pesquisa para filtrar produtos por ID ou descrição.
class ProdutoSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ProdutoSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Pesquisar por ID ou descrição...',
            hintStyle: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: cs.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: cs.onSurface.withValues(alpha: 0.5),
                      size: 18,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        );
      },
    );
  }
}
