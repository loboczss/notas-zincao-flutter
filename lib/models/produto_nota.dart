import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/utils/parse_utils.dart' as parse;

/// Representa um item de produto dentro do array `produtos` de [NotaRetirada].
///
/// O banco armazena este objeto como JSON puro (`List<dynamic>`).
/// Use [ProdutoNota.fromMap] para desserializar e [toMap] para serializar.
class ProdutoNota {
  final int idProdutoEstoque;
  final String nome;
  final String? tipoProduto;
  final double quantidade;
  final double quantidadeRetirada;
  final String tipoUnidade;
  final String? embalagem;
  final double valorUnitario;
  final double valorTotal;

  const ProdutoNota({
    required this.idProdutoEstoque,
    required this.nome,
    this.tipoProduto,
    required this.quantidade,
    this.quantidadeRetirada = 0,
    required this.tipoUnidade,
    this.embalagem,
    required this.valorUnitario,
    required this.valorTotal,
  });

  factory ProdutoNota.fromMap(Map<String, dynamic> map) {
    return ProdutoNota(
      idProdutoEstoque: map[ColsProdutoNota.idProdutoEstoque] as int,
      nome: (map[ColsProdutoNota.nome] ?? '').toString(),
      tipoProduto: map[ColsProdutoNota.tipoProduto]?.toString(),
      quantidade: parse.parseDouble(map[ColsProdutoNota.quantidade], fallback: 1),
      quantidadeRetirada: parse.parseDouble(map[ColsProdutoNota.quantidadeRetirada]),
      tipoUnidade: (map[ColsProdutoNota.tipoUnidade] ?? map[ColsProdutoNota.embalagem] ?? 'UN').toString(),
      embalagem: map[ColsProdutoNota.embalagem]?.toString(),
      valorUnitario: parse.parseDouble(map[ColsProdutoNota.valorUnitario]),
      valorTotal: parse.parseDouble(map[ColsProdutoNota.valorTotal]),
    );
  }

  Map<String, dynamic> toMap() => {
        ColsProdutoNota.idProdutoEstoque: idProdutoEstoque,
        ColsProdutoNota.nome: nome,
        ColsProdutoNota.tipoProduto: tipoProduto,
        ColsProdutoNota.quantidade: quantidade,
        ColsProdutoNota.quantidadeRetirada: quantidadeRetirada,
        ColsProdutoNota.tipoUnidade: tipoUnidade,
        ColsProdutoNota.embalagem: embalagem,
        ColsProdutoNota.valorUnitario: valorUnitario,
        ColsProdutoNota.valorTotal: valorTotal,
      };

  /// Saldo ainda disponível para retirada nesta nota.
  double get saldoPendente {
    final saldo = quantidade - quantidadeRetirada;
    return saldo < 0 ? 0 : saldo;
  }

  bool get totalmenteRetirado => saldoPendente <= 0;

  ProdutoNota copyWith({
    int? idProdutoEstoque,
    String? nome,
    String? tipoProduto,
    double? quantidade,
    double? quantidadeRetirada,
    String? tipoUnidade,
    String? embalagem,
    double? valorUnitario,
    double? valorTotal,
  }) {
    return ProdutoNota(
      idProdutoEstoque: idProdutoEstoque ?? this.idProdutoEstoque,
      nome: nome ?? this.nome,
      tipoProduto: tipoProduto ?? this.tipoProduto,
      quantidade: quantidade ?? this.quantidade,
      quantidadeRetirada: quantidadeRetirada ?? this.quantidadeRetirada,
      tipoUnidade: tipoUnidade ?? this.tipoUnidade,
      embalagem: embalagem ?? this.embalagem,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      valorTotal: valorTotal ?? this.valorTotal,
    );
  }

  @override
  String toString() =>
      'ProdutoNota(id: $idProdutoEstoque, nome: $nome, qtd: $quantidade, retirado: $quantidadeRetirada)';
}
