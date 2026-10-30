import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/mentari_scripts.dart';
import '../../../../core/services/storage_service.dart';
import '../domain/models/mentari_course_model.dart';
import '../domain/models/mentari_section_model.dart';
import 'mentari_service.dart';

class MentariWebFetcher {
  static const String channelName = MentariScripts.fetchChannel;
  static const Duration _pageTimeout = Duration(seconds: 25);
  static const Duration _requestTimeout = Duration(seconds: 25);

  final StorageService _storage;
  final ValueNotifier<WebViewController?> controller = ValueNotifier(null);
  final Map<String, Completer<Response<dynamic>>> _pending = {};
  Completer<void>? _pageReady;
  int _sequence = 0;

  MentariWebFetcher(this._storage);

  Future<Response<dynamic>> get(
    String path,
    Map<String, dynamic>? query, {
    String? token,
  }) async {
    final parsed = Uri.parse(path);
    final queryParams = <String, String>{
      ...parsed.queryParameters,
      if (query != null) ...query.map((k, v) => MapEntry(k, '$v')),
    };
    final uri = Uri(
      path: parsed.path,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final response = await _fetch(uri.toString(), token ?? _storage.getMentariToken());
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
    var stored = localStorage.getItem('access_token') || localStorage.getItem('token') || '';
    stored = stored.replace(/^__q_strn\\|/, '').replace(/^Bearer\\s+/i, '').replace(/["']/g, '');
    var auth = (stored.length > 20) ? stored : token;
    var headers = { 'Accept': 'application/json, text/plain, */*' };
    if (auth && auth.length > 20) {
      headers['Authorization'] = 'Bearer ' + auth;
    }
    var res = await fetch(url, { headers: headers, credentials: 'include' });
    var text = await res.text();
    send({ id: id, status: res.status, body: text, token: auth || '' });
  } catch (e) {
    send({ id: id, status: 0, error: String(e) });
  }
})(${jsonEncode(id)}, ${jsonEncode(url)}, ${jsonEncode(token ?? '')});
''');
    } catch (e) {
      _pending.remove(id);
      throw MentariAuthException('Gagal menjalankan permintaan Mentari LMS: $e');
    }

    return completer.future.timeout(_requestTimeout, onTimeout: () {
      _pending.remove(id);
      throw const MentariAuthException('Koneksi ke Mentari LMS terlalu lama. Silakan periksa jaringan.');
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
        const MentariAuthException('Tidak dapat terhubung ke Mentari LMS. Periksa koneksi internet.'),
      );
      return;
    }

    final token = (payload['token'] ?? '').toString().trim();
    if (status == 200 && token.length > 20) {
      _storage.saveMentariToken(token);
    }

    final body = (payload['body'] ?? '').toString();
    dynamic data = body;
    try {
      data = jsonDecode(body);
    } catch (_) {}

    completer.complete(Response(
      requestOptions: RequestOptions(path: ApiConstants.mentariBaseUrl),
      statusCode: status,
      data: data,
    ));
  }

  Future<void> _onTokenReceived(String raw) async {
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final token = (payload['token'] ?? '').toString().trim();
      if (token.length > 20) {
        await _storage.saveMentariToken(token);
      }
    } catch (_) {}
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
      ..addJavaScriptChannel(MentariScripts.tokenChannel, onMessageReceived: (m) => _onTokenReceived(m.message))
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: _onPageFinished))
      ..loadRequest(Uri.parse('${ApiConstants.mentariBaseUrl}/'));

    return completer.future.timeout(_pageTimeout, onTimeout: () {
      _pageReady = null;
      controller.value = null;
      throw const MentariAuthException('Halaman Mentari LMS tidak dapat dimuat.');
    });
  }

  Future<void> _onPageFinished(String url) async {
    if (!url.toLowerCase().contains('mentari.unpam.ac.id')) return;
    try {
      await controller.value?.runJavaScript(MentariScripts.tokenSniffer);
    } catch (_) {}
    final ready = _pageReady;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  Future<List<MentariCourseModel>> fetchCoursesDirectly() async {
    try {
      final res = await get('/api/user-course?page=1&limit=100', null);
      if (res.statusCode == 200 && res.data != null) {
        final raw = res.data;
        List<dynamic>? list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['data'] is List) {
          list = raw['data'] as List;
        } else if (raw is Map && raw['courses'] is List) {
          list = raw['courses'] as List;
        } else if (raw is Map && raw['results'] is List) {
          list = raw['results'] as List;
        }

        if (list != null && list.isNotEmpty) {
          final courses = list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentariCourseModel.fromJson(e))
              .toList();
          if (courses.isNotEmpty) return courses;
        }
      }
    } catch (e) {
      debugPrint('[MentariWebFetcher] API user-course error: $e');
    }

    // Fallback: ekstraksi dari DOM yang sedang dirender di background WebView
    try {
      final webView = controller.value;
      if (webView != null) {
        final rawResult = await webView.runJavaScriptReturningResult(MentariScripts.scrapeCoursesFromDom);
        var str = rawResult.toString();
        if (str.startsWith('"') && str.endsWith('"')) {
          str = jsonDecode(str);
        }
        final list = jsonDecode(str);
        if (list is List && list.isNotEmpty) {
          final courses = list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentariCourseModel.fromJson(e))
              .toList();
          if (courses.isNotEmpty) return courses;
        }
      }
    } catch (e) {
      debugPrint('[MentariWebFetcher] DOM scrape fallback error: $e');
    }

    return const [];
  }

  Future<List<MentariSectionModel>> fetchCourseSectionsDirectly(String courseCodeOrId) async {
    try {
      final res = await get('/api/user-course/$courseCodeOrId', null);
      if (res.statusCode == 200 && res.data != null) {
        final raw = res.data;
        List<dynamic>? list;
        if (raw is Map && raw['data'] is List) {
          list = raw['data'] as List;
        } else if (raw is List) {
          list = raw;
        }

        if (list != null && list.isNotEmpty) {
          final sections = list
              .whereType<Map<String, dynamic>>()
              .map((s) => MentariSectionModel.fromJson(s))
              .toList();
          if (sections.isNotEmpty) return sections;
        }
      }
    } catch (e) {
      debugPrint('[MentariWebFetcher] API fetch detail error: $e');
    }
    return const [];
  }

  void reset() {
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(const MentariAuthException('Sesi Mentari direset.'));
      }
    }
    _pending.clear();
    _pageReady = null;
    controller.value = null;
  }
}
