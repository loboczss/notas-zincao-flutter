import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/constants/db_tables.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form_viewmodel.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';

/// Campo de texto reutilizável para o formulário de nota.
/// Suporta animação de piscada vermelha quando o campo está faltando.
class NotaTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool isMissing;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const NotaTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.isMissing = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  @override
  State<NotaTextField> createState() => _NotaTextFieldState();
}

class _NotaTextFieldState extends State<NotaTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant NotaTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMissing && !oldWidget.isMissing) {
      _blinkController.repeat(reverse: true);
    } else if (!widget.isMissing && oldWidget.isMissing) {
      _blinkController.stop();
      _blinkController.reset();
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        final borderColor = widget.isMissing
            ? Color.lerp(
                Colors.transparent,
                AppColors.error,
                _blinkAnimation.value,
              )!
          : cs.outlineVariant;

        final bgColor = widget.isMissing
            ? Color.lerp(
            cs.surfaceContainerHighest,
                AppColors.error.withValues(alpha: 0.08),
                _blinkAnimation.value * 0.3,
              )!
          : cs.surfaceContainerHighest;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isMissing
                        ? AppColors.error
                          : cs.onSurfaceVariant,
                  ),
                ),
                if (widget.isMissing) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• Obrigatório',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: widget.isMissing ? 1.5 : 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  style: GoogleFonts.inter(
                    color: cs.onSurface,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.inter(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                    prefixIcon: widget.icon != null
                        ? Icon(
                            widget.icon,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          )
                        : null,
                    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    disabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Seção de campos do formulário agrupados.
class NotaFormFields extends StatefulWidget {
  final NotaFormViewModel viewModel;

  const NotaFormFields({super.key, required this.viewModel});

  @override
  State<NotaFormFields> createState() => _NotaFormFieldsState();
}

class _NotaFormFieldsState extends State<NotaFormFields> {
  final FocusNode _nomeClienteFocusNode = FocusNode();

  @override
  void dispose() {
    _nomeClienteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final missing = viewModel.missingFields;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Dados do Cliente ──
        _buildSectionTitle('Dados do Cliente', Icons.person_outline_rounded),
        const SizedBox(height: 12),
        RawAutocomplete<Map<String, dynamic>>(
          textEditingController: viewModel.nomeClienteCtrl,
          focusNode: _nomeClienteFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 3) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            try {
              final res = await supabase
                  .from(DbTables.crmZincao)
                  .select('${ColsCrmZincao.contatoId}, ${ColsCrmZincao.nome}')
                  .ilike(ColsCrmZincao.nome, '%${textEditingValue.text}%')
                  .limit(5);
              return List<Map<String, dynamic>>.from(res);
            } catch (_) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
          },
          displayStringForOption: (option) => option[ColsCrmZincao.nome] as String? ?? '',
          onSelected: (option) {
            viewModel.nomeClienteCtrl.text = option[ColsCrmZincao.nome] as String? ?? '';
            viewModel.telefoneClienteCtrl.text = option[ColsCrmZincao.contatoId] as String? ?? '';
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return NotaTextField(
              controller: controller,
              focusNode: focusNode,
              label: 'Nome do Cliente',
              hint: 'Digite para buscar no CRM...',
              icon: Icons.person_rounded,
              isMissing: missing.contains(CampoObrigatorio.nomeCliente),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8.0,
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => Divider(color: cs.outlineVariant, height: 1),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.person, color: AppColors.primary),
                        title: Text(option[ColsCrmZincao.nome] ?? 'Sem Nome', style: GoogleFonts.inter(color: cs.onSurface, fontWeight: FontWeight.w500)),
                        subtitle: Text(option[ColsCrmZincao.contatoId] ?? '', style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 13)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: NotaTextField(
                controller: viewModel.documentoClienteCtrl,
                label: 'CPF/CNPJ',
                hint: 'Documento',
                icon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NotaTextField(
                controller: viewModel.telefoneClienteCtrl,
                label: 'Telefone',
                hint: '(00) 00000-0000',
                icon: Icons.phone_rounded,
                isMissing: missing.contains(CampoObrigatorio.telefoneCliente),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Dados da Nota ──
        _buildSectionTitle('Dados da Nota Fiscal', Icons.receipt_outlined),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: NotaTextField(
                controller: viewModel.numeroNotaCtrl,
                label: 'Número da Nota',
                hint: '000001',
                icon: Icons.numbers_rounded,
                isMissing: missing.contains(CampoObrigatorio.numeroNota),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NotaTextField(
                controller: viewModel.serieNotaCtrl,
                label: 'Série',
                hint: '1',
                isMissing: missing.contains(CampoObrigatorio.serieNota),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        NotaTextField(
          controller: viewModel.chaveNfeCtrl,
          label: 'Chave NFe',
          hint: 'Chave de acesso da nota fiscal',
          icon: Icons.vpn_key_rounded,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: NotaTextField(
                controller: viewModel.dataCompraCtrl,
                label: 'Data da Compra',
                hint: 'YYYY-MM-DD',
                icon: Icons.calendar_today_rounded,
                isMissing: missing.contains(CampoObrigatorio.dataCompra),
                readOnly: true,
                onTap: () => _selectDate(context, viewModel.dataCompraCtrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NotaTextField(
                controller: viewModel.dataPrevistaRetiradaCtrl,
                label: 'Previsão Retirada',
                hint: 'Opcional',
                icon: Icons.event_rounded,
                readOnly: true,
                onTap: () => _selectDate(context, viewModel.dataPrevistaRetiradaCtrl),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Valores ──
        _buildSectionTitle('Valor e Observações', Icons.attach_money_rounded),
        const SizedBox(height: 12),
        NotaTextField(
          controller: viewModel.valorTotalCtrl,
          label: 'Valor Total',
          hint: '0.00',
          icon: Icons.payments_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 14),
        NotaTextField(
          controller: viewModel.descontoCtrl,
          label: 'Valor do Desconto',
          hint: '0.00',
          icon: Icons.percent_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              _buildResumoLinha(context, 'Valor total', viewModel.valorTotalBruto),
              const SizedBox(height: 6),
              _buildResumoLinha(context, 'Desconto', viewModel.descontoTotalInformado),
              Divider(height: 16, color: cs.outlineVariant),
              _buildResumoLinha(context, 'Total com desconto', viewModel.valorTotalComDesconto, isHighlight: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NotaTextField(
          controller: viewModel.observacoesCtrl,
          label: 'Observações',
          hint: 'Anotações adicionais...',
          icon: Icons.notes_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
    });
  }

  Widget _buildResumoLinha(
    BuildContext context,
    String label,
    double valor, {
    bool isHighlight = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final textoValor = 'R\$ ${valor.toStringAsFixed(2)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          textoValor,
          style: GoogleFonts.inter(
            fontSize: isHighlight ? 15 : 13,
            color: isHighlight ? AppColors.primary : cs.onSurface,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController ctrl) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
              primary: AppColors.primary,
              surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      ctrl.text = date.toIso8601String().split('T').first;
    }
  }
}
