import 'package:flutter/foundation.dart';

@immutable
class KhsCourseItem {
  final String idMtk;
  final String namaMataKuliah;
  final String sks;
  final String kelas;
  final String grade;
  final String mutu;
  final String? ambilMutu;
  final String? nilaiAbsen;
  final String? nilaiTugas;
  final String? nilaiUts;
  final String? nilaiUas;
  final String? nilaiQuiz;
  final String? aktifitasPartisipatif;
  final String? hasilProyek;

  const KhsCourseItem({
    required this.idMtk,
    required this.namaMataKuliah,
    required this.sks,
    required this.kelas,
    required this.grade,
    required this.mutu,
    this.ambilMutu,
    this.nilaiAbsen,
    this.nilaiTugas,
    this.nilaiUts,
    this.nilaiUas,
    this.nilaiQuiz,
    this.aktifitasPartisipatif,
    this.hasilProyek,
  });

  int get sksCount => int.tryParse(sks) ?? 0;
  double get mutuValue => double.tryParse(mutu) ?? 0.0;

  bool get isPassed {
    final g = grade.trim().toUpperCase();
    return g.isNotEmpty && g != 'E' && g != 'D' && g != 'T';
  }

  factory KhsCourseItem.fromJson(Map<String, dynamic> json) {
    return KhsCourseItem(
      idMtk: json['idmtk']?.toString() ?? '',
      namaMataKuliah: (json['snama'] as String?)?.trim() ?? '',
      sks: json['isks']?.toString() ?? '0',
      kelas: json['kelas']?.toString() ?? '',
      grade: (json['fgrade'] as String?)?.trim() ?? '-',
      mutu: json['imutu']?.toString() ?? '0',
      ambilMutu: json['ambil_mutu']?.toString(),
      nilaiAbsen: json['absen']?.toString(),
      nilaiTugas: json['tugas']?.toString(),
      nilaiUts: json['uts']?.toString(),
      nilaiUas: json['uas']?.toString(),
      nilaiQuiz: json['quiz']?.toString(),
      aktifitasPartisipatif: json['aktifitas_partisipatif']?.toString(),
      hasilProyek: json['hasil_proyek']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'idmtk': idMtk,
        'snama': namaMataKuliah,
        'isks': sks,
        'kelas': kelas,
        'fgrade': grade,
        'imutu': mutu,
        'ambil_mutu': ambilMutu,
        'absen': nilaiAbsen,
        'tugas': nilaiTugas,
        'uts': nilaiUts,
        'uas': nilaiUas,
        'quiz': nilaiQuiz,
        'aktifitas_partisipatif': aktifitasPartisipatif,
        'hasil_proyek': hasilProyek,
      };
}

@immutable
class KhsMutu {
  final String totalSksLulus;
  final String totalMutuLulus;
  final String totalSksAmbil;
  final String totalMutuAmbil;

  const KhsMutu({
    required this.totalSksLulus,
    required this.totalMutuLulus,
    required this.totalSksAmbil,
    required this.totalMutuAmbil,
  });

  int get sksAmbil => int.tryParse(totalSksAmbil) ?? 0;
  int get sksLulus => int.tryParse(totalSksLulus) ?? 0;

  factory KhsMutu.fromJson(Map<String, dynamic> json) {
    return KhsMutu(
      totalSksLulus: json['itotalskslulus']?.toString() ?? '0',
      totalMutuLulus: json['itotalmutululus']?.toString() ?? '0',
      totalSksAmbil: json['itotalsksambil']?.toString() ?? '0',
      totalMutuAmbil: json['itotalmutuambil']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() => {
        'itotalskslulus': totalSksLulus,
        'itotalmutululus': totalMutuLulus,
        'itotalsksambil': totalSksAmbil,
        'itotalmutuambil': totalMutuAmbil,
      };
}

@immutable
class KhsSemester {
  final String idSemesterRegistrasi;
  final String namaSemesterRegistrasi;

  const KhsSemester({
    required this.idSemesterRegistrasi,
    required this.namaSemesterRegistrasi,
  });

  factory KhsSemester.fromJson(Map<String, dynamic> json) {
    return KhsSemester(
      idSemesterRegistrasi: json['id_semester_registrasi']?.toString() ?? '',
      namaSemesterRegistrasi: json['nama_semester_registrasi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_semester_registrasi': idSemesterRegistrasi,
        'nama_semester_registrasi': namaSemesterRegistrasi,
      };
}

@immutable
class KhsResponse {
  final double? ips;
  final KhsSemester? semester;
  final KhsMutu? mutu;
  final List<KhsCourseItem> courses;

  const KhsResponse({
    this.ips,
    this.semester,
    this.mutu,
    required this.courses,
  });

  int get totalSks => courses.fold<int>(0, (sum, c) => sum + c.sksCount);

  factory KhsResponse.fromJson(Map<String, dynamic> json) {
    final List<KhsCourseItem> parsedCourses = [];
    if (json['khs'] is List) {
      for (final item in json['khs'] as List) {
        if (item is Map<String, dynamic>) {
          parsedCourses.add(KhsCourseItem.fromJson(item));
        }
      }
    }

    double? parsedIps;
    if (json['ips'] != null) {
      if (json['ips'] is num) {
        parsedIps = (json['ips'] as num).toDouble();
      } else {
        parsedIps = double.tryParse(json['ips'].toString());
      }
    }

    return KhsResponse(
      ips: parsedIps,
      semester: json['semester'] is Map<String, dynamic>
          ? KhsSemester.fromJson(json['semester'] as Map<String, dynamic>)
          : null,
      mutu: json['mutu'] is Map<String, dynamic>
          ? KhsMutu.fromJson(json['mutu'] as Map<String, dynamic>)
          : null,
      courses: List.unmodifiable(parsedCourses),
    );
  }

  Map<String, dynamic> toJson() => {
        'ips': ips,
        'semester': semester?.toJson(),
        'mutu': mutu?.toJson(),
        'khs': courses.map((c) => c.toJson()).toList(),
      };
}

