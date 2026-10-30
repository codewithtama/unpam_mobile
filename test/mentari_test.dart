import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unpam_mobile/core/services/storage_service.dart';
import 'package:unpam_mobile/features/mentari/domain/models/mentari_course_model.dart';
import 'package:unpam_mobile/features/mentari/domain/models/mentari_section_model.dart';
import 'package:unpam_mobile/features/mentari/domain/models/mentari_module_model.dart';
import 'package:unpam_mobile/features/portal/presentation/screens/main_navigation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MentariCourseModel Tests', () {
    test('Cleans course title with bracketed semester and class code suffix', () {
      const course = MentariCourseModel(
        id: 101,
        fullName: '[3] JARINGAN KOMPUTER # 04SIFE001 (Sabtu) [E-1]',
        shortName: 'JK-04SIFE001',
      );

      expect(course.cleanTitle, equals('JARINGAN KOMPUTER'));
      expect(course.cleanCode, equals('04SIFE001'));
      expect(course.initials, equals('JK'));
    });

    test('Cleans course title with standard prefix code', () {
      const course = MentariCourseModel(
        id: 102,
        fullName: '[04TPLP001] PEMROGRAMAN MOBILE',
        shortName: '04TPLP001',
      );

      expect(course.cleanTitle, equals('PEMROGRAMAN MOBILE'));
      expect(course.cleanCode, equals('04TPLP001'));
      expect(course.initials, equals('PM'));
    });

    test('Serializes to and from JSON accurately', () {
      final jsonMap = {
        'id': 505,
        'fullname': 'SISTEM BASIS DATA',
        'shortname': 'SBD-01',
        'idnumber': '04TPLP002',
        'courseimage': 'https://mentari.unpam.ac.id/image.jpg',
        'progress': 75,
        'coursecategory': 'Teknik Informatika',
        'isfavourite': true,
        'sections': [
          {
            'id': 1,
            'name': 'Pertemuan 1',
            'section': 1,
            'summary': 'Pengenalan SQL',
            'modules': [
              {
                'id': 1001,
                'name': 'Modul 01 - Pengantar Database',
                'modname': 'resource',
                'url': 'https://mentari.unpam.ac.id/mod/resource/view.php?id=1001',
                'contents': [
                  {
                    'fileurl': 'https://mentari.unpam.ac.id/mod/resource/download.pdf',
                    'filesize': 1024000,
                  }
                ]
              }
            ]
          }
        ],
      };

      final course = MentariCourseModel.fromJson(jsonMap);
      expect(course.id, equals(505));
      expect(course.fullName, equals('SISTEM BASIS DATA'));
      expect(course.progress, equals(75));
      expect(course.isFavorite, isTrue);
      expect(course.sections.length, equals(1));
      expect(course.sections.first.modules.first.isPdf, isTrue);

      final encoded = course.toJson();
      expect(encoded['id'], equals(505));
      expect(encoded['fullname'], equals('SISTEM BASIS DATA'));
      expect(encoded['progress'], equals(75));
    });
  });

  group('MentariModuleModel & Section Tests', () {
    test('Correctly identifies module types and icons', () {
      expect(MentariModuleModel.parseModuleType('resource'), equals(MentariModuleType.resource));
      expect(MentariModuleModel.parseModuleType('quiz'), equals(MentariModuleType.quiz));
      expect(MentariModuleModel.parseModuleType('assign'), equals(MentariModuleType.assign));
      expect(MentariModuleModel.parseModuleType('forum'), equals(MentariModuleType.forum));
      expect(MentariModuleModel.parseModuleType('attendance'), equals(MentariModuleType.attendance));
      expect(MentariModuleModel.parseModuleType('url'), equals(MentariModuleType.url));
      expect(MentariModuleModel.parseModuleType('unknown_type'), equals(MentariModuleType.other));
    });

    test('Detects PDF file download suitability', () {
      const pdfModule = MentariModuleModel(
        id: 11,
        name: 'Slide Kuliah Bab 1',
        type: MentariModuleType.resource,
        fileUrl: 'https://mentari.unpam.ac.id/pluginfile.php/slide.pdf',
      );
      expect(pdfModule.isPdf, isTrue);
      expect(pdfModule.isDownloadable, isTrue);

      const quizModule = MentariModuleModel(
        id: 12,
        name: 'Kuis Pertemuan 1',
        type: MentariModuleType.quiz,
        url: 'https://mentari.unpam.ac.id/mod/quiz/view.php?id=12',
      );
      expect(quizModule.isPdf, isFalse);
      expect(quizModule.isDownloadable, isFalse);
    });

    test('Section meeting calculation and serialization', () {
      const section = MentariSectionModel(
        id: 2,
        name: 'Pertemuan 2',
        sectionNumber: 2,
        summary: 'Arsitektur Jaringan',
        modules: [
          MentariModuleModel(
            id: 201,
            name: 'Forum Diskusi Topologi',
            type: MentariModuleType.forum,
          ),
        ],
      );

      final json = section.toJson();
      expect(json['id'], equals(2));
      expect(json['name'], equals('Pertemuan 2'));
      expect(json['modules'], isList);

      final decoded = MentariSectionModel.fromJson(json);
      expect(decoded.id, equals(2));
      expect(decoded.name, equals('Pertemuan 2'));
      expect(decoded.modules.first.type, equals(MentariModuleType.forum));
    });
  });

  group('Mentari HTML Scraper Tests', () {
    test('Parses 22 sections from real Mentari HTML page', () {
      final file = File('test/mentari_course.html');
      expect(file.existsSync(), isTrue);

      final htmlContent = file.readAsStringSync();
      final doc = html_parser.parse(htmlContent);

      var sectionNodes = doc.querySelectorAll('li.section.main, .section.course-section');
      if (sectionNodes.isEmpty) {
        sectionNodes = doc
            .querySelectorAll('div[id^="PERTEMUAN_"], div#GENERAL')
            .where((node) => !(node.attributes['id']?.endsWith('-course-index') ?? false))
            .toList();
      }

      // 1 General + 21 Pertemuan = 22 total sections
      expect(sectionNodes.length, equals(22));

      final firstMeeting = sectionNodes.firstWhere(
        (node) => node.attributes['id'] == 'PERTEMUAN_1',
      );
      final titleElem = firstMeeting.querySelector('.MuiTypography-h6, h6');
      final captionElem = firstMeeting.querySelector('.MuiTypography-caption, span');

      expect(titleElem?.text.trim(), equals('Pertemuan 1'));
      expect(captionElem?.text.trim(), equals('PENGENALAN INTRANET DAN INTERNET'));

      final lastMeeting = sectionNodes.firstWhere(
        (node) => node.attributes['id'] == 'PERTEMUAN_21',
      );
      final lastCaption = lastMeeting.querySelector('.MuiTypography-caption, span');
      expect(lastCaption?.text.trim(), equals('RESTORE'));
    });

    test('Parses classic Moodle HTML with activities and resources', () {
      const classicMoodleHtml = '''
        <div class="coursebox">
          <a href="https://mentari.unpam.ac.id/course/view.php?id=999">
            <span class="coursename">[3] ALGORITMA PEMROGRAMAN</span>
          </a>
        </div>
        <ul class="topics">
          <li class="section main" id="section-1">
            <h3 class="sectionname">Pertemuan 1: Dasar C++</h3>
            <div class="summary"><p>Pengenalan sintaks C++</p></div>
            <ul class="section img-text">
              <li class="activity resource modtype_resource" id="module-101">
                <div class="activityinstance">
                  <a class="aalink" href="https://mentari.unpam.ac.id/mod/resource/view.php?id=101">
                    <span class="instancename">Materi C++ PDF File</span>
                  </a>
                </div>
              </li>
              <li class="activity quiz modtype_quiz" id="module-102">
                <div class="activityinstance">
                  <a class="aalink" href="https://mentari.unpam.ac.id/mod/quiz/view.php?id=102">
                    <span class="instancename">Kuis 01</span>
                  </a>
                </div>
              </li>
            </ul>
          </li>
        </ul>
      ''';

      final doc = html_parser.parse(classicMoodleHtml);
      final sectionNode = doc.querySelector('li.section.main');
      expect(sectionNode, isNotNull);

      final title = sectionNode!.querySelector('.sectionname')?.text.trim();
      expect(title, equals('Pertemuan 1: Dasar C++'));

      final activities = sectionNode.querySelectorAll('li.activity');
      expect(activities.length, equals(2));

      final act1Link = activities[0].querySelector('a[href*="/mod/"]')?.attributes['href'];
      expect(act1Link, contains('/mod/resource/'));
      final act1Classes = activities[0].classes.join(' ');
      expect(act1Classes, contains('modtype_resource'));

      final act2Link = activities[1].querySelector('a[href*="/mod/"]')?.attributes['href'];
      expect(act2Link, contains('/mod/quiz/'));
    });
  });

  group('StorageService Mentari Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves and retrieves Mentari sesskey and cached courses correctly', () async {
      final storage = await StorageService.getInstance();

      expect(storage.getMentariSesskey(), isNull);
      await storage.saveMentariSesskey('test_sesskey_abc123');
      expect(storage.getMentariSesskey(), equals('test_sesskey_abc123'));

      const testCoursesJson = '[{"id":101,"fullname":"JARINGAN KOMPUTER","shortname":"JK"}]';
      await storage.saveMentariCachedCourses(testCoursesJson);
      expect(storage.getMentariCachedCourses(), equals(testCoursesJson));

      const testDetailJson = '[{"id":1,"name":"Pertemuan 1","modules":[]}]';
      await storage.saveMentariCachedCourseDetail(101, testDetailJson);
      expect(storage.getMentariCachedCourseDetail(101), equals(testDetailJson));
    });
  });

  group('MainNavigationScreen Architecture Tests', () {
    test('isAllowedInAppNavigation correctly validates internal campus & SSO domains', () {
      expect(MainNavigationScreen.isAllowedInAppNavigation('https://mentari.unpam.ac.id/my/'), isTrue);
      expect(MainNavigationScreen.isAllowedInAppNavigation('https://my.unpam.ac.id/dashboard'), isTrue);
      expect(MainNavigationScreen.isAllowedInAppNavigation('https://satu.unpam.ac.id/login'), isTrue);
      expect(MainNavigationScreen.isAllowedInAppNavigation('https://challenges.cloudflare.com/turnstile'), isTrue);
      expect(MainNavigationScreen.isAllowedInAppNavigation('blob:https://mentari.unpam.ac.id/test.pdf'), isTrue);

      expect(MainNavigationScreen.isAllowedInAppNavigation('https://unpam.fake-domain.com'), isFalse);
      expect(MainNavigationScreen.isAllowedInAppNavigation('https://phishing-site.com'), isFalse);
    });
  });
}
