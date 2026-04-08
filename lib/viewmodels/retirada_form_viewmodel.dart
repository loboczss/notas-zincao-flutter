import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/services/estoque_produto_service.dart';
import 'package:notas_zincao_flutter/services/pending_retirada_service.dart';
import 'package:notas_zincao_flutter/services/retirada_form_service.dart';
import 'package:notas_zincao_flutter/viewmodels/product_stock_header_viewmodel.dart';

enum RetiradaStatus { idle, capturing, saving, success, error }

class RetiradaViewModel extends ChangeNotifier {
  final RetiradaService _service = RetiradaService();
  final EstoqueProdutoService _estoqueService = EstoqueProdutoService();
  final ImagePicker _picker = ImagePicker();

  bool _isDisposed = false;

  NotaRetirada? notaSelecionada;

  // Mapa de Indice do Produto -> Quantidade selecionada para retirar agora
  final Map<int, double> quantidadesSelecionadas = {};

  // Fotos capturadas como comprovante para esta retirada
  final List<File> fotosComprovante = [];

  final Map<int, double> estoqueDisponivelPorIndex = {};
  final Map<int, String> parentInfoPorIndex = {};

  RetiradaStatus status = RetiradaStatus.idle;
  String? errorMessage;

  /// true quando a última retirada foi salva localmente e aguarda sincronização.
  bool syncPendente = false;

  String _mapRetiradaError(Object error) {
    final text = error.toString();
    if (text.contains('nao existe no estoque') ||
        text.contains('não existe no estoque')) {
      return 'Um ou mais produtos da nota nao existem no estoque. Abra a tela de Estoque, cadastre/vincule os produtos e tente novamente.';
    }
    if (text.contains('nao pode ser vinculado ao estoque') ||
        text.contains('não pode ser vinculado ao estoque')) {
      return 'Existe produto sem nome ou sem vinculo. Corrija na nota e vincule ao estoque antes de confirmar a retirada.';
    }
    return 'Erro ao salvar retirada: $error';
  }

  /// Inicializa o ViewModel com uma nota
  void init(NotaRetirada nota) {
    notaSelecionada = nota;
    quantidadesSelecionadas.clear();
    fotosComprovante.clear();
    estoqueDisponivelPorIndex.clear();
    parentInfoPorIndex.clear();

    // Inicializa as quantidades selecionadas com 0.0
    for (int i = 0; i < nota.produtos.length; i++) {
      quantidadesSelecionadas[i] = 0.0;
    }

    status = RetiradaStatus.idle;
    errorMessage = null;
    syncPendente = false;
    notifyListeners();

    _loadEstoqueDisponivel();
  }

  Future<void> _loadEstoqueDisponivel() async {
    if (notaSelecionada == null) return;

    try {
      final ids = <int>[];
      for (int i = 0; i < notaSelecionada!.produtos.length; i++) {
        final raw = notaSelecionada!.produtos[i];
        if (raw is! Map) continue;
        final p = Map<String, dynamic>.from(raw);
        final idProduto = p[ColsProdutoNota.idProdutoEstoque];
        if (idProduto is int) {
          ids.add(idProduto);
        }
      }

      final produtosEstoque = await _estoqueService.fetchByIds(ids);
      final produtosMap = {
        for (var p in produtosEstoque)
          if (p.idProduto != null) p.idProduto!: p
      };

      final idsPai = produtosEstoque
          .map((p) => p.idProdutoPai)
          .where((id) => id != null)
          .cast<int>()
          .toSet()
          .toList();

      final paisEstoque = idsPai.isNotEmpty
          ? await _estoqueService.fetchByIds(idsPai)
          : <ProdutoEstoque>[];

      final paisMap = {
        for (var p in paisEstoque)
          if (p.idProduto != null) p.idProduto!: p
      };

      if (_isDisposed) return;

      for (int i = 0; i < notaSelecionada!.produtos.length; i++) {
        final raw = notaSelecionada!.produtos[i];
        if (raw is! Map) continue;
        final p = Map<String, dynamic>.from(raw);
        final idProduto = p[ColsProdutoNota.idProdutoEstoque];
        if (idProduto is int) {
          final prod = produtosMap[idProduto];
          if (prod != null) {
            if (prod.idProdutoPai != null &&
                paisMap.containsKey(prod.idProdutoPai)) {
              final pai = paisMap[prod.idProdutoPai]!;
              final fator =
                  (prod.fatorConversao ?? 1.0) <= 0 ? 1.0 : prod.fatorConversao!;
              estoqueDisponivelPorIndex[i] = pai.quantidadeEstoque / fator;
              parentInfoPorIndex[i] =
                  'Vinculado ao estoque: ${pai.descricao} (ID ${pai.idProduto})';
            } else {
              estoqueDisponivelPorIndex[i] = prod.quantidadeEstoque;
            }
          } else {
            estoqueDisponivelPorIndex[i] = 0;
          }
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  double getQuantidadeMaxima(int index) {
    final saldoNota = getSaldoNota(index);

    final estoqueDisponivel = estoqueDisponivelPorIndex[index];
    if (estoqueDisponivel == null) {
      return saldoNota < 0 ? 0 : saldoNota;
    }

    final maximo =
        saldoNota <= estoqueDisponivel ? saldoNota : estoqueDisponivel;
    return maximo < 0 ? 0 : maximo;
  }

  double getQuantidadeOriginal(int index) {
    final produtos = notaSelecionada?.produtos;
    if (produtos == null || index >= produtos.length) return 0.0;
    final raw = produtos[index];
    if (raw is! Map) return 0.0;
    final p = Map<String, dynamic>.from(raw);
    double qtdOriginal =
        double.tryParse(p[ColsProdutoNota.quantidade]?.toString() ?? '1') ?? 1.0;
    if (qtdOriginal <= 0) qtdOriginal = 1.0;
    return qtdOriginal;
  }

  double getQuantidadeJaRetirada(int index) {
    final produtos = notaSelecionada?.produtos;
    if (produtos == null || index >= produtos.length) return 0.0;
    final raw = produtos[index];
    if (raw is! Map) return 0.0;
    final p = Map<String, dynamic>.from(raw);
    return double.tryParse(
            p[ColsProdutoNota.quantidadeRetirada]?.toString() ?? '0') ??
        0.0;
  }

  double getSaldoNota(int index) {
    final saldo = getQuantidadeOriginal(index) - getQuantidadeJaRetirada(index);
    return saldo < 0 ? 0 : saldo;
  }

  bool isProdutoEntregue(int index) {
    return getSaldoNota(index) <= 0.001;
  }

  bool isSemEstoqueDisponivel(int index) {
    if (isProdutoEntregue(index)) return false;
    final estoque = estoqueDisponivelPorIndex[index];
    return estoque != null && estoque <= 0.001;
  }

  String? validarAntesDeConfirmar() {
    if (fotosComprovante.isEmpty) {
      return 'Adicione pelo menos 1 foto do comprovante.';
    }

    if (!temAlgumProdutoSelecionado) {
      return 'Selecione pelo menos 1 produto para retirada.';
    }

    var houveItemValido = false;
    var houveAjuste = false;

    quantidadesSelecionadas.forEach((index, selecionada) {
      if (selecionada <= 0) return;
      final max = getQuantidadeMaxima(index);

      if (max <= 0.001) {
        quantidadesSelecionadas[index] = 0;
        houveAjuste = true;
        return;
      }

      if (selecionada > max) {
        quantidadesSelecionadas[index] = max;
        houveAjuste = true;
      }

      if ((quantidadesSelecionadas[index] ?? 0) > 0) {
        houveItemValido = true;
      }
    });

    if (houveAjuste) {
      notifyListeners();
    }

    if (!houveItemValido) {
      return 'Nenhum item selecionado possui saldo disponível em estoque no momento.';
    }

    return null;
  }

  void incrementarQuantidade(int index) {
    final atual = quantidadesSelecionadas[index] ?? 0.0;
    final max = getQuantidadeMaxima(index);
    // Incrementa em 0.1 para permitir fracionados
    const incremento = 0.1;
    final novo = double.parse((atual + incremento).toStringAsFixed(2));
    if (novo <= max) {
      quantidadesSelecionadas[index] = novo;
      notifyListeners();
    } else if (atual < max) {
      quantidadesSelecionadas[index] = max;
      notifyListeners();
    }
  }

  void decrementarQuantidade(int index) {
    final atual = quantidadesSelecionadas[index] ?? 0.0;
    // Decrementa em 0.1 para permitir fracionados
    const incremento = 0.1;
    final novo = double.parse((atual - incremento).toStringAsFixed(2));
    if (novo >= 0) {
      quantidadesSelecionadas[index] = novo;
      notifyListeners();
    } else if (atual > 0) {
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

  Future<void> confirmarRetirada(
    String userId, {
    required String? userRole,
    required String? userName,
  }) async {
    if (notaSelecionada == null) return;

    final normalizedRole = (userRole ?? '').trim().toLowerCase();
    final canMakeRetirada =
        normalizedRole == 'admin' || normalizedRole == 'colaborador';
    if (!canMakeRetirada) {
      status = RetiradaStatus.error;
      errorMessage =
          'Você não tem permissão para registrar retirada de produtos.';
      notifyListeners();
      return;
    }

    final erroValidacao = validarAntesDeConfirmar();
    if (erroValidacao != null) {
      status = RetiradaStatus.error;
      errorMessage = erroValidacao;
      notifyListeners();
      return;
    }

    status = RetiradaStatus.saving;
    errorMessage = null;
    notifyListeners();

    try {
      // Verifica conectividade antes de tentar operações de rede
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline =
          connectivity.every((r) => r == ConnectivityResult.none);

      if (isOffline) {
        await _confirmarOffline(userId, userRole: userRole, userName: userName);
        return;
      }

      // 1. Upload das Fotos
      final urls = await _service.uploadImages(fotosComprovante, userId);

      // 2. Registro no Banco de Dados
      final notaAtualizada = await _service.registrarRetirada(
        nota: notaSelecionada!,
        quantidadesRetiradas: quantidadesSelecionadas,
        comprovantesUrls: urls,
        userId: userId,
        userName: userName,
        userRole: userRole,
      );

      notaSelecionada = notaAtualizada;

      // Atualiza o saldo do produto no header
      ProductStockHeaderViewModel.instance.refreshStock();

      syncPendente = false;
      status = RetiradaStatus.success;
    } catch (e) {
      status = RetiradaStatus.error;
      errorMessage = _mapRetiradaError(e);
    } finally {
      notifyListeners();
    }
  }

  // ─── Fluxo Offline ────────────────────────────────────────────────

  Future<void> _confirmarOffline(
    String userId, {
    required String? userRole,
    required String? userName,
  }) async {
    final pendingService = PendingRetiradaService();
    final pendingId = 'retirada_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Persiste as fotos em local estável para sobreviver a reinicializações
    final fotosPaths =
        await pendingService.persistPhotos(fotosComprovante, pendingId);

    // 2. Enfileira a operação
    final item = PendingRetiradaItem(
      id: pendingId,
      notaId: notaSelecionada!.id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      quantidades: Map.from(quantidadesSelecionadas),
      fotosPaths: fotosPaths,
      timestamp: DateTime.now(),
    );
    await pendingService.add(item);

    // 3. Atualiza o estado da nota localmente (otimista, sem RPC de estoque)
    notaSelecionada = _calcularRetiradaLocal(
      nota: notaSelecionada!,
      quantidades: quantidadesSelecionadas,
      userId: userId,
      userName: userName,
    );

    syncPendente = true;
    status = RetiradaStatus.success;
    notifyListeners();
  }

  /// Aplica a retirada localmente sem chamadas de rede.
  /// Usa as quantidades solicitadas diretamente (sem validação via RPC de estoque).
  NotaRetirada _calcularRetiradaLocal({
    required NotaRetirada nota,
    required Map<int, double> quantidades,
    required String userId,
    String? userName,
  }) {
    final novosProdutos = List<dynamic>.from(nota.produtos);
    bool todasRetiradas = true;
    final retiradasEfetivas = <int, double>{};

    for (int i = 0; i < novosProdutos.length; i++) {
      final raw = novosProdutos[i];
      if (raw is! Map) continue;
      final p = Map<String, dynamic>.from(raw);

      final qtdOriginal =
          double.tryParse(p[ColsProdutoNota.quantidade]?.toString() ?? '1') ??
              1.0;
      final qtdJaRetirada = double.tryParse(
              p[ColsProdutoNota.quantidadeRetirada]?.toString() ?? '0') ??
          0.0;
      final saldo = (qtdOriginal - qtdJaRetirada).clamp(0.0, double.infinity);
      final qtdRetirandoAgora = (quantidades[i] ?? 0.0).clamp(0.0, saldo);

      retiradasEfetivas[i] = qtdRetirandoAgora;
      p[ColsProdutoNota.quantidadeRetirada] = qtdJaRetirada + qtdRetirandoAgora;
      novosProdutos[i] = p;

      final novaQtdRetirada = qtdJaRetirada + qtdRetirandoAgora;
      if ((novaQtdRetirada + 0.001) < qtdOriginal) {
        todasRetiradas = false;
      }
    }

    final novoStatusStr = todasRetiradas ? 'retirada' : 'parcial';
    final novoHistorico = List<dynamic>.from(nota.historicoRetiradas ?? []);

    if (retiradasEfetivas.values.any((q) => q > 0)) {
      novoHistorico.add({
        'data': DateTime.now().toIso8601String(),
        'responsavel_id': userId,
        'responsavel_nome':
            (userName ?? '').trim().isEmpty ? 'Usuario' : userName!.trim(),
        'fotos': <String>[],
        'itens_retirados': retiradasEfetivas.entries
            .map((e) => {
                  'index': e.key,
                  'quantidade': e.value,
                  'quantidade_solicitada': quantidades[e.key] ?? 0,
                })
            .toList(),
      });
    }

    return nota.copyWith(
      produtos: novosProdutos,
      historicoRetiradas: novoHistorico,
      statusRetirada: StatusRetirada.fromString(novoStatusStr),
      retiradaConfirmadaPor: userId,
      dataRetirada: novoStatusStr == 'retirada' && nota.dataRetirada == null
          ? DateTime.now()
          : nota.dataRetirada,
    );
  }
}
