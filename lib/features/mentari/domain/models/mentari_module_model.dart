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
  final String name;
  final MentariModuleType type;
  final String url;
  final String? description;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final bool isCompleted;
  final DateTime? dueDate;

  const MentariModuleModel({
    required this.id,
    required this.name,
    required this.type,
    this.url = '',
    this.description,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.isCompleted = false,
    this.dueDate,
  });

  static MentariModuleType parseModuleType(String modName) {
    final lower = modName.toLowerCase().trim();
    return switch (lower) {
      'resource' || 'file' || 'folder' => MentariModuleType.resource,
      'forum' || 'discussion' => MentariModuleType.forum,
      'quiz' => MentariModuleType.quiz,
      'assign' || 'assignment' => MentariModuleType.assign,
      'attendance' || 'presensi' => MentariModuleType.attendance,
      'url' => MentariModuleType.url,
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

    final rawType = (json['modname'] ?? json['type'] ?? 'other').toString();

    return MentariModuleModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? 'Aktivitas Perkuliahan').toString(),
      type: parseModuleType(rawType),
      url: (json['url'] ?? '').toString(),
      description: json['description']?.toString(),
      fileUrl: fUrl ?? json['fileurl']?.toString(),
      fileName: fName ?? json['filename']?.toString(),
      fileSize: fSize,
      isCompleted: json['completiondata']?['state'] == 1 || json['completion'] == 1,
      dueDate: due,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'url': url,
        'description': description,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'isCompleted': isCompleted,
        'dueDate': dueDate?.toIso8601String(),
      };
}
