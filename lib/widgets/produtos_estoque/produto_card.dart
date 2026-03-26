import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

/// Card que exibe as informações resumidas de um produto do estoque.
class ProdutoCard extends StatelessWidget {
  final ProdutoEstoque produto;
  final VoidCallback onEdit;
  final bool canEdit;

  const ProdutoCard({
    super.key,
    required this.produto,
    required this.onEdit,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Linha: badge ID + descrição ──
                Row(
                  children: [
                    if (produto.idProduto != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${produto.idProduto}',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        produto.descricao,
                        style: GoogleFonts.inter(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ── Linha: tipo + embalagem ──
                Text(
                  'Tipo: ${produto.tipoProduto ?? '-'}  •  Embalagem: ${produto.embalagemSaida}',
                  style: GoogleFonts.inter(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 2),

                // ── Linha: quantidade em estoque ──
                Text(
                  'Estoque: ${produto.quantidadeEstoque.toString().replaceAll(RegExp(r'\.0$'), '')} ${produto.embalagemSaida}',
                  style: GoogleFonts.inter(
                    color: produto.quantidadeEstoque > 0
                        ? AppColors.success
                        : AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (produto.valorPrecoVarejo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Preço varejo: R\$ ${produto.valorPrecoVarejo!.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.inter(
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            onPressed: canEdit ? onEdit : null,
            tooltip: canEdit ? 'Editar produto' : 'Somente admin pode editar',
            icon: Icon(
              canEdit ? Icons.edit_rounded : Icons.lock_outline_rounded,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
