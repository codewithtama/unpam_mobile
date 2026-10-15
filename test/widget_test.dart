import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unpam_mobile/core/services/storage_service.dart';
import 'package:unpam_mobile/core/services/ai_service.dart';
import 'package:unpam_mobile/models/student_profile_model.dart';
import 'package:unpam_mobile/providers/auth_provider.dart';
import 'package:unpam_mobile/providers/ai_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudentProfile Model Tests', () {
    test('Default StudentProfile has valid initial values and passes validation', () {
      const profile = StudentProfile();
      expect(profile.name, equals('Tama Vernaldi'));
      expect(profile.nim, equals('221011400123'));
      expect(profile.prodi, equals('Teknik Informatika (S1)'));
      expect(profile.isValidName, isTrue);
      expect(profile.isValidNim, isTrue);
      expect(profile.isValidEmail, isTrue);
      expect(profile.isValidPhone, isTrue);
    });

    test('Validation detects invalid NIM, email, and phone', () {
      const invalidProfile = StudentProfile(
        name: 'A',
        nim: 'abc12',
        email: 'bukan-email',
        phone: '123',
      );
      expect(invalidProfile.isValidName, isFalse);
      expect(invalidProfile.isValidNim, isFalse);
      expect(invalidProfile.isValidEmail, isFalse);
      expect(invalidProfile.isValidPhone, isFalse);
    });

    test('Serialization and deserialization roundtrip works accurately', () {
      const original = StudentProfile(
        name: 'Budi Santoso',
        nim: '2021140099',
        prodi: 'Sistem Informasi (S1)',
        fakultas: 'Fakultas Ilmu Komputer',
        kelas: '06SIFP001',
        shift: 'Reguler A (Pagi)',
        semester: 'Semester 6',
        email: 'budi@mahasiswa.unpam.ac.id',
        phone: '081298765432',
        status: 'Mahasiswa Aktif',
        bio: 'Fokus Data Science & Machine Learning',
      );

      final json = original.toJson();
      final restored = StudentProfile.fromJson(json);

      expect(restored.name, equals('Budi Santoso'));
      expect(restored.nim, equals('2021140099'));
      expect(restored.prodi, equals('Sistem Informasi (S1)'));
      expect(restored.kelas, equals('06SIFP001'));
      expect(restored.shift, equals('Reguler A (Pagi)'));
      expect(restored.semester, equals('Semester 6'));
      expect(restored.email, equals('budi@mahasiswa.unpam.ac.id'));
      expect(restored.phone, equals('081298765432'));
      expect(restored.status, equals('Mahasiswa Aktif'));
      expect(restored.bio, equals('Fokus Data Science & Machine Learning'));
    });

    test('copyWith updates specific fields while preserving others', () {
      const original = StudentProfile();
      final updated = original.copyWith(
        name: 'Ahmad Dahlan',
        semester: 'Semester 5',
      );

      expect(updated.name, equals('Ahmad Dahlan'));
      expect(updated.semester, equals('Semester 5'));
      expect(updated.nim, equals(original.nim));
      expect(updated.prodi, equals(original.prodi));
    });
  });

  group('StorageService & AuthProvider Profile Persistence Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
    });

    test('Saving and retrieving StudentProfile preserves data', () async {
      const newProfile = StudentProfile(
        name: 'Rina Kusuma',
        nim: '221011400555',
        prodi: 'Manajemen (S1)',
        fakultas: 'Fakultas Ekonomi & Bisnis',
        kelas: '04SMJE002',
        shift: 'Reguler B (Siang)',
        semester: 'Semester 4',
        email: 'rina@mahasiswa.unpam.ac.id',
        phone: '085712345678',
        status: 'Mahasiswa Aktif',
        bio: 'Peminatan Manajemen Keuangan',
      );

      await storage.saveStudentProfile(newProfile);
      final retrieved = storage.getStudentProfile();

      expect(retrieved.name, equals('Rina Kusuma'));
      expect(retrieved.nim, equals('221011400555'));
      expect(retrieved.prodi, equals('Manajemen (S1)'));
      expect(retrieved.fakultas, equals('Fakultas Ekonomi & Bisnis'));
      expect(retrieved.kelas, equals('04SMJE002'));
    });

    test('AuthProvider notifies listeners when profile is updated', () async {
      final auth = AuthProvider(storage);
      bool notified = false;
      auth.addListener(() => notified = true);

      const update = StudentProfile(name: 'Updated Name', nim: '1234567890');
      await auth.updateProfile(update);

      expect(notified, isTrue);
      expect(auth.studentName, equals('Updated Name'));
      expect(auth.studentNim, equals('1234567890'));
    });

    test('AuthProvider resets profile to default values', () async {
      final auth = AuthProvider(storage);
      const custom = StudentProfile(name: 'Custom User', nim: '9999999999');
      await auth.updateProfile(custom);
      expect(auth.studentName, equals('Custom User'));

      await auth.resetProfileToDefault();
      expect(auth.studentName, equals('Tama Vernaldi'));
      expect(auth.studentNim, equals('221011400123'));
    });
  });

  group('AiProvider API Key Management Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
    });

    test('Saving and removing Gemini API key updates AiProvider state', () async {
      final aiService = AiService(storage);
      final aiProv = AiProvider(aiService, storage);

      expect(aiProv.hasCustomApiKey, isFalse);
      expect(aiProv.getGeminiApiKey(), isEmpty);

      await aiProv.updateGeminiApiKey('AIzaSyDummyKey123456');
      expect(aiProv.hasCustomApiKey, isTrue);
      expect(aiProv.getGeminiApiKey(), equals('AIzaSyDummyKey123456'));

      await aiProv.removeGeminiApiKey();
      expect(aiProv.hasCustomApiKey, isFalse);
      expect(aiProv.getGeminiApiKey(), isEmpty);
    });
  });
}
