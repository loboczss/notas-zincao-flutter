import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/theme/theme_controller.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';
import 'package:notas_zincao_flutter/widgets/header/header_logo.dart';
import 'package:notas_zincao_flutter/widgets/header/header_user_info.dart';

/// Header principal que agora é composto por sub-componentes.
/// Implementa layout responsivo para evitar overflow em telas pequenas ou com longos inputs.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final AuthViewModel authViewModel;

  const AppHeader({
    super.key,
    required this.authViewModel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(74);

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: HeaderLogo()),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
      ),
    );
  }
}
