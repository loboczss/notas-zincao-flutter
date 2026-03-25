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
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _quantidadeCtrl;
  late final TextEditingController _precoCtrl;
  late String _embalagemSelecionada;

  bool get _isEditing => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    _tipoCtrl = TextEditingController(text: p?.tipoProduto ?? '');
    _descricaoCtrl = TextEditingController(text: p?.descricao ?? '');
    _quantidadeCtrl = TextEditingController(
      text: p != null
          ? p.quantidadeEstoque.toString().replaceAll(RegExp(r'\.0$'), '')
          : '0',
    );
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
  void dispose() {
    _tipoCtrl.dispose();
    _descricaoCtrl.dispose();
    _quantidadeCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  ProdutoEstoque? _buildProduto() {
    if (_descricaoCtrl.text.trim().isEmpty) return null;
    final quantidade =
        double.tryParse(_quantidadeCtrl.text.replaceAll(',', '.')) ?? 0;
    final preco = _precoCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_precoCtrl.text.replaceAll(',', '.'));

    return ProdutoEstoque(
      idProduto: widget.produto?.idProduto,
      tipoProduto:
          _tipoCtrl.text.trim().isEmpty ? null : _tipoCtrl.text.trim(),
      descricao: _descricaoCtrl.text.trim(),
      embalagemSaida: _embalagemSelecionada,
      quantidadeEstoque: quantidade < 0 ? 0 : quantidade,
      valorPrecoVarejo: preco,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isEditing ? 'Editar Produto' : 'Cadastrar Produto',
        style:
            GoogleFonts.inter(fontWeight: FontWeight.w700, color: cs.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_tipoCtrl, 'Tipo do produto (telha, cimento...)'),
            const SizedBox(height: 10),
            _field(_descricaoCtrl, 'Descrição do produto'),
            const SizedBox(height: 10),
            _embalagemDropdown(),
            const SizedBox(height: 10),
            _field(
              _quantidadeCtrl,
              'Quantidade em estoque',
              inputType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            _field(
              _precoCtrl,
              'Preço varejo (opcional)',
              inputType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSaving ? null : () => Navigator.pop(context),
          child: Text('Cancelar',
            style: GoogleFonts.inter(color: cs.onSurface.withValues(alpha: 0.6))),
        ),
        ElevatedButton(
          onPressed: widget.isSaving
              ? null
              : () {
                  final p = _buildProduto();
                  if (p == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Descrição é obrigatória.'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, p);
                },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary),
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
    TextEditingController ctrl,
    String hint, {
    TextInputType? inputType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: GoogleFonts.inter(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: cs.onSurface.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _embalagemDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: _embalagemSelecionada,
      dropdownColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      iconEnabledColor: cs.onSurface.withValues(alpha: 0.7),
      style: GoogleFonts.inter(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Selecione a embalagem',
        hintStyle: GoogleFonts.inter(
          color: cs.onSurface.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: widget.embalagens
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _embalagemSelecionada = v);
      },
    );
  }
}
