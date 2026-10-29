import 'package:flutter/foundation.dart';

@immutable
class CourseProjectItem {
  final String id;
  final String namaMataKuliah;
  final String pertemuanKe;
  final String sks;
  final String namaDosenPengampu;
  final String? namaJenisLampiran;
  final String? fileLampiran;
  final String? batasWaktuMengerjakan;
  final String? nilai;
  final String? disetujuiDosenPengampu;
  final String? validasiJawaban;
  final bool pengajuanExpired;
  final String? createdAt;

  const CourseProjectItem({
    required this.id,
    required this.namaMataKuliah,
    required this.pertemuanKe,
    required this.sks,
    required this.namaDosenPengampu,
    this.namaJenisLampiran,
    this.fileLampiran,
    this.batasWaktuMengerjakan,
    this.nilai,
    this.disetujuiDosenPengampu,
    this.validasiJawaban,
    this.pengajuanExpired = false,
    this.createdAt,
  });

  bool get isApproved =>
      disetujuiDosenPengampu == '1' ||
      disetujuiDosenPengampu?.toLowerCase() == 'ya' ||
      validasiJawaban == '1';

  factory CourseProjectItem.fromJson(Map<String, dynamic> json) {
    return CourseProjectItem(
      id: json['id']?.toString() ?? '',
      namaMataKuliah: (json['nama_mata_kuliah'] as String?)?.trim() ?? '',
      pertemuanKe: json['pertemuan_ke']?.toString() ?? '',
      sks: json['sks']?.toString() ?? '0',
      namaDosenPengampu: (json['nama_dosen_pengampu'] as String?)?.trim() ?? '',
      namaJenisLampiran: json['nama_jenis_lampiran'] as String?,
      fileLampiran: json['file_lampiran'] as String?,
      batasWaktuMengerjakan: json['batas_waktu_mengerjakan'] as String?,
      nilai: json['nilai']?.toString(),
      disetujuiDosenPengampu: json['disetujui_dosen_pengampu']?.toString(),
      validasiJawaban: json['validasi_jawaban']?.toString(),
      pengajuanExpired: json['pengajuan_expired'] == true,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama_mata_kuliah': namaMataKuliah,
        'pertemuan_ke': pertemuanKe,
        'sks': sks,
        'nama_dosen_pengampu': namaDosenPengampu,
        'nama_jenis_lampiran': namaJenisLampiran,
        'file_lampiran': fileLampiran,
        'batas_waktu_mengerjakan': batasWaktuMengerjakan,
        'nilai': nilai,
        'disetujui_dosen_pengampu': disetujuiDosenPengampu,
        'validasi_jawaban': validasiJawaban,
        'pengajuan_expired': pengajuanExpired,
        'created_at': createdAt,
      };
}

@immutable
class CourseProjectResponse {
  final int currentPage;
  final int lastPage;
  final int total;
  final List<CourseProjectItem> projects;

  const CourseProjectResponse({
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    required this.projects,
  });

  factory CourseProjectResponse.fromJson(Map<String, dynamic> json) {
    final List<CourseProjectItem> items = [];
    if (json['data'] is List) {
      for (final item in json['data'] as List) {
        if (item is Map<String, dynamic>) {
          items.add(CourseProjectItem.fromJson(item));
        }
      }
    }

    return CourseProjectResponse(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      projects: List.unmodifiable(items),
    );
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'total': total,
        'data': projects.map((p) => p.toJson()).toList(),
      };
}

