import 'student_biodata_model.dart';

class AcademicGradesResponse {
  final String ipk;
  final StudentBiodata? mahasiswa;
  final List<CourseGradeItem> rangkuman;
  final GradeSummary? mutu;
  final AcademicSemesterInfo? semester;

  AcademicGradesResponse({
    required this.ipk,
    this.mahasiswa,
    required this.rangkuman,
    this.mutu,
    this.semester,
  });

  double get ipkValue => double.tryParse(ipk) ?? 0.0;

  Map<int, List<CourseGradeItem>> get groupedBySemester {
    final Map<int, List<CourseGradeItem>> groups = {};
    for (final item in rangkuman) {
      final sem = int.tryParse(item.isemester) ?? 0;
      groups.putIfAbsent(sem, () => []).add(item);
    }
    final sortedKeys = groups.keys.toList()..sort();
    final Map<int, List<CourseGradeItem>> sorted = {};
    for (final key in sortedKeys) {
      sorted[key] = groups[key]!;
    }
    return sorted;
  }

  int get totalSksAcrossAll {
    return rangkuman.fold<int>(0, (sum, item) => sum + item.sks);
  }

  double calculateSemesterGpa(int semesterNum) {
    final courses = groupedBySemester[semesterNum];
    if (courses == null || courses.isEmpty) return 0.0;
    int totalSks = 0;
    double totalPoints = 0.0;
    for (final c in courses) {
      totalSks += c.sks;
      totalPoints += c.totalGradePoint;
    }
    if (totalSks == 0) return 0.0;
    return totalPoints / totalSks;
  }

  int calculateSemesterSks(int semesterNum) {
    final courses = groupedBySemester[semesterNum];
    if (courses == null) return 0;
    return courses.fold<int>(0, (sum, item) => sum + item.sks);
  }

  factory AcademicGradesResponse.fromJson(Map<String, dynamic> json) {
    return AcademicGradesResponse(
      ipk: json['ipk']?.toString() ?? '0.00',
      mahasiswa: json['mahasiswa'] != null
          ? StudentBiodata.fromJson(json['mahasiswa'] as Map<String, dynamic>)
          : null,
      rangkuman: json['rangkuman'] is List
          ? (json['rangkuman'] as List<dynamic>)
              .map((e) => CourseGradeItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      mutu: json['mutu'] != null
          ? GradeSummary.fromJson(json['mutu'] as Map<String, dynamic>)
          : null,
      semester: json['semester'] != null
          ? AcademicSemesterInfo.fromJson(json['semester'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'ipk': ipk,
        'mahasiswa': mahasiswa?.toJson(),
        'rangkuman': rangkuman.map((e) => e.toJson()).toList(),
        'mutu': mutu?.toJson(),
        'semester': semester?.toJson(),
      };
}

class CourseGradeItem {
  final String nim;
  final String isemester;
  final String idmtk;
  final String idKelas;
  final String snama;
  final String isks;
  final String fmasa;
  final String fgrade;
  final String ambilMutu;
  final String imutu;
  final String? kelompokMtk;
  final int? kuesioner;

  CourseGradeItem({
    required this.nim,
    required this.isemester,
    required this.idmtk,
    required this.idKelas,
    required this.snama,
    required this.isks,
    required this.fmasa,
    required this.fgrade,
    required this.ambilMutu,
    required this.imutu,
    this.kelompokMtk,
    this.kuesioner,
  });

  int get sks => int.tryParse(isks) ?? 0;
  double get gradePoint => double.tryParse(ambilMutu) ?? 0.0;
  double get totalGradePoint => double.tryParse(imutu) ?? 0.0;
  int get semesterNumber => int.tryParse(isemester) ?? 0;

  bool get isPassed {
    final g = fgrade.toUpperCase().trim();
    return g.isNotEmpty && g != 'E' && g != 'D' && g != 'TL';
  }

  factory CourseGradeItem.fromJson(Map<String, dynamic> json) {
    return CourseGradeItem(
      nim: json['nim']?.toString() ?? '',
      isemester: json['isemester']?.toString() ?? '1',
      idmtk: json['idmtk']?.toString() ?? '',
      idKelas: json['id_kelas']?.toString() ?? '',
      snama: json['snama']?.toString() ?? '',
      isks: json['isks']?.toString() ?? '0',
      fmasa: json['fmasa']?.toString() ?? '',
      fgrade: json['fgrade']?.toString() ?? '-',
      ambilMutu: json['ambil_mutu']?.toString() ?? '0.00',
      imutu: json['imutu']?.toString() ?? '0.00',
      kelompokMtk: json['kelompok_mtk']?.toString(),
      kuesioner: json['kuesioner'] is int
          ? json['kuesioner'] as int
          : int.tryParse(json['kuesioner']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'nim': nim,
        'isemester': isemester,
        'idmtk': idmtk,
        'id_kelas': idKelas,
        'snama': snama,
        'isks': isks,
        'fmasa': fmasa,
        'fgrade': fgrade,
        'ambil_mutu': ambilMutu,
        'imutu': imutu,
        'kelompok_mtk': kelompokMtk,
        'kuesioner': kuesioner,
      };
}

class GradeSummary {
  final String itotalskslulus;
  final String itotalmutululus;
  final String itotalsksambil;
  final String itotalmutuambil;

  GradeSummary({
    required this.itotalskslulus,
    required this.itotalmutululus,
    required this.itotalsksambil,
    required this.itotalmutuambil,
  });

  int get totalSksPassed => int.tryParse(itotalskslulus) ?? 0;
  int get totalSksTaken => int.tryParse(itotalsksambil) ?? 0;
  double get totalMutuPassed => double.tryParse(itotalmutululus) ?? 0.0;
  double get totalMutuTaken => double.tryParse(itotalmutuambil) ?? 0.0;

  factory GradeSummary.fromJson(Map<String, dynamic> json) {
    return GradeSummary(
      itotalskslulus: json['itotalskslulus']?.toString() ?? '0',
      itotalmutululus: json['itotalmutululus']?.toString() ?? '0.00',
      itotalsksambil: json['itotalsksambil']?.toString() ?? '0',
      itotalmutuambil: json['itotalmutuambil']?.toString() ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() => {
        'itotalskslulus': itotalskslulus,
        'itotalmutululus': itotalmutululus,
        'itotalsksambil': itotalsksambil,
        'itotalmutuambil': itotalmutuambil,
      };
}

class AcademicSemesterInfo {
  final String idSemesterRegistrasi;
  final String namaSemesterRegistrasi;

  AcademicSemesterInfo({
    required this.idSemesterRegistrasi,
    required this.namaSemesterRegistrasi,
  });

  factory AcademicSemesterInfo.fromJson(Map<String, dynamic> json) {
    return AcademicSemesterInfo(
      idSemesterRegistrasi: json['id_semester_registrasi']?.toString() ?? '',
      namaSemesterRegistrasi: json['nama_semester_registrasi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_semester_registrasi': idSemesterRegistrasi,
        'nama_semester_registrasi': namaSemesterRegistrasi,
      };
}
