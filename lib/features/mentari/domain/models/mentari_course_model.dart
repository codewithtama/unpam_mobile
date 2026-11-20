import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'mentari_section_model.dart';

class MentariCourseModel {
  final int id;
  final String fullName;
  final String shortName;
  final String idNumber;
  final String? courseImage;
  final int? progress;
  final String? courseCategory;
  final bool isFavorite;
  final List<MentariSectionModel> sections;
  final String? courseCode;

  const MentariCourseModel({
    required this.id,
    required this.fullName,
    required this.shortName,
    this.idNumber = '',
    this.courseImage,
    this.progress,
    this.courseCategory,
    this.isFavorite = false,
    this.sections = const [],
    this.courseCode,
  });

  String get cleanTitle {
    var title = fullName.trim();
    // Bersihkan prefix kode/nomor kelas seperti "[3] " atau "[04TPLP001] " atau "04TPLP001 - "
    title = title.replaceAll(RegExp(r'^\[[^\]]+\]\s*'), '');
    title = title.replaceAll(RegExp(r'^[A-Z0-9]{5,12}\s*[-–]\s*', caseSensitive: false), '');
    // Bersihkan suffix kelas seperti " # 04SIFE001 (Sabtu) [E-1]" jika ada
    final hashIdx = title.indexOf('#');
    if (hashIdx > 0) {
      final beforeHash = title.substring(0, hashIdx).trim();
      if (beforeHash.isNotEmpty) {
        return beforeHash;
      }
    }
    return title.isNotEmpty ? title : fullName;
  }

  String get cleanCode {
    if (idNumber.isNotEmpty) {
      final unpamClassMatch = RegExp(r'\b([0-9]{2}[A-Za-z]{3,5}[0-9]{3})\b').firstMatch(idNumber);
      if (unpamClassMatch != null) return unpamClassMatch.group(1)!;
    }
    // Coba ekstrak pola kode kelas UNPAM seperti 04SIFE001 atau 04TPLP001 dari fullName
    final unpamClassMatch = RegExp(r'\b([0-9]{2}[A-Za-z]{3,5}[0-9]{3})\b').firstMatch(fullName);
    if (unpamClassMatch != null) return unpamClassMatch.group(1)!;
    // Coba ekstrak pola umum [KODE] atau KODE
    final match = RegExp(r'\[?([A-Z0-9]{5,12})\]?', caseSensitive: false).firstMatch(fullName);
    if (match != null) return match.group(1) ?? (idNumber.isNotEmpty ? idNumber : shortName);
    return idNumber.isNotEmpty ? idNumber : (courseCode ?? shortName);
  }

  String get initials {
    final words = cleanTitle
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .toList();
    if (words.isEmpty) return 'MK';
    if (words.length == 1) return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Color get accentColor {
    final colors = [
      AppTheme.primaryBlue,
      Colors.teal.shade700,
      AppTheme.primaryBlue,
      AppTheme.accentGold,
      Colors.deepPurple.shade700,
      AppTheme.primaryLight,
    ];
    final seed = id != 0 ? id.abs() : (courseCode?.hashCode.abs() ?? 1);
    return colors[seed % colors.length];
  }

  MentariCourseModel copyWith({
    List<MentariSectionModel>? sections,
    int? progress,
    String? courseCode,
  }) {
    return MentariCourseModel(
      id: id,
      fullName: fullName,
      shortName: shortName,
      idNumber: idNumber,
      courseImage: courseImage,
      progress: progress ?? this.progress,
      courseCategory: courseCategory,
      isFavorite: isFavorite,
      sections: sections ?? this.sections,
      courseCode: courseCode ?? this.courseCode,
    );
  }

  factory MentariCourseModel.fromJson(Map<String, dynamic> json) {
    int? p;
    final rawProgress = json['progress'];
    if (rawProgress is num) {
      p = rawProgress.toInt();
    } else if (rawProgress is String) {
      p = int.tryParse(rawProgress);
    }

    final rawSections = (json['sections'] ?? json['data']) as List<dynamic>? ?? [];
    final sections = rawSections
        .whereType<Map<String, dynamic>>()
        .map((s) => MentariSectionModel.fromJson(s))
        .toList();

    final code = (json['kode_course'] ?? json['course_code'] ?? json['idnumber'] ?? '').toString();
    int parsedId = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    if (parsedId == 0 && code.isNotEmpty) {
      parsedId = code.hashCode.abs();
    }

    final fullName = (json['coursename'] ?? json['course_name'] ?? json['fullname'] ?? json['name'] ?? 'Mata Kuliah').toString();
    final shortName = (json['shortname'] ?? (code.isNotEmpty ? code : '')).toString();

    return MentariCourseModel(
      id: parsedId,
      fullName: fullName,
      shortName: shortName,
      idNumber: (json['idnumber'] ?? code).toString(),
      courseImage: (json['courseimage'] ?? json['image'] ?? json['cover_image'])?.toString(),
      progress: p,
      courseCategory: (json['coursecategory'] ?? json['categoryname'] ?? json['content_type'])?.toString(),
      isFavorite: json['isfavourite'] == true,
      sections: sections,
      courseCode: code.isNotEmpty ? code : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullname': fullName,
        'shortname': shortName,
        'idnumber': idNumber,
        'courseimage': courseImage,
        'progress': progress,
        'coursecategory': courseCategory,
        'isfavourite': isFavorite,
        if (courseCode != null) 'kode_course': courseCode,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}
