import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/viewmodels/product_stock_header_viewmodel.dart';

/// Widget minimalista para exibir o saldo do produto ID 10 no header.
class ProductHeaderStock extends StatefulWidget {
  const ProductHeaderStock({super.key});

  @override
  State<ProductHeaderStock> createState() => _ProductHeaderStockState();
}

class _ProductHeaderStockState extends State<ProductHeaderStock> {
  final _viewModel = ProductStockHeaderViewModel.instance;

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
    
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.product == null) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (_viewModel.error != null && _viewModel.product == null) {
          return const SizedBox.shrink();
        }

        final amount = _viewModel.stockAmount;
        final product = _viewModel.product;
        final unit = product?.embalagemSaida ?? 'M²';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.secondaryContainer.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'Saldo: $amount $unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
