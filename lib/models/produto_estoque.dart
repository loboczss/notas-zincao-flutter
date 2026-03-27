import 'package:notas_zincao_flutter/utils/parse_utils.dart' as parse;

class ProdutoEstoque {
  final int? idProduto;
  final String descricao;
  final String embalagemSaida;
  final String? tipoProduto;
  final double quantidadeEstoque;
  final double? valorPrecoVarejo;

  const ProdutoEstoque({
    this.idProduto,
    required this.descricao,
    required this.embalagemSaida,
    this.tipoProduto,
    required this.quantidadeEstoque,
    this.valorPrecoVarejo,
  });

  factory ProdutoEstoque.fromMap(Map<String, dynamic> map) {
    return ProdutoEstoque(
      idProduto: (map['IDPRODUTO'] ?? map['idproduto']) as int?,
      descricao: (map['DESCRICAO'] ?? map['descricao'] ?? '').toString(),
      embalagemSaida: (map['EMBALAGEMSAIDA'] ?? map['embalagamsaida'] ?? map['embalagemsaida'] ?? map['embalagem'] ?? 'UN').toString(),
      tipoProduto: (map['TIPOPRODUTO'] ?? map['tipoproduto'])?.toString(),
      quantidadeEstoque: parse.parseDouble(map['QUANTIDADEESTOQUE'] ?? map['quantidadeestoque']),
      valorPrecoVarejo: map['VALPRECOVAREJO'] != null
          ? parse.parseDouble(map['VALPRECOVAREJO'])
          : (map['valprecovarejo'] != null ? parse.parseDouble(map['valprecovarejo']) : null),
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'DESCRICAO': descricao,
      'EMBALAGEMSAIDA': embalagemSaida,
      'TIPOPRODUTO': tipoProduto,
      'QUANTIDADEESTOQUE': quantidadeEstoque,
      'VALPRECOVAREJO': valorPrecoVarejo,
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
  }) {
    return ProdutoEstoque(
      idProduto: idProduto ?? this.idProduto,
      descricao: descricao ?? this.descricao,
      embalagemSaida: embalagemSaida ?? this.embalagemSaida,
      tipoProduto: tipoProduto ?? this.tipoProduto,
      quantidadeEstoque: quantidadeEstoque ?? this.quantidadeEstoque,
      valorPrecoVarejo: valorPrecoVarejo ?? this.valorPrecoVarejo,
    );
  }
}