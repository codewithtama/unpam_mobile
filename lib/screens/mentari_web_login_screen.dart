import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../models/user_course_model.dart';
import '../models/course_detail_model.dart';
import '../theme/app_theme.dart';

class MentariWebLoginScreen extends StatefulWidget {
  final Future<bool> Function(
    String token, {
    String? cookies,
    UserCourseResponse? preloadCourses,
  }) onTokenFound;

  const MentariWebLoginScreen({super.key, required this.onTokenFound});

  @override
  State<MentariWebLoginScreen> createState() => _MentariWebLoginScreenState();
}

class _MentariWebLoginScreenState extends State<MentariWebLoginScreen> {
  static const _loginUrl = 'https://mentari.unpam.ac.id/';

  static const _injectionScript = r'''
(function () {
  if (window._unpamScriptLoaded) {
    if (window._unpamScan) window._unpamScan();
    return;
  }
  window._unpamScriptLoaded = true;

  function postMsg(data) {
    try {
      if (window.TokenChannel) {
        window.TokenChannel.postMessage(JSON.stringify(data));
      }
    } catch(e) {}
  }

  // 1. Intercept XMLHttpRequest
  var origOpen = XMLHttpRequest.prototype.open;
  var origSend = XMLHttpRequest.prototype.send;
  var origSetHeader = XMLHttpRequest.prototype.setRequestHeader;

  XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
    this._headers = this._headers || {};
    this._headers[header.toLowerCase()] = value;
    if (header && header.toLowerCase() === 'authorization') {
      var t = String(value).replace(/^Bearer\s+/i, '').trim();
      if (t) {
        window._activeBearerToken = t;
        postMsg({ type: 'captured_token', token: t, source: 'xhr_header' });
      }
    }
    return origSetHeader.apply(this, arguments);
  };

  XMLHttpRequest.prototype.open = function(method, url) {
    this._url = url;
    return origOpen.apply(this, arguments);
  };

  XMLHttpRequest.prototype.send = function() {
    var self = this;
    this.addEventListener('load', function() {
      try {
        if (self._url && String(self._url).indexOf('user-course') !== -1) {
          var json = JSON.parse(self.responseText);
          if (json && (json.data || Array.isArray(json))) {
            postMsg({
              type: 'live_courses',
              data: json,
              token: window._activeBearerToken || null
            });
          }
        } else if (self._url && String(self._url).indexOf('course') !== -1) {
          try {
            var cJson = JSON.parse(self.responseText);
            if (cJson && (cJson.data || cJson.peserta || cJson.kode_course)) {
              postMsg({ type: 'live_course_detail', data: cJson });
            }
          } catch(e) {}
        }
      } catch(e) {}
    });
    return origSend.apply(this, arguments);
  };

  // 2. Intercept Fetch API
  var origFetch = window.fetch;
  window.fetch = function(input, init) {
    var url = typeof input === 'string' ? input : (input && input.url ? input.url : '');
    var headers = (init && init.headers) || (input && input.headers);
    var authHeader = null;
    if (headers) {
      if (typeof headers.get === 'function') {
        authHeader = headers.get('Authorization') || headers.get('authorization');
      } else if (typeof headers === 'object') {
        authHeader = headers['Authorization'] || headers['authorization'] || headers['AUTHORIZATION'];
      }
    }
    if (authHeader) {
      var t = String(authHeader).replace(/^Bearer\s+/i, '').trim();
      if (t) {
        window._activeBearerToken = t;
        postMsg({ type: 'captured_token', token: t, source: 'fetch_header' });
      }
    }

    return origFetch.apply(this, arguments).then(function(res) {
      try {
        if (String(url).indexOf('user-course') !== -1) {
          var clone = res.clone();
          clone.json().then(function(json) {
            if (json && (json.data || Array.isArray(json))) {
              postMsg({
                type: 'live_courses',
                data: json,
                token: window._activeBearerToken || null
              });
            }
          }).catch(function() {});
        } else if (String(url).indexOf('course') !== -1) {
          var clone2 = res.clone();
          clone2.json().then(function(cJson) {
            if (cJson && (cJson.data || cJson.peserta || cJson.kode_course)) {
              postMsg({ type: 'live_course_detail', data: cJson });
            }
          }).catch(function() {});
        }
      } catch(e) {}
      return res;
    });
  };

  // 3. Storage Scanner
  window._unpamScan = function() {
    var priorityTokens = [];
    var otherTokens = [];

    function checkVal(val) {
      if (!val) return;
      try {
        var parsed = JSON.parse(val);
        if (parsed && typeof parsed === 'object') {
          ['access_token', 'token', 'accessToken', 'bearer'].forEach(function(k) {
            if (parsed[k] && typeof parsed[k] === 'string' && parsed[k].length > 20) {
              priorityTokens.push(parsed[k].replace(/^Bearer\s+/i, '').trim());
            }
          });
          if (parsed.id_token && typeof parsed.id_token === 'string') {
            otherTokens.push(parsed.id_token);
          }
        }
      } catch(e) {}

      var re = /eyJ[\w-]+\.[\w-]+\.[\w-]+/g;
      var matches = String(val).match(re);
      if (matches) {
        for (var i = 0; i < matches.length; i++) {
          if (priorityTokens.indexOf(matches[i]) === -1 && otherTokens.indexOf(matches[i]) === -1) {
            otherTokens.push(matches[i]);
          }
        }
      }
    }

    [window.localStorage, window.sessionStorage].forEach(function(st) {
      if (!st) return;
      for (var i = 0; i < st.length; i++) {
        var key = st.key(i);
        var val = st.getItem(key);
        checkVal(val);
      }
    });

    checkVal(document.cookie);

    postMsg({
      type: 'scan_tokens',
      priority: priorityTokens,
      others: otherTokens
    });
  };

  // 4. Active Live Course Fetcher (Berjalan di dalam sesi Chromium aktif)
  window._unpamFetchLiveCourses = function() {
    var url = '/api/user-course?page=1&limit=50';
    var headers = { 'Accept': 'application/json' };
    if (window._activeBearerToken) {
      headers['Authorization'] = 'Bearer ' + window._activeBearerToken;
    }
    fetch(url, { headers: headers, credentials: 'include' })
      .then(function(r) { return r.json(); })
      .then(function(json) {
        if (json && (json.data || Array.isArray(json))) {
          postMsg({
            type: 'live_courses',
            data: json,
            token: window._activeBearerToken || null
          });
        }
      })
      .catch(function() {
        window._unpamScan();
      });
  };

  window._unpamScan();
})();
''';

  late final WebViewController _controller;
  final Set<String> _tried = {};
  String? _lastCapturedToken;
  Timer? _poller;
  bool _validating = false;
  int _progress = 0;
  bool _canShowManualButton = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('TokenChannel', onMessageReceived: _onChannelMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => _inject(),
          onPageFinished: (url) {
            _inject();
            if (url.contains('dashboard') || !url.endsWith('.id/')) {
              if (mounted) setState(() => _canShowManualButton = true);
              // Jalankan pemanggilan aktif live data setelah halaman selesai
              Future.delayed(const Duration(seconds: 1), () {
                _triggerActiveFetch();
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));

    _poller = Timer.periodic(const Duration(seconds: 2), (_) {
      _inject();
    });

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

  void _triggerActiveFetch() {
    _controller.runJavaScript(
      'if (window._unpamFetchLiveCourses) { window._unpamFetchLiveCourses(); } else { if (window._unpamScan) window._unpamScan(); }',
    );
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

  Future<void> _onChannelMessage(JavaScriptMessage message) async {
    if (_validating) return;

    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map<String, dynamic>) return;

      final type = decoded['type']?.toString();

      // Kasus 0: Detail mata kuliah tertangkap dari traffic WebView!
      if (type == 'live_course_detail') {
        final rawDetail = decoded['data'];
        if (rawDetail is Map<String, dynamic>) {
          try {
            final detail = CourseDetailResponse.fromJson(rawDetail);
            if (detail.kodeCourse.isNotEmpty) {
              final storage = await StorageService.getInstance();
              await storage.saveCachedCourseDetail(
                detail.kodeCourse,
                jsonEncode(rawDetail),
              );
            }
          } catch (_) {}
        }
      }

      // Kasus A: Data Real Mata Kuliah langsung tertangkap dari traffic WebView!
      if (type == 'live_courses') {
        final rawData = decoded['data'];
        if (rawData is Map<String, dynamic>) {
          final courseRes = UserCourseResponse.fromJson(rawData);
          if (courseRes.data.isNotEmpty) {
            _validating = true;
            final token = decoded['token']?.toString() ?? _lastCapturedToken ?? '';
            final cookies = await _getCookieHeader();

            final ok = await widget.onTokenFound(
              token,
              cookies: cookies,
              preloadCourses: courseRes,
            );

            if (ok && mounted) {
              _poller?.cancel();
              Navigator.of(context).pop(true);
              return;
            }
            _validating = false;
          }
        }
      }

      // Kasus B: Bearer token aktif tertangkap dari request fetch/XHR
      if (type == 'captured_token') {
        final token = decoded['token']?.toString();
        if (token != null && token.isNotEmpty) {
          _lastCapturedToken = token;
          if (!_tried.contains(token) && ApiClient.isTokenFresh(token)) {
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
        }
      }

      // Kasus C: Hasil pemindaian storage
      if (type == 'scan_tokens') {
        final priority = (decoded['priority'] as List<dynamic>?)?.cast<String>() ?? [];
        final others = (decoded['others'] as List<dynamic>?)?.cast<String>() ?? [];

        // Uji token prioritas (access_token) terlebih dahulu!
        for (final token in priority) {
          if (!_tried.contains(token) && ApiClient.isTokenFresh(token)) {
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
        }

        // Uji kandidat lainnya
        for (final token in others) {
          if (!_tried.contains(token) && ApiClient.isTokenFresh(token)) {
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
        }
      }
    } catch (_) {
      _validating = false;
    }
  }

  /// Tombol Manual: Membaca paksa sesi WebView dan langsung memuat data ke aplikasi native
  Future<void> _manualVerifyAndEnter() async {
    setState(() => _validating = true);

    try {
      final cookies = await _getCookieHeader();

      // 1. Eksekusi fetch langsung di dalam sesi Chromium WebView yang sudah lolos Cloudflare
      final jsResult = await _controller.runJavaScriptReturningResult(
        r'''
        (async function() {
          try {
            var url = '/api/user-course?page=1&limit=50';
            var headers = { 'Accept': 'application/json' };
            if (window._activeBearerToken) {
              headers['Authorization'] = 'Bearer ' + window._activeBearerToken;
            }
            var res = await fetch(url, { headers: headers, credentials: 'include' });
            var json = await res.json();
            return JSON.stringify({
              ok: true,
              data: json,
              token: window._activeBearerToken || null
            });
          } catch(e) {
            return JSON.stringify({ ok: false, error: String(e) });
          }
        })()
        ''',
      );

      final str = jsResult.toString();
      // Handle string escaping dari runJavaScriptReturningResult
      String cleanJson = str;
      if (cleanJson.startsWith('"') && cleanJson.endsWith('"')) {
        cleanJson = jsonDecode(cleanJson);
      }

      final Map<String, dynamic> parsed = jsonDecode(cleanJson) as Map<String, dynamic>;

      if (parsed['ok'] == true && parsed['data'] != null) {
        final courseRes = UserCourseResponse.fromJson(parsed['data'] as Map<String, dynamic>);
        if (courseRes.data.isNotEmpty) {
          final token = parsed['token']?.toString() ?? _lastCapturedToken ?? '';
          final ok = await widget.onTokenFound(
            token,
            cookies: cookies,
            preloadCourses: courseRes,
          );
          if (ok && mounted) {
            _poller?.cancel();
            Navigator.of(context).pop(true);
            return;
          }
        }
      }

      // 2. Jika fetch belum berhasil (misal belum selesai login di web)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pastikan Anda sudah menyelesaikan login My Unpam di halaman web di atas hingga muncul daftar mata kuliah.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kendala sinkronisasi: $e')),
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
                  _validating ? 'Menyinkronkan Akun & Data...' : 'Sudah Login? Masuk ke Aplikasi Mobile',
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
