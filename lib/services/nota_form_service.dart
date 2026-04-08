import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/constants/db_tables.dart';
import 'package:path/path.dart' as p;
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/services/storage_service.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';
import 'package:notas_zincao_flutter/utils/field_validators.dart' as validators;
import 'package:notas_zincao_flutter/utils/parse_utils.dart' as parse;

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
  final String? rawText;
  final Map<String, double> confidencias;
  final List<String> warnings;
  final List<String> missingFields;

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
    this.rawText,
    this.confidencias = const {},
    this.warnings = const [],
    this.missingFields = const [],
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
    final confidenceRaw = json['confidence'];
    final confidenceMap = confidenceRaw is Map
        ? confidenceRaw.map(
            (key, value) => MapEntry(
              key.toString(),
              parse.parseDouble(value, fallback: 0),
            ),
          )
        : <String, double>{};

    return CupomAnaliseResult(
      nomeCliente: json['nome_cliente'] as String?,
      documentoCliente: json['documento_cliente'] as String?,
      telefoneCliente: json['telefone_cliente'] as String?,
      numeroNota: json['numero_nota'] as String?,
      serieNota: json['serie_nota'] as String?,
      chaveNfe: json['chave_nfe'] as String?,
      dataCompra: json['data_compra'] as String?,
      produtos:
          (json['produtos'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      valorTotal: json['valor_total'] == null
              ? null
              : parse.parseDouble(json['valor_total'], fallback: 0),
      valorTotalBruto: json['valor_total_bruto'] == null
              ? null
              : parse.parseDouble(json['valor_total_bruto'], fallback: 0),
      valorTotalLiquido: json['valor_total_liquido'] == null
              ? null
              : parse.parseDouble(json['valor_total_liquido'], fallback: 0),
      descontoTotal: json['desconto_total'] == null
              ? null
              : parse.parseDouble(json['desconto_total'], fallback: 0),
      observacoes: json['observacoes'] as String?,
            rawText: json['raw_text'] as String?,
      confidencias: confidenceMap,
      warnings: (json['warnings'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      missingFields: (json['missing_fields'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }
}

class ReceiptImageQualityReport {
  final bool canProceed;
  final List<String> blockingIssues;
  final List<String> warnings;

  const ReceiptImageQualityReport({
    required this.canProceed,
    this.blockingIssues = const [],
    this.warnings = const [],
  });
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
    final numero = numeroNota.trim();
    final chave = chaveNfe?.trim();

    final temNumero = numero.isNotEmpty;
    final temChave = chave != null && chave.isNotEmpty;

    if (!temNumero && !temChave) return null;

    final futures = await Future.wait([
      temNumero
          ? supabase
              .from(DbTables.notasRetirada)
              .select()
              .eq(ColsNotasRetirada.numeroNota, numero)
              .order(ColsNotasRetirada.criadoEm, ascending: false)
              .limit(1)
              .maybeSingle()
          : Future<Map<String, dynamic>?>.value(null),
      temChave
          ? supabase
              .from(DbTables.notasRetirada)
              .select()
              .eq(ColsNotasRetirada.chaveNfe, chave)
              .order(ColsNotasRetirada.criadoEm, ascending: false)
              .limit(1)
              .maybeSingle()
          : Future<Map<String, dynamic>?>.value(null),
    ]);

    final porNumero = futures[0];
    final porChave = futures[1];

    if (porNumero != null) return NotaRetirada.fromMap(porNumero);
    if (porChave != null) return NotaRetirada.fromMap(porChave);
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

  Future<String> uploadImage(File imageFile, String userId) =>
      StorageService.uploadImage(imageFile, userId);

  // ─── Análise de Cupom com OpenAI Vision ──────────────────────────

  /// Envia a imagem do cupom para a OpenAI Vision e retorna os dados extraídos.
  Future<CupomAnaliseResult> analyzeReceipt(File imageFile) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY não configurada no .env');
    }

    final bytes = await imageFile.readAsBytes();
    final quality = _assessImageQuality(bytes);
    if (!quality.canProceed) {
      throw Exception(
        'Qualidade da foto insuficiente: ${quality.blockingIssues.join(' | ')}. Tire outra foto com melhor foco, luz e enquadramento.',
      );
    }

    final base64Image = base64Encode(bytes);
    final ext = p.extension(imageFile.path).replaceFirst('.', '').toLowerCase();
    final mimeType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';

    final warnings = [...quality.warnings];
    CupomAnaliseResult? bestResult;
    var bestScore = -1;
    Object? lastError;

    for (var tentativa = 1; tentativa <= 3; tentativa++) {
      try {
        final raw = await _callReceiptModel(
          apiKey: apiKey,
          base64Image: base64Image,
          mimeType: mimeType,
          retryHint: _retryHintForAttempt(tentativa),
        );
        final normalized = _normalizeAndValidateAiPayload(raw);
        final candidate = _applyDeterministicFieldValidation(
          CupomAnaliseResult.fromJson(normalized),
          extraWarnings: warnings,
        );

        final score = _scoreCriticalQuality(candidate);
        if (score > bestScore) {
          bestScore = score;
          bestResult = candidate;
        }

        if (score >= 90 && _criticalMissingErrors(candidate).isEmpty) {
          break;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (bestResult == null) {
      throw Exception('Nao foi possivel validar o JSON da IA: $lastError');
    }

    final normalizedResult = bestResult;

    final criticalErrors = _criticalMissingErrors(normalizedResult);
    if (criticalErrors.isNotEmpty) {
      throw Exception(
        'A leitura da IA ficou incompleta para campos criticos: ${criticalErrors.join(', ')}. Reenvie a foto para garantir chave de acesso, numero da nota, data, quantidade e precos corretos.',
      );
    }

    return normalizedResult;
  }

  String? _retryHintForAttempt(int attempt) {
    if (attempt == 1) return null;
    if (attempt == 2) {
      return 'A resposta anterior estava incompleta. Foque em chave_nfe (44 digitos), numero_nota, serie_nota, data_compra e em todos os itens com quantidade, valor_unitario e valor_total corretos.';
    }
    return 'Ultima tentativa: extraia com maxima precisao chave_nfe (44 digitos) e numero_nota; extraia produtos e valores e valide a soma dos itens com valor_total_liquido.';
  }

  Future<Map<String, dynamic>> _callReceiptModel({
    required String apiKey,
    required String base64Image,
    required String mimeType,
    String? retryHint,
  }) async {
    final body = jsonEncode({
      'model': 'gpt-5.4-mini',
      'max_completion_tokens': 2200,
      'messages': [
        {
          'role': 'system',
          'content':
              '''Voce extrai dados de cupons fiscais brasileiros e DEVE responder APENAS com JSON valido.
Schema obrigatorio (responda APENAS com este JSON, sem nenhum texto adicional):
{
  "nome_cliente": string|null,
  "documento_cliente": string|null,
  "telefone_cliente": string|null,
  "numero_nota": string|null,
  "serie_nota": string|null,
  "chave_nfe": string|null,
  "data_compra": string|null,
  "produtos": [
    {
      "nome": string,
      "quantidade": number,
      "tipo_unidade": string|null,
      "valor_unitario": number|null,
      "valor_total": number|null,
      "confidence": number
    }
  ],
  "valor_total": number|null,
  "valor_total_bruto": number|null,
  "valor_total_liquido": number|null,
  "desconto_total": number,
  "observacoes": string|null,
  "raw_text": string|null,
  "confidence": {
    "nome_cliente": number,
    "documento_cliente": number,
    "telefone_cliente": number,
    "numero_nota": number,
    "serie_nota": number,
    "chave_nfe": number,
    "data_compra": number,
    "produtos": number,
    "totais": number
  },
  "warnings": [string],
  "missing_fields": [string]
}
Regras gerais:
- Use null quando nao estiver legivel.
- Desconto deve ser numero >= 0.
- Confidence sempre entre 0 e 1.
- Se conseguir ler chave_nfe de 44 digitos, extraia corretamente serie_nota e numero_nota.
- Prioridade absoluta de precisao: data_compra, numero_nota e produtos.quantidade.
- Para produtos, nome e quantidade sao obrigatorios; valores podem ser null se nao estiverem confiaveis.
- Sem markdown, sem comentarios, sem texto fora do JSON.

REGRAS CRITICAS PARA QUANTIDADE DE PRODUTOS:
1. O cupom fiscal tem colunas: CODIGO | DESCRICAO | QTDE | UN | VL.UNIT | VL.TOTAL
2. "quantidade" e o valor na coluna QTDE — e SEMPRE o numero de unidades vendidas daquele produto.
3. NUNCA confunda numeros que fazem parte do nome ou descricao do produto com a quantidade.
  Exemplos de especificacoes que NAO sao quantidade: medidas como "49.000", "1/2", "4500", "2 1/2", codigos numericos no nome.
  Identificacao: se o numero esta dentro do texto do nome do produto (antes da coluna QTDE), e especificacao, nao quantidade.
4. METODO obrigatorio para cada linha de produto:
  a) Identifique a posicao das colunas QTDE, VL.UNIT e VL.TOTAL pelo cabecalho da tabela.
  b) Leia os valores numericos apos a descricao do produto alinhando com essas colunas.
  c) VALIDE: quantidade x VL.UNIT deve ser aproximadamente igual a VL.TOTAL. Se nao bater, revise a leitura.
5. Quantidades tipicas de varejo (referencia): 1, 2, 3, 4, 5, 10, 20, 50. Valores como 44, 49, 197, 4500 so sao quantidade se o contexto confirmar claramente.''',
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': retryHint == null
                  ? 'Analise este cupom fiscal e retorne o JSON no schema obrigatorio.'
                  : 'Analise este cupom fiscal e retorne o JSON no schema obrigatorio. $retryHint',
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image', 'detail': 'high'},
            },
          ],
        },
      ],
    });

    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $apiKey',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('OpenAI API erro: ${response.statusCode} - ${response.body}');
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) throw Exception('AI nao retornou resposta');

    final rawText = (choices[0]['message']['content'] as String?)?.trim() ?? '';
    if (rawText.isEmpty) throw Exception('AI retornou conteudo vazio');

    final jsonText = _extractJsonObject(rawText);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('JSON da IA nao e objeto');
    }
    return decoded;
  }

  String _extractJsonObject(String content) {
    final clean = content
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw Exception('Nao foi possivel localizar JSON na resposta da IA');
    }
    return clean.substring(start, end + 1);
  }

  Map<String, dynamic> _normalizeAndValidateAiPayload(Map<String, dynamic> raw) {
    final produtosRaw = raw['produtos'];
    final produtos = <Map<String, dynamic>>[];
    if (produtosRaw is List) {
      for (final item in produtosRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final nome = (map['nome'] ?? '').toString().trim();
        if (nome.isEmpty) continue;

        final quantidade = parse.parseDouble(map['quantidade'], fallback: 1);
        final valorUnitario = map['valor_unitario'] == null
            ? null
            : parse.parseDouble(map['valor_unitario'], fallback: 0);
        final valorTotal = map['valor_total'] == null
            ? null
            : parse.parseDouble(map['valor_total'], fallback: 0);
        final confidence = parse.parseDouble(map['confidence'], fallback: 0.5)
            .clamp(0, 1)
            .toDouble();

        produtos.add({
          'nome': nome,
          'quantidade': quantidade <= 0 ? 1.0 : quantidade,
          'tipo_unidade': map['tipo_unidade']?.toString(),
          'valor_unitario': valorUnitario,
          'valor_total': valorTotal,
          'confidence': confidence,
        });
      }
    }

    final confidenceRaw = raw['confidence'];
    final confidence = <String, double>{
      'nome_cliente': 0,
      'documento_cliente': 0,
      'telefone_cliente': 0,
      'numero_nota': 0,
      'serie_nota': 0,
      'chave_nfe': 0,
      'data_compra': 0,
      'produtos': 0,
      'totais': 0,
    };
    if (confidenceRaw is Map) {
      confidenceRaw.forEach((key, value) {
        confidence[key.toString()] = parse
            .parseDouble(value, fallback: 0)
            .clamp(0, 1)
            .toDouble();
      });
    }

    return {
      'nome_cliente': _nullIfBlank(raw['nome_cliente']),
      'documento_cliente': _nullIfBlank(raw['documento_cliente']),
      'telefone_cliente': _nullIfBlank(raw['telefone_cliente']),
      'numero_nota': _nullIfBlank(raw['numero_nota']),
      'serie_nota': _nullIfBlank(raw['serie_nota']) ?? '1',
      'chave_nfe': _nullIfBlank(raw['chave_nfe']),
      'data_compra': _nullIfBlank(raw['data_compra']),
      'produtos': produtos,
      'valor_total': raw['valor_total'] == null
          ? null
          : parse.parseDouble(raw['valor_total'], fallback: 0),
      'valor_total_bruto': raw['valor_total_bruto'] == null
          ? null
          : parse.parseDouble(raw['valor_total_bruto'], fallback: 0),
      'valor_total_liquido': raw['valor_total_liquido'] == null
          ? null
          : parse.parseDouble(raw['valor_total_liquido'], fallback: 0),
      'desconto_total': parse.parseDouble(raw['desconto_total'], fallback: 0),
      'observacoes': _nullIfBlank(raw['observacoes']),
      'raw_text': _nullIfBlank(raw['raw_text']),
      'confidence': confidence,
      'warnings': (raw['warnings'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
      'missing_fields': (raw['missing_fields'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
    };
  }

  String? _nullIfBlank(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  CupomAnaliseResult _applyDeterministicFieldValidation(
    CupomAnaliseResult result, {
    List<String> extraWarnings = const [],
  }) {
    final warnings = [...result.warnings, ...extraWarnings];

    var numeroNota = _normalizeNumeroNota(result.numeroNota);
    var serieNota = _normalizeSerieNota(result.serieNota);
    var dataCompra = validators.normalizeIsoDate(result.dataCompra);

    final chaveNfeNormalizada = validators.normalizeChaveNfe(result.chaveNfe);
    if (chaveNfeNormalizada != null) {
      final fromKey = _extractNumeroSerieFromChaveNfe(chaveNfeNormalizada);
      numeroNota ??= fromKey.$1;
      serieNota ??= fromKey.$2;
    }

    if (result.rawText != null) {
      numeroNota ??= _extractNumeroNotaFromRawText(result.rawText!);
      serieNota ??= _extractSerieFromRawText(result.rawText!);
      dataCompra ??= _extractDataCompraFromRawText(result.rawText!);
    }

    if (numeroNota == null) {
      warnings.add('Numero da nota nao foi identificado com confianca.');
    }
    if (dataCompra == null) {
      warnings.add('Data da venda nao foi identificada com confianca.');
    }

    final produtosValidados = _validateAndNormalizeProdutos(result.produtos, warnings);

    final documentoConsumidor = result.rawText == null
      ? null
      : _extractConsumidorCpfFromRawText(result.rawText!);

    var documento = documentoConsumidor ?? validators.normalizeDocumento(result.documentoCliente);
    documento ??= result.rawText == null ? null : _extractDocumentoFromRawText(result.rawText!);
    if (result.documentoCliente != null && documento == null) {
      warnings.add('Documento da foto invalido ou incompleto.');
    }

    final telefone = validators.normalizePhoneBr(result.telefoneCliente);
    if (result.telefoneCliente != null && telefone == null) {
      warnings.add('Telefone da foto invalido ou incompleto.');
    }

    final chaveNfe = chaveNfeNormalizada ??
        (result.rawText == null ? null : _extractChaveNfeFromRawText(result.rawText!));
    if (result.chaveNfe != null && chaveNfe == null) {
      warnings.add('Chave NFe da foto invalida (esperado 44 digitos).');
    }

    if (result.dataCompra != null && dataCompra == null) {
      warnings.add('Data da compra da foto esta fora do formato esperado.');
    }

    return CupomAnaliseResult(
      nomeCliente: result.nomeCliente,
      documentoCliente: documento,
      telefoneCliente: telefone,
      numeroNota: numeroNota,
      serieNota: serieNota ?? '1',
      chaveNfe: chaveNfe,
      dataCompra: dataCompra,
      produtos: produtosValidados,
      valorTotal: result.valorTotal,
      valorTotalBruto: result.valorTotalBruto,
      valorTotalLiquido: result.valorTotalLiquido,
      descontoTotal: result.descontoTotal,
      observacoes: result.observacoes,
      rawText: result.rawText,
      confidencias: result.confidencias,
      warnings: warnings,
      missingFields: result.missingFields,
    );
  }

  int _scoreCriticalQuality(CupomAnaliseResult result) {
    var score = 0;
    if (_normalizeNumeroNota(result.numeroNota) != null) score += 20;
    if (validators.normalizeIsoDate(result.dataCompra) != null) score += 20;
    if (validators.normalizeChaveNfe(result.chaveNfe) != null) score += 10;
    if (result.produtos.isNotEmpty) score += 20;

    final itensCompletos = result.produtos.where((p) {
      final q = parse.parseDouble(p['quantidade'], fallback: 0);
      return q > 0;
    }).length;

    if (result.produtos.isNotEmpty) {
      score += ((itensCompletos / result.produtos.length) * 30).round();
    }
    return score;
  }

  List<String> _criticalMissingErrors(CupomAnaliseResult result) {
    final errors = <String>[];
    if (validators.normalizeChaveNfe(result.chaveNfe) == null) errors.add('chave de acesso');
    if (_normalizeNumeroNota(result.numeroNota) == null) errors.add('numero da nota');
    if (validators.normalizeIsoDate(result.dataCompra) == null) errors.add('data da venda');
    if (result.produtos.isEmpty) errors.add('produtos');

    final temItemInvalido = result.produtos.any((p) {
      final q = parse.parseDouble(p['quantidade'], fallback: 0);
      return q <= 0;
    });
    if (temItemInvalido) errors.add('quantidade dos produtos');

    return errors;
  }

  String? _normalizeNumeroNota(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = validators.onlyDigits(value);
    if (digits.isEmpty) return null;
    return int.tryParse(digits)?.toString() ?? digits;
  }

  String? _normalizeSerieNota(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = validators.onlyDigits(value);
    if (digits.isEmpty) return null;
    return int.tryParse(digits)?.toString() ?? digits;
  }

  (String?, String?) _extractNumeroSerieFromChaveNfe(String chave) {
    if (chave.length != 44) return (null, null);
    final serie = int.tryParse(chave.substring(22, 25))?.toString();
    final numero = int.tryParse(chave.substring(25, 34))?.toString();
    return (numero, serie);
  }

  String? _extractNumeroNotaFromRawText(String rawText) {
    final patterns = [
      RegExp(r'nfc-?e\s*n[oº]\s*(\d+)', caseSensitive: false),
      RegExp(r'numero\s*da\s*nota\s*[:\-]?\s*(\d+)', caseSensitive: false),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(rawText);
      if (m != null) {
        final normalized = _normalizeNumeroNota(m.group(1));
        if (normalized != null) return normalized;
      }
    }
    return null;
  }

  String? _extractSerieFromRawText(String rawText) {
    final re = RegExp(r'serie\s*(\d+)', caseSensitive: false);
    final m = re.firstMatch(rawText);
    if (m == null) return null;
    return _normalizeSerieNota(m.group(1));
  }

  String? _extractDataCompraFromRawText(String rawText) {
    final re = RegExp(r'(\d{2}\/\d{2}\/\d{4})');
    final m = re.firstMatch(rawText);
    if (m == null) return null;
    return validators.normalizeIsoDate(m.group(1));
  }

  String? _extractDocumentoFromRawText(String rawText) {
    final patterns = [
      RegExp(r'consumidor\s*cpf\s*[:\-]?\s*([\d.\-]{11,18})', caseSensitive: false),
      RegExp(r'cpf\s*[:\-]?\s*([\d.\-]{11,18})', caseSensitive: false),
      RegExp(r'cnpj\s*[:\-]?\s*([\d.\/\-]{14,22})', caseSensitive: false),
    ];

    for (final re in patterns) {
      final m = re.firstMatch(rawText);
      if (m == null) continue;
      final normalized = validators.normalizeDocumento(m.group(1));
      if (normalized != null) return normalized;
    }

    return null;
  }

  String? _extractConsumidorCpfFromRawText(String rawText) {
    final patterns = [
      RegExp(r'consumidor\s*cpf\s*[:\-]?\s*([\d.\-]{11,18})', caseSensitive: false),
      RegExp(r'consumidor[^\n]{0,40}cpf\s*[:\-]?\s*([\d.\-]{11,18})', caseSensitive: false),
    ];

    for (final re in patterns) {
      final m = re.firstMatch(rawText);
      if (m == null) continue;
      final digits = validators.onlyDigits(m.group(1) ?? '');
      if (digits.length != 11) continue;
      if (validators.isValidCpf(digits)) return digits;
    }

    return null;
  }

  String? _extractChaveNfeFromRawText(String rawText) {
    final text = rawText.replaceAll('\n', ' ');

    // 1) Chave em URL de consulta SEFAZ (parametro p=...)
    final pParamMatches = RegExp(r'[?&]p=([^\s&#]+)', caseSensitive: false).allMatches(text);
    for (final m in pParamMatches) {
      final rawParam = m.group(1) ?? '';
      final firstChunk = rawParam.split('|').first;
      final candidate = validators.normalizeChaveNfe(firstChunk);
      if (candidate != null) return candidate;

      final digitsParam = validators.onlyDigits(rawParam);
      if (digitsParam.length >= 44) {
        final prefix44 = digitsParam.substring(0, 44);
        final normalized = validators.normalizeChaveNfe(prefix44);
        if (normalized != null) return normalized;
      }
    }

    // 2) Blocos longos com separadores comuns de OCR (espaco, ponto, barra, hifen)
    final matches = RegExp(r'(\d[\d\s./\-]{42,90}\d)').allMatches(text);
    for (final m in matches) {
      final digits = validators.onlyDigits(m.group(1) ?? '');
      if (digits.length == 44) {
        final normalized = validators.normalizeChaveNfe(digits);
        if (normalized != null) return normalized;
      }

      if (digits.length > 44) {
        for (var i = 0; i <= digits.length - 44; i++) {
          final window = digits.substring(i, i + 44);
          final normalized = validators.normalizeChaveNfe(window);
          if (normalized != null) return normalized;
        }
      }
    }

    // 3) Fallback global: varredura em todos os digitos do texto OCR
    final allDigits = validators.onlyDigits(text);
    if (allDigits.length >= 44) {
      for (var i = 0; i <= allDigits.length - 44; i++) {
        final window = allDigits.substring(i, i + 44);
        final normalized = validators.normalizeChaveNfe(window);
        if (normalized != null) return normalized;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _validateAndNormalizeProdutos(
    List<Map<String, dynamic>> produtos,
    List<String> warnings,
  ) {
    final out = <Map<String, dynamic>>[];
    for (final item in produtos) {
      final nome = (item['nome'] ?? '').toString().trim();
      if (nome.isEmpty) continue;

      final quantidade = parse.parseDouble(item['quantidade'], fallback: 0);
      var valorUnitario = item['valor_unitario'] == null
          ? null
          : parse.parseDouble(item['valor_unitario'], fallback: 0);
      var valorTotal = item['valor_total'] == null
          ? null
          : parse.parseDouble(item['valor_total'], fallback: 0);

      if (quantidade <= 0) {
        warnings.add('Produto "$nome" com quantidade invalida.');
        continue;
      }

      // Preco da nota pode estar impreciso no OCR. O backend usa preco oficial do estoque.
      if (valorUnitario != null && valorUnitario <= 0) {
        valorUnitario = null;
      }
      if (valorTotal != null && valorTotal <= 0) {
        valorTotal = null;
      }

      // Tenta corrigir quantidade inconsistente baseando-se no total e no preco unitario.
      final (qtdFinal, unitFinal) = _corrigirQuantidade(
        quantidade,
        valorUnitario,
        valorTotal,
        nome,
        warnings,
      );

      out.add({
        ...item,
        'nome': nome,
        'quantidade': qtdFinal,
        'valor_unitario': unitFinal,
        'valor_total': valorTotal,
      });
    }
    return out;
  }

  /// Retorna true se [q] e um numero "limpo" de quantidade comercial:
  /// inteiro ou com no maximo 3 casas decimais e em faixa razoavel (0.01 a 99999).
  bool _isReasonableQty(double q) {
    if (q < 0.001 || q > 99999) return false;
    // Verifica se e proximo de um numero com ate 3 decimais
    final rounded = (q * 1000).round() / 1000;
    return (rounded - q).abs() < 0.0005;
  }

  /// Tenta corrigir a quantidade de um produto usando o valor total e o preco unitario.
  /// Retorna [qty, unitario] possivelmente corrigidos.
  (double, double?) _corrigirQuantidade(
    double qty,
    double? valorUnitario,
    double? valorTotal,
    String nome,
    List<String> warnings,
  ) {
    if (valorTotal == null || valorTotal <= 0) return (qty, valorUnitario);
    if (valorUnitario == null || valorUnitario <= 0) return (qty, valorUnitario);

    // Verifica consistencia: qty × unit ≈ total?
    final expectedTotal = qty * valorUnitario;
    final discrepancia = (expectedTotal - valorTotal).abs() / valorTotal;
    if (discrepancia <= 0.02) return (qty, valorUnitario); // OK, dentro de 2%

    // Tenta corrigir: qty_corrigida = total / unit
    final calcQty = valorTotal / valorUnitario;
    if (_isReasonableQty(calcQty) && calcQty > 0) {
      final roundedQty = double.parse(calcQty.toStringAsFixed(3));
      warnings.add('Produto "$nome": quantidade corrigida de $qty para $roundedQty (baseado em total / preco unitario).');
      return (roundedQty, valorUnitario);
    }

    // Nao conseguiu corrigir via unit price — tenta derivar unit do total/qty
    // (o preco unitario pode estar errado, mas a quantidade pode estar certa)
    // Apenas emite aviso para o usuario revisar
    warnings.add('Produto "$nome": verifique a quantidade ($qty). O produto pode ter sido lido incorretamente da tabela do cupom.');
    return (qty, valorUnitario);
  }

  ReceiptImageQualityReport _assessImageQuality(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ReceiptImageQualityReport(
        canProceed: false,
        blockingIssues: ['Nao foi possivel ler a imagem selecionada.'],
      );
    }

    final severeIssues = <String>[];
    final warnings = <String>[];
    final width = decoded.width;
    final height = decoded.height;
    final shortSide = math.min(width, height);
    final pixelCount = width * height;

    // Bloqueia apenas resolucao realmente critica.
    if (shortSide < 600 || pixelCount < 700000) {
      severeIssues.add('Resolucao muito baixa (${width}x$height).');
    } else if (shortSide < 750) {
      warnings.add('Resolucao abaixo do ideal (${width}x$height). Ainda pode funcionar, mas tente aproximar um pouco mais.');
    }

    final sampleStep = (decoded.width ~/ 120).clamp(1, 10);
    var sumLum = 0.0;
    var sumLumSq = 0.0;
    var edgeEnergy = 0.0;
    var count = 0;

    for (var y = 0; y < decoded.height; y += sampleStep) {
      for (var x = 0; x < decoded.width; x += sampleStep) {
        final c = decoded.getPixel(x, y);
        final lum = (0.299 * c.r + 0.587 * c.g + 0.114 * c.b);
        sumLum += lum;
        sumLumSq += lum * lum;
        count++;

        if (x + sampleStep < decoded.width) {
          final c2 = decoded.getPixel(x + sampleStep, y);
          final lum2 = (0.299 * c2.r + 0.587 * c2.g + 0.114 * c2.b);
          edgeEnergy += (lum - lum2).abs();
        }
      }
    }

    if (count == 0) {
      return const ReceiptImageQualityReport(
        canProceed: false,
        blockingIssues: ['Imagem invalida para analise de qualidade.'],
      );
    }

    final mean = sumLum / count;
    final variance = (sumLumSq / count) - (mean * mean);
    final std = variance <= 0 ? 0.0 : math.sqrt(variance);
    final sharpness = edgeEnergy / count;

    if (mean < 25) {
      severeIssues.add('Imagem muito escura.');
    } else if (mean < 40) {
      warnings.add('Imagem escura. Tente aumentar a iluminacao para melhorar a leitura.');
    }

    if (mean > 245) {
      severeIssues.add('Imagem estourada (clara demais).');
    } else if (mean > 225) {
      warnings.add('Imagem muito clara. Pode perder contraste em textos.');
    }

    if (std < 10) {
      severeIssues.add('Baixo contraste no cupom.');
    } else if (std < 16) {
      warnings.add('Contraste baixo. Evite reflexo e sombra na foto.');
    }

    if (sharpness < 3.5) {
      severeIssues.add('Foto desfocada.');
    } else if (sharpness < 6) {
      warnings.add('Foto com nitidez baixa. Se der, recapture com foco no texto.');
    }

    // Regra anti-falso-negativo: so bloqueia quando houver mais de um problema severo.
    final blocking = severeIssues.length >= 2 ? severeIssues : <String>[];
    if (severeIssues.length == 1) {
      warnings.add('${severeIssues.first} A analise foi liberada, mas pode haver erro de leitura.');
    }

    return ReceiptImageQualityReport(
      canProceed: blocking.isEmpty,
      blockingIssues: blocking,
      warnings: warnings,
    );
  }

  // ─── CRM ─────────────────────────────────────────────────────────

  /// Cria ou atualiza o contato no CRM (upsert atômico por contato_id).
  Future<void> upsertCrmContact({
    required String telefone,
    required String nome,
  }) async {
    if (telefone.isEmpty || nome.isEmpty) return;
    try {
      await supabase.from(DbTables.crmZincao).upsert(
        {ColsCrmZincao.contatoId: telefone, ColsCrmZincao.nome: nome},
        onConflict: ColsCrmZincao.contatoId,
      );
    } catch (e) {
      debugPrint('Erro ao sincronizar com CRM: $e');
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
      ColsNotasRetirada.ownerUserId: ownerUserId,
      ColsNotasRetirada.nomeCliente: nomeCliente,
      ColsNotasRetirada.numeroNota: numeroNota,
      ColsNotasRetirada.dataCompra: dataCompra.toIso8601String().split('T').first,
      ColsNotasRetirada.fotoUrl: fotoUrl,
      ColsNotasRetirada.documentoCliente: documentoCliente,
      ColsNotasRetirada.telefoneCliente: telefoneCliente,
      ColsNotasRetirada.serieNota: serieNota,
      ColsNotasRetirada.chaveNfe: chaveNfe,
      ColsNotasRetirada.dataPrevistaRetirada: dataPrevistaRetirada
          ?.toIso8601String()
          .split('T')
          .first,
      ColsNotasRetirada.produtos: produtos,
      ColsNotasRetirada.valorTotal: valorTotal,
      ColsNotasRetirada.descontoTotal: descontoTotal,
      ColsNotasRetirada.observacoes: observacoes,
      ColsNotasRetirada.statusRetirada: 'pendente',
      ColsNotasRetirada.contatoId: contatoId,
    };

    // Remove null values para usar defaults do banco
    data.removeWhere((key, value) => value == null);

    debugPrint('📤 [createNota] Payload enviado ao Supabase: $data');

    try {
      final response = await supabase
          .from(DbTables.notasRetirada)
          .insert(data)
          .select()
          .single();

      debugPrint('✅ [createNota] Nota salva com sucesso: ${response[ColsNotasRetirada.id]}');
      return NotaRetirada.fromMap(response);
    } catch (e, st) {
      debugPrint('❌ [createNota] Erro ao inserir no Supabase: $e');
      debugPrint('❌ [createNota] StackTrace: $st');
      rethrow;
    }
  }
}
