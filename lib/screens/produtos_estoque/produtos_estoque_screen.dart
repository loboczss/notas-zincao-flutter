import 'package:flutter/material.dart';
import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/produtos_estoque_viewmodel.dart';
import 'package:notas_zincao_flutter/widgets/produtos_estoque/produto_card.dart';
import 'package:notas_zincao_flutter/widgets/produtos_estoque/produto_dialog.dart';
import 'package:notas_zincao_flutter/widgets/produtos_estoque/produto_search_bar.dart';
import 'package:notas_zincao_flutter/widgets/shared/app_error_feedback.dart';

class ProdutosEstoqueScreen extends StatefulWidget {
  const ProdutosEstoqueScreen({super.key});

  @override
  State<ProdutosEstoqueScreen> createState() => _ProdutosEstoqueScreenState();
}

class _ProdutosEstoqueScreenState extends State<ProdutosEstoqueScreen> {
  final ProdutosEstoqueViewModel _viewModel = ProdutosEstoqueViewModel();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;

  static const List<String> _embalagens = [
    'PESO',
    'METRO',
    'SACO',
    'UN',
    'KG',
    'M',
    'CX',
    'PCT',
    'L',
    'G',
    'CM',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel.carregarProdutos();
    _viewModel.addListener(_onViewModelChanged);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      _viewModel.carregarMais();
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _viewModel.pesquisar(q);
    });
  }

  Future<void> _abrirDialog({int? index}) async {
    final produto =
      index != null ? _viewModel.produtos[index] : null;

    final resultado = await ProdutoDialog.show(
      context,
      produto: produto,
      embalagens: _embalagens,
      isSaving: _viewModel.isSaving,
    );

    if (resultado == null) return;

    try {
      if (produto != null) {
        await _viewModel.editarProduto(resultado);
      } else {
        await _viewModel.criarProduto(resultado);
      }
    } catch (e) {
      if (!mounted) return;
      AppErrorFeedback.show(
        context,
        error: e,
        fallbackMessage: 'Não foi possível salvar o produto.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtos = _viewModel.produtos;
    final isLoading = _viewModel.isLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Barra de pesquisa ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ProdutoSearchBar(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
            ),
          ),

          // ── Contador de resultados ─────────────────────────────────────────
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    _viewModel.query.isEmpty
                        ? '${produtos.length} produto${produtos.length != 1 ? 's' : ''} carregado${produtos.length != 1 ? 's' : ''}${_viewModel.temMais ? ' (carregando mais...)' : ''}'
                        : '${produtos.length} resultado${produtos.length != 1 ? 's' : ''} para "${_viewModel.query}"${_viewModel.temMais ? '...' : ''}',
                    style: GoogleFonts.inter(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // ── Lista / estados ────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _viewModel.carregarProdutos,
                    child: produtos.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: produtos.length + (_viewModel.temMais ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == produtos.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return ProdutoCard(
                                produto: produtos[index],
                                onEdit: () => _abrirDialog(index: index),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _abrirDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Cadastrar Produto',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final temPesquisa = _viewModel.query.isNotEmpty;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(
          temPesquisa ? Icons.search_off_rounded : Icons.inventory_2_outlined,
          size: 44,
          color: cs.onSurface.withValues(alpha: 0.25),
        ),
        const SizedBox(height: 12),
        Text(
          temPesquisa
              ? 'Nenhum produto encontrado para\n"${_viewModel.query}"'
              : 'Nenhum produto cadastrado no estoque.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: cs.onSurface.withValues(alpha: 0.6)),
        ),
        if (temPesquisa) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                _searchCtrl.clear();
                _viewModel.limparPesquisa();
              },
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Limpar pesquisa'),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
