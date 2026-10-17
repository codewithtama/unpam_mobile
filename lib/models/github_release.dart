import 'package:intl/intl.dart';

class GitHubRelease {
  final int id;
  final String tagName;
  final String name;
  final String body;
  final DateTime? publishedAt;
  final String htmlUrl;
  final String? apkDownloadUrl;
  final int apkSizeBytes;
  final int downloadCount;
  final bool isPrerelease;
  final bool isDraft;

  const GitHubRelease({
    required this.id,
    required this.tagName,
    required this.name,
    required this.body,
    this.publishedAt,
    required this.htmlUrl,
    this.apkDownloadUrl,
    this.apkSizeBytes = 0,
    this.downloadCount = 0,
    this.isPrerelease = false,
    this.isDraft = false,
  });

  String get displayTitle {
    if (name.trim().isNotEmpty) return name.trim();
    if (tagName.trim().isNotEmpty) return 'Rilis $tagName';
    return 'Pembaruan Aplikasi';
  }

  String get formattedPublishedDate {
    if (publishedAt == null) return 'Tanggal tidak diketahui';
    try {
      final formatter = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');
      return '${formatter.format(publishedAt!.toLocal())} WIB';
    } catch (_) {
      return '${publishedAt!.day}/${publishedAt!.month}/${publishedAt!.year}';
    }
  }

  String get formattedApkSize {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  bool get hasApkAsset => apkDownloadUrl != null && apkDownloadUrl!.isNotEmpty;

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final tagName = json['tag_name']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final body = json['body']?.toString() ?? '';
    final htmlUrl = json['html_url']?.toString() ?? '';
    final isPrerelease = json['prerelease'] == true;
    final isDraft = json['draft'] == true;

    DateTime? publishedAt;
    final pubStr = json['published_at']?.toString() ?? json['created_at']?.toString();
    if (pubStr != null && pubStr.isNotEmpty) {
      publishedAt = DateTime.tryParse(pubStr);
    }

    String? apkUrl;
    int apkSize = 0;
    int downloads = 0;

    final assets = json['assets'] as List<dynamic>? ?? [];
    for (final rawAsset in assets) {
      if (rawAsset is Map<String, dynamic>) {
        final assetName = rawAsset['name']?.toString().toLowerCase() ?? '';
        if (assetName.endsWith('.apk')) {
          apkUrl = rawAsset['browser_download_url']?.toString();
          apkSize = (rawAsset['size'] as num?)?.toInt() ?? 0;
          downloads = (rawAsset['download_count'] as num?)?.toInt() ?? 0;
          break;
        }
      }
    }

    return GitHubRelease(
      id: id,
      tagName: tagName,
      name: name,
      body: body,
      publishedAt: publishedAt,
      htmlUrl: htmlUrl,
      apkDownloadUrl: apkUrl,
      apkSizeBytes: apkSize,
      downloadCount: downloads,
      isPrerelease: isPrerelease,
      isDraft: isDraft,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag_name': tagName,
      'name': name,
      'body': body,
      'published_at': publishedAt?.toIso8601String(),
      'html_url': htmlUrl,
      'browser_download_url': apkDownloadUrl,
      'apk_size_bytes': apkSizeBytes,
      'download_count': downloadCount,
      'prerelease': isPrerelease,
      'draft': isDraft,
    };
  }
}
