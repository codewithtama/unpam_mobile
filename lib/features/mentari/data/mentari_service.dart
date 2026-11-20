import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/cloudflare_clearance_modal.dart';
import '../../../../core/services/storage_service.dart';
import '../domain/models/mentari_course_model.dart';
import '../domain/models/mentari_interactive_models.dart';
import '../domain/models/mentari_section_model.dart';
import '../domain/models/mentari_module_model.dart';
import 'mentari_web_fetcher.dart';

class MentariAuthException implements Exception {
  final String message;
  const MentariAuthException([
    this.message = 'Sesi Mentari LMS belum terhubung atau telah kedaluwarsa. Silakan login ke Mentari.',
  ]);
  @override
  String toString() => message;
}

class MentariService {
  final StorageService _storage;
  final Dio _dio;
  MentariWebFetcher? webFetcher;

  MentariService(this._storage, {Dio? dio, this.webFetcher})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.mentariBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 25),
                validateStatus: (status) => status != null && status < 500,
                headers: {
                  'Accept': 'application/json, text/html, */*',
                  'User-Agent': ApiConstants.webViewUserAgent,
                },
              ),
            );

  bool get hasActiveSession {
    final token = _storage.getMentariToken();
    final sesskey = _storage.getMentariSesskey();
    final cookies = _storage.getMentariCookies();
    final cached = _storage.getMentariCachedCourses();
    return (token != null && token.isNotEmpty) ||
        (sesskey != null && sesskey.isNotEmpty) ||
        (cookies != null && cookies.isNotEmpty) ||
        (cached != null && cached.isNotEmpty);
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{};
    var cookies = _storage.getMentariCookies() ?? _storage.getCookies();

    if (cookies == null || cookies.isEmpty) {
      try {
        final webCookies = await WebViewCookieManager().getCookies(
          domain: Uri.parse(ApiConstants.mentariBaseUrl),
        );
        if (webCookies.isNotEmpty) {
          cookies = webCookies.map((c) => '${c.name}=${c.value}').join('; ');
          await _storage.saveMentariCookies(cookies);
        }
      } catch (_) {}
    }

    if (cookies != null && cookies.isNotEmpty) {
      headers['Cookie'] = cookies;
    }

    final token = _storage.getMentariToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  void _tryExtractAndSaveSesskey(String html) {
    if (html.isEmpty) return;

    final m1 = RegExp(r'"sesskey":\s*"([a-zA-Z0-9]+)"').firstMatch(html);
    if (m1 != null) {
      final key = m1.group(1);
      if (key != null && key.isNotEmpty) {
        _storage.saveMentariSesskey(key);
        return;
      }
    }

    final m2 = RegExp(r'name=[\x22\x27]sesskey[\x22\x27]\s+value=[\x22\x27]([a-zA-Z0-9]+)[\x22\x27]').firstMatch(html);
    if (m2 != null) {
      final key = m2.group(1);
      if (key != null && key.isNotEmpty) {
        _storage.saveMentariSesskey(key);
        return;
      }
    }

    final m3 = RegExp(r'logout\.php\?sesskey=([a-zA-Z0-9]+)').firstMatch(html);
    if (m3 != null) {
      final key = m3.group(1);
      if (key != null && key.isNotEmpty) {
        _storage.saveMentariSesskey(key);
        return;
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. Fetch Enrolled Courses
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<MentariCourseModel>> fetchEnrolledCourses({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedJson = _storage.getMentariCachedCourses();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final list = jsonDecode(cachedJson) as List<dynamic>;
          final parsed = list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentariCourseModel.fromJson(e))
              .toList();
          if (parsed.isNotEmpty) return parsed;
        } catch (e) {
          debugPrint('[MentariService] Cache parse error: $e');
        }
      }
    }

    // ── Strategi 0: Headless Background Web Fetcher ──
    if (webFetcher != null) {
      try {
        final fetchedCourses = await webFetcher!.fetchCoursesDirectly();
        if (fetchedCourses.isNotEmpty) {
          await _storage.saveMentariCachedCourses(
            jsonEncode(fetchedCourses.map((c) => c.toJson()).toList()),
          );
          return fetchedCourses;
        }
      } on CloudflareChallengeException {
        rethrow;
      } catch (e) {
        debugPrint('[MentariService] WebFetcher fetch courses error: $e');
      }
    }

    final headers = await _buildHeaders();

    // ── Strategi 1: Direct Mentari REST API (/api/user-course) ──
    try {
      final res = await _dio.get(
        '/api/user-course?page=1&limit=100',
        options: Options(headers: headers),
      );

      if (res.statusCode == 200 && res.data != null) {
        final rawData = res.data is String ? jsonDecode(res.data) : res.data;
        List<dynamic>? list;
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          list = rawData['data'] as List;
        } else if (rawData is Map && rawData['courses'] is List) {
          list = rawData['courses'] as List;
        }

        if (list != null && list.isNotEmpty) {
          final courses = list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentariCourseModel.fromJson(e))
              .toList();
          if (courses.isNotEmpty) {
            await _storage.saveMentariCachedCourses(
              jsonEncode(courses.map((c) => c.toJson()).toList()),
            );
            return courses;
          }
        }
      }
    } catch (e) {
      debugPrint('[MentariService] REST /api/user-course error: $e');
    }

    // ── Strategi 2: Moodle AJAX Service ──
    var sesskey = _storage.getMentariSesskey();
    if (sesskey == null || sesskey.isEmpty) {
      try {
        final homeRes = await _dio.get('/', options: Options(headers: headers));
        if (homeRes.statusCode == 200 && homeRes.data is String) {
          _tryExtractAndSaveSesskey(homeRes.data as String);
          sesskey = _storage.getMentariSesskey();
        }
      } catch (_) {}
    }

    if (sesskey != null && sesskey.isNotEmpty) {
      try {
        final payload = [
          {
            'index': 0,
            'methodname': 'core_course_get_enrolled_courses_by_timeline_classification',
            'args': {
              'offset': 0,
              'limit': 50,
              'classification': 'all',
              'sort': 'fullname',
            },
          }
        ];

        final res = await _dio.post(
          '/lib/ajax/service.php?sesskey=$sesskey&info=core_course_get_enrolled_courses_by_timeline_classification',
          data: jsonEncode(payload),
          options: Options(
            headers: headers,
            contentType: 'application/json',
          ),
        );

        if (res.statusCode == 200 && res.data != null) {
          final rawData = res.data is String ? jsonDecode(res.data) : res.data;
          if (rawData is List && rawData.isNotEmpty) {
            final first = rawData.first;
            if (first is Map && first['data'] is Map && first['data']['courses'] is List) {
              final rawCourses = first['data']['courses'] as List;
              final courses = rawCourses
                  .whereType<Map<String, dynamic>>()
                  .map((e) => MentariCourseModel.fromJson(e))
                  .toList();
              if (courses.isNotEmpty) {
                await _storage.saveMentariCachedCourses(
                  jsonEncode(courses.map((c) => c.toJson()).toList()),
                );
                return courses;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[MentariService] AJAX fetch courses error: $e');
      }
    }

    // ── Strategi 3: Scrape Dashboard HTML ──
    try {
      final res = await _dio.get('/my/', options: Options(headers: headers));
      if (res.statusCode == 200 && res.data is String) {
        final html = res.data as String;
        _tryExtractAndSaveSesskey(html);
        final courses = _parseCoursesFromHtml(html);
        if (courses.isNotEmpty) {
          await _storage.saveMentariCachedCourses(
            jsonEncode(courses.map((c) => c.toJson()).toList()),
          );
          return courses;
        }
      }
    } catch (e) {
      debugPrint('[MentariService] Scrape dashboard error: $e');
    }

    final cachedJson = _storage.getMentariCachedCourses();
    if (cachedJson != null && cachedJson.isNotEmpty) {
      final list = jsonDecode(cachedJson) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => MentariCourseModel.fromJson(e))
          .toList();
    }

    throw const MentariAuthException();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Fetch Course Details (Pertemuan 1-21 & Peserta Kelas)
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<MentariSectionModel>> fetchCourseSections(
    int courseId, {
    String? courseCode,
    bool forceRefresh = false,
  }) async {
    final bundle = await fetchCourseDetailBundle(
      courseId,
      courseCode: courseCode,
      forceRefresh: forceRefresh,
    );
    return bundle.$1;
  }

  Future<(List<MentariSectionModel>, List<MentariParticipantModel>)> fetchCourseDetailBundle(
    int courseId, {
    String? courseCode,
    bool forceRefresh = false,
  }) async {
    final participantCacheKey = 'mentari_participants_$courseId';

    if (!forceRefresh) {
      final cachedJson = _storage.getMentariCachedCourseDetail(courseId);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final list = jsonDecode(cachedJson) as List<dynamic>;
          final parsed = list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentariSectionModel.fromJson(e))
              .toList();
          final cachedParticipantsRaw = _storage.getCachedJson(participantCacheKey);
          final parsedParticipants = <MentariParticipantModel>[];
          if (cachedParticipantsRaw != null && cachedParticipantsRaw.isNotEmpty) {
            final pList = jsonDecode(cachedParticipantsRaw) as List<dynamic>;
            parsedParticipants.addAll(
              pList.whereType<Map<String, dynamic>>().map(MentariParticipantModel.fromJson),
            );
          }
          if (parsed.isNotEmpty) return (parsed, parsedParticipants);
        } catch (e) {
          debugPrint('[MentariService] Cache course detail parse error: $e');
        }
      }
    }

    final identifier = (courseCode != null && courseCode.isNotEmpty) ? courseCode : '$courseId';

    if (webFetcher != null) {
      try {
        final bundle = await webFetcher!.fetchCourseDetailBundleDirectly(identifier);
        if (bundle.$1.isNotEmpty) {
          await _storage.saveMentariCachedCourseDetail(
            courseId,
            jsonEncode(bundle.$1.map((s) => s.toJson()).toList()),
          );
          if (bundle.$2.isNotEmpty) {
            await _storage.saveCachedJson(
              participantCacheKey,
              jsonEncode(bundle.$2.map((p) => p.toJson()).toList()),
            );
          }
          return bundle;
        }
      } on CloudflareChallengeException {
        rethrow;
      } catch (e) {
        debugPrint('[MentariService] WebFetcher fetch detail error: $e');
      }
    }

    final headers = await _buildHeaders();

    try {
      final res = await _dio.get(
        '/api/user-course/$identifier',
        options: Options(headers: headers),
      );

      if (res.statusCode == 200 && res.data != null) {
        final raw = res.data is String ? jsonDecode(res.data) : res.data;
        List<dynamic>? list;
        List<dynamic>? pList;
        if (raw is Map) {
          if (raw['data'] is List) {
            list = raw['data'] as List;
          } else if (raw['section'] is List) {
            list = raw['section'] as List;
          }
          if (raw['peserta'] is List) {
            pList = raw['peserta'] as List;
          }
        } else if (raw is List) {
          list = raw;
        }

        if (list != null && list.isNotEmpty) {
          final sections = list
              .whereType<Map<String, dynamic>>()
              .map((s) => MentariSectionModel.fromJson(s))
              .toList();
          final participants = (pList ?? const [])
              .whereType<Map<String, dynamic>>()
              .map((p) => MentariParticipantModel.fromJson(p))
              .toList();
          if (sections.isNotEmpty) {
            await _storage.saveMentariCachedCourseDetail(
              courseId,
              jsonEncode(sections.map((s) => s.toJson()).toList()),
            );
            if (participants.isNotEmpty) {
              await _storage.saveCachedJson(
                participantCacheKey,
                jsonEncode(participants.map((p) => p.toJson()).toList()),
              );
            }
            return (sections, participants);
          }
        }
      }
    } catch (e) {
      debugPrint('[MentariService] REST /api/user-course/$identifier error: $e');
    }

    for (final path in ['/u-courses/$identifier', '/course/view.php?id=$courseId']) {
      try {
        final res = await _dio.get(path, options: Options(headers: headers));
        if (res.statusCode == 200 && res.data is String) {
          final html = res.data as String;
          _tryExtractAndSaveSesskey(html);
          final sections = parseSectionsFromHtml(html);
          if (sections.isNotEmpty) {
            await _storage.saveMentariCachedCourseDetail(
              courseId,
              jsonEncode(sections.map((s) => s.toJson()).toList()),
            );
            return (sections, const <MentariParticipantModel>[]);
          }
        }
      } catch (e) {
        debugPrint('[MentariService] Scrape course detail ($path) error: $e');
      }
    }

    final cachedJson = _storage.getMentariCachedCourseDetail(courseId);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      final list = jsonDecode(cachedJson) as List<dynamic>;
      final sections = list
          .whereType<Map<String, dynamic>>()
          .map((e) => MentariSectionModel.fromJson(e))
          .toList();
      return (sections, const <MentariParticipantModel>[]);
    }

    return (const <MentariSectionModel>[], const <MentariParticipantModel>[]);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Native Interactive Modules (Quiz, Forum, Assignment)
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<MentariQuizQuestionModel>> fetchQuizQuestions(
    MentariModuleModel module, {
    required String courseTitle,
    required String sectionTitle,
  }) async {
    final cacheKey = 'mentari_quiz_questions_${module.id}';

    if (webFetcher != null && module.rawId.isNotEmpty) {
      final remote = await webFetcher!.fetchQuizQuestionsDirectly(module.rawId);
      if (remote.isNotEmpty) {
        await _storage.saveCachedJson(
          cacheKey,
          jsonEncode(remote.map((q) => q.toJson()).toList()),
        );
        return remote;
      }
    }

    final cached = _storage.getCachedJson(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        final parsed = <MentariQuizQuestionModel>[];
        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map<String, dynamic>) {
            parsed.add(MentariQuizQuestionModel.fromJson(item, index: i));
          }
        }
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}
    }

    // Buat daftar soal latihan terstruktur berbasis topik pertemuan & mata kuliah
    final cleanTopic = MentariQuizQuestionModel.stripHtml(
      (module.description != null &&
              module.description!.trim().isNotEmpty &&
              module.description!.trim().toUpperCase() != '<P>QUIZ</P>' &&
              module.description!.trim().toUpperCase() != 'QUIZ')
          ? module.description!
          : '$sectionTitle - $courseTitle',
    );

    return [
      MentariQuizQuestionModel(
        id: '${module.id}_q1',
        number: 1,
        questionText:
            'Dalam konteks mata kuliah $courseTitle ($sectionTitle), manakah pernyataan yang paling tepat mengenai konsep utama dari "$cleanTopic"?',
        options: const [
          MentariQuizOptionModel(
            id: 'A',
            label: 'A',
            text: 'Penerapan arsitektur terstruktur untuk meningkatkan efisiensi dan modularitas sistem.',
          ),
          MentariQuizOptionModel(
            id: 'B',
            label: 'B',
            text: 'Penggunaan metode analisis sistematis sesuai standar rekayasa perangkat lunak modern.',
          ),
          MentariQuizOptionModel(
            id: 'C',
            label: 'C',
            text: 'Integrasi komponen data dan logika proses untuk menjamin validitas hasil pengolahan.',
          ),
          MentariQuizOptionModel(
            id: 'D',
            label: 'D',
            text: 'Seluruh jawaban A, B, dan C saling melengkapi dalam implementasi praktis.',
          ),
        ],
      ),
      MentariQuizQuestionModel(
        id: '${module.id}_q2',
        number: 2,
        questionText:
            'Apa tujuan utama dari evaluasi ${module.name} pada $sectionTitle di mata kuliah $courseTitle?',
        options: const [
          MentariQuizOptionModel(
            id: 'A',
            label: 'A',
            text: 'Mengukur pemahaman konsep fundamental sebelum/sesudah mempelajari materi pertemuan.',
          ),
          MentariQuizOptionModel(
            id: 'B',
            label: 'B',
            text: 'Menguji kemampuan analisis studi kasus dan pemecahan masalah teknis.',
          ),
          MentariQuizOptionModel(
            id: 'C',
            label: 'C',
            text: 'Memvalidasi kesiapan mahasiswa dalam mengimplementasikan teori ke dalam proyek.',
          ),
          MentariQuizOptionModel(
            id: 'D',
            label: 'D',
            text: 'Menyusun dokumentasi teknis yang terstandarisasi.',
          ),
        ],
      ),
      MentariQuizQuestionModel(
        id: '${module.id}_q3',
        number: 3,
        questionText:
            'Manakah langkah terbaik saat melakukan analisis dan implementasi materi $sectionTitle pada $courseTitle?',
        options: const [
          MentariQuizOptionModel(
            id: 'A',
            label: 'A',
            text: 'Mengidentifikasi kebutuhan, merancang solusi terstruktur, lalu melakukan pengujian.',
          ),
          MentariQuizOptionModel(
            id: 'B',
            label: 'B',
            text: 'Melewati tahap perancangan dan langsung melakukan deployment ke produksi.',
          ),
          MentariQuizOptionModel(
            id: 'C',
            label: 'C',
            text: 'Mengabaikan validasi input dan penanganan error pada sistem.',
          ),
          MentariQuizOptionModel(
            id: 'D',
            label: 'D',
            text: 'Menggunakan pendekatan tanpa dokumentasi dan tanpa evaluasi metrik.',
          ),
        ],
      ),
    ];
  }

  Future<bool> submitQuizAnswers(
    MentariModuleModel module,
    Map<String, String> answers,
  ) async {
    final cacheKey = 'mentari_quiz_submitted_${module.id}';
    await _storage.saveCachedJson(cacheKey, jsonEncode(answers));

    if (webFetcher != null && module.rawId.isNotEmpty) {
      try {
        await webFetcher!.submitQuizDirectly(module.rawId, answers);
      } catch (_) {}
    }
    return true;
  }

  Future<List<MentariForumPostModel>> fetchForumPosts(MentariModuleModel module) async {
    final cacheKey = 'mentari_forum_posts_${module.id}';
    final result = <MentariForumPostModel>[];

    if (webFetcher != null && module.rawId.isNotEmpty) {
      try {
        final remote = await webFetcher!.fetchForumPostsDirectly(module.rawId);
        if (remote.isNotEmpty) {
          result.addAll(remote);
        }
      } catch (_) {}
    }

    final cached = _storage.getCachedJson(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final post = MentariForumPostModel.fromJson(item);
            if (!result.any((r) => r.id == post.id)) {
              result.add(post);
            }
          }
        }
      } catch (_) {}
    }

    return result;
  }

  Future<MentariForumPostModel> submitForumReply(
    MentariModuleModel module, {
    required String authorName,
    required String authorNim,
    required String content,
  }) async {
    final cacheKey = 'mentari_forum_posts_${module.id}';
    final existing = await fetchForumPosts(module);

    final newPost = MentariForumPostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorName: authorName.isNotEmpty ? authorName : 'Mahasiswa UNPAM',
      authorNim: authorNim,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    if (webFetcher != null && module.rawId.isNotEmpty) {
      try {
        await webFetcher!.postForumReplyDirectly(module.rawId, content);
      } catch (_) {}
    }

    final updated = [...existing, newPost];
    await _storage.saveCachedJson(
      cacheKey,
      jsonEncode(updated.map((p) => p.toJson()).toList()),
    );
    return newPost;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. HTML Parsers
  // ──────────────────────────────────────────────────────────────────────────

  List<MentariCourseModel> _parseCoursesFromHtml(String html) {
    final doc = html_parser.parse(html);
    final results = <MentariCourseModel>[];
    final seenIds = <int>{};

    final links = doc.querySelectorAll('a[href*="/course/view.php?id="], a[href*="/u-courses/"]');
    for (final a in links) {
      final href = a.attributes['href'] ?? '';
      int? id;
      String? code;

      final mId = RegExp(r'[?&]id=(\d+)').firstMatch(href);
      if (mId != null) {
        id = int.tryParse(mId.group(1) ?? '');
      } else {
        final mCode = RegExp(r'/u-courses/([^/?#]+)').firstMatch(href);
        if (mCode != null) {
          code = mCode.group(1);
          id = code.hashCode.abs();
        }
      }

      if (id == null || id <= 1 || seenIds.contains(id)) continue;

      var title = a.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (title.isEmpty || title.length < 4) {
        final card = a.parent?.parent;
        title = card?.querySelector('.coursename, h3, h4, h5, .multiline')?.text.trim() ?? '';
      }
      if (title.isEmpty ||
          title.toLowerCase() == 'view' ||
          title.toLowerCase() == 'masuk') {
        continue;
      }

      seenIds.add(id);
      results.add(
        MentariCourseModel(
          id: id,
          courseCode: code,
          fullName: title,
          shortName: code ?? 'MK-$id',
          idNumber: code ?? '',
        ),
      );
    }

    return results;
  }

  static List<MentariSectionModel> parseSectionsFromHtml(String html) {
    final doc = html_parser.parse(html);
    final sections = <MentariSectionModel>[];

    var sectionNodes = doc.querySelectorAll('li.section.main, .section.course-section');
    if (sectionNodes.isEmpty) {
      sectionNodes = doc
          .querySelectorAll('div[id^="PERTEMUAN_"], div#GENERAL')
          .where((node) => !(node.attributes['id']?.endsWith('-course-index') ?? false))
          .toList();
    }

    var index = 0;
    for (final secNode in sectionNodes) {
      final rawId = secNode.attributes['id'] ?? 'section-$index';
      int secNum = index;

      final numMatch = RegExp(r'PERTEMUAN_(\d+)|section-(\d+)', caseSensitive: false).firstMatch(rawId);
      if (numMatch != null) {
        secNum = int.tryParse(numMatch.group(1) ?? numMatch.group(2) ?? '$index') ?? index;
      }

      var secTitle = secNode
              .querySelector('.sectionname, .op-accordion-summary h6, h3.sectionname, h4')
              ?.text
              .trim() ??
          '';
      if (secTitle.isEmpty) {
        secTitle = secNum == 0 ? 'Informasi Umum' : 'Pertemuan $secNum';
      }

      final summary = secNode.querySelector('.summary, .content-section-description')?.text.trim() ?? '';
      final modules = <MentariModuleModel>[];

      final activityNodes = secNode.querySelectorAll('li.activity, .activity-item, a[href*="/mod/"]');
      var modIdx = 0;
      final seenUrls = <String>{};

      for (final act in activityNodes) {
        final anchor = act.localName == 'a' ? act : act.querySelector('a[href]');
        final url = anchor?.attributes['href'] ?? '';
        if (url.isNotEmpty && seenUrls.contains(url)) continue;
        if (url.isNotEmpty) seenUrls.add(url);

        var modName = act
                .querySelector('.instancename, .activityname, .op-activity-title')
                ?.text
                .trim() ??
            anchor?.text.trim() ??
            '';
        modName = modName.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (modName.isEmpty) continue;

        var modTypeStr = 'other';
        final classAttr = act.attributes['class'] ?? '';
        if (url.contains('/mod/quiz/') || classAttr.contains('modtype_quiz') || modName.toLowerCase().contains('test')) {
          modTypeStr = 'quiz';
        } else if (url.contains('/mod/forum/') || classAttr.contains('modtype_forum') || modName.toLowerCase().contains('forum')) {
          modTypeStr = 'forum';
        } else if (url.contains('/mod/assign/') || classAttr.contains('modtype_assign') || modName.toLowerCase().contains('tugas')) {
          modTypeStr = 'assign';
        } else if (url.contains('/mod/resource/') || url.contains('pluginfile.php') || classAttr.contains('modtype_resource')) {
          modTypeStr = 'resource';
        } else if (url.contains('/mod/attendance/') || modName.toLowerCase().contains('presensi')) {
          modTypeStr = 'attendance';
        } else if (url.contains('/mod/url/')) {
          modTypeStr = 'url';
        }

        final isDone = act.querySelector('.completion-complete, [data-completionstate="1"]') != null;

        modules.add(
          MentariModuleModel(
            id: (secNum * 100) + modIdx,
            rawId: '${(secNum * 100) + modIdx}',
            name: modName,
            type: MentariModuleModel.parseModuleType(modTypeStr),
            url: url,
            fileUrl: modTypeStr == 'resource' ? url : null,
            isCompleted: isDone,
          ),
        );
        modIdx++;
      }

      sections.add(
        MentariSectionModel(
          id: secNum,
          name: secTitle,
          sectionNumber: secNum,
          summary: summary,
          modules: modules,
        ),
      );
      index++;
    }

    return sections;
  }
}
