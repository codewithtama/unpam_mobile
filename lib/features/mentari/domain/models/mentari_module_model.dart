import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

enum MentariModuleType {
  resource,
  forum,
  quiz,
  assign,
  attendance,
  url,
  page,
  other,
}

class MentariModuleModel {
  final int id;
  final String rawId;
  final String name;
  final MentariModuleType type;
  final String kodeTemplate;
  final String url;
  final String? description;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final bool isCompleted;
  final bool haveAction;
  final int quizDurationMinutes;
  final bool onePagePerQuestion;
  final DateTime? dueDate;
  final String? warningAlert;

  const MentariModuleModel({
    required this.id,
    this.rawId = '',
    required this.name,
    required this.type,
    this.kodeTemplate = '',
    this.url = '',
    this.description,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.isCompleted = false,
    this.haveAction = true,
    this.quizDurationMinutes = 60,
    this.onePagePerQuestion = true,
    this.dueDate,
    this.warningAlert,
  });

  static MentariModuleType parseModuleType(String raw) {
    final lower = raw.toLowerCase().trim();
    return switch (lower) {
      'resource' ||
      'file' ||
      'folder' ||
      'buku_isbn' ||
      'power_point' ||
      'artikel_riset' ||
      'materi_lainnya' =>
        MentariModuleType.resource,
      'forum' || 'discussion' || 'forum_diskusi' => MentariModuleType.forum,
      'quiz' ||
      'pre_test' ||
      'post_test' ||
      'quesioner' ||
      'kuesioner' =>
        MentariModuleType.quiz,
      'assign' ||
      'assignment' ||
      'penugasan_terstruktur' =>
        MentariModuleType.assign,
      'attendance' || 'presensi' => MentariModuleType.attendance,
      'url' || 'link' || 'link_vcon' || 'video_ajar' => MentariModuleType.url,
      'page' || 'book' || 'label' => MentariModuleType.page,
      _ => MentariModuleType.other,
    };
  }

  IconData get icon => switch (type) {
        MentariModuleType.resource => Icons.description_rounded,
        MentariModuleType.forum => Icons.forum_rounded,
        MentariModuleType.quiz => Icons.quiz_rounded,
        MentariModuleType.assign => Icons.assignment_rounded,
        MentariModuleType.attendance => Icons.how_to_reg_rounded,
        MentariModuleType.url => Icons.link_rounded,
        MentariModuleType.page => Icons.menu_book_rounded,
        MentariModuleType.other => Icons.extension_rounded,
      };

  Color get color => switch (type) {
        MentariModuleType.resource => AppTheme.primaryBlue,
        MentariModuleType.forum => Colors.teal,
        MentariModuleType.quiz => AppTheme.accentGold,
        MentariModuleType.assign => AppTheme.accentGold,
        MentariModuleType.attendance => AppTheme.successGreen,
        MentariModuleType.url => AppTheme.primaryBlue,
        MentariModuleType.page => AppTheme.primaryLight,
        MentariModuleType.other => Colors.grey.shade600,
      };

  String get typeLabel => switch (type) {
        MentariModuleType.resource => 'Materi / Berkas',
        MentariModuleType.forum => 'Forum Diskusi',
        MentariModuleType.quiz => 'Kuis Pertemuan',
        MentariModuleType.assign => 'Tugas Kuliah',
        MentariModuleType.attendance => 'Presensi Mandiri',
        MentariModuleType.url => 'Tautan Luar',
        MentariModuleType.page => 'Modul Bacaan',
        MentariModuleType.other => 'Aktivitas',
      };

  bool get isPdf =>
      (fileName != null && fileName!.toLowerCase().endsWith('.pdf')) ||
      (fileUrl != null && fileUrl!.toLowerCase().contains('.pdf')) ||
      name.toLowerCase().contains('.pdf');

  bool get isDownloadable =>
      type == MentariModuleType.resource &&
      ((fileUrl != null && fileUrl!.isNotEmpty) || url.isNotEmpty);

  String get formattedFileSize {
    if (fileSize == null || fileSize! <= 0) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory MentariModuleModel.fromJson(Map<String, dynamic> json) {
    String? fUrl;
    String? fName;
    int? fSize;

    if (json['contents'] is List && (json['contents'] as List).isNotEmpty) {
      final first = (json['contents'] as List).first;
      if (first is Map<String, dynamic>) {
        fUrl = first['fileurl']?.toString();
        fName = first['filename']?.toString();
        final rawSize = first['filesize'];
        if (rawSize is num) fSize = rawSize.toInt();
      }
    }

    DateTime? due;
    final rawDue = json['dates'];
    if (rawDue is List) {
      for (final d in rawDue) {
        if (d is Map && d['label']?.toString().toLowerCase().contains('due') == true) {
          final ts = d['timestamp'];
          if (ts is num) {
            due = DateTime.fromMillisecondsSinceEpoch(ts.toInt() * 1000);
          }
        }
      }
    }
    if (due == null && json['dueDate'] != null) {
      due = DateTime.tryParse(json['dueDate'].toString());
    }

    final rawType = (json['kode_template'] ??
            json['tipe'] ??
            json['modname'] ??
            json['type'] ??
            'other')
        .toString();
    final url = (json['link'] ?? json['url'] ?? '').toString();
    final name = (json['judul'] ?? json['name'] ?? 'Aktivitas Perkuliahan').toString();
    final rawIdStr = (json['rawId'] ?? json['id'] ?? '').toString();

    int parsedId = int.tryParse(rawIdStr) ?? 0;
    if (parsedId == 0 && rawIdStr.isNotEmpty) {
      parsedId = rawIdStr.hashCode.abs();
    }

    final isCompleted = json['completion'] == true ||
        json['completion'] == 1 ||
        json['isCompleted'] == true ||
        json['completiondata']?['state'] == 1;

    int duration = 60;
    bool onePage = true;
    final settingQuiz = json['setting_quiz'];
    if (settingQuiz is Map) {
      duration = (settingQuiz['duration'] as num?)?.toInt() ?? 60;
      onePage = settingQuiz['one_page_per_question'] != false;
    } else if (json['quizDurationMinutes'] is num) {
      duration = (json['quizDurationMinutes'] as num).toInt();
    }

    return MentariModuleModel(
      id: parsedId,
      rawId: rawIdStr,
      name: name,
      type: parseModuleType(rawType),
      kodeTemplate: (json['kode_template'] ?? rawType).toString(),
      url: url,
      description: (json['konten'] ?? json['description'])?.toString(),
      fileUrl: json['file']?.toString() ?? fUrl ?? json['fileurl']?.toString(),
      fileName: fName ?? json['filename']?.toString(),
      fileSize: fSize,
      isCompleted: isCompleted,
      haveAction: json['haveAction'] != false,
      quizDurationMinutes: duration,
      onePagePerQuestion: onePage,
      dueDate: due,
      warningAlert: json['warningAlert']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawId': rawId,
        'name': name,
        'type': type.name,
        'kode_template': kodeTemplate,
        'url': url,
        'description': description,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'isCompleted': isCompleted,
        'haveAction': haveAction,
        'quizDurationMinutes': quizDurationMinutes,
        'onePagePerQuestion': onePagePerQuestion,
        'dueDate': dueDate?.toIso8601String(),
        if (warningAlert != null) 'warningAlert': warningAlert,
      };
}
