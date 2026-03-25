import 'dart:io';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/services/estoque_produto_service.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class RetiradaService {
  final EstoqueProdutoService _estoqueService = EstoqueProdutoService();

  /// Faz upload de múltiplas imagens no Supabase Storage e retorna a lista de URLs públicas.
  Future<List<String>> uploadImages(List<File> images, String userId) async {
    List<String> urls = [];
    final bucket = supabase.storage.from('cupons');

    for (var i = 0; i < images.length; i++) {
        final imageFile = images[i];
        final ext = p.extension(imageFile.path).replaceFirst('.', '');
        final fileName = '${userId}_retirada_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        final storagePath = 'cupons/$fileName';

        final bytes = await imageFile.readAsBytes();

        await bucket.uploadBinary(
          storagePath, 
          bytes, 
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: true)
        );

        final publicUrl = bucket.getPublicUrl(storagePath);
        urls.add(publicUrl);
    }
    return urls;
  }

  /// Registra uma nova retirada (parcial ou total) para uma nota.
  Future<NotaRetirada> registrarRetirada({
    required NotaRetirada nota,
    required Map<int, double> quantidadesRetiradas, // indice do produto -> quantidade que esta sendo retirada agora
    required List<String> comprovantesUrls,
    required String userId,
  }) async {
    // 1. Clona a lista de produtos para atualizar as quantidades
    List<dynamic> novosProdutos = List.from(nota.produtos);
    bool checkTodasRetiradas = true;

    final Map<int, double> retiradasEfetivas = {};

    for (int i = 0; i < novosProdutos.length; i++) {
      final p = Map<String, dynamic>.from(novosProdutos[i]);
      double qtdOriginal = double.tryParse(p['quantidade']?.toString() ?? '1') ?? 1.0;
      if (qtdOriginal <= 0) qtdOriginal = 1.0;
      
      final double qtdJaRetiradaAnteriormente = double.tryParse(p['quantidade_retirada']?.toString() ?? '0') ?? 0.0;
      
      final double qtdRetirandoAgora = quantidadesRetiradas[i] ?? 0.0;
      final double saldoNaNota = (qtdOriginal - qtdJaRetiradaAnteriormente) < 0
          ? 0.0
          : (qtdOriginal - qtdJaRetiradaAnteriormente);

      double qtdRetiradaEfetiva = qtdRetirandoAgora <= saldoNaNota ? qtdRetirandoAgora : saldoNaNota;

      final idProdutoEstoque = p['id_produto_estoque'];
      if (qtdRetiradaEfetiva > 0 && idProdutoEstoque is int) {
        qtdRetiradaEfetiva = await _estoqueService.baixarEstoqueComFallback(
          idProduto: idProdutoEstoque,
          quantidadeSolicitada: qtdRetiradaEfetiva,
        );
      }

      final novaQtdRetirada = qtdJaRetiradaAnteriormente + qtdRetiradaEfetiva;
      retiradasEfetivas[i] = qtdRetiradaEfetiva;
      
      p['quantidade_retirada'] = novaQtdRetirada;
      novosProdutos[i] = p;

      // Usando uma margem de tolerância para comparações double
      if ((novaQtdRetirada + 0.001) < qtdOriginal) {
        checkTodasRetiradas = false;
      }
    }

    // 2. Determina o novo status
    String novoStatus = checkTodasRetiradas ? 'retirada' : 'parcial';

    // 3. Monta o novo histórico de retiradas
    List<dynamic> novoHistorico = List.from(nota.historicoRetiradas ?? []);
    
    // Adiciona o evento de retirada atual
    if (retiradasEfetivas.values.any((qtd) => qtd > 0)) {
      novoHistorico.add({
        'data': DateTime.now().toIso8601String(),
        'responsavel_id': userId,
        'fotos': comprovantesUrls,
        'itens_retirados': retiradasEfetivas.entries.map((e) => {
          'index': e.key,
          'quantidade': e.value,
          'quantidade_solicitada': quantidadesRetiradas[e.key] ?? 0,
        }).toList(),
      });
    }

    // 4. Salva no banco de dados
    final response = await supabase
        .from('notas_retirada')
        .update({
          'produtos': novosProdutos,
          'historico_retiradas': novoHistorico,
          'status_retirada': novoStatus,
          'atualizado_em': DateTime.now().toIso8601String(),
          // Se completou a entrega:
          if (novoStatus == 'retirada' && nota.dataRetirada == null)
            'data_retirada': DateTime.now().toIso8601String(),
        })
        .eq('id', nota.id)
        .select()
        .single();

    return NotaRetirada.fromMap(response);
  }
}
