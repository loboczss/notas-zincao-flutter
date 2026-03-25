import 'dart:convert';
import 'dart:io';
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
    this.observacoes,
  });

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
      'model': 'gpt-4.1-mini',
      'max_tokens': 2000,
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
  "observacoes": "Qualquer observação relevante"
}
Se algum campo não estiver visível na imagem, use null.
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
      'observacoes': observacoes,
      'status_retirada': 'pendente',
      'contato_id': contatoId,
    };

    // Remove null values para usar defaults do banco
    data.removeWhere((key, value) => value == null);

    final response = await supabase
        .from('notas_retirada')
        .insert(data)
        .select()
        .single();

    return NotaRetirada.fromMap(response);
  }
}
