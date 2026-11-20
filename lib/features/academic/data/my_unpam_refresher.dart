import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/my_unpam_scripts.dart';
import 'my_unpam_session.dart';

class MyUnpamRefresher {
  static const Duration _timeout = Duration(seconds: 50);
  static const Duration _stageGrace = Duration(seconds: 15);

  final MyUnpamSession _session;
  final ValueNotifier<WebViewController?> controller = ValueNotifier(null);

  Completer<RefreshOutcome>? _completer;
  Timer? _ticker;
  Timer? _deadline;
  DateTime _stageStartedAt = DateTime.now();
  bool _triedSatuUnpam = false;
  bool _validating = false;
  bool _isNavigating = false;
  int _loginTicks = 0;
  String _lastHost = '';

  MyUnpamRefresher(this._session);

  Future<RefreshOutcome> run() {
    final running = _completer;
    if (running != null) return running.future;

    final completer = Completer<RefreshOutcome>();
    _completer = completer;
    _triedSatuUnpam = false;
    _loginTicks = 0;
    _lastHost = '';
    _isNavigating = true;

    final webView = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(ApiConstants.webViewUserAgent)
      ..addJavaScriptChannel(
        MyUnpamScripts.tokenChannel,
        onMessageReceived: (message) => _onToken(message.message),
      )
      ..addJavaScriptChannel(
        MyUnpamScripts.statusChannel,
        onMessageReceived: (_) {},
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _isNavigating = true,
          onPageFinished: _onPageFinished,
        ),
      );

    controller.value = webView;
    // Prioritaskan membuka My UNPAM terlebih dahulu karena token JWT tersimpan di localStorage
    _loadStage(ApiConstants.myUnpamBaseUrl);
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
    _deadline = Timer(_timeout, () => _finish(RefreshOutcome.failed));

    return completer.future;
  }

  void _loadStage(String baseUrl) {
    _isNavigating = true;
    _stageStartedAt = DateTime.now();
    _loginTicks = 0;
    controller.value?.loadRequest(Uri.parse('$baseUrl/'));
  }

  Future<void> _onPageFinished(String url) async {
    _isNavigating = false;
    final webView = controller.value;
    if (webView == null) return;

    final lower = url.toLowerCase();
    try {
      await webView.runJavaScript(MyUnpamScripts.tokenSniffer);

      if (lower.contains('my.unpam.ac.id')) {
        // Cek langsung localStorage untuk token access_token
        await _tryExtractTokenDirectly(webView);
      } else if (lower.contains('satu.unpam.ac.id')) {
        await webView.runJavaScript(MyUnpamScripts.satuUnpamNavigator);
        final creds = _session.rememberedCredentials;
        if (creds != null) {
          await webView.runJavaScript(MyUnpamScripts.fillLogin(creds.$1, creds.$2));
        }
      }
    } catch (_) {}
  }

  Future<void> _tryExtractTokenDirectly(WebViewController webView) async {
    try {
      final result = await webView.runJavaScriptReturningResult(r'''
      (function() {
        try {
          var t = (localStorage.getItem('access_token') || '').replace(/^__q_strn\|/, '');
          if (t.indexOf('eyJ') === 0 && t.length > 20) return t;
          for (var i = 0; i < localStorage.length; i++) {
            var v = localStorage.getItem(localStorage.key(i)) || '';
            var m = v.match(/eyJ[\w-]+\.[\w-]+\.[\w-]+/);
            if (m) return m[0];
          }
        } catch(e) {}
        return '';
      })()
      ''');
      final tokenStr = result.toString().replaceAll('"', '').trim();
      if (tokenStr.startsWith('eyJ') && tokenStr.length > 20) {
        final host = await _session.captureToken(
          jsonEncode({'host': 'my.unpam.ac.id', 'token': tokenStr}),
        );
        if (host != null && host.contains('my.unpam.ac.id')) {
          await _validateAndFinish();
        }
      }
    } catch (_) {}
  }

  Future<void> _onToken(String message) async {
    final host = await _session.captureToken(message);
    if (host == null || !host.contains('my.unpam.ac.id')) return;
    await _validateAndFinish();
  }

  Future<void> _validateAndFinish() async {
    if (_validating || _completer == null) return;
    _validating = true;
    try {
      await _session.syncCookies();
      if (await _session.validate()) _finish(RefreshOutcome.refreshed);
    } finally {
      _validating = false;
    }
  }

  Future<void> _tick() async {
    if (_isNavigating) return;
    final webView = controller.value;
    if (webView == null) return;

    Map<String, dynamic>? state;
    try {
      state = _decodeState(await webView.runJavaScriptReturningResult(MyUnpamScripts.pageState));
    } catch (_) {
      return;
    }
    if (state == null || state['ready'] != true) return;

    final host = (state['host'] ?? '').toString();
    final onMyUnpam = host.contains('my.unpam.ac.id');
    final onSatuUnpam = host.contains('satu.unpam.ac.id');

    if (host != _lastHost) {
      _lastHost = host;
      _stageStartedAt = DateTime.now();
      _loginTicks = 0;
    }

    if (onMyUnpam) {
      await _tryExtractTokenDirectly(webView);
      if (_completer == null) return;
    }

    if (state['isLogin'] == true) {
      _loginTicks++;
      if (onSatuUnpam) {
        // Pada halaman login Satu UNPAM
        final hasCreds = _session.rememberedCredentials != null;
        final maxTicks = hasCreds ? 5 : 3;
        if (_loginTicks >= maxTicks) {
          _finish(RefreshOutcome.loginRequired);
          return;
        }
      } else if (onMyUnpam) {
        // My UNPAM redirect ke login, arahkan ke SSO Satu UNPAM
        if (!_triedSatuUnpam) {
          _triedSatuUnpam = true;
          _loadStage(ApiConstants.satuUnpamBaseUrl);
          return;
        }
        if (_loginTicks >= 3) {
          _finish(RefreshOutcome.loginRequired);
          return;
        }
      }
      return;
    }

    _loginTicks = 0;
    if (onMyUnpam) {
      await _validateAndFinish();
      if (_completer == null) return;
    }

    if (DateTime.now().difference(_stageStartedAt) > _stageGrace) {
      if (!onSatuUnpam && !_triedSatuUnpam) {
        _triedSatuUnpam = true;
        _loadStage(ApiConstants.satuUnpamBaseUrl);
      } else {
        _finish(RefreshOutcome.failed);
      }
    }
  }

  Map<String, dynamic>? _decodeState(Object raw) {
    dynamic value = raw;
    for (var i = 0; i < 2 && value is String; i++) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return null;
      }
    }
    return value is Map<String, dynamic> ? value : null;
  }

  void _finish(RefreshOutcome outcome) {
    final completer = _completer;
    if (completer == null) return;
    _completer = null;
    _ticker?.cancel();
    _deadline?.cancel();
    controller.value?.loadRequest(Uri.parse('about:blank'));
    controller.value = null;
    completer.complete(outcome);
  }
}

class MyUnpamRefreshHost extends StatelessWidget {
  final List<ValueListenable<WebViewController?>> controllers;
  final Widget child;

  const MyUnpamRefreshHost({
    super.key,
    required this.controllers,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        child,
        for (final listenable in controllers)
          ValueListenableBuilder<WebViewController?>(
            valueListenable: listenable,
            builder: (context, webView, _) {
              if (webView == null) return const SizedBox.shrink();
              return Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: WebViewWidget(controller: webView),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
