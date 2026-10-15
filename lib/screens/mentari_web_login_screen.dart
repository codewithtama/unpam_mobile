import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/network/api_client.dart';

/// Membuka halaman login Mentari asli (Turnstile ditangani halaman itu sendiri),
/// lalu mengembalikan token JWT pertama yang diterima server saat divalidasi.
class MentariWebLoginScreen extends StatefulWidget {
  final Future<bool> Function(String token) onTokenFound;

  const MentariWebLoginScreen({super.key, required this.onTokenFound});

  @override
  State<MentariWebLoginScreen> createState() => _MentariWebLoginScreenState();
}

class _MentariWebLoginScreenState extends State<MentariWebLoginScreen> {
  static const _loginUrl = 'https://mentari.unpam.ac.id/';
  static const _scanScript = r'''
(function () {
  var re = /eyJ[\w-]+\.[\w-]+\.[\w-]+/g;
  var found = [];
  function scan(s) { var m = String(s || '').match(re); if (m) found = found.concat(m); }
  try {
    [window.localStorage, window.sessionStorage].forEach(function (st) {
      for (var i = 0; i < st.length; i++) { scan(st.getItem(st.key(i))); }
    });
    scan(document.cookie);
  } catch (e) {}
  TokenChannel.postMessage(JSON.stringify(found));
})();
''';

  late final WebViewController _controller;
  final Set<String> _tried = {};
  Timer? _poller;
  bool _validating = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('TokenChannel', onMessageReceived: _onScanResult)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageFinished: (_) => _scan(),
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));

    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _scan());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  void _scan() {
    if (!_validating) _controller.runJavaScript(_scanScript);
  }

  Future<void> _onScanResult(JavaScriptMessage message) async {
    if (_validating) return;

    final List<dynamic> raw = jsonDecode(message.message) as List<dynamic>;
    final candidates = raw
        .whereType<String>()
        .toSet()
        .where((t) => !_tried.contains(t) && ApiClient.isTokenFresh(t));

    for (final token in candidates) {
      _tried.add(token);
      _validating = true;
      final ok = await widget.onTokenFound(token);
      if (ok && mounted) {
        _poller?.cancel();
        Navigator.of(context).pop(true);
        return;
      }
      _validating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masuk ke Mentari'),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progress / 100),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
