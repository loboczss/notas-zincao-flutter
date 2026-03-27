import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/constants/db_schema.dart';
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
  final double? descontoTotal;
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
    this.descontoTotal,
    this.observacoes,
    required this.statusRetirada,
    this.dataRetirada,
    this.retiradaConfirmadaPor,
    this.comprovanteRetiradaUrl,
    required this.criadoEm,
  });

  factory NotaRetirada.fromMap(Map<String, dynamic> map) {
    return NotaRetirada(
      id: map[ColsNotasRetirada.id] as String,
      ownerUserId: map[ColsNotasRetirada.ownerUserId] as String,
      fotoUrl: map[ColsNotasRetirada.fotoUrl] as String?,
      nomeCliente: map[ColsNotasRetirada.nomeCliente] as String,
      documentoCliente: map[ColsNotasRetirada.documentoCliente] as String?,
      telefoneCliente: map[ColsNotasRetirada.telefoneCliente] as String?,
      numeroNota: map[ColsNotasRetirada.numeroNota] as String,
      serieNota: map[ColsNotasRetirada.serieNota] as String,
      chaveNfe: map[ColsNotasRetirada.chaveNfe] as String?,
      dataCompra: DateTime.parse(map[ColsNotasRetirada.dataCompra] as String),
      dataPrevistaRetirada: map[ColsNotasRetirada.dataPrevistaRetirada] != null
          ? DateTime.parse(map[ColsNotasRetirada.dataPrevistaRetirada] as String)
          : null,
      produtos: (map[ColsNotasRetirada.produtos] as List<dynamic>?) ?? const [],
      historicoRetiradas: map[ColsNotasRetirada.historicoRetiradas] as List<dynamic>?,
      valorTotal: map[ColsNotasRetirada.valorTotal] != null ? (map[ColsNotasRetirada.valorTotal] as num).toDouble() : null,
      descontoTotal: map[ColsNotasRetirada.descontoTotal] != null ? (map[ColsNotasRetirada.descontoTotal] as num).toDouble() : null,
      observacoes: map[ColsNotasRetirada.observacoes] as String?,
      statusRetirada: StatusRetirada.fromString(map[ColsNotasRetirada.statusRetirada] as String),
      dataRetirada: map[ColsNotasRetirada.dataRetirada] != null
          ? DateTime.parse(map[ColsNotasRetirada.dataRetirada] as String)
          : null,
      retiradaConfirmadaPor: map[ColsNotasRetirada.retiradaConfirmadaPor] as String?,
      comprovanteRetiradaUrl: map[ColsNotasRetirada.comprovanteRetiradaUrl] as String?,
      criadoEm: DateTime.parse(map[ColsNotasRetirada.criadoEm] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ColsNotasRetirada.id: id,
      ColsNotasRetirada.ownerUserId: ownerUserId,
      ColsNotasRetirada.fotoUrl: fotoUrl,
      ColsNotasRetirada.nomeCliente: nomeCliente,
      ColsNotasRetirada.documentoCliente: documentoCliente,
      ColsNotasRetirada.telefoneCliente: telefoneCliente,
      ColsNotasRetirada.numeroNota: numeroNota,
      ColsNotasRetirada.serieNota: serieNota,
      ColsNotasRetirada.chaveNfe: chaveNfe,
      ColsNotasRetirada.dataCompra: dataCompra.toIso8601String(),
      ColsNotasRetirada.dataPrevistaRetirada: dataPrevistaRetirada?.toIso8601String(),
      ColsNotasRetirada.produtos: produtos,
      ColsNotasRetirada.historicoRetiradas: historicoRetiradas,
      ColsNotasRetirada.valorTotal: valorTotal,
      ColsNotasRetirada.descontoTotal: descontoTotal,
      ColsNotasRetirada.observacoes: observacoes,
      ColsNotasRetirada.statusRetirada: statusRetirada.name,
      ColsNotasRetirada.dataRetirada: dataRetirada?.toIso8601String(),
      ColsNotasRetirada.retiradaConfirmadaPor: retiradaConfirmadaPor,
      ColsNotasRetirada.comprovanteRetiradaUrl: comprovanteRetiradaUrl,
      ColsNotasRetirada.criadoEm: criadoEm.toIso8601String(),
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
    double? descontoTotal,
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
      descontoTotal: descontoTotal ?? this.descontoTotal,
      observacoes: observacoes ?? this.observacoes,
      statusRetirada: statusRetirada ?? this.statusRetirada,
      dataRetirada: dataRetirada ?? this.dataRetirada,
      retiradaConfirmadaPor: retiradaConfirmadaPor ?? this.retiradaConfirmadaPor,
      comprovanteRetiradaUrl: comprovanteRetiradaUrl ?? this.comprovanteRetiradaUrl,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  double? get valorComDesconto {
    if (valorTotal == null) return null;
    final desconto = descontoTotal ?? 0;
    final liquido = valorTotal! - desconto;
    return liquido < 0 ? 0 : liquido;
  }
}
