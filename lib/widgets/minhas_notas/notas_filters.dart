import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';

class NotasFilters extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final StatusRetirada? selectedStatus;
  final ValueChanged<StatusRetirada?> onStatusSelected;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final VoidCallback onClearDateRange;

  const NotasFilters({
    super.key,
    required this.onSearch,
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onClearDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final hasDateFilter = startDate != null || endDate != null;

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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(
                    context,
                    initialDate: startDate ?? DateTime.now(),
                    onDateSelected: onStartDateChanged,
                  ),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: Text(_formatDateLabel('Início', startDate)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(
                    context,
                    initialDate: endDate ?? startDate ?? DateTime.now(),
                    onDateSelected: onEndDateChanged,
                  ),
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(_formatDateLabel('Fim', endDate)),
                ),
              ),
            ],
          ),
          if (hasDateFilter) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearDateRange,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpar período'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateLabel(String prefix, DateTime? date) {
    if (date == null) return '$prefix: --/--/----';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$prefix: $d/$m/$y';
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime?> onDateSelected,
  }) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 10);
    final lastDate = DateTime(now.year + 10, 12, 31);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selected != null) {
      onDateSelected(DateUtils.dateOnly(selected));
    }
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
