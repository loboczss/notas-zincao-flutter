import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';
import 'package:notas_zincao_flutter/viewmodels/retirada_form_viewmodel.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/multiple_photo_capture.dart';
import 'package:notas_zincao_flutter/widgets/shared/app_error_feedback.dart';

class RetiradaProdutosScreen extends StatefulWidget {
  final NotaRetirada nota;
  final AuthViewModel authViewModel;

  const RetiradaProdutosScreen({
    super.key,
    required this.nota,
    required this.authViewModel,
  });

  @override
  State<RetiradaProdutosScreen> createState() => _RetiradaProdutosScreenState();
}

class _RetiradaProdutosScreenState extends State<RetiradaProdutosScreen> {
  final _viewModel = RetiradaViewModel();
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _viewModel.init(widget.nota);
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    for (var c in _controllers.values) {
      c.dispose();
    }
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;

    // Sincroniza os controllers com o ViewModel
    _viewModel.quantidadesSelecionadas.forEach((index, value) {
      final controller = _controllers[index];
      if (controller != null) {
        final currentVal = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
        if ((currentVal - value).abs() > 0.001) {
          final newText = value == 0 ? '' : value.toString().replaceAll('.0', '');
          controller.text = newText;
          // Garante que o cursor fique no final
          controller.selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
        }
      }
    });

    if (_viewModel.status == RetiradaStatus.error && _viewModel.errorMessage != null) {
      AppErrorFeedback.show(
        context,
        message: _viewModel.errorMessage,
        fallbackMessage: 'Não foi possível registrar a retirada.',
      );
    } else if (_viewModel.status == RetiradaStatus.success) {
      _showSuccessDialog();
    } else {
      setState(() {});
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: AppColors.success, size: 64),
        content: Text(
          'Retirada registrada com sucesso!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 18),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // fecha dialog
                Navigator.of(context).pop(true); // volta para a tela anterior
              },
              child: Text('Voltar', style: TextStyle(color: colorScheme.onPrimary)),
            ),
          ),
        ],
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = _viewModel.status == RetiradaStatus.saving;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Fazer Retirada',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.nota.nomeCliente,
                          style: GoogleFonts.inter(fontSize: 18, color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Nota: ${widget.nota.numeroNota}',
                          style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Text('Selecione os produtos e as quantidades que o cliente está levando agora:',
                  style: GoogleFonts.inter(fontSize: 15, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),

                // Lista de Produtos com Stepper
                ...List.generate(widget.nota.produtos.length, (index) {
                  return _buildProductItem(index);
                }),
                
                const SizedBox(height: 24),
                MultiplePhotoCapture(viewModel: _viewModel),
                const SizedBox(height: 100), // Espaço pro botão
              ],
            ),
          ),
          
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: colorScheme.scrim.withValues(alpha: 0.54),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FloatingActionButton.extended(
            backgroundColor: _viewModel.isValidoParaConfirmar
                ? AppColors.primary
                : colorScheme.surfaceContainerHighest,
            foregroundColor: _viewModel.isValidoParaConfirmar
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            onPressed: isLoading
                ? null
                : () {
                    final userId = widget.authViewModel.profile?.id;
                    if (userId == null) {
                      AppErrorFeedback.show(
                        context,
                        message: 'Usuário não autenticado.',
                        fallbackMessage: 'Sua sessão expirou. Faça login novamente.',
                      );
                      return;
                    }
                    _viewModel.confirmarRetirada(userId);
                  },
            label: Text(
              'Confirmar Retirada',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.check),
          ),
        ),
      ),
    );
  }

  TextEditingController _getController(int index, double initialValue) {
    if (!_controllers.containsKey(index)) {
      _controllers[index] = TextEditingController(
        text: initialValue == 0 ? '' : initialValue.toString().replaceAll('.0', ''),
      );
    }
    return _controllers[index]!;
  }

  Widget _buildProductItem(int index) {
    final raw = widget.nota.produtos[index];
    if (raw is! Map) return const SizedBox.shrink();
    final p = Map<String, dynamic>.from(raw);
    final nome = p[ColsProdutoNota.nome] ?? 'Produto';
    final tipoUnidade = p[ColsProdutoNota.tipoUnidade] ?? 'UN';

    double qtdOriginal = double.tryParse(p[ColsProdutoNota.quantidade]?.toString() ?? '1') ?? 1.0;
    if (qtdOriginal <= 0) qtdOriginal = 1.0;

    final double qtdJaRetirada = double.tryParse(p[ColsProdutoNota.quantidadeRetirada]?.toString() ?? '0') ?? 0.0;
    final maxRetiravel = _viewModel.getQuantidadeMaxima(index);
    final isCompletamenteRetirado = _viewModel.isProdutoEntregue(index);
    final isSemEstoque = _viewModel.isSemEstoqueDisponivel(index);
    final estoqueDisponivel = _viewModel.estoqueDisponivelPorIndex[index];
    
    final qtdSelecionada = _viewModel.quantidadesSelecionadas[index] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompletamenteRetirado 
            ? AppColors.success.withValues(alpha: 0.1) 
            : isSemEstoque
                ? AppColors.warning.withValues(alpha: 0.10)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: isCompletamenteRetirado
              ? AppColors.success.withValues(alpha: 0.3)
              : isSemEstoque
                  ? AppColors.warning.withValues(alpha: 0.35)
                  : Colors.transparent
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Comprados: $qtdOriginal $tipoUnidade | Já retirados: $qtdJaRetirada $tipoUnidade', 
                    style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                if (estoqueDisponivel != null)
                  Text(
                    'Estoque disponível: ${estoqueDisponivel.toString().replaceAll('.0', '')} $tipoUnidade',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: estoqueDisponivel <= 0.001 ? AppColors.warning : AppColors.success,
                      fontWeight: estoqueDisponivel <= 0.001 ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (isCompletamenteRetirado)
            ...[
               const Icon(Icons.check_circle, color: AppColors.success),
               const SizedBox(width: 8),
               Text('Entregue', style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold))
            ]
          else if (isSemEstoque)
            ...[
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              SizedBox(
                width: 108,
                child: Text(
                  'Sem item no estoque',
                  style: GoogleFonts.inter(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ]
          else
            Row(
              children: [
                Tooltip(
                  message: 'Diminuir 0.1',
                  child: IconButton(
                    onPressed: maxRetiravel <= 0 ? null : () => _viewModel.decrementarQuantidade(index),
                    icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 40,
                  child: TextFormField(
                    controller: _getController(index, qtdSelecionada),
                    enabled: maxRetiravel > 0,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autocorrect: false,
                    enableSuggestions: false,
                    textAlign: TextAlign.center,
                    onChanged: (val) => _viewModel.setQuantidade(index, val),
                    style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant,
                              width: 0.5,
                            ),
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                        ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Aumentar 0.1',
                  child: IconButton(
                    onPressed: maxRetiravel <= 0 ? null : () => _viewModel.incrementarQuantidade(index),
                    icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
