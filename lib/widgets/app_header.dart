import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/services/pending_retirada_service.dart';
import 'package:notas_zincao_flutter/theme/theme_controller.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';
import 'package:notas_zincao_flutter/widgets/header/header_logo.dart';
import 'package:notas_zincao_flutter/widgets/header/header_user_info.dart';
import 'package:notas_zincao_flutter/widgets/product_header_stock.dart';

/// Header principal que agora é composto por sub-componentes.
/// Implementa layout responsivo para evitar overflow em telas pequenas ou com longos inputs.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final AuthViewModel authViewModel;
  final VoidCallback? onTapPendencias;

  const AppHeader({
    super.key,
    required this.authViewModel,
    this.onTapPendencias,
  });

  @override
  Size get preferredSize => const Size.fromHeight(135);

  @override
  Widget build(BuildContext context) {
    final profile = authViewModel.profile;
    final colorScheme = Theme.of(context).colorScheme;
    final bg = colorScheme.surface;
    final border = colorScheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
            color: border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Tier 1: Logo + User Info ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: HeaderLogo()),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: PendingRetiradaService.pendingCount,
                        builder: (context, count, _) {
                          if (count <= 0) return const SizedBox.shrink();
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: onTapPendencias,
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cloud_off,
                                      size: 14,
                                      color: colorScheme.onErrorContainer,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$count pendente${count > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: colorScheme.onErrorContainer,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Alternar tema',
                        onPressed: ThemeController.instance.toggleTheme,
                        icon: Icon(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 22,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      HeaderUserInfo(
                        nome: profile?.nome,
                        role: profile?.role,
                        fotoUrl: profile?.fotoPerfil,
                        onLogout: () => authViewModel.signOut(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // ── Tier 2: Product Stock Highlight ──
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: ProductHeaderStock(),
            ),
          ],
        ),
      ),
    );
  }
}
