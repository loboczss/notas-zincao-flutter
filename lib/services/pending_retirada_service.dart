import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PendingRetiradaStatus {
  pending,
  failedMaxRetries;

  String get label {
    switch (this) {
      case PendingRetiradaStatus.pending:
        return 'Pendente';
      case PendingRetiradaStatus.failedMaxRetries:
        return 'Excedeu tentativas';
    }
  }

  static PendingRetiradaStatus fromItem(PendingRetiradaItem item) {
    return item.tentativas >= 3
        ? PendingRetiradaStatus.failedMaxRetries
        : PendingRetiradaStatus.pending;
  }
}

/// Representa uma operação de retirada que ainda não foi sincronizada com o Supabase.
class PendingRetiradaItem {
  final String id;
  final String notaId;
  final String userId;
  final String? userName;
  final String? userRole;

  /// Mapa de índice do produto → quantidade a retirar.
  final Map<int, double> quantidades;

  /// Caminhos locais das fotos comprovantes (persistidos no diretório de documentos).
  final List<String> fotosPaths;

  final DateTime timestamp;
  final int tentativas;
  final String? erro;

  PendingRetiradaItem({
    required this.id,
    required this.notaId,
    required this.userId,
    this.userName,
    this.userRole,
    required this.quantidades,
    required this.fotosPaths,
    required this.timestamp,
    this.tentativas = 0,
    this.erro,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'notaId': notaId,
        'userId': userId,
        'userName': userName,
        'userRole': userRole,
        'quantidades': quantidades.map((k, v) => MapEntry(k.toString(), v)),
        'fotosPaths': fotosPaths,
        'timestamp': timestamp.toIso8601String(),
        'tentativas': tentativas,
        'erro': erro,
      };

  factory PendingRetiradaItem.fromJson(Map<String, dynamic> json) {
    return PendingRetiradaItem(
      id: json['id'] as String,
      notaId: json['notaId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      userRole: json['userRole'] as String?,
      quantidades: (json['quantidades'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
      ),
      fotosPaths: List<String>.from(json['fotosPaths'] as List),
      timestamp: DateTime.parse(json['timestamp'] as String),
      tentativas: json['tentativas'] as int? ?? 0,
      erro: json['erro'] as String?,
    );
  }

  PendingRetiradaItem copyWith({int? tentativas, String? erro}) {
    return PendingRetiradaItem(
      id: id,
      notaId: notaId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      quantidades: quantidades,
      fotosPaths: fotosPaths,
      timestamp: timestamp,
      tentativas: tentativas ?? this.tentativas,
      erro: erro ?? this.erro,
    );
  }
}

/// Gerencia a fila de retiradas pendentes (offline) no SharedPreferences.
class PendingRetiradaService {
  static const _key = 'pending_retiradas_v1';
  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  Future<void> refreshCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    pendingCount.value = raw.length;
  }

  Future<List<PendingRetiradaItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    pendingCount.value = raw.length;
    return raw
        .map((s) =>
            PendingRetiradaItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(PendingRetiradaItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_key, raw);
    pendingCount.value = raw.length;
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final decoded = PendingRetiradaItem.fromJson(
          jsonDecode(s) as Map<String, dynamic>);
      return decoded.id == id;
    });
    await prefs.setStringList(_key, raw);
    pendingCount.value = raw.length;
  }

  Future<void> incrementTentativas(String id, String erro) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final updated = raw.map((s) {
      final item = PendingRetiradaItem.fromJson(
          jsonDecode(s) as Map<String, dynamic>);
      if (item.id == id) {
        return jsonEncode(
            item.copyWith(tentativas: item.tentativas + 1, erro: erro).toJson());
      }
      return s;
    }).toList();
    await prefs.setStringList(_key, updated);
    pendingCount.value = updated.length;
  }

  Future<bool> hasPending() async {
    final items = await getAll();
    return items.isNotEmpty;
  }

  Future<int> countPending() async {
    final items = await getAll();
    return items.length;
  }

  Future<List<PendingRetiradaItem>> filterByStatus(
      PendingRetiradaStatus status) async {
    final items = await getAll();
    return items
        .where((item) => PendingRetiradaStatus.fromItem(item) == status)
        .toList();
  }

  /// Remove um item da fila incluindo suas fotos persistidas.
  Future<void> deleteItem(String id) async {
    await deletePhotos(id);
    await remove(id);
  }

  /// Copia as fotos para o diretório de documentos do app (sobrevive a reinicializações).
  Future<List<String>> persistPhotos(List<File> fotos, String pendingId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder =
        Directory('${dir.path}/pending_retiradas/$pendingId');
    await folder.create(recursive: true);

    final paths = <String>[];
    for (int i = 0; i < fotos.length; i++) {
      final ext = fotos[i].path.contains('.')
          ? '.${fotos[i].path.split('.').last}'
          : '.jpg';
      final dest = '${folder.path}/foto_$i$ext';
      await fotos[i].copy(dest);
      paths.add(dest);
    }
    return paths;
  }

  /// Remove as fotos persistidas de um item da fila.
  Future<void> deletePhotos(String pendingId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder =
        Directory('${dir.path}/pending_retiradas/$pendingId');
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }
}
