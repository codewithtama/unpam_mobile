import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/my_unpam_scripts.dart';
import 'my_unpam_session.dart';

class MyUnpamWebFetcher {
  static const String channelName = 'MyUnpamFetchChannel';
  static const Duration _pageTimeout = Duration(seconds: 25);
  static const Duration _requestTimeout = Duration(seconds: 25);

  final MyUnpamSession _session;
  final ValueNotifier<WebViewController?> controller = ValueNotifier(null);
  final Map<String, Completer<Response<dynamic>>> _pending = {};
  Completer<void>? _pageReady;
  int _sequence = 0;

  MyUnpamWebFetcher(this._session) {
    _session.addSignOutListener(reset);
  }

  Future<Response<dynamic>> get(String path, Map<String, dynamic>? query, String? token) async {
    final parsed = Uri.parse(path);
    final queryParams = <String, String>{
      ...parsed.queryParameters,
      if (query != null) ...query.map((k, v) => MapEntry(k, '$v')),
    };
    final uri = Uri(
      path: parsed.path,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    var response = await _fetch(uri.toString(), token);
    if (_isChallenge(response)) {
      await _reloadPage();
      response = await _fetch(uri.toString(), token);
    }
    return response;
  }

  Future<Response<dynamic>> _fetch(String url, String? token) async {
    await _ensurePage();
    final webView = controller.value!;
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
    final completer = Completer<Response<dynamic>>();
    _pending[id] = completer;

    try {
      await webView.runJavaScript('''
(async function(id, url, token) {
  function send(payload) { window.$channelName.postMessage(JSON.stringify(payload)); }
  try {
    var stored = (localStorage.getItem('access_token') || '').replace(/^__q_strn\\|/, '');
    var auth = stored.indexOf('eyJ') === 0 ? stored : token;
    var headers = { 'Accept': 'application/json, text/plain, */*' };
    if (auth) headers['Authorization'] = 'Bearer ' + auth;
    var res = await fetch(url, { headers: headers, credentials: 'include' });
    send({ id: id, status: res.status, body: await res.text(), token: auth || '' });
  } catch (e) {
    send({ id: id, status: 0, error: String(e) });
  }
})(${jsonEncode(id)}, ${jsonEncode(url)}, ${jsonEncode(token ?? '')});
''');
    } catch (e) {
      _pending.remove(id);
      throw PortalRequestException('Gagal menjalankan permintaan My UNPAM: $e');
    }

    return completer.future.timeout(_requestTimeout, onTimeout: () {
      _pending.remove(id);
      throw const PortalRequestException(
          'Koneksi ke My UNPAM terlalu lama. Periksa jaringan Anda.');
    });
  }

  void _onMessage(String raw) {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final completer = _pending.remove(payload['id']);
    if (completer == null || completer.isCompleted) return;

    final status = (payload['status'] as num?)?.toInt() ?? 0;
    if (status == 0) {
      completer.completeError(
        const PortalRequestException(
            'Tidak dapat terhubung ke My UNPAM. Periksa koneksi internet Anda.'),
      );
      return;
    }

    final token = (payload['token'] ?? '').toString();
    if (status == 200 && token.length > 20) {
      _session.captureToken(jsonEncode({'host': 'my.unpam.ac.id', 'token': token}));
    }

    final body = (payload['body'] ?? '').toString();
    dynamic data = body;
    try {
      data = jsonDecode(body);
    } catch (_) {}
    completer.complete(Response(
      requestOptions: RequestOptions(path: ApiConstants.myUnpamBaseUrl),
      statusCode: status,
      data: data,
    ));
  }

  bool _isChallenge(Response<dynamic> response) {
    final body = response.data;
    if (body is String) {
      final lower = body.toLowerCase();
      if (lower.contains('challenges.cloudflare.com') ||
          lower.contains('<title>just a moment')) {
        return true;
      }
    }
    return response.statusCode == 403;
  }

  Future<void> _ensurePage() {
    final ready = _pageReady;
    if (ready != null) return ready.future;

    final completer = Completer<void>();
    _pageReady = completer;
    controller.value = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(ApiConstants.webViewUserAgent)
      ..addJavaScriptChannel(channelName, onMessageReceived: (m) => _onMessage(m.message))
      ..addJavaScriptChannel(
        MyUnpamScripts.tokenChannel,
        onMessageReceived: (m) => _session.captureToken(m.message),
      )
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: _onPageFinished))
      ..loadRequest(Uri.parse('${ApiConstants.myUnpamBaseUrl}/'));

    return completer.future.timeout(_pageTimeout, onTimeout: () {
      _pageReady = null;
      controller.value = null;
      throw const PortalRequestException('Halaman My UNPAM tidak dapat dimuat. Coba lagi.');
    });
  }

  Future<void> _onPageFinished(String url) async {
    if (!url.toLowerCase().contains('my.unpam.ac.id')) return;
    try {
      await controller.value?.runJavaScript(MyUnpamScripts.tokenSniffer);
    } catch (_) {}
    final ready = _pageReady;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  Future<void> _reloadPage() async {
    final webView = controller.value;
    if (webView == null) return;
    final completer = Completer<void>();
    _pageReady = completer;
    await webView.loadRequest(Uri.parse('${ApiConstants.myUnpamBaseUrl}/'));
    await completer.future.timeout(_pageTimeout, onTimeout: () {});
    await Future.delayed(const Duration(seconds: 2));
  }

  void reset() {
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(const PortalRequestException('Sesi direset.'));
    }
    _pending.clear();
    _pageReady = null;
    controller.value = null;
  }
}
