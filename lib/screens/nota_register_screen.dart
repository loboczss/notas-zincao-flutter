import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form_viewmodel.dart';
import 'package:notas_zincao_flutter/widgets/nova_nota/nota_form_fields.dart';
import 'package:notas_zincao_flutter/widgets/nova_nota/photo_capture.dart';
import 'package:notas_zincao_flutter/widgets/nova_nota/produtos_list.dart';
import 'package:notas_zincao_flutter/widgets/shared/app_error_feedback.dart';
import 'package:notas_zincao_flutter/widgets/shared/quota_error_dialog.dart';

/// Tela principal para cadastro de notas de retirada.
/// Fluxo: Foto → IA analisa → Preenche campos → Usuário valida → Salva
class NotaRegisterScreen extends StatefulWidget {
  final AuthViewModel authViewModel;

  const NotaRegisterScreen({super.key, required this.authViewModel});

  @override
  State<NotaRegisterScreen> createState() => _NotaRegisterScreenState();
}

class _NotaRegisterScreenState extends State<NotaRegisterScreen> {
  final NotaFormViewModel _viewModel = NotaFormViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});

    // Exibe erros via SnackBar
    if (_viewModel.status == NotaFormStatus.error && _viewModel.errorMessage != null) {
      AppErrorFeedback.show(
        context,
        message: _viewModel.errorMessage,
        fallbackMessage: 'Não foi possível salvar a nota.',
      );
    }

    // Exibe modal de quota esgotada
    if (_viewModel.status == NotaFormStatus.quotaExceeded && _viewModel.quotaExceeded) {
      QuotaErrorDialog.show(context).then((_) => _viewModel.clearQuotaError());
    }

    // Exibe sucesso
    if (_viewModel.status == NotaFormStatus.success) {
      _showSuccessDialog();
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBusy = _viewModel.status == NotaFormStatus.saving ||
        _viewModel.status == NotaFormStatus.uploadingImage;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Nova Nota de Retirada',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tire uma foto do cupom e a IA preencherá os dados.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Captura de Foto
            PhotoCapture(viewModel: _viewModel),
            const SizedBox(height: 24),

            // Campos do Formulário
            NotaFormFields(viewModel: _viewModel),
            const SizedBox(height: 24),

            // Lista de Produtos
            ProdutosList(viewModel: _viewModel),
            const SizedBox(height: 32),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isBusy ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: isBusy
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _viewModel.status == NotaFormStatus.uploadingImage
                                ? 'Enviando foto...'
                                : 'Salvando...',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Salvar Nota',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    final userId = widget.authViewModel.profile?.authUid;
    if (userId == null) {
      AppErrorFeedback.show(
        context,
        message: 'Usuário não autenticado',
        fallbackMessage: 'Sua sessão expirou. Faça login novamente.',
      );
      return;
    }

    _viewModel.saveNota(userId);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 40, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            Text(
              'Nota Salva!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A nota foi cadastrada com sucesso.',
              style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _viewModel.resetForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Cadastrar Outra',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
      },
    );
  }
}
