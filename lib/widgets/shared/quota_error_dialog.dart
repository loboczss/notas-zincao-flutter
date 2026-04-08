import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

/// Modal exibido quando a cota da API OpenAI está esgotada (erro 429 quota).
/// Orienta o usuário a entrar em contato com o desenvolvedor.
class QuotaErrorDialog extends StatelessWidget {
  const QuotaErrorDialog({super.key});

  static const String _devContact = 'contato@loboczss.cloud';

  /// Exibe o modal via [showDialog].
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const QuotaErrorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A22) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              'IA temporariamente indisponível',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // Descrição
            Text(
              'O limite de uso da inteligência artificial foi atingido.\n\nEntre em contato com o desenvolvedor para reativar o serviço.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // E-mail copiável
            GestureDetector(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: _devContact));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'E-mail copiado!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _devContact,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botão OK
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Entendi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
