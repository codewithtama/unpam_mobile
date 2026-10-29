import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unpam_mobile/core/services/storage_service.dart';
import 'package:unpam_mobile/core/services/finance_service.dart';
import 'package:unpam_mobile/core/services/my_unpam_session.dart';
import 'package:unpam_mobile/models/finance_model.dart';
import 'package:unpam_mobile/providers/finance_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<dynamic> sampleSemestersJson = [
    {
      "id_semester_registrasi": "20262",
      "flags": "0",
      "nama_semester_registrasi": "GENAP 2026/2027",
      "flags_pmb": "1",
      "flags_remedial": "0",
      "flags_sp": null,
      "flags_keuangan": null,
    },
    {
      "id_semester_registrasi": "20261",
      "flags": "1",
      "nama_semester_registrasi": "GANJIL 2026/2027",
      "flags_pmb": "0",
      "flags_remedial": "0",
      "flags_sp": null,
      "flags_keuangan": "1",
    },
    {
      "id_semester_registrasi": "20256",
      "flags": "0",
      "nama_semester_registrasi": "GENAP 2025/2026 SP",
      "flags_sp": "1",
      "flags_keuangan": "1",
    },
    {
      "id_semester_registrasi": "20252",
      "flags": "0",
      "nama_semester_registrasi": "GENAP 2025/2026",
      "flags_keuangan": "1",
    }
  ];

  final Map<String, dynamic> sampleFinanceJson = {
    "mahasiswa": {
      "nim": "241011000001",
      "id_prodi": "57201",
      "id_shift": "E",
      "semester": "04",
      "nama_mahasiswa": "BUDI SANTOSO",
      "alamat_mahasiswa": "JL. CONTOH NO. 1",
      "tempat_lahir_mahasiswa": "TANGERANG",
      "tanggal_lahir_mahasiswa": "2005-01-01",
      "no_identitas": "3600000000000001",
      "no_hp_mahasiswa": "081200000000",
      "alamat_email": "mahasiswa@example.com",
      "ipk_semester_berjalan": "3.77",
      "sks_semester_berjalan": "60",
      "pekerjaan": "KARYAWAN SWASTA",
      "id_kelas": "04SIFE001",
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
    },
    "tagihan": [
      {
        "no_tagihan": "2610129826102201",
        "nomor_urut": "1",
        "keterangan": "Registrasi",
        "total_tagihan": "550000",
        "channel": "",
        "tanggal_bayar": "2026-07-26 00:00:00.000000",
        "nama_tempat_bayar": "Bank BNI",
        "status": "LUNAS"
      },
      {
        "no_tagihan": "2610129826102301",
        "nomor_urut": "2",
        "keterangan": "ANGSURAN KE-2",
        "total_tagihan": "300000",
        "channel": "",
        "tanggal_bayar": "2026-09-28 00:00:00.000000",
        "nama_tempat_bayar": "Bank BNI",
        "status": "LUNAS"
      },
      {
        "no_tagihan": "2610129826102501",
        "nomor_urut": "5",
        "keterangan": "ANGSURAN KE-4",
        "total_tagihan": "300000",
        "channel": null,
        "tanggal_bayar": null,
        "nama_tempat_bayar": null,
        "status": "BELUM LUNAS"
      }
    ],
    "tagihan_lainnya": [
      {
        "no_tagihan": "2610129826199711",
        "nomor_urut": "11",
        "keterangan": "Hot Spot (Gold)",
        "total_tagihan": "50000",
        "channel": "LOKET",
        "tanggal_bayar": "2026-09-05 12:46:00.693000",
        "nama_tempat_bayar": "UNPAM",
        "status": "LUNAS"
      }
    ],
    "tagihan_sp": [],
    "semester": {
      "id_semester_registrasi": "20261",
      "nama_semester_registrasi": "GANJIL 2026/2027"
    }
  };

  group('SemesterItem Model Tests', () {
    test('Parses semester payload accurately and identifies active status', () {
      final items = sampleSemestersJson
          .map((e) => SemesterItem.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(items.length, equals(4));

      // 20261 is active
      final active = items[1];
      expect(active.idSemesterRegistrasi, equals('20261'));
      expect(active.namaSemesterRegistrasi, equals('GANJIL 2026/2027'));
      expect(active.isActive, isTrue);
      expect(active.hasFinance, isTrue);
      expect(active.isShortSemester, isFalse);

      // 20256 is SP
      final sp = items[2];
      expect(sp.idSemesterRegistrasi, equals('20256'));
      expect(sp.isShortSemester, isTrue);
      expect(sp.isActive, isFalse);
    });
  });

  group('FinanceResponse & StudentProfile Model Tests', () {
    test('Correctly parses full JSON response payload', () {
      final response = FinanceResponse.fromJson(sampleFinanceJson);

      expect(response.student.namaMahasiswa, equals('BUDI SANTOSO'));
      expect(response.student.nim, equals('241011000001'));
      expect(response.student.semester, equals('04'));
      expect(response.student.ipkSemesterBerjalan, equals('3.77'));
      expect(response.student.sksSemesterBerjalan, equals('60'));
      expect(response.student.pekerjaan, equals('KARYAWAN SWASTA'));
      expect(response.student.studyProgram?.namaProdi, equals('SISTEM INFORMASI S1'));

      expect(response.billings.length, equals(3));
      expect(response.billings[0].isPaid, isTrue);
      expect(response.billings[0].formattedTotal, contains('550.000'));
      expect(response.billings[2].isPaid, isFalse);

      expect(response.otherBillings.length, equals(1));
      expect(response.semester?.idSemesterRegistrasi, equals('20261'));
    });

    test('Calculates financial metrics accurately', () {
      final response = FinanceResponse.fromJson(sampleFinanceJson);

      expect(response.totalBillingAmount, equals(1150000));
      expect(response.totalPaidAmount, equals(850000));
      expect(response.totalUnpaidAmount, equals(300000));
      expect(response.paidPercentage, closeTo(850000 / 1150000, 0.001));
      expect(response.formatCurrency(1150000), contains('1.150.000'));
    });
  });

  group('StorageService Persistence Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
      await storage.resetAll();
    });

    test('Saving and retrieving MyUnpam Bearer token works', () async {
      expect(storage.hasMyUnpamToken, isFalse);
      expect(storage.getMyUnpamToken(), isNull);

      await storage.saveMyUnpamToken('dummy_jwt_token_for_myunpam_test');
      expect(storage.hasMyUnpamToken, isTrue);
      expect(storage.getMyUnpamToken(), equals('dummy_jwt_token_for_myunpam_test'));

      await storage.clearSession();
      expect(storage.hasMyUnpamToken, isFalse);
    });

    test('Saving and retrieving cached finance and semester list works', () async {
      expect(storage.getCachedFinanceData(), isNull);
      expect(storage.getCachedSemesters(), isNull);

      await storage.saveCachedFinanceData('{"test": true}');
      await storage.saveCachedSemesters('[{"id_semester_registrasi":"20261"}]');

      expect(storage.getCachedFinanceData(), equals('{"test": true}'));
      expect(storage.getCachedSemesters(), contains('20261'));

      await storage.clearSession();
      expect(storage.getCachedFinanceData(), isNull);
      expect(storage.getCachedSemesters(), isNull);
    });
  });

  group('FinanceProvider Tests', () {
    late StorageService storage;
    late FinanceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
      await storage.resetAll();
      service = FinanceService(MyUnpamSession(storage), storage);
    });

    test('FinanceProvider initializes with default semester and state', () async {
      final provider = FinanceProvider(service, storage);
      expect(provider.selectedSemesterId, equals('20261'));
      expect(provider.hasData, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.hasToken, isFalse);
    });
  });
}
