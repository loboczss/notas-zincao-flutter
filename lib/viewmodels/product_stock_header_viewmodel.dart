import 'package:flutter/foundation.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/services/estoque_produto_service.dart';

/// ViewModel para o saldo do produto no header (Produto ID 10 por padrão).
class ProductStockHeaderViewModel extends ChangeNotifier {
  // Singleton pattern for easy access since it's used in the global header
  static final ProductStockHeaderViewModel instance = ProductStockHeaderViewModel._internal();
  ProductStockHeaderViewModel._internal();

  final EstoqueProdutoService _service = EstoqueProdutoService();
  
  static const int productId = 10;

  ProdutoEstoque? _product;
  bool _isLoading = false;
  String? _error;

  ProdutoEstoque? get product => _product;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get stockAmount => _product?.quantidadeEstoque ?? 0;

  Future<void> refreshStock() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProduct = await _service.fetchById(productId);
      if (updatedProduct != null) {
        _product = updatedProduct;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
