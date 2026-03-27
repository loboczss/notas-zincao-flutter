import 'package:flutter/foundation.dart';
import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/services/estoque_produto_service.dart';
import 'package:notas_zincao_flutter/utils/parse_utils.dart' as parse;

class NotaFormCatalogViewModel extends ChangeNotifier {
  final EstoqueProdutoService _estoqueService;

  NotaFormCatalogViewModel(this._estoqueService);

  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> get produtos => List.unmodifiable(_produtos);

  List<ProdutoEstoque> _produtosCatalogo = [];
  List<ProdutoEstoque> get produtosCatalogo => List.unmodifiable(_produtosCatalogo);

  bool _isLoadingProdutosCatalogo = false;
  bool get isLoadingProdutosCatalogo => _isLoadingProdutosCatalogo;

  void setProdutos(List<Map<String, dynamic>> produtos) {
    _produtos = List<Map<String, dynamic>>.from(produtos);
    notifyListeners();
  }

  void clearProdutos() {
    _produtos = [];
    notifyListeners();
  }

  Future<void> loadProdutosCatalogo() async {
    _isLoadingProdutosCatalogo = true;
    notifyListeners();

    try {
      _produtosCatalogo = await _estoqueService.searchForNotePicker(limit: 20);
    } catch (_) {
      _produtosCatalogo = [];
    } finally {
      _isLoadingProdutosCatalogo = false;
      notifyListeners();
    }
  }

  void addProduto(Map<String, dynamic> produto) {
    if (produto[ColsProdutoNota.idProdutoEstoque] == null) return;
    _produtos.add(produto);
    notifyListeners();
  }

  void removeProduto(int index) {
    if (index >= 0 && index < _produtos.length) {
      _produtos.removeAt(index);
      notifyListeners();
    }
  }

  void updateProduto(int index, Map<String, dynamic> produto) {
    if (index >= 0 && index < _produtos.length) {
      if (produto[ColsProdutoNota.idProdutoEstoque] == null) return;
      _produtos[index] = produto;
      notifyListeners();
    }
  }

  double toDouble(dynamic value) => parse.parseDouble(value);

  double calcularTotalProdutos([List<Map<String, dynamic>>? itens]) {
    final base = itens ?? _produtos;
    var total = 0.0;
    for (final item in base) {
      final quantidade = toDouble(item[ColsProdutoNota.quantidade]);
      final valorUnitario = toDouble(item[ColsProdutoNota.valorUnitario]);
      total += quantidade * valorUnitario;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  String? validarProdutosAntesDeSalvar() {
    if (_produtos.isEmpty) {
      return 'Adicione pelo menos 1 produto antes de salvar a nota.';
    }

    for (var i = 0; i < _produtos.length; i++) {
      final produto = _produtos[i];
      final quantidade = toDouble(produto[ColsProdutoNota.quantidade]);
      final valorUnitario = toDouble(produto[ColsProdutoNota.valorUnitario]);

      if (quantidade <= 0) {
        return 'A quantidade do produto ${i + 1} e invalida. Ajuste para um valor maior que zero.';
      }

      if (valorUnitario < 0) {
        return 'O valor unitario do produto ${i + 1} e invalido.';
      }

      final totalCalculado = double.parse((quantidade * valorUnitario).toStringAsFixed(2));
      produto[ColsProdutoNota.quantidade] = quantidade;
      produto[ColsProdutoNota.valorUnitario] = valorUnitario;
      produto[ColsProdutoNota.valorTotal] = totalCalculado;
    }

    return null;
  }

  Map<String, dynamic> buildProdutoNotaFromCatalogo({
    required ProdutoEstoque produto,
    required double quantidade,
    double? valorUnitario,
  }) {
    final valor = valorUnitario ?? produto.valorPrecoVarejo ?? 0;
    return {
      ColsProdutoNota.idProdutoEstoque: produto.idProduto,
      ColsProdutoNota.nome: produto.descricao,
      ColsProdutoNota.tipoProduto: produto.tipoProduto,
      ColsProdutoNota.quantidade: quantidade,
      ColsProdutoNota.embalagem: produto.embalagemSaida,
      ColsProdutoNota.tipoUnidade: produto.embalagemSaida,
      ColsProdutoNota.valorUnitario: valor,
      ColsProdutoNota.valorTotal: valor * quantidade,
    };
  }

  Future<List<ProdutoEstoque>> searchProdutosCatalogo(String query) {
    return _estoqueService.searchForNotePicker(query: query, limit: 30);
  }

  Future<ProdutoEstoque?> findProdutoCatalogoById(int idProduto) {
    return _estoqueService.fetchById(idProduto);
  }

  Future<ProdutoEstoque?> findProdutoCatalogo(String nome) async {
    final targetOriginal = _normalizeText(nome);
    final target = _normalizeProductQuery(targetOriginal);
    if (target.isEmpty) return null;

    final consultas = <String>[
      nome.trim(),
      target,
      ..._buildSearchCandidates(target),
    ].where((q) => q.trim().isNotEmpty).toSet().toList();

    final agregados = <ProdutoEstoque>[];
    for (final consulta in consultas.take(5)) {
      final resultados = await _estoqueService.searchForNotePicker(query: consulta, limit: 30);
      for (final item in resultados) {
        final exists = agregados.any((p) => p.idProduto == item.idProduto && p.idProduto != null);
        if (!exists) {
          agregados.add(item);
        }
      }
      if (agregados.length >= 30) break;
    }

    if (agregados.isEmpty) return null;

    for (final produto in agregados) {
      if (_normalizeText(produto.descricao) == target) {
        return produto;
      }
    }

    for (final produto in agregados) {
      final descricaoNorm = _normalizeText(produto.descricao);
      if (descricaoNorm.contains(target) || target.contains(descricaoNorm)) {
        return produto;
      }
    }

    final tokenAlvo = target.split(' ').where((t) => t.length >= 3).toSet();
    ProdutoEstoque? melhor;
    var melhorScore = -1;

    for (final produto in agregados) {
      final descricao = _normalizeText(produto.descricao);
      final tokensDescricao = descricao.split(' ').where((t) => t.length >= 3).toSet();
      var score = tokensDescricao.intersection(tokenAlvo).length;
      if (descricao.contains(target)) score += 3;
      if (target.contains(descricao)) score += 2;

      if (score > melhorScore) {
        melhor = produto;
        melhorScore = score;
      }
    }

    if (melhor != null && melhorScore > 0) {
      return melhor;
    }

    return agregados.first;
  }

  Future<List<Map<String, dynamic>>> filtrarProdutosDoCatalogo(
    List<Map<String, dynamic>> produtosDaIa,
  ) async {
    final validos = produtosDaIa
        .where((p) => (p[ColsProdutoNota.nome] ?? '').toString().trim().isNotEmpty)
        .toList();

    if (validos.isEmpty) return [];

    // Coleta todos os IDs candidatos sem tocar no banco
    final todosIds = <int>{};
    for (final p in validos) {
      final idDireto = p[ColsProdutoNota.idProdutoEstoque];
      final id = idDireto is int ? idDireto : int.tryParse((idDireto ?? '').toString());
      if (id != null) todosIds.add(id);
      todosIds.addAll(_extractCandidateProductIds((p[ColsProdutoNota.nome] ?? '').toString()));
    }

    // Uma única query para todos os IDs conhecidos
    final porId = <int, ProdutoEstoque>{};
    if (todosIds.isNotEmpty) {
      final resultados = await _estoqueService.fetchByIds(todosIds.toList());
      for (final prod in resultados) {
        if (prod.idProduto != null) porId[prod.idProduto!] = prod;
      }
    }

    // Resolve cada produto em paralelo — IDs saem do cache, nomes fazem 1 busca async
    Future<ProdutoEstoque?> resolver(Map<String, dynamic> p) {
      final nome = (p[ColsProdutoNota.nome] ?? '').toString().trim();

      final idDireto = p[ColsProdutoNota.idProdutoEstoque];
      final id = idDireto is int ? idDireto : int.tryParse((idDireto ?? '').toString());
      if (id != null && porId.containsKey(id)) return Future.value(porId[id]);

      for (final candidatoId in _extractCandidateProductIds(nome)) {
        final encontrado = porId[candidatoId];
        if (encontrado != null) return Future.value(encontrado);
      }

      return findProdutoCatalogo(nome);
    }

    final resolved = await Future.wait(validos.map(resolver));

    final itens = <Map<String, dynamic>>[];
    for (var i = 0; i < resolved.length; i++) {
      final produtoCatalogo = resolved[i];
      if (produtoCatalogo == null || produtoCatalogo.idProduto == null) continue;

      final produtoIa = validos[i];
      final quantidade = double.tryParse(
            (produtoIa[ColsProdutoNota.quantidade] ?? '1').toString().replaceAll(',', '.'),
          ) ??
          1;

      itens.add(buildProdutoNotaFromCatalogo(
        produto: produtoCatalogo,
        quantidade: quantidade <= 0 ? 1 : quantidade,
        valorUnitario: produtoCatalogo.valorPrecoVarejo ?? 0,
      ));
    }

    return itens;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeProductQuery(String value) {
    final base = value
        .replaceAll(RegExp(r'^\d+([.,]\d+)?\s*'), '')
        .replaceAll(RegExp(r'\b(un|und|pc|pcs|cx|kit)\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return base.isEmpty ? value : base;
  }

  List<String> _buildSearchCandidates(String normalized) {
    final tokens = normalized
        .split(' ')
        .map((t) => t.trim())
        .where((t) => t.length >= 3)
        .where((t) => !{'com', 'para', 'de', 'da', 'do', 'e'}.contains(t))
        .toList();

    final candidatos = <String>[];
    if (tokens.length >= 2) {
      candidatos.add(tokens.take(2).join(' '));
    }
    if (tokens.length >= 3) {
      candidatos.add(tokens.take(3).join(' '));
    }
    candidatos.addAll(tokens.take(3));
    return candidatos;
  }

  List<int> _extractCandidateProductIds(String nome) {
    final ids = <int>[];
    final matches = RegExp(r'\b(?:id|cod|codigo|produto)\s*[:#-]?\s*(\d{2,})\b', caseSensitive: false)
        .allMatches(nome);

    for (final match in matches) {
      final id = int.tryParse(match.group(1) ?? '');
      if (id != null && !ids.contains(id)) {
        ids.add(id);
      }
    }

    return ids;
  }
}
