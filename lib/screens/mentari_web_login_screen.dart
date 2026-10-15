import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/network/api_client.dart';
import '../theme/app_theme.dart';

class MentariWebLoginScreen extends StatefulWidget {
  final Future<bool> Function(String token, {String? cookies}) onTokenFound;

  const MentariWebLoginScreen({super.key, required this.onTokenFound});

  @override
  State<MentariWebLoginScreen> createState() => _MentariWebLoginScreenState();
}

class _MentariWebLoginScreenState extends State<MentariWebLoginScreen> {
  static const _loginUrl = 'https://mentari.unpam.ac.id/';

  // Skrip injeksi untuk mencegat token di localStorage, sessionStorage, cookies, fetch, dan XHR
  static const _injectionScript = r'''
(function () {
  var re = /eyJ[\w-]+\.[\w-]+\.[\w-]+/g;
  var found = [];

  function scan(s) {
    if (!s) return;
    var matches = String(s).match(re);
    if (matches) {
      for (var i = 0; i < matches.length; i++) {
        if (found.indexOf(matches[i]) === -1) {
          found.push(matches[i]);
        }
      }
    }
  }

  // 1. Scan Storage
  try {
    [window.localStorage, window.sessionStorage].forEach(function (st) {
      if (!st) return;
      for (var i = 0; i < st.length; i++) {
        scan(st.getItem(st.key(i)));
      }
    });
    scan(document.cookie);
  } catch (e) {}

  // 2. Intercept Fetch & XHR
  try {
    if (!window._tokenIntercepted) {
      window._tokenIntercepted = true;
      var origFetch = window.fetch;
      window.fetch = function() {
        try {
          var h = arguments[1] && arguments[1].headers;
          if (h) {
            var auth = h['Authorization'] || h['authorization'] || (h.get && h.get('Authorization'));
            scan(auth);
          }
        } catch(e) {}
        return origFetch.apply(this, arguments);
      };

      var origSetHeader = XMLHttpRequest.prototype.setRequestHeader;
      XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
        if (header && header.toLowerCase() === 'authorization') {
          scan(value);
        }
        return origSetHeader.apply(this, arguments);
      };
    }
  } catch (e) {}

  TokenChannel.postMessage(JSON.stringify(found));
})();
''';

  late final WebViewController _controller;
  final Set<String> _tried = {};
  Timer? _poller;
  bool _validating = false;
  int _progress = 0;
  bool _canShowManualButton = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('TokenChannel', onMessageReceived: _onScanResult)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => _inject(),
          onPageFinished: (url) {
            _inject();
            // Jika user sudah masuk ke dashboard atau url bukan halaman login kosong, munculkan tombol masuk
            if (url.contains('dashboard') || !url.endsWith('.id/')) {
              if (mounted) setState(() => _canShowManualButton = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));

    _poller = Timer.periodic(const Duration(seconds: 2), (_) {
      _inject();
    });

    // Munculkan tombol bantuan otomatis setelah 4 detik agar pengguna tidak terjebak
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _canShowManualButton = true);
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  void _inject() {
    if (!_validating) {
      _controller.runJavaScript(_injectionScript);
    }
  }

  Future<String> _getCookieHeader() async {
    try {
      final raw = await _controller.runJavaScriptReturningResult('document.cookie');
      final s = raw.toString();
      if (s.startsWith('"') && s.endsWith('"')) {
        return s.substring(1, s.length - 1);
      }
      return s;
    } catch (_) {
      return '';
    }
  }

  Future<void> _onScanResult(JavaScriptMessage message) async {
    if (_validating) return;

    try {
      final List<dynamic> raw = jsonDecode(message.message) as List<dynamic>;
      final candidates = raw
          .whereType<String>()
          .toSet()
          .where((t) => !_tried.contains(t) && ApiClient.isTokenFresh(t));

      for (final token in candidates) {
        _tried.add(token);
        _validating = true;
        final cookies = await _getCookieHeader();
        final ok = await widget.onTokenFound(token, cookies: cookies);
        if (ok && mounted) {
          _poller?.cancel();
          Navigator.of(context).pop(true);
          return;
        }
        _validating = false;
      }
    } catch (_) {
      _validating = false;
    }
  }

  /// Tombol Manual: Membaca paksa localStorage & cookies dan langsung masuk ke aplikasi
  Future<void> _manualVerifyAndEnter() async {
    setState(() => _validating = true);

    try {
      // 1. Baca semua isi localStorage via JavaScript
      final result = await _controller.runJavaScriptReturningResult(
        r'''
        (function() {
          var all = [];
          for (var i = 0; i < localStorage.length; i++) {
            all.push(localStorage.getItem(localStorage.key(i)));
          }
          for (var j = 0; j < sessionStorage.length; j++) {
            all.push(sessionStorage.getItem(sessionStorage.key(j)));
          }
          all.push(document.cookie);
          return JSON.stringify(all);
        })()
        ''',
      );

      final re = RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]+');
      final matches = re.allMatches(result.toString());

      final cookies = await _getCookieHeader();

      for (final match in matches) {
        final token = match.group(0);
        if (token != null && ApiClient.isTokenFresh(token)) {
          final ok = await widget.onTokenFound(token, cookies: cookies);
          if (ok && mounted) {
            _poller?.cancel();
            Navigator.of(context).pop(true);
            return;
          }
        }
      }

      // Jika belum ketemu token, coba scan lagi
      _inject();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login My Unpam terlebih dahulu di layar web ini hingga masuk ke dashboard.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kendala verifikasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Portal Mentari'),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  backgroundColor: AppTheme.primaryBlue,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Tombol Masuk ke Aplikasi Mobile Native yang Selalu Siap Membantu
          if (_canShowManualButton)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: ElevatedButton.icon(
                onPressed: _validating ? null : _manualVerifyAndEnter,
                icon: _validating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                label: Text(
                  _validating ? 'Menyinkronkan Akun...' : 'Sudah Login? Masuk ke Aplikasi Mobile',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
