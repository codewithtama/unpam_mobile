import 'package:flutter/foundation.dart';

@immutable
class KrsCourseItem {
  final String idMataKuliah;
  final String namaMataKuliah;
  final String sksMataKuliah;
  final String idKelas;
  final String? idProdi;
  final String? idKurikulum;
  final String? namaKurikulum;
  final String? idJenisMataKuliah;
  final String? namaDosenPengampu;

  const KrsCourseItem({
    required this.idMataKuliah,
    required this.namaMataKuliah,
    required this.sksMataKuliah,
    required this.idKelas,
    this.idProdi,
    this.idKurikulum,
    this.namaKurikulum,
    this.idJenisMataKuliah,
    this.namaDosenPengampu,
  });

  int get sks => int.tryParse(sksMataKuliah) ?? 0;

  factory KrsCourseItem.fromJson(Map<String, dynamic> json) {
    String? dosen;
    if (json['mata_kuliah'] is Map) {
      final mk = json['mata_kuliah'] as Map<String, dynamic>;
      dosen = mk['nama_dosen_pengampu'] as String? ??
          mk['dosen_pengampu']?['nama_dosen'] as String?;
    }

    return KrsCourseItem(
      idMataKuliah: json['id_mata_kuliah']?.toString() ?? '',
      namaMataKuliah: (json['nama_mata_kuliah'] as String?)?.trim() ?? '',
      sksMataKuliah: json['sks_mata_kuliah']?.toString() ?? '0',
      idKelas: json['id_kelas']?.toString() ?? '',
      idProdi: json['id_prodi']?.toString(),
      idKurikulum: json['id_kurikulum']?.toString(),
      namaKurikulum: json['nama_kurikulum'] as String?,
      idJenisMataKuliah: json['id_jenis_mata_kuliah']?.toString(),
      namaDosenPengampu: dosen,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_mata_kuliah': idMataKuliah,
        'nama_mata_kuliah': namaMataKuliah,
        'sks_mata_kuliah': sksMataKuliah,
        'id_kelas': idKelas,
        'id_prodi': idProdi,
        'id_kurikulum': idKurikulum,
        'nama_kurikulum': namaKurikulum,
        'id_jenis_mata_kuliah': idJenisMataKuliah,
        'nama_dosen_pengampu': namaDosenPengampu,
      };
}

@immutable
class KrsMutu {
  final String totalSksLulus;
  final String totalMutuLulus;
  final String totalSksAmbil;
  final String totalMutuAmbil;

  const KrsMutu({
    required this.totalSksLulus,
    required this.totalMutuLulus,
    required this.totalSksAmbil,
    required this.totalMutuAmbil,
  });

  int get sksAmbil => int.tryParse(totalSksAmbil) ?? 0;
  int get sksLulus => int.tryParse(totalSksLulus) ?? 0;

  factory KrsMutu.fromJson(Map<String, dynamic> json) {
    return KrsMutu(
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
class KrsSemester {
  final String idSemesterRegistrasi;
  final String namaSemesterRegistrasi;

  const KrsSemester({
    required this.idSemesterRegistrasi,
    required this.namaSemesterRegistrasi,
  });

  factory KrsSemester.fromJson(Map<String, dynamic> json) {
    return KrsSemester(
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
class KrsResponse {
  final KrsSemester? semester;
  final KrsMutu? mutu;
  final List<KrsCourseItem> courses;

  const KrsResponse({
    this.semester,
    this.mutu,
    required this.courses,
  });

  int get totalSks => courses.fold<int>(0, (sum, c) => sum + c.sks);

  factory KrsResponse.fromJson(Map<String, dynamic> json) {
    final List<KrsCourseItem> parsedCourses = [];
    if (json['mahasiswa'] is Map && (json['mahasiswa'] as Map)['krs'] is List) {
      final list = (json['mahasiswa'] as Map)['krs'] as List;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          parsedCourses.add(KrsCourseItem.fromJson(item));
        }
      }
    } else if (json['krs'] is List) {
      final list = json['krs'] as List;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          parsedCourses.add(KrsCourseItem.fromJson(item));
        }
      }
    }

    return KrsResponse(
      semester: json['semester'] is Map<String, dynamic>
          ? KrsSemester.fromJson(json['semester'] as Map<String, dynamic>)
          : null,
      mutu: json['mutu'] is Map<String, dynamic>
          ? KrsMutu.fromJson(json['mutu'] as Map<String, dynamic>)
          : null,
      courses: List.unmodifiable(parsedCourses),
    );
  }

  Map<String, dynamic> toJson() => {
        'semester': semester?.toJson(),
        'mutu': mutu?.toJson(),
        'krs': courses.map((c) => c.toJson()).toList(),
      };
}
