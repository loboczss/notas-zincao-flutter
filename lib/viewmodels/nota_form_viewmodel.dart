import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/models/produto_estoque.dart';
import 'package:notas_zincao_flutter/services/estoque_produto_service.dart';
import 'package:notas_zincao_flutter/services/nota_form_service.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form/nota_form_catalog_viewmodel.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form/nota_form_enums.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form/nota_form_fields_viewmodel.dart';
import 'package:notas_zincao_flutter/viewmodels/nota_form/nota_form_photo_viewmodel.dart';

export 'package:notas_zincao_flutter/viewmodels/nota_form/nota_form_enums.dart';

/// ViewModel para a tela de Nova Nota.
/// Gerencia todo o fluxo: captura → IA → formulário → salvar.
class NotaFormViewModel extends ChangeNotifier {
  final NotaFormService _service = NotaFormService();
  final EstoqueProdutoService _estoqueService = EstoqueProdutoService();
  late final NotaFormFieldsViewModel _fieldsVm;
  late final NotaFormPhotoViewModel _photoVm;
  late final NotaFormCatalogViewModel _catalogVm;
  bool _isDisposed = false;

  NotaFormViewModel() {
    _fieldsVm = NotaFormFieldsViewModel();
    _photoVm = NotaFormPhotoViewModel();
    _catalogVm = NotaFormCatalogViewModel(_estoqueService);

    _fieldsVm.addListener(_notifySafe);
    _photoVm.addListener(_notifySafe);
    _catalogVm.addListener(_onCatalogChanged);
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

  File? get selectedImage => _photoVm.selectedImage;
  String? get uploadedImageUrl => _photoVm.uploadedImageUrl;
  Set<CampoObrigatorio> get missingFields => _fieldsVm.missingFields;
  bool get aiProcessed => _photoVm.aiProcessed;
  double? get valorTotalFotoAnalisada => _photoVm.valorTotalFotoAnalisada;
  double? get divergenciaTotalFotoItens => _photoVm.divergenciaTotalFotoItens;
  bool get quotaExceeded => _photoVm.quotaExceeded;

  void clearQuotaError() {
    _photoVm.clearQuotaError();
    _setStatus(NotaFormStatus.idle);
  }

  // ─── Campos do Formulário ────────────────────────────────────

  TextEditingController get nomeClienteCtrl => _fieldsVm.nomeClienteCtrl;
  TextEditingController get documentoClienteCtrl => _fieldsVm.documentoClienteCtrl;
  TextEditingController get telefoneClienteCtrl => _fieldsVm.telefoneClienteCtrl;
  TextEditingController get numeroNotaCtrl => _fieldsVm.numeroNotaCtrl;
  TextEditingController get serieNotaCtrl => _fieldsVm.serieNotaCtrl;
  TextEditingController get chaveNfeCtrl => _fieldsVm.chaveNfeCtrl;
  TextEditingController get dataCompraCtrl => _fieldsVm.dataCompraCtrl;
  TextEditingController get dataPrevistaRetiradaCtrl => _fieldsVm.dataPrevistaRetiradaCtrl;
  TextEditingController get valorTotalCtrl => _fieldsVm.valorTotalCtrl;
  TextEditingController get descontoCtrl => _fieldsVm.descontoCtrl;
  TextEditingController get observacoesCtrl => _fieldsVm.observacoesCtrl;
  TextEditingController get contatoIdCtrl => _fieldsVm.contatoIdCtrl;

  double get descontoTotalInformado => _fieldsVm.descontoTotalInformado;

  double get valorTotalBruto {
    if (_catalogVm.produtos.isNotEmpty) {
      return _catalogVm.calcularTotalProdutos();
    }
    return _fieldsVm.parseCurrency(valorTotalCtrl.text);
  }

  double get valorTotalComDesconto {
    final liquido = valorTotalBruto - descontoTotalInformado;
    return liquido < 0 ? 0 : liquido;
  }

  List<Map<String, dynamic>> get produtos => _catalogVm.produtos;
  List<ProdutoEstoque> get produtosCatalogo => _catalogVm.produtosCatalogo;
  bool get isLoadingProdutosCatalogo => _catalogVm.isLoadingProdutosCatalogo;

  // ─── Ações ───────────────────────────────────────────────────

  Future<void> loadProdutosCatalogo() async {
    if (_isDisposed) return;
    await _catalogVm.loadProdutosCatalogo();
  }

  Future<void> capturePhoto() =>
      _handlePhotoPick(_service.captureFromCamera, 'capturar foto');

  Future<void> pickPhoto() =>
      _handlePhotoPick(_service.pickFromGallery, 'selecionar foto');

  /// Envia a foto para a OpenAI e preenche os campos automaticamente.
  Future<void> analyzeWithAI() async {
    if (_photoVm.selectedImage == null) {
      _setError('Selecione ou tire uma foto primeiro.');
      return;
    }

    _setStatus(NotaFormStatus.analyzingReceipt);
    _fieldsVm.clearMissingFields();

    try {
      final result = await _service.analyzeReceipt(_photoVm.selectedImage!);
      _photoVm.iniciarAnalise();

      debugPrint(
        '🧾 [analyzeReceipt] bruto=${result.totalBrutoFoto}, liquido=${result.totalLiquidoFoto}, desconto=${result.descontoTotal}, valor_total=${result.valorTotal}',
      );

      _fieldsVm.fillField(nomeClienteCtrl, result.nomeCliente);
      _fieldsVm.fillField(documentoClienteCtrl, result.documentoCliente);
      _fieldsVm.fillField(telefoneClienteCtrl, result.telefoneCliente);
      _fieldsVm.fillField(numeroNotaCtrl, result.numeroNota);
      _fieldsVm.fillField(serieNotaCtrl, result.serieNota ?? '1');
      _fieldsVm.fillField(chaveNfeCtrl, result.chaveNfe);
      _fieldsVm.fillField(dataCompraCtrl, result.dataCompra);

      if (result.totalBrutoFoto != null) {
        valorTotalCtrl.text = result.totalBrutoFoto!.toStringAsFixed(2);
      }
      descontoCtrl.text = (result.descontoTotal ?? 0).toStringAsFixed(2);
      if (result.observacoes != null) observacoesCtrl.text = result.observacoes ?? '';

      if (result.produtos.isNotEmpty) {
        _catalogVm.setProdutos(await _catalogVm.filtrarProdutosDoCatalogo(result.produtos));
      } else {
        _catalogVm.clearProdutos();
      }

      double? finalValorTotal = result.totalLiquidoFoto;
      double? finalDivergencia;

      if (_catalogVm.produtos.isNotEmpty) {
        final totalItens = _catalogVm.calcularTotalProdutos();
        final totaisFoto = _resolverTotaisFoto(result, totalItens);
        finalValorTotal = totaisFoto.totalLiquido;
        valorTotalCtrl.text = totalItens.toStringAsFixed(2);

        if (finalValorTotal != null) {
          final desconto = result.descontoTotal ?? 0;
          final totalLiquido = totalItens - desconto;
          finalDivergencia = (totalLiquido - finalValorTotal).abs();
          if (finalDivergencia > 0.01) {
            observacoesCtrl.text = _appendConferenciaAutomatica(
              observacoesCtrl.text,
              totalFoto: finalValorTotal,
              totalItens: totalLiquido,
            );
          }
        }
      } else if (result.totalBrutoFoto != null) {
        valorTotalCtrl.text = result.totalBrutoFoto!.toStringAsFixed(2);
      }

      _photoVm.concluirAnalise(valorTotal: finalValorTotal, divergencia: finalDivergencia);
      _fieldsVm.checkMissingFields();
      _setStatus(NotaFormStatus.idle);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('insufficient_quota') || msg.contains('429')) {
        _photoVm.setQuotaExceeded(true);
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
    if (_isDisposed) return;
    _fieldsVm.clearMissingFields();
    _fieldsVm.checkMissingFields();
    _notaDuplicada = null;
    _duplicateReason = null;

    if (_fieldsVm.missingFields.isNotEmpty) {
      _setError('Preencha os campos obrigatórios destacados em vermelho.');
      return;
    }

    final erroProdutos = _catalogVm.validarProdutosAntesDeSalvar();
    if (erroProdutos != null) { _setError(erroProdutos); return; }

    final erroDesconto = _validarDesconto();
    if (erroDesconto != null) { _setError(erroDesconto); return; }

    final erroConferencia = _validarConferenciaComTotalDaFoto();
    if (erroConferencia != null) { _setError(erroConferencia); return; }

    if (await _verificarDuplicata()) return;

    _setStatus(NotaFormStatus.saving);
    try {
      await _uploadPhotoIfNeeded(ownerUserId);

      final dataCompra = _parseDate(dataCompraCtrl.text);
      if (dataCompra == null) throw Exception('Data de compra inválida');
      final dataPrevista = _parseDate(dataPrevistaRetiradaCtrl.text);
      final valorTotal = _calcularValorTotal();

      await _service.upsertCrmContact(
        telefone: telefoneClienteCtrl.text,
        nome: nomeClienteCtrl.text,
      );

      debugPrint('📝 [saveNota] numeroNota=${numeroNotaCtrl.text}, dataCompra=$dataCompra, valorTotal=$valorTotal, desconto=$descontoTotalInformado, produtos=${_catalogVm.produtos.length}');

      await _service.createNota(
        ownerUserId: ownerUserId,
        nomeCliente: nomeClienteCtrl.text,
        numeroNota: numeroNotaCtrl.text,
        dataCompra: dataCompra,
        fotoUrl: _photoVm.uploadedImageUrl,
        documentoCliente: documentoClienteCtrl.text.isNotEmpty ? documentoClienteCtrl.text : null,
        telefoneCliente: telefoneClienteCtrl.text.isNotEmpty ? telefoneClienteCtrl.text : null,
        serieNota: serieNotaCtrl.text.isNotEmpty ? serieNotaCtrl.text : '1',
        chaveNfe: chaveNfeCtrl.text.isNotEmpty ? chaveNfeCtrl.text : null,
        dataPrevistaRetirada: dataPrevista,
        produtos: _catalogVm.produtos,
        valorTotal: valorTotal,
        descontoTotal: descontoTotalInformado,
        observacoes: observacoesCtrl.text.isNotEmpty ? observacoesCtrl.text : null,
        contatoId: contatoIdCtrl.text.isNotEmpty ? contatoIdCtrl.text : null,
      );

      _setStatus(NotaFormStatus.success);
    } catch (e, st) {
      debugPrint('❌ [saveNota] Erro ao salvar: $e\n$st');
      _setError('Erro ao salvar nota: $e');
    }
  }

  /// Reseta o formulário para cadastrar outra nota.
  void resetForm() {
    _photoVm.reset();
    _catalogVm.clearProdutos();
    _notaDuplicada = null;
    _duplicateReason = null;
    _fieldsVm.resetFields();
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

  void addProduto(Map<String, dynamic> produto) => _catalogVm.addProduto(produto);
  void removeProduto(int index) => _catalogVm.removeProduto(index);
  void updateProduto(int index, Map<String, dynamic> produto) => _catalogVm.updateProduto(index, produto);

  Map<String, dynamic> buildProdutoNotaFromCatalogo({
    required ProdutoEstoque produto,
    required double quantidade,
    double? valorUnitario,
  }) =>
      _catalogVm.buildProdutoNotaFromCatalogo(
        produto: produto,
        quantidade: quantidade,
        valorUnitario: valorUnitario,
      );

  Future<List<ProdutoEstoque>> searchProdutosCatalogo(String query) =>
      _catalogVm.searchProdutosCatalogo(query);

  Future<ProdutoEstoque?> findProdutoCatalogoById(int idProduto) =>
      _catalogVm.findProdutoCatalogoById(idProduto);

  Future<ProdutoEstoque?> findProdutoCatalogo(String nome) =>
      _catalogVm.findProdutoCatalogo(nome);

  // ─── Helpers privados ────────────────────────────────────────

  Future<void> _handlePhotoPick(
    Future<File?> Function() picker,
    String errorLabel,
  ) async {
    _setStatus(NotaFormStatus.pickingImage);
    try {
      final file = await picker();
      _photoVm.setSelectedImage(file);
      _setStatus(NotaFormStatus.idle);
    } catch (e) {
      _setError('Erro ao $errorLabel: $e');
    }
  }

  Future<void> _uploadPhotoIfNeeded(String ownerUserId) async {
    if (_photoVm.selectedImage == null) return;
    _setStatus(NotaFormStatus.uploadingImage);
    _photoVm.setUploadedImageUrl(
      await _service.uploadImage(_photoVm.selectedImage!, ownerUserId),
    );
    _setStatus(NotaFormStatus.saving);
  }

  /// Retorna `true` se encontrou duplicata (e já atualizou o estado).
  Future<bool> _verificarDuplicata() async {
    final numero = numeroNotaCtrl.text.trim();
    final chave = chaveNfeCtrl.text.trim();
    try {
      final duplicada = await _service.findNotaDuplicada(
        numeroNota: numero,
        chaveNfe: chave.isEmpty ? null : chave,
      );

      if (duplicada == null) return false;

      _notaDuplicada = duplicada;
      final porNumero = numero.isNotEmpty && duplicada.numeroNota.trim() == numero;
      final porChave = chave.isNotEmpty && duplicada.chaveNfe?.trim() == chave;
      _duplicateReason = porNumero && porChave
          ? 'Já existe uma nota com este número e esta chave NFe.'
          : porNumero
              ? 'Já existe uma nota com este número.'
              : 'Já existe uma nota com esta chave NFe.';

      _status = NotaFormStatus.duplicateFound;
      _errorMessage = null;
      _notifySafe();
      return true;
    } catch (e) {
      _setError('Erro ao verificar duplicidade da nota: $e');
      return true; // aborta o save
    }
  }

  DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;
    try {
      return DateTime.parse(text);
    } catch (_) {
      final parts = text.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
      return null;
    }
  }

  double? _calcularValorTotal() {
    if (_catalogVm.produtos.isNotEmpty) {
      final total = _catalogVm.calcularTotalProdutos();
      valorTotalCtrl.text = total.toStringAsFixed(2);
      return total;
    }
    if (valorTotalCtrl.text.isNotEmpty) {
      return _fieldsVm.parseCurrency(valorTotalCtrl.text);
    }
    return null;
  }

  void _onCatalogChanged() {
    _sincronizarValorTotalComProdutos();
    _notifySafe();
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
    if (!_isDisposed) notifyListeners();
  }

  String? _validarDesconto() {
    final desconto = descontoTotalInformado;
    if (desconto < 0) return 'O valor do desconto não pode ser negativo.';
    if (desconto > valorTotalBruto) return 'O desconto não pode ser maior que o valor total da nota.';
    return null;
  }

  void _sincronizarValorTotalComProdutos() {
    if (_catalogVm.produtos.isEmpty) return;
    valorTotalCtrl.text = _catalogVm.calcularTotalProdutos().toStringAsFixed(2);
  }

  String? _validarConferenciaComTotalDaFoto() {
    if (_photoVm.valorTotalFotoAnalisada == null || _catalogVm.produtos.isEmpty) return null;

    final totalItens = _catalogVm.calcularTotalProdutos();
    final desconto = descontoTotalInformado;
    final totalLiquido = totalItens - desconto;
    final divergencia = (totalLiquido - _photoVm.valorTotalFotoAnalisada!).abs();
    _photoVm.setDivergenciaTotalFotoItens(divergencia);

    if (divergencia > 0.01) {
      final descontoInfo = desconto > 0
          ? ' - desconto R\$ ${desconto.toStringAsFixed(2)} = R\$ ${totalLiquido.toStringAsFixed(2)}'
          : '';
      return 'A soma dos itens (R\$ ${totalItens.toStringAsFixed(2)}$descontoInfo) está diferente do total da foto (R\$ ${_photoVm.valorTotalFotoAnalisada!.toStringAsFixed(2)}). Revise quantidade e preços dos produtos antes de salvar.';
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
        .where((l) => !l.trim().startsWith(marcador))
        .toList()
      ..add('$marcador Total da foto: ${totalFoto.toStringAsFixed(2)} | Soma dos itens: ${totalItens.toStringAsFixed(2)}');
    return linhas.where((l) => l.trim().isNotEmpty).join('\n');
  }

  ({double? totalBruto, double? totalLiquido}) _resolverTotaisFoto(
    CupomAnaliseResult result,
    double totalItens,
  ) {
    final desconto = result.descontoTotal ?? 0.0;

    if (result.valorTotalBruto != null || result.valorTotalLiquido != null) {
      return (totalBruto: result.totalBrutoFoto, totalLiquido: result.totalLiquidoFoto);
    }

    final valorReportado = result.valorTotal;
    if (valorReportado == null) {
      final liquido = totalItens - desconto;
      return (totalBruto: totalItens, totalLiquido: liquido < 0 ? 0 : liquido);
    }

    final totalLiquidoItens = totalItens - desconto;
    final diffBruto = (totalItens - valorReportado).abs();
    final diffLiquido = (totalLiquidoItens - valorReportado).abs();

    if (diffLiquido <= 0.01 || diffLiquido < diffBruto) {
      return (totalBruto: totalItens, totalLiquido: valorReportado);
    }

    final liquido = valorReportado - desconto;
    return (totalBruto: valorReportado, totalLiquido: liquido < 0 ? 0 : liquido);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fieldsVm.removeListener(_notifySafe);
    _photoVm.removeListener(_notifySafe);
    _catalogVm.removeListener(_onCatalogChanged);
    _fieldsVm.dispose();
    _photoVm.dispose();
    _catalogVm.dispose();
    super.dispose();
  }
}
