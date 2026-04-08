import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/services/relatorio_export_service.dart';
import 'package:notas_zincao_flutter/widgets/shared/app_error_feedback.dart';

class ExportarRelatorioSheet extends StatefulWidget {
  final List<NotaRetirada> notas;
  final DateTime? startDate;
  final DateTime? endDate;
  final StatusRetirada? status;

  const ExportarRelatorioSheet({
    super.key,
    required this.notas,
    this.startDate,
    this.endDate,
    this.status,
  });

  @override
  State<ExportarRelatorioSheet> createState() => _ExportarRelatorioSheetState();
}

class _ExportarRelatorioSheetState extends State<ExportarRelatorioSheet> {
  bool _isExporting = false;
  FormatoExportacao _formato = FormatoExportacao.csv;
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  String get _periodoLabel {
    final start = widget.startDate != null ? _dateFmt.format(widget.startDate!) : null;
    final end = widget.endDate != null ? _dateFmt.format(widget.endDate!) : null;

    if (start != null && end != null) return 'de $start a $end';
    if (start != null) return 'a partir de $start';
    if (end != null) return 'até $end';
    return 'todo o período';
  }

  String get _statusLabel => widget.status?.label ?? 'todos os status';

  Future<void> _exportar() async {
    setState(() => _isExporting = true);
    try {
      await RelatorioExportService().exportarRetiradas(widget.notas, formato: _formato);
      if (mounted) Navigator.of(context).pop();
    } catch (e, s) {
      debugPrint('Erro ao exportar relatório: $e');
      debugPrint('Stack: $s');
      if (!mounted) return;
      AppErrorFeedback.show(
        context,
        message: e.toString(),
        fallbackMessage: 'Não foi possível exportar o relatório.',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNotas = widget.notas.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.download_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Exportar Relatório',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Notas', value: '${widget.notas.length}'),
          _InfoRow(label: 'Período', value: _periodoLabel),
          _InfoRow(label: 'Status', value: _statusLabel),
          const SizedBox(height: 12),
          Text(
            'Formato',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<FormatoExportacao>(
            segments: const [
              ButtonSegment(
                value: FormatoExportacao.csv,
                label: Text('CSV'),
                icon: Icon(Icons.table_chart_outlined),
              ),
              ButtonSegment(
                value: FormatoExportacao.pdf,
                label: Text('PDF'),
                icon: Icon(Icons.picture_as_pdf_outlined),
              ),
            ],
            selected: {_formato},
            onSelectionChanged: (s) => setState(() => _formato = s.first),
          ),
          const SizedBox(height: 6),
          Text(
            _formato == FormatoExportacao.csv
                ? 'Compatível com Excel e Google Sheets'
                : 'Documento formatado para impressão ou compartilhamento',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasNotas && !_isExporting ? _exportar : null,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(_isExporting ? 'Exportando...' : 'Exportar'),
            ),
          ),
          if (!hasNotas) ...[
            const SizedBox(height: 8),
            Text(
              'Sem notas para exportar com os filtros atuais.',
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
