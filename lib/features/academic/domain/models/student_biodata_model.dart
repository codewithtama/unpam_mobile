import 'package:intl/intl.dart';

class StudentBiodata {
  final String nim;
  final String namaMahasiswa;
  final String? alamatMahasiswa;
  final String? tempatLahirMahasiswa;
  final String? tanggalLahirMahasiswa;
  final String? noIdentitas;
  final String? noTeleponMahasiswa;
  final String? noHpMahasiswa;
  final String? alamatEmail;
  final String? tanggalDiterima;
  final String? ipkSemesterBerjalan;
  final String? sksSemesterBerjalan;
  final String? semester;
  final String? namaIbuKandung;
  final String? namaOrangTua;
  final String? alamatOrangTua;
  final String? noHpOrangTua;
  final String? pekerjaanOrangTua;
  final String? asalSekolah;
  final String? alamatSekolahAsal;
  final String? nomorSttb;
  final String? tanggalSttb;
  final String? nomorIjazah;
  final String? tanggalIjazah;
  final String? pekerjaan;
  final String? idKelas;
  final StudentShift? shift;
  final StudentStatus? statusMahasiswa;
  final StudentProgramStudi? programStudi;

  StudentBiodata({
    required this.nim,
    required this.namaMahasiswa,
    this.alamatMahasiswa,
    this.tempatLahirMahasiswa,
    this.tanggalLahirMahasiswa,
    this.noIdentitas,
    this.noTeleponMahasiswa,
    this.noHpMahasiswa,
    this.alamatEmail,
    this.tanggalDiterima,
    this.ipkSemesterBerjalan,
    this.sksSemesterBerjalan,
    this.semester,
    this.namaIbuKandung,
    this.namaOrangTua,
    this.alamatOrangTua,
    this.noHpOrangTua,
    this.pekerjaanOrangTua,
    this.asalSekolah,
    this.alamatSekolahAsal,
    this.nomorSttb,
    this.tanggalSttb,
    this.nomorIjazah,
    this.tanggalIjazah,
    this.pekerjaan,
    this.idKelas,
    this.shift,
    this.statusMahasiswa,
    this.programStudi,
  });

  bool get isActive => statusMahasiswa?.idStatusMahasiswa == 'A';

  double get ipkValue {
    if (ipkSemesterBerjalan == null) return 0.0;
    return double.tryParse(ipkSemesterBerjalan!) ?? 0.0;
  }

  int get sksValue {
    if (sksSemesterBerjalan == null) return 0;
    return int.tryParse(sksSemesterBerjalan!) ?? 0;
  }

  String get formattedBirthPlaceAndDate {
    final place = tempatLahirMahasiswa ?? '';
    if (tanggalLahirMahasiswa == null || tanggalLahirMahasiswa!.isEmpty) {
      return place;
    }
    try {
      final dt = DateTime.parse(tanggalLahirMahasiswa!);
      final dateStr = DateFormat('d MMMM yyyy', 'id_ID').format(dt);
      return place.isNotEmpty ? '$place, $dateStr' : dateStr;
    } catch (_) {
      return place.isNotEmpty ? '$place, $tanggalLahirMahasiswa' : (tanggalLahirMahasiswa ?? '');
    }
  }

  String get formattedAcceptedDate {
    if (tanggalDiterima == null || tanggalDiterima!.isEmpty) return '-';
    try {
      final dt = DateTime.parse(tanggalDiterima!);
      return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return tanggalDiterima!;
    }
  }

  factory StudentBiodata.fromJson(Map<String, dynamic> json) {
    return StudentBiodata(
      nim: json['nim']?.toString() ?? '',
      namaMahasiswa: json['nama_mahasiswa']?.toString() ?? '',
      alamatMahasiswa: json['alamat_mahasiswa']?.toString(),
      tempatLahirMahasiswa: json['tempat_lahir_mahasiswa']?.toString(),
      tanggalLahirMahasiswa: json['tanggal_lahir_mahasiswa']?.toString(),
      noIdentitas: json['no_identitas']?.toString(),
      noTeleponMahasiswa: json['no_telepon_mahasiswa']?.toString(),
      noHpMahasiswa: json['no_hp_mahasiswa']?.toString(),
      alamatEmail: json['alamat_email']?.toString(),
      tanggalDiterima: json['tanggal_diterima']?.toString(),
      ipkSemesterBerjalan: json['ipk_semester_berjalan']?.toString(),
      sksSemesterBerjalan: json['sks_semester_berjalan']?.toString(),
      semester: json['semester']?.toString(),
      namaIbuKandung: json['nama_ibu_kandung']?.toString(),
      namaOrangTua: json['nama_orang_tua']?.toString(),
      alamatOrangTua: json['alamat_orang_tua']?.toString(),
      noHpOrangTua: json['no_hp_orang_tua']?.toString(),
      pekerjaanOrangTua: json['pekerjaan_orang_tua']?.toString(),
      asalSekolah: json['asal_sekolah']?.toString(),
      alamatSekolahAsal: json['alamat_sekolah_asal']?.toString(),
      nomorSttb: json['nomor_sttb']?.toString(),
      tanggalSttb: json['tanggal_sttb']?.toString(),
      nomorIjazah: json['nomor_ijazah']?.toString(),
      tanggalIjazah: json['tanggal_ijazah']?.toString(),
      pekerjaan: json['pekerjaan']?.toString(),
      idKelas: json['id_kelas']?.toString(),
      shift: json['shift'] != null ? StudentShift.fromJson(json['shift'] as Map<String, dynamic>) : null,
      statusMahasiswa: json['status_mahasiswa'] != null
          ? StudentStatus.fromJson(json['status_mahasiswa'] as Map<String, dynamic>)
          : null,
      programStudi: json['program_studi'] != null
          ? StudentProgramStudi.fromJson(json['program_studi'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'nim': nim,
        'nama_mahasiswa': namaMahasiswa,
        'alamat_mahasiswa': alamatMahasiswa,
        'tempat_lahir_mahasiswa': tempatLahirMahasiswa,
        'tanggal_lahir_mahasiswa': tanggalLahirMahasiswa,
        'no_identitas': noIdentitas,
        'no_telepon_mahasiswa': noTeleponMahasiswa,
        'no_hp_mahasiswa': noHpMahasiswa,
        'alamat_email': alamatEmail,
        'tanggal_diterima': tanggalDiterima,
        'ipk_semester_berjalan': ipkSemesterBerjalan,
        'sks_semester_berjalan': sksSemesterBerjalan,
        'semester': semester,
        'nama_ibu_kandung': namaIbuKandung,
        'nama_orang_tua': namaOrangTua,
        'alamat_orang_tua': alamatOrangTua,
        'no_hp_orang_tua': noHpOrangTua,
        'pekerjaan_orang_tua': pekerjaanOrangTua,
        'asal_sekolah': asalSekolah,
        'alamat_sekolah_asal': alamatSekolahAsal,
        'nomor_sttb': nomorSttb,
        'tanggal_sttb': tanggalSttb,
        'nomor_ijazah': nomorIjazah,
        'tanggal_ijazah': tanggalIjazah,
        'pekerjaan': pekerjaan,
        'id_kelas': idKelas,
        'shift': shift?.toJson(),
        'status_mahasiswa': statusMahasiswa?.toJson(),
        'program_studi': programStudi?.toJson(),
      };
}

class StudentShift {
  final String idShift;
  final String namaShift;

  StudentShift({required this.idShift, required this.namaShift});

  factory StudentShift.fromJson(Map<String, dynamic> json) {
    return StudentShift(
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

  StudentStatus({required this.idStatusMahasiswa, required this.namaStatusMahasiswa});

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

class StudentProgramStudi {
  final String idProdi;
  final String namaProdi;
  final String? emailProdi;
  final String? websiteProdi;
  final String? alamatUniversitas;
  final String? namaKotaUniversitas;
  final StudentJenjangPendidikan? jenjangPendidikan;
  final StudentFakultas? fakultas;
  final StudentPejabat? pejabat;

  StudentProgramStudi({
    required this.idProdi,
    required this.namaProdi,
    this.emailProdi,
    this.websiteProdi,
    this.alamatUniversitas,
    this.namaKotaUniversitas,
    this.jenjangPendidikan,
    this.fakultas,
    this.pejabat,
  });

  factory StudentProgramStudi.fromJson(Map<String, dynamic> json) {
    return StudentProgramStudi(
      idProdi: json['id_prodi']?.toString() ?? '',
      namaProdi: json['nama_prodi']?.toString() ?? '',
      emailProdi: json['email_prodi']?.toString(),
      websiteProdi: json['website_prodi']?.toString(),
      alamatUniversitas: json['alamat_universitas']?.toString(),
      namaKotaUniversitas: json['nama_kota_universitas']?.toString(),
      jenjangPendidikan: json['jenjang_pendidikan'] != null
          ? StudentJenjangPendidikan.fromJson(json['jenjang_pendidikan'] as Map<String, dynamic>)
          : null,
      fakultas: json['fakultas'] != null
          ? StudentFakultas.fromJson(json['fakultas'] as Map<String, dynamic>)
          : null,
      pejabat: json['pejabat'] != null
          ? StudentPejabat.fromJson(json['pejabat'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_prodi': idProdi,
        'nama_prodi': namaProdi,
        'email_prodi': emailProdi,
        'website_prodi': websiteProdi,
        'alamat_universitas': alamatUniversitas,
        'nama_kota_universitas': namaKotaUniversitas,
        'jenjang_pendidikan': jenjangPendidikan?.toJson(),
        'fakultas': fakultas?.toJson(),
        'pejabat': pejabat?.toJson(),
      };
}

class StudentJenjangPendidikan {
  final String idJenjangPendidikan;
  final String namaJenjangPendidikan;
  final String? singkatanJenjangPendidikan;
  final String? gelarJenjangPendidikan;

  StudentJenjangPendidikan({
    required this.idJenjangPendidikan,
    required this.namaJenjangPendidikan,
    this.singkatanJenjangPendidikan,
    this.gelarJenjangPendidikan,
  });

  factory StudentJenjangPendidikan.fromJson(Map<String, dynamic> json) {
    return StudentJenjangPendidikan(
      idJenjangPendidikan: json['id_jenjang_pendidikan']?.toString() ?? '',
      namaJenjangPendidikan: json['nama_jenjang_pendidikan']?.toString() ?? '',
      singkatanJenjangPendidikan: json['singkatan_jenjang_pendidikan']?.toString(),
      gelarJenjangPendidikan: json['gelar_jenjang_pendidikan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id_jenjang_pendidikan': idJenjangPendidikan,
        'nama_jenjang_pendidikan': namaJenjangPendidikan,
        'singkatan_jenjang_pendidikan': singkatanJenjangPendidikan,
        'gelar_jenjang_pendidikan': gelarJenjangPendidikan,
      };
}

class StudentFakultas {
  final String idFakultas;
  final String namaFakultas;
  final StudentPejabat? pejabat;

  StudentFakultas({
    required this.idFakultas,
    required this.namaFakultas,
    this.pejabat,
  });

  factory StudentFakultas.fromJson(Map<String, dynamic> json) {
    return StudentFakultas(
      idFakultas: json['id_fakultas']?.toString() ?? '',
      namaFakultas: json['nama_fakultas']?.toString() ?? '',
      pejabat: json['pejabat'] != null
          ? StudentPejabat.fromJson(json['pejabat'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_fakultas': idFakultas,
        'nama_fakultas': namaFakultas,
        'pejabat': pejabat?.toJson(),
      };
}

class StudentPejabat {
  final String namaPejabat;
  final String? nidn;
  final String? statusNidn;

  StudentPejabat({
    required this.namaPejabat,
    this.nidn,
    this.statusNidn,
  });

  factory StudentPejabat.fromJson(Map<String, dynamic> json) {
    return StudentPejabat(
      namaPejabat: json['nama_pejabat']?.toString() ?? '',
      nidn: json['nidn']?.toString(),
      statusNidn: json['status_nidn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nama_pejabat': namaPejabat,
        'nidn': nidn,
        'status_nidn': statusNidn,
      };
}
