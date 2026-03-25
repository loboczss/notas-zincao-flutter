import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';

class EstoqueProdutoService {
  static const int _pageSize = 1000;

  Future<List<ProdutoEstoque>> searchForNotePicker({
    String query = '',
    int limit = 30,
  }) {
    return fetchPagina(offset: 0, limite: limit, query: query);
  }

  Future<ProdutoEstoque?> fetchById(int idProduto) async {
    final resultados = await supabase
        .from('bd_estoque_geral')
        .select()
        .eq('IDPRODUTO', idProduto)
        .limit(1);

    if (resultados.isEmpty) return null;
    return ProdutoEstoque.fromMap(
      Map<String, dynamic>.from(resultados.first as Map),
    );
  }

  // ─── Paginação server-side (usada pela tela de estoque) ───────────────────

  /// Busca uma página de produtos no banco com filtro opcional por texto.
  /// [query] pesquisa por ID exato (quando numérico) ou por ILIKE em
  /// DESCRICAO e TIPOPRODUTO.
  Future<List<ProdutoEstoque>> fetchPagina({
    required int offset,
    required int limite,
    String query = '',
  }) async {
    final q = query.trim();

    if (q.isEmpty) {
      final raw = await supabase
          .from('bd_estoque_geral')
          .select()
          .order('DESCRICAO', ascending: true)
          .range(offset, offset + limite - 1);

      return raw
          .map((row) => ProdutoEstoque.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    }

    final idQ = int.tryParse(q);
    if (idQ != null) {
      final raw = await supabase
          .from('bd_estoque_geral')
          .select()
          .eq('IDPRODUTO', idQ)
          .order('DESCRICAO', ascending: true)
          .range(offset, offset + limite - 1);

      return raw
          .map((row) => ProdutoEstoque.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    }

    final searchText = _sanitizeSearchText(q);
    if (searchText.isEmpty) {
      return const [];
    }

    final descricaoRaw = await supabase
        .from('bd_estoque_geral')
        .select()
        .ilike('DESCRICAO', '%$searchText%')
        .order('DESCRICAO', ascending: true)
        .limit(limite);

    final tipoProdutoRaw = await supabase
        .from('bd_estoque_geral')
        .select()
        .ilike('TIPOPRODUTO', '%$searchText%')
        .order('DESCRICAO', ascending: true)
        .limit(limite);

    final agregados = <ProdutoEstoque>[];
    final ids = <int?>{};

    for (final row in [...descricaoRaw, ...tipoProdutoRaw]) {
      final produto = ProdutoEstoque.fromMap(Map<String, dynamic>.from(row as Map));
      if (ids.add(produto.idProduto)) {
        agregados.add(produto);
      }
      if (agregados.length >= limite) {
        break;
      }
    }

    return agregados;
  }

  String _sanitizeSearchText(String value) {
    return value
        .replaceAll(RegExp(r'[%(),]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ─── Carga completa (usada pelo catálogo do formulário de nota) ───────────

  /// Busca todos os registros da tabela usando paginação automática.
  Future<List<ProdutoEstoque>> fetchAll() async {
    final todos = <ProdutoEstoque>[];
    int offset = 0;

    while (true) {
      final pagina = await supabase
          .from('bd_estoque_geral')
          .select()
          .order('DESCRICAO', ascending: true)
          .range(offset, offset + _pageSize - 1);

      final lista = pagina as List;
      for (final row in lista) {
        todos.add(ProdutoEstoque.fromMap(Map<String, dynamic>.from(row as Map)));
      }

      if (lista.length < _pageSize) break;
      offset += _pageSize;
    }

    return todos;
  }

  Future<ProdutoEstoque> createProduto(ProdutoEstoque produto) async {
    final inserted = await supabase
        .from('bd_estoque_geral')
        .insert(produto.toMap())
        .select()
        .single();

    return ProdutoEstoque.fromMap(inserted);
  }

  Future<ProdutoEstoque> updateProduto(ProdutoEstoque produto) async {
    if (produto.idProduto != null) {
      final updated = await supabase
          .from('bd_estoque_geral')
          .update(produto.toMap())
          .eq('IDPRODUTO', produto.idProduto as Object)
          .select()
          .single();
      return ProdutoEstoque.fromMap(updated);
    }

    final updated = await supabase
        .from('bd_estoque_geral')
        .update(produto.toMap())
        .eq('DESCRICAO', produto.descricao)
        .eq('EMBALAGEMSAIDA', produto.embalagemSaida)
        .eq('TIPOPRODUTO', produto.tipoProduto ?? '')
        .select()
        .single();
    return ProdutoEstoque.fromMap(updated);
  }

  Future<Map<int, double>> fetchQuantidadesDisponiveis(List<int> idsProdutos) async {
    if (idsProdutos.isEmpty) return {};

    final response = await supabase
        .from('bd_estoque_geral')
        .select('IDPRODUTO, QUANTIDADEESTOQUE')
        .inFilter('IDPRODUTO', idsProdutos);

    final result = <int, double>{};
    for (final row in response as List) {
      final data = Map<String, dynamic>.from(row as Map);
      final id = data['IDPRODUTO'];
      final qtdRaw = data['QUANTIDADEESTOQUE'];
      if (id is int) {
        final qtd = qtdRaw is num
            ? qtdRaw.toDouble()
            : double.tryParse((qtdRaw ?? '0').toString().replaceAll(',', '.')) ?? 0;
        result[id] = qtd;
      }
    }
    return result;
  }

  Future<double> baixarEstoqueComFallback({
    required int idProduto,
    required double quantidadeSolicitada,
  }) async {
    try {
      final rpcResult = await supabase.rpc(
        'baixar_estoque_produto',
        params: {
          'p_id_produto': idProduto,
          'p_quantidade_solicitada': quantidadeSolicitada,
        },
      );

      if (rpcResult is Map<String, dynamic>) {
        final retirado = rpcResult['quantidade_retirada'];
        return retirado is num
            ? retirado.toDouble()
            : double.tryParse((retirado ?? '0').toString().replaceAll(',', '.')) ?? 0;
      }
    } catch (_) {}

    final registro = await supabase
        .from('bd_estoque_geral')
        .select('QUANTIDADEESTOQUE')
        .eq('IDPRODUTO', idProduto)
        .maybeSingle();

    if (registro == null) {
      return 0;
    }

    final qtdAtualRaw = registro['QUANTIDADEESTOQUE'];
    final qtdAtual = qtdAtualRaw is num
        ? qtdAtualRaw.toDouble()
        : double.tryParse((qtdAtualRaw ?? '0').toString().replaceAll(',', '.')) ?? 0;

    final qtdRetirada = quantidadeSolicitada <= qtdAtual ? quantidadeSolicitada : qtdAtual;
    final novoSaldo = qtdAtual - qtdRetirada;

    await supabase
        .from('bd_estoque_geral')
        .update({'QUANTIDADEESTOQUE': novoSaldo})
        .eq('IDPRODUTO', idProduto);

    return qtdRetirada;
  }
}