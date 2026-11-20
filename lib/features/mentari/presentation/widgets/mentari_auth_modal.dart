import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/mentari_scripts.dart';
import '../../../../core/network/cloudflare_clearance_modal.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../providers/biometric_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../academic/data/my_unpam_session.dart';
import '../../domain/models/mentari_course_model.dart';
import '../providers/mentari_provider.dart';

/// Modal Autentikasi Mentari LMS 100% Native Form.
/// WebView berjalan di background (1x1 px) untuk menjaga kompatibilitas sesi Chromium,
/// dan user HANYA membuka `CloudflareClearanceModal` bila terdeteksi tantangan Cloudflare Turnstile.
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
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final WebViewController _headlessController;
  late final StorageService _storage;

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _needsCloudflare = false;
  bool _sessionCaptured = false;
  String _statusText = 'Masukkan NIM dan Password Mentari LMS Anda.';

  @override
  void initState() {
    super.initState();
    _storage = context.read<StorageService>();
    _prefillCredentials();

    _headlessController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(ApiConstants.webViewUserAgent)
      ..addJavaScriptChannel(
        MentariScripts.tokenChannel,
        onMessageReceived: (m) => _onTokenChannelMessage(m.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => _inspectHeadlessPage(url),
        ),
      )
      ..loadRequest(Uri.parse('${ApiConstants.mentariBaseUrl}/login'));
  }

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _prefillCredentials() async {
    final session = context.read<MyUnpamSession>();
    final remembered = session.rememberedCredentials;
    if (remembered != null) {
      _nimController.text = remembered.$1;
      _passwordController.text = remembered.$2;
      return;
    }

    final biometric = context.read<BiometricProvider>();
    if (biometric.savedNim != null && biometric.savedNim!.isNotEmpty) {
      _nimController.text = biometric.savedNim!;
    }
  }

  Future<void> _fillWithBiometric() async {
    final biometric = context.read<BiometricProvider>();
    if (!biometric.hasSavedCredentials) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada kredensial tersimpan di Biometric Vault.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final creds = await biometric.getCredentialsForLogin();
    if (!mounted || creds == null) return;
    final nim = (creds['nim'] ?? '').trim();
    final pass = creds['password'] ?? '';
    if (nim.isNotEmpty && pass.isNotEmpty) {
      setState(() {
        _nimController.text = nim;
        _passwordController.text = pass;
      });
      await _submitNativeLogin();
    }
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

  Future<void> _inspectHeadlessPage(String url) async {
    if (_sessionCaptured || !mounted) return;
    try {
      await _headlessController.runJavaScript(MentariScripts.tokenSniffer);
      final cfRes = await _headlessController.runJavaScriptReturningResult(r'''
(function() {
  var t = (document.title || '').toLowerCase();
  return t.indexOf('just a moment') !== -1 ||
      t.indexOf('attention required') !== -1 ||
      !!document.querySelector('#challenge-form, iframe[src*="challenges.cloudflare.com"]');
})()
''');
      final isCf = cfRes == true || cfRes.toString() == 'true';
      if (mounted && isCf != _needsCloudflare) {
        setState(() {
          _needsCloudflare = isCf;
          if (isCf) {
            _statusText = 'Cloudflare membutuhkan verifikasi Turnstile. Klik tombol Verifikasi di bawah.';
          }
        });
      }
      if (!isCf) {
        await _verifyAndCaptureSession();
      }
    } catch (_) {}
  }

  Future<void> _submitNativeLogin() async {
    final nim = _nimController.text.trim();
    final pass = _passwordController.text;
    if (nim.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIM dan Password wajib diisi.'),
          backgroundColor: AppTheme.accentGold,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusText = 'Mengautentikasi akun Mentari secara native...';
    });

    context.read<MyUnpamSession>().rememberCredentials(nim, pass);

    try {
      // Coba login via API fetch di dalam context Chromium atau form submission headless
      await _headlessController.runJavaScript(MentariScripts.fillLogin(nim, pass));
      await Future.delayed(const Duration(milliseconds: 1800));
      await _verifyAndCaptureSession();

      if (!_sessionCaptured && mounted) {
        setState(() {
          _isSubmitting = false;
          _statusText = _needsCloudflare
              ? 'Selesaikan verifikasi Cloudflare Turnstile terlebih dahulu.'
              : 'Memverifikasi sesi... Jika belum masuk, klik Verifikasi Cloudflare.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _statusText = 'Terjadi kendala koneksi: $e';
        });
      }
    }
  }

  Future<void> _openCloudflareOnlyModal() async {
    final cleared = await CloudflareClearanceModal.show(
      context,
      targetUrl: '${ApiConstants.mentariBaseUrl}/login',
      portalTitle: 'Mentari LMS',
    );
    if (cleared == true && mounted) {
      setState(() {
        _needsCloudflare = false;
        _statusText = 'Cloudflare terverifikasi! Melanjutkan login native...';
      });
      await _headlessController.reload();
      if (_nimController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 800));
        await _submitNativeLogin();
      }
    }
  }

  Future<void> _verifyAndCaptureSession({String? token}) async {
    if (_sessionCaptured) return;

    String cookieString = '';
    try {
      final webCookies = await WebViewCookieManager().getCookies(
        domain: Uri.parse(ApiConstants.mentariBaseUrl),
      );
      if (webCookies.isNotEmpty) {
        cookieString = webCookies.map((c) => '${c.name}=${c.value}').join('; ');
      }
    } catch (_) {}

    try {
      final probeResult = await _headlessController.runJavaScriptReturningResult(r'''
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
    } catch (_) {}
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
      _isSubmitting = false;
      _statusText = courses.isNotEmpty
          ? '${courses.length} mata kuliah Mentari berhasil disinkronkan!'
          : 'Sesi Mentari LMS berhasil terhubung!';
    });

    final mentariProvider = context.read<MentariProvider>();
    unawaited(mentariProvider.fetchCourses(forceRefresh: true));

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bioProv = context.watch<BiometricProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headless 1x1 bridge
              SizedBox(
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0.01,
                  child: WebViewWidget(controller: _headlessController),
                ),
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppTheme.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login Native Mentari LMS',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusText,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (_needsCloudflare)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentGold),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Cloudflare Turnstile aktif. Klik tombol untuk mencentang verifikasi.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _openCloudflareOnlyModal,
                        child: const Text('Centang CF'),
                      ),
                    ],
                  ),
                ),

              TextField(
                controller: _nimController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'NIM Mahasiswa',
                  hintText: 'Masukkan NIM Anda',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password Mentari / Satu UNPAM',
                  hintText: 'Masukkan password Anda',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSubmitting ? null : _submitNativeLogin,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login_rounded, size: 18),
                      label: Text(_isSubmitting ? 'Menghubungkan...' : 'Masuk Native'),
                    ),
                  ),
                  if (bioProv.hasSavedCredentials) ...[
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Masuk dengan Biometrik',
                      onPressed: _isSubmitting ? null : _fillWithBiometric,
                      icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryBlue),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _openCloudflareOnlyModal,
                  icon: const Icon(Icons.verified_user_outlined, size: 16, color: AppTheme.accentGold),
                  label: const Text(
                    'Buka Verifikasi Cloudflare Turnstile Saja',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
