class UserCourseResponse {
  final List<CourseItem> data;
  final int limit;
  final int page;
  final int total;
  final String semester;

  UserCourseResponse({
    required this.data,
    required this.limit,
    required this.page,
    required this.total,
    required this.semester,
  });

  factory UserCourseResponse.fromJson(Map<String, dynamic> json) {
    return UserCourseResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => CourseItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      limit: json['limit'] as int? ?? 12,
      page: json['page'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
      semester: json['semester']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((x) => x.toJson()).toList(),
      'limit': limit,
      'page': page,
      'total': total,
      'semester': semester,
    };
  }
}

class CourseItem {
  final String id;
  final String kodeCourse;
  final String coursename;
  final String shortname;
  final String idMataKuliah;
  final String idProdi;
  final String idSemesterRegistrasi;
  final String idPeriode;
  final String idKelas;
  final String idShift;
  final String idHariWaktuKuliah;
  final String namaHari;
  final String namaMataKuliah;
  final int sks;
  final String createdAt;
  final String namaDosen;

  CourseItem({
    required this.id,
    required this.kodeCourse,
    required this.coursename,
    required this.shortname,
    required this.idMataKuliah,
    required this.idProdi,
    required this.idSemesterRegistrasi,
    required this.idPeriode,
    required this.idKelas,
    required this.idShift,
    required this.idHariWaktuKuliah,
    required this.namaHari,
    required this.namaMataKuliah,
    required this.sks,
    required this.createdAt,
    required this.namaDosen,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: json['id']?.toString() ?? '',
      kodeCourse: json['kode_course']?.toString() ?? '',
      coursename: json['coursename']?.toString() ?? '',
      shortname: json['shortname']?.toString() ?? '',
      idMataKuliah: json['id_mata_kuliah']?.toString() ?? '',
      idProdi: json['id_prodi']?.toString() ?? '',
      idSemesterRegistrasi: json['id_semester_registrasi']?.toString() ?? '',
      idPeriode: json['id_periode']?.toString() ?? '',
      idKelas: json['id_kelas']?.toString() ?? '',
      idShift: json['id_shift']?.toString() ?? '',
      idHariWaktuKuliah: json['id_hari_waktu_kuliah']?.toString() ?? '',
      namaHari: json['nama_hari']?.toString() ?? '',
      namaMataKuliah: json['nama_mata_kuliah']?.toString() ?? '',
      sks: json['sks'] as int? ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
      namaDosen: json['nama_dosen']?.toString() ?? 'Dosen Pengampu',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_course': kodeCourse,
      'coursename': coursename,
      'shortname': shortname,
      'id_mata_kuliah': idMataKuliah,
      'id_prodi': idProdi,
      'id_semester_registrasi': idSemesterRegistrasi,
      'id_periode': idPeriode,
      'id_kelas': idKelas,
      'id_shift': idShift,
      'id_hari_waktu_kuliah': idHariWaktuKuliah,
      'nama_hari': namaHari,
      'nama_mata_kuliah': namaMataKuliah,
      'sks': sks,
      'createdAt': createdAt,
      'nama_dosen': namaDosen,
    };
  }
}
