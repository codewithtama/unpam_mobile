import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../domain/models/finance_model.dart';
import 'my_unpam_session.dart';
import '../../../../core/services/storage_service.dart';

class FinanceService {
  static const String defaultSemesterId = '20261';

  static final List<SemesterItem> _fallbackSemesters = [
    SemesterItem(
      idSemesterRegistrasi: '20261',
      namaSemesterRegistrasi: 'GANJIL 2026/2027',
      flags: '1',
      flagsKeuangan: '1',
    ),
    SemesterItem(
      idSemesterRegistrasi: '20252',
      namaSemesterRegistrasi: 'GENAP 2025/2026',
      flags: '0',
      flagsKeuangan: '1',
    ),
    SemesterItem(
      idSemesterRegistrasi: '20251',
      namaSemesterRegistrasi: 'GANJIL 2025/2026',
      flags: '0',
      flagsKeuangan: '1',
    ),
    SemesterItem(
      idSemesterRegistrasi: '20242',
      namaSemesterRegistrasi: 'GENAP 2024/2025',
      flags: '0',
      flagsKeuangan: '1',
    ),
  ];

  final MyUnpamSession _session;
  final StorageService _storage;

  FinanceService(this._session, this._storage);

  List<SemesterItem> getCachedSemesters() {
    final cached = _storage.getCachedSemesters();
    if (cached == null) return [];
    try {
      return (jsonDecode(cached) as List)
          .map((e) => SemesterItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[FinanceService] invalid semester cache: $e');
      return [];
    }
  }

  Future<List<SemesterItem>> fetchSemesters() async {
    try {
      final json = await _session.get('/api/semester') as List;
      await _storage.saveCachedSemesters(jsonEncode(json));
      return json.map((e) => SemesterItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[FinanceService] fetchSemesters: $e');
      final cached = getCachedSemesters();
      return cached.isNotEmpty ? cached : _fallbackSemesters;
    }
  }

  FinanceResponse? getCachedFinanceData() {
    final cached = _storage.getCachedFinanceData();
    if (cached == null) return null;
    try {
      return FinanceResponse.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[FinanceService] invalid finance cache: $e');
      return null;
    }
  }

  Future<FinanceResponse> fetchFinanceData({String? semester}) async {
    final targetSemester = semester ?? _storage.getSelectedSemester() ?? defaultSemesterId;
    final json = await _session.get('/api/keuangan', query: {'semester': targetSemester});
    final result = FinanceResponse.fromJson(json as Map<String, dynamic>);
    await _storage.saveCachedFinanceData(jsonEncode(json));
    await _storage.saveSelectedSemester(targetSemester);
    return result;
  }
}
