import 'package:notas_zincao_flutter/utils/parse_utils.dart' as parse;

class ProdutoEstoque {
  final int? idProduto;
  final String descricao;
  final String embalagemSaida;
  final String? tipoProduto;
  final double quantidadeEstoque;
  final double? valorPrecoVarejo;
  final int? idProdutoPai;
  final double? fatorConversao;

  const ProdutoEstoque({
    this.idProduto,
    required this.descricao,
    required this.embalagemSaida,
    this.tipoProduto,
    required this.quantidadeEstoque,
    this.valorPrecoVarejo,
    this.idProdutoPai,
    this.fatorConversao,
  });

  factory ProdutoEstoque.fromMap(Map<String, dynamic> map) {
    final idProdutoRaw = _firstNonNull(map, const ['IDPRODUTO', 'idproduto', 'id_produto']);
    final descricaoRaw = _firstNonNull(map, const ['DESCRICAO', 'descricao']);
    final embalagemRaw = _firstNonNull(
      map,
      const ['EMBALAGEMSAIDA', 'embalagamsaida', 'embalagemsaida', 'embalagem_saida', 'embalagem'],
    );
    final tipoProdutoRaw = _firstNonNull(map, const ['TIPOPRODUTO', 'tipoproduto', 'tipo_produto']);
    final quantidadeRaw = _firstNonNull(map, const ['QUANTIDADEESTOQUE', 'quantidadeestoque', 'quantidade_estoque']);
    final precoRaw = _firstNonNull(map, const ['VALPRECOVAREJO', 'valprecovarejo', 'val_preco_varejo']);
    final idPaiRaw = _firstNonNull(map, const ['IDPRODUTOPAI', 'idprodutopai', 'ID_PRODUTO_PAI', 'id_produto_pai']);
    final fatorRaw = _firstNonNull(map, const ['FATORCONVERSAO', 'fatorconversao', 'FATOR_CONVERSAO', 'fator_conversao']);

    return ProdutoEstoque(
      idProduto: _parseInt(idProdutoRaw),
      descricao: (descricaoRaw ?? '').toString(),
      embalagemSaida: (embalagemRaw ?? 'UN').toString(),
      tipoProduto: tipoProdutoRaw?.toString(),
      quantidadeEstoque: parse.parseDouble(quantidadeRaw),
      valorPrecoVarejo: precoRaw != null ? parse.parseDouble(precoRaw) : null,
      idProdutoPai: _parseInt(idPaiRaw),
      fatorConversao: fatorRaw != null ? parse.parseDouble(fatorRaw) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'DESCRICAO': descricao,
      'EMBALAGEMSAIDA': embalagemSaida,
      'TIPOPRODUTO': tipoProduto,
      'QUANTIDADEESTOQUE': quantidadeEstoque,
      'VALPRECOVAREJO': valorPrecoVarejo,
      'IDPRODUTOPAI': idProdutoPai,
      'FATORCONVERSAO': fatorConversao,
    };
    if (idProduto != null) {
      data['IDPRODUTO'] = idProduto;
    }
    data.removeWhere((key, value) => value == null);
    return data;
  }

  ProdutoEstoque copyWith({
    int? idProduto,
    String? descricao,
    String? embalagemSaida,
    String? tipoProduto,
    double? quantidadeEstoque,
    double? valorPrecoVarejo,
    int? idProdutoPai,
    double? fatorConversao,
  }) {
    return ProdutoEstoque(
      idProduto: idProduto ?? this.idProduto,
      descricao: descricao ?? this.descricao,
      embalagemSaida: embalagemSaida ?? this.embalagemSaida,
      tipoProduto: tipoProduto ?? this.tipoProduto,
      quantidadeEstoque: quantidadeEstoque ?? this.quantidadeEstoque,
      valorPrecoVarejo: valorPrecoVarejo ?? this.valorPrecoVarejo,
      idProdutoPai: idProdutoPai ?? this.idProdutoPai,
      fatorConversao: fatorConversao ?? this.fatorConversao,
    );
  }
}

dynamic _firstNonNull(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key) && map[key] != null) {
      return map[key];
    }
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}