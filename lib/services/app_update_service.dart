import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:notas_zincao_flutter/models/app_update_policy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateDecision { none, optional, required, unavailable }

class UpdateCheckResult {
  final UpdateDecision decision;
  final AppUpdatePolicy? policy;
  final String installedVersion;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.decision,
    required this.policy,
    required this.installedVersion,
    this.errorMessage,
  });
}

class AppUpdateService {
  static const _cacheKey = 'app_update_policy_cache';

  final http.Client _httpClient;

  AppUpdateService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<UpdateCheckResult> checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final installedVersion = packageInfo.version;

    final remoteUrl = dotenv.env['UPDATE_CONFIG_URL']?.trim();
    if (remoteUrl == null || remoteUrl.isEmpty) {
      return UpdateCheckResult(
        decision: UpdateDecision.unavailable,
        policy: null,
        installedVersion: installedVersion,
        errorMessage: 'UPDATE_CONFIG_URL não configurada.',
      );
    }

    AppUpdatePolicy? policy;

    try {
      policy = await _fetchRemotePolicy(remoteUrl);
      await _savePolicyCache(policy);
    } catch (_) {
      policy = await _loadPolicyCache();
    }

    if (policy == null ||
        policy.latestVersion.isEmpty ||
        policy.minSupportedVersion.isEmpty) {
      return UpdateCheckResult(
        decision: UpdateDecision.unavailable,
        policy: null,
        installedVersion: installedVersion,
        errorMessage: 'Política de atualização indisponível.',
      );
    }

    if (!_isUserIncludedInRollout(policy.rolloutPercent, packageInfo.packageName)) {
      return UpdateCheckResult(
        decision: UpdateDecision.none,
        policy: policy,
        installedVersion: installedVersion,
      );
    }

    final compareWithMin = _compareVersions(
      installedVersion,
      policy.minSupportedVersion,
    );

    final compareWithLatest = _compareVersions(installedVersion, policy.latestVersion);

    if (compareWithMin < 0 || (policy.forceUpdate && compareWithLatest < 0)) {
      return UpdateCheckResult(
        decision: UpdateDecision.required,
        policy: policy,
        installedVersion: installedVersion,
      );
    }

    if (compareWithLatest < 0) {
      return UpdateCheckResult(
        decision: UpdateDecision.optional,
        policy: policy,
        installedVersion: installedVersion,
      );
    }

    return UpdateCheckResult(
      decision: UpdateDecision.none,
      policy: policy,
      installedVersion: installedVersion,
    );
  }

  Future<bool> performUpdate({
    required bool immediate,
    required AppUpdatePolicy policy,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (immediate) {
          final result = await InAppUpdate.performImmediateUpdate();
          return result == AppUpdateResult.success;
        }

        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
          return true;
        }
      }
    }

    return _openStoreUrl(policy);
  }

  Future<AppUpdatePolicy> _fetchRemotePolicy(String remoteUrl) async {
    final response = await _httpClient
        .get(Uri.parse(remoteUrl))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha ao buscar política de atualização.');
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Resposta inválida da política de atualização.');
    }

    return AppUpdatePolicy.fromJson(body);
  }

  Future<void> _savePolicyCache(AppUpdatePolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(policy.toJson()));
  }

  Future<AppUpdatePolicy?> _loadPolicyCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return AppUpdatePolicy.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  bool _isUserIncludedInRollout(int rolloutPercent, String seed) {
    if (rolloutPercent >= 100) return true;
    if (rolloutPercent <= 0) return false;

    final bucket = seed.hashCode.abs() % 100;
    return bucket < rolloutPercent;
  }

  int _compareVersions(String currentVersion, String targetVersion) {
    final current = _toVersionNumbers(currentVersion);
    final target = _toVersionNumbers(targetVersion);

    for (var i = 0; i < 3; i++) {
      if (current[i] > target[i]) return 1;
      if (current[i] < target[i]) return -1;
    }
    return 0;
  }

  List<int> _toVersionNumbers(String version) {
    final cleaned = version.split('+').first.split('-').first.trim();
    final parts = cleaned.split('.');
    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }

  Future<bool> _openStoreUrl(AppUpdatePolicy policy) async {
    final storeUrl = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => policy.storeUrlIos,
      TargetPlatform.android => policy.storeUrlAndroid,
      _ => policy.storeUrlAndroid ?? policy.storeUrlIos,
    };

    if (storeUrl == null || storeUrl.isEmpty) return false;

    final uri = Uri.tryParse(storeUrl);
    if (uri == null) return false;

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
