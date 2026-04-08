import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingNotaItem {
  final String id;
  final String ownerUserId;
  final String nomeCliente;
  final String numeroNota;
  final String dataCompraIso;
  final String? fotoLocalPath;
  final String? documentoCliente;
  final String? telefoneCliente;
  final String serieNota;
  final String? chaveNfe;
  final String? dataPrevistaRetiradaIso;
  final List<Map<String, dynamic>> produtos;
  final double? valorTotal;
  final double? descontoTotal;
  final String? observacoes;
  final String? contatoId;
  final DateTime createdAt;
  final int tentativas;
  final String? erro;

  const PendingNotaItem({
    required this.id,
    required this.ownerUserId,
    required this.nomeCliente,
    required this.numeroNota,
    required this.dataCompraIso,
    required this.fotoLocalPath,
    required this.documentoCliente,
    required this.telefoneCliente,
    required this.serieNota,
    required this.chaveNfe,
    required this.dataPrevistaRetiradaIso,
    required this.produtos,
    required this.valorTotal,
    required this.descontoTotal,
    required this.observacoes,
    required this.contatoId,
    required this.createdAt,
    this.tentativas = 0,
    this.erro,
  });

  PendingNotaItem copyWith({
    int? tentativas,
    String? erro,
  }) {
    return PendingNotaItem(
      id: id,
      ownerUserId: ownerUserId,
      nomeCliente: nomeCliente,
      numeroNota: numeroNota,
      dataCompraIso: dataCompraIso,
      fotoLocalPath: fotoLocalPath,
      documentoCliente: documentoCliente,
      telefoneCliente: telefoneCliente,
      serieNota: serieNota,
      chaveNfe: chaveNfe,
      dataPrevistaRetiradaIso: dataPrevistaRetiradaIso,
      produtos: produtos,
      valorTotal: valorTotal,
      descontoTotal: descontoTotal,
      observacoes: observacoes,
      contatoId: contatoId,
      createdAt: createdAt,
      tentativas: tentativas ?? this.tentativas,
      erro: erro ?? this.erro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUserId': ownerUserId,
      'nomeCliente': nomeCliente,
      'numeroNota': numeroNota,
      'dataCompraIso': dataCompraIso,
      'fotoLocalPath': fotoLocalPath,
      'documentoCliente': documentoCliente,
      'telefoneCliente': telefoneCliente,
      'serieNota': serieNota,
      'chaveNfe': chaveNfe,
      'dataPrevistaRetiradaIso': dataPrevistaRetiradaIso,
      'produtos': produtos,
      'valorTotal': valorTotal,
      'descontoTotal': descontoTotal,
      'observacoes': observacoes,
      'contatoId': contatoId,
      'createdAt': createdAt.toIso8601String(),
      'tentativas': tentativas,
      'erro': erro,
    };
  }

  factory PendingNotaItem.fromMap(Map<String, dynamic> map) {
    final produtosRaw = (map['produtos'] as List?) ?? const [];
    return PendingNotaItem(
      id: map['id'] as String,
      ownerUserId: map['ownerUserId'] as String,
      nomeCliente: map['nomeCliente'] as String,
      numeroNota: map['numeroNota'] as String,
      dataCompraIso: map['dataCompraIso'] as String,
      fotoLocalPath: map['fotoLocalPath'] as String?,
      documentoCliente: map['documentoCliente'] as String?,
      telefoneCliente: map['telefoneCliente'] as String?,
      serieNota: map['serieNota'] as String,
      chaveNfe: map['chaveNfe'] as String?,
      dataPrevistaRetiradaIso: map['dataPrevistaRetiradaIso'] as String?,
      produtos: produtosRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      valorTotal: (map['valorTotal'] as num?)?.toDouble(),
      descontoTotal: (map['descontoTotal'] as num?)?.toDouble(),
      observacoes: map['observacoes'] as String?,
      contatoId: map['contatoId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      tentativas: (map['tentativas'] as num?)?.toInt() ?? 0,
      erro: map['erro'] as String?,
    );
  }
}

class PendingNotaService {
  static const String _storageKey = 'pending_notas_queue_v1';

  Future<List<PendingNotaItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((e) => PendingNotaItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> add(PendingNotaItem item) async {
    final all = await getAll();
    all.add(item);
    await _saveAll(all);
  }

  Future<void> remove(String id) async {
    final all = await getAll();
    all.removeWhere((i) => i.id == id);
    await _saveAll(all);
  }

  Future<void> incrementTentativas(String id, String erro) async {
    final all = await getAll();
    final idx = all.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final atual = all[idx];
    all[idx] = atual.copyWith(tentativas: atual.tentativas + 1, erro: erro);
    await _saveAll(all);
  }

  Future<String?> persistImage(File? image, String pendingId) async {
    if (image == null) return null;
    if (!await image.exists()) return null;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'pending_notas', pendingId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final ext = p.extension(image.path);
    final target = File(p.join(dir.path, 'nota$ext'));
    await image.copy(target.path);
    return target.path;
  }

  Future<void> deletePersistedImage(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    if (!await file.exists()) return;

    final dir = file.parent;
    await file.delete();
    if (await dir.exists()) {
      final remaining = await dir.list().toList();
      if (remaining.isEmpty) {
        await dir.delete(recursive: true);
      }
    }
  }

  Future<void> _saveAll(List<PendingNotaItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((e) => e.toMap()).toList()),
    );
  }
}
