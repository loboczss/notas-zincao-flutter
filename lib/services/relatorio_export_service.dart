import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:notas_zincao_flutter/models/nota_retirada.dart';

enum FormatoExportacao { csv, pdf }

class RelatorioExportService {
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _moneyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _fileNameDateFmt = DateFormat('yyyyMMdd_HHmm');

  /// Exporta [notas] no [formato] escolhido e compartilha via intent nativo.
  Future<void> exportarRetiradas(
    List<NotaRetirada> notas, {
    FormatoExportacao formato = FormatoExportacao.csv,
  }) async {
    switch (formato) {
      case FormatoExportacao.csv:
        await _exportarCsv(notas);
      case FormatoExportacao.pdf:
        await _exportarPdf(notas);
    }
  }

  // ── CSV ────────────────────────────────────────────────────────────────────

  Future<void> _exportarCsv(List<NotaRetirada> notas) async {
    final csv = _buildCsv(notas);
    final fileName =
        'relatorio_retiradas_${_fileNameDateFmt.format(DateTime.now())}.csv';

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    // UTF-8 BOM + encoding correto para compatibilidade com Excel
    final bytes = utf8.encode(csv);
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...bytes]);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: fileName,
    );
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  Future<void> _exportarPdf(List<NotaRetirada> notas) async {
    final fileName =
        'relatorio_retiradas_${_fileNameDateFmt.format(DateTime.now())}.pdf';

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final doc = pw.Document();

    final headers = [
      'Nº Nota', 'Série', 'Cliente', 'Data Compra',
      'Data Retirada', 'Status', 'Valor Líquido',
    ];

    final rows = notas.map((nota) {
      final valorBruto = nota.valorTotal ?? 0.0;
      final desconto = nota.descontoTotal ?? 0.0;
      final valorLiquido = valorBruto - desconto;
      return [
        nota.numeroNota.toString(),
        nota.serieNota.toString(),
        nota.nomeCliente,
        _dateFmt.format(nota.dataCompra),
        nota.dataRetirada != null ? _dateFmt.format(nota.dataRetirada!) : '-',
        nota.statusRetirada.label,
        _moneyFmt.format(valorLiquido),
      ];
    }).toList();

    const pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
    );

    doc.addPage(pw.MultiPage(
      pageTheme: pageTheme,
      build: (context) => [
        pw.Text(
          'Relatório de Retiradas',
          style: pw.TextStyle(font: fontBold, fontSize: 18),
        ),
        pw.Text(
          'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellStyle: pw.TextStyle(font: font, fontSize: 8),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.center,
            4: pw.Alignment.center,
            5: pw.Alignment.center,
            6: pw.Alignment.centerRight,
          },
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total: ${notas.length} nota(s)',
            style: pw.TextStyle(font: fontBold, fontSize: 10),
          ),
        ),
      ],
    ));

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: fileName,
    );
  }

  String _buildCsv(List<NotaRetirada> notas) {
    final buf = StringBuffer();

    buf.writeln(_row([
      'Nº Nota',
      'Série',
      'Cliente',
      'Documento',
      'Telefone',
      'Data Compra',
      'Data Prevista Retirada',
      'Data Retirada',
      'Status',
      'Valor Bruto',
      'Desconto',
      'Valor Líquido',
      'Qtd Produtos',
      'Cadastrado Por',
      'Confirmado Por',
      'Observações',
    ]));

    for (final nota in notas) {
      final valorBruto = nota.valorTotal ?? 0.0;
      final desconto = nota.descontoTotal ?? 0.0;
      final valorLiquido = valorBruto - desconto;

      buf.writeln(_row([
        nota.numeroNota,
        nota.serieNota,
        nota.nomeCliente,
        nota.documentoCliente ?? '',
        nota.telefoneCliente ?? '',
        _dateFmt.format(nota.dataCompra),
        nota.dataPrevistaRetirada != null
            ? _dateFmt.format(nota.dataPrevistaRetirada!)
            : '',
        nota.dataRetirada != null ? _dateFmt.format(nota.dataRetirada!) : '',
        nota.statusRetirada.label,
        _moneyFmt.format(valorBruto),
        _moneyFmt.format(desconto),
        _moneyFmt.format(valorLiquido),
        nota.produtos.length.toString(),
        nota.cadastradoPorNome ?? '',
        nota.retiradaConfirmadaPor ?? '',
        nota.observacoes ?? '',
      ]));
    }

    return buf.toString();
  }

  String _row(List<String> fields) {
    return fields.map(_escapeField).join(',');
  }

  String _escapeField(String value) {
    final needsQuoting =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuoting) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
