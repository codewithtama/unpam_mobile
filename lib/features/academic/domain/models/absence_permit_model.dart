import 'package:flutter/foundation.dart';

@immutable
class AbsencePermitItem {
  final String id;
  final String? namaMataKuliah;
  final String? pertemuanKe;
  final String? jenisIzin;
  final String? alasan;
  final String? status;
  final String? tanggal;
  final String? fileLampiran;

  const AbsencePermitItem({
    required this.id,
    this.namaMataKuliah,
    this.pertemuanKe,
    this.jenisIzin,
    this.alasan,
    this.status,
    this.tanggal,
    this.fileLampiran,
  });

  bool get isApproved =>
      status?.toLowerCase() == 'disetujui' ||
      status?.toLowerCase() == 'acc' ||
      status == '1';

  factory AbsencePermitItem.fromJson(Map<String, dynamic> json) {
    return AbsencePermitItem(
      id: json['id']?.toString() ?? '',
      namaMataKuliah: (json['nama_mata_kuliah'] ?? json['mata_kuliah'] ?? json['nama_matakuliah'])?.toString(),
      pertemuanKe: (json['pertemuan_ke'] ?? json['pertemuan'])?.toString(),
      jenisIzin: (json['jenis_izin'] ?? json['nama_jenis_izin'] ?? json['kategori'])?.toString(),
      alasan: (json['alasan'] ?? json['keterangan'] ?? json['catatan'])?.toString(),
      status: (json['status'] ?? json['status_validasi'] ?? json['keterangan_status'])?.toString(),
      tanggal: (json['tanggal'] ?? json['created_at'])?.toString(),
      fileLampiran: (json['file_lampiran'] ?? json['lampiran'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama_mata_kuliah': namaMataKuliah,
        'pertemuan_ke': pertemuanKe,
        'jenis_izin': jenisIzin,
        'alasan': alasan,
        'status': status,
        'tanggal': tanggal,
        'file_lampiran': fileLampiran,
      };
}

@immutable
class AbsencePermitResponse {
  final int currentPage;
  final int lastPage;
  final int total;
  final List<AbsencePermitItem> permits;

  const AbsencePermitResponse({
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    required this.permits,
  });

  factory AbsencePermitResponse.fromJson(dynamic json) {
    if (json == null) return const AbsencePermitResponse(permits: []);

    final List<AbsencePermitItem> items = [];
    if (json is Map<String, dynamic> && json['data'] is List) {
      for (final item in json['data'] as List) {
        if (item is Map<String, dynamic>) {
          items.add(AbsencePermitItem.fromJson(item));
        }
      }
    } else if (json is List) {
      for (final item in json) {
        if (item is Map<String, dynamic>) {
          items.add(AbsencePermitItem.fromJson(item));
        }
      }
    }

    int parseNum(dynamic val, int fallback) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};

    return AbsencePermitResponse(
      currentPage: parseNum(map['current_page'], 1),
      lastPage: parseNum(map['last_page'], 1),
      total: parseNum(map['total'], items.length),
      permits: List.unmodifiable(items),
    );
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'total': total,
        'data': permits.map((p) => p.toJson()).toList(),
      };
}
