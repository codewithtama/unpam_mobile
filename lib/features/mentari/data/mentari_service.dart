import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../domain/models/mentari_course_model.dart';
import '../domain/models/mentari_section_model.dart';
import '../domain/models/mentari_module_model.dart';

class MentariAuthException implements Exception {
  final String message;
  const MentariAuthException([
    this.message = 'Sesi Mentari LMS belum terhubung atau telah kedaluwarsa.',
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

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{};
    final cookies = _storage.getCookies();
    if (cookies != null && cookies.isNotEmpty) {
      headers['Cookie'] = cookies;
    }
    return headers;
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

    final sesskey = _storage.getMentariSesskey();

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
            headers: _buildHeaders(),
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
        options: Options(headers: _buildHeaders()),
      );

      if (res.statusCode == 200 && res.data is String) {
        final courses = _parseCoursesFromHtml(res.data as String);
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
            headers: _buildHeaders(),
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
        options: Options(headers: _buildHeaders()),
      );

      if (res.statusCode == 200 && res.data is String) {
        final sections = _parseSectionsFromHtml(res.data as String);
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

    // Fallback pencarian tautan langsung jika card tidak terdeteksi
    if (results.isEmpty) {
      final allLinks = doc.querySelectorAll('a[href*="/course/view.php?id="]');
      for (final a in allLinks) {
        final href = a.attributes['href'] ?? '';
        final match = RegExp(r'[?&]id=(\d+)').firstMatch(href);
        if (match == null) continue;

        final id = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (id <= 0 || seenIds.contains(id)) continue;

        final text = a.text.trim();
        if (text.length < 4 || text.toLowerCase() == 'view') continue;

        seenIds.add(id);
        results.add(
          MentariCourseModel(
            id: id,
            fullName: text,
            shortName: text,
          ),
        );
      }
    }

    return results;
  }

  List<MentariSectionModel> _parseSectionsFromHtml(String html) {
    final doc = html_parser.parse(html);
    final results = <MentariSectionModel>[];
    var sectionNodes = doc.querySelectorAll('li.section.main, .section.course-section');

    // Dukung DOM Mentari modern (React/MUI: div[id^="PERTEMUAN_"], div#GENERAL)
    if (sectionNodes.isEmpty) {
      sectionNodes = doc
          .querySelectorAll('div[id^="PERTEMUAN_"], div#GENERAL')
          .where((node) => !(node.attributes['id']?.endsWith('-course-index') ?? false))
          .toList();
    }

    int sectionIdx = 0;
    for (final secNode in sectionNodes) {
      final titleElem = secNode.querySelector('.sectionname, .section-title, .MuiTypography-h6, h3, h6');
      final title = titleElem?.text.trim() ?? 'Pertemuan $sectionIdx';

      final summaryElem = secNode.querySelector('.summary, .section-summary, .MuiTypography-caption');
      final summary = summaryElem?.text.trim() ?? '';

      final modules = <MentariModuleModel>[];
      final activityNodes = secNode.querySelectorAll('li.activity, .activity-item, a[href*="/mod/"]');

      for (final act in activityNodes) {
        final actLink = act.localName == 'a' 
            ? act 
            : (act.querySelector('a.aalink, a[href*="/mod/"]') ?? act.querySelector('a'));
        final actUrl = actLink?.attributes['href'] ?? '';
        if (actUrl.isEmpty) continue;

        final nameElem = act.querySelector('.instancename, .activityname') ?? actLink;
        var actName = nameElem?.text.trim() ?? 'Aktivitas';
        // Bersihkan label Moodle tersembunyi seperti "File", "Forum"
        actName = actName.replaceAll(RegExp(r'\s*(?:File|Forum|Quiz|Assignment)\s*$', caseSensitive: false), '');

        // Tipe modul dari class name CSS atau URL path (/mod/quiz/, dsb)
        final classList = act.classes.join(' ').toLowerCase();
        String typeStr = 'other';
        if (classList.contains('modtype_resource') || actUrl.contains('/mod/resource/')) {
          typeStr = 'resource';
        } else if (classList.contains('modtype_forum') || actUrl.contains('/mod/forum/')) {
          typeStr = 'forum';
        } else if (classList.contains('modtype_quiz') || actUrl.contains('/mod/quiz/')) {
          typeStr = 'quiz';
        } else if (classList.contains('modtype_assign') || actUrl.contains('/mod/assign/')) {
          typeStr = 'assign';
        } else if (classList.contains('modtype_attendance') || actUrl.contains('/mod/attendance/')) {
          typeStr = 'attendance';
        } else if (classList.contains('modtype_url') || actUrl.contains('/mod/url/')) {
          typeStr = 'url';
        }

        final mIdMatch = RegExp(r'[?&]id=(\d+)').firstMatch(actUrl);
        final mId = int.tryParse(mIdMatch?.group(1) ?? '0') ?? 0;

        modules.add(
          MentariModuleModel(
            id: mId,
            name: actName.isNotEmpty ? actName : 'Aktivitas',
            type: MentariModuleModel.parseModuleType(typeStr),
            url: actUrl,
            fileUrl: typeStr == 'resource' ? actUrl : null,
          ),
        );
      }

      results.add(
        MentariSectionModel(
          id: sectionIdx,
          name: title,
          sectionNumber: sectionIdx,
          summary: summary,
          modules: modules,
        ),
      );
      sectionIdx++;
    }

    return results;
  }
}
