import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/services/estoque_produto_service.dart';
import 'package:notas_zincao_flutter/services/nota_form_service.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';

/// Campos obrigatórios que a IA precisa preencher.
/// Se não forem preenchidos, devem piscar em vermelho.
enum CampoObrigatorio {
  nomeCliente,
  telefoneCliente,
  numeroNota,
  serieNota,
  dataCompra,
}

/// Estados possíveis da tela.
enum NotaFormStatus {
  idle,
  pickingImage,
  uploadingImage,
  analyzingReceipt,
  saving,
  success,
  duplicateFound,
  error,
  quotaExceeded,
}

/// ViewModel para a tela de Nova Nota.
/// Gerencia todo o fluxo: captura → IA → formulário → salvar.
class NotaFormViewModel extends ChangeNotifier {
  final NotaFormService _service = NotaFormService();
  final EstoqueProdutoService _estoqueService = EstoqueProdutoService();
  bool _isDisposed = false;

  NotaFormViewModel() {
    nomeClienteCtrl.addListener(_onFieldChanged);
    telefoneClienteCtrl.addListener(_onFieldChanged);
    numeroNotaCtrl.addListener(_onFieldChanged);
    serieNotaCtrl.addListener(_onFieldChanged);
    dataCompraCtrl.addListener(_onFieldChanged);
    descontoCtrl.addListener(_onDiscountChanged);
  }

  void _onFieldChanged() {
    // Se o campo estava marcado como faltante e agora não está mais vazio,
    // removemos da lista para parar de piscar.
    if (_missingFields.isEmpty) return;
    _checkMissingFields();
  }

  void _onDiscountChanged() {
    _notifySafe();
  }

  // ─── Estado ──────────────────────────────────────────────────

  NotaFormStatus _status = NotaFormStatus.idle;
  NotaFormStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  NotaRetirada? _notaDuplicada;
  NotaRetirada? get notaDuplicada => _notaDuplicada;

  String? _duplicateReason;
  String? get duplicateReason => _duplicateReason;

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  String? _uploadedImageUrl;
  String? get uploadedImageUrl => _uploadedImageUrl;

  /// Campos que estão faltando (devem piscar em vermelho).
  final Set<CampoObrigatorio> _missingFields = {};
  Set<CampoObrigatorio> get missingFields => Set.unmodifiable(_missingFields);

  bool _aiProcessed = false;
  bool get aiProcessed => _aiProcessed;

  double? _valorTotalFotoAnalisada;
  double? get valorTotalFotoAnalisada => _valorTotalFotoAnalisada;

  double? _divergenciaTotalFotoItens;
  double? get divergenciaTotalFotoItens => _divergenciaTotalFotoItens;

  bool _quotaExceeded = false;
  bool get quotaExceeded => _quotaExceeded;

  void clearQuotaError() {
    _quotaExceeded = false;
    _setStatus(NotaFormStatus.idle);
  }

  // ─── Campos do Formulário ────────────────────────────────────

  final TextEditingController nomeClienteCtrl = TextEditingController();
  final TextEditingController documentoClienteCtrl = TextEditingController();
  final TextEditingController telefoneClienteCtrl = TextEditingController();
  final TextEditingController numeroNotaCtrl = TextEditingController();
  final TextEditingController serieNotaCtrl = TextEditingController(text: '1');
  final TextEditingController chaveNfeCtrl = TextEditingController();
  final TextEditingController dataCompraCtrl = TextEditingController();
  final TextEditingController dataPrevistaRetiradaCtrl = TextEditingController();
  final TextEditingController valorTotalCtrl = TextEditingController();
  final TextEditingController descontoCtrl = TextEditingController(text: '0.00');
  final TextEditingController observacoesCtrl = TextEditingController();
  final TextEditingController contatoIdCtrl = TextEditingController();

  double get descontoTotalInformado => _parseCurrency(descontoCtrl.text);

  double get valorTotalBruto {
    if (_produtos.isNotEmpty) {
      return _calcularTotalProdutos(_produtos);
    }
    return _parseCurrency(valorTotalCtrl.text);
  }

  double get valorTotalComDesconto {
    final liquido = valorTotalBruto - descontoTotalInformado;
    return liquido < 0 ? 0 : liquido;
  }

  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> get produtos => List.unmodifiable(_produtos);

  List<ProdutoEstoque> _produtosCatalogo = [];
  List<ProdutoEstoque> get produtosCatalogo => List.unmodifiable(_produtosCatalogo);

  bool _isLoadingProdutosCatalogo = false;
  bool get isLoadingProdutosCatalogo => _isLoadingProdutosCatalogo;

  // ─── Ações ───────────────────────────────────────────────────

  Future<void> loadProdutosCatalogo() async {
    if (_isDisposed) return;
    _isLoadingProdutosCatalogo = true;
    _notifySafe();

    try {
      _produtosCatalogo = await _estoqueService.searchForNotePicker(limit: 20);
    } catch (_) {
      _produtosCatalogo = [];
    } finally {
      if (!_isDisposed) {
        _isLoadingProdutosCatalogo = false;
        _notifySafe();
      }
    }
  }

  /// Tira foto com a câmera.
  Future<void> capturePhoto() async {
    _setStatus(NotaFormStatus.pickingImage);
    try {
      final file = await _service.captureFromCamera();
      if (file != null) {
        _selectedImage = file;
        _aiProcessed = false;
        _uploadedImageUrl = null;
        _valorTotalFotoAnalisada = null;
        _divergenciaTotalFotoItens = null;
        _setStatus(NotaFormStatus.idle);
      } else {
        _setStatus(NotaFormStatus.idle);
      }
    } catch (e) {
      _setError('Erro ao capturar foto: $e');
    }
  }

  /// Seleciona foto da galeria.
  Future<void> pickPhoto() async {
    _setStatus(NotaFormStatus.pickingImage);
    try {
      final file = await _service.pickFromGallery();
      if (file != null) {
        _selectedImage = file;
        _aiProcessed = false;
        _uploadedImageUrl = null;
        _valorTotalFotoAnalisada = null;
        _divergenciaTotalFotoItens = null;
        _setStatus(NotaFormStatus.idle);
      } else {
        _setStatus(NotaFormStatus.idle);
      }
    } catch (e) {
      _setError('Erro ao selecionar foto: $e');
    }
  }

  /// Envia a foto para a OpenAI e preenche os campos automaticamente.
  Future<void> analyzeWithAI() async {
    if (_selectedImage == null) {
      _setError('Selecione ou tire uma foto primeiro.');
      return;
    }

    _setStatus(NotaFormStatus.analyzingReceipt);
    _missingFields.clear();

    try {
      final result = await _service.analyzeReceipt(_selectedImage!);
      _valorTotalFotoAnalisada = result.totalLiquidoFoto;
      _divergenciaTotalFotoItens = null;

      debugPrint(
        '🧾 [analyzeReceipt] bruto=${result.totalBrutoFoto}, liquido=${result.totalLiquidoFoto}, desconto=${result.descontoTotal}, valor_total=${result.valorTotal}',
      );

      // Preenche os campos com os dados da IA
      _fillField(nomeClienteCtrl, result.nomeCliente);
      _fillField(documentoClienteCtrl, result.documentoCliente);
      _fillField(telefoneClienteCtrl, result.telefoneCliente);
      _fillField(numeroNotaCtrl, result.numeroNota);
      _fillField(serieNotaCtrl, result.serieNota ?? '1');
      _fillField(chaveNfeCtrl, result.chaveNfe);
      _fillField(dataCompraCtrl, result.dataCompra);

      if (result.totalBrutoFoto != null) {
        valorTotalCtrl.text = result.totalBrutoFoto!.toStringAsFixed(2);
      }

      descontoCtrl.text = (result.descontoTotal ?? 0).toStringAsFixed(2);

      if (result.observacoes != null) {
        observacoesCtrl.text = result.observacoes!;
      }

      if (result.produtos.isNotEmpty) {
        _produtos = await _filtrarProdutosDoCatalogo(result.produtos);
      } else {
        _produtos = [];
      }

      if (_produtos.isNotEmpty) {
        final totalItens = _calcularTotalProdutos(_produtos);
        final totaisFoto = _resolverTotaisFoto(result, totalItens);
        _valorTotalFotoAnalisada = totaisFoto.totalLiquido;
        valorTotalCtrl.text = totalItens.toStringAsFixed(2);

        if (_valorTotalFotoAnalisada != null) {
          final desconto = result.descontoTotal ?? 0.0;
          final totalLiquido = totalItens - desconto;
          _divergenciaTotalFotoItens =
              (totalLiquido - _valorTotalFotoAnalisada!).abs();
          if (_divergenciaTotalFotoItens! > 0.01) {
            observacoesCtrl.text = _appendConferenciaAutomatica(
              observacoesCtrl.text,
              totalFoto: _valorTotalFotoAnalisada!,
              totalItens: totalLiquido,
            );
          }
        }
      } else if (result.totalBrutoFoto != null) {
        valorTotalCtrl.text = result.totalBrutoFoto!.toStringAsFixed(2);
      }

      _aiProcessed = true;

      // Verifica campos obrigatórios que ficaram vazios
      _checkMissingFields();

      _setStatus(NotaFormStatus.idle);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('insufficient_quota') || msg.contains('429')) {
        _quotaExceeded = true;
        _status = NotaFormStatus.quotaExceeded;
        _errorMessage = null;
        _notifySafe();
      } else {
        _setError('Erro na análise: $e');
      }
    }
  }

  /// Salva a nota no Supabase (upload da foto + inserção da nota).
  Future<void> saveNota(String ownerUserId) async {
    _missingFields.clear();
    _checkMissingFields();
    _notaDuplicada = null;
    _duplicateReason = null;

    if (_missingFields.isNotEmpty) {
      _setError('Preencha os campos obrigatórios destacados em vermelho.');
      return;
    }

    final erroProdutos = _validarProdutosAntesDeSalvar();
    if (erroProdutos != null) {
      _setError(erroProdutos);
      return;
    }

    final erroDesconto = _validarDesconto();
    if (erroDesconto != null) {
      _setError(erroDesconto);
      return;
    }

    final erroConferencia = _validarConferenciaComTotalDaFoto();
    if (erroConferencia != null) {
      _setError(erroConferencia);
      return;
    }

    final numeroDigitado = numeroNotaCtrl.text.trim();
    final chaveDigitada = chaveNfeCtrl.text.trim();

    try {
      final duplicada = await _service.findNotaDuplicada(
        numeroNota: numeroDigitado,
        chaveNfe: chaveDigitada.isEmpty ? null : chaveDigitada,
      );

      if (duplicada != null) {
        _notaDuplicada = duplicada;
        final duplicouPorNumero = numeroDigitado.isNotEmpty &&
            duplicada.numeroNota.trim() == numeroDigitado;
        final duplicouPorChave = chaveDigitada.isNotEmpty &&
            (duplicada.chaveNfe?.trim() == chaveDigitada);

        _duplicateReason = duplicouPorNumero && duplicouPorChave
            ? 'Já existe uma nota com este número e esta chave NFe.'
            : duplicouPorNumero
                ? 'Já existe uma nota com este número.'
                : 'Já existe uma nota com esta chave NFe.';

        _status = NotaFormStatus.duplicateFound;
        _errorMessage = null;
        _notifySafe();
        return;
      }
    } catch (e) {
      _setError('Erro ao verificar duplicidade da nota: $e');
      return;
    }

    _setStatus(NotaFormStatus.saving);

    try {
      // Upload da imagem se existir
      if (_selectedImage != null) {
        _setStatus(NotaFormStatus.uploadingImage);
        _uploadedImageUrl = await _service.uploadImage(_selectedImage!, ownerUserId);
        _setStatus(NotaFormStatus.saving);
      }

      // Parse da data de compra
      DateTime dataCompra;
      try {
        dataCompra = DateTime.parse(dataCompraCtrl.text);
      } catch (_) {
        // Tenta formato DD/MM/YYYY
        final parts = dataCompraCtrl.text.split('/');
        if (parts.length == 3) {
          dataCompra = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } else {
          throw Exception('Data de compra inválida');
        }
      }

      // Parse da data prevista de retirada (opcional)
      DateTime? dataPrevistaRetirada;
      if (dataPrevistaRetiradaCtrl.text.isNotEmpty) {
        try {
          dataPrevistaRetirada = DateTime.parse(dataPrevistaRetiradaCtrl.text);
        } catch (_) {
          final parts = dataPrevistaRetiradaCtrl.text.split('/');
          if (parts.length == 3) {
            dataPrevistaRetirada = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      }

      // Parse do valor total
      double? valorTotal;
      if (_produtos.isNotEmpty) {
        final totalCalculado = _calcularTotalProdutos(_produtos);
        valorTotalCtrl.text = totalCalculado.toStringAsFixed(2);
        valorTotal = totalCalculado;
      } else if (valorTotalCtrl.text.isNotEmpty) {
        valorTotal = _parseCurrency(valorTotalCtrl.text);
      }

      final descontoTotal = descontoTotalInformado;

      // Salva no CRM se o cliente não existe
      if (telefoneClienteCtrl.text.isNotEmpty && nomeClienteCtrl.text.isNotEmpty) {
        try {
          final existing = await supabase
              .from('crm_zincao')
              .select('contato_id')
              .eq('contato_id', telefoneClienteCtrl.text)
              .maybeSingle();

          if (existing == null) {
            await supabase.from('crm_zincao').insert({
              'contato_id': telefoneClienteCtrl.text,
              'nome': nomeClienteCtrl.text,
            });
          }
        } catch (e) {
          debugPrint('Erro ao sincronizar com CRM: $e');
        }
      }

      debugPrint('📝 [saveNota] Iniciando save — numeroNota=${numeroNotaCtrl.text}, dataCompra=$dataCompra, valorTotal=$valorTotal, desconto=$descontoTotal, produtos=${_produtos.length}');

      await _service.createNota(
        ownerUserId: ownerUserId,
        nomeCliente: nomeClienteCtrl.text,
        numeroNota: numeroNotaCtrl.text,
        dataCompra: dataCompra,
        fotoUrl: _uploadedImageUrl,
        documentoCliente: documentoClienteCtrl.text.isNotEmpty ? documentoClienteCtrl.text : null,
        telefoneCliente: telefoneClienteCtrl.text.isNotEmpty ? telefoneClienteCtrl.text : null,
        serieNota: serieNotaCtrl.text.isNotEmpty ? serieNotaCtrl.text : '1',
        chaveNfe: chaveNfeCtrl.text.isNotEmpty ? chaveNfeCtrl.text : null,
        dataPrevistaRetirada: dataPrevistaRetirada,
        produtos: _produtos,
        valorTotal: valorTotal,
        descontoTotal: descontoTotal,
        observacoes: observacoesCtrl.text.isNotEmpty ? observacoesCtrl.text : null,
        contatoId: contatoIdCtrl.text.isNotEmpty ? contatoIdCtrl.text : null,
      );

      _setStatus(NotaFormStatus.success);
    } catch (e, st) {
      debugPrint('❌ [saveNota] Erro ao salvar: $e');
      debugPrint('❌ [saveNota] StackTrace: $st');
      _setError('Erro ao salvar nota: $e');
    }
  }

  /// Reseta o formulário para cadastrar outra nota.
  void resetForm() {
    _selectedImage = null;
    _uploadedImageUrl = null;
    _aiProcessed = false;
    _valorTotalFotoAnalisada = null;
    _divergenciaTotalFotoItens = null;
    _missingFields.clear();
    _produtos = [];
    _notaDuplicada = null;
    _duplicateReason = null;

    nomeClienteCtrl.clear();
    documentoClienteCtrl.clear();
    telefoneClienteCtrl.clear();
    numeroNotaCtrl.clear();
    serieNotaCtrl.text = '1';
    chaveNfeCtrl.clear();
    dataCompraCtrl.clear();
    dataPrevistaRetiradaCtrl.clear();
    valorTotalCtrl.clear();
    descontoCtrl.text = '0.00';
    observacoesCtrl.clear();
    contatoIdCtrl.clear();

    _setStatus(NotaFormStatus.idle);
  }

  void clearDuplicateFound() {
    _notaDuplicada = null;
    _duplicateReason = null;
    if (_status == NotaFormStatus.duplicateFound) {
      _setStatus(NotaFormStatus.idle);
      return;
    }
    _notifySafe();
  }

  /// Adiciona um produto manualmente.
  void addProduto(Map<String, dynamic> produto) {
    if (produto['id_produto_estoque'] == null) return;
    _produtos.add(produto);
    _sincronizarValorTotalComProdutos();
    _notifySafe();
  }

  /// Remove um produto pelo índice.
  void removeProduto(int index) {
    if (index >= 0 && index < _produtos.length) {
      _produtos.removeAt(index);
      _sincronizarValorTotalComProdutos();
      _notifySafe();
    }
  }

  /// Atualiza um produto pelo índice.
  void updateProduto(int index, Map<String, dynamic> produto) {
    if (index >= 0 && index < _produtos.length) {
      if (produto['id_produto_estoque'] == null) return;
      _produtos[index] = produto;
      _sincronizarValorTotalComProdutos();
      _notifySafe();
    }
  }

  Map<String, dynamic> buildProdutoNotaFromCatalogo({
    required ProdutoEstoque produto,
    required double quantidade,
    double? valorUnitario,
  }) {
    final valor = valorUnitario ?? produto.valorPrecoVarejo ?? 0;
    return {
      'id_produto_estoque': produto.idProduto,
      'nome': produto.descricao,
      'tipo_produto': produto.tipoProduto,
      'quantidade': quantidade,
      'embalagem': produto.embalagemSaida,
      'tipo_unidade': produto.embalagemSaida,
      'valor_unitario': valor,
      'valor_total': valor * quantidade,
    };
  }

  Future<List<ProdutoEstoque>> searchProdutosCatalogo(String query) {
    return _estoqueService.searchForNotePicker(query: query, limit: 30);
  }

  Future<ProdutoEstoque?> findProdutoCatalogoById(int idProduto) {
    return _estoqueService.fetchById(idProduto);
  }

  Future<ProdutoEstoque?> findProdutoCatalogo(String nome) async {
    final targetOriginal = _normalizeText(nome);
    final target = _normalizeProductQuery(targetOriginal);
    if (target.isEmpty) return null;

    final consultas = <String>[
      nome.trim(),
      target,
      ..._buildSearchCandidates(target),
    ].where((q) => q.trim().isNotEmpty).toSet().toList();

    final agregados = <ProdutoEstoque>[];
    for (final consulta in consultas.take(5)) {
      final resultados = await _estoqueService.searchForNotePicker(query: consulta, limit: 30);
      for (final item in resultados) {
        final exists = agregados.any((p) => p.idProduto == item.idProduto && p.idProduto != null);
        if (!exists) {
          agregados.add(item);
        }
      }
      if (agregados.length >= 30) break;
    }

    if (agregados.isEmpty) return null;

    for (final produto in agregados) {
      if (_normalizeText(produto.descricao) == target) {
        return produto;
      }
    }

    for (final produto in agregados) {
      final descricaoNorm = _normalizeText(produto.descricao);
      if (descricaoNorm.contains(target) || target.contains(descricaoNorm)) {
        return produto;
      }
    }

    final tokenAlvo = target.split(' ').where((t) => t.length >= 3).toSet();
    ProdutoEstoque? melhor;
    var melhorScore = -1;

    for (final produto in agregados) {
      final descricao = _normalizeText(produto.descricao);
      final tokensDescricao = descricao.split(' ').where((t) => t.length >= 3).toSet();
      var score = tokensDescricao.intersection(tokenAlvo).length;
      if (descricao.contains(target)) score += 3;
      if (target.contains(descricao)) score += 2;

      if (score > melhorScore) {
        melhor = produto;
        melhorScore = score;
      }
    }

    if (melhor != null && melhorScore > 0) {
      return melhor;
    }

    return agregados.first;
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _checkMissingFields() {
    final prevMissing = Set<CampoObrigatorio>.from(_missingFields);
    _missingFields.clear();

    if (nomeClienteCtrl.text.trim().isEmpty) {
      _missingFields.add(CampoObrigatorio.nomeCliente);
    }
    if (telefoneClienteCtrl.text.trim().isEmpty) {
      _missingFields.add(CampoObrigatorio.telefoneCliente);
    }
    if (numeroNotaCtrl.text.trim().isEmpty) {
      _missingFields.add(CampoObrigatorio.numeroNota);
    }
    if (serieNotaCtrl.text.trim().isEmpty) {
      _missingFields.add(CampoObrigatorio.serieNota);
    }
    if (dataCompraCtrl.text.trim().isEmpty) {
      _missingFields.add(CampoObrigatorio.dataCompra);
    }

    // Só notifica se a lista de campos faltando mudou (otimização)
    if (prevMissing.length != _missingFields.length || 
        !prevMissing.every((e) => _missingFields.contains(e))) {
      _notifySafe();
    }
  }

  void _fillField(TextEditingController ctrl, String? value) {
    if (value != null && value.isNotEmpty) {
      ctrl.text = value;
    }
  }

  void _setStatus(NotaFormStatus s) {
    if (_isDisposed) return;
    _status = s;
    _errorMessage = null;
    _notifySafe();
  }

  void _setError(String msg) {
    if (_isDisposed) return;
    _status = NotaFormStatus.error;
    _errorMessage = msg;
    _notifySafe();
  }

  void _notifySafe() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeProductQuery(String value) {
    final base = value
        .replaceAll(RegExp(r'^\d+([.,]\d+)?\s*'), '')
        .replaceAll(RegExp(r'\b(un|und|pc|pcs|cx|kit)\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return base.isEmpty ? value : base;
  }

  List<String> _buildSearchCandidates(String normalized) {
    final tokens = normalized
        .split(' ')
        .map((t) => t.trim())
        .where((t) => t.length >= 3)
        .where((t) => !{'com', 'para', 'de', 'da', 'do', 'e'}.contains(t))
        .toList();

    final candidatos = <String>[];
    if (tokens.length >= 2) {
      candidatos.add(tokens.take(2).join(' '));
    }
    if (tokens.length >= 3) {
      candidatos.add(tokens.take(3).join(' '));
    }
    candidatos.addAll(tokens.take(3));
    return candidatos;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.').trim()) ?? 0;
  }

  double _parseCurrency(String value) {
    var clean = value
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .trim();

    if (clean.contains(',')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(clean) ?? 0;
  }

  double _calcularTotalProdutos(List<Map<String, dynamic>> itens) {
    var total = 0.0;
    for (final item in itens) {
      final quantidade = _toDouble(item['quantidade']);
      final valorUnitario = _toDouble(item['valor_unitario']);
      final valorTotalItem = quantidade * valorUnitario;
      total += valorTotalItem;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  String? _validarProdutosAntesDeSalvar() {
    if (_produtos.isEmpty) {
      return 'Adicione pelo menos 1 produto antes de salvar a nota.';
    }

    for (var i = 0; i < _produtos.length; i++) {
      final produto = _produtos[i];
      final quantidade = _toDouble(produto['quantidade']);
      final valorUnitario = _toDouble(produto['valor_unitario']);

      if (quantidade <= 0) {
        return 'A quantidade do produto ${i + 1} é inválida. Ajuste para um valor maior que zero.';
      }

      if (valorUnitario < 0) {
        return 'O valor unitário do produto ${i + 1} é inválido.';
      }

      final totalCalculado = double.parse((quantidade * valorUnitario).toStringAsFixed(2));
      produto['quantidade'] = quantidade;
      produto['valor_unitario'] = valorUnitario;
      produto['valor_total'] = totalCalculado;
    }

    return null;
  }

  String? _validarDesconto() {
    final desconto = descontoTotalInformado;
    if (desconto < 0) {
      return 'O valor do desconto não pode ser negativo.';
    }
    if (desconto > valorTotalBruto) {
      return 'O desconto não pode ser maior que o valor total da nota.';
    }
    return null;
  }

  void _sincronizarValorTotalComProdutos() {
    if (_produtos.isEmpty) return;
    final total = _calcularTotalProdutos(_produtos);
    valorTotalCtrl.text = total.toStringAsFixed(2);
  }

  String? _validarConferenciaComTotalDaFoto() {
    if (_valorTotalFotoAnalisada == null || _produtos.isEmpty) {
      return null;
    }

    final totalItens = _calcularTotalProdutos(_produtos);
    final desconto = descontoTotalInformado;
    final totalLiquido = totalItens - desconto;
    final divergencia = (totalLiquido - _valorTotalFotoAnalisada!).abs();
    _divergenciaTotalFotoItens = divergencia;

    if (divergencia > 0.01) {
      final descontoInfo = desconto > 0 ? ' - desconto R\$ ${desconto.toStringAsFixed(2)} = R\$ ${totalLiquido.toStringAsFixed(2)}' : '';
      return 'A soma dos itens (R\$ ${totalItens.toStringAsFixed(2)}$descontoInfo) está diferente do total da foto (R\$ ${_valorTotalFotoAnalisada!.toStringAsFixed(2)}). Revise quantidade e preços dos produtos antes de salvar.';
    }

    return null;
  }

  String _appendConferenciaAutomatica(
    String textoAtual, {
    required double totalFoto,
    required double totalItens,
  }) {
    const marcador = '[Conferência automática IA]';
    final linhas = textoAtual
        .split('\n')
        .where((linha) => !linha.trim().startsWith(marcador))
        .toList();

    linhas.add(
      '$marcador Total da foto: ${totalFoto.toStringAsFixed(2)} | Soma dos itens: ${totalItens.toStringAsFixed(2)}',
    );

    return linhas.where((linha) => linha.trim().isNotEmpty).join('\n');
  }

  ({double? totalBruto, double? totalLiquido}) _resolverTotaisFoto(
    CupomAnaliseResult result,
    double totalItens,
  ) {
    final desconto = result.descontoTotal ?? 0.0;

    if (result.valorTotalBruto != null || result.valorTotalLiquido != null) {
      return (
        totalBruto: result.totalBrutoFoto,
        totalLiquido: result.totalLiquidoFoto,
      );
    }

    final valorReportado = result.valorTotal;
    if (valorReportado == null) {
      final liquido = totalItens - desconto;
      return (
        totalBruto: totalItens,
        totalLiquido: liquido < 0 ? 0 : liquido,
      );
    }

    final totalLiquidoItens = totalItens - desconto;
    final diffBruto = (totalItens - valorReportado).abs();
    final diffLiquido = (totalLiquidoItens - valorReportado).abs();

    if (diffLiquido <= 0.01 || diffLiquido < diffBruto) {
      return (
        totalBruto: totalItens,
        totalLiquido: valorReportado,
      );
    }

    final liquido = valorReportado - desconto;
    return (
      totalBruto: valorReportado,
      totalLiquido: liquido < 0 ? 0 : liquido,
    );
  }

  Future<List<Map<String, dynamic>>> _filtrarProdutosDoCatalogo(List<Map<String, dynamic>> produtosDaIa) async {
    final itens = <Map<String, dynamic>>[];

    for (final produtoIa in produtosDaIa) {
      final nome = (produtoIa['nome'] ?? '').toString().trim();
      if (nome.isEmpty) continue;

      ProdutoEstoque? produtoCatalogo;

      final idDireto = produtoIa['id_produto_estoque'] ?? produtoIa['id_produto'];
      final idProduto = idDireto is int ? idDireto : int.tryParse((idDireto ?? '').toString());
      if (idProduto != null) {
        produtoCatalogo = await findProdutoCatalogoById(idProduto);
      }

      if (produtoCatalogo == null) {
        for (final candidatoId in _extractCandidateProductIds(nome)) {
          produtoCatalogo = await findProdutoCatalogoById(candidatoId);
          if (produtoCatalogo != null) {
            break;
          }
        }
      }

      produtoCatalogo ??= await findProdutoCatalogo(nome);

      if (produtoCatalogo == null || produtoCatalogo.idProduto == null) {
        continue;
      }

      final quantidade = double.tryParse(
            (produtoIa['quantidade'] ?? '1').toString().replaceAll(',', '.'),
          ) ??
          1;

      final valorUnitario = produtoCatalogo.valorPrecoVarejo ?? 0;

      itens.add(
        buildProdutoNotaFromCatalogo(
          produto: produtoCatalogo,
          quantidade: quantidade <= 0 ? 1 : quantidade,
          valorUnitario: valorUnitario,
        ),
      );
    }

    return itens;
  }

  List<int> _extractCandidateProductIds(String nome) {
    final ids = <int>[];
    final matches = RegExp(r'\b(?:id|cod|codigo|produto)\s*[:#-]?\s*(\d{2,})\b', caseSensitive: false)
        .allMatches(nome);

    for (final match in matches) {
      final id = int.tryParse(match.group(1) ?? '');
      if (id != null && !ids.contains(id)) {
        ids.add(id);
      }
    }

    return ids;
  }

  @override
  void dispose() {
    _isDisposed = true;
    nomeClienteCtrl.removeListener(_onFieldChanged);
    telefoneClienteCtrl.removeListener(_onFieldChanged);
    numeroNotaCtrl.removeListener(_onFieldChanged);
    serieNotaCtrl.removeListener(_onFieldChanged);
    dataCompraCtrl.removeListener(_onFieldChanged);
    descontoCtrl.removeListener(_onDiscountChanged);

    nomeClienteCtrl.dispose();
    documentoClienteCtrl.dispose();
    telefoneClienteCtrl.dispose();
    numeroNotaCtrl.dispose();
    serieNotaCtrl.dispose();
    chaveNfeCtrl.dispose();
    dataCompraCtrl.dispose();
    dataPrevistaRetiradaCtrl.dispose();
    valorTotalCtrl.dispose();
    descontoCtrl.dispose();
    observacoesCtrl.dispose();
    contatoIdCtrl.dispose();
    super.dispose();
  }
}
