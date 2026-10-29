import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:unpam_mobile/models/absence_permit_model.dart';
import 'package:unpam_mobile/models/academic_document_model.dart';
import 'package:unpam_mobile/models/course_project_model.dart';
import 'package:unpam_mobile/models/khs_model.dart';
import 'package:unpam_mobile/models/krs_model.dart';
import 'package:unpam_mobile/models/thesis_model.dart';
import 'package:unpam_mobile/models/academic_grades_model.dart';
import 'package:unpam_mobile/models/attendance_model.dart';
import 'package:unpam_mobile/models/lecture_schedule_model.dart';
import 'package:unpam_mobile/models/seminar_certificate_model.dart';
import 'package:unpam_mobile/models/student_biodata_model.dart';

void main() {
  group('StudentBiodata Model Tests', () {
    const rawJson = '''
    {
      "nim": "241011000001",
      "nama_mahasiswa": "BUDI SANTOSO",
      "alamat_mahasiswa": "JL. CONTOH NO. 1",
      "tempat_lahir_mahasiswa": "TANGERANG",
      "tanggal_lahir_mahasiswa": "2005-01-01",
      "no_identitas": "3600000000000001",
      "no_hp_mahasiswa": "081200000000",
      "alamat_email": "mahasiswa@example.com",
      "tanggal_diterima": "2024-10-21",
      "ipk_semester_berjalan": "3.77",
      "sks_semester_berjalan": "60",
      "semester": "04",
      "id_kelas": "04SIFE001",
      "pekerjaan": "KARYAWAN SWASTA",
      "asal_sekolah": "SMK CONTOH TANGERANG",
      "shift": {
        "id_shift": "E",
        "nama_shift": "REGULER C"
      },
      "status_mahasiswa": {
        "id_status_mahasiswa": "A",
        "nama_status_mahasiswa": "AKTIF"
      },
      "program_studi": {
        "id_prodi": "57201",
        "nama_prodi": "SISTEM INFORMASI S1",
        "fakultas": {
          "id_fakultas": "09",
          "nama_fakultas": "ILMU KOMPUTER"
        }
      }
    }
    ''';

    test('Parses StudentBiodata accurately', () {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final biodata = StudentBiodata.fromJson(map);

      expect(biodata.nim, '241011000001');
      expect(biodata.namaMahasiswa, 'BUDI SANTOSO');
      expect(biodata.isActive, isTrue);
      expect(biodata.ipkValue, 3.77);
      expect(biodata.sksValue, 60);
      expect(biodata.semester, '04');
      expect(biodata.shift?.namaShift, 'REGULER C');
      expect(biodata.programStudi?.namaProdi, 'SISTEM INFORMASI S1');
      expect(biodata.programStudi?.fakultas?.namaFakultas, 'ILMU KOMPUTER');
      expect(biodata.pekerjaan, 'KARYAWAN SWASTA');
      expect(biodata.asalSekolah, 'SMK CONTOH TANGERANG');
      expect(biodata.formattedBirthPlaceAndDate, contains('TANGERANG'));
      expect(biodata.formattedBirthPlaceAndDate, contains('2005'));
    });
  });

  group('AcademicGrades Model Tests', () {
    const rawJson = '''
    {
      "ipk": "3.77",
      "rangkuman": [
        {
          "nim": "241011000001",
          "isemester": "1",
          "idmtk": "22ILK0013",
          "id_kelas": "01SIFE004",
          "snama": "ALGORITMA DAN PEMROGRAMAN I",
          "isks": "3",
          "fmasa": "20242",
          "fgrade": "A-",
          "ambil_mutu": "3.67",
          "imutu": "11.01"
        },
        {
          "nim": "241011000001",
          "isemester": "1",
          "idmtk": "22ILK0022",
          "id_kelas": "01SIFE004",
          "snama": "PENGANTAR TEKNOLOGI INFORMASI",
          "isks": "2",
          "fmasa": "20242",
          "fgrade": "A",
          "ambil_mutu": "4.00",
          "imutu": "8.00"
        },
        {
          "nim": "241011000001",
          "isemester": "2",
          "idmtk": "22SIF0053",
          "id_kelas": "02SIFE001",
          "snama": "ALGORITMA DAN STRUKTUR DATA",
          "isks": "3",
          "fmasa": "20251",
          "fgrade": "A-",
          "ambil_mutu": "3.67",
          "imutu": "11.01"
        }
      ],
      "mutu": {
        "itotalskslulus": "60",
        "itotalmutululus": "226.07",
        "itotalsksambil": "80",
        "itotalmutuambil": "226.07"
      }
    }
    ''';

    test('Parses AcademicGradesResponse and groups by semester accurately', () {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final resp = AcademicGradesResponse.fromJson(map);

      expect(resp.ipk, '3.77');
      expect(resp.ipkValue, 3.77);
      expect(resp.rangkuman.length, 3);
      expect(resp.mutu?.totalSksPassed, 60);
      expect(resp.mutu?.totalSksTaken, 80);

      final grouped = resp.groupedBySemester;
      expect(grouped.containsKey(1), isTrue);
      expect(grouped.containsKey(2), isTrue);
      expect(grouped[1]?.length, 2);
      expect(grouped[2]?.length, 1);

      // Semester 1: (11.01 + 8.00) / (3 + 2) = 19.01 / 5 = 3.802
      final ips1 = resp.calculateSemesterGpa(1);
      expect(ips1, closeTo(3.80, 0.01));
      expect(resp.calculateSemesterSks(1), 5);
      expect(resp.calculateSemesterSks(2), 3);
      expect(resp.totalSksAcrossAll, 8);
    });

    test('CourseGradeItem calculates passed status and mutus accurately', () {
      final item = CourseGradeItem(
        nim: '241011000001',
        isemester: '1',
        idmtk: '22ILK0013',
        idKelas: '01SIFE004',
        snama: 'ALGORITMA',
        isks: '3',
        fmasa: '20242',
        fgrade: 'A-',
        ambilMutu: '3.67',
        imutu: '11.01',
      );

      expect(item.sks, 3);
      expect(item.gradePoint, 3.67);
      expect(item.totalGradePoint, 11.01);
      expect(item.isPassed, isTrue);
    });
  });

  group('LectureSchedule Model Tests', () {
    const rawJson = '''
    {
      "jadwal": [
        {
          "id_semester_registrasi": "20261",
          "id_mata_kuliah": "22SIF0173",
          "nama_mata_kuliah": "JARINGAN KOMPUTER",
          "id_kelas": "04SIFE001",
          "id_ruang": "V.906",
          "ruang": "V-V.906",
          "nama_lokasi_kampus": "VIKTOR",
          "id_periode": "1",
          "id_jenis_perkuliahan": "TM",
          "keterangan_jenis_perkuliahan": "Perkuliahan Luring (Tatap Muka)",
          "waktu_kuliah": {
            "ket_jam": "07.40 - 09.20",
            "hari": {
              "id_hari_waktu_kuliah": "6",
              "nama_hari": "Sabtu"
            }
          },
          "dosen": {
            "id_dosen": "02985",
            "nama_dosen": "GUSMAYENI",
            "nama_gelar_dosen": "GUSMAYENI, S.Kom., M.Kom."
          }
        },
        {
          "id_semester_registrasi": "20261",
          "id_mata_kuliah": "22SIF0213",
          "nama_mata_kuliah": "REKAYASA PERANGKAT LUNAK",
          "id_kelas": "04SIFE001",
          "id_ruang": "V.906",
          "ruang": "V-V.906",
          "nama_lokasi_kampus": "VIKTOR",
          "id_periode": "2",
          "id_jenis_perkuliahan": "OL",
          "keterangan_jenis_perkuliahan": "Perkuliahan Daring (Online)",
          "waktu_kuliah": {
            "ket_jam": "07.40 - 09.20",
            "hari": {
              "id_hari_waktu_kuliah": "6",
              "nama_hari": "Sabtu"
            }
          },
          "dosen": {
            "id_dosen": "02980",
            "nama_dosen": "ANANDA",
            "nama_gelar_dosen": "ANANDA, S.Kom., M.Kom."
          }
        }
      ]
    }
    ''';

    test('Parses LectureScheduleResponse and distinguishes modes & periods', () {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final resp = LectureScheduleResponse.fromJson(map);

      expect(resp.jadwal.length, 2);
      expect(resp.jadwal[0].isOnline, isFalse);
      expect(resp.jadwal[0].isOffline, isTrue);
      expect(resp.jadwal[0].lecturerDisplayName, 'GUSMAYENI, S.Kom., M.Kom.');
      expect(resp.jadwal[0].locationRoom, 'VIKTOR • V-V.906');
      expect(resp.jadwal[0].dayName, 'Sabtu');

      expect(resp.jadwal[1].isOnline, isTrue);
      expect(resp.jadwal[1].isOffline, isFalse);

      final p1 = resp.filterByPeriod('1');
      expect(p1.length, 1);
      expect(p1.first.namaMataKuliah, 'JARINGAN KOMPUTER');

      final p2 = resp.filterByPeriod('2');
      expect(p2.length, 1);
      expect(p2.first.namaMataKuliah, 'REKAYASA PERANGKAT LUNAK');
    });
  });

  group('SeminarCertificate Model Tests', () {
    const rawJson = '''
    [
      {
        "nama_event": "BERGERAK BERSAMA MEMPERKUAT PUSAT PENGEMBANGAN PERADABAN",
        "nomor_barcode": "205e4c06-9583-4cc1-aacb-0e051e0023d5",
        "tanggal_kegiatan": "2025-03-03T00:00:00.000Z",
        "jenis_event": "PKKMB",
        "approved_sertifikat": true
      }
    ]
    ''';

    test('Parses SeminarCertificateItem correctly', () {
      final list = jsonDecode(rawJson) as List<dynamic>;
      final cert = SeminarCertificateItem.fromJson(list[0] as Map<String, dynamic>);

      expect(cert.namaEvent, contains('BERGERAK BERSAMA'));
      expect(cert.nomorBarcode, '205e4c06-9583-4cc1-aacb-0e051e0023d5');
      expect(cert.isVerified, isTrue);
      expect(cert.shortBarcode, '205E4C06');
      expect(cert.formattedDate, contains('2025'));
    });
  });

  group('Attendance Model Tests', () {
    test('Calculates attendance summary metrics correctly', () {
      final meetings = [
        AttendanceMeetingItem(
          idSemesterRegistrasi: '20261',
          idMataKuliah: '22SIF0173',
          idKelas: '04SIFE001',
          presensiStatus: 'hadir',
          dateStatus: 'lessthan',
        ),
        AttendanceMeetingItem(
          idSemesterRegistrasi: '20261',
          idMataKuliah: '22SIF0173',
          idKelas: '04SIFE001',
          presensiStatus: 'hadir',
          dateStatus: 'lessthan',
        ),
        AttendanceMeetingItem(
          idSemesterRegistrasi: '20261',
          idMataKuliah: '22SIF0173',
          idKelas: '04SIFE001',
          presensiStatus: 'absen',
          dateStatus: 'lessthan',
        ),
        AttendanceMeetingItem(
          idSemesterRegistrasi: '20261',
          idMataKuliah: '22SIF0173',
          idKelas: '04SIFE001',
          presensiStatus: null,
          dateStatus: 'greaterthan',
        ),
      ];

      final summary = AttendanceSummary(meetings);
      expect(summary.total, 4);
      expect(summary.attended, 2);
      expect(summary.absent, 1);
      expect(summary.upcoming, 1);
      expect(summary.recorded, 3);
      // percentage = 2 / 3 * 100 = 66.666%
      expect(summary.percentage, closeTo(66.67, 0.05));
    });
  });

  group('KRS Model Tests', () {
    const rawJson = '''
    {
      "semester": {
        "id_semester_registrasi": "20261",
        "nama_semester_registrasi": "Ganjil 2026/2027"
      },
      "mutu": {
        "itotalsksambil": "20",
        "itotalskslulus": "80",
        "itotalmutuambil": "75.5",
        "itotalmutululus": "302.0"
      },
      "mahasiswa": {
        "krs": [
          {
            "id_mata_kuliah": "22SIF0013",
            "nama_mata_kuliah": "REKAYASA PERANGKAT LUNAK",
            "sks_mata_kuliah": "3",
            "id_kelas": "04SIFE001",
            "nama_kurikulum": "KURIKULUM 2022",
            "mata_kuliah": {
              "nama_dosen_pengampu": "DR. AHMAD FAUZI, M.KOM"
            }
          },
          {
            "id_mata_kuliah": "22SIF0022",
            "nama_mata_kuliah": "BASIS DATA LANJUT",
            "sks_mata_kuliah": "3",
            "id_kelas": "04SIFE001",
            "nama_kurikulum": "KURIKULUM 2022"
          }
        ]
      }
    }
    ''';

    test('Parses KrsResponse accurately', () {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final krs = KrsResponse.fromJson(map);

      expect(krs.semester?.namaSemesterRegistrasi, 'Ganjil 2026/2027');
      expect(krs.mutu?.sksLulus, 80);
      expect(krs.courses.length, 2);
      expect(krs.totalSks, 6);
      expect(krs.courses[0].namaMataKuliah, 'REKAYASA PERANGKAT LUNAK');
      expect(krs.courses[0].namaDosenPengampu, 'DR. AHMAD FAUZI, M.KOM');
      expect(krs.courses[0].idKelas, '04SIFE001');
    });
  });

  group('KHS Model Tests', () {
    const rawJson = '''
    {
      "ips": 3.85,
      "semester": {
        "id_semester_registrasi": "20252",
        "nama_semester_registrasi": "Genap 2025/2026"
      },
      "mutu": {
        "itotalsksambil": "18",
        "itotalskslulus": "18",
        "itotalmutuambil": "69.3",
        "itotalmutululus": "69.3"
      },
      "khs": [
        {
          "idmtk": "22SIF0073",
          "snama": "PEMROGRAMAN MOBILE",
          "isks": "3",
          "kelas": "04SIFE001",
          "fgrade": "A",
          "imutu": "12.0",
          "absen": "100",
          "tugas": "90",
          "quiz": "85",
          "uts": "92",
          "uas": "95"
        },
        {
          "idmtk": "22SIF0083",
          "snama": "JARINGAN KOMPUTER",
          "isks": "3",
          "kelas": "04SIFE001",
          "fgrade": "B+",
          "imutu": "9.9",
          "absen": "85",
          "tugas": "80",
          "quiz": "75",
          "uts": "78",
          "uas": "82"
        }
      ]
    }
    ''';

    test('Parses KhsResponse and score components accurately', () {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final khs = KhsResponse.fromJson(map);

      expect(khs.ips, 3.85);
      expect(khs.courses.length, 2);
      expect(khs.totalSks, 6);
      final c1 = khs.courses[0];
      expect(c1.namaMataKuliah, 'PEMROGRAMAN MOBILE');
      expect(c1.grade, 'A');
      expect(c1.isPassed, isTrue);
      expect(c1.nilaiAbsen, '100');
      expect(c1.nilaiUts, '92');
      expect(c1.nilaiUas, '95');
    });
  });

  group('AcademicDocument Model Tests', () {
    const rawDocs = '''
    [
      {
        "id_dokumen": "DOC001",
        "nama_dokumen": "Panduan Skripsi 2026",
        "url": "https://my.unpam.ac.id/files/panduan_skripsi.pdf",
        "id_dokumen_kategori": "CAT01",
        "type_url": "pdf"
      }
    ]
    ''';

    const rawCats = '''
    [
      {
        "id_dokumen_kategori": "CAT01",
        "nama_dokumen_kategori": "Buku Pedoman"
      }
    ]
    ''';

    test('Parses AcademicDocumentItem and Category correctly', () {
      final docList = jsonDecode(rawDocs) as List;
      final doc = AcademicDocumentItem.fromJson(docList[0] as Map<String, dynamic>);
      expect(doc.idDokumen, 'DOC001');
      expect(doc.namaDokumen, 'Panduan Skripsi 2026');
      expect(doc.isPdf, isTrue);
      expect(doc.fileExtension, 'pdf');

      final catList = jsonDecode(rawCats) as List;
      final cat = AcademicDocumentCategory.fromJson(catList[0] as Map<String, dynamic>);
      expect(cat.idKategori, 'CAT01');
      expect(cat.namaKategori, 'Buku Pedoman');
    });
  });

  group('Thesis Model Tests', () {
    const rawJson = '''
    {
      "is_proposal": false,
      "nama_mahasiswa": "BUDI SANTOSO",
      "data_tugas_akhir": {
        "judul": "RANCANG BANGUN APLIKASI MOBILE UNPAM",
        "status": "Bimbingan Aktif",
        "semester": "08"
      }
    }
    ''';

    test('Parses ThesisResponse and active thesis status correctly', () {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final thesis = ThesisResponse.fromJson(map);

      expect(thesis.hasActiveThesis, isTrue);
      expect(thesis.detail?.judul, 'RANCANG BANGUN APLIKASI MOBILE UNPAM');
      expect(thesis.detail?.status, 'Bimbingan Aktif');
    });
  });

  group('CourseProject and AbsencePermit Tests', () {
    const rawProjects = '''
    {
      "current_page": 1,
      "data": [
        {
          "id": "PRJ01",
          "nama_mata_kuliah": "PROYEK SISTEM INFORMASI",
          "pertemuan_ke": "12",
          "sks": "3",
          "nama_dosen_pengampu": "DR. BUDI, M.KOM",
          "disetujui_dosen_pengampu": "1",
          "nilai": "90",
          "pengajuan_expired": false
        }
      ]
    }
    ''';

    const rawPermits = '''
    {
      "current_page": 1,
      "data": [
        {
          "id": "IZIN01",
          "nama_mata_kuliah": "ALGORITMA",
          "pertemuan_ke": "3",
          "jenis_izin": "Sakit",
          "alasan": "Demam berdarah",
          "status": "Disetujui",
          "created_at": "2026-10-25"
        }
      ]
    }
    ''';

    test('Parses CourseProjectResponse and AbsencePermitResponse accurately', () {
      final prjMap = jsonDecode(rawProjects) as Map<String, dynamic>;
      final projects = CourseProjectResponse.fromJson(prjMap);
      expect(projects.projects.length, 1);
      expect(projects.projects[0].namaMataKuliah, 'PROYEK SISTEM INFORMASI');
      expect(projects.projects[0].isApproved, isTrue);
      expect(projects.projects[0].nilai, '90');

      final permitMap = jsonDecode(rawPermits) as Map<String, dynamic>;
      final permits = AbsencePermitResponse.fromJson(permitMap);
      expect(permits.permits.length, 1);
      expect(permits.permits[0].isApproved, isTrue);
      expect(permits.permits[0].alasan, 'Demam berdarah');
    });
  });
}
