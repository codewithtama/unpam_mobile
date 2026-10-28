import 'dart:convert';

/// Model jadwal kuliah satu sesi pertemuan.
class CourseSchedule {
  final String kode;
  final String namaMataKuliah;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String ruang;
  final String dosen;
  final String kelas;
  final int hariIndex; // 1=Senin … 7=Minggu, 0=unknown

  const CourseSchedule({
    required this.kode,
    required this.namaMataKuliah,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruang,
    required this.dosen,
    required this.kelas,
    required this.hariIndex,
  });

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    return CourseSchedule(
      kode: (json['kode'] as String? ?? '').trim(),
      namaMataKuliah: (json['namaMataKuliah'] as String? ?? '').trim(),
      hari: (json['hari'] as String? ?? '').trim(),
      jamMulai: (json['jamMulai'] as String? ?? '').trim(),
      jamSelesai: (json['jamSelesai'] as String? ?? '').trim(),
      ruang: (json['ruang'] as String? ?? '').trim(),
      dosen: (json['dosen'] as String? ?? '').trim(),
      kelas: (json['kelas'] as String? ?? '').trim(),
      hariIndex: (json['hariIndex'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'kode': kode,
        'namaMataKuliah': namaMataKuliah,
        'hari': hari,
        'jamMulai': jamMulai,
        'jamSelesai': jamSelesai,
        'ruang': ruang,
        'dosen': dosen,
        'kelas': kelas,
        'hariIndex': hariIndex,
      };

  static List<CourseSchedule> listFromJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CourseSchedule.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<CourseSchedule> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());
}

/// Tipe deadline akademik.
enum DeadlineType { tugas, kuis, ujian, presensi, lainnya }

extension DeadlineTypeExtension on DeadlineType {
  String get label {
    switch (this) {
      case DeadlineType.tugas:
        return 'Tugas';
      case DeadlineType.kuis:
        return 'Kuis';
      case DeadlineType.ujian:
        return 'Ujian';
      case DeadlineType.presensi:
        return 'Presensi';
      case DeadlineType.lainnya:
        return 'Lainnya';
    }
  }

  String get emoji {
    switch (this) {
      case DeadlineType.tugas:
        return '📝';
      case DeadlineType.kuis:
        return '📋';
      case DeadlineType.ujian:
        return '📖';
      case DeadlineType.presensi:
        return '✅';
      case DeadlineType.lainnya:
        return '📌';
    }
  }
}

/// Model deadline / tenggat waktu akademik.
class CourseDeadline {
  final String id;
  final String namaTugas;
  final String namaMataKuliah;
  final DateTime dueDate;
  final DeadlineType tipe;
  final String url;

  const CourseDeadline({
    required this.id,
    required this.namaTugas,
    required this.namaMataKuliah,
    required this.dueDate,
    required this.tipe,
    required this.url,
  });

  /// Sisa waktu ke deadline dalam hari (negatif = sudah lewat).
  int get daysUntilDue =>
      dueDate.difference(DateTime.now()).inDays;

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  bool get isDueSoon => !isOverdue && daysUntilDue <= 3;

  factory CourseDeadline.fromJson(Map<String, dynamic> json) {
    DeadlineType tipe;
    final tipeStr = (json['tipe'] as String? ?? 'lainnya').toLowerCase();
    switch (tipeStr) {
      case 'tugas':
        tipe = DeadlineType.tugas;
        break;
      case 'kuis':
        tipe = DeadlineType.kuis;
        break;
      case 'ujian':
        tipe = DeadlineType.ujian;
        break;
      case 'presensi':
        tipe = DeadlineType.presensi;
        break;
      default:
        tipe = DeadlineType.lainnya;
    }

    return CourseDeadline(
      id: (json['id'] as String? ?? '').trim(),
      namaTugas: (json['namaTugas'] as String? ?? '').trim(),
      namaMataKuliah: (json['namaMataKuliah'] as String? ?? '').trim(),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      tipe: tipe,
      url: (json['url'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'namaTugas': namaTugas,
        'namaMataKuliah': namaMataKuliah,
        'dueDate': dueDate.toIso8601String(),
        'tipe': tipe.name,
        'url': url,
      };

  static List<CourseDeadline> listFromJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CourseDeadline.fromJson)
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<CourseDeadline> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());
}

