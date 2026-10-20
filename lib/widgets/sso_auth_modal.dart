import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/my_unpam_scripts.dart';
import '../core/services/my_unpam_session.dart';
import '../providers/biometric_provider.dart';
import '../theme/app_theme.dart';

class SsoAuthModal extends StatefulWidget {
  final String? initialNim;

  const SsoAuthModal({super.key, this.initialNim});

  static Future<bool?> show(BuildContext context, {String? initialNim}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SsoAuthModal(initialNim: initialNim),
    );
  }

  @override
  State<SsoAuthModal> createState() => _SsoAuthModalState();
}

class _SsoAuthModalState extends State<SsoAuthModal> {
  late final WebViewController _controller;
  late final MyUnpamSession _session;
  int _progress = 0;
  bool _isLoading = true;
  String _currentStepText = 'Memuat halaman login Satu UNPAM...';
  bool _tokenCaptured = false;
  bool _myUnpamTokenSeen = false;
  Timer? _closeFallback;
  late final Future<(String, String)?> _credentials;

  @override
  void initState() {
    super.initState();
    _session = context.read<MyUnpamSession>();
    _credentials = _resolveCredentials();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(ApiConstants.webViewUserAgent)
      ..addJavaScriptChannel(
        MyUnpamScripts.tokenChannel,
        onMessageReceived: (message) => _handleToken(message.message),
      )
      ..addJavaScriptChannel(
        MyUnpamScripts.statusChannel,
        onMessageReceived: (message) => _handleSsoStatus(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
              _isLoading = progress < 100;
            });
          },
          onPageStarted: _updateStepDescription,
          onPageFinished: (url) {
            _updateStepDescription(url);
            _injectScripts(url);
          },
        ),
      )
      ..loadRequest(Uri.parse('${ApiConstants.satuUnpamBaseUrl}/login'));
  }

  @override
  void dispose() {
    _closeFallback?.cancel();
    super.dispose();
  }

  Future<(String, String)?> _resolveCredentials() async {
    final remembered = _session.rememberedCredentials;
    if (remembered != null) return remembered;

    final biometric = context.read<BiometricProvider>();
    if (biometric.isAvailable && biometric.hasSavedCredentials) {
      final creds = await biometric.getCredentialsForLogin();
      final nim = (creds?['nim'] ?? '').trim();
      final password = creds?['password'] ?? '';
      if (nim.isNotEmpty && password.isNotEmpty) {
        _session.rememberCredentials(nim, password);
        return (nim, password);
      }
    }

    final nim = widget.initialNim ?? biometric.savedNim;
    return nim == null || nim.isEmpty ? null : (nim, '');
  }

  void _updateStepDescription(String url) {
    if (!mounted || _tokenCaptured) return;
    final lower = url.toLowerCase();
    setState(() {
      if (lower.contains('my.unpam.ac.id')) {
        _currentStepText = 'Berhasil masuk My UNPAM! Menyimpan sesi...';
      } else if (lower.contains('otp')) {
        _currentStepText = 'Silakan masukkan kode OTP dari Telegram Anda.';
      } else if (lower.contains('login')) {
        _currentStepText = 'Masukkan NIM dan password Satu UNPAM Anda.';
      } else if (lower.contains('satu.unpam.ac.id')) {
        _currentStepText =
            'Login berhasil! Klik kartu My UNPAM di bawah jika belum terbuka otomatis.';
      }
    });
  }

  void _handleSsoStatus(String status) {
    if (!mounted || _tokenCaptured) return;
    setState(() {
      if (status == 'auto_submitted') {
        _currentStepText = 'NIM & password terisi otomatis. Menunggu verifikasi...';
      } else if (status == 'clicked_myunpam') {
        _currentStepText = 'Membuka My UNPAM...';
      } else if (status == 'clicked_proceed') {
        _currentStepText = 'Mengonfirmasi redirect ke My UNPAM...';
      }
    });
  }

  Future<void> _injectScripts(String url) async {
    final lower = url.toLowerCase();
    try {
      await _controller.runJavaScript(MyUnpamScripts.tokenSniffer);
      if (lower.contains('satu.unpam.ac.id')) {
        await _controller.runJavaScript(MyUnpamScripts.satuUnpamNavigator);
        final creds = await _credentials;
        if (creds != null && mounted) {
          await _controller.runJavaScript(MyUnpamScripts.fillLogin(creds.$1, creds.$2));
        }
      } else if (lower.contains('my.unpam.ac.id')) {
        _scheduleCloseFallback();
      }
    } catch (e) {
      debugPrint('[SsoAuthModal] script injection: $e');
    }
  }

  Future<void> _handleToken(String message) async {
    if (_tokenCaptured) return;
    final host = await _session.captureToken(message);
    if (host == null || !host.contains('my.unpam.ac.id')) return;
    _myUnpamTokenSeen = true;
    await _finishIfOnMyUnpam();
  }

  void _scheduleCloseFallback() {
    _closeFallback?.cancel();
    _closeFallback = Timer(const Duration(seconds: 6), () {
      if (_myUnpamTokenSeen) _finishIfOnMyUnpam();
    });
  }

  Future<void> _finishIfOnMyUnpam() async {
    if (_tokenCaptured || !mounted || !_myUnpamTokenSeen) return;
    final currentUrl = (await _controller.currentUrl())?.toLowerCase() ?? '';
    if (!currentUrl.contains('my.unpam.ac.id') || _tokenCaptured || !mounted) return;

    setState(() {
      _tokenCaptured = true;
      _currentStepText = 'Sesi Satu UNPAM & My UNPAM berhasil terhubung!';
    });
    await _session.syncCookies();
    _session.markConnected();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop(true);
  }

  String _getNoticeBannerText() {
    if (_currentStepText.contains('My UNPAM!') || _currentStepText.contains('Membuka')) {
      return 'Sedang menghubungkan ke My UNPAM. Jendela ini akan otomatis tertutup.';
    } else if (_currentStepText.contains('OTP')) {
      return 'Ketikkan kode OTP yang masuk ke chat bot Telegram UNPAM.';
    } else if (_currentStepText.contains('kartu My UNPAM')) {
      return 'Penting: klik ikon/kartu "My UNPAM" pada dashboard untuk melanjutkan.';
    }
    return 'Login dengan NIM & Password Satu UNPAM, lalu verifikasi OTP Telegram.';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final modalHeight = mediaQuery.size.height * 0.92;

    return Container(
      height: modalHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verifikasi Satu UNPAM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentStepText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textDark),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress / 100 : null,
              backgroundColor: Colors.grey.shade100,
              color: AppTheme.primaryBlue,
              minHeight: 2.5,
            )
          else
            const Divider(height: 1, thickness: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getNoticeBannerText(),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.blue.shade900,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_tokenCaptured)
                  Container(
                    color: Colors.white.withOpacity(0.92),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Berhasil Terhubung!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Menyiapkan data akademik Anda...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
