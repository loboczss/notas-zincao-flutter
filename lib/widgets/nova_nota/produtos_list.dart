import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form_viewmodel.dart';

class ProdutosList extends StatefulWidget {
  final NotaFormViewModel viewModel;

  const ProdutosList({super.key, required this.viewModel});

  @override
  State<ProdutosList> createState() => _ProdutosListState();
}

class _ProdutosListState extends State<ProdutosList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produtos = widget.viewModel.produtos;
    final colorScheme = Theme.of(context).colorScheme;
    final produtoError = widget.viewModel.getFieldError(CampoErroValidacao.produtos);

    if (produtoError != null) {
      if (!_blinkController.isAnimating) {
        _blinkController.repeat(reverse: true);
      }
    } else if (_blinkController.isAnimating) {
      _blinkController.stop();
      _blinkController.reset();
    }

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, _) {
        final borderColor = produtoError == null
            ? Colors.transparent
            : Color.lerp(
                Colors.transparent,
                AppColors.error,
                _blinkAnimation.value,
              )!;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: produtoError == null ? 0 : 1.5,
            ),
          ),
          padding: produtoError == null
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
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
                  style: TextStyle(
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
                      style: TextStyle(
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
        if (produtoError != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
            ),
            child: Text(
              produtoError,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'A IA pode sugerir produtos. Você pode editar nome, quantidade, unidade e preço livremente.',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  'A IA pode sugerir e você pode ajustar livremente',
                  style: TextStyle(
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
          ),
        );
      },
    );
  }

  Widget _buildProdutoCard(BuildContext context, int index, Map<String, dynamic> produto) {
    final colorScheme = Theme.of(context).colorScheme;
    final nome = produto[ColsProdutoNota.nome] ?? 'Produto ${index + 1}';
    final qtd = produto[ColsProdutoNota.quantidade] ?? 1;
    final valorUnitario = produto[ColsProdutoNota.valorUnitario];
    final valorTotal = produto[ColsProdutoNota.valorTotal];
    final embalagem = produto[ColsProdutoNota.embalagem] ?? produto[ColsProdutoNota.tipoUnidade] ?? 'UN';

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
                style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qtd: $qtd $embalagem${valorUnitario != null ? '  •  R\$ ${(valorUnitario as num).toStringAsFixed(2)}' : ''}',
                  style: TextStyle(
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
                style: TextStyle(
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
            onPressed: () => widget.viewModel.removeProduto(index),
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
        viewModel: widget.viewModel,
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
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _buscaCtrl;
  late final TextEditingController _unidadeCtrl;
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
    _nomeCtrl = TextEditingController(text: _isEditing ? (widget.produto?[ColsProdutoNota.nome] ?? '').toString() : '');
    _buscaCtrl = TextEditingController();
    _unidadeCtrl = TextEditingController(
      text: _isEditing
          ? (widget.produto?[ColsProdutoNota.embalagem] ?? widget.produto?[ColsProdutoNota.tipoUnidade] ?? 'UN').toString()
          : 'UN',
    );
    _qtdCtrl = TextEditingController(text: _isEditing ? widget.produto!['quantidade']?.toString() : '1');
    _valorCtrl = TextEditingController(text: _isEditing ? (widget.produto!['valor_unitario']?.toString() ?? '') : '');
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _carregarResultados('');

    if (_isEditing) {
      final idAtual = widget.produto!['id_produto_estoque'];
      ProdutoEstoque? produtoInicial;
      final idProduto = idAtual is int
          ? idAtual
          : int.tryParse((idAtual ?? '').toString());

      if (idProduto != null) {
        produtoInicial = await widget.viewModel.findProdutoCatalogoById(idProduto);
      }

      produtoInicial ??= await widget.viewModel.findProdutoCatalogo((widget.produto!['nome'] ?? '').toString());

      if (!mounted) return;
      if (produtoInicial != null) {
        final produtoEncontrado = produtoInicial;
        setState(() {
          _selectedProduto = produtoEncontrado;
          _buscaCtrl.text = produtoEncontrado.descricao;
          _nomeCtrl.text = produtoEncontrado.descricao;
          _unidadeCtrl.text = produtoEncontrado.embalagemSaida;
          _valorCtrl.text = (produtoEncontrado.valorPrecoVarejo ?? 0).toStringAsFixed(2);
        });
      }
      return;
    }

    if (!mounted || _resultados.isEmpty) return;
    setState(() {
      _selectedProduto = _resultados.first;
      _buscaCtrl.text = _selectedProduto!.descricao;
      _nomeCtrl.text = _selectedProduto!.descricao;
      _unidadeCtrl.text = _selectedProduto!.embalagemSaida;
      _valorCtrl.text = (_selectedProduto!.valorPrecoVarejo ?? 0).toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nomeCtrl.dispose();
    _buscaCtrl.dispose();
    _unidadeCtrl.dispose();
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
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) return;

    final qtd = double.tryParse(_qtdCtrl.text.replaceAll(',', '.')) ?? 0;
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;
    final quantidade = qtd <= 0 ? 0 : qtd;
    final unidade = _unidadeCtrl.text.trim().isEmpty ? 'UN' : _unidadeCtrl.text.trim();
    final total = quantidade * valor;

    final prodData = <String, dynamic>{
      ColsProdutoNota.idProdutoEstoque: _selectedProduto?.idProduto,
      ColsProdutoNota.nome: nome,
      ColsProdutoNota.tipoProduto: _selectedProduto?.tipoProduto,
      ColsProdutoNota.quantidade: quantidade,
      ColsProdutoNota.embalagem: unidade,
      ColsProdutoNota.tipoUnidade: unidade,
      ColsProdutoNota.valorUnitario: valor,
      ColsProdutoNota.valorTotal: total,
    };

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
        style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
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
                'Buscar no estoque (opcional)',
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
                              child: Text(_erroBusca!, style: TextStyle(color: AppColors.error)),
                            ),
                          )
                        : _resultados.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Nenhum produto encontrado.',
                                    style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID ${produto.idProduto ?? '-'} • ${produto.embalagemSaida}',
                                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                                    ),
                                    trailing: produto.valorPrecoVarejo != null
                                        ? Text(
                                            'R\$ ${produto.valorPrecoVarejo!.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedProduto = produto;
                                        _buscaCtrl.text = produto.descricao;
                                        _nomeCtrl.text = produto.descricao;
                                        _unidadeCtrl.text = produto.embalagemSaida;
                                        _valorCtrl.text = (produto.valorPrecoVarejo ?? 0).toStringAsFixed(2);
                                      });
                                    },
                                  );
                                },
                              ),
              ),
              const SizedBox(height: 12),
              _dialogField(
                _nomeCtrl,
                'Nome do produto',
                prefixIcon: Icons.inventory_2_outlined,
                isDark: Theme.of(context).brightness == Brightness.dark,
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
                    style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
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
                          style: TextStyle(
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
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _dialogField(
                          _unidadeCtrl,
                          'UN',
                          isDark: Theme.of(context).brightness == Brightness.dark,
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
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _dialogField(
                          _valorCtrl,
                          'Ex.: 85.00',
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
          child: Text('Cancelar', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ),
        ElevatedButton(
          onPressed: _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(_isEditing ? 'Salvar' : 'Adicionar', style: TextStyle(fontWeight: FontWeight.w600)),
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
  bool readOnly = false,
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
    readOnly: readOnly,
    style: TextStyle(color: textColor, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
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
