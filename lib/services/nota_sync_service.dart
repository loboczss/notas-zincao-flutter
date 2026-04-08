import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:notas_zincao_flutter/services/nota_form_service.dart';
import 'package:notas_zincao_flutter/services/pending_nota_service.dart';

class NotaSyncService {
  NotaSyncService._();
  static final NotaSyncService instance = NotaSyncService._();

  static const int _maxTentativas = 3;

  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);
  final PendingNotaService _pendingService = PendingNotaService();
  final NotaFormService _notaService = NotaFormService();

  Future<void> processarSeOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.every((r) => r == ConnectivityResult.none);
    if (!isOffline) {
      await processar();
    }
  }

  Future<void> processar() async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      final pendentes = await _pendingService.getAll();
      for (final item in pendentes) {
        if (item.tentativas >= _maxTentativas) continue;
        try {
          await _processarItem(item);
          await _pendingService.remove(item.id);
          await _pendingService.deletePersistedImage(item.fotoLocalPath);
        } catch (e) {
          await _pendingService.incrementTentativas(item.id, e.toString());
        }
      }
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _processarItem(PendingNotaItem item) async {
    String? fotoUrl;
    if (item.fotoLocalPath != null && item.fotoLocalPath!.isNotEmpty) {
      final file = File(item.fotoLocalPath!);
      if (await file.exists()) {
        fotoUrl = await _notaService.uploadImage(file, item.ownerUserId);
      }
    }

    await _notaService.upsertCrmContact(
      telefone: item.telefoneCliente ?? '',
      nome: item.nomeCliente,
    );

    await _notaService.createNota(
      ownerUserId: item.ownerUserId,
      nomeCliente: item.nomeCliente,
      numeroNota: item.numeroNota,
      dataCompra: DateTime.parse(item.dataCompraIso),
      fotoUrl: fotoUrl,
      documentoCliente: item.documentoCliente,
      telefoneCliente: item.telefoneCliente,
      serieNota: item.serieNota,
      chaveNfe: item.chaveNfe,
      dataPrevistaRetirada: item.dataPrevistaRetiradaIso == null
          ? null
          : DateTime.parse(item.dataPrevistaRetiradaIso!),
      produtos: item.produtos,
      valorTotal: item.valorTotal,
      descontoTotal: item.descontoTotal,
      observacoes: item.observacoes,
      contatoId: item.contatoId,
    );
  }
}
