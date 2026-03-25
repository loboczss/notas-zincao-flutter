import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/status_badge.dart';

class NotasCardView extends StatelessWidget {
  final List<NotaRetirada> notas;
  final ValueChanged<NotaRetirada> onNotaSelected;

  const NotasCardView({
    super.key,
    required this.notas,
    required this.onNotaSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notas.length,
      itemBuilder: (context, index) {
        return _CardItem(
          nota: notas[index],
          onTap: () => onNotaSelected(notas[index]),
        );
      },
    );
  }
}

class NotasTableView extends StatelessWidget {
  final List<NotaRetirada> notas;
  final ValueChanged<NotaRetirada> onNotaSelected;

  const NotasTableView({
    super.key,
    required this.notas,
    required this.onNotaSelected,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
          ),
          columns: const [
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Nota')),
            DataColumn(label: Text('Série')),
            DataColumn(label: Text('Data Compra')),
            DataColumn(label: Text('Valor Total')),
            DataColumn(label: Text('Status')),
          ],
          rows: notas.map((nota) {
            return DataRow(
              onSelectChanged: (_) => onNotaSelected(nota),
              cells: [
                DataCell(Text(
                  nota.nomeCliente,
                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
                )),
                DataCell(Text(nota.numeroNota)),
                DataCell(Text(nota.serieNota)),
                DataCell(Text(dateFormat.format(nota.dataCompra))),
                DataCell(Text(nota.valorTotal != null ? currencyFormat.format(nota.valorTotal) : '-')),
                DataCell(StatusBadge(status: nota.statusRetirada)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final NotaRetirada nota;
  final VoidCallback onTap;

  const _CardItem({
    required this.nota,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: cs.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Text(
                      nota.nomeCliente,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  StatusBadge(status: nota.statusRetirada),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.description_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    'Nota: ${nota.numeroNota} (Série ${nota.serieNota})',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    'Compra: ${dateFormat.format(nota.dataCompra)}',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
                  ),
                  if (nota.dataPrevistaRetirada != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.local_shipping_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      'Retirada: ${dateFormat.format(nota.dataPrevistaRetirada!)}',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ],
                ],
              ),
              Divider(height: 24, color: cs.onSurface.withValues(alpha: 0.1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${nota.produtos.length} produtos',
                    style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurface),
                  ),
                  if (nota.valorTotal != null)
                    Text(
                      currencyFormat.format(nota.valorTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
