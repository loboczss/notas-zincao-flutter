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
    _produtos.add(_normalizarProdutoLivre(produto));
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
      _produtos[index] = _normalizarProdutoLivre(produto);
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

  Future<String?> validarProdutosAntesDeSalvar() async {
    for (var i = 0; i < _produtos.length; i++) {
      final produto = _normalizarProdutoLivre(_produtos[i]);
      final nome = (produto[ColsProdutoNota.nome] ?? '').toString().trim();
      if (nome.isEmpty) {
        return 'Produto na linha ${i + 1} sem nome. Corrija antes de salvar.';
      }

      try {
        _produtos[i] = await _vincularProdutoAoEstoque(produto);
      } catch (e) {
        return _mensagemProdutoNaoVinculado(nome);
      }
    }
    notifyListeners();
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
    final processados = <Map<String, dynamic>>[];
    for (final p in produtosDaIa) {
      final nome = (p[ColsProdutoNota.nome] ?? '').toString().trim();
      if (nome.isEmpty) continue;

      final normalizado = _normalizarProdutoLivre(p);
      try {
        processados.add(await _vincularProdutoAoEstoque(normalizado));
      } catch (_) {
        // Mantem item sem vinculo para o usuario corrigir manualmente antes de salvar.
        processados.add({
          ...normalizado,
          ColsProdutoNota.idProdutoEstoque: null,
        });
      }
    }
    return processados;
  }

  Future<Map<String, dynamic>> _vincularProdutoAoEstoque(
    Map<String, dynamic> produto,
  ) async {
    final normalizado = _normalizarProdutoLivre(produto);
    final idExistente = _parseIdProduto(normalizado[ColsProdutoNota.idProdutoEstoque]);

    ProdutoEstoque? produtoEstoque;
    if (idExistente != null) {
      produtoEstoque = await _estoqueService.fetchById(idExistente);
    }

    final nome = (normalizado[ColsProdutoNota.nome] ?? '').toString().trim();
    if (produtoEstoque == null && nome.isNotEmpty) {
      produtoEstoque = await findProdutoCatalogo(nome);
    }

    if (produtoEstoque == null) {
      throw StateError(_mensagemProdutoNaoVinculado(nome));
    }

    final idProduto = produtoEstoque.idProduto;
    if (idProduto == null) {
      throw StateError('Produto encontrado sem ID valido no estoque.');
    }

    return {
      ...normalizado,
      ColsProdutoNota.idProdutoEstoque: idProduto,
      ColsProdutoNota.nome: produtoEstoque.descricao,
      ColsProdutoNota.tipoProduto:
          (normalizado[ColsProdutoNota.tipoProduto] ?? produtoEstoque.tipoProduto),
      ColsProdutoNota.tipoUnidade:
          (normalizado[ColsProdutoNota.tipoUnidade] ?? produtoEstoque.embalagemSaida)
              .toString(),
      ColsProdutoNota.embalagem:
          (normalizado[ColsProdutoNota.embalagem] ?? produtoEstoque.embalagemSaida)
              .toString(),
    };
  }

  int? _parseIdProduto(dynamic rawId) {
    if (rawId is int) return rawId;
    if (rawId == null) return null;
    return int.tryParse(rawId.toString());
  }

  String _mensagemProdutoNaoVinculado(String nome) {
    return 'Produto "$nome" nao existe no estoque. Abra a tela de Estoque, cadastre esse produto e volte para vincular antes de salvar a nota.';
  }

  Map<String, dynamic> _normalizarProdutoLivre(Map<String, dynamic> produto) {
    final nome = (produto[ColsProdutoNota.nome] ?? '').toString().trim();
    final quantidade = toDouble(produto[ColsProdutoNota.quantidade]);
    final valorUnitario = toDouble(produto[ColsProdutoNota.valorUnitario]);
    final valorTotalInformado = toDouble(produto[ColsProdutoNota.valorTotal]);
    final totalCalculado = quantidade * valorUnitario;

    final total = valorTotalInformado > 0
        ? valorTotalInformado
        : double.parse(totalCalculado.toStringAsFixed(2));

    return {
      ...produto,
      ColsProdutoNota.idProdutoEstoque: produto[ColsProdutoNota.idProdutoEstoque],
      ColsProdutoNota.nome: nome,
      ColsProdutoNota.quantidade: quantidade,
      ColsProdutoNota.valorUnitario: valorUnitario,
      ColsProdutoNota.valorTotal: total,
      ColsProdutoNota.tipoUnidade:
          (produto[ColsProdutoNota.tipoUnidade] ?? produto[ColsProdutoNota.embalagem] ?? 'UN')
              .toString(),
      ColsProdutoNota.embalagem:
          (produto[ColsProdutoNota.embalagem] ?? produto[ColsProdutoNota.tipoUnidade] ?? 'UN')
              .toString(),
    };
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

}

