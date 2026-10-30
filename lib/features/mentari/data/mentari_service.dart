import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../domain/models/mentari_course_model.dart';
import '../domain/models/mentari_section_model.dart';
import '../domain/models/mentari_module_model.dart';

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

  MentariService(this._storage, {Dio? dio})
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
    final sesskey = _storage.getMentariSesskey();
    final cookies = _storage.getMentariCookies() ?? _storage.getCookies();
    return (sesskey != null && sesskey.isNotEmpty) || (cookies != null && cookies.isNotEmpty);
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
    return headers;
  }

  void _tryExtractAndSaveSesskey(String html) {
    if (html.isEmpty) return;

    // 1. window.M.cfg.sesskey atau "sesskey":"..."
    final m1 = RegExp(r'"sesskey":\s*"([a-zA-Z0-9]+)"').firstMatch(html);
    if (m1 != null) {
      final key = m1.group(1);
      if (key != null && key.isNotEmpty) {
        _storage.saveMentariSesskey(key);
        return;
      }
    }

    // 2. input[name="sesskey"] value="..."
    final m2 = RegExp(r'name=[\x22\x27]sesskey[\x22\x27]\s+value=[\x22\x27]([a-zA-Z0-9]+)[\x22\x27]').firstMatch(html);
    if (m2 != null) {
      final key = m2.group(1);
      if (key != null && key.isNotEmpty) {
        _storage.saveMentariSesskey(key);
        return;
      }
    }

    // 3. logout.php?sesskey=...
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

    final headers = await _buildHeaders();
    var sesskey = _storage.getMentariSesskey();

    // Jika sesskey belum ada namun cookies ada, preflight ke /my/ untuk tangkap sesskey
    if ((sesskey == null || sesskey.isEmpty) && headers.containsKey('Cookie')) {
      try {
        final preflight = await _dio.get(
          '/my/',
          options: Options(headers: headers),
        );
        if (preflight.statusCode == 200 && preflight.data is String) {
          final html = preflight.data as String;
          _tryExtractAndSaveSesskey(html);
          sesskey = _storage.getMentariSesskey();
          final parsed = _parseCoursesFromHtml(html);
          if (parsed.isNotEmpty) {
            await _storage.saveMentariCachedCourses(jsonEncode(parsed));
            return parsed;
          }
        }
      } catch (e) {
        debugPrint('[MentariService] Preflight /my/ error: $e');
      }
    }

    // ── Strategi 1: Moodle AJAX Web Service ──
    if (sesskey != null && sesskey.isNotEmpty) {
      try {
        final ajaxUrl = '/lib/ajax/service.php?sesskey=${Uri.encodeComponent(sesskey)}&info=core_course_get_enrolled_courses_by_timeline_classification';
        final payload = [
          {
            'index': 0,
            'methodname': 'core_course_get_enrolled_courses_by_timeline_classification',
            'args': {
              'classification': 'all',
              'limit': 0,
              'offset': 0,
              'sort': 'fullname asc',
            },
          }
        ];

        final res = await _dio.post(
          ajaxUrl,
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
                await _storage.saveMentariCachedCourses(jsonEncode(courses));
                return courses;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[MentariService] AJAX fetch courses error: $e');
      }
    }

    // ── Strategi 2: Scrape Dashboard HTML ──
    try {
      final res = await _dio.get(
        '/my/',
        options: Options(headers: headers),
      );

      if (res.statusCode == 200 && res.data is String) {
        final html = res.data as String;
        _tryExtractAndSaveSesskey(html);
        final courses = _parseCoursesFromHtml(html);
        if (courses.isNotEmpty) {
          await _storage.saveMentariCachedCourses(jsonEncode(courses));
          return courses;
        }
      }
    } catch (e) {
      debugPrint('[MentariService] Scrape dashboard error: $e');
    }

    // Fallback: jika offline dan ada cache
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
  // 2. Fetch Course Details (Pertemuan 1-21 & Modul)
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<MentariSectionModel>> fetchCourseSections(int courseId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedJson = _storage.getMentariCachedCourseDetail(courseId);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final list = jsonDecode(cachedJson) as List<dynamic>;
          final parsed = list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentariSectionModel.fromJson(e))
              .toList();
          if (parsed.isNotEmpty) return parsed;
        } catch (e) {
          debugPrint('[MentariService] Cache course detail parse error: $e');
        }
      }
    }

    final headers = await _buildHeaders();
    final sesskey = _storage.getMentariSesskey();

    // ── Strategi 1: Moodle AJAX Web Service ──
    if (sesskey != null && sesskey.isNotEmpty) {
      try {
        final ajaxUrl = '/lib/ajax/service.php?sesskey=${Uri.encodeComponent(sesskey)}&info=core_course_get_contents';
        final payload = [
          {
            'index': 0,
            'methodname': 'core_course_get_contents',
            'args': {'courseid': courseId},
          }
        ];

        final res = await _dio.post(
          ajaxUrl,
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
            dynamic sectionsList;
            if (first is Map && first['data'] is List) {
              sectionsList = first['data'];
            } else if (first is Map && first.containsKey('modules')) {
              sectionsList = rawData;
            }

            if (sectionsList is List) {
              final sections = sectionsList
                  .whereType<Map<String, dynamic>>()
                  .map((e) => MentariSectionModel.fromJson(e))
                  .toList();
              if (sections.isNotEmpty) {
                await _storage.saveMentariCachedCourseDetail(courseId, jsonEncode(sections));
                return sections;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[MentariService] AJAX fetch sections error: $e');
      }
    }

    // ── Strategi 2: Scrape Course Page HTML ──
    try {
      final res = await _dio.get(
        '/course/view.php?id=$courseId',
        options: Options(headers: headers),
      );

      if (res.statusCode == 200 && res.data is String) {
        final html = res.data as String;
        _tryExtractAndSaveSesskey(html);
        final sections = _parseSectionsFromHtml(html);
        if (sections.isNotEmpty) {
          await _storage.saveMentariCachedCourseDetail(courseId, jsonEncode(sections));
          return sections;
        }
      }
    } catch (e) {
      debugPrint('[MentariService] Scrape course page error: $e');
    }

    // Fallback: baca cache lokal
    final cachedJson = _storage.getMentariCachedCourseDetail(courseId);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      final list = jsonDecode(cachedJson) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => MentariSectionModel.fromJson(e))
          .toList();
    }

    return const [];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helper HTML Scrapers
  // ──────────────────────────────────────────────────────────────────────────

  List<MentariCourseModel> _parseCoursesFromHtml(String html) {
    final doc = html_parser.parse(html);
    final results = <MentariCourseModel>[];
    final seenIds = <int>{};

    // Deteksi card kursus di Moodle modern
    final cards = doc.querySelectorAll('.dashboard-card, .course-info-container, .coursebox');
    for (final card in cards) {
      final link = card.querySelector('a[href*="/course/view.php?id="]');
      if (link == null) continue;

      final href = link.attributes['href'] ?? '';
      final match = RegExp(r'[?&]id=(\d+)').firstMatch(href);
      if (match == null) continue;

      final id = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (id <= 0 || seenIds.contains(id)) continue;
      seenIds.add(id);

      final titleElem = card.querySelector('.coursename, .course-title, .title, .fullname') ?? link;
      final title = titleElem.text.trim();
      if (title.isEmpty) continue;

      final imgElem = card.querySelector('img.courseimage, .dashboard-card-img');
      final imgSrc = imgElem?.attributes['src'];

      int? progress;
      final progressElem = card.querySelector('.progress-bar, .course-progress');
      if (progressElem != null) {
        final style = progressElem.attributes['style'] ?? '';
        final mProg = RegExp(r'width:\s*(\d+)%').firstMatch(style);
        if (mProg != null) progress = int.tryParse(mProg.group(1) ?? '0');
      }

      results.add(
        MentariCourseModel(
          id: id,
          fullName: title,
          shortName: title,
          courseImage: imgSrc,
          progress: progress,
        ),
      );
    }

    // Fallback: parsing dari generic links
    if (results.isEmpty) {
      final allLinks = doc.querySelectorAll('a[href*="/course/view.php?id="]');
      for (final link in allLinks) {
        final href = link.attributes['href'] ?? '';
        final match = RegExp(r'[?&]id=(\d+)').firstMatch(href);
        if (match == null) continue;

        final id = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (id <= 0 || seenIds.contains(id)) continue;

        final title = link.text.trim();
        if (title.length < 3 || title.toLowerCase().contains('view') || title.toLowerCase().contains('masuk')) {
          continue;
        }

        seenIds.add(id);
        results.add(
          MentariCourseModel(
            id: id,
            fullName: title,
            shortName: title,
          ),
        );
      }
    }

    return results;
  }

  List<MentariSectionModel> _parseSectionsFromHtml(String html) {
    final doc = html_parser.parse(html);
    final sections = <MentariSectionModel>[];

    // Deteksi container section Moodle
    var sectionNodes = doc.querySelectorAll('li.section.main, .section.course-section');
    if (sectionNodes.isEmpty) {
      sectionNodes = doc
          .querySelectorAll('div[id^="PERTEMUAN_"], div#GENERAL')
          .where((node) => !(node.attributes['id']?.endsWith('-course-index') ?? false))
          .toList();
    }

    for (var i = 0; i < sectionNodes.length; i++) {
      final node = sectionNodes[i];
      final titleNode = node.querySelector('.sectionname, .section-title, h3, h4');
      final rawTitle = titleNode?.text.trim() ?? 'Pertemuan ${i + 1}';

      final summaryNode = node.querySelector('.summary, .section-summary');
      final summary = summaryNode?.text.trim();

      final modules = <MentariModuleModel>[];
      final modNodes = node.querySelectorAll('li.activity, .activity-item');

      for (final mod in modNodes) {
        final link = mod.querySelector('a');
        final href = link?.attributes['href'] ?? '';
        final modIdMatch = RegExp(r'[?&]id=(\d+)').firstMatch(href);
        final modId = int.tryParse(modIdMatch?.group(1) ?? '0') ?? 0;

        final nameNode = mod.querySelector('.instancename, .activityname') ?? link;
        var name = nameNode?.text.trim() ?? '';
        name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

        if (name.isEmpty) continue;

        String? modTypeStr;
        final classes = mod.attributes['class'] ?? '';
        final classMatch = RegExp(r'modtype_([a-zA-Z0-9_]+)').firstMatch(classes);
        if (classMatch != null) {
          modTypeStr = classMatch.group(1);
        } else {
          final match = RegExp(r'/mod/([a-zA-Z0-9_]+)/').firstMatch(href);
          modTypeStr = match?.group(1);
        }

        final modType = MentariModuleModel.parseModuleType(modTypeStr ?? '');

        // Cari link file langsung jika ada (PDF / Resource)
        String? directFileUrl;
        if (modType == MentariModuleType.resource) {
          final fileLink = mod.querySelector('a[href*="pluginfile.php"]');
          if (fileLink != null) {
            directFileUrl = fileLink.attributes['href'];
          }
        }

        modules.add(
          MentariModuleModel(
            id: modId,
            name: name,
            type: modType,
            url: href,
            fileUrl: directFileUrl,
          ),
        );
      }

      sections.add(
        MentariSectionModel(
          id: i + 1,
          name: rawTitle,
          sectionNumber: i + 1,
          summary: summary ?? '',
          modules: modules,
        ),
      );
    }

    return sections;
  }
}
