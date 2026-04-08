import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/utils/parse_utils.dart' as parse;

import 'nota_form_enums.dart';

class NotaFormFieldsViewModel extends ChangeNotifier {
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

  final Set<CampoObrigatorio> _missingFields = {};

  Set<CampoObrigatorio> get missingFields => Set.unmodifiable(_missingFields);

  NotaFormFieldsViewModel() {
    nomeClienteCtrl.addListener(_onFieldChanged);
    telefoneClienteCtrl.addListener(_onFieldChanged);
    numeroNotaCtrl.addListener(_onFieldChanged);
    serieNotaCtrl.addListener(_onFieldChanged);
    chaveNfeCtrl.addListener(_onFieldChanged);
    dataCompraCtrl.addListener(_onFieldChanged);
    descontoCtrl.addListener(_onDiscountChanged);
  }

  double get descontoTotalInformado => parseCurrency(descontoCtrl.text);

  void _onFieldChanged() {
    if (_missingFields.isEmpty) return;
    checkMissingFields();
  }

  void _onDiscountChanged() {
    notifyListeners();
  }

  void checkMissingFields() {
    final novo = <CampoObrigatorio>{};
    if (nomeClienteCtrl.text.trim().isEmpty) novo.add(CampoObrigatorio.nomeCliente);
    if (telefoneClienteCtrl.text.trim().isEmpty) novo.add(CampoObrigatorio.telefoneCliente);
    if (numeroNotaCtrl.text.trim().isEmpty) novo.add(CampoObrigatorio.numeroNota);
    if (serieNotaCtrl.text.trim().isEmpty) novo.add(CampoObrigatorio.serieNota);
    if (chaveNfeCtrl.text.trim().isEmpty) novo.add(CampoObrigatorio.chaveNfe);
    if (dataCompraCtrl.text.trim().isEmpty) novo.add(CampoObrigatorio.dataCompra);

    if (novo.length != _missingFields.length || !novo.every(_missingFields.contains)) {
      _missingFields
        ..clear()
        ..addAll(novo);
      notifyListeners();
    }
  }

  void clearMissingFields() {
    if (_missingFields.isEmpty) return;
    _missingFields.clear();
    notifyListeners();
  }

  void fillField(TextEditingController ctrl, String? value) {
    if (value != null && value.isNotEmpty) {
      ctrl.text = value;
    }
  }

  double parseCurrency(String value) => parse.parseDouble(value);

  void resetFields() {
    _missingFields.clear();

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

    notifyListeners();
  }

  @override
  void dispose() {
    nomeClienteCtrl.removeListener(_onFieldChanged);
    telefoneClienteCtrl.removeListener(_onFieldChanged);
    numeroNotaCtrl.removeListener(_onFieldChanged);
    serieNotaCtrl.removeListener(_onFieldChanged);
    chaveNfeCtrl.removeListener(_onFieldChanged);
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
