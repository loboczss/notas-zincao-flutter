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
  final String? userRole;

  const ProdutoDialog({
    super.key,
    this.produto,
    required this.embalagens,
    this.isSaving = false,
    this.userRole,
  });

  /// Atalho para abrir o dialog e aguardar o resultado.
  static Future<ProdutoEstoque?> show(
    BuildContext context, {
    ProdutoEstoque? produto,
    required List<String> embalagens,
    bool isSaving = false,
    String? userRole,
  }) {
    return showModalBottomSheet<ProdutoEstoque>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProdutoDialog(
        produto: produto,
        embalagens: embalagens,
        isSaving: isSaving,
        userRole: userRole,
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
  late final TextEditingController _definirQuantidadeCtrl;
  late final TextEditingController _precoCtrl;
  late final TextEditingController _idProdutoPaiCtrl;
  late final TextEditingController _fatorConversaoCtrl;
  late String _embalagemSelecionada;
  bool _modoDefinirQuantidade = false;

  // Cached theme-derived values
  late bool _isDark;
  late ColorScheme _cs;
  late Color _fillColor;
  late InputBorder _baseBorder;
  late InputBorder _focusedBorder;
  late TextStyle _fieldTextStyle;
  late TextStyle _helperStyle;

  bool get _isEditing => widget.produto != null;
  bool get _isAdmin => widget.userRole == 'admin';

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
    _definirQuantidadeCtrl = TextEditingController(
      text: p != null
          ? p.quantidadeEstoque.toString().replaceAll(RegExp(r'\.0$'), '')
          : '0',
    );
    _precoCtrl = TextEditingController(
      text: p?.valorPrecoVarejo != null
          ? p!.valorPrecoVarejo!.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _idProdutoPaiCtrl = TextEditingController(text: p?.idProdutoPai?.toString() ?? '');
    _fatorConversaoCtrl = TextEditingController(
      text: p?.fatorConversao != null 
          ? p!.fatorConversao!.toStringAsFixed(2).replaceAll('.00', '').replaceAll('.', ',')
          : '1,00',
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
    _fieldTextStyle = GoogleFonts.inter(color: _cs.onSurface, fontSize: 15);
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
    _definirQuantidadeCtrl.dispose();
    _precoCtrl.dispose();
    _idProdutoPaiCtrl.dispose();
    _fatorConversaoCtrl.dispose();
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
    double quantidadeFinal;
    if (_isEditing) {
      if (_modoDefinirQuantidade) {
        final definida = double.tryParse(_definirQuantidadeCtrl.text.replaceAll(',', '.')) ?? quantidadeBaseEdicao;
        quantidadeFinal = definida < 0 ? 0 : definida;
      } else {
        quantidadeFinal = quantidadeBaseEdicao + (acrescentar < 0 ? 0 : acrescentar);
      }
    } else {
      quantidadeFinal = quantidadeInicial;
    }

    final idPaiText = _idProdutoPaiCtrl.text.trim();
    final idPai = idPaiText.isEmpty ? null : int.tryParse(idPaiText);
    final fatorText = _fatorConversaoCtrl.text.trim().replaceAll(',', '.');
    final fator = fatorText.isEmpty ? 1.0 : double.tryParse(fatorText);

    return ProdutoEstoque(
      idProduto: idProduto,
      tipoProduto:
          _tipoCtrl.text.trim().isEmpty ? null : _tipoCtrl.text.trim(),
      descricao: _descricaoCtrl.text.trim(),
      embalagemSaida: _embalagemSelecionada,
      quantidadeEstoque: quantidadeFinal < 0 ? 0 : quantidadeFinal,
      valorPrecoVarejo: preco,
      idProdutoPai: idPai,
      fatorConversao: fator ?? 1.0,
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
      if (_modoDefinirQuantidade) {
        final definida = double.tryParse(_definirQuantidadeCtrl.text.replaceAll(',', '.'));
        if (definida == null) {
          return 'Quantidade inválida. Use apenas números (ex: 150 ou 12,5).';
        }
        if (definida < 0) {
          return 'A quantidade não pode ser negativa.';
        }
      } else {
        final acrescentar = double.tryParse(_acrescentarCtrl.text.replaceAll(',', '.'));
        if (acrescentar == null) {
          return 'A quantidade para acrescentar é inválida.';
        }
        if (acrescentar < 0) {
          return 'A quantidade para acrescentar não pode ser negativa.';
        }
      }
    }
    if (_precoCtrl.text.trim().isEmpty) {
      return 'O preço de venda é obrigatório.';
    }
    if (double.tryParse(_precoCtrl.text.replaceAll(',', '.')) == null) {
      return 'Preço inválido. Use apenas números (ex: 44,00).';
    }
    
    final idPaiText = _idProdutoPaiCtrl.text.trim();
    if (idPaiText.isNotEmpty && int.tryParse(idPaiText) == null) {
      return 'O código do protudo pai deve ser um número inteiro.';
    }

    final fatorText = _fatorConversaoCtrl.text.trim().replaceAll(',', '.');
    if (fatorText.isNotEmpty && double.tryParse(fatorText) == null) {
      return 'O fator de conversão deve ser numérico (ex: 0,5 ou 1,0)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Drag Handle e Cabeçalho
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _cs.onSurface.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isEditing ? Icons.edit_outlined : Icons.add_box_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isEditing ? 'Editar Produto' : 'Novo Produto',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: _cs.onSurface),
                    ),
                  ],
                ),
              ),

              // Conteúdo rolável
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // SEÇÃO 1: Informações Básicas
                      _SectionCard(
                        title: 'Informações Básicas',
                        icon: Icons.info_outline,
                        children: [
                          _field(
                            _idCtrl,
                            label: 'ID do produto',
                            helperText: 'Opcional. Código único do cadastro.',
                            prefixIcon: Icons.tag_outlined,
                            inputType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            _descricaoCtrl,
                            label: 'Descrição / Nome *',
                            helperText: 'Ex: Telha Zinco M² ASTM',
                            prefixIcon: Icons.inventory_2_outlined,
                            inputType: TextInputType.text,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            _tipoCtrl,
                            label: 'Tipo / Categoria',
                            helperText: 'Ex: telha, cimento, ferragem...',
                            prefixIcon: Icons.category_outlined,
                            inputType: TextInputType.text,
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          _field(
                            _precoCtrl,
                            label: 'Preço de Venda (R\$) *',
                            helperText: 'Preço unitário no varejo',
                            prefixIcon: Icons.attach_money_rounded,
                            inputType: const TextInputType.numberWithOptions(decimal: true),
                            isRequired: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // SEÇÃO 2: Controle de Estoque
                      _SectionCard(
                        title: 'Gestão de Estoque',
                        icon: Icons.inventory_outlined,
                        children: [
                          if (!_isEditing)
                            _field(
                              _quantidadeCtrl,
                              label: 'Quantidade inicial *',
                              helperText: 'Saldo inicial em estoque.',
                              prefixIcon: Icons.numbers_outlined,
                              inputType: const TextInputType.numberWithOptions(decimal: true),
                              isRequired: true,
                            ),
                          if (_isEditing) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _cs.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.query_stats, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo atual em sistema',
                                        style: TextStyle(fontSize: 12, color: _cs.onSurface.withValues(alpha: 0.6)),
                                      ),
                                      Text(
                                        '${widget.produto!.quantidadeEstoque.toString().replaceAll('.', ',').replaceAll(RegExp(r',0$'), '')} $_embalagemSelecionada',
                                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _cs.onSurface),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Toggle Adicionar / Definir
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _modoDefinirQuantidade = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !_modoDefinirQuantidade
                                            ? AppColors.primary
                                            : _fillColor,
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                        border: Border.all(
                                          color: !_modoDefinirQuantidade
                                              ? AppColors.primary
                                              : _cs.outlineVariant,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_circle_outline,
                                              size: 16,
                                              color: !_modoDefinirQuantidade
                                                  ? Colors.white
                                                  : _cs.onSurface.withValues(alpha: 0.6)),
                                          const SizedBox(width: 6),
                                          Text('Adicionar',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: !_modoDefinirQuantidade
                                                    ? Colors.white
                                                    : _cs.onSurface.withValues(alpha: 0.6),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _modoDefinirQuantidade = true),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _modoDefinirQuantidade
                                            ? AppColors.primary
                                            : _fillColor,
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                                        border: Border.all(
                                          color: _modoDefinirQuantidade
                                              ? AppColors.primary
                                              : _cs.outlineVariant,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.edit_outlined,
                                              size: 16,
                                              color: _modoDefinirQuantidade
                                                  ? Colors.white
                                                  : _cs.onSurface.withValues(alpha: 0.6)),
                                          const SizedBox(width: 6),
                                          Text('Definir',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: _modoDefinirQuantidade
                                                    ? Colors.white
                                                    : _cs.onSurface.withValues(alpha: 0.6),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!_modoDefinirQuantidade)
                              _field(
                                _acrescentarCtrl,
                                label: 'Adicionar ao estoque',
                                helperText: 'Quantidade para SOMAR ao saldo atual.',
                                prefixIcon: Icons.add_circle_outline,
                                inputType: const TextInputType.numberWithOptions(decimal: true),
                              )
                            else
                              _field(
                                _definirQuantidadeCtrl,
                                label: 'Nova quantidade em estoque',
                                helperText: 'Substitui o saldo atual pelo valor informado.',
                                prefixIcon: Icons.edit_outlined,
                                inputType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                          ],
                        ],
                      ),
                      
                      // SEÇÃO 3: Dependência (Somente Admin)
                      if (_isAdmin) ...[
                        const SizedBox(height: 24),
                        _SectionCard(
                          title: 'Vínculo (Avançado)',
                          icon: Icons.link_outlined,
                          isWarning: true,
                          children: [
                            _field(
                              _idProdutoPaiCtrl,
                              label: 'ID do Produto Pai',
                              helperText: 'Vincular desconto a outro saldo (Ex: código 10).',
                              prefixIcon: Icons.link,
                              inputType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              _fatorConversaoCtrl,
                              label: 'Fator de Conversão',
                              helperText: 'Ex: 0,5 significa que 1UN desconta 0,5 do pai.',
                              prefixIcon: Icons.calculate_outlined,
                              inputType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 80), // Espaço para o botão fixo
                    ],
                  ),
                ),
              ),

              // Botão Salvar (Fixo no rodapé)
              Container(
                padding: const EdgeInsets.all(24).copyWith(top: 16),
                decoration: BoxDecoration(
                  color: _cs.surface,
                  border: Border(top: BorderSide(color: _cs.outlineVariant)),
                ),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
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
                            _isEditing ? 'Salvar Alterações' : 'Cadastrar Produto',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool isWarning;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isWarning ? AppColors.warning : AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
