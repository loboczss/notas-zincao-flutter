import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notas_zincao_flutter/constants/db_tables.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/services/estoque_produto_service.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ViewModel para o saldo do produto no header (Produto ID 10 por padrão).
class ProductStockHeaderViewModel extends ChangeNotifier {
  // Singleton pattern for easy access since it's used in the global header
  static final ProductStockHeaderViewModel instance = ProductStockHeaderViewModel._internal();
  ProductStockHeaderViewModel._internal() {
    _setupRealtimeSync();
  }

  final EstoqueProdutoService _service = EstoqueProdutoService();

  static const int productId = 10;
  static const Duration _realtimeRefreshDelay = Duration(milliseconds: 250);

  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeDebounce;

  ProdutoEstoque? _product;
  bool _isLoading = false;
  String? _error;

  ProdutoEstoque? get product => _product;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get stockAmount => _product?.quantidadeEstoque ?? 0;

  /// Registra um listener e retorna uma funcao para cleanup.
  ///
  /// Como este ViewModel e singleton, nao ha `dispose` automatico por rota.
  /// Use o callback retornado dentro do `dispose()` do widget consumidor.
  VoidCallback bindListener(VoidCallback listener) {
    addListener(listener);
    return () {
      removeListener(listener);
    };
  }

  Future<void> refreshStock() async {
    if (_isLoading) return;
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

  void _setupRealtimeSync() {
    if (_realtimeChannel != null) return;

    _realtimeChannel = supabase
        .channel('realtime:estoque:header_stock_vm')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: DbTables.estoqueGeral,
        callback: (payload) {
          final newId = int.tryParse((payload.newRecord['IDPRODUTO'] ?? payload.newRecord['idproduto'] ?? '').toString());
          final oldId = int.tryParse((payload.oldRecord['IDPRODUTO'] ?? payload.oldRecord['idproduto'] ?? '').toString());
          if (newId == productId || oldId == productId) {
            _scheduleRefreshFromRealtime();
          }
        },
      )
      ..subscribe();
  }

  void _scheduleRefreshFromRealtime() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(_realtimeRefreshDelay, refreshStock);
  }
}
