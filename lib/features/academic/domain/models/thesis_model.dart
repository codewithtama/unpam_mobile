import 'package:flutter/foundation.dart';

@immutable
class ThesisDetail {
  final String? judul;
  final String? status;
  final String? tanggalPengajuan;
  final String? tahunAkademik;
  final String? semester;
  final String? abstrak;

  const ThesisDetail({
    this.judul,
    this.status,
    this.tanggalPengajuan,
    this.tahunAkademik,
    this.semester,
    this.abstrak,
  });

  factory ThesisDetail.fromJson(Map<String, dynamic> json) {
    return ThesisDetail(
      judul: (json['judul'] ?? json['judul_tugas_akhir'] ?? json['nama_tugas_akhir']) as String?,
      status: (json['status'] ?? json['status_tugas_akhir'] ?? json['keterangan_status']) as String?,
      tanggalPengajuan: (json['tanggal_pengajuan'] ?? json['created_at']) as String?,
      tahunAkademik: json['tahun_akademik']?.toString(),
      semester: json['semester']?.toString(),
      abstrak: json['abstrak'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'judul': judul,
        'status': status,
        'tanggal_pengajuan': tanggalPengajuan,
        'tahun_akademik': tahunAkademik,
        'semester': semester,
        'abstrak': abstrak,
      };
}

@immutable
class ThesisSupervisors {
  final String? pembimbing1;
  final String? pembimbing2;

  const ThesisSupervisors({
    this.pembimbing1,
    this.pembimbing2,
  });

  factory ThesisSupervisors.fromJson(Map<String, dynamic> json) {
    return ThesisSupervisors(
      pembimbing1: (json['pembimbing_1'] ?? json['nama_pembimbing_1'] ?? json['dosen_1']) as String?,
      pembimbing2: (json['pembimbing_2'] ?? json['nama_pembimbing_2'] ?? json['dosen_2']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'pembimbing_1': pembimbing1,
        'pembimbing_2': pembimbing2,
      };
}

@immutable
class ThesisGuidanceItem {
  final String id;
  final String pertemuanKe;
  final String? catatan;
  final String? status;
  final String? tanggal;
  final String? materiBimbingan;

  const ThesisGuidanceItem({
    required this.id,
    required this.pertemuanKe,
    this.catatan,
    this.status,
    this.tanggal,
    this.materiBimbingan,
  });

  factory ThesisGuidanceItem.fromJson(Map<String, dynamic> json) {
    return ThesisGuidanceItem(
      id: json['id']?.toString() ?? '',
      pertemuanKe: (json['pertemuan_ke'] ?? json['pertemuan'] ?? '').toString(),
      catatan: (json['catatan'] ?? json['catatan_dosen'] ?? json['komentar']) as String?,
      status: (json['status'] ?? json['status_bimbingan']) as String?,
      tanggal: (json['tanggal'] ?? json['tanggal_bimbingan'] ?? json['created_at']) as String?,
      materiBimbingan: (json['materi'] ?? json['materi_bimbingan'] ?? json['pokok_bahasan']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pertemuan_ke': pertemuanKe,
        'catatan': catatan,
        'status': status,
        'tanggal': tanggal,
        'materi_bimbingan': materiBimbingan,
      };
}

@immutable
class ThesisResponse {
  final bool isProposal;
  final String? namaMahasiswa;
  final String? namaProdi;
  final String? namaFakultas;
  final ThesisDetail? detail;
  final ThesisSupervisors? supervisors;
  final List<ThesisGuidanceItem> guidanceHistory;

  const ThesisResponse({
    this.isProposal = false,
    this.namaMahasiswa,
    this.namaProdi,
    this.namaFakultas,
    this.detail,
    this.supervisors,
    this.guidanceHistory = const [],
  });

  bool get hasActiveThesis => detail != null && (detail!.judul?.trim().isNotEmpty ?? false);

  factory ThesisResponse.fromJson(
    Map<String, dynamic> json, {
    List<ThesisGuidanceItem> guidance = const [],
    ThesisSupervisors? supervisors,
  }) {
    ThesisDetail? parsedDetail;
    if (json['data_tugas_akhir'] is Map<String, dynamic>) {
      parsedDetail = ThesisDetail.fromJson(json['data_tugas_akhir'] as Map<String, dynamic>);
    }

    return ThesisResponse(
      isProposal: json['is_proposal'] == true || json['is_proposal'] == '1',
      namaMahasiswa: json['nama_mahasiswa'] as String?,
      namaProdi: json['nama_prodi'] as String?,
      namaFakultas: json['nama_fakultas'] as String?,
      detail: parsedDetail,
      supervisors: supervisors,
      guidanceHistory: List.unmodifiable(guidance),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_proposal': isProposal,
        'nama_mahasiswa': namaMahasiswa,
        'nama_prodi': namaProdi,
        'nama_fakultas': namaFakultas,
        'data_tugas_akhir': detail?.toJson(),
        'supervisors': supervisors?.toJson(),
        'bimbingan_riwayat': guidanceHistory.map((g) => g.toJson()).toList(),
      };
}
