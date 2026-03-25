import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

class HeaderNavTabs extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const HeaderNavTabs({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = colorScheme.surface;
    final border = colorScheme.outlineVariant;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNavItem(context, 0, 'Minhas Notas', Icons.receipt_long_rounded),
          _buildNavItem(context, 1, 'Nova Nota', Icons.add_box_outlined),
          _buildNavItem(context, 2, 'Estoque', Icons.inventory_2_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String label, IconData icon) {
    final isSelected = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final itemColor = isSelected ? AppColors.info : colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: itemColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: itemColor,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: 72,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.info : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
