import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/mentari_scripts.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../providers/biometric_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../academic/data/my_unpam_session.dart';
import '../../domain/models/mentari_course_model.dart';
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
  String _currentStepText = 'Memuat portal Mentari LMS...';
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
      ..addJavaScriptChannel(
        MentariScripts.tokenChannel,
        onMessageReceived: (m) => _onTokenChannelMessage(m.message),
      )
      ..addJavaScriptChannel(
        MentariScripts.statusChannel,
        onMessageReceived: (m) {
          if (!mounted) return;
          if (m.message == 'auto_submitted') {
            setState(() {
              _currentStepText = 'Memverifikasi kredensial login Mentari...';
            });
          }
        },
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
            _inspectPageAndExtract(url);
          },
        ),
      )
      ..loadRequest(Uri.parse('${ApiConstants.mentariBaseUrl}/'));
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
      if (lower.contains('/u-courses') || lower.contains('/dashboard') || (lower.contains('mentari.unpam.ac.id') && !lower.contains('login'))) {
        _currentStepText = 'Berhasil masuk Mentari! Menyinkronkan daftar mata kuliah...';
      } else if (lower.contains('satu.unpam.ac.id')) {
        _currentStepText = 'Menghubungkan via SSO Satu UNPAM...';
      } else if (lower.contains('login')) {
        _currentStepText = 'Silakan login dengan NIM & Password Mentari Anda.';
      } else {
        _currentStepText = 'Memproses autentikasi Mentari LMS...';
      }
    });
  }

  Future<void> _onTokenChannelMessage(String message) async {
    if (_sessionCaptured) return;
    try {
      final payload = jsonDecode(message) as Map<String, dynamic>;
      final token = (payload['token'] ?? '').toString().trim();
      if (token.length > 20) {
        await _storage.saveMentariToken(token);
        await _verifyAndCaptureSession(token: token);
      }
    } catch (_) {}
  }

  Future<void> _inspectPageAndExtract(String url) async {
    if (_sessionCaptured) return;

    // 1. Injeksi token sniffer
    try {
      await _controller.runJavaScript(MentariScripts.tokenSniffer);
    } catch (_) {}

    // 2. Auto-fill credentials jika terdapat input login
    final creds = await _credentials;
    if (creds != null && mounted) {
      try {
        await _controller.runJavaScript(MentariScripts.fillLogin(creds.$1, creds.$2));
      } catch (_) {}
    }

    // 3. Verifikasi apakah sudah masuk dashboard atau memiliki session aktif
    await _verifyAndCaptureSession();
  }

  Future<void> _verifyAndCaptureSession({String? token}) async {
    if (_sessionCaptured) return;

    // Ekstrak cookies dari WebView
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

    // Jalankan verifikasi API langsung dalam konteks WebView browser
    try {
      final probeResult = await _controller.runJavaScriptReturningResult(r'''
(async function() {
  try {
    var stored = localStorage.getItem('access_token') || localStorage.getItem('token') || '';
    stored = stored.replace(/^__q_strn\|/, '').replace(/^Bearer\s+/i, '').replace(/["']/g, '');
    var headers = { 'Accept': 'application/json, text/plain, */*' };
    if (stored && stored.length > 20) {
      headers['Authorization'] = 'Bearer ' + stored;
    }
    var res = await fetch('/api/user-course?page=1&limit=50', { headers: headers, credentials: 'include' });
    if (res.status === 200) {
      var body = await res.text();
      return JSON.stringify({ ok: true, status: 200, body: body, token: stored });
    }
    var isLogin = location.pathname.indexOf('/login') !== -1;
    return JSON.stringify({ ok: !isLogin && stored.length > 20, status: res.status, token: stored });
  } catch (e) {
    return JSON.stringify({ ok: false, error: String(e) });
  }
})()
''');

      var probeStr = probeResult.toString();
      if (probeStr.startsWith('"') && probeStr.endsWith('"')) {
        probeStr = jsonDecode(probeStr);
      }
      final probeData = jsonDecode(probeStr) as Map<String, dynamic>;

      if (probeData['ok'] == true) {
        final activeToken = (probeData['token'] ?? token ?? '').toString().trim();
        final bodyStr = (probeData['body'] ?? '').toString();

        List<MentariCourseModel> courses = [];
        if (bodyStr.isNotEmpty) {
          try {
            final raw = jsonDecode(bodyStr);
            List<dynamic>? list;
            if (raw is List) {
              list = raw;
            } else if (raw is Map && raw['data'] is List) {
              list = raw['data'] as List;
            } else if (raw is Map && raw['courses'] is List) {
              list = raw['courses'] as List;
            }
            if (list != null && list.isNotEmpty) {
              courses = list
                  .whereType<Map<String, dynamic>>()
                  .map((e) => MentariCourseModel.fromJson(e))
                  .toList();
            }
          } catch (_) {}
        }

        await _saveSessionAndFinish(
          cookieString: cookieString,
          token: activeToken,
          courses: courses,
        );
      }
    } catch (e) {
      debugPrint('[MentariAuthModal] probe error: $e');
    }
  }

  Future<void> _saveSessionAndFinish({
    required String cookieString,
    required String token,
    List<MentariCourseModel> courses = const [],
  }) async {
    if (_sessionCaptured || !mounted) return;
    _sessionCaptured = true;

    if (cookieString.isNotEmpty) {
      await _storage.saveMentariCookies(cookieString);
      await _storage.saveCookies(cookieString);
    }

    if (token.isNotEmpty) {
      await _storage.saveMentariToken(token);
    }

    if (courses.isNotEmpty) {
      await _storage.saveMentariCachedCourses(
        jsonEncode(courses.map((c) => c.toJson()).toList()),
      );
    }

    if (!mounted) return;
    setState(() {
      _currentStepText = courses.isNotEmpty
          ? '${courses.length} mata kuliah Mentari berhasil disinkronkan!'
          : 'Sesi Mentari LMS berhasil terhubung!';
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
