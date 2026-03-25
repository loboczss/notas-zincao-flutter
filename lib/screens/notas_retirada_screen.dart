import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/services/nota_retirada_service.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';

import 'package:notas_zincao_flutter/widgets/minhas_notas/notas_action_row.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/notas_filters.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/notas_empty_state.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/notas_list_views.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/nota_details_sheet.dart';

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
  bool _isLoading = true;
  bool _isTableView = true;

  @override
  void initState() {
    super.initState();
    _loadNotas();
  }

  Future<void> _loadNotas() async {
    setState(() => _isLoading = true);
    try {
      final notas = await _service.fetchAll(widget.authViewModel.profile);
      setState(() {
        _notas = notas;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar notas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
      return matchesSearch && matchesStatus;
    }).toList();
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
          ),
          NotasFilters(
            onSearch: (v) => setState(() => _searchQuery = v),
            selectedStatus: _selectedStatus,
            onStatusSelected: (s) => setState(() => _selectedStatus = s),
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
