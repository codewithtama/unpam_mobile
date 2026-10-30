import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../providers/biometric_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../academic/data/my_unpam_session.dart';
import '../providers/mentari_provider.dart';

class MentariAuthModal extends StatefulWidget {
  const MentariAuthModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const MentariAuthModal(),
    );
  }

  @override
  State<MentariAuthModal> createState() => _MentariAuthModalState();
}

class _MentariAuthModalState extends State<MentariAuthModal> {
  late final WebViewController _controller;
  late final StorageService _storage;
  int _progress = 0;
  bool _isLoading = true;
  bool _sessionCaptured = false;
  String _currentStepText = 'Memuat portal login Mentari LMS...';
  late final Future<(String, String)?> _credentials;

  @override
  void initState() {
    super.initState();
    _storage = context.read<StorageService>();
    final session = context.read<MyUnpamSession>();
    _credentials = _resolveCredentials(session);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(ApiConstants.webViewUserAgent)
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
            _inspectPageAndExtract(url);
          },
        ),
      )
      ..loadRequest(Uri.parse('${ApiConstants.mentariBaseUrl}/login/index.php'));
  }

  Future<(String, String)?> _resolveCredentials(MyUnpamSession session) async {
    final remembered = session.rememberedCredentials;
    if (remembered != null) return remembered;

    final biometric = context.read<BiometricProvider>();
    if (biometric.isAvailable && biometric.hasSavedCredentials) {
      final creds = await biometric.getCredentialsForLogin();
      final nim = (creds?['nim'] ?? '').trim();
      final password = creds?['password'] ?? '';
      if (nim.isNotEmpty && password.isNotEmpty) {
        session.rememberCredentials(nim, password);
        return (nim, password);
      }
    }
    return null;
  }

  void _updateStepDescription(String url) {
    if (!mounted || _sessionCaptured) return;
    final lower = url.toLowerCase();
    setState(() {
      if (lower.contains('/my') || lower.contains('course/view.php')) {
        _currentStepText = 'Berhasil masuk Mentari! Menyimpan sesi & sesskey...';
      } else if (lower.contains('satu.unpam.ac.id')) {
        _currentStepText = 'Menghubungkan via SSO Satu UNPAM...';
      } else if (lower.contains('login')) {
        _currentStepText = 'Silakan login dengan NIM & Password Anda di Mentari.';
      } else {
        _currentStepText = 'Memproses navigasi Mentari...';
      }
    });
  }

  Future<void> _inspectPageAndExtract(String url) async {
    if (_sessionCaptured) return;
    final lower = url.toLowerCase();

    // 1. Auto-fill credentials jika berada di halaman login
    if (lower.contains('login/index.php') || lower.contains('/login')) {
      final creds = await _credentials;
      if (creds != null && mounted) {
        try {
          await _controller.runJavaScript('''
          (function(u, p) {
            try {
              var userEl = document.querySelector('#username') || document.querySelector('input[name="username"]');
              var passEl = document.querySelector('#password') || document.querySelector('input[name="password"]');
              if (userEl && passEl && !userEl.value) {
                userEl.value = u;
                passEl.value = p;
                ['input', 'change'].forEach(function(e) {
                  userEl.dispatchEvent(new Event(e, { bubbles: true }));
                  passEl.dispatchEvent(new Event(e, { bubbles: true }));
                });
              }
            } catch(e) {}
          })(${Uri.encodeComponent(creds.$1)}, ${Uri.encodeComponent(creds.$2)});
          ''');
        } catch (_) {}
      }
    }

    // 2. Ekstrak sesskey dari DOM
    String extractedSesskey = '';
    try {
      final rawKey = await _controller.runJavaScriptReturningResult(r'''
      (function() {
        try {
          if (window.M && window.M.cfg && window.M.cfg.sesskey) return window.M.cfg.sesskey;
          var el = document.querySelector('input[name="sesskey"]');
          if (el && el.value) return el.value;
          var m = document.documentElement.innerHTML.match(/"sesskey":"([a-zA-Z0-9]+)"/);
          if (m) return m[1];
          var m2 = document.documentElement.innerHTML.match(/logout\.php\?sesskey=([a-zA-Z0-9]+)/);
          if (m2) return m2[1];
        } catch (e) {}
        return '';
      })()
      ''');
      extractedSesskey = rawKey.toString().replaceAll('"', '').trim();
    } catch (_) {}

    // 3. Ekstrak Cookies Moodle dari WebViewCookieManager dan document.cookie
    String cookieString = '';
    try {
      final webCookies = await WebViewCookieManager().getCookies(
        domain: Uri.parse(ApiConstants.mentariBaseUrl),
      );
      if (webCookies.isNotEmpty) {
        cookieString = webCookies.map((c) => '${c.name}=${c.value}').join('; ');
      }
    } catch (_) {}

    if (cookieString.isEmpty) {
      try {
        final docCookie = await _controller.runJavaScriptReturningResult('document.cookie');
        cookieString = docCookie.toString().replaceAll('"', '').trim();
      } catch (_) {}
    }

    final hasMoodleCookie = cookieString.toLowerCase().contains('moodlesession');
    final isOnDashboard = lower.contains('/my') || lower.contains('course');

    if ((hasMoodleCookie || extractedSesskey.isNotEmpty) && (isOnDashboard || hasMoodleCookie)) {
      await _saveSessionAndFinish(cookieString, extractedSesskey);
    }
  }

  Future<void> _saveSessionAndFinish(String cookieString, String sesskey) async {
    if (_sessionCaptured || !mounted) return;
    _sessionCaptured = true;

    if (cookieString.isNotEmpty) {
      await _storage.saveMentariCookies(cookieString);
      await _storage.saveCookies(cookieString);
    }

    if (sesskey.isNotEmpty) {
      await _storage.saveMentariSesskey(sesskey);
    }

    if (!mounted) return;
    setState(() {
      _currentStepText = 'Sesi Mentari LMS & sesskey berhasil tersimpan!';
    });

    final mentariProvider = context.read<MentariProvider>();
    unawaited(mentariProvider.fetchCourses(forceRefresh: true));

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _manualVerifySession() async {
    final currentUrl = await _controller.currentUrl() ?? '';
    await _inspectPageAndExtract(currentUrl);

    if (!_sessionCaptured && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan selesaikan proses login pada tampilan terlebih dahulu.'),
          backgroundColor: AppTheme.accentGold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                    color: AppTheme.accentGold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hubungkan Mentari LMS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentStepText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(false),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              color: AppTheme.accentGold,
            )
          else
            const Divider(height: 1, thickness: 1, color: AppTheme.cardBorder),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.bgGrey,
              border: Border(top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Login sekali untuk sinkronisasi otomatis.',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                ),
                TextButton.icon(
                  onPressed: _manualVerifySession,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Verifikasi Sesi', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
