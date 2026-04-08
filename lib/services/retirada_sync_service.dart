import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:notas_zincao_flutter/services/nota_retirada_service.dart';
import 'package:notas_zincao_flutter/services/pending_retirada_service.dart' show PendingRetiradaStatus, PendingRetiradaItem, PendingRetiradaService;
import 'package:notas_zincao_flutter/services/retirada_form_service.dart';

export 'package:notas_zincao_flutter/services/pending_retirada_service.dart' show PendingRetiradaStatus, PendingRetiradaItem;

class SyncRunResult {
  final int processados;
  final int sucesso;
  final int falhas;

  const SyncRunResult({
    required this.processados,
    required this.sucesso,
    required this.falhas,
  });
}

/// Processa a fila de retiradas offline e as envia ao Supabase quando há conexão.
class RetiradaSyncService {
  RetiradaSyncService._();
  static final RetiradaSyncService instance = RetiradaSyncService._();

  static const int _maxTentativas = 3;
  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);

  final PendingRetiradaService _pendingService = PendingRetiradaService();
  final RetiradaService _retiradaService = RetiradaService();
  final NotaRetiradaService _notaService = NotaRetiradaService();

  /// Verifica conectividade e, se online, processa a fila.
  Future<void> processarSeOnline() async {
    final result = await Connectivity().checkConnectivity();
    final isOffline = result.every((r) => r == ConnectivityResult.none);
    if (!isOffline) {
      await processar();
    }
  }

  Future<List<PendingRetiradaItem>> listarPendentes() {
    return _pendingService.getAll();
  }

  Future<List<PendingRetiradaItem>> listarPorStatus(PendingRetiradaStatus status) {
    return _pendingService.filterByStatus(status);
  }

  Future<void> deletarItem(String id) {
    return _pendingService.deleteItem(id);
  }

  Future<bool> processarItem(String id) async {
    if (isProcessing.value) return false;

    isProcessing.value = true;
    try {
      final items = await _pendingService.getAll();
      PendingRetiradaItem? item;
      for (final current in items) {
        if (current.id == id) {
          item = current;
          break;
        }
      }
      if (item == null) return false;

      return _processarItem(item, ignorarLimiteTentativas: true);
    } finally {
      isProcessing.value = false;
    }
  }

  /// Processa todos os itens pendentes da fila.
  /// Seguro para chamar múltiplas vezes — itens com falhas repetidas são ignorados.
  Future<void> processar() async {
    if (isProcessing.value) return;

    isProcessing.value = true;
    try {
      await processarComResumo();
    } finally {
      isProcessing.value = false;
    }
  }

  /// Executa sincronização manual e retorna resumo do processamento.
  Future<SyncRunResult> processarComResumo() async {
    final items = await _pendingService.getAll();
    if (items.isEmpty) {
      return const SyncRunResult(processados: 0, sucesso: 0, falhas: 0);
    }

    int processados = 0;
    int sucesso = 0;
    int falhas = 0;

    for (final item in items) {
      processados++;
      final ok = await _processarItem(item);
      if (ok) {
        sucesso++;
      } else {
        falhas++;
      }
    }

    return SyncRunResult(
      processados: processados,
      sucesso: sucesso,
      falhas: falhas,
    );
  }

  Future<bool> _processarItem(
    PendingRetiradaItem item, {
    bool ignorarLimiteTentativas = false,
  }) async {
    if (!ignorarLimiteTentativas && item.tentativas >= _maxTentativas) {
      return false;
    }

    try {
      // 1. Busca a nota atualizada do servidor
      final nota = await _notaService.getById(item.notaId);
      if (nota == null) {
        // Nota foi removida — descarta sem erro
        await _pendingService.deletePhotos(item.id);
        await _pendingService.remove(item.id);
        return true;
      }

      // 2. Upload das fotos locais para o Supabase Storage
      final arquivos = item.fotosPaths
          .map((p) => File(p))
          .where((f) => f.existsSync())
          .toList();
      final urls = await _retiradaService.uploadImages(arquivos, item.userId);

      // 3. Registra a retirada com os dados verificados pelo servidor (inclui RPC de estoque)
      await _retiradaService.registrarRetirada(
        nota: nota,
        quantidadesRetiradas: item.quantidades,
        comprovantesUrls: urls,
        userId: item.userId,
        userName: item.userName,
        userRole: item.userRole,
      );

      // 4. Limpeza após sync bem-sucedido
      await _pendingService.deletePhotos(item.id);
      await _pendingService.remove(item.id);
      return true;
    } catch (e) {
      await _pendingService.incrementTentativas(item.id, e.toString());
      return false;
    }
  }
}
