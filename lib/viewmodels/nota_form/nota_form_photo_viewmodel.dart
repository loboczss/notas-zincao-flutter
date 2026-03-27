import 'dart:io';

import 'package:flutter/foundation.dart';

class NotaFormPhotoViewModel extends ChangeNotifier {
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _aiProcessed = false;
  double? _valorTotalFotoAnalisada;
  double? _divergenciaTotalFotoItens;
  bool _quotaExceeded = false;

  File? get selectedImage => _selectedImage;
  String? get uploadedImageUrl => _uploadedImageUrl;
  bool get aiProcessed => _aiProcessed;
  double? get valorTotalFotoAnalisada => _valorTotalFotoAnalisada;
  double? get divergenciaTotalFotoItens => _divergenciaTotalFotoItens;
  bool get quotaExceeded => _quotaExceeded;

  void setSelectedImage(File? file) {
    _selectedImage = file;
    _aiProcessed = false;
    _uploadedImageUrl = null;
    _valorTotalFotoAnalisada = null;
    _divergenciaTotalFotoItens = null;
    notifyListeners();
  }

  void setUploadedImageUrl(String? value) {
    _uploadedImageUrl = value;
    notifyListeners();
  }

  void setAiProcessed(bool value) {
    _aiProcessed = value;
    notifyListeners();
  }

  void setValorTotalFotoAnalisada(double? value) {
    _valorTotalFotoAnalisada = value;
    notifyListeners();
  }

  void setDivergenciaTotalFotoItens(double? value) {
    _divergenciaTotalFotoItens = value;
    notifyListeners();
  }

  /// Limpa estado de análise anterior em um único notify.
  void iniciarAnalise() {
    _valorTotalFotoAnalisada = null;
    _divergenciaTotalFotoItens = null;
    notifyListeners();
  }

  /// Conclui análise da IA com todos os resultados em um único notify.
  void concluirAnalise({required double? valorTotal, required double? divergencia}) {
    _aiProcessed = true;
    _valorTotalFotoAnalisada = valorTotal;
    _divergenciaTotalFotoItens = divergencia;
    notifyListeners();
  }

  void setQuotaExceeded(bool value) {
    _quotaExceeded = value;
    notifyListeners();
  }

  void clearQuotaError() {
    _quotaExceeded = false;
    notifyListeners();
  }

  void reset() {
    _selectedImage = null;
    _uploadedImageUrl = null;
    _aiProcessed = false;
    _valorTotalFotoAnalisada = null;
    _divergenciaTotalFotoItens = null;
    _quotaExceeded = false;
    notifyListeners();
  }
}
