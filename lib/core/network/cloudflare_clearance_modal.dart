import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import '../../theme/app_theme.dart';

/// Exception khusus saat request REST API dihadang oleh Cloudflare Managed Challenge / Turnstile.
class CloudflareChallengeException implements Exception {
  final String targetUrl;
  final String message;

  const CloudflareChallengeException({
    required this.targetUrl,
    this.message = 'Verifikasi keamanan Cloudflare diperlukan untuk melanjutkan.',
  });

  @override
  String toString() => message;
}

/// Modal ringkas yang HANYA menampilkan kotak verifikasi Cloudflare Turnstile
/// ketika server kampus (Mentari / MyUnpam / Satu UNPAM) meminta validasi anti-bot.
/// Otomatis tertutup begitu cookie `cf_clearance` atau halaman non-challenge tercapai.
class CloudflareClearanceModal extends StatefulWidget {
  final String targetUrl;
  final String portalTitle;

  const CloudflareClearanceModal({
    super.key,
    required this.targetUrl,
    this.portalTitle = 'Portal Kampus UNPAM',
  });

  /// Deteksi apakah respons HTTP merupakan halaman tantangan Cloudflare Turnstile / WAF.
  static bool isCloudflareChallenge({
    int? statusCode,
    String? body,
    Map<String, dynamic>? headers,
  }) {
    final cfMitigated = headers?['cf-mitigated']?.toString().toLowerCase() ?? '';
    if (cfMitigated.contains('challenge')) return true;

    if (statusCode != 403 && statusCode != 503 && statusCode != 429) {
      return false;
    }

    final lowerBody = (body ?? '').toLowerCase();
    return lowerBody.contains('just a moment') ||
        lowerBody.contains('challenges.cloudflare.com') ||
        lowerBody.contains('cf-turnstile') ||
        lowerBody.contains('cf_chl_opt') ||
        lowerBody.contains('attention required! | cloudflare') ||
        lowerBody.contains('ray id');
  }

  static Future<bool?> show(
    BuildContext context, {
    required String targetUrl,
    String portalTitle = 'Portal Kampus UNPAM',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CloudflareClearanceModal(
        targetUrl: targetUrl,
        portalTitle: portalTitle,
      ),
    );
  }

  @override
  State<CloudflareClearanceModal> createState() => _CloudflareClearanceModalState();
}

class _CloudflareClearanceModalState extends State<CloudflareClearanceModal> {
  late final WebViewController _controller;
  Timer? _pollTimer;
  int _progress = 0;
  bool _isLoading = true;
  bool _isCleared = false;
  String _statusMessage = 'Memuat verifikasi keamanan Cloudflare...';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(ApiConstants.webViewUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (!mounted) return;
            setState(() {
              _progress = p;
              _isLoading = p < 100;
            });
          },
          onPageFinished: (_) => _checkClearance(),
        ),
      )
      ..loadRequest(Uri.parse(widget.targetUrl));

    _pollTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _checkClearance();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkClearance() async {
    if (_isCleared || !mounted) return;

    try {
      final result = await _controller.runJavaScriptReturningResult(r'''
(function() {
  var title = (document.title || '').toLowerCase();
  var html = (document.documentElement ? document.documentElement.innerHTML : '').toLowerCase();
  var isChallenge = title.indexOf('just a moment') !== -1 ||
      title.indexOf('attention required') !== -1 ||
      html.indexOf('cf_chl_opt') !== -1 ||
      !!document.querySelector('#challenge-form, #cf-challenge-running, iframe[src*="challenges.cloudflare.com"]');
  var bodyReady = document.body && (document.body.innerText.trim().length > 0 || document.querySelectorAll('input, button, a, div').length > 3);
  return JSON.stringify({
    isChallenge: isChallenge,
    bodyReady: !!bodyReady,
    cookie: document.cookie || '',
    href: location.href || ''
  });
})()
''');

      final rawStr = result.toString();
      if (rawStr.contains('"isChallenge":false') && rawStr.contains('"bodyReady":true')) {
        await _persistClearanceAndClose();
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Silakan centang kotak verifikasi Cloudflare di bawah.';
        });
      }
    } catch (_) {}
  }

  Future<void> _persistClearanceAndClose() async {
    if (_isCleared || !mounted) return;
    _isCleared = true;
    _pollTimer?.cancel();

    try {
      final storage = context.read<StorageService>();
      final uri = Uri.parse(widget.targetUrl);
      final cookies = await WebViewCookieManager().getCookies(domain: uri);
      if (cookies.isNotEmpty) {
        final serialized = cookies.map((c) => '${c.name}=${c.value}').join('; ');
        if (uri.host.contains('mentari')) {
          await storage.saveMentariCookies(serialized);
        } else if (uri.host.contains('my.unpam')) {
          await storage.saveMyUnpamCookies(serialized);
        } else if (uri.host.contains('satu.unpam')) {
          await storage.saveSatuUnpamCookies(serialized);
        }
        await storage.saveCookies(serialized);
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _statusMessage = 'Verifikasi Cloudflare berhasil! Melanjutkan ke aplikasi native...';
    });

    await Future.delayed(const Duration(milliseconds: 280));
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.62;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
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
                    color: AppTheme.accentGold.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifikasi Cloudflare (${widget.portalTitle})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
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
              value: _progress > 0 ? _progress / 100.0 : null,
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              color: AppTheme.accentGold,
            )
          else
            const Divider(height: 1, color: AppTheme.cardBorder),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isCleared)
                  Container(
                    color: Colors.white.withOpacity(0.94),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.successGreen,
                          size: 54,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Cloudflare Terverifikasi!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
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
