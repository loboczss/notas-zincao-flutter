import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';

class NotasFilters extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final StatusRetirada? selectedStatus;
  final ValueChanged<StatusRetirada?> onStatusSelected;

  const NotasFilters({
    super.key,
    required this.onSearch,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              onChanged: onSearch,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Pesquisar cliente ou nota...',
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
                prefixIcon: Icon(Icons.search, color: cs.onSurface.withValues(alpha: 0.55)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(context, null, 'Todos'),
                ...StatusRetirada.values.map((s) => _buildStatusChip(context, s, s.label)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, StatusRetirada? status, String label) {
    final isSelected = selectedStatus == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.75),
            fontSize: 12,
          ),
        ),
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        selectedColor: status?.color.withValues(alpha: 0.5) ?? cs.primary,
        checkmarkColor: Colors.white,
        onSelected: (selected) {
          onStatusSelected(selected ? status : null);
        },
      ),
    );
  }
}
