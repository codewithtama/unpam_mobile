import 'academic_grades_model.dart';
import 'student_biodata_model.dart';

class LectureScheduleResponse {
  final StudentBiodata? mahasiswa;
  final List<LectureScheduleItem> jadwal;
  final AcademicSemesterInfo? semester;

  LectureScheduleResponse({
    this.mahasiswa,
    required this.jadwal,
    this.semester,
  });

  Map<String, List<LectureScheduleItem>> get groupedByDay {
    final Map<String, List<LectureScheduleItem>> map = {};
    for (final item in jadwal) {
      final day = item.dayName;
      map.putIfAbsent(day, () => []).add(item);
    }
    return map;
  }

  List<LectureScheduleItem> filterByPeriod(String? period) {
    if (period == null || period.isEmpty || period == 'all') {
      return jadwal;
    }
    return jadwal.where((item) => item.idPeriode == period).toList();
  }

  factory LectureScheduleResponse.fromJson(Map<String, dynamic> json) {
    return LectureScheduleResponse(
      mahasiswa: json['mahasiswa'] != null
          ? StudentBiodata.fromJson(json['mahasiswa'] as Map<String, dynamic>)
          : null,
      jadwal: json['jadwal'] is List
          ? (json['jadwal'] as List<dynamic>)
              .map((e) => LectureScheduleItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      semester: json['semester'] != null
          ? AcademicSemesterInfo.fromJson(json['semester'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'mahasiswa': mahasiswa?.toJson(),
        'jadwal': jadwal.map((e) => e.toJson()).toList(),
        'semester': semester?.toJson(),
      };
}

class LectureScheduleItem {
  final String idSemesterRegistrasi;
  final String idMataKuliah;
  final String namaMataKuliah;
  final String idKelas;
  final String idRuang;
  final String ruang;
  final String namaLokasiKampus;
  final String idPeriode;
  final String idJenisPerkuliahan;
  final String keteranganJenisPerkuliahan;
  final String? tglMulaiKuliah;
  final String? tglAkhirKuliah;
  final ScheduleTimeInfo? waktuKuliah;
  final LecturerInfo? dosen;

  LectureScheduleItem({
    required this.idSemesterRegistrasi,
    required this.idMataKuliah,
    required this.namaMataKuliah,
    required this.idKelas,
    required this.idRuang,
    required this.ruang,
    required this.namaLokasiKampus,
    required this.idPeriode,
    required this.idJenisPerkuliahan,
    required this.keteranganJenisPerkuliahan,
    this.tglMulaiKuliah,
    this.tglAkhirKuliah,
    this.waktuKuliah,
    this.dosen,
  });

  bool get isOnline =>
      idJenisPerkuliahan == 'OL' ||
      keteranganJenisPerkuliahan.toLowerCase().contains('online') ||
      keteranganJenisPerkuliahan.toLowerCase().contains('daring');

  bool get isOffline => !isOnline;

  String get dayName => waktuKuliah?.hari?.namaHari ?? 'Lainnya';

  String get timeRange => waktuKuliah?.ketJam ?? '-';

  String get lecturerDisplayName =>
      dosen?.namaGelarDosen ?? dosen?.namaDosen ?? '-';

  String get locationRoom {
    final r = ruang.isNotEmpty ? ruang : idRuang;
    if (r.isNotEmpty && namaLokasiKampus.isNotEmpty) {
      return '$namaLokasiKampus • $r';
    }
    return r.isNotEmpty ? r : namaLokasiKampus;
  }

  factory LectureScheduleItem.fromJson(Map<String, dynamic> json) {
    return LectureScheduleItem(
      idSemesterRegistrasi: json['id_semester_registrasi']?.toString() ?? '',
      idMataKuliah: json['id_mata_kuliah']?.toString() ?? '',
      namaMataKuliah: json['nama_mata_kuliah']?.toString() ?? '',
      idKelas: json['id_kelas']?.toString() ?? '',
      idRuang: json['id_ruang']?.toString() ?? '',
      ruang: json['ruang']?.toString() ?? '',
      namaLokasiKampus: json['nama_lokasi_kampus']?.toString() ?? '',
      idPeriode: json['id_periode']?.toString() ?? '1',
      idJenisPerkuliahan: json['id_jenis_perkuliahan']?.toString() ?? 'TM',
      keteranganJenisPerkuliahan:
          json['keterangan_jenis_perkuliahan']?.toString() ?? 'Tatap Muka',
      tglMulaiKuliah: json['tgl_mulai_kuliah']?.toString(),
      tglAkhirKuliah: json['tgl_akhir_kuliah']?.toString(),
      waktuKuliah: json['waktu_kuliah'] != null
          ? ScheduleTimeInfo.fromJson(json['waktu_kuliah'] as Map<String, dynamic>)
          : null,
      dosen: json['dosen'] != null
          ? LecturerInfo.fromJson(json['dosen'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_semester_registrasi': idSemesterRegistrasi,
        'id_mata_kuliah': idMataKuliah,
        'nama_mata_kuliah': namaMataKuliah,
        'id_kelas': idKelas,
        'id_ruang': idRuang,
        'ruang': ruang,
        'nama_lokasi_kampus': namaLokasiKampus,
        'id_periode': idPeriode,
        'id_jenis_perkuliahan': idJenisPerkuliahan,
        'keterangan_jenis_perkuliahan': keteranganJenisPerkuliahan,
        'tgl_mulai_kuliah': tglMulaiKuliah,
        'tgl_akhir_kuliah': tglAkhirKuliah,
        'waktu_kuliah': waktuKuliah?.toJson(),
        'dosen': dosen?.toJson(),
      };
}

class ScheduleTimeInfo {
  final String ketJam;
  final ScheduleDayInfo? hari;
  final StudentShift? shift;

  ScheduleTimeInfo({
    required this.ketJam,
    this.hari,
    this.shift,
  });

  factory ScheduleTimeInfo.fromJson(Map<String, dynamic> json) {
    return ScheduleTimeInfo(
      ketJam: json['ket_jam']?.toString() ?? '',
      hari: json['hari'] != null
          ? ScheduleDayInfo.fromJson(json['hari'] as Map<String, dynamic>)
          : null,
      shift: json['shift'] != null
          ? StudentShift.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'ket_jam': ketJam,
        'hari': hari?.toJson(),
        'shift': shift?.toJson(),
      };
}

class ScheduleDayInfo {
  final String idHariWaktuKuliah;
  final String namaHari;

  ScheduleDayInfo({
    required this.idHariWaktuKuliah,
    required this.namaHari,
  });

  factory ScheduleDayInfo.fromJson(Map<String, dynamic> json) {
    return ScheduleDayInfo(
      idHariWaktuKuliah: json['id_hari_waktu_kuliah']?.toString() ?? '',
      namaHari: json['nama_hari']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_hari_waktu_kuliah': idHariWaktuKuliah,
        'nama_hari': namaHari,
      };
}

class LecturerInfo {
  final String idDosen;
  final String namaDosen;
  final String? gelarDepanDosen;
  final String? gelarBelakangDosen;
  final String? namaGelarDosen;

  LecturerInfo({
    required this.idDosen,
    required this.namaDosen,
    this.gelarDepanDosen,
    this.gelarBelakangDosen,
    this.namaGelarDosen,
  });

  factory LecturerInfo.fromJson(Map<String, dynamic> json) {
    return LecturerInfo(
      idDosen: json['id_dosen']?.toString() ?? '',
      namaDosen: json['nama_dosen']?.toString() ?? '',
      gelarDepanDosen: json['gelar_depan_dosen']?.toString(),
      gelarBelakangDosen: json['gelar_belakang_dosen']?.toString(),
      namaGelarDosen: json['nama_gelar_dosen']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id_dosen': idDosen,
        'nama_dosen': namaDosen,
        'gelar_depan_dosen': gelarDepanDosen,
        'gelar_belakang_dosen': gelarBelakangDosen,
        'nama_gelar_dosen': namaGelarDosen,
      };
}
