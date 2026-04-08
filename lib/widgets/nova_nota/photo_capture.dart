import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form_viewmodel.dart';

/// Widget de captura/seleção de foto do cupom fiscal.
/// Exibe um botão para câmera e galeria, e mostra o preview da foto selecionada.
class PhotoCapture extends StatelessWidget {
  final NotaFormViewModel viewModel;

  const PhotoCapture({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final image = viewModel.selectedImage;
    final isProcessing = viewModel.status == NotaFormStatus.pickingImage ||
        viewModel.status == NotaFormStatus.analyzingReceipt;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // Preview da imagem
          if (image != null) _buildImagePreview(image, isProcessing),

          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (image == null) ...[
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 48,
                    color: cs.onSurface.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Envie a foto do cupom fiscal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A IA vai preencher os dados automaticamente',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Câmera',
                        onTap: viewModel.capturePhoto,
                        isDisabled: isProcessing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeria',
                        onTap: viewModel.pickPhoto,
                        isDisabled: isProcessing,
                      ),
                    ),
                  ],
                ),
                if (image != null && !viewModel.aiProcessed) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing ? null : viewModel.analyzeWithAI,
                      icon: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 20),
                      label: Text(
                        isProcessing ? 'Analisando...' : 'Analisar com IA',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File image, bool isProcessing) {
    return Stack(
      children: [
        Builder(
          builder: (context) => InkWell(
            onTap: () => _showImagePreview(context, image),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.file(
                image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (isProcessing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Analisando cupom...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (viewModel.aiProcessed)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Analisado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Toque para ampliar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showImagePreview(BuildContext context, File image) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Image.file(image, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDisabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final fillColor = isDark ? Colors.white.withValues(alpha: 0.06) : cs.surface;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.10) : cs.outlineVariant;
    final enabledTextColor = isDark ? Colors.white70 : cs.onSurface;
    final disabledColor = isDark ? Colors.white38 : cs.onSurface.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isDisabled ? disabledColor : AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? disabledColor : enabledTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
