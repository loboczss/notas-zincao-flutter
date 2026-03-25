import 'package:flutter/material.dart';

class NotasEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const NotasEmptyState({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma nota encontrada.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Recarregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
              foregroundColor: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
