import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

class HeaderUserInfo extends StatelessWidget {
  final String? nome;
  final String? role;
  final String? fotoUrl;
  final VoidCallback onLogout;

  const HeaderUserInfo({
    super.key,
    this.nome,
    this.role,
    this.fotoUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: colorScheme.surface,
      onSelected: (value) {
        if (value == 'logout') {
          onLogout();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome ?? 'Usuário',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                role ?? 'Colaborador',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20, color: AppColors.error),
              const SizedBox(width: 12),
              Text(
                'Sair',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(19),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.info,
          backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl!) : null,
          child: fotoUrl == null
              ? Text(
                  (nome ?? 'U').substring(0, 1).toUpperCase(),
                  style: TextStyle(color: colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                )
              : null,
        ),
      ),
    );
  }
}
