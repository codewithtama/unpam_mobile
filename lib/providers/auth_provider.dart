import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';
import '../models/student_profile_model.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  late StudentProfile _profile;

  AuthProvider(this._storage) {
    _profile = _storage.getStudentProfile();
  }

  StudentProfile get profile => _profile;
  String get studentNim => _profile.nim;
  String get studentName => _profile.name;
  bool get isProfileFilled => _profile.isFilled;
  bool get isLoggedIn => _profile.isFilled;

  Future<void> updateProfile(StudentProfile updated) async {
    _profile = updated;
    await _storage.saveStudentProfile(updated);
    notifyListeners();
  }

  Future<void> resetProfileToDefault() async {
    const defaultProfile = StudentProfile();
    _profile = defaultProfile;
    await _storage.saveStudentProfile(defaultProfile);
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.clearSession();
    notifyListeners();
  }
}
