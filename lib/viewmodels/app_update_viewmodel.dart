import 'package:flutter/foundation.dart';
import 'package:notas_zincao_flutter/models/app_update_policy.dart';
import 'package:notas_zincao_flutter/services/app_update_service.dart';

enum AppUpdateStatus { idle, checking, upToDate, optional, required, unavailable }

class AppUpdateViewModel extends ChangeNotifier {
  final AppUpdateService _service;

  AppUpdateStatus _status = AppUpdateStatus.idle;
  AppUpdatePolicy? _policy;
  String? _installedVersion;
  String? _errorMessage;
  bool _optionalPromptDismissed = false;

  AppUpdateViewModel(this._service);

  AppUpdateStatus get status => _status;
  AppUpdatePolicy? get policy => _policy;
  String? get installedVersion => _installedVersion;
  String? get errorMessage => _errorMessage;

  bool get shouldShowOptionalPrompt =>
      _status == AppUpdateStatus.optional && !_optionalPromptDismissed;

  Future<void> checkForUpdates({bool silently = false}) async {
    _status = AppUpdateStatus.checking;
    _errorMessage = null;
    if (!silently) {
      notifyListeners();
    }

    final result = await _service.checkForUpdates();
    _installedVersion = result.installedVersion;
    _policy = result.policy;
    _errorMessage = result.errorMessage;

    switch (result.decision) {
      case UpdateDecision.required:
        _status = AppUpdateStatus.required;
        break;
      case UpdateDecision.optional:
        _status = AppUpdateStatus.optional;
        break;
      case UpdateDecision.none:
        _status = AppUpdateStatus.upToDate;
        break;
      case UpdateDecision.unavailable:
        _status = AppUpdateStatus.unavailable;
        break;
    }

    notifyListeners();
  }

  void dismissOptionalPrompt() {
    _optionalPromptDismissed = true;
    notifyListeners();
  }

  void resetOptionalPrompt() {
    _optionalPromptDismissed = false;
    notifyListeners();
  }

  Future<bool> updateNow({bool immediate = false}) async {
    final currentPolicy = _policy;
    if (currentPolicy == null) return false;
    return _service.performUpdate(immediate: immediate, policy: currentPolicy);
  }
}
