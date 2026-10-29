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
  final String jenisPerkuliahan; // e.g. "Tatap Muka", "Online", dll.
  final String idJenisPerkuliahan; // e.g. "TM", "OL"

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
    this.jenisPerkuliahan = 'Tatap Muka',
    this.idJenisPerkuliahan = 'TM',
  });

  bool get isOnline =>
      idJenisPerkuliahan.trim().toUpperCase() == 'OL' ||
      jenisPerkuliahan.toLowerCase().contains('online') ||
      jenisPerkuliahan.toLowerCase().contains('daring') ||
      ruang.toLowerCase().contains('online') ||
      ruang.toLowerCase().contains('daring') ||
      namaMataKuliah.toLowerCase().contains('online') ||
      namaMataKuliah.toLowerCase().contains('e-learning');

  bool get isOffline => !isOnline;

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    // 1. Tangani nested object jika payload berasal langsung dari API MyUnpam (/api/jadwal-kuliah)
    final waktu = json['waktu_kuliah'] is Map ? json['waktu_kuliah'] as Map : {};
    final hariObj = waktu['hari'] is Map ? waktu['hari'] as Map : {};
    final dosenObj = json['dosen'] is Map ? json['dosen'] as Map : {};
    final mkObj = json['mata_kuliah'] is Map ? json['mata_kuliah'] as Map : {};

    // 2. Ekstraksi nama mata kuliah & kode secara aman
    String namaMk = '';
    if (json['namaMataKuliah'] is String) {
      namaMk = json['namaMataKuliah'] as String;
    } else if (json['nama_mata_kuliah'] is String) {
      namaMk = json['nama_mata_kuliah'] as String;
    } else if (mkObj['nama_mata_kuliah'] is String) {
      namaMk = mkObj['nama_mata_kuliah'] as String;
    } else if (json['matakuliah'] is String) {
      namaMk = json['matakuliah'] as String;
    }
    namaMk = namaMk.trim();

    String kodeMk = '';
    if (json['kode'] is String) {
      kodeMk = json['kode'] as String;
    } else if (json['id_mata_kuliah'] is String) {
      kodeMk = json['id_mata_kuliah'] as String;
    } else if (mkObj['id_mata_kuliah'] is String) {
      kodeMk = mkObj['id_mata_kuliah'] as String;
    } else if (json['kode_mk'] is String) {
      kodeMk = json['kode_mk'] as String;
    }
    kodeMk = kodeMk.trim();

    // 3. Ekstraksi dosen secara aman (bisa string atau Map)
    String namaDosen = '';
    if (json['dosen'] is String) {
      namaDosen = json['dosen'] as String;
    } else if (dosenObj['nama_gelar_dosen'] is String) {
      namaDosen = dosenObj['nama_gelar_dosen'] as String;
    } else if (dosenObj['nama_dosen'] is String) {
      namaDosen = dosenObj['nama_dosen'] as String;
    } else if (json['nama_dosen'] is String) {
      namaDosen = json['nama_dosen'] as String;
    }
    namaDosen = namaDosen.trim();

    // 4. Ekstraksi ruang & kelas secara aman
    String ruang = '';
    if (json['ruang'] is String) {
      ruang = json['ruang'] as String;
    } else if (json['id_ruang'] is String) {
      ruang = json['id_ruang'] as String;
    } else if (json['nama_lokasi_kampus'] is String) {
      ruang = json['nama_lokasi_kampus'] as String;
    }
    ruang = ruang.trim();

    String kelas = '';
    if (json['kelas'] is String) {
      kelas = json['kelas'] as String;
    } else if (json['id_kelas'] is String) {
      kelas = json['id_kelas'] as String;
    }
    kelas = kelas.trim();

    // 5. Ekstraksi nama hari & hariIndex (1=Senin ... 7=Minggu)
    String namaHariRaw = '';
    if (json['hari'] is String) {
      namaHariRaw = json['hari'] as String;
    } else if (waktu['nama_hari'] is String) {
      namaHariRaw = waktu['nama_hari'] as String;
    } else if (hariObj['nama_hari'] is String) {
      namaHariRaw = hariObj['nama_hari'] as String;
    } else if (json['nama_hari'] is String) {
      namaHariRaw = json['nama_hari'] as String;
    }
    namaHariRaw = namaHariRaw.trim();

    var rawHariId = 0;
    if (json['hariIndex'] is int) {
      rawHariId = json['hariIndex'] as int;
    } else {
      final idStr = json['id_hari_waktu_kuliah']?.toString() ??
          waktu['id_hari_waktu_kuliah']?.toString() ??
          hariObj['id_hari_waktu_kuliah']?.toString() ??
          '';
      rawHariId = int.tryParse(idStr) ?? 0;
    }

    final hariNormalized = _normalizeHari(namaHariRaw, rawHariId);
    final finalHariIndex = rawHariId > 0 ? rawHariId : _hariToNumber(hariNormalized);

    // 6. Ekstraksi jam mulai & jam selesai
    String jMulai = (json['jamMulai'] as String? ?? '').trim();
    String jSelesai = (json['jamSelesai'] as String? ?? '').trim();

    String rawKetJam = '';
    if (waktu['ket_jam'] is String) {
      rawKetJam = waktu['ket_jam'] as String;
    } else if (json['ket_jam'] is String) {
      rawKetJam = json['ket_jam'] as String;
    } else if (json['jam'] is String) {
      rawKetJam = json['jam'] as String;
    } else if (json['waktu'] is String) {
      rawKetJam = json['waktu'] as String;
    }
    rawKetJam = rawKetJam.trim();

    if (rawKetJam.isNotEmpty && (jMulai.isEmpty || jSelesai.isEmpty)) {
      final parts = rawKetJam.split(RegExp(r'\s*[-–—]\s*'));
      if (parts.length >= 2) {
        jMulai = parts[0].replaceAll('.', ':').trim();
        jSelesai = parts[1].replaceAll('.', ':').trim();
      } else if (parts.isNotEmpty) {
        jMulai = parts[0].replaceAll('.', ':').trim();
      }
    }

    // 7. Ekstraksi mode jenis perkuliahan (Tatap Muka vs Online)
    String idJenis = '';
    if (json['id_jenis_perkuliahan'] is String) {
      idJenis = (json['id_jenis_perkuliahan'] as String).trim();
    } else if (json['idJenisPerkuliahan'] is String) {
      idJenis = (json['idJenisPerkuliahan'] as String).trim();
    }

    String ketJenis = '';
    if (json['keterangan_jenis_perkuliahan'] is String) {
      ketJenis = (json['keterangan_jenis_perkuliahan'] as String).trim();
    } else if (json['jenisPerkuliahan'] is String) {
      ketJenis = (json['jenisPerkuliahan'] as String).trim();
    } else if (json['jenis_perkuliahan'] is String) {
      ketJenis = (json['jenis_perkuliahan'] as String).trim();
    } else if (json['jenis'] is String) {
      ketJenis = (json['jenis'] as String).trim();
    }

    if (ketJenis.isEmpty) {
      if (idJenis.toUpperCase() == 'OL' ||
          ruang.toLowerCase().contains('online') ||
          ruang.toLowerCase().contains('daring') ||
          namaMk.toLowerCase().contains('online') ||
          namaMk.toLowerCase().contains('e-learning')) {
        ketJenis = 'Online';
        if (idJenis.isEmpty) idJenis = 'OL';
      } else {
        ketJenis = 'Tatap Muka';
        if (idJenis.isEmpty) idJenis = 'TM';
      }
    }

    return CourseSchedule(
      kode: kodeMk,
      namaMataKuliah: namaMk,
      hari: hariNormalized,
      jamMulai: jMulai,
      jamSelesai: jSelesai,
      ruang: ruang,
      dosen: namaDosen,
      kelas: kelas,
      hariIndex: finalHariIndex,
      jenisPerkuliahan: ketJenis,
      idJenisPerkuliahan: idJenis,
    );
  }

  static String _normalizeHari(String input, int index) {
    if (input.isNotEmpty) {
      final lower = input.toLowerCase();
      if (lower.contains('sen')) return 'Senin';
      if (lower.contains('sel')) return 'Selasa';
      if (lower.contains('rab')) return 'Rabu';
      if (lower.contains('kam')) return 'Kamis';
      if (lower.contains('jum')) return 'Jumat';
      if (lower.contains('sab')) return 'Sabtu';
      if (lower.contains('min')) return 'Minggu';
    }
    switch (index) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return input;
    }
  }

  static int _hariToNumber(String hari) {
    final lower = hari.toLowerCase();
    if (lower.contains('sen')) return 1;
    if (lower.contains('sel')) return 2;
    if (lower.contains('rab')) return 3;
    if (lower.contains('kam')) return 4;
    if (lower.contains('jum')) return 5;
    if (lower.contains('sab')) return 6;
    if (lower.contains('min')) return 7;
    return 0;
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
        'jenisPerkuliahan': jenisPerkuliahan,
        'idJenisPerkuliahan': idJenisPerkuliahan,
      };

  static List<CourseSchedule> listFromJson(String jsonStr) {
    try {
      var raw = jsonStr.trim();
      // Tangani jika string terbungkus kutip ganda akibat string serialization
      if (raw.startsWith('"') && raw.endsWith('"')) {
        try {
          raw = jsonDecode(raw) as String;
        } catch (_) {}
      }

      final decoded = jsonDecode(raw);
      List<dynamic> list;

      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        // Cek struktur respons API MyUnpam /api/jadwal-kuliah -> {"mahasiswa": ..., "jadwal": [...]}
        if (decoded['jadwal'] is List) {
          list = decoded['jadwal'] as List;
        } else if (decoded['data'] is List) {
          // Cek struktur paginasi /api/jadwal-kuliah/daftar -> {"data": [...]}
          list = decoded['data'] as List;
        } else if (decoded['schedules'] is List) {
          list = decoded['schedules'] as List;
        } else {
          return [];
        }
      } else {
        return [];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(CourseSchedule.fromJson)
          .where((s) => s.namaMataKuliah.isNotEmpty)
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
    final tipeStr = (json['tipe'] as String? ??
            json['eventtype'] as String? ??
            json['modname'] as String? ??
            'lainnya')
        .toLowerCase();
    switch (tipeStr) {
      case 'tugas':
      case 'assign':
      case 'assignment':
        tipe = DeadlineType.tugas;
        break;
      case 'kuis':
      case 'quiz':
        tipe = DeadlineType.kuis;
        break;
      case 'ujian':
      case 'exam':
      case 'uts':
      case 'uas':
        tipe = DeadlineType.ujian;
        break;
      case 'presensi':
      case 'attendance':
      case 'absen':
        tipe = DeadlineType.presensi;
        break;
      default:
        tipe = DeadlineType.lainnya;
    }

    String namaTugas = '';
    if (json['namaTugas'] is String) {
      namaTugas = json['namaTugas'] as String;
    } else if (json['name'] is String) {
      namaTugas = json['name'] as String;
    } else if (json['title'] is String) {
      namaTugas = json['title'] as String;
    } else if (json['activityname'] is String) {
      namaTugas = json['activityname'] as String;
    }
    namaTugas = namaTugas.trim();

    String namaMk = '';
    if (json['namaMataKuliah'] is String) {
      namaMk = json['namaMataKuliah'] as String;
    } else if (json['course'] is Map) {
      final cMap = json['course'] as Map;
      namaMk = (cMap['fullname'] ?? cMap['shortname'] ?? cMap['name'] ?? '').toString();
    } else if (json['course'] is String) {
      namaMk = json['course'] as String;
    } else if (json['coursename'] is String) {
      namaMk = json['coursename'] as String;
    }
    namaMk = namaMk.trim();

    DateTime parsedDate;
    if (json['timesort'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch((json['timesort'] as int) * 1000);
    } else if (json['timestart'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch((json['timestart'] as int) * 1000);
    } else if (json['dueDate'] != null) {
      final rawDueDate = json['dueDate'].toString();
      parsedDate = DateTime.tryParse(rawDueDate) ?? DateTime.now().add(const Duration(days: 7));
    } else {
      parsedDate = DateTime.now().add(const Duration(days: 7));
    }

    return CourseDeadline(
      id: (json['id']?.toString() ?? '').trim(),
      namaTugas: namaTugas,
      namaMataKuliah: namaMk,
      dueDate: parsedDate,
      tipe: tipe,
      url: (json['url']?.toString() ?? '').trim(),
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
      var raw = jsonStr.trim();
      if (raw.startsWith('"') && raw.endsWith('"')) {
        try {
          raw = jsonDecode(raw) as String;
        } catch (_) {}
      }

      final decoded = jsonDecode(raw);
      List<dynamic> list;

      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['events'] is List) {
          list = decoded['events'] as List;
        } else if (decoded['data'] is List) {
          list = decoded['data'] as List;
        } else if (decoded['deadlines'] is List) {
          list = decoded['deadlines'] as List;
        } else {
          return [];
        }
      } else {
        return [];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(CourseDeadline.fromJson)
          .where((d) => d.namaTugas.isNotEmpty)
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<CourseDeadline> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());
}

