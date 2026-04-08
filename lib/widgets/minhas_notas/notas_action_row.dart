import 'package:flutter/material.dart';

class NotasActionRow extends StatelessWidget {
  final bool isTableView;
  final VoidCallback onToggleView;
  final VoidCallback onRefresh;
  final bool isAdmin;
  final VoidCallback? onExport;

  const NotasActionRow({
    super.key,
    required this.isTableView,
    required this.onToggleView,
    required this.onRefresh,
    this.isAdmin = false,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Listagem',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: onSurface.withValues(alpha: 0.75),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isTableView ? Icons.grid_view : Icons.table_chart,
              color: onSurface.withValues(alpha: 0.6),
            ),
            tooltip: isTableView ? 'Ver em cards' : 'Ver como tabela',
            onPressed: onToggleView,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: onSurface.withValues(alpha: 0.6)),
            tooltip: 'Atualizar',
            onPressed: onRefresh,
          ),
          if (isAdmin)
            IconButton(
              icon: Icon(
                Icons.download_outlined,
                color: onSurface.withValues(alpha: 0.6),
              ),
              tooltip: 'Exportar relatório',
              onPressed: onExport,
            ),
        ],
      ),
    );
  }
}
