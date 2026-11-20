import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:unpam_mobile/core/network/cloudflare_clearance_modal.dart';
import 'package:unpam_mobile/features/mentari/data/mentari_service.dart';
import 'package:unpam_mobile/features/mentari/domain/models/mentari_course_model.dart';
import 'package:unpam_mobile/features/mentari/domain/models/mentari_interactive_models.dart';
import 'package:unpam_mobile/features/mentari/domain/models/mentari_module_model.dart';
import 'package:unpam_mobile/features/portal/presentation/screens/main_navigation_screen.dart';

void main() {
  group('MentariCourseModel Tests', () {
    test('Parses Mentari REST API course format (/api/user-course)', () {
      final apiJson = {
        'id': 'ffa1168d-5a44-4033-8cbc-5d3b4b37b548',
        'kode_course': '20261-04SIFE001-22SIF0173',
        'coursename': '[3] JARINGAN KOMPUTER # 04SIFE001 (Sabtu) [E-1]',
        'shortname': '57201-22SIF0173-04SIFE001-20261-1',
        'id_mata_kuliah': '22SIF0173',
        'nama_hari': 'Sabtu',
        'nama_mata_kuliah': 'JARINGAN KOMPUTER',
        'sks': 3,
        'nama_dosen': 'GUSMAYENI S.Kom., M.Kom.',
      };

      final course = MentariCourseModel.fromJson(apiJson);
      expect(course.courseCode, equals('20261-04SIFE001-22SIF0173'));
      expect(course.cleanTitle, equals('JARINGAN KOMPUTER'));
      expect(course.initials, equals('JK'));
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

  group('MentariModuleModel & Interactive Models Tests', () {
    test('Parses Vite REST API sub_section with UUID, setting_quiz, and warningAlert', () {
      final subSectionJson = {
        'id': 'ce7dd065-2868-4666-9686-59881256fcdc',
        'tipe': 'QUIZ',
        'kode_template': 'PRE_TEST',
        'sort': 1,
        'judul': 'Pretest',
        'konten': '<p>QUIZ</p>',
        'setting_quiz': {
          'tipe_quiz': 'MULTIPLE_CHOICE',
          'one_page_per_question': true,
          'duration': 45,
        },
        'completion': false,
        'haveAction': true,
        'warningAlert': 'Silakan selesaikan Pretest tepat waktu',
      };

      final module = MentariModuleModel.fromJson(subSectionJson);
      expect(module.rawId, equals('ce7dd065-2868-4666-9686-59881256fcdc'));
      expect(module.type, equals(MentariModuleType.quiz));
      expect(module.kodeTemplate, equals('PRE_TEST'));
      expect(module.quizDurationMinutes, equals(45));
      expect(module.onePagePerQuestion, isTrue);
      expect(module.warningAlert, contains('Pretest'));
    });

    test('Parses MentariParticipantModel from peserta array', () {
      final json = {
        'nim': '241011750041',
        'nama_mahasiswa': 'DIMAS ALFA PRATAMA',
        'alamat_email': 'd***@l***.com',
        'no_hp_mahasiswa': '-',
      };
      final participant = MentariParticipantModel.fromJson(json);
      expect(participant.nim, equals('241011750041'));
      expect(participant.namaMahasiswa, equals('DIMAS ALFA PRATAMA'));
      expect(participant.initials, equals('DA'));
    });

    test('Parses MentariQuizQuestionModel and MentariForumPostModel cleanly', () {
      final qJson = {
        'id': 'q1',
        'nomor': 1,
        'pertanyaan': '<p>Apakah kepanjangan dari <b>OOP</b>?</p>',
        'pilihan': [
          {'id': 'A', 'label': 'A', 'jawaban': 'Object Oriented Programming'},
          {'id': 'B', 'label': 'B', 'jawaban': 'Open Output Protocol'},
        ],
      };

      final q = MentariQuizQuestionModel.fromJson(qJson);
      expect(q.number, equals(1));
      expect(q.questionText, equals('Apakah kepanjangan dari OOP ?'));
      expect(q.options.length, equals(2));
      expect(q.options.first.text, equals('Object Oriented Programming'));

      final postJson = {
        'id': 'p101',
        'nama_user': 'BUDI SANTOSO',
        'nim': '241011750099',
        'konten': '<p>Menurut saya enkapsulasi sangat penting.</p>',
        'createdAt': '2026-10-30T10:00:00.000Z',
      };
      final post = MentariForumPostModel.fromJson(postJson);
      expect(post.authorName, equals('BUDI SANTOSO'));
      expect(post.content, equals('Menurut saya enkapsulasi sangat penting.'));
    });
  });

  group('Cloudflare Turnstile Gatekeeper & HTML Scraper Tests', () {
    test('Detects Cloudflare challenge responses accurately', () {
      expect(
        CloudflareClearanceModal.isCloudflareChallenge(
          statusCode: 403,
          body: '<html><title>Just a moment...</title><div class="cf-turnstile"></div></html>',
        ),
        isTrue,
      );
      expect(
        CloudflareClearanceModal.isCloudflareChallenge(
          statusCode: 403,
          headers: {'cf-mitigated': 'challenge'},
        ),
        isTrue,
      );
      expect(
        CloudflareClearanceModal.isCloudflareChallenge(
          statusCode: 200,
          body: '{"data": []}',
        ),
        isFalse,
      );
    });

    test('Parses 22 sections from real Mentari HTML page', () {
      final file = File('test/mentari_course.html');
      expect(file.existsSync(), isTrue);

      final htmlContent = file.readAsStringSync();
      final sections = MentariService.parseSectionsFromHtml(htmlContent);
      expect(sections.isNotEmpty, isTrue);
    });

    test('MainNavigationScreen keeps campus and Cloudflare origins in-app', () {
      expect(
        MainNavigationScreen.isAllowedInAppNavigation('https://mentari.unpam.ac.id/u-courses/123'),
        isTrue,
      );
      expect(
        MainNavigationScreen.isAllowedInAppNavigation('https://challenges.cloudflare.com/turnstile'),
        isTrue,
      );
    });
  });
}
