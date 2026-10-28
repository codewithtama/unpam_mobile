class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseTitle;
  final String changelog;
  final String apkDownloadUrl;
  final int apkSizeBytes;
  final DateTime? publishedAt;
  final bool hasUpdate;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseTitle,
    required this.changelog,
    required this.apkDownloadUrl,
    required this.apkSizeBytes,
    this.publishedAt,
    required this.hasUpdate,
  });

  String get formattedApkSize {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'releaseTitle': releaseTitle,
        'changelog': changelog,
        'apkDownloadUrl': apkDownloadUrl,
        'apkSizeBytes': apkSizeBytes,
        'publishedAt': publishedAt?.toIso8601String(),
        'hasUpdate': hasUpdate,
      };

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
        currentVersion: json['currentVersion'] as String? ?? '',
        latestVersion: json['latestVersion'] as String? ?? '',
        releaseTitle: json['releaseTitle'] as String? ?? '',
        changelog: json['changelog'] as String? ?? '',
        apkDownloadUrl: json['apkDownloadUrl'] as String? ?? '',
        apkSizeBytes: (json['apkSizeBytes'] as num?)?.toInt() ?? 0,
        publishedAt: json['publishedAt'] != null
            ? DateTime.tryParse(json['publishedAt'] as String)
            : null,
        hasUpdate: json['hasUpdate'] as bool? ?? false,
      );

  /// Membandingkan format semver (misal '1.0.1' vs '1.0.0')
  static bool isNewerVersion(String remote, String current) {
    final cleanRemote = _cleanVersion(remote);
    final cleanCurrent = _cleanVersion(current);

    if (cleanRemote.isEmpty || cleanCurrent.isEmpty) return false;
    if (cleanRemote == cleanCurrent) return false;

    final remoteParts = cleanRemote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = remoteParts.length > currentParts.length ? remoteParts.length : currentParts.length;

    for (int i = 0; i < maxLen; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  static String _cleanVersion(String v) {
    String clean = v.trim().toLowerCase();
    if (clean.startsWith('v')) {
      clean = clean.substring(1);
    }
    final plusIndex = clean.indexOf('+');
    if (plusIndex != -1) {
      clean = clean.substring(0, plusIndex);
    }
    final dashIndex = clean.indexOf('-');
    if (dashIndex != -1) {
      clean = clean.substring(0, dashIndex);
    }
    return clean;
  }
}
