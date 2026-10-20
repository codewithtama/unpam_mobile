import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
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
}
