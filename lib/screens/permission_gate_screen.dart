import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/services/permission_service.dart';
import '../core/services/storage_service.dart';
import '../theme/app_theme.dart';
import 'portal_webview_screen.dart';

class PermissionGateScreen extends StatefulWidget {
  final StorageService storageService;
  final bool autoProceed;

  const PermissionGateScreen({
    super.key,
    required this.storageService,
    this.autoProceed = true,
  });

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen>
    with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();

  bool _isLoading = true;
  bool _isRequesting = false;

  PermissionStatus _notifStatus = PermissionStatus.denied;
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _mediaStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatuses();
    }
  }

  Future<void> _refreshPermissionStatuses() async {
    setState(() => _isLoading = true);

    final notif = await _permissionService.checkNotificationStatus();
    final camera = await _permissionService.checkCameraStatus();
    final media = await _permissionService.checkMediaStorageStatus();

    if (!mounted) return;

    setState(() {
      _notifStatus = notif;
      _cameraStatus = camera;
      _mediaStatus = media;
      _isLoading = false;
    });

    // Jika seluruh izin sudah disetujui, auto lanjut ke aplikasi jika diaktifkan
    if (widget.autoProceed && _areAllGranted) {
      _proceedToApp();
    }
  }

  bool _isGranted(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  bool get _areAllGranted =>
      _isGranted(_notifStatus) &&
      _isGranted(_cameraStatus) &&
      _isGranted(_mediaStatus);

  bool get _hasPermanentlyDenied =>
      _notifStatus.isPermanentlyDenied ||
      _cameraStatus.isPermanentlyDenied ||
      _mediaStatus.isPermanentlyDenied;

  Future<void> _requestAllPermissions() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      final results = await _permissionService.requestAllPermissions();

      if (!mounted) return;

      setState(() {
        _notifStatus =
            results[AppPermissionType.notification] ?? _notifStatus;
        _cameraStatus = results[AppPermissionType.camera] ?? _cameraStatus;
        _mediaStatus =
            results[AppPermissionType.photosOrStorage] ?? _mediaStatus;
      });

      if (_areAllGranted) {
        _proceedToApp();
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _requestSingle(AppPermissionType type) async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      final status = await _permissionService.requestSinglePermission(type);
      if (!mounted) return;

      setState(() {
        switch (type) {
          case AppPermissionType.notification:
            _notifStatus = status;
            break;
          case AppPermissionType.camera:
            _cameraStatus = status;
            break;
          case AppPermissionType.photosOrStorage:
            _mediaStatus = status;
            break;
        }
      });

      if (_areAllGranted) {
        _proceedToApp();
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _proceedToApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PortalWebViewScreen()),
    );
  }

  Future<void> _handleExitPrompt() async {
    final bool? confirmExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Izin Wajib Diperlukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Aplikasi The PAMs memerlukan persetujuan seluruh izin (Notifikasi, Kamera, dan Penyimpanan Media) untuk dapat beroperasi. Jika izin tidak disetujui, aplikasi tidak dapat digunakan.',
          style: TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tetap di Aplikasi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar dari Aplikasi'),
          ),
        ],
      ),
    );

    if (confirmExit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleExitPrompt();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgGrey,
        appBar: AppBar(
          title: const Text('Izin Akses Aplikasi'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Perbarui Status Izin',
              onPressed: _isLoading ? null : _refreshPermissionStatuses,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryBlue),
                      SizedBox(height: 16),
                      Text(
                        'Memeriksa izin perangkat...',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Badge & Intro
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            size: 48,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Persetujuan Izin Wajib',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sebelum menggunakan The PAMs, Anda wajib menyetujui seluruh izin di bawah ini agar portal perkuliahan, notifikasi, dan kecerdasan buatan dapat bekerja optimal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.textMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Warning Banner jika ada izin yang ditolak permanen
                      if (_hasPermanentlyDenied) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.dangerRed,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Izin Diblokir oleh Sistem Android',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.dangerRed,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Satu atau lebih izin ditolak secara permanen. Buka Pengaturan HP Anda lalu aktifkan semua izin secara manual agar aplikasi dapat dibuka.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.textDark,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _permissionService.openSettings(),
                                      child: const Text(
                                        'Buka Pengaturan HP Sekarang →',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Card 1: Notifikasi
                      _buildPermissionCard(
                        type: AppPermissionType.notification,
                        icon: Icons.notifications_active_rounded,
                        title: 'Notifikasi Sistem & Perkuliahan',
                        description:
                            'Pemberitahuan pengumuman kampus, jadwal kuliah, pembaruan materi LMS Mentari & MyUnpam, serta rilis versi baru aplikasi secara tepat waktu.',
                        status: _notifStatus,
                      ),
                      const SizedBox(height: 12),

                      // Card 2: Kamera
                      _buildPermissionCard(
                        type: AppPermissionType.camera,
                        icon: Icons.camera_alt_rounded,
                        title: 'Kamera (The PAMs AI Vision OCR)',
                        description:
                            'Memindai langsung foto soal kuis/tugas perkuliahan, teks modul kuliah, dan tangkapan visual untuk dianalisis oleh AI cerdas.',
                        status: _cameraStatus,
                      ),
                      const SizedBox(height: 12),

                      // Card 3: Galeri & Media Penyimpanan
                      _buildPermissionCard(
                        type: AppPermissionType.photosOrStorage,
                        icon: Icons.photo_library_rounded,
                        title: 'Foto & Media Penyimpanan',
                        description:
                            'Mengunggah berkas jawaban tugas mahasiswa ke portal Mentari/MyUnpam, memilih gambar dari galeri HP, dan mengunduh berkas materi.',
                        status: _mediaStatus,
                      ),
                      const SizedBox(height: 24),

                      // Summary & Requirements Footer Notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _areAllGranted
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              color: _areAllGranted
                                  ? AppTheme.successGreen
                                  : AppTheme.accentGold,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _areAllGranted
                                    ? 'Seluruh izin lengkap! Anda dapat masuk ke aplikasi.'
                                    : 'Semua 3 izin di atas wajib disetujui untuk membuka aplikasi.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _areAllGranted
                                      ? AppTheme.successGreen
                                      : AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Primary Action Buttons
                      if (_hasPermanentlyDenied)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _permissionService.openSettings(),
                          icon: const Icon(Icons.settings_suggest_rounded),
                          label: const Text(
                            'Buka Pengaturan HP',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (_areAllGranted)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _proceedToApp,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text(
                            'Lanjutkan ke Aplikasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isRequesting ? null : _requestAllPermissions,
                          icon: _isRequesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.verified_user_rounded),
                          label: Text(
                            _isRequesting
                                ? 'Memproses Izin...'
                                : 'Izinkan Seluruh Akses',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Exit App Option
                      Center(
                        child: TextButton(
                          onPressed: _handleExitPrompt,
                          child: const Text(
                            'Tolak & Keluar dari Aplikasi',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.dangerRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required AppPermissionType type,
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus status,
  }) {
    final bool isGranted = _isGranted(status);
    final bool isPermDenied = status.isPermanentlyDenied;

    final Color badgeBg = isGranted
        ? AppTheme.successGreen.withAlpha(25)
        : (isPermDenied
            ? AppTheme.dangerRed.withAlpha(25)
            : AppTheme.accentGold.withAlpha(25));

    final Color badgeColor = isGranted
        ? AppTheme.successGreen
        : (isPermDenied ? AppTheme.dangerRed : AppTheme.accentGold);

    final String badgeText = isGranted
        ? 'Diizinkan'
        : (isPermDenied ? 'Diblokir Sistem' : 'Belum Diizinkan');

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isGranted
              ? AppTheme.successGreen.withAlpha(80)
              : AppTheme.cardBorder,
          width: isGranted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? AppTheme.successGreen.withAlpha(20)
                        : AppTheme.primaryBlue.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isGranted ? AppTheme.successGreen : AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGranted
                                  ? Icons.check_circle_rounded
                                  : (isPermDenied
                                      ? Icons.lock_outline_rounded
                                      : Icons.pending_outlined),
                              size: 13,
                              color: badgeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isGranted) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: badgeColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isRequesting
                        ? null
                        : () {
                            if (isPermDenied) {
                              _permissionService.openSettings();
                            } else {
                              _requestSingle(type);
                            }
                          },
                    child: Text(
                      isPermDenied ? 'Pengaturan' : 'Izinkan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
