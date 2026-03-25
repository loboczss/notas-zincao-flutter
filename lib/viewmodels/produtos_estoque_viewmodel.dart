import 'package:flutter/foundation.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/services/estoque_produto_service.dart';

/// ViewModel para a tela de gestão do estoque de produtos.
/// Usa paginação server-side com infinite scroll e busca por ILIKE no banco.
class ProdutosEstoqueViewModel extends ChangeNotifier {
  final EstoqueProdutoService _service = EstoqueProdutoService();

  static const int _limite = 50;

  final List<ProdutoEstoque> _produtos = [];
  String _query = '';
  int _offset = 0;
  bool _temMais = true;

  bool isLoading = false;
  bool isCarregandoMais = false;
  bool isSaving = false;
  String? erro;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<ProdutoEstoque> get produtos => List.unmodifiable(_produtos);
  String get query => _query;
  bool get temMais => _temMais;

  // ─── Carregamento inicial / refresh ───────────────────────────────────────

  Future<void> carregarProdutos() async {
    _offset = 0;
    _temMais = true;
    _produtos.clear();
    isLoading = true;
    erro = null;
    notifyListeners();

    try {
      final pagina = await _service.fetchPagina(
        offset: 0,
        limite: _limite,
        query: _query,
      );
      _produtos.addAll(pagina);
      _temMais = pagina.length >= _limite;
      _offset = pagina.length;
    } catch (e) {
      erro = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── Infinite scroll: próxima página ──────────────────────────────────────

  Future<void> carregarMais() async {
    if (isCarregandoMais || isLoading || !_temMais) return;

    isCarregandoMais = true;
    notifyListeners();

    try {
      final pagina = await _service.fetchPagina(
        offset: _offset,
        limite: _limite,
        query: _query,
      );
      _produtos.addAll(pagina);
      _temMais = pagina.length >= _limite;
      _offset += pagina.length;
    } catch (e) {
      erro = e.toString();
    } finally {
      isCarregandoMais = false;
      notifyListeners();
    }
  }

  // ─── Pesquisa (server-side via ILIKE) ─────────────────────────────────────

  Future<void> pesquisar(String query) async {
    if (_query == query) return;
    _query = query;
    await carregarProdutos();
  }

  Future<void> limparPesquisa() async {
    if (_query.isEmpty) return;
    _query = '';
    await carregarProdutos();
  }

  // ─── Mutações ─────────────────────────────────────────────────────────────

  Future<void> criarProduto(ProdutoEstoque produto) async {
    isSaving = true;
    erro = null;
    notifyListeners();

    try {
      await _service.createProduto(produto);
      await carregarProdutos();
    } catch (e) {
      erro = e.toString();
      isSaving = false;
      notifyListeners();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> editarProduto(ProdutoEstoque produto) async {
    isSaving = true;
    erro = null;
    notifyListeners();

    try {
      await _service.updateProduto(produto);
      await carregarProdutos();
    } catch (e) {
      erro = e.toString();
      isSaving = false;
      notifyListeners();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
