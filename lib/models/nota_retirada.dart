import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

/// Status possíveis para a retirada.
enum StatusRetirada {
  pendente,
  parcial,
  retirada,
  cancelada;

  static StatusRetirada fromString(String status) {
    return StatusRetirada.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => StatusRetirada.pendente,
    );
  }

  Color get color {
    switch (this) {
      case StatusRetirada.pendente:
        return AppColors.warning;
      case StatusRetirada.parcial:
        return AppColors.info;
      case StatusRetirada.retirada:
        return AppColors.success;
      case StatusRetirada.cancelada:
        return AppColors.error;
    }
  }

  String get label {
    switch (this) {
      case StatusRetirada.pendente:
        return 'Pendente';
      case StatusRetirada.parcial:
        return 'Parcial';
      case StatusRetirada.retirada:
        return 'Retirada';
      case StatusRetirada.cancelada:
        return 'Cancelada';
    }
  }
}

class NotaRetirada {
  final String id;
  final String ownerUserId;
  final String? fotoUrl;
  final String nomeCliente;
  final String? documentoCliente;
  final String? telefoneCliente;
  final String numeroNota;
  final String serieNota;
  final String? chaveNfe;
  final DateTime dataCompra;
  final DateTime? dataPrevistaRetirada;
  final List<dynamic> produtos;
  final List<dynamic>? historicoRetiradas;
  final double? valorTotal;
  final String? observacoes;
  final StatusRetirada statusRetirada;
  final DateTime? dataRetirada;
  final String? retiradaConfirmadaPor;
  final String? comprovanteRetiradaUrl;
  final DateTime criadoEm;

  const NotaRetirada({
    required this.id,
    required this.ownerUserId,
    this.fotoUrl,
    required this.nomeCliente,
    this.documentoCliente,
    this.telefoneCliente,
    required this.numeroNota,
    required this.serieNota,
    this.chaveNfe,
    required this.dataCompra,
    this.dataPrevistaRetirada,
    required this.produtos,
    this.historicoRetiradas,
    this.valorTotal,
    this.observacoes,
    required this.statusRetirada,
    this.dataRetirada,
    this.retiradaConfirmadaPor,
    this.comprovanteRetiradaUrl,
    required this.criadoEm,
  });

  factory NotaRetirada.fromMap(Map<String, dynamic> map) {
    return NotaRetirada(
      id: map['id'] as String,
      ownerUserId: map['owner_user_id'] as String,
      fotoUrl: map['foto_url'] as String?,
      nomeCliente: map['nome_cliente'] as String,
      documentoCliente: map['documento_cliente'] as String?,
      telefoneCliente: map['telefone_cliente'] as String?,
      numeroNota: map['numero_nota'] as String,
      serieNota: map['serie_nota'] as String,
      chaveNfe: map['chave_nfe'] as String?,
      dataCompra: DateTime.parse(map['data_compra'] as String),
      dataPrevistaRetirada: map['data_prevista_retirada'] != null 
          ? DateTime.parse(map['data_prevista_retirada'] as String) 
          : null,
      produtos: map['produtos'] as List<dynamic>,
      historicoRetiradas: map['historico_retiradas'] as List<dynamic>?,
      valorTotal: map['valor_total'] != null ? (map['valor_total'] as num).toDouble() : null,
      observacoes: map['observacoes'] as String?,
      statusRetirada: StatusRetirada.fromString(map['status_retirada'] as String),
      dataRetirada: map['data_retirada'] != null 
          ? DateTime.parse(map['data_retirada'] as String) 
          : null,
      retiradaConfirmadaPor: map['retirada_confirmada_por'] as String?,
      comprovanteRetiradaUrl: map['comprovante_retirada_url'] as String?,
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'foto_url': fotoUrl,
      'nome_cliente': nomeCliente,
      'documento_cliente': documentoCliente,
      'telefone_cliente': telefoneCliente,
      'numero_nota': numeroNota,
      'serie_nota': serieNota,
      'chave_nfe': chaveNfe,
      'data_compra': dataCompra.toIso8601String(),
      'data_prevista_retirada': dataPrevistaRetirada?.toIso8601String(),
      'produtos': produtos,
      'historico_retiradas': historicoRetiradas,
      'valor_total': valorTotal,
      'observacoes': observacoes,
      'status_retirada': statusRetirada.name,
      'data_retirada': dataRetirada?.toIso8601String(),
      'retirada_confirmada_por': retiradaConfirmadaPor,
      'comprovante_retirada_url': comprovanteRetiradaUrl,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  NotaRetirada copyWith({
    String? id,
    String? ownerUserId,
    String? fotoUrl,
    String? nomeCliente,
    String? documentoCliente,
    String? telefoneCliente,
    String? numeroNota,
    String? serieNota,
    String? chaveNfe,
    DateTime? dataCompra,
    DateTime? dataPrevistaRetirada,
    List<dynamic>? produtos,
    List<dynamic>? historicoRetiradas,
    double? valorTotal,
    String? observacoes,
    StatusRetirada? statusRetirada,
    DateTime? dataRetirada,
    String? retiradaConfirmadaPor,
    String? comprovanteRetiradaUrl,
    DateTime? criadoEm,
  }) {
    return NotaRetirada(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      nomeCliente: nomeCliente ?? this.nomeCliente,
      documentoCliente: documentoCliente ?? this.documentoCliente,
      telefoneCliente: telefoneCliente ?? this.telefoneCliente,
      numeroNota: numeroNota ?? this.numeroNota,
      serieNota: serieNota ?? this.serieNota,
      chaveNfe: chaveNfe ?? this.chaveNfe,
      dataCompra: dataCompra ?? this.dataCompra,
      dataPrevistaRetirada: dataPrevistaRetirada ?? this.dataPrevistaRetirada,
      produtos: produtos ?? this.produtos,
      historicoRetiradas: historicoRetiradas ?? this.historicoRetiradas,
      valorTotal: valorTotal ?? this.valorTotal,
      observacoes: observacoes ?? this.observacoes,
      statusRetirada: statusRetirada ?? this.statusRetirada,
      dataRetirada: dataRetirada ?? this.dataRetirada,
      retiradaConfirmadaPor: retiradaConfirmadaPor ?? this.retiradaConfirmadaPor,
      comprovanteRetiradaUrl: comprovanteRetiradaUrl ?? this.comprovanteRetiradaUrl,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
