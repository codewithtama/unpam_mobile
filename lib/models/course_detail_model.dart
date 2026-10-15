class CourseDetailResponse {
  final String kodeCourse;
  final String coursename;
  final bool haveAction;
  final String contentType;
  final List<Student> peserta;
  final List<CourseSection> data;

  CourseDetailResponse({
    required this.kodeCourse,
    required this.coursename,
    required this.haveAction,
    required this.contentType,
    required this.peserta,
    required this.data,
  });

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) {
    return CourseDetailResponse(
      kodeCourse: json['kode_course']?.toString() ?? '',
      coursename: json['coursename']?.toString() ?? '',
      haveAction: json['haveAction'] as bool? ?? false,
      contentType: json['content_type']?.toString() ?? 'COURSE',
      peserta: (json['peserta'] as List<dynamic>?)
              ?.map((item) => Student.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => CourseSection.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kode_course': kodeCourse,
      'coursename': coursename,
      'haveAction': haveAction,
      'content_type': contentType,
      'peserta': peserta.map((x) => x.toJson()).toList(),
      'data': data.map((x) => x.toJson()).toList(),
    };
  }
}

class Student {
  final String nim;
  final String namaMahasiswa;
  final String alamatEmail;
  final String noHpMahasiswa;

  Student({
    required this.nim,
    required this.namaMahasiswa,
    required this.alamatEmail,
    required this.noHpMahasiswa,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      nim: json['nim']?.toString() ?? '',
      namaMahasiswa: json['nama_mahasiswa']?.toString() ?? '',
      alamatEmail: json['alamat_email']?.toString() ?? '',
      noHpMahasiswa: json['no_hp_mahasiswa']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nim': nim,
      'nama_mahasiswa': namaMahasiswa,
      'alamat_email': alamatEmail,
      'no_hp_mahasiswa': noHpMahasiswa,
    };
  }
}

class CourseSection {
  final String kodeSection;
  final int sort;
  final String namaSection;
  final String? namaPertemuan;
  final List<SubSection> subSection;
  final String createdAt;

  CourseSection({
    required this.kodeSection,
    required this.sort,
    required this.namaSection,
    this.namaPertemuan,
    required this.subSection,
    required this.createdAt,
  });

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    return CourseSection(
      kodeSection: json['kode_section']?.toString() ?? '',
      sort: json['sort'] as int? ?? 0,
      namaSection: json['nama_section']?.toString() ?? '',
      namaPertemuan: json['nama_pertemuan']?.toString(),
      subSection: (json['sub_section'] as List<dynamic>?)
              ?.map((item) => SubSection.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kode_section': kodeSection,
      'sort': sort,
      'nama_section': namaSection,
      'nama_pertemuan': namaPertemuan,
      'sub_section': subSection.map((x) => x.toJson()).toList(),
      'createdAt': createdAt,
    };
  }
}

class SubSection {
  final String? id;
  final String tipe;
  final String kodeTemplate;
  final int sort;
  final String judul;
  final String konten;
  final String? link;
  final String? file;
  final QuizSetting? settingQuiz;
  final dynamic settingAvailability;
  bool completion;
  final bool haveAction;
  final String? warningAlert;
  final String createdAt;

  SubSection({
    this.id,
    required this.tipe,
    required this.kodeTemplate,
    required this.sort,
    required this.judul,
    required this.konten,
    this.link,
    this.file,
    this.settingQuiz,
    this.settingAvailability,
    required this.completion,
    required this.haveAction,
    this.warningAlert,
    required this.createdAt,
  });

  factory SubSection.fromJson(Map<String, dynamic> json) {
    return SubSection(
      id: json['id']?.toString(),
      tipe: json['tipe']?.toString() ?? '',
      kodeTemplate: json['kode_template']?.toString() ?? '',
      sort: json['sort'] as int? ?? 0,
      judul: json['judul']?.toString() ?? '',
      konten: json['konten']?.toString() ?? '',
      link: json['link']?.toString(),
      file: json['file']?.toString(),
      settingQuiz: json['setting_quiz'] != null
          ? QuizSetting.fromJson(json['setting_quiz'] as Map<String, dynamic>)
          : null,
      settingAvailability: json['setting_availability'],
      completion: json['completion'] as bool? ?? false,
      haveAction: json['haveAction'] as bool? ?? false,
      warningAlert: json['warningAlert']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipe': tipe,
      'kode_template': kodeTemplate,
      'sort': sort,
      'judul': judul,
      'konten': konten,
      'link': link,
      'file': file,
      'setting_quiz': settingQuiz?.toJson(),
      'setting_availability': settingAvailability,
      'completion': completion,
      'haveAction': haveAction,
      'warningAlert': warningAlert,
      'createdAt': createdAt,
    };
  }

  bool get isTask =>
      tipe == 'ASSIGNMENT' ||
      tipe == 'QUIZ' ||
      tipe == 'FORUM' ||
      tipe == 'QUESIONER';

  String get typeLabel {
    switch (kodeTemplate) {
      case 'PRE_TEST':
        return 'Pretest';
      case 'POST_TEST':
        return 'Posttest';
      case 'PENUGASAN_TERSTRUKTUR':
        return 'Tugas Kuliah';
      case 'FORUM_DISKUSI':
        return 'Forum Diskusi';
      case 'POWER_POINT':
        return 'Slide Presentasi';
      case 'BUKU_ISBN':
        return 'Buku ISBN';
      case 'VIDEO_AJAR':
        return 'Video Ajar';
      case 'LINK_VCON':
        return 'Video Conference';
      case 'KUESIONER':
        return 'Kuesioner';
      case 'RPS':
        return 'Rencana Perkuliahan (RPS)';
      case 'MATERI_LAINNYA':
        return 'Materi';
      case 'ARTIKEL_RISET':
        return 'Artikel Riset';
      default:
        return tipe;
    }
  }
}

class QuizSetting {
  final String tipeQuiz;
  final bool onePagePerQuestion;
  final int duration;
  final bool shuffleSoal;
  final bool shuffleJawaban;

  QuizSetting({
    required this.tipeQuiz,
    required this.onePagePerQuestion,
    required this.duration,
    required this.shuffleSoal,
    required this.shuffleJawaban,
  });

  factory QuizSetting.fromJson(Map<String, dynamic> json) {
    return QuizSetting(
      tipeQuiz: json['tipe_quiz']?.toString() ?? 'MULTIPLE_CHOICE',
      onePagePerQuestion: json['one_page_per_question'] as bool? ?? true,
      duration: json['duration'] as int? ?? 60,
      shuffleSoal: json['shuffle_soal'] as bool? ?? false,
      shuffleJawaban: json['shuffle_jawaban'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipe_quiz': tipeQuiz,
      'one_page_per_question': onePagePerQuestion,
      'duration': duration,
      'shuffle_soal': shuffleSoal,
      'shuffle_jawaban': shuffleJawaban,
    };
  }
}
