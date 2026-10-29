import 'package:intl/intl.dart';

class AttendanceCourseItem {
  final String nim;
  final String namaMahasiswa;
  final String idSemesterRegistrasi;
  final String namaSemesterRegistrasi;
  final String idKelas;
  final String idMataKuliah;
  final String namaMataKuliah;
  final String sks;

  AttendanceCourseItem({
    required this.nim,
    required this.namaMahasiswa,
    required this.idSemesterRegistrasi,
    required this.namaSemesterRegistrasi,
    required this.idKelas,
    required this.idMataKuliah,
    required this.namaMataKuliah,
    required this.sks,
  });

  int get sksValue => int.tryParse(sks) ?? 0;

  factory AttendanceCourseItem.fromJson(Map<String, dynamic> json) {
    return AttendanceCourseItem(
      nim: json['nim']?.toString() ?? '',
      namaMahasiswa: json['nama_mahasiswa']?.toString() ?? '',
      idSemesterRegistrasi: json['id_semester_registrasi']?.toString() ?? '',
      namaSemesterRegistrasi: json['nama_semester_registrasi']?.toString() ?? '',
      idKelas: json['id_kelas']?.toString() ?? '',
      idMataKuliah: json['id_mata_kuliah']?.toString() ?? '',
      namaMataKuliah: json['nama_mata_kuliah']?.toString() ?? '',
      sks: json['sks']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() => {
        'nim': nim,
        'nama_mahasiswa': namaMahasiswa,
        'id_semester_registrasi': idSemesterRegistrasi,
        'nama_semester_registrasi': namaSemesterRegistrasi,
        'id_kelas': idKelas,
        'id_mata_kuliah': idMataKuliah,
        'nama_mata_kuliah': namaMataKuliah,
        'sks': sks,
      };
}

class AttendanceMeetingItem {
  final String? jenisPerkuliahan;
  final String idSemesterRegistrasi;
  final String idMataKuliah;
  final String idKelas;
  final String? ketJam;
  final String? tanggalMulai;
  final String? tanggalAkhir;
  final String? presensiStatus;
  final String? presensiDate;
  final String? presensiBy;
  final String dateStatus;

  AttendanceMeetingItem({
    this.jenisPerkuliahan,
    required this.idSemesterRegistrasi,
    required this.idMataKuliah,
    required this.idKelas,
    this.ketJam,
    this.tanggalMulai,
    this.tanggalAkhir,
    this.presensiStatus,
    this.presensiDate,
    this.presensiBy,
    required this.dateStatus,
  });

  bool get isAttended => presensiStatus?.toLowerCase() == 'hadir';
  bool get isAbsent => presensiStatus?.toLowerCase() == 'absen';
  bool get isRecorded => presensiStatus != null && presensiStatus!.isNotEmpty;
  bool get isUpcoming => dateStatus == 'greaterthan' || !isRecorded;
  bool get isOnline => jenisPerkuliahan?.toLowerCase().contains('e-learning') ?? false;

  String get formattedDateRange {
    if (tanggalMulai == null) return '-';
    try {
      final start = DateTime.parse(tanggalMulai!);
      final startStr = DateFormat('d MMM', 'id_ID').format(start);
      if (tanggalAkhir != null) {
        final end = DateTime.parse(tanggalAkhir!);
        final endStr = DateFormat('d MMM yyyy', 'id_ID').format(end);
        return '$startStr - $endStr';
      }
      return startStr;
    } catch (_) {
      return tanggalMulai!;
    }
  }

  String get formattedPresensiTime {
    if (presensiDate == null || presensiDate!.isEmpty) return '-';
    try {
      final dt = DateTime.parse(presensiDate!);
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return presensiDate!;
    }
  }

  factory AttendanceMeetingItem.fromJson(Map<String, dynamic> json) {
    return AttendanceMeetingItem(
      jenisPerkuliahan: json['jenis_perkuliahan']?.toString(),
      idSemesterRegistrasi: json['id_semester_registrasi']?.toString() ?? '',
      idMataKuliah: json['id_mata_kuliah']?.toString() ?? '',
      idKelas: json['id_kelas']?.toString() ?? '',
      ketJam: json['ket_jam']?.toString(),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      tanggalAkhir: json['tanggal_akhir']?.toString(),
      presensiStatus: json['presensi_status']?.toString(),
      presensiDate: json['presensi_date']?.toString(),
      presensiBy: json['presensi_by']?.toString(),
      dateStatus: json['date_status']?.toString() ?? 'lessthan',
    );
  }

  Map<String, dynamic> toJson() => {
        'jenis_perkuliahan': jenisPerkuliahan,
        'id_semester_registrasi': idSemesterRegistrasi,
        'id_mata_kuliah': idMataKuliah,
        'id_kelas': idKelas,
        'ket_jam': ketJam,
        'tanggal_mulai': tanggalMulai,
        'tanggal_akhir': tanggalAkhir,
        'presensi_status': presensiStatus,
        'presensi_date': presensiDate,
        'presensi_by': presensiBy,
        'date_status': dateStatus,
      };
}

class AttendanceSummary {
  final List<AttendanceMeetingItem> meetings;

  AttendanceSummary(this.meetings);

  int get total => meetings.length;
  int get attended => meetings.where((m) => m.isAttended).length;
  int get absent => meetings.where((m) => m.isAbsent).length;
  int get upcoming => meetings.where((m) => m.isUpcoming).length;
  int get recorded => meetings.where((m) => m.isRecorded).length;

  double get percentage {
    if (recorded == 0) return 100.0;
    return (attended / recorded) * 100.0;
  }
}
