import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChromiumSessionService {
  static final ChromiumSessionService instance = ChromiumSessionService._();

  ChromiumSessionService._() {
    _initController();
  }

  late final WebViewController _controller;
  bool _isReady = false;
  Completer<void> _readyCompleter = Completer<void>();
  String? _activeBearerToken;
  String? _lastCookies;

  bool get isReady => _isReady;
  String? get activeBearerToken => _activeBearerToken;

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SessionBridgeChannel',
        onMessageReceived: _handleBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            _injectSessionMonitor();
            if (!_isReady) {
              _isReady = true;
              if (!_readyCompleter.isCompleted) {
                _readyCompleter.complete();
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://mentari.unpam.ac.id/'));
  }

  void _injectSessionMonitor() {
    const script = '''
(function() {
  if (window._unpamBridgeReady) return;
  window._unpamBridgeReady = true;

  function postMsg(data) {
    try {
      if (window.SessionBridgeChannel) {
        window.SessionBridgeChannel.postMessage(JSON.stringify(data));
      }
    } catch(e) {}
  }

  // Intercept Bearer Token dari XHR & Fetch
  var origSetHeader = XMLHttpRequest.prototype.setRequestHeader;
  XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
    if (header && header.toLowerCase() === 'authorization') {
      var t = String(value).replace(/^Bearer\\s+/i, '').trim();
      if (t) {
        window._activeBearerToken = t;
        postMsg({ type: 'token_found', token: t });
      }
    }
    return origSetHeader.apply(this, arguments);
  };

  var origFetch = window.fetch;
  window.fetch = function(input, init) {
    var headers = (init && init.headers) || (input && input.headers);
    if (headers) {
      var auth = null;
      if (typeof headers.get === 'function') {
        auth = headers.get('Authorization') || headers.get('authorization');
      } else if (typeof headers === 'object') {
        auth = headers['Authorization'] || headers['authorization'];
      }
      if (auth) {
        var t = String(auth).replace(/^Bearer\\s+/i, '').trim();
        if (t) {
          window._activeBearerToken = t;
          postMsg({ type: 'token_found', token: t });
        }
      }
    }
    return origFetch.apply(this, arguments);
  };

  // Scan LocalStorage untuk token
  try {
    for (var i = 0; i < localStorage.length; i++) {
      var val = localStorage.getItem(localStorage.key(i));
      if (!val) continue;
      var m = String(val).match(/eyJ[\\w-]+\\.[\\w-]+\\.[\\w-]+/);
      if (m) {
        window._activeBearerToken = m[0];
        postMsg({ type: 'token_found', token: m[0] });
        break;
      }
    }
  } catch(e) {}
})();
''';
    _controller.runJavaScript(script);
  }

  void _handleBridgeMessage(JavaScriptMessage msg) {
    try {
      final decoded = jsonDecode(msg.message);
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['type'] == 'token_found') {
        final t = decoded['token']?.toString();
        if (t != null && t.isNotEmpty) {
          _activeBearerToken = t;
        }
      }
    } catch (_) {}
  }

  Widget buildHeadlessWidget() {
    return SizedBox(
      width: 1,
      height: 1,
      child: WebViewWidget(controller: _controller),
    );
  }

  Future<void> reloadSession() async {
    _isReady = false;
    _readyCompleter = Completer<void>();
    await _controller.loadRequest(Uri.parse('https://mentari.unpam.ac.id/'));
    await ensureReady(timeout: const Duration(seconds: 8));
  }

  Future<void> ensureReady({Duration timeout = const Duration(seconds: 6)}) async {
    if (_isReady) return;
    try {
      await _readyCompleter.future.timeout(timeout);
    } catch (_) {
      // Jika timeout, tetap anggap siap untuk mencoba eksekusi
      _isReady = true;
    }
  }

  Future<Map<String, dynamic>?> fetchJson(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
  }) async {
    await ensureReady();

    String targetUrl = url;
    if (targetUrl.startsWith('/')) {
      targetUrl = 'https://mentari.unpam.ac.id$targetUrl';
    }

    final headersJson = jsonEncode(headers ?? {});
    final bodyJson = body != null ? jsonEncode(body) : 'null';

    final jsCode = '''
(async function() {
  try {
    var url = '$targetUrl';
    var method = '$method';
    var customHeaders = $headersJson;

    var reqHeaders = Object.assign({
      'Accept': 'application/json, text/plain, */*'
    }, customHeaders);

    if (window._activeBearerToken && !reqHeaders['Authorization']) {
      reqHeaders['Authorization'] = 'Bearer ' + window._activeBearerToken;
    }

    var opts = {
      method: method,
      headers: reqHeaders,
      credentials: 'include'
    };

    if (method !== 'GET' && method !== 'HEAD' && $bodyJson !== null) {
      opts.body = typeof $bodyJson === 'object' ? JSON.stringify($bodyJson) : String($bodyJson);
    }

    var res = await fetch(url, opts);
    var text = await res.text();

    try {
      var parsed = JSON.parse(text);
      return JSON.stringify({ ok: true, status: res.status, data: parsed });
    } catch(parseErr) {
      return JSON.stringify({ ok: false, status: res.status, rawText: text.substring(0, 300) });
    }
  } catch(err) {
    return JSON.stringify({ ok: false, error: String(err) });
  }
})()
''';

    try {
      final jsResult = await _controller.runJavaScriptReturningResult(jsCode);
      String clean = jsResult.toString();

      // Unescape format string hasil runJavaScriptReturningResult
      if (clean.startsWith('"') && clean.endsWith('"')) {
        clean = jsonDecode(clean);
      }

      final Map<String, dynamic> parsed = jsonDecode(clean) as Map<String, dynamic>;
      if (parsed['ok'] == true && parsed['data'] != null) {
        final data = parsed['data'];
        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is List) {
          return {'data': data};
        }
      }
      return null;
    } catch (e) {
      debugPrint('ChromiumSessionService fetchJson error: $e');
      return null;
    }
  }

  Future<String?> getCookies() async {
    try {
      final raw = await _controller.runJavaScriptReturningResult('document.cookie');
      var s = raw.toString();
      if (s.startsWith('"') && s.endsWith('"')) {
        s = jsonDecode(s);
      }
      _lastCookies = s;
      return s;
    } catch (_) {
      return _lastCookies;
    }
  }
}
