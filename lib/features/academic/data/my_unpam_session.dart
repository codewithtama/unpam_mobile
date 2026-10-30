import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';

enum PortalSessionStatus { unknown, active, refreshing, expired }

enum RefreshOutcome { refreshed, loginRequired, failed }

typedef SessionRefresher = Future<RefreshOutcome> Function();

typedef PortalFetcher = Future<Response<dynamic>> Function(
  String path,
  Map<String, dynamic>? query,
  String? token,
);

class SessionExpiredException implements Exception {
  final String message;

  const SessionExpiredException([
    this.message = 'Sesi Satu UNPAM & My UNPAM telah berakhir. Silakan hubungkan ulang akun Anda.',
  ]);

  @override
  String toString() => message;
}

class PortalRequestException implements Exception {
  final String message;

  const PortalRequestException(this.message);

  @override
  String toString() => message;
}

class MyUnpamSession extends ChangeNotifier {
  final StorageService _storage;
  final Dio _dio;
  SessionRefresher? refresher;
  PortalFetcher? fetcher;
  Completer<RefreshOutcome>? _pendingRefresh;
  PortalSessionStatus _status = PortalSessionStatus.unknown;
  (String, String)? _credentials;
  final List<VoidCallback> _signOutListeners = [];

  MyUnpamSession(this._storage, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConstants.myUnpamBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 25),
              validateStatus: (status) => status != null && status < 500,
              headers: {
                'Accept': 'application/json, text/plain, */*',
                'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
                'User-Agent': 'PostmanRuntime/7.43.0',
              },
            ));

  StorageService get storage => _storage;
  PortalSessionStatus get status => _status;
  bool get hasToken => _storage.hasMyUnpamToken;
  bool get needsLogin => _status == PortalSessionStatus.expired;
  bool get _hasAnySavedSession =>
      _storage.getSatuUnpamToken() != null ||
      _storage.getSatuUnpamCookies() != null ||
      _storage.getMyUnpamCookies() != null;
  bool get isRefreshing => _status == PortalSessionStatus.refreshing;

  void _setStatus(PortalSessionStatus next) {
    if (_status == next) return;
    _status = next;
    notifyListeners();
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final stored = _storage.getMyUnpamToken();
    if (fetcher == null && (stored == null || !isTokenFresh(stored))) {
      if (stored == null && !_hasAnySavedSession) {
        _setStatus(PortalSessionStatus.expired);
        throw const SessionExpiredException(
            'Akun Satu UNPAM belum terhubung. Silakan hubungkan akun Anda.');
      }
      final outcome = await refreshSession();
      if (outcome != RefreshOutcome.refreshed) throw _exceptionFor(outcome);
    }

    var response = await _send(path, query);
    if (_isAuthFailure(response)) {
      final outcome = await refreshSession();
      if (outcome != RefreshOutcome.refreshed) throw _exceptionFor(outcome);
      response = await _send(path, query);
      if (_isAuthFailure(response)) {
        _setStatus(PortalSessionStatus.expired);
        throw const SessionExpiredException();
      }
    }

    if (response.statusCode == 200 && response.data != null) {
      _setStatus(PortalSessionStatus.active);
      return _decode(response.data);
    }
    throw PortalRequestException(_errorMessage(response));
  }

  Future<bool> validate() async {
    try {
      final response = await _send('/api/biodata/mahasiswa', null);
      final ok = response.statusCode == 200 && !_isAuthFailure(response);
      if (ok) _setStatus(PortalSessionStatus.active);
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<RefreshOutcome> refreshSession() {
    final pending = _pendingRefresh;
    if (pending != null) return pending.future;

    final completer = Completer<RefreshOutcome>();
    _pendingRefresh = completer;
    _setStatus(PortalSessionStatus.refreshing);

    () async {
      var outcome = RefreshOutcome.loginRequired;
      try {
        final run = refresher;
        if (run != null) outcome = await run();
      } catch (e) {
        debugPrint('[MyUnpamSession] refresh error: $e');
        outcome = RefreshOutcome.failed;
      }
      if (outcome == RefreshOutcome.loginRequired) {
        await _storage.clearPortalSessions();
      }
      _setStatus(switch (outcome) {
        RefreshOutcome.refreshed => PortalSessionStatus.active,
        RefreshOutcome.loginRequired => PortalSessionStatus.expired,
        RefreshOutcome.failed =>
          hasToken ? PortalSessionStatus.unknown : PortalSessionStatus.expired,
      });
      _pendingRefresh = null;
      completer.complete(outcome);
    }();

    return completer.future;
  }

  Future<String?> captureToken(String channelMessage) async {
    try {
      final payload = jsonDecode(channelMessage) as Map<String, dynamic>;
      final host = (payload['host'] ?? '').toString().toLowerCase();
      final token = (payload['token'] ?? '')
          .toString()
          .trim()
          .replaceAll(RegExp(r'^Bearer\s+', caseSensitive: false), '')
          .replaceAll('"', '');
      if (token.length < 20 || !isTokenFresh(token)) return null;

      if (host.contains('my.unpam.ac.id')) {
        if (_storage.getMyUnpamToken() != token) {
          await _storage.saveMyUnpamToken(token);
        }
      } else if (host.contains('satu.unpam.ac.id')) {
        if (_storage.getSatuUnpamToken() != token) {
          await _storage.saveSatuUnpamToken(token);
        }
      } else {
        return null;
      }
      return host;
    } catch (_) {
      return null;
    }
  }

  Future<void> syncCookies() async {
    final myCookies = await _readWebViewCookies(ApiConstants.myUnpamBaseUrl);
    if (myCookies != null) await _storage.saveMyUnpamCookies(myCookies);
    final satuCookies = await _readWebViewCookies(ApiConstants.satuUnpamBaseUrl);
    if (satuCookies != null) await _storage.saveSatuUnpamCookies(satuCookies);
  }

  void markConnected() => _setStatus(PortalSessionStatus.active);

  (String, String)? get rememberedCredentials => _credentials;

  void rememberCredentials(String nim, String password) {
    if (nim.trim().isEmpty || password.isEmpty) return;
    _credentials = (nim.trim(), password);
  }

  static bool isTokenFresh(String token, {DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is! num) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return expiry.isAfter(now ?? DateTime.now());
    } catch (_) {
      return true;
    }
  }

  void addSignOutListener(VoidCallback listener) => _signOutListeners.add(listener);

  Future<void> signOut() async {
    _credentials = null;
    await _storage.clearPortalSessions();
    for (final listener in List.of(_signOutListeners)) {
      listener();
    }
    _setStatus(PortalSessionStatus.expired);
  }

  Future<Response<dynamic>> _send(String path, Map<String, dynamic>? query) async {
    final token = _storage.getMyUnpamToken();
    final webFetch = fetcher;
    if (webFetch != null) {
      try {
        return await webFetch(path, query, token);
      } on PortalRequestException catch (e) {
        debugPrint('[MyUnpamSession] web fetch failed, falling back to Dio: $e');
      }
    }

    final headers = <String, dynamic>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final cookies =
        await _readWebViewCookies(ApiConstants.myUnpamBaseUrl) ?? _storage.getMyUnpamCookies();
    if (cookies != null) headers['Cookie'] = cookies;

    try {
      return await _dio.get(
        path,
        queryParameters: query,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw PortalRequestException(_networkMessage(e));
    }
  }

  Future<String?> _readWebViewCookies(String baseUrl) async {
    try {
      final cookies = await WebViewCookieManager().getCookies(domain: Uri.parse(baseUrl));
      if (cookies.isEmpty) return null;
      return cookies.map((c) => '${c.name}=${c.value}').join('; ');
    } catch (_) {
      return null;
    }
  }

  bool _isAuthFailure(Response<dynamic> response) {
    final code = response.statusCode;
    if (code == 401 || code == 403 || code == 419) return true;
    final body = response.data;
    if (body is String) {
      final lower = body.toLowerCase();
      return lower.contains('challenges.cloudflare.com') ||
          lower.contains('<title>just a moment') ||
          lower.contains('satu.unpam.ac.id') ||
          lower.contains('<!doctype html') ||
          lower.contains('<html');
    }
    return false;
  }

  dynamic _decode(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.startsWith('<html') ||
          trimmed.startsWith('<!DOCTYPE') ||
          trimmed.startsWith('<!doctype')) {
        throw const SessionExpiredException(
            'Sesi berakhir atau server mengembalikan halaman web. Silakan hubungkan akun.');
      }
      try {
        return jsonDecode(data);
      } catch (_) {
        throw const PortalRequestException('Format data dari server tidak valid.');
      }
    }
    return data;
  }

  String _errorMessage(Response<dynamic> response) {
    final data = response.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return 'Gagal memuat data dari server (HTTP ${response.statusCode}).';
  }

  String _networkMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Koneksi ke My UNPAM terlalu lama. Periksa jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke My UNPAM. Periksa koneksi internet Anda.';
      default:
        return 'Terjadi kesalahan jaringan saat menghubungi My UNPAM.';
    }
  }

  Exception _exceptionFor(RefreshOutcome outcome) {
    if (outcome == RefreshOutcome.failed) {
      return const PortalRequestException(
        'Gagal menyegarkan sesi My UNPAM. Periksa koneksi lalu coba lagi.',
      );
    }
    return const SessionExpiredException();
  }
}
