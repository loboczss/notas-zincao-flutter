import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

class HeaderLogo extends StatelessWidget {
  const HeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.info],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset('public/logo-icone.png', width: 22, height: 22, fit: BoxFit.contain),
        ),
        const SizedBox(width: 8),
        Text(
          'Notas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
