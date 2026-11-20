import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/constants/my_unpam_scripts.dart';
import '../../../../../core/network/cloudflare_clearance_modal.dart';
import '../../data/my_unpam_session.dart';
import '../../../../../providers/biometric_provider.dart';
import '../../../../../theme/app_theme.dart';

/// Modal Autentikasi Satu UNPAM & My UNPAM 100% Native Form + OTP Telegram.
/// WebView berjalan secara headless (1x1 px) untuk menjaga cookie jar Chromium,
/// sedangkan user hanya melihat form Native Flutter dan hanya membuka
/// `CloudflareClearanceModal` bila Cloudflare Turnstile meminta centang verifikasi.
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
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  late final WebViewController _headlessController;
  late final MyUnpamSession _session;

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isOtpStep = false;
  bool _needsCloudflare = false;
  bool _tokenCaptured = false;
  bool _myUnpamTokenSeen = false;
  String _currentStepText = 'Masukkan NIM dan Password Satu UNPAM Anda.';
  Timer? _closeFallback;

  @override
  void initState() {
    super.initState();
    _session = context.read<MyUnpamSession>();
    _prefillCredentials();

    _headlessController = WebViewController()
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
    _nimController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _prefillCredentials() async {
    final remembered = _session.rememberedCredentials;
    if (remembered != null) {
      _nimController.text = remembered.$1;
      _passwordController.text = remembered.$2;
      return;
    }

    final biometric = context.read<BiometricProvider>();
    final nim = widget.initialNim ?? biometric.savedNim;
    if (nim != null && nim.isNotEmpty) {
      _nimController.text = nim;
    }
  }

  Future<void> _fillWithBiometric() async {
    final biometric = context.read<BiometricProvider>();
    if (!biometric.hasSavedCredentials) return;

    final creds = await biometric.getCredentialsForLogin();
    if (!mounted || creds == null) return;
    final nim = (creds['nim'] ?? '').trim();
    final password = creds['password'] ?? '';
    if (nim.isNotEmpty && password.isNotEmpty) {
      _session.rememberCredentials(nim, password);
      setState(() {
        _nimController.text = nim;
        _passwordController.text = password;
      });
      await _submitNativeCredentials();
    }
  }

  void _updateStepDescription(String url) {
    if (!mounted || _tokenCaptured) return;
    final lower = url.toLowerCase();
    setState(() {
      if (lower.contains('my.unpam.ac.id')) {
        _currentStepText = 'Berhasil masuk My UNPAM! Menyimpan sesi...';
      } else if (lower.contains('otp')) {
        _isOtpStep = true;
        _isSubmitting = false;
        _currentStepText = 'Masukkan 6 digit kode OTP dari Bot Telegram UNPAM Anda.';
      } else if (lower.contains('satu.unpam.ac.id') && !lower.contains('login')) {
        _currentStepText = 'Mengarahkan otomatis dari Satu UNPAM ke My UNPAM...';
      }
    });
  }

  void _handleSsoStatus(String status) {
    if (!mounted || _tokenCaptured) return;
    setState(() {
      if (status == 'auto_submitted') {
        _currentStepText = 'Memverifikasi kredensial Satu UNPAM...';
      } else if (status == 'clicked_myunpam') {
        _currentStepText = 'Membuka sesi My UNPAM...';
      } else if (status == 'clicked_proceed') {
        _currentStepText = 'Mengonfirmasi akses SSO ke My UNPAM...';
      }
    });
  }

  Future<void> _injectScripts(String url) async {
    final lower = url.toLowerCase();
    try {
      await _headlessController.runJavaScript(MyUnpamScripts.tokenSniffer);

      // Cek apakah halaman ditahan oleh Cloudflare Turnstile
      final cfRes = await _headlessController.runJavaScriptReturningResult(r'''
(function() {
  var t = (document.title || '').toLowerCase();
  var hasOtp = !!document.querySelector('input[name*="otp" i], input[placeholder*="otp" i]');
  var isCf = t.indexOf('just a moment') !== -1 ||
      t.indexOf('attention required') !== -1 ||
      !!document.querySelector('#challenge-form, iframe[src*="challenges.cloudflare.com"]');
  return JSON.stringify({ isCf: isCf, hasOtp: hasOtp });
})()
''');
      final rawStr = cfRes.toString();
      final isCf = rawStr.contains('"isCf":true');
      final hasOtp = rawStr.contains('"hasOtp":true');

      if (mounted) {
        setState(() {
          _needsCloudflare = isCf;
          if (hasOtp) {
            _isOtpStep = true;
            _isSubmitting = false;
            _currentStepText = 'Masukkan kode OTP dari Telegram Anda.';
          }
        });
      }

      if (lower.contains('satu.unpam.ac.id')) {
        await _headlessController.runJavaScript(MyUnpamScripts.satuUnpamNavigator);
      } else if (lower.contains('my.unpam.ac.id')) {
        _scheduleCloseFallback();
      }
    } catch (e) {
      debugPrint('[SsoAuthModal] script injection: $e');
    }
  }

  Future<void> _submitNativeCredentials() async {
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

    _session.rememberCredentials(nim, pass);
    setState(() {
      _isSubmitting = true;
      _currentStepText = 'Mengirim kredensial ke Satu UNPAM...';
    });

    try {
      await _headlessController.runJavaScript(
        'window.__unpamAutoSubmitted = false;',
      );
      await _headlessController.runJavaScript(
        MyUnpamScripts.fillLogin(nim, pass),
      );
    } catch (_) {}
  }

  Future<void> _submitNativeOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _currentStepText = 'Memverifikasi kode OTP Telegram...';
    });

    try {
      await _headlessController.runJavaScript('''
(function(otpVal) {
  var inp = document.querySelector('input[name*="otp" i], input[type="number"], input[type="tel"], input[type="text"]');
  if (inp) {
    var desc = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(inp), 'value') ||
        Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
    if (desc && desc.set) desc.set.call(inp, otpVal); else inp.value = otpVal;
    ['input', 'change', 'blur'].forEach(function(t) {
      inp.dispatchEvent(new Event(t, { bubbles: true }));
    });
  }
  var btns = Array.from(document.querySelectorAll('button, input[type="submit"], [role="button"]'));
  var btn = btns.find(function(b) {
    var txt = (b.textContent || b.value || '').toLowerCase();
    return txt.indexOf('verifikasi') !== -1 || txt.indexOf('kirim') !== -1 || txt.indexOf('submit') !== -1 || txt.indexOf('masuk') !== -1;
  });
  if (btn) btn.click();
})(${jsonEncode(otp)});
''');
    } catch (_) {}
  }

  Future<void> _openCloudflareOnlyModal() async {
    final currentUrl = await _headlessController.currentUrl() ??
        '${ApiConstants.satuUnpamBaseUrl}/login';
    if (!mounted) return;
    final cleared = await CloudflareClearanceModal.show(
      context,
      targetUrl: currentUrl,
      portalTitle: 'Satu UNPAM / MyUnpam',
    );
    if (cleared == true && mounted) {
      setState(() {
        _needsCloudflare = false;
        _currentStepText = 'Cloudflare terverifikasi! Melanjutkan koneksi SSO...';
      });
      await _headlessController.reload();
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
    _closeFallback = Timer(const Duration(seconds: 4), () {
      if (_myUnpamTokenSeen) _finishIfOnMyUnpam();
    });
  }

  Future<void> _finishIfOnMyUnpam() async {
    if (_tokenCaptured || !mounted || !_myUnpamTokenSeen) return;
    final currentUrl = (await _headlessController.currentUrl())?.toLowerCase() ?? '';
    if (!currentUrl.contains('my.unpam.ac.id') || _tokenCaptured || !mounted) return;

    setState(() {
      _tokenCaptured = true;
      _isSubmitting = false;
      _currentStepText = 'Sesi Satu UNPAM & My UNPAM berhasil terhubung!';
    });
    await _session.syncCookies();
    _session.markConnected();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.of(context).pop(true);
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
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login Native Satu UNPAM',
                          style: TextStyle(
                            fontSize: 16.5,
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
                          'Verifikasi Cloudflare Turnstile diperlukan untuk melanjutkan.',
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

              if (!_isOtpStep) ...[
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
                    labelText: 'Password Satu UNPAM',
                    hintText: 'Masukkan password Anda',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                        onPressed: _isSubmitting ? null : _submitNativeCredentials,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_rounded, size: 18),
                        label: Text(_isSubmitting ? 'Memproses...' : 'Masuk Satu UNPAM'),
                      ),
                    ),
                    if (bioProv.hasSavedCredentials) ...[
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: 'Auto-Fill Biometrik',
                        onPressed: _isSubmitting ? null : _fillWithBiometric,
                        icon: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Kode OTP Telegram (6 Digit)',
                    hintText: 'Contoh: 123456',
                    prefixIcon: Icon(Icons.telegram_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _submitNativeOtp,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(_isSubmitting ? 'Memverifikasi OTP...' : 'Verifikasi Kode OTP'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _isOtpStep = false;
                    _isSubmitting = false;
                  }),
                  child: const Text('Kembali ke Input NIM & Password'),
                ),
              ],

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _isOtpStep = !_isOtpStep),
                    icon: const Icon(Icons.pin_outlined, size: 16),
                    label: Text(
                      _isOtpStep ? 'Input NIM' : 'Sudah Punya Kode OTP?',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openCloudflareOnlyModal,
                    icon: const Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: AppTheme.accentGold,
                    ),
                    label: const Text(
                      'Verifikasi Cloudflare',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
