import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/constants/db_tables.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class EstoqueProdutoService {
  static const int _pageSize = 1000;
  static const String _cacheKey = 'estoque_produtos_cache_v2';
  static const int _cacheSchemaVersion = 2;
  static const int _maxCacheSize = 5000;  // Limite para evitar OOM
  static const int _maxFetchAllRecords = 50000;  // Limite em fetchAll()

  Future<List<ProdutoEstoque>> searchForNotePicker({
    String query = '',
    int limit = 30,
  }) {
    return fetchPagina(offset: 0, limite: limit, query: query);
  }

  Future<ProdutoEstoque?> fetchById(int idProduto) async {
    try {
      final resultados = await supabase
          .from(DbTables.estoqueGeral)
          .select()
          .eq(ColsEstoqueGeral.idProduto, idProduto)
          .limit(1);

      if (resultados.isEmpty) return null;
      final produto = ProdutoEstoque.fromMap(
        Map<String, dynamic>.from(resultados.first as Map),
      );
      await _upsertCache([produto]);
      return produto;
    } on Exception catch (e) {
      debugPrint('EstoqueProduto.fetchById($idProduto): erro ao buscar - $e');
      final local = await _loadCache();
      for (final p in local) {
        if (p.idProduto == idProduto) return p;
      }
      return null;
    }
  }

  /// Busca múltiplos produtos por ID com chunking para evitar queries gigantes.
  /// P6: Divide em chunks (máx 100 IDs por request)
  Future<List<ProdutoEstoque>> fetchByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    
    const maxIdsPerQuery = 100;
    final chunks = <List<int>>[];
    
    for (int i = 0; i < ids.length; i += maxIdsPerQuery) {
      chunks.add(ids.sublist(i, min(i + maxIdsPerQuery, ids.length)));
    }
    
    final allProdutos = <ProdutoEstoque>[];
    
    try {
      for (final chunk in chunks) {
        final raw = await supabase
            .from(DbTables.estoqueGeral)
            .select()
            .inFilter(ColsEstoqueGeral.idProduto, chunk);
        final produtos = (raw as List)
            .map((row) => ProdutoEstoque.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();
        allProdutos.addAll(produtos);
      }
      
      await _upsertCache(allProdutos);
      return allProdutos;
    } on Exception catch (e) {
      debugPrint('EstoqueProduto.fetchByIds: erro ao buscar ${ids.length} produtos em ${chunks.length} chunks - $e');
      final local = await _loadCache();
      final wanted = ids.toSet();
      return local.where((p) => p.idProduto != null && wanted.contains(p.idProduto)).toList();
    }
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
    try {
      if (q.isEmpty) {
        final raw = await supabase
            .from(DbTables.estoqueGeral)
            .select()
            .order(ColsEstoqueGeral.descricao, ascending: true)
            .range(offset, offset + limite - 1);

        final produtos = raw
            .map((row) => ProdutoEstoque.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();
        await _upsertCache(produtos);
        return produtos;
      }

      final idQ = int.tryParse(q);
      if (idQ != null) {
        final raw = await supabase
            .from(DbTables.estoqueGeral)
            .select()
            .eq(ColsEstoqueGeral.idProduto, idQ)
            .order(ColsEstoqueGeral.descricao, ascending: true)
            .range(offset, offset + limite - 1);

        final produtos = raw
            .map((row) => ProdutoEstoque.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();
        await _upsertCache(produtos);
        return produtos;
      }

      final searchText = _sanitizeSearchText(q);
      if (searchText.isEmpty) return const [];

      // P2: Usar OR em vez de N+1 queries separadas
      final raw = await supabase
          .from(DbTables.estoqueGeral)
          .select()
          .or('${ColsEstoqueGeral.descricao}.ilike.%$searchText%, '
              '${ColsEstoqueGeral.tipoProduto}.ilike.%$searchText%')
          .order(ColsEstoqueGeral.descricao, ascending: true)
          .limit(limite);

      final produtos = (raw as List)
          .map((row) => ProdutoEstoque.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();

      await _upsertCache(produtos);
      return produtos;
    } on Exception catch (e) {
      debugPrint('EstoqueProduto.fetchPagina: erro ao buscar com query "$q" - $e');
      final local = await _loadCache();
      return _searchLocal(local, query: q, offset: offset, limite: limite);
    }
  }

  String _sanitizeSearchText(String value) {
    // P9: Apenas normalizar espaços - deixar Supabase fazer o escaping em ILIKE
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ─── Carga completa (usada pelo catálogo do formulário de nota) ───────────

  /// Busca todos os registros da tabela usando paginação automática.
  /// P3: Adiciona limite de 50k registros para evitar timeout
  Future<List<ProdutoEstoque>> fetchAll() async {
    final todos = <ProdutoEstoque>[];
    int offset = 0;

    try {
      while (true) {
        if (todos.length >= _maxFetchAllRecords) {
          debugPrint('EstoqueProduto.fetchAll: limite de $_maxFetchAllRecords registros atingido');
          break;
        }

        final pagina = await supabase
            .from(DbTables.estoqueGeral)
            .select()
            .order(ColsEstoqueGeral.descricao, ascending: true)
            .range(offset, offset + _pageSize - 1);

        final lista = pagina as List;
        for (final row in lista) {
          todos.add(ProdutoEstoque.fromMap(Map<String, dynamic>.from(row as Map)));
        }

        if (lista.length < _pageSize) break;
        offset += _pageSize;
      }

      await _saveAllCache(todos);
      return todos;
    } on Exception catch (e) {
      debugPrint('EstoqueProduto.fetchAll: erro ao carregar produtos - $e');
      return _loadCache();
    }
  }

  Future<ProdutoEstoque> createProduto(ProdutoEstoque produto) async {
    final inserted = await supabase
        .from(DbTables.estoqueGeral)
        .insert(produto.toMap())
        .select()
        .single();

    return ProdutoEstoque.fromMap(inserted);
  }

  Future<ProdutoEstoque> updateProduto(
    ProdutoEstoque produto, {
    int? idProdutoReferencia,
  }) async {
    final idRef = idProdutoReferencia ?? produto.idProduto;
    if (idRef != null) {
      final updated = await supabase
          .from(DbTables.estoqueGeral)
          .update(produto.toMap())
          .eq(ColsEstoqueGeral.idProduto, idRef)
          .select()
          .single();
      return ProdutoEstoque.fromMap(updated);
    }

    final updated = await supabase
        .from(DbTables.estoqueGeral)
        .update(produto.toMap())
        .eq(ColsEstoqueGeral.descricao, produto.descricao)
        .eq(ColsEstoqueGeral.embalagemSaida, produto.embalagemSaida)
        .eq(ColsEstoqueGeral.tipoProduto, produto.tipoProduto ?? '')
        .select()
        .single();
    return ProdutoEstoque.fromMap(updated);
  }

  Future<Map<int, double>> fetchQuantidadesDisponiveis(List<int> idsProdutos) async {
    if (idsProdutos.isEmpty) return {};

    final response = await supabase
        .from(DbTables.estoqueGeral)
        .select('${ColsEstoqueGeral.idProduto}, ${ColsEstoqueGeral.quantidadeEstoque}')
        .inFilter(ColsEstoqueGeral.idProduto, idsProdutos);

    final result = <int, double>{};
    for (final row in response as List) {
      final data = Map<String, dynamic>.from(row as Map);
      final id = data[ColsEstoqueGeral.idProduto];
      final qtdRaw = data[ColsEstoqueGeral.quantidadeEstoque];
      if (id is int) {
        final qtd = qtdRaw is num
            ? qtdRaw.toDouble()
            : double.tryParse((qtdRaw ?? '0').toString().replaceAll(',', '.')) ?? 0;
        result[id] = qtd;
      }
    }
    return result;
  }

  /// Baixa estoque com idempotency key para evitar duplicatas em retries.
  /// P8: Adiciona idempotency para prevenir debits duplicados em falhas de rede
  Future<double> baixarEstoque({
    required int idProduto,
    required double quantidadeSolicitada,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? Uuid().v4();
    
    try {
      dynamic rpcResult;
      try {
        rpcResult = await supabase.rpc(
          RpcFunctions.baixarEstoqueProduto,
          params: {
            'p_id_produto': idProduto,
            'p_quantidade_solicitada': quantidadeSolicitada,
            'p_idempotency_key': key,
          },
        );
      } on Exception catch (e) {
        // Compatibilidade: alguns ambientes ainda possuem a assinatura antiga da RPC.
        if (!_isRpcWithoutIdempotencyKey(e)) rethrow;

        debugPrint(
          'EstoqueProduto.baixarEstoque: RPC sem suporte a p_idempotency_key; usando assinatura legada.'
        );
        rpcResult = await supabase.rpc(
          RpcFunctions.baixarEstoqueProduto,
          params: {
            'p_id_produto': idProduto,
            'p_quantidade_solicitada': quantidadeSolicitada,
          },
        );
      }

      return _parseQuantidadeRetiradaRpc(rpcResult);
    } on Exception catch (e) {
      debugPrint('EstoqueProduto.baixarEstoque($idProduto, $quantidadeSolicitada): erro - $e');
      rethrow;
    }
  }

  bool _isRpcWithoutIdempotencyKey(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('p_idempotency_key') ||
        (msg.contains('baixar_estoque_produto') &&
            (msg.contains('does not exist') || msg.contains('nao existe') || msg.contains('não existe')));
  }

  /// P10: Parse com schema validation en vez de recursão frágil
  double _parseQuantidadeRetiradaRpc(dynamic rpcResult) {
    if (rpcResult == null) {
      throw FormatException('RPC retornou null - esperado quantidade numérica');
    }

    // Alguns ambientes retornam lista (ex.: setof/recordset). Usa o primeiro item.
    if (rpcResult is List) {
      if (rpcResult.isEmpty) {
        throw FormatException('RPC retornou lista vazia - esperado quantidade numérica');
      }
      return _parseQuantidadeRetiradaRpc(rpcResult.first);
    }

    // Caso simples: retornou um número diretamente
    if (rpcResult is num) return rpcResult.toDouble();

    // Caso String: tentar parsear
    if (rpcResult is String) {
      final parsed = _parseFlexibleDouble(rpcResult);
      if (parsed != null) return parsed;
      throw FormatException('RPC retornou string não-numérica: "$rpcResult"');
    }

    // Caso Map: procurar campo esperado com validação
    if (rpcResult is Map) {
      final map = Map<String, dynamic>.from(rpcResult);
      
      // Tentar campos padrões em ordem de preferência
      final candidates = [
        map['quantidade_retirada'],
        map['retirado'],
        map['value'],
      ];

      for (final value in candidates) {
        if (value != null) {
          final parsed = _parseFlexibleDouble(value);
          if (parsed != null) return parsed;
        }
      }
      
      throw FormatException(
        'Campo "quantidade_retirada" obrigatório no RPC. Recebido: ${map.keys.join(", ")}'
      );
    }

    throw FormatException(
      'RPC retornou tipo inesperado: ${rpcResult.runtimeType}. Esperado: num, String, Map ou List'
    );
  }

  double? _parseFlexibleDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    var text = value.toString().trim();
    if (text.isEmpty) return null;

    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(text);
  }

  /// P7: Salva cache com versionamento de schema
  Future<void> _saveAllCache(List<ProdutoEstoque> produtos) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(produtos.map((p) => p.toMap()).toList());
    await prefs.setString(_cacheKey, payload);
    await prefs.setInt('${_cacheKey}_schema_version', _cacheSchemaVersion);
  }

  /// P5: Carrega cache inteiro apenas se necessário, com limite de tamanho
  Future<void> _upsertCache(List<ProdutoEstoque> produtos) async {
    if (produtos.isEmpty) return;

    final existentes = await _loadCache();
    
    // P5: Se vai exceder limite, limpar e resalvar apenas novos
    if (existentes.length + produtos.length > _maxCacheSize) {
      debugPrint('EstoqueProduto._upsertCache: limit atingido (${existentes.length} + ${produtos.length} > $_maxCacheSize), limpando cache');
      await _saveAllCache(produtos);
      return;
    }

    final byId = <String, ProdutoEstoque>{
      for (final p in existentes) _cacheIdFor(p): p,
    };
    for (final p in produtos) {
      byId[_cacheIdFor(p)] = p;
    }

    final merged = byId.values.toList()
      ..sort((a, b) => a.descricao.toLowerCase().compareTo(b.descricao.toLowerCase()));
    await _saveAllCache(merged);
  }

  /// P7: Carrega com validação de schema version
  Future<List<ProdutoEstoque>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt('${_cacheKey}_schema_version') ?? 0;
    
    // Se schema está desatualizado, limpar cache
    if (version != _cacheSchemaVersion) {
      debugPrint('EstoqueProduto._loadCache: schema v$version != v$_cacheSchemaVersion, limpando cache');
      await prefs.remove(_cacheKey);
      await prefs.remove('${_cacheKey}_schema_version');
      return const [];
    }

    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((row) => ProdutoEstoque.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } on Exception catch (e) {
      debugPrint('EstoqueProduto._loadCache: erro ao desserializar - $e');
      return const [];
    }
  }

  List<ProdutoEstoque> _searchLocal(
    List<ProdutoEstoque> base, {
    required String query,
    required int offset,
    required int limite,
  }) {
    final sorted = [...base]
      ..sort((a, b) => a.descricao.toLowerCase().compareTo(b.descricao.toLowerCase()));

    final q = query.trim();
    List<ProdutoEstoque> filtered;

    if (q.isEmpty) {
      filtered = sorted;
    } else {
      final idQ = int.tryParse(q);
      if (idQ != null) {
        filtered = sorted.where((p) => p.idProduto == idQ).toList();
      } else {
        final s = _sanitizeSearchText(q).toLowerCase();
        if (s.isEmpty) return const [];
        filtered = sorted.where((p) {
          final desc = p.descricao.toLowerCase();
          final tipo = (p.tipoProduto ?? '').toLowerCase();
          return desc.contains(s) || tipo.contains(s);
        }).toList();
      }
    }

    if (offset >= filtered.length) return const [];
    final end = (offset + limite) > filtered.length ? filtered.length : (offset + limite);
    return filtered.sublist(offset, end);
  }

  /// P4: Gera cache ID com hash para evitar colisões em campos compostos
  String _cacheIdFor(ProdutoEstoque p) {
    // Se tem ID primário, usar diretamente
    if (p.idProduto != null) return 'id:${p.idProduto}';
    
    // Para produtos sem ID, gerar hash determinístico dos campos únicos
    final desc = p.descricao.trim().toLowerCase();
    final emb = p.embalagemSaida.trim().toLowerCase();
    final tipo = (p.tipoProduto ?? '').trim().toLowerCase();
    final combined = '$desc|$emb|$tipo';
    
    // Usar hashCode convertido para string positiva (remove possível sinal negativo)
    final hash = combined.hashCode.abs().toString();
    return 'hash:$hash';
  }

}
