import 'package:flutter/foundation.dart';

@immutable
class AcademicDocumentCategory {
  final String idKategori;
  final String namaKategori;

  const AcademicDocumentCategory({
    required this.idKategori,
    required this.namaKategori,
  });

  factory AcademicDocumentCategory.fromJson(Map<String, dynamic> json) {
    return AcademicDocumentCategory(
      idKategori: json['id_dokumen_kategori']?.toString() ?? '',
      namaKategori: (json['nama_dokumen_kategori'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_dokumen_kategori': idKategori,
        'nama_dokumen_kategori': namaKategori,
      };
}

@immutable
class AcademicDocumentItem {
  final String idDokumen;
  final String namaDokumen;
  final String url;
  final String idDokumenKategori;
  final String typeUrl;

  const AcademicDocumentItem({
    required this.idDokumen,
    required this.namaDokumen,
    required this.url,
    required this.idDokumenKategori,
    required this.typeUrl,
  });

  String get fileExtension {
    final clean = url.split('?').first;
    final dot = clean.lastIndexOf('.');
    if (dot != -1 && dot < clean.length - 1) {
      return clean.substring(dot + 1).toLowerCase();
    }
    return typeUrl.toLowerCase();
  }

  bool get isPdf => fileExtension == 'pdf';

  factory AcademicDocumentItem.fromJson(Map<String, dynamic> json) {
    return AcademicDocumentItem(
      idDokumen: json['id_dokumen']?.toString() ?? '',
      namaDokumen: (json['nama_dokumen'] as String?)?.trim() ?? '',
      url: (json['url'] as String?)?.trim() ?? '',
      idDokumenKategori: json['id_dokumen_kategori']?.toString() ?? '',
      typeUrl: (json['type_url'] as String?)?.trim() ?? 'pdf',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_dokumen': idDokumen,
        'nama_dokumen': namaDokumen,
        'url': url,
        'id_dokumen_kategori': idDokumenKategori,
        'type_url': typeUrl,
      };
}

