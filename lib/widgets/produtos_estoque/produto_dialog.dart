import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

/// Dialog de cadastro/edição de um produto do estoque.
/// Retorna [ProdutoEstoque] via [Navigator.pop] quando confirmado,
/// ou `null` quando cancelado.
class ProdutoDialog extends StatefulWidget {
  /// Produto a editar. Se `null`, o dialog opera em modo de cadastro.
  final ProdutoEstoque? produto;
  final List<String> embalagens;
  final bool isSaving;

  const ProdutoDialog({
    super.key,
    this.produto,
    required this.embalagens,
    this.isSaving = false,
  });

  /// Atalho para abrir o dialog e aguardar o resultado.
  static Future<ProdutoEstoque?> show(
    BuildContext context, {
    ProdutoEstoque? produto,
    required List<String> embalagens,
    bool isSaving = false,
  }) {
    return showDialog<ProdutoEstoque>(
      context: context,
      builder: (_) => ProdutoDialog(
        produto: produto,
        embalagens: embalagens,
        isSaving: isSaving,
      ),
    );
  }

  @override
  State<ProdutoDialog> createState() => _ProdutoDialogState();
}

class _ProdutoDialogState extends State<ProdutoDialog> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _quantidadeCtrl;
  late final TextEditingController _acrescentarCtrl;
  late final TextEditingController _precoCtrl;
  late String _embalagemSelecionada;

  // Cached theme-derived values — computed once in didChangeDependencies
  // to avoid repeated Theme.of / GoogleFonts lookups on every rebuild.
  late bool _isDark;
  late ColorScheme _cs;
  late Color _fillColor;
  late InputBorder _baseBorder;
  late InputBorder _focusedBorder;
  late TextStyle _fieldTextStyle;
  late TextStyle _helperStyle;

  bool get _isEditing => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    _idCtrl = TextEditingController(text: p?.idProduto?.toString() ?? '');
    _tipoCtrl = TextEditingController(text: p?.tipoProduto ?? '');
    _descricaoCtrl = TextEditingController(text: p?.descricao ?? '');
    _quantidadeCtrl = TextEditingController(
      text: p != null
          ? p.quantidadeEstoque.toString().replaceAll(RegExp(r'\.0$'), '')
          : '0',
    );
    _acrescentarCtrl = TextEditingController(text: '0');
    _precoCtrl = TextEditingController(
      text: p?.valorPrecoVarejo != null
          ? p!.valorPrecoVarejo!.toStringAsFixed(2)
          : '',
    );
    _embalagemSelecionada =
        (p?.embalagemSaida ?? widget.embalagens.first).trim().toUpperCase();
    if (!widget.embalagens.contains(_embalagemSelecionada)) {
      _embalagemSelecionada = widget.embalagens.first;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDark = Theme.of(context).brightness == Brightness.dark;
    _cs = Theme.of(context).colorScheme;
    _fillColor = _isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    const radius = BorderRadius.all(Radius.circular(12));
    _baseBorder = const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );
    _focusedBorder = const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    );
    _fieldTextStyle = GoogleFonts.inter(color: _cs.onSurface, fontSize: 14);
    _helperStyle = GoogleFonts.inter(
      color: _cs.onSurface.withValues(alpha: 0.45),
      fontSize: 11,
    );
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _tipoCtrl.dispose();
    _descricaoCtrl.dispose();
    _quantidadeCtrl.dispose();
    _acrescentarCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  ProdutoEstoque? _buildProduto() {
    if (_descricaoCtrl.text.trim().isEmpty) return null;
    if (_precoCtrl.text.trim().isEmpty) return null;

    final idText = _idCtrl.text.trim();
    final idProduto = idText.isEmpty ? null : int.tryParse(idText);
    final quantidadeInicial =
      double.tryParse(_quantidadeCtrl.text.replaceAll(',', '.')) ?? 0;
    final acrescentar =
        double.tryParse(_acrescentarCtrl.text.replaceAll(',', '.')) ?? 0;
    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.'));

    if (preco == null || (idText.isNotEmpty && idProduto == null)) return null;

    final quantidadeBaseEdicao = widget.produto?.quantidadeEstoque ?? 0;
    final quantidadeFinal = _isEditing
      ? (quantidadeBaseEdicao + (acrescentar < 0 ? 0 : acrescentar))
      : quantidadeInicial;

    return ProdutoEstoque(
      idProduto: idProduto,
      tipoProduto:
          _tipoCtrl.text.trim().isEmpty ? null : _tipoCtrl.text.trim(),
      descricao: _descricaoCtrl.text.trim(),
      embalagemSaida: _embalagemSelecionada,
      quantidadeEstoque: quantidadeFinal < 0 ? 0 : quantidadeFinal,
      valorPrecoVarejo: preco,
    );
  }

  String? _validationError() {
    if (_descricaoCtrl.text.trim().isEmpty && _precoCtrl.text.trim().isEmpty) {
      return 'Descrição e preço são obrigatórios.';
    }
    final idText = _idCtrl.text.trim();
    if (idText.isNotEmpty && int.tryParse(idText) == null) {
      return 'ID do produto inválido. Use um número inteiro.';
    }
    if (_descricaoCtrl.text.trim().isEmpty) {
      return 'A descrição do produto é obrigatória.';
    }
    if (!_isEditing &&
        double.tryParse(_quantidadeCtrl.text.replaceAll(',', '.')) == null) {
      return 'Quantidade inválida. Use apenas números.';
    }
    if (_isEditing) {
      final acrescentar = double.tryParse(_acrescentarCtrl.text.replaceAll(',', '.'));
      if (acrescentar == null) {
        return 'A quantidade para acrescentar é inválida.';
      }
      if (acrescentar < 0) {
        return 'A quantidade para acrescentar não pode ser negativa.';
      }
    }
    if (_precoCtrl.text.trim().isEmpty) {
      return 'O preço de venda é obrigatório.';
    }
    if (double.tryParse(_precoCtrl.text.replaceAll(',', '.')) == null) {
      return 'Preço inválido. Use apenas números (ex: 44.00).';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit_outlined : Icons.add_box_outlined,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            _isEditing ? 'Editar Produto' : 'Cadastrar Produto',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ID do produto ─────────────────────────────────────────────
            _field(
              _idCtrl,
              label: 'ID do produto',
              helperText: 'Opcional no cadastro. Pode ser editado.',
              prefixIcon: Icons.tag_outlined,
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 14),

            // ── Tipo ──────────────────────────────────────────────────────
            _field(
              _tipoCtrl,
              label: 'Tipo do produto',
              helperText: 'Categoria geral: telha, cimento, ferro...',
              prefixIcon: Icons.category_outlined,
              inputType: TextInputType.text,
            ),
            const SizedBox(height: 14),

            // ── Descrição (obrigatório) ────────────────────────────────
            _field(
              _descricaoCtrl,
              label: 'Descrição *',
              helperText: 'Nome completo do produto conforme cadastro',
              prefixIcon: Icons.inventory_2_outlined,
              inputType: TextInputType.text,
              isRequired: true,
            ),
            const SizedBox(height: 14),

            // ── Embalagem — widget próprio para isolar setState ────────
            _EmbalagemDropdown(
              embalagens: widget.embalagens,
              initialValue: _embalagemSelecionada,
              isDark: _isDark,
              cs: _cs,
              fillColor: _fillColor,
              baseBorder: _baseBorder,
              focusedBorder: _focusedBorder,
              onChanged: (v) => _embalagemSelecionada = v,
            ),
            const SizedBox(height: 14),

            if (!_isEditing)
              _field(
                _quantidadeCtrl,
                label: 'Quantidade inicial em estoque *',
                helperText: 'Quantidade inicial disponível no estoque.',
                prefixIcon: Icons.numbers_outlined,
                inputType: const TextInputType.numberWithOptions(decimal: true),
                isRequired: true,
              ),

            if (_isEditing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: _cs.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Estoque atual: ${widget.produto!.quantidadeEstoque.toString().replaceAll(RegExp(r'\\.0$'), '')}',
                      style: _fieldTextStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _field(
                _acrescentarCtrl,
                label: 'Acrescentar ao estoque *',
                helperText:
                    'Essa quantidade será somada ao estoque atual ao salvar.',
                prefixIcon: Icons.add_circle_outline,
                inputType:
                    const TextInputType.numberWithOptions(decimal: true),
                isRequired: true,
              ),
            ],
            const SizedBox(height: 14),

            // ── Preço (obrigatório) ────────────────────────────────────
            _field(
              _precoCtrl,
              label: 'Preço de venda (R\$) *',
              helperText: 'Preço unitário de venda no varejo',
              prefixIcon: Icons.attach_money_rounded,
              inputType: const TextInputType.numberWithOptions(decimal: true),
              isRequired: true,
            ),
          ],
        ),
      ),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: widget.isSaving ? null : () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(
                color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ),
        ElevatedButton(
          onPressed: widget.isSaving
              ? null
              : () {
                  final erro = _validationError();
                  if (erro != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(erro),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                  final p = _buildProduto();
                  if (p == null) return;
                  Navigator.pop(context, p);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: widget.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _isEditing ? 'Salvar' : 'Cadastrar',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl, {
    required String label,
    String? helperText,
    IconData? prefixIcon,
    TextInputType? inputType,
    bool isRequired = false,
    bool readOnly = false,
  }) {
    final labelColor =
        isRequired ? AppColors.primary : _cs.onSurface.withValues(alpha: 0.7);
    final labelStyle = GoogleFonts.inter(color: labelColor, fontSize: 13);

    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      keyboardType: inputType,
      // TextCapitalization.sentences is lighter than .characters on Android
      // (.characters forces every-char IME round-trip; .sentences does not)
      textCapitalization: inputType == null || inputType == TextInputType.text
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      style: _fieldTextStyle,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        floatingLabelStyle:
            GoogleFonts.inter(color: AppColors.primary, fontSize: 13),
        helperText: helperText,
        helperStyle: _helperStyle,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon,
                size: 20, color: _cs.onSurface.withValues(alpha: 0.55))
            : null,
        filled: true,
        fillColor: _fillColor,
        border: _baseBorder,
        enabledBorder: _baseBorder,
        focusedBorder: _focusedBorder,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Dropdown isolado ────────────────────────────────────────────────────────
// Gerencia seu próprio estado para que a mudança de seleção não dispare
// um rebuild de toda a árvore do dialog pai.
class _EmbalagemDropdown extends StatefulWidget {
  final List<String> embalagens;
  final String initialValue;
  final bool isDark;
  final ColorScheme cs;
  final Color fillColor;
  final InputBorder baseBorder;
  final InputBorder focusedBorder;
  final ValueChanged<String> onChanged;

  const _EmbalagemDropdown({
    required this.embalagens,
    required this.initialValue,
    required this.isDark,
    required this.cs,
    required this.fillColor,
    required this.baseBorder,
    required this.focusedBorder,
    required this.onChanged,
  });

  @override
  State<_EmbalagemDropdown> createState() => _EmbalagemDropdownState();
}

class _EmbalagemDropdownState extends State<_EmbalagemDropdown> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _value,
      dropdownColor: widget.isDark ? const Color(0xFF1E1E24) : Colors.white,
      iconEnabledColor: widget.cs.onSurface.withValues(alpha: 0.7),
      style: GoogleFonts.inter(color: widget.cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Embalagem de saída *',
        labelStyle: GoogleFonts.inter(color: AppColors.primary, fontSize: 13),
        floatingLabelStyle:
            GoogleFonts.inter(color: AppColors.primary, fontSize: 13),
        helperText: 'Unidade usada ao registrar saída no estoque',
        helperStyle: GoogleFonts.inter(
          color: widget.cs.onSurface.withValues(alpha: 0.45),
          fontSize: 11,
        ),
        prefixIcon: Icon(Icons.straighten_outlined,
            size: 20, color: widget.cs.onSurface.withValues(alpha: 0.55)),
        filled: true,
        fillColor: widget.fillColor,
        border: widget.baseBorder,
        enabledBorder: widget.baseBorder,
        focusedBorder: widget.focusedBorder,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: widget.embalagens
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _value = v);
        widget.onChanged(v);
      },
    );
  }
}
