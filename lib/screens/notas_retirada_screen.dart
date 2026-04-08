import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/services/nota_retirada_service.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';

import 'package:notas_zincao_flutter/widgets/minhas_notas/exportar_relatorio_sheet.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/notas_action_row.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/notas_filters.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/notas_empty_state.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/notas_list_views.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/nota_details_sheet.dart';
import 'package:notas_zincao_flutter/widgets/shared/app_error_feedback.dart';

class NotasRetiradaScreen extends StatefulWidget {
  final AuthViewModel authViewModel;

  const NotasRetiradaScreen({super.key, required this.authViewModel});

  @override
  State<NotasRetiradaScreen> createState() => _NotasRetiradaScreenState();
}

class _NotasRetiradaScreenState extends State<NotasRetiradaScreen> {
  final _service = NotaRetiradaService();
  List<NotaRetirada>? _notas;
  String _searchQuery = '';
  StatusRetirada? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    _loadNotas();
  }

  Future<void> _loadNotas() async {
    setState(() => _isLoading = true);
    try {
      final notas = await _service.fetchAll(widget.authViewModel.profile);
      if (!mounted) return;
      setState(() {
        _notas = notas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      AppErrorFeedback.show(
        context,
        error: e,
        fallbackMessage: 'Não foi possível carregar suas notas.',
      );
      setState(() => _isLoading = false);
    }
  }

  List<NotaRetirada> get _filteredNotas {
    if (_notas == null) return [];
    return _notas!.where((nota) {
      final matchesSearch =
          nota.nomeCliente.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          nota.numeroNota.contains(_searchQuery);
      final matchesStatus = _selectedStatus == null || nota.statusRetirada == _selectedStatus;
      final matchesDateRange = _matchesDateRange(nota.dataCompra);
      return matchesSearch && matchesStatus && matchesDateRange;
    }).toList();
  }

  bool _matchesDateRange(DateTime date) {
    final targetDate = DateUtils.dateOnly(date);

    if (_startDate != null) {
      final start = DateUtils.dateOnly(_startDate!);
      if (targetDate.isBefore(start)) return false;
    }

    if (_endDate != null) {
      final end = DateUtils.dateOnly(_endDate!);
      if (targetDate.isAfter(end)) return false;
    }

    return true;
  }

  void _setStartDate(DateTime? value) {
    if (value != null && _endDate != null && value.isAfter(_endDate!)) {
      _showInvalidRangeMessage();
      return;
    }
    setState(() => _startDate = value);
  }

  void _setEndDate(DateTime? value) {
    if (value != null && _startDate != null && value.isBefore(_startDate!)) {
      _showInvalidRangeMessage();
      return;
    }
    setState(() => _endDate = value);
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _showInvalidRangeMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Período inválido: a data inicial não pode ser maior que a final.'),
      ),
    );
  }

  bool get _isAdmin =>
      widget.authViewModel.profile?.role?.toLowerCase() == 'admin';

  void _openExportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ExportarRelatorioSheet(
        notas: _filteredNotas,
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          NotasActionRow(
            isTableView: _isTableView,
            onToggleView: () => setState(() => _isTableView = !_isTableView),
            onRefresh: _loadNotas,
            isAdmin: _isAdmin,
            onExport: _isAdmin ? _openExportSheet : null,
          ),
          NotasFilters(
            onSearch: (v) => setState(() => _searchQuery = v),
            selectedStatus: _selectedStatus,
            onStatusSelected: (s) => setState(() => _selectedStatus = s),
            startDate: _startDate,
            endDate: _endDate,
            onStartDateChanged: _setStartDate,
            onEndDateChanged: _setEndDate,
            onClearDateRange: _clearDateRange,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotas.isEmpty
                    ? NotasEmptyState(onRefresh: _loadNotas)
                    : RefreshIndicator(
                        onRefresh: _loadNotas,
                        child: _isTableView
                            ? NotasTableView(
                                notas: _filteredNotas,
                                onNotaSelected: (nota) => showNotaDetails(context, nota, widget.authViewModel, _loadNotas),
                              )
                            : NotasCardView(
                                notas: _filteredNotas,
                                onNotaSelected: (nota) => showNotaDetails(context, nota, widget.authViewModel, _loadNotas),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
