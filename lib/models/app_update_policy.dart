class AppUpdatePolicy {
  final String latestVersion;
  final String minSupportedVersion;
  final bool forceUpdate;
  final String? storeUrlAndroid;
  final String? storeUrlIos;
  final int rolloutPercent;
  final String? message;

  const AppUpdatePolicy({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.forceUpdate,
    required this.storeUrlAndroid,
    required this.storeUrlIos,
    required this.rolloutPercent,
    required this.message,
  });

  factory AppUpdatePolicy.fromJson(Map<String, dynamic> json) {
    return AppUpdatePolicy(
      latestVersion: (json['latestVersion'] ?? json['latest_version'] ?? '').toString(),
      minSupportedVersion:
          (json['minSupportedVersion'] ?? json['min_supported_version'] ?? '').toString(),
      forceUpdate: _parseBool(json['forceUpdate'] ?? json['force_update']),
      storeUrlAndroid:
          (json['storeUrlAndroid'] ?? json['store_url_android'])?.toString(),
      storeUrlIos: (json['storeUrlIos'] ?? json['store_url_ios'])?.toString(),
      rolloutPercent: _parseRollout(
        json['rolloutPercent'] ?? json['rollout_percent'],
      ),
      message: (json['message'] ?? json['mensagem'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latestVersion': latestVersion,
      'minSupportedVersion': minSupportedVersion,
      'forceUpdate': forceUpdate,
      'storeUrlAndroid': storeUrlAndroid,
      'storeUrlIos': storeUrlIos,
      'rolloutPercent': rolloutPercent,
      'message': message,
    };
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static int _parseRollout(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '100') ?? 100;
    if (parsed < 0) return 0;
    if (parsed > 100) return 100;
    return parsed;
  }
}
