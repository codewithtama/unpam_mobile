import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/storage_service.dart';
import '../theme/app_theme.dart';
import 'portal_webview_screen.dart';

class UserAgreementScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback? onAccepted;

  const UserAgreementScreen({
    super.key,
    required this.storageService,
    this.onAccepted,
  });

  @override
  State<UserAgreementScreen> createState() => _UserAgreementScreenState();
}

class _UserAgreementScreenState extends State<UserAgreementScreen> {
  static const int _totalWaitSeconds = 15;
  int _remainingSeconds = _totalWaitSeconds;
  Timer? _countdownTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _remainingSeconds = 0;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (_remainingSeconds > 0) return;
    await widget.storageService.setUserAgreementAccepted(true);
    if (!mounted) return;
    if (widget.onAccepted != null) {
      widget.onAccepted!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PortalWebViewScreen()),
    );
  }

  Future<void> _handleReject() async {
    if (_remainingSeconds > 0) return;
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
                'Tolak Ketentuan?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Untuk menggunakan aplikasi UNPAM Mobile dan mengakses portal Mentari, persetujuan syarat dan ketentuan diperlukan. Jika Anda menolak, aplikasi akan ditutup.',
          style: TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal & Baca Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tolak & Keluar'),
          ),
        ],
      ),
    );

    if (confirmExit == true) {
      await SystemNavigator.pop();
    }
  }

  void _notifyBackBlocked() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _remainingSeconds > 0
                    ? 'Mohon membaca ketentuan penggunaan ($_remainingSeconds detik tersisa).'
                    : 'Pilih "Saya Setuju" atau "Tolak" untuk melanjutkan.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isReady = _remainingSeconds == 0;
    final double timerProgress = (_totalWaitSeconds - _remainingSeconds) / _totalWaitSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _notifyBackBlocked();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgGrey,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.primaryBlue,
          title: const Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppTheme.accentGold, size: 22),
              SizedBox(width: 10),
              Text(
                'Syarat & Ketentuan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'UNPAM Mobile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeaderBanner(),
              _buildTimerIndicator(isReady, timerProgress),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntroBox(),
                        const SizedBox(height: 14),
                        _buildSimpleSection(
                          number: '1',
                          title: 'Status Aplikasi',
                          content:
                              'Aplikasi ini adalah perangkat lunak tidak resmi yang dikembangkan secara independen dan tidak berafiliasi, tidak didukung, serta tidak diotorisasi oleh Universitas Pamulang (UNPAM) dalam bentuk apapun. Seluruh data akademik yang ditampilkan bersumber dari portal Mentari UNPAM dan merupakan milik Universitas Pamulang.',
                        ),
                        const SizedBox(height: 12),
                        _buildSimpleSection(
                          number: '2',
                          title: 'Penggunaan Data Akun',
                          content:
                              'Untuk mengakses fitur aplikasi, Anda diperlukan memasukkan kredensial akun Mentari UNPAM (NIM dan kata sandi). Data ini digunakan hanya untuk keperluan autentikasi ke server Mentari dan tidak disimpan di server pihak ketiga manapun. Anda bertanggung jawab penuh atas kerahasiaan akun Anda.',
                        ),
                        const SizedBox(height: 12),
                        _buildAiFeatureSection(),
                        const SizedBox(height: 12),
                        _buildLiabilitySection(),
                        const SizedBox(height: 12),
                        _buildSimpleSection(
                          number: '5',
                          title: 'Pembaruan Ketentuan',
                          content:
                              'Ketentuan ini dapat diperbarui sewaktu-waktu tanpa pemberitahuan sebelumnya. Penggunaan berkelanjutan setelah pembaruan dianggap sebagai persetujuan atas ketentuan yang baru.',
                        ),
                        const SizedBox(height: 12),
                        _buildContactSection(),
                        const SizedBox(height: 18),
                        _buildConsentConfirmationCard(isReady),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomActionBar(isReady),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppTheme.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYARAT DAN KETENTUAN PENGGUNAAN',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Berlaku sejak pertama kali aplikasi diinstal',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerIndicator(bool isReady, double timerProgress) {
    return Container(
      width: double.infinity,
      color: isReady ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isReady ? Icons.check_circle_rounded : Icons.timer_outlined,
                size: 18,
                color: isReady ? AppTheme.successGreen : AppTheme.accentGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isReady
                      ? 'Waktu telaah 15 detik selesai. Opsi persetujuan aktif.'
                      : 'Wajib membaca ketentuan: $_remainingSeconds detik tersisa',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isReady ? const Color(0xFF065F46) : const Color(0xFF92400E),
                  ),
                ),
              ),
              if (!isReady)
                Text(
                  '${_remainingSeconds}s',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
            ],
          ),
          if (!isReady) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: timerProgress,
                minHeight: 4,
                backgroundColor: const Color(0xFFFDE68A),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntroBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryLight, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dengan melanjutkan penggunaan aplikasi ini, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan yang tertulis di bawah ini.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeatureSection() {
    final List<String> aiPoints = [
      'Respons yang diberikan AI bersifat bantuan, bukan keputusan resmi. Jangan jadikan output AI sebagai dasar keputusan akademik yang penting.',
      'AI dapat memberikan informasi yang tidak akurat atau tidak mutakhir. Selalu verifikasi ke sumber resmi UNPAM.',
      'Percakapan dengan fitur AI dapat diproses oleh penyedia layanan AI pihak ketiga sesuai kebijakan privasi mereka.',
      'Jangan memasukkan informasi sensitif seperti kata sandi, data keuangan, atau informasi pribadi yang tidak relevan ke dalam kolom percakapan AI.',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. Fitur Kecerdasan Buatan (AI)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aplikasi ini menyertakan fitur berbasis AI yang dapat membantu Anda meringkas informasi akademik, menjawab pertanyaan umum terkait perkuliahan, serta memberikan saran belajar.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Hal yang perlu Anda pahami terkait fitur AI:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...aiPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLiabilitySection() {
    final List<String> liabilityPoints = [
      'Kerusakan data atau kerugian yang timbul akibat penggunaan aplikasi ini',
      'Ketidakakuratan data yang bersumber dari portal Mentari UNPAM',
      'Gangguan akses yang disebabkan oleh perubahan sistem dari pihak UNPAM',
      'Keputusan yang diambil berdasarkan output fitur AI',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '4. Batasan Tanggung Jawab',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pengembang tidak bertanggung jawab atas:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...liabilityPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppTheme.dangerRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '6. Kontak',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pertanyaan atau laporan terkait aplikasi dapat disampaikan melalui:',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryLight.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.email_outlined, size: 16, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'tamavons12@gmail.com',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentConfirmationCard(bool isReady) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isReady
            ? AppTheme.primaryLight.withOpacity(0.06)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady ? AppTheme.primaryLight.withOpacity(0.3) : AppTheme.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReady ? Icons.check_circle_outline : Icons.lock_clock,
            color: isReady ? AppTheme.primaryLight : AppTheme.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isReady
                  ? 'Dengan menekan "SAYA SETUJU", Anda mengonfirmasi telah membaca, memahami, dan menyetujui seluruh ketentuan di atas.'
                  : 'Tombol persetujuan akan terbuka secara otomatis setelah timer 15 detik berakhir.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isReady ? FontWeight.w600 : FontWeight.normal,
                color: isReady ? AppTheme.primaryBlue : AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isReady) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: isReady ? _handleReject : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.dangerRed,
                side: BorderSide(
                  color: isReady ? AppTheme.dangerRed : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isReady ? 'TOLAK' : 'TOLAK (${_remainingSeconds}s)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isReady ? AppTheme.dangerRed : Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: isReady ? _handleAccept : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isReady ? 'SAYA SETUJU' : 'TUNGGU (${_remainingSeconds}s)',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
