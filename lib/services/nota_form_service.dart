import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

/// Resultado da análise do cupom pela IA.
class CupomAnaliseResult {
  final String? nomeCliente;
  final String? documentoCliente;
  final String? telefoneCliente;
  final String? numeroNota;
  final String? serieNota;
  final String? chaveNfe;
  final String? dataCompra;
  final List<Map<String, dynamic>> produtos;
  final double? valorTotal;
  final double? valorTotalBruto;
  final double? valorTotalLiquido;
  final double? descontoTotal;
  final String? observacoes;

  const CupomAnaliseResult({
    this.nomeCliente,
    this.documentoCliente,
    this.telefoneCliente,
    this.numeroNota,
    this.serieNota,
    this.chaveNfe,
    this.dataCompra,
    this.produtos = const [],
    this.valorTotal,
    this.valorTotalBruto,
    this.valorTotalLiquido,
    this.descontoTotal,
    this.observacoes,
  });

  double? get totalBrutoFoto => valorTotalBruto ?? valorTotal;

  double? get totalLiquidoFoto {
    if (valorTotalLiquido != null) return valorTotalLiquido;

    final bruto = totalBrutoFoto;
    if (bruto == null) return null;

    final desconto = descontoTotal ?? 0;
    final liquido = bruto - desconto;
    return liquido < 0 ? 0 : liquido;
  }

  factory CupomAnaliseResult.fromJson(Map<String, dynamic> json) {
    return CupomAnaliseResult(
      nomeCliente: json['nome_cliente'] as String?,
      documentoCliente: json['documento_cliente'] as String?,
      telefoneCliente: json['telefone_cliente'] as String?,
      numeroNota: json['numero_nota'] as String?,
      serieNota: json['serie_nota'] as String?,
      chaveNfe: json['chave_nfe'] as String?,
      dataCompra: json['data_compra'] as String?,
      produtos: (json['produtos'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      valorTotal: json['valor_total'] != null
          ? (json['valor_total'] as num).toDouble()
          : null,
        valorTotalBruto: json['valor_total_bruto'] != null
          ? (json['valor_total_bruto'] as num).toDouble()
          : null,
        valorTotalLiquido: json['valor_total_liquido'] != null
          ? (json['valor_total_liquido'] as num).toDouble()
          : null,
      descontoTotal: json['desconto_total'] != null
          ? (json['desconto_total'] as num).toDouble()
          : null,
      observacoes: json['observacoes'] as String?,
    );
  }
}

/// Service responsável por:
/// 1. Capturar/selecionar fotos (câmera ou galeria)
/// 2. Fazer upload no Supabase Storage
/// 3. Enviar a imagem para a OpenAI Vision e extrair dados do cupom
/// 4. Inserir a nota no banco de dados
class NotaFormService {
  final ImagePicker _picker = ImagePicker();

  Future<NotaRetirada?> findNotaDuplicada({
    required String numeroNota,
    String? chaveNfe,
  }) async {
    final numeroNormalizado = numeroNota.trim();
    final chaveNormalizada = chaveNfe?.trim();

    if (numeroNormalizado.isEmpty && (chaveNormalizada == null || chaveNormalizada.isEmpty)) {
      return null;
    }

    if (numeroNormalizado.isNotEmpty) {
      final existentePorNumero = await supabase
          .from('notas_retirada')
          .select()
          .eq('numero_nota', numeroNormalizado)
          .order('criado_em', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existentePorNumero != null) {
        return NotaRetirada.fromMap(existentePorNumero);
      }
    }

    if (chaveNormalizada != null && chaveNormalizada.isNotEmpty) {
      final existentePorChave = await supabase
          .from('notas_retirada')
          .select()
          .eq('chave_nfe', chaveNormalizada)
          .order('criado_em', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existentePorChave != null) {
        return NotaRetirada.fromMap(existentePorChave);
      }
    }

    return null;
  }

  // ─── Captura de Imagem ───────────────────────────────────────────

  /// Tira uma foto com a câmera.
  Future<File?> captureFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return photo != null ? File(photo.path) : null;
  }

  /// Seleciona uma foto da galeria.
  Future<File?> pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return photo != null ? File(photo.path) : null;
  }

  // ─── Upload no Supabase Storage ──────────────────────────────────

  /// Faz upload de uma imagem no Supabase Storage (bucket: `cupons`).
  /// Retorna a URL pública do arquivo.
  Future<String> uploadImage(File imageFile, String userId) async {
    final ext = p.extension(imageFile.path).replaceFirst('.', '');
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = 'cupons/$fileName';

    final bytes = await imageFile.readAsBytes();

    await supabase.storage
        .from('cupons')
        .uploadBinary(storagePath, bytes, fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ));

    final publicUrl = supabase.storage
        .from('cupons')
        .getPublicUrl(storagePath);

    return publicUrl;
  }

  // ─── Análise de Cupom com OpenAI Vision ──────────────────────────

  /// Envia a imagem do cupom para a OpenAI Vision (via HTTP direto) e retorna os dados extraídos.
  Future<CupomAnaliseResult> analyzeReceipt(File imageFile) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY não configurada no .env');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = p.extension(imageFile.path).replaceFirst('.', '').toLowerCase();
    final mimeType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';

    final body = jsonEncode({
      'model': 'gpt-5.4-mini',
      'max_completion_tokens': 2000,
      'messages': [
        {
          'role': 'system',
          'content': '''Você é um assistente especializado em extrair dados de cupons fiscais e notas fiscais brasileiras.
Analise a imagem e extraia TODOS os dados possíveis no formato JSON abaixo (sem markdown, apenas o JSON puro):
{
  "nome_cliente": "Nome do cliente se visível",
  "documento_cliente": "CPF ou CNPJ do cliente se visível",
  "telefone_cliente": "Telefone se visível",
  "numero_nota": "Número da nota fiscal",
  "serie_nota": "Série da nota fiscal",
  "chave_nfe": "Chave de acesso da NFe se visível",
  "data_compra": "Data no formato YYYY-MM-DD",
  "produtos": [
    {"nome": "Nome do produto", "quantidade": 1, "tipo_unidade": "UN", "valor_unitario": 10.50, "valor_total": 10.50}
  ],
  "valor_total": 123.45,
  "valor_total_bruto": 123.45,
  "valor_total_liquido": 120.45,
  "desconto_total": 0.00,
  "observacoes": "Qualquer observação relevante"
}
"valor_total_bruto" deve ser o total antes dos descontos.
"valor_total_liquido" deve ser o total final pago, após os descontos.
"valor_total" pode repetir o valor final pago para compatibilidade, mas priorize preencher corretamente "valor_total_bruto" e "valor_total_liquido".
"desconto_total" deve ser o valor total de descontos aplicados na nota (se houver). Se não houver desconto, use 0.
Se algum campo não estiver visível na imagem, use null (exceto desconto_total que deve ser 0).
IMPORTANTE: Retorne APENAS o JSON, sem nenhum texto adicional ou markdown code blocks.'''
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Analise este cupom fiscal e extraia os dados:'
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image',
                'detail': 'high'
              }
            }
          ]
        }
      ]
    });

    final httpClient = HttpClient();
    try {
      final request = await httpClient.postUrl(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
      );
      final utf8Body = utf8.encode(body);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', 'Bearer $apiKey');
      request.contentLength = utf8Body.length;
      request.add(utf8Body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('OpenAI API erro: ${response.statusCode} - $responseBody');
      }

      final Map<String, dynamic> json = jsonDecode(responseBody);
      final choices = json['choices'] as List;
      if (choices.isEmpty) {
        throw Exception('AI não retornou resposta');
      }

      String jsonText = choices[0]['message']['content'] as String;

      // Remove possíveis markdown code blocks
      jsonText = jsonText.replaceAll(RegExp(r'```json\s*'), '');
      jsonText = jsonText.replaceAll(RegExp(r'```\s*'), '');
      jsonText = jsonText.trim();

      final Map<String, dynamic> parsed = jsonDecode(jsonText);
      return CupomAnaliseResult.fromJson(parsed);
    } catch (e) {
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  // ─── Persistência no Supabase ────────────────────────────────────

  /// Insere uma nova nota no banco de dados.
  Future<NotaRetirada> createNota({
    required String ownerUserId,
    required String nomeCliente,
    required String numeroNota,
    required DateTime dataCompra,
    String? fotoUrl,
    String? documentoCliente,
    String? telefoneCliente,
    String serieNota = '1',
    String? chaveNfe,
    DateTime? dataPrevistaRetirada,
    List<Map<String, dynamic>> produtos = const [],
    double? valorTotal,
    double? descontoTotal,
    String? observacoes,
    String? contatoId,
  }) async {
    final data = {
      'owner_user_id': ownerUserId,
      'nome_cliente': nomeCliente,
      'numero_nota': numeroNota,
      'data_compra': dataCompra.toIso8601String().split('T').first,
      'foto_url': fotoUrl,
      'documento_cliente': documentoCliente,
      'telefone_cliente': telefoneCliente,
      'serie_nota': serieNota,
      'chave_nfe': chaveNfe,
      'data_prevista_retirada': dataPrevistaRetirada?.toIso8601String().split('T').first,
      'produtos': produtos,
      'valor_total': valorTotal,
      'desconto_total': descontoTotal,
      'observacoes': observacoes,
      'status_retirada': 'pendente',
      'contato_id': contatoId,
    };

    // Remove null values para usar defaults do banco
    data.removeWhere((key, value) => value == null);

    debugPrint('📤 [createNota] Payload enviado ao Supabase: $data');

    try {
      final response = await supabase
          .from('notas_retirada')
          .insert(data)
          .select()
          .single();

      debugPrint('✅ [createNota] Nota salva com sucesso: ${response['id']}');
      return NotaRetirada.fromMap(response);
    } catch (e, st) {
      debugPrint('❌ [createNota] Erro ao inserir no Supabase: $e');
      debugPrint('❌ [createNota] StackTrace: $st');
      rethrow;
    }
  }
}
