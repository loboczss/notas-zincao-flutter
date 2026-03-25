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
    double parseDouble(dynamic value, {double fallback = 0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.')) ?? fallback;
    }

    return ProdutoEstoque(
      idProduto: (map['IDPRODUTO'] ?? map['idproduto']) as int?,
      descricao: (map['DESCRICAO'] ?? map['descricao'] ?? '').toString(),
      embalagemSaida: (map['EMBALAGEMSAIDA'] ?? map['embalagamsaida'] ?? map['embalagemsaida'] ?? map['embalagem'] ?? 'UN').toString(),
      tipoProduto: (map['TIPOPRODUTO'] ?? map['tipoproduto'])?.toString(),
      quantidadeEstoque: parseDouble(map['QUANTIDADEESTOQUE'] ?? map['quantidadeestoque']),
      valorPrecoVarejo: map['VALPRECOVAREJO'] != null
          ? parseDouble(map['VALPRECOVAREJO'])
          : (map['valprecovarejo'] != null ? parseDouble(map['valprecovarejo']) : null),
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