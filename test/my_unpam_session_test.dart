import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unpam_mobile/core/services/my_unpam_session.dart';
import 'package:unpam_mobile/core/services/storage_service.dart';

class _FakeAdapter implements HttpClientAdapter {
  final List<(int, String)> responses;
  final List<String?> authHeaders = [];

  _FakeAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authHeaders.add(options.headers['Authorization'] as String?);
    final (status, body) = responses.removeAt(0);
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [
        body.startsWith('<') ? 'text/html' : Headers.jsonContentType,
      ],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.getInstance();
    await storage.resetAll();
  });

  MyUnpamSession buildSession(_FakeAdapter adapter) {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://my.unpam.ac.id',
      validateStatus: (s) => s != null && s < 500,
    ))
      ..httpClientAdapter = adapter;
    return MyUnpamSession(storage, dio: dio);
  }

  test('returns decoded data with a valid token', () async {
    await storage.saveMyUnpamToken('valid-token-abcdefghijklmnop');
    final adapter = _FakeAdapter([(200, jsonEncode({'ok': true}))]);
    final session = buildSession(adapter);

    final data = await session.get('/api/biodata/mahasiswa');

    expect(data, {'ok': true});
    expect(session.status, PortalSessionStatus.active);
    expect(adapter.authHeaders.single, 'Bearer valid-token-abcdefghijklmnop');
  });

  test('refreshes the session on 401 and retries with the new token', () async {
    await storage.saveMyUnpamToken('expired-token-abcdefghijklmnop');
    final adapter = _FakeAdapter([(401, '{}'), (200, '[1,2]')]);
    final session = buildSession(adapter);
    var refreshCalls = 0;
    session.refresher = () async {
      refreshCalls++;
      await storage.saveMyUnpamToken('fresh-token-abcdefghijklmnop');
      return RefreshOutcome.refreshed;
    };

    final data = await session.get('/api/semester');

    expect(data, [1, 2]);
    expect(refreshCalls, 1);
    expect(adapter.authHeaders.last, 'Bearer fresh-token-abcdefghijklmnop');
  });

  test('Cloudflare 403 with both sessions dead requires login and clears tokens', () async {
    await storage.saveMyUnpamToken('expired-token-abcdefghijklmnop');
    await storage.saveSatuUnpamToken('satu-token-abcdefghijklmnopqr');
    final adapter = _FakeAdapter([
      (403, '<html><title>Just a moment...</title>challenges.cloudflare.com</html>'),
    ]);
    final session = buildSession(adapter)
      ..refresher = () async => RefreshOutcome.loginRequired;

    await expectLater(session.get('/api/keuangan'), throwsA(isA<SessionExpiredException>()));
    expect(session.needsLogin, isTrue);
    expect(storage.getMyUnpamToken(), isNull);
    expect(storage.getSatuUnpamToken(), isNull);
  });

  test('concurrent auth failures trigger a single refresh', () async {
    await storage.saveMyUnpamToken('expired-token-abcdefghijklmnop');
    final adapter = _FakeAdapter([(401, '{}'), (401, '{}'), (200, '{}'), (200, '{}')]);
    final session = buildSession(adapter);
    var refreshCalls = 0;
    session.refresher = () async {
      refreshCalls++;
      await Future.delayed(const Duration(milliseconds: 20));
      return RefreshOutcome.refreshed;
    };

    await Future.wait([session.get('/a'), session.get('/b')]);

    expect(refreshCalls, 1);
  });

  test('never-connected account fails fast without running the refresher', () async {
    final session = buildSession(_FakeAdapter([]));
    var refreshCalls = 0;
    session.refresher = () async {
      refreshCalls++;
      return RefreshOutcome.refreshed;
    };

    await expectLater(session.get('/api/semester'), throwsA(isA<SessionExpiredException>()));
    expect(refreshCalls, 0);
  });

  test('captureToken stores Satu UNPAM and My UNPAM tokens separately', () async {
    final session = buildSession(_FakeAdapter([]));

    await session.captureToken(jsonEncode({'host': 'satu.unpam.ac.id', 'token': 'Bearer satu-abcdefghijklmnopqrstu'}));
    await session.captureToken(jsonEncode({'host': 'my.unpam.ac.id', 'token': 'my-abcdefghijklmnopqrstuvw'}));
    await session.captureToken(jsonEncode({'host': 'mentari.unpam.ac.id', 'token': 'mentari-abcdefghijklmnopqr'}));

    expect(storage.getSatuUnpamToken(), 'satu-abcdefghijklmnopqrstu');
    expect(storage.getMyUnpamToken(), 'my-abcdefghijklmnopqrstuvw');
  });

  String jwtWithExp(int? exp) {
    String part(Map<String, dynamic> map) =>
        base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
    return '${part({'alg': 'HS256'})}.${part({'id_user': 1, if (exp != null) 'exp': exp})}.sig';
  }

  test('isTokenFresh honours the JWT exp claim', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000);
    expect(MyUnpamSession.isTokenFresh(jwtWithExp(1700003600), now: now), isTrue);
    expect(MyUnpamSession.isTokenFresh(jwtWithExp(1699990000), now: now), isFalse);
    expect(MyUnpamSession.isTokenFresh(jwtWithExp(null), now: now), isTrue);
    expect(MyUnpamSession.isTokenFresh('not-a-jwt', now: now), isTrue);
  });

  test('captureToken ignores expired My UNPAM tokens', () async {
    final session = buildSession(_FakeAdapter([]));
    final expired = jwtWithExp(1000);

    final host = await session.captureToken(jsonEncode({'host': 'my.unpam.ac.id', 'token': expired}));

    expect(host, isNull);
    expect(storage.getMyUnpamToken(), isNull);
  });

  test('remembered credentials live in memory only and clear on sign out', () async {
    final session = buildSession(_FakeAdapter([]));

    session.rememberCredentials(' 241011000001 ', 'secret');

    expect(session.rememberedCredentials, ('241011000001', 'secret'));
    expect(storage.rawPreferences.getKeys().any((k) => storage.rawPreferences.get(k) == 'secret'), isFalse);

    await session.signOut();
    expect(session.rememberedCredentials, isNull);
  });

  test('signOut clears both sessions and notifies listeners', () async {
    await storage.saveMyUnpamToken('my-token-abcdefghijklmnopqrstu');
    await storage.saveSatuUnpamToken('satu-token-abcdefghijklmnopqr');
    final session = buildSession(_FakeAdapter([]));
    var notified = 0;
    session.addSignOutListener(() => notified++);

    await session.signOut();

    expect(notified, 1);
    expect(storage.getMyUnpamToken(), isNull);
    expect(storage.getSatuUnpamToken(), isNull);
    expect(session.needsLogin, isTrue);
  });
}
