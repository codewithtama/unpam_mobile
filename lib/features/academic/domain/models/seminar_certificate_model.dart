import 'package:intl/intl.dart';

class SeminarCertificateItem {
  final String namaEvent;
  final String? namaEventEn;
  final String nomorBarcode;
  final String? tanggalKegiatan;
  final String? jenisEvent;
  final bool approvedSertifikat;

  SeminarCertificateItem({
    required this.namaEvent,
    this.namaEventEn,
    required this.nomorBarcode,
    this.tanggalKegiatan,
    this.jenisEvent,
    this.approvedSertifikat = false,
  });

  bool get isVerified => approvedSertifikat;

  String get formattedDate {
    if (tanggalKegiatan == null || tanggalKegiatan!.isEmpty) return '-';
    try {
      final dt = DateTime.parse(tanggalKegiatan!);
      return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return tanggalKegiatan!;
    }
  }

  String get shortBarcode {
    if (nomorBarcode.isEmpty) return '-';
    if (nomorBarcode.length <= 8) return nomorBarcode.toUpperCase();
    return nomorBarcode.substring(0, 8).toUpperCase();
  }

  factory SeminarCertificateItem.fromJson(Map<String, dynamic> json) {
    return SeminarCertificateItem(
      namaEvent: json['nama_event']?.toString() ?? '',
      namaEventEn: json['nama_event_en']?.toString(),
      nomorBarcode: json['nomor_barcode']?.toString() ?? '',
      tanggalKegiatan: json['tanggal_kegiatan']?.toString(),
      jenisEvent: json['jenis_event']?.toString() ?? 'Seminar',
      approvedSertifikat: json['approved_sertifikat'] == true ||
          json['approved_sertifikat']?.toString() == '1' ||
          json['approved_sertifikat']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() => {
        'nama_event': namaEvent,
        'nama_event_en': namaEventEn,
        'nomor_barcode': nomorBarcode,
        'tanggal_kegiatan': tanggalKegiatan,
        'jenis_event': jenisEvent,
        'approved_sertifikat': approvedSertifikat,
      };
}
