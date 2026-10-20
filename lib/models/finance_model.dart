import 'package:intl/intl.dart';

class SemesterItem {
  final String idSemesterRegistrasi;
  final String namaSemesterRegistrasi;
  final String? flags;
  final String? flagsKeuangan;
  final String? flagsKuliah;
  final String? flagsSp;
  final String? flagsPmb;
  final String? flagsRemedial;
  final String? flagsWk;
  final String? flagsUaps;
  final String? noUrut;

  SemesterItem({
    required this.idSemesterRegistrasi,
    required this.namaSemesterRegistrasi,
    this.flags,
    this.flagsKeuangan,
    this.flagsKuliah,
    this.flagsSp,
    this.flagsPmb,
    this.flagsRemedial,
    this.flagsWk,
    this.flagsUaps,
    this.noUrut,
  });

  bool get isActive => flags == '1';
  bool get hasFinance => flagsKeuangan == '1';
  bool get isShortSemester => (flagsSp == '1') || namaSemesterRegistrasi.toUpperCase().contains('SP');

  String get displayName {
    if (namaSemesterRegistrasi.isEmpty) return idSemesterRegistrasi;
    return namaSemesterRegistrasi;
  }

  factory SemesterItem.fromJson(Map<String, dynamic> json) {
    return SemesterItem(
      idSemesterRegistrasi: json['id_semester_registrasi']?.toString() ?? '',
      namaSemesterRegistrasi: json['nama_semester_registrasi']?.toString() ?? '',
      flags: json['flags']?.toString(),
      flagsKeuangan: json['flags_keuangan']?.toString(),
      flagsKuliah: json['flags_kuliah']?.toString(),
      flagsSp: json['flags_sp']?.toString(),
      flagsPmb: json['flags_pmb']?.toString(),
      flagsRemedial: json['flags_remedial']?.toString(),
      flagsWk: json['flags_wk']?.toString(),
      flagsUaps: json['flags_uaps']?.toString(),
      noUrut: json['no_urut']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id_semester_registrasi': idSemesterRegistrasi,
        'nama_semester_registrasi': namaSemesterRegistrasi,
        'flags': flags,
        'flags_keuangan': flagsKeuangan,
        'flags_kuliah': flagsKuliah,
        'flags_sp': flagsSp,
        'flags_pmb': flagsPmb,
        'flags_remedial': flagsRemedial,
        'flags_wk': flagsWk,
        'flags_uaps': flagsUaps,
        'no_urut': noUrut,
      };
}

class Shift {
  final String idShift;
  final String namaShift;

  Shift({
    required this.idShift,
    required this.namaShift,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      idShift: json['id_shift']?.toString() ?? '',
      namaShift: json['nama_shift']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_shift': idShift,
        'nama_shift': namaShift,
      };
}

class StudentStatus {
  final String idStatusMahasiswa;
  final String namaStatusMahasiswa;

  StudentStatus({
    required this.idStatusMahasiswa,
    required this.namaStatusMahasiswa,
  });

  factory StudentStatus.fromJson(Map<String, dynamic> json) {
    return StudentStatus(
      idStatusMahasiswa: json['id_status_mahasiswa']?.toString() ?? '',
      namaStatusMahasiswa: json['nama_status_mahasiswa']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_status_mahasiswa': idStatusMahasiswa,
        'nama_status_mahasiswa': namaStatusMahasiswa,
      };
}

class Faculty {
  final String idFakultas;
  final String namaFakultas;

  Faculty({
    required this.idFakultas,
    required this.namaFakultas,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      idFakultas: json['id_fakultas']?.toString() ?? '',
      namaFakultas: json['nama_fakultas']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_fakultas': idFakultas,
        'nama_fakultas': namaFakultas,
      };
}

class EducationDegree {
  final String idJenjangPendidikan;
  final String namaJenjangPendidikan;
  final String singkatanJenjangPendidikan;
  final String gelarJenjangPendidikan;

  EducationDegree({
    required this.idJenjangPendidikan,
    required this.namaJenjangPendidikan,
    required this.singkatanJenjangPendidikan,
    required this.gelarJenjangPendidikan,
  });

  factory EducationDegree.fromJson(Map<String, dynamic> json) {
    return EducationDegree(
      idJenjangPendidikan: json['id_jenjang_pendidikan']?.toString() ?? '',
      namaJenjangPendidikan: json['nama_jenjang_pendidikan']?.toString() ?? '',
      singkatanJenjangPendidikan: json['singkatan_jenjang_pendidikan']?.toString() ?? '',
      gelarJenjangPendidikan: json['gelar_jenjang_pendidikan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_jenjang_pendidikan': idJenjangPendidikan,
        'nama_jenjang_pendidikan': namaJenjangPendidikan,
        'singkatan_jenjang_pendidikan': singkatanJenjangPendidikan,
        'gelar_jenjang_pendidikan': gelarJenjangPendidikan,
      };
}

class StudyProgram {
  final String idProdi;
  final String namaProdi;
  final String? emailProdi;
  final String? websiteProdi;
  final Faculty? faculty;
  final EducationDegree? educationDegree;

  StudyProgram({
    required this.idProdi,
    required this.namaProdi,
    this.emailProdi,
    this.websiteProdi,
    this.faculty,
    this.educationDegree,
  });

  factory StudyProgram.fromJson(Map<String, dynamic> json) {
    return StudyProgram(
      idProdi: json['id_prodi']?.toString() ?? '',
      namaProdi: json['nama_prodi']?.toString() ?? '',
      emailProdi: json['email_prodi']?.toString(),
      websiteProdi: json['website_prodi']?.toString(),
      faculty: json['fakultas'] != null ? Faculty.fromJson(json['fakultas']) : null,
      educationDegree: json['jenjang_pendidikan'] != null
          ? EducationDegree.fromJson(json['jenjang_pendidikan'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_prodi': idProdi,
        'nama_prodi': namaProdi,
        'email_prodi': emailProdi,
        'website_prodi': websiteProdi,
        'fakultas': faculty?.toJson(),
        'jenjang_pendidikan': educationDegree?.toJson(),
      };
}

class StudentProfile {
  final String nim;
  final String namaMahasiswa;
  final String semester;
  final String idKelas;
  final String ipkSemesterBerjalan;
  final String sksSemesterBerjalan;
  final String alamatMahasiswa;
  final String tempatLahirMahasiswa;
  final String tanggalLahirMahasiswa;
  final String noIdentitas;
  final String noHpMahasiswa;
  final String alamatEmail;
  final String asalSekolah;
  final String alamatSekolahAsal;
  final String namaOrangTua;
  final String namaIbuKandung;
  final String pekerjaanOrangTua;
  final String noHpOrangTua;
  final String pekerjaan;
  final Shift? shift;
  final StudentStatus? studentStatus;
  final StudyProgram? studyProgram;

  StudentProfile({
    required this.nim,
    required this.namaMahasiswa,
    required this.semester,
    required this.idKelas,
    required this.ipkSemesterBerjalan,
    required this.sksSemesterBerjalan,
    required this.alamatMahasiswa,
    required this.tempatLahirMahasiswa,
    required this.tanggalLahirMahasiswa,
    required this.noIdentitas,
    required this.noHpMahasiswa,
    required this.alamatEmail,
    required this.asalSekolah,
    required this.alamatSekolahAsal,
    required this.namaOrangTua,
    required this.namaIbuKandung,
    required this.pekerjaanOrangTua,
    required this.noHpOrangTua,
    required this.pekerjaan,
    this.shift,
    this.studentStatus,
    this.studyProgram,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      nim: json['nim']?.toString() ?? '',
      namaMahasiswa: json['nama_mahasiswa']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      idKelas: json['id_kelas']?.toString() ?? '',
      ipkSemesterBerjalan: json['ipk_semester_berjalan']?.toString() ?? '0.00',
      sksSemesterBerjalan: json['sks_semester_berjalan']?.toString() ?? '0',
      alamatMahasiswa: json['alamat_mahasiswa']?.toString() ?? '',
      tempatLahirMahasiswa: json['tempat_lahir_mahasiswa']?.toString() ?? '',
      tanggalLahirMahasiswa: json['tanggal_lahir_mahasiswa']?.toString() ?? '',
      noIdentitas: json['no_identitas']?.toString() ?? '',
      noHpMahasiswa: json['no_hp_mahasiswa']?.toString() ?? '',
      alamatEmail: json['alamat_email']?.toString() ?? '',
      asalSekolah: json['asal_sekolah']?.toString() ?? '',
      alamatSekolahAsal: json['alamat_sekolah_asal']?.toString() ?? '',
      namaOrangTua: json['nama_orang_tua']?.toString() ?? '',
      namaIbuKandung: json['nama_ibu_kandung']?.toString() ?? '',
      pekerjaanOrangTua: json['pekerjaan_orang_tua']?.toString() ?? '',
      noHpOrangTua: json['no_hp_orang_tua']?.toString() ?? '',
      pekerjaan: json['pekerjaan']?.toString() ?? '',
      shift: json['shift'] != null ? Shift.fromJson(json['shift']) : null,
      studentStatus: json['status_mahasiswa'] != null
          ? StudentStatus.fromJson(json['status_mahasiswa'])
          : null,
      studyProgram: json['program_studi'] != null
          ? StudyProgram.fromJson(json['program_studi'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'nim': nim,
        'nama_mahasiswa': namaMahasiswa,
        'semester': semester,
        'id_kelas': idKelas,
        'ipk_semester_berjalan': ipkSemesterBerjalan,
        'sks_semester_berjalan': sksSemesterBerjalan,
        'alamat_mahasiswa': alamatMahasiswa,
        'tempat_lahir_mahasiswa': tempatLahirMahasiswa,
        'tanggal_lahir_mahasiswa': tanggalLahirMahasiswa,
        'no_identitas': noIdentitas,
        'no_hp_mahasiswa': noHpMahasiswa,
        'alamat_email': alamatEmail,
        'asal_sekolah': asalSekolah,
        'alamat_sekolah_asal': alamatSekolahAsal,
        'nama_orang_tua': namaOrangTua,
        'nama_ibu_kandung': namaIbuKandung,
        'pekerjaan_orang_tua': pekerjaanOrangTua,
        'no_hp_orang_tua': noHpOrangTua,
        'pekerjaan': pekerjaan,
        'shift': shift?.toJson(),
        'status_mahasiswa': studentStatus?.toJson(),
        'program_studi': studyProgram?.toJson(),
      };
}

class BillingItem {
  final String noTagihan;
  final String nomorUrut;
  final String keterangan;
  final int totalTagihan;
  final String? channel;
  final String? tanggalBayar;
  final String? namaTempatBayar;
  final String status;

  BillingItem({
    required this.noTagihan,
    required this.nomorUrut,
    required this.keterangan,
    required this.totalTagihan,
    this.channel,
    this.tanggalBayar,
    this.namaTempatBayar,
    required this.status,
  });

  bool get isPaid => status.toUpperCase().trim() == 'LUNAS';

  String get formattedTotal {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(totalTagihan);
  }

  String? get formattedTanggalBayar {
    if (tanggalBayar == null || tanggalBayar!.isEmpty) return null;
    try {
      final dt = DateTime.parse(tanggalBayar!.split('.').first);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return tanggalBayar;
    }
  }

  factory BillingItem.fromJson(Map<String, dynamic> json) {
    int parsedTotal = 0;
    final rawTotal = json['total_tagihan'];
    if (rawTotal is num) {
      parsedTotal = rawTotal.toInt();
    } else if (rawTotal is String) {
      parsedTotal = int.tryParse(rawTotal) ?? 0;
    }

    return BillingItem(
      noTagihan: json['no_tagihan']?.toString() ?? '',
      nomorUrut: json['nomor_urut']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      totalTagihan: parsedTotal,
      channel: json['channel']?.toString(),
      tanggalBayar: json['tanggal_bayar']?.toString(),
      namaTempatBayar: json['nama_tempat_bayar']?.toString(),
      status: json['status']?.toString() ?? 'BELUM LUNAS',
    );
  }

  Map<String, dynamic> toJson() => {
        'no_tagihan': noTagihan,
        'nomor_urut': nomorUrut,
        'keterangan': keterangan,
        'total_tagihan': totalTagihan,
        'channel': channel,
        'tanggal_bayar': tanggalBayar,
        'nama_tempat_bayar': namaTempatBayar,
        'status': status,
      };
}

class FinanceResponse {
  final StudentProfile student;
  final List<BillingItem> billings;
  final List<BillingItem> otherBillings;
  final List<BillingItem> spBillings;
  final SemesterItem? semester;

  FinanceResponse({
    required this.student,
    required this.billings,
    required this.otherBillings,
    required this.spBillings,
    this.semester,
  });

  int get totalBillingAmount {
    return billings.fold(0, (sum, item) => sum + item.totalTagihan);
  }

  int get totalPaidAmount {
    return billings
        .where((item) => item.isPaid)
        .fold(0, (sum, item) => sum + item.totalTagihan);
  }

  int get totalUnpaidAmount {
    return billings
        .where((item) => !item.isPaid)
        .fold(0, (sum, item) => sum + item.totalTagihan);
  }

  double get paidPercentage {
    final total = totalBillingAmount;
    if (total == 0) return 0.0;
    return (totalPaidAmount / total).clamp(0.0, 1.0);
  }

  String formatCurrency(int amount) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(amount);
  }

  factory FinanceResponse.fromJson(Map<String, dynamic> json) {
    return FinanceResponse(
      student: StudentProfile.fromJson(json['mahasiswa'] ?? {}),
      billings: (json['tagihan'] as List<dynamic>? ?? [])
          .map((e) => BillingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      otherBillings: (json['tagihan_lainnya'] as List<dynamic>? ?? [])
          .map((e) => BillingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      spBillings: (json['tagihan_sp'] as List<dynamic>? ?? [])
          .map((e) => BillingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      semester: json['semester'] != null
          ? SemesterItem.fromJson(json['semester'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'mahasiswa': student.toJson(),
        'tagihan': billings.map((e) => e.toJson()).toList(),
        'tagihan_lainnya': otherBillings.map((e) => e.toJson()).toList(),
        'tagihan_sp': spBillings.map((e) => e.toJson()).toList(),
        'semester': semester?.toJson(),
      };
}
