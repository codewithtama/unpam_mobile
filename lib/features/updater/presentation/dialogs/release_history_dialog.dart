import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unpam_mobile/features/updater/data/update_checker_service.dart';
import 'package:unpam_mobile/features/updater/domain/models/app_update_info.dart';
import 'package:unpam_mobile/features/updater/domain/models/github_release.dart';
import 'package:unpam_mobile/theme/app_theme.dart';
import 'update_dialog.dart';

class ReleaseHistoryDialog extends StatefulWidget {
  final UpdateCheckerService updateService;

  const ReleaseHistoryDialog({
    super.key,
    required this.updateService,
  });

  static Future<void> show({
    required BuildContext context,
    required UpdateCheckerService updateService,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReleaseHistoryDialog(
        updateService: updateService,
      ),
    );
  }

  @override
  State<ReleaseHistoryDialog> createState() => _ReleaseHistoryDialogState();
}

class _ReleaseHistoryDialogState extends State<ReleaseHistoryDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<GitHubRelease> _releases = [];
  String _currentVersion = '1.0.51';

  @override
  void initState() {
    super.initState();
    _loadCurrentVersionAndReleases();
  }

  Future<void> _loadCurrentVersionAndReleases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
    } catch (_) {}

    try {
      final list = await widget.updateService.fetchReleaseHistory();
      if (!mounted) return;

      setState(() {
        _releases = list;
        _isLoading = false;
        if (list.isEmpty) {
          _errorMessage =
              'Belum ada data riwayat rilis yang berhasil dimuat dari GitHub.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Gagal menghubungkan ke GitHub API. Periksa sambungan internet Anda atau coba sesaat lagi.';
      });
    }
  }

  Future<void> _openGitHubUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan browser.')),
        );
      }
    }
  }

  void _installRelease(GitHubRelease release) {
    Navigator.of(context).pop();

    final updateInfo = AppUpdateInfo(
      currentVersion: _currentVersion,
      latestVersion: release.tagName,
      releaseTitle: release.displayTitle,
      changelog: release.body,
      apkDownloadUrl: release.apkDownloadUrl ?? '',
      apkSizeBytes: release.apkSizeBytes,
      publishedAt: release.publishedAt,
      hasUpdate: true,
    );

    UpdateDialog.show(
      context: context,
      updateInfo: updateInfo,
      updateService: widget.updateService,
    );
  }

  bool _isCurrentVersion(String tagName) {
    final cleanTag = _cleanTag(tagName);
    final cleanCurrent = _cleanTag(_currentVersion);
    return cleanTag == cleanCurrent;
  }

  bool _isNewer(String tagName) {
    return AppUpdateInfo.isNewerVersion(tagName, _currentVersion);
  }

  String _cleanTag(String v) {
    String clean = v.trim().toLowerCase();
    if (clean.startsWith('v')) {
      clean = clean.substring(1);
    }
    final plusIndex = clean.indexOf('+');
    if (plusIndex != -1) {
      clean = clean.substring(0, plusIndex);
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.bgGrey,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: size.height * 0.88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            _buildHeader(),

            // Version Info Header Banner
            _buildVersionBanner(),

            // Content Body: Loading, Error, or List
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history_edu_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Riwayat Pembaruan Aplikasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Data riwayat rilis langsung dari GitHub Repository',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            tooltip: 'Segarkan Riwayat',
            onPressed: _isLoading ? null : _loadCurrentVersionAndReleases,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            tooltip: 'Tutup',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppTheme.successGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'Versi Terpasang: v$_currentVersion',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          if (!_isLoading && _releases.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_releases.length} Rilis Terdata',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Menghubungkan ke GitHub API...',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _releases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: AppTheme.dangerRed,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: _loadCurrentVersionAndReleases,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Coba Lagi', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openGitHubUrl('https://github.com/codewithtama/unpam_mobile/releases'),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text('Buka Web GitHub', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _releases.length,
      itemBuilder: (context, index) {
        final release = _releases[index];
        final bool isCurrent = _isCurrentVersion(release.tagName);
        final bool isNewerVersion = _isNewer(release.tagName);

        return _buildReleaseCard(
          release: release,
          isCurrent: isCurrent,
          isNewer: isNewerVersion,
        );
      },
    );
  }

  Widget _buildReleaseCard({
    required GitHubRelease release,
    required bool isCurrent,
    required bool isNewer,
  }) {
    Color cardBorderColor = AppTheme.cardBorder;
    if (isCurrent) {
      cardBorderColor = AppTheme.successGreen;
    } else if (isNewer) {
      cardBorderColor = AppTheme.accentGold;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cardBorderColor,
          width: (isCurrent || isNewer) ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Tag badge, Status badge, Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag Name Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppTheme.successGreen
                        : (isNewer ? AppTheme.accentGold : AppTheme.primaryBlue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    release.tagName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Versi Terpasang',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  )
                else if (isNewer)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Tersedia Pembaruan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                      ),
                    ),
                  ),

                const Spacer(),

                // Published Date
                Text(
                  release.formattedPublishedDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Release Title
            Text(
              release.displayTitle,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),

            // Changelog Content Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgGrey,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Text(
                release.body.trim().isNotEmpty
                    ? release.body.trim()
                    : 'Peningkatan performa, kestabilan, dan perbaikan bug.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textDark,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Actions & Metadata
            Row(
              children: [
                if (release.hasApkAsset) ...[
                  const Icon(
                    Icons.android_rounded,
                    size: 15,
                    color: AppTheme.successGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'APK (${release.formattedApkSize})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  if (release.downloadCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${release.downloadCount}x diunduh',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ],

                const Spacer(),

                // Action: Open in GitHub
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _openGitHubUrl(release.htmlUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text(
                    'Lihat di GitHub',
                    style: TextStyle(fontSize: 12),
                  ),
                ),

                // Action: Install if newer and has APK
                if (isNewer && release.hasApkAsset) ...[
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _installRelease(release),
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: const Text(
                      'Pasang',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
