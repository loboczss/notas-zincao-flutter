import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form_viewmodel.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/nota_details_sheet.dart';
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
  bool _isDuplicateDialogOpen = false;
  bool _isSuccessDialogOpen = false;
  bool _isHandlingSuccessAction = false;

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

    if (_viewModel.status == NotaFormStatus.duplicateFound &&
        _viewModel.notaDuplicada != null &&
        !_isDuplicateDialogOpen) {
      _showDuplicateNotaDialog();
    }

    // Exibe sucesso
    if (_viewModel.status == NotaFormStatus.success && !_isSuccessDialogOpen) {
      _showSuccessDialog();
    }
  }

  void _showDuplicateNotaDialog() {
    final nota = _viewModel.notaDuplicada;
    if (nota == null) return;

    _isDuplicateDialogOpen = true;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Nota já cadastrada',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _viewModel.duplicateReason ??
                    'Já existe uma nota com o mesmo número ou a mesma chave NFe.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(
                'Cliente: ${nota.nomeCliente}',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Número: ${nota.numeroNota} | Série: ${nota.serieNota}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  showNotaDetails(context, nota, widget.authViewModel);
                });
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Ver nota'),
            ),
          ],
        );
      },
    ).then((_) {
      _isDuplicateDialogOpen = false;
      if (mounted) {
        _viewModel.clearDuplicateFound();
      }
    });
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tire uma foto do cupom e a IA preencherá os dados.',
              style: TextStyle(
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Salvar Nota',
                        style: TextStyle(
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
    final syncPendente = _viewModel.syncPendente;
    _isSuccessDialogOpen = true;
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
                color: (syncPendente ? AppColors.warning : AppColors.success)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                syncPendente ? Icons.cloud_off_rounded : Icons.check_rounded,
                size: 40,
                color: syncPendente ? AppColors.warning : AppColors.success,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              syncPendente ? 'Nota salva offline!' : 'Nota Salva!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              syncPendente
                  ? 'Sem internet agora. Vamos sincronizar automaticamente quando a conexão voltar.'
                  : 'A nota foi cadastrada com sucesso.',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isHandlingSuccessAction
                    ? null
                    : () {
                  setState(() {
                    _isHandlingSuccessAction = true;
                  });
                  _viewModel.resetForm();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Cadastrar Outra',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
      },
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _isSuccessDialogOpen = false;
        _isHandlingSuccessAction = false;
      });
    });
  }
}
