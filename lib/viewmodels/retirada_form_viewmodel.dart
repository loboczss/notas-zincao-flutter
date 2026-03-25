import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/services/estoque_produto_service.dart';
import 'package:notas_zincao_flutter/services/retirada_form_service.dart';

enum RetiradaStatus { idle, capturing, saving, success, error }

class RetiradaViewModel extends ChangeNotifier {
  final RetiradaService _service = RetiradaService();
  final EstoqueProdutoService _estoqueService = EstoqueProdutoService();
  final ImagePicker _picker = ImagePicker();

  NotaRetirada? notaSelecionada;
  
  // Mapa de Indice do Produto -> Quantidade selecionada para retirar agora
  final Map<int, double> quantidadesSelecionadas = {};
  
  // Fotos capturadas como comprovante para esta retirada
  final List<File> fotosComprovante = [];

  final Map<int, double> estoqueDisponivelPorIndex = {};

  RetiradaStatus status = RetiradaStatus.idle;
  String? errorMessage;

  /// Inicializa o ViewModel com uma nota
  void init(NotaRetirada nota) {
    notaSelecionada = nota;
    quantidadesSelecionadas.clear();
    fotosComprovante.clear();
    estoqueDisponivelPorIndex.clear();
    
    // Inicializa as quantidades selecionadas com 0.0
    for (int i = 0; i < nota.produtos.length; i++) {
        quantidadesSelecionadas[i] = 0.0;
    }
    
    status = RetiradaStatus.idle;
    errorMessage = null;
    notifyListeners();

    _loadEstoqueDisponivel();
  }

  Future<void> _loadEstoqueDisponivel() async {
    if (notaSelecionada == null) return;

    try {
      final ids = <int>[];
      for (int i = 0; i < notaSelecionada!.produtos.length; i++) {
        final p = notaSelecionada!.produtos[i] as Map<String, dynamic>;
        final idProduto = p['id_produto_estoque'];
        if (idProduto is int) {
          ids.add(idProduto);
        }
      }

      final estoquePorId = await _estoqueService.fetchQuantidadesDisponiveis(ids);

      for (int i = 0; i < notaSelecionada!.produtos.length; i++) {
        final p = notaSelecionada!.produtos[i] as Map<String, dynamic>;
        final idProduto = p['id_produto_estoque'];
        if (idProduto is int) {
          estoqueDisponivelPorIndex[i] = estoquePorId[idProduto] ?? 0;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  double getQuantidadeMaxima(int index) {
    if (notaSelecionada == null) return 0.0;
    final p = notaSelecionada!.produtos[index] as Map<String, dynamic>;
    double qtdOriginal = double.tryParse(p['quantidade']?.toString() ?? '1') ?? 1.0;
    if (qtdOriginal <= 0) qtdOriginal = 1.0;
    final double qtdJaRetirada = double.tryParse(p['quantidade_retirada']?.toString() ?? '0') ?? 0.0;
    final saldoNota = qtdOriginal - qtdJaRetirada;

    final estoqueDisponivel = estoqueDisponivelPorIndex[index];
    if (estoqueDisponivel == null) {
      return saldoNota < 0 ? 0 : saldoNota;
    }

    final maximo = saldoNota <= estoqueDisponivel ? saldoNota : estoqueDisponivel;
    return maximo < 0 ? 0 : maximo;
  }

  void incrementarQuantidade(int index) {
    final atual = quantidadesSelecionadas[index] ?? 0.0;
    final max = getQuantidadeMaxima(index);
    if (atual + 1 <= max) {
      quantidadesSelecionadas[index] = atual + 1;
      notifyListeners();
    } else {
      quantidadesSelecionadas[index] = max;
      notifyListeners();
    }
  }

  void decrementarQuantidade(int index) {
    final atual = quantidadesSelecionadas[index] ?? 0.0;
    if (atual - 1 >= 0) {
      quantidadesSelecionadas[index] = atual - 1;
      notifyListeners();
    } else {
      quantidadesSelecionadas[index] = 0;
      notifyListeners();
    }
  }

  void setQuantidade(int index, String value) {
    double? val = double.tryParse(value.replaceAll(',', '.'));
    if (val != null) {
      final max = getQuantidadeMaxima(index);
      if (val < 0) val = 0;
      if (val > max) val = max;
      quantidadesSelecionadas[index] = val;
      notifyListeners();
    }
  }

  bool get temAlgumProdutoSelecionado {
    return quantidadesSelecionadas.values.any((qtd) => qtd > 0);
  }

  bool get isValidoParaConfirmar {
    return temAlgumProdutoSelecionado && fotosComprovante.isNotEmpty;
  }

  // ─── Fotos ────────────────────────────────────────────────────────
  
  Future<void> tirarFoto() async {
    status = RetiradaStatus.capturing;
    notifyListeners();

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (photo != null) {
        fotosComprovante.add(File(photo.path));
      }
    } catch (e) {
      errorMessage = 'Erro ao capturar foto: $e';
    } finally {
      status = RetiradaStatus.idle;
      notifyListeners();
    }
  }

  void removerFoto(int index) {
    fotosComprovante.removeAt(index);
    notifyListeners();
  }

  // ─── Confirmação ──────────────────────────────────────────────────
  
  Future<void> confirmarRetirada(String userId) async {
    if (notaSelecionada == null || !isValidoParaConfirmar) return;

    status = RetiradaStatus.saving;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload das Fotos
      final urls = await _service.uploadImages(fotosComprovante, userId);

      // 2. Registro no Banco de Dados
      final notaAtualizada = await _service.registrarRetirada(
        nota: notaSelecionada!,
        quantidadesRetiradas: quantidadesSelecionadas,
        comprovantesUrls: urls,
        userId: userId,
      );

      notaSelecionada = notaAtualizada;
      status = RetiradaStatus.success;
      
    } catch (e) {
      status = RetiradaStatus.error;
      errorMessage = 'Erro ao salvar retirada: $e';
    } finally {
      notifyListeners();
    }
  }
}
