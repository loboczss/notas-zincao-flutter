import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form_viewmodel.dart';

class ProdutosList extends StatelessWidget {
  final NotaFormViewModel viewModel;

  const ProdutosList({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final produtos = viewModel.produtos;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Produtos',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (produtos.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${produtos.length}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              onPressed: () => _showAddOrEditProductDialog(context),
              tooltip: 'Adicionar produto',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Somente produtos do estoque podem ser vinculados à nota. Use a busca para selecionar sem travar a tela.',
          style: GoogleFonts.inter(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (produtos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 32,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nenhum produto adicionado',
                  style: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  'A IA preencherá com base no estoque ou selecione manualmente',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...List.generate(produtos.length, (i) => _buildProdutoCard(context, i, produtos[i])),
      ],
    );
  }

  Widget _buildProdutoCard(BuildContext context, int index, Map<String, dynamic> produto) {
    final colorScheme = Theme.of(context).colorScheme;
    final nome = produto['nome'] ?? 'Produto ${index + 1}';
    final qtd = produto['quantidade'] ?? 1;
    final valorUnitario = produto['valor_unitario'];
    final valorTotal = produto['valor_total'];
    final embalagem = produto['embalagem'] ?? produto['tipo_unidade'] ?? 'UN';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qtd: $qtd $embalagem${valorUnitario != null ? '  •  R\$ ${(valorUnitario as num).toStringAsFixed(2)}' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (valorTotal != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'R\$ ${(valorTotal as num).toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.edit_rounded, size: 18, color: colorScheme.onSurfaceVariant),
            onPressed: () => _showAddOrEditProductDialog(context, produto: produto, index: index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65)),
            onPressed: () => viewModel.removeProduto(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditProductDialog(BuildContext context, {Map<String, dynamic>? produto, int? index}) {
    showDialog<void>(
      context: context,
      builder: (_) => _ProdutoPickerDialog(
        viewModel: viewModel,
        produto: produto,
        index: index,
      ),
    );
  }
}

class _ProdutoPickerDialog extends StatefulWidget {
  final NotaFormViewModel viewModel;
  final Map<String, dynamic>? produto;
  final int? index;

  const _ProdutoPickerDialog({
    required this.viewModel,
    this.produto,
    this.index,
  });

  @override
  State<_ProdutoPickerDialog> createState() => _ProdutoPickerDialogState();
}

class _ProdutoPickerDialogState extends State<_ProdutoPickerDialog> {
  late final TextEditingController _buscaCtrl;
  late final TextEditingController _qtdCtrl;
  late final TextEditingController _valorCtrl;
  Timer? _debounce;
  List<ProdutoEstoque> _resultados = [];
  ProdutoEstoque? _selectedProduto;
  bool _isSearching = false;
  String? _erroBusca;

  bool get _isEditing => widget.produto != null && widget.index != null;

  @override
  void initState() {
    super.initState();
    _buscaCtrl = TextEditingController();
    _qtdCtrl = TextEditingController(text: _isEditing ? widget.produto!['quantidade']?.toString() : '1');
    _valorCtrl = TextEditingController(text: _isEditing ? (widget.produto!['valor_unitario']?.toString() ?? '') : '');
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _carregarResultados('');

    if (_isEditing) {
      final idAtual = widget.produto!['id_produto_estoque'];
      ProdutoEstoque? produtoInicial;

      if (idAtual is int) {
        produtoInicial = await widget.viewModel.findProdutoCatalogoById(idAtual);
      }

      produtoInicial ??= await widget.viewModel.findProdutoCatalogo((widget.produto!['nome'] ?? '').toString());

      if (!mounted) return;
      if (produtoInicial != null) {
        final produtoEncontrado = produtoInicial;
        setState(() {
          _selectedProduto = produtoEncontrado;
          _buscaCtrl.text = produtoEncontrado.descricao;
        });
      }
      return;
    }

    if (!mounted || _resultados.isEmpty) return;
    setState(() {
      _selectedProduto = _resultados.first;
      _buscaCtrl.text = _selectedProduto!.descricao;
      if (_selectedProduto!.valorPrecoVarejo != null) {
        _valorCtrl.text = _selectedProduto!.valorPrecoVarejo!.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaCtrl.dispose();
    _qtdCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarResultados(String query) async {
    setState(() {
      _isSearching = true;
      _erroBusca = null;
    });

    try {
      final resultados = await widget.viewModel.searchProdutosCatalogo(query);
      if (!mounted) return;
      setState(() {
        _resultados = resultados;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erroBusca = 'Não foi possível carregar os produtos do estoque.';
        _resultados = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _carregarResultados(value.trim());
    });
  }

  void _salvar() {
    final produto = _selectedProduto;
    if (produto == null || produto.idProduto == null) return;

    final qtd = double.tryParse(_qtdCtrl.text.replaceAll(',', '.')) ?? 1.0;
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;

    final prodData = widget.viewModel.buildProdutoNotaFromCatalogo(
      produto: produto,
      quantidade: qtd <= 0 ? 1 : qtd,
      valorUnitario: valor,
    );

    if (_isEditing) {
      widget.viewModel.updateProduto(widget.index!, prodData);
    } else {
      widget.viewModel.addProduto(prodData);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(
        _isEditing ? 'Editar Produto' : 'Adicionar Produto',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogField(
                _buscaCtrl,
                'Pesquisar produto por nome ou ID',
                onChanged: _onSearchChanged,
                prefixIcon: Icons.search_rounded,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _erroBusca != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(_erroBusca!, style: GoogleFonts.inter(color: AppColors.error)),
                            ),
                          )
                        : _resultados.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Nenhum produto encontrado.',
                                    style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _resultados.length,
                                separatorBuilder: (_, _) => Divider(height: 1, color: colorScheme.outlineVariant),
                                itemBuilder: (context, index) {
                                  final produto = _resultados[index];
                                  final isSelected = _selectedProduto?.idProduto == produto.idProduto;

                                  return ListTile(
                                    selected: isSelected,
                                    selectedTileColor: AppColors.primary.withValues(alpha: 0.10),
                                    title: Text(
                                      produto.descricao,
                                      style: GoogleFonts.inter(
                                        color: colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID ${produto.idProduto ?? '-'} • ${produto.embalagemSaida}',
                                      style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 12),
                                    ),
                                    trailing: produto.valorPrecoVarejo != null
                                        ? Text(
                                            'R\$ ${produto.valorPrecoVarejo!.toStringAsFixed(2)}',
                                            style: GoogleFonts.inter(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedProduto = produto;
                                        _buscaCtrl.text = produto.descricao;
                                        if (_valorCtrl.text.trim().isEmpty && produto.valorPrecoVarejo != null) {
                                          _valorCtrl.text = produto.valorPrecoVarejo!.toStringAsFixed(2);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
              ),
              const SizedBox(height: 12),
              if (_selectedProduto != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Selecionado: ${_selectedProduto!.descricao} (${_selectedProduto!.embalagemSaida})',
                    style: GoogleFonts.inter(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                  ),
                ),
              if (_selectedProduto != null) const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantidade',
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _dialogField(
                          _qtdCtrl,
                          'Ex.: 40',
                          inputType: const TextInputType.numberWithOptions(decimal: true),
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unidade',
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Text(
                            _selectedProduto?.embalagemSaida ?? '-',
                            style: GoogleFonts.inter(
                              color: colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor unitário (R\$)',
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _dialogField(
                          _valorCtrl,
                          'Ex.: 44,00',
                          inputType: const TextInputType.numberWithOptions(decimal: true),
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
        ),
        ElevatedButton(
          onPressed: _selectedProduto == null ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(_isEditing ? 'Salvar' : 'Adicionar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

Widget _dialogField(
  TextEditingController ctrl,
  String hint, {
  TextInputType? inputType,
  void Function(String value)? onChanged,
  IconData? prefixIcon,
  required bool isDark,
}) {
  final fillColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);
  final hintColor = isDark ? Colors.white38 : Colors.black45;
  final textColor = isDark ? Colors.white : Colors.black87;
  final iconColor = isDark ? Colors.white54 : Colors.black54;

  return TextField(
    controller: ctrl,
    keyboardType: inputType,
    onChanged: onChanged,
    style: GoogleFonts.inter(color: textColor, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: hintColor, fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: iconColor) : null,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
