import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/viewmodels/produtos_estoque_viewmodel.dart';
import 'package:notas_zincao_flutter/viewmodels/product_stock_header_viewmodel.dart';

/// Widget minimalista para exibir o saldo do produto ID 10 no header.
class ProductHeaderStock extends StatefulWidget {
  const ProductHeaderStock({super.key});

  @override
  State<ProductHeaderStock> createState() => _ProductHeaderStockState();
}

class _ProductHeaderStockState extends State<ProductHeaderStock> {
  final _viewModel = ProductStockHeaderViewModel.instance;
  bool _isRefreshingAll = false;

  Future<void> _refreshAllStockData() async {
    if (_isRefreshingAll) return;
    setState(() => _isRefreshingAll = true);

    try {
      await Future.wait([
        _viewModel.refreshStock(),
        ProdutosEstoqueViewModel.refreshAllInstances(),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estoque atualizado com sucesso.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao atualizar estoque. Tente novamente.'),
          duration: Duration(milliseconds: 1600),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshingAll = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Carrega o estoque inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_viewModel.product == null) {
        _viewModel.refreshStock();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.product == null) {
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final product = _viewModel.product;
        if (product == null) return const SizedBox.shrink();

        final amount = _viewModel.stockAmount;
        final unit = product.embalagemSaida;
        final name = product.descricao;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [
                      colorScheme.primary.withValues(alpha: 0.15), 
                      colorScheme.primary.withValues(alpha: 0.05)
                    ]
                  : [
                      colorScheme.primary.withValues(alpha: 0.1), 
                      colorScheme.primary.withValues(alpha: 0.02)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ícone Estilizado
              IgnorePointer(
                ignoring: _isRefreshingAll,
                child: InkWell(
                  onTap: _refreshAllStockData,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      _isRefreshingAll ? Icons.sync : Icons.inventory_2_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Informações do Produto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PRODUTO EM DESTAQUE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Divisor vertical sutil
              Container(
                height: 28,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0),
                      colorScheme.primary.withValues(alpha: 0.3),
                      colorScheme.primary.withValues(alpha: 0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Container do Saldo
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DISPONÍVEL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        amount.toString().replaceAll(RegExp(r'\.0$'), ''),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        unit.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
