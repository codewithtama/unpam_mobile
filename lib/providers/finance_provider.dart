import 'package:flutter/foundation.dart';
import '../core/services/finance_service.dart';
import '../core/services/storage_service.dart';
import '../models/finance_model.dart';

class FinanceProvider extends ChangeNotifier {
  final FinanceService _financeService;
  final StorageService _storage;

  bool _isLoading = false;
  bool _isLoadingSemesters = false;
  String? _errorMessage;
  FinanceResponse? _financeData;
  List<SemesterItem> _semesters = [];
  String _selectedSemesterId;

  FinanceProvider(this._financeService, this._storage)
      : _selectedSemesterId = _storage.getSelectedSemester() ?? FinanceService.defaultSemesterId {
    _semesters = _financeService.getCachedSemesters();
    _financeData = _financeService.getCachedFinanceData();
  }

  bool get isLoading => _isLoading;
  bool get isLoadingSemesters => _isLoadingSemesters;
  String? get errorMessage => _errorMessage;
  FinanceResponse? get financeData => _financeData;
  List<SemesterItem> get semesters => _semesters;
  String get selectedSemesterId => _selectedSemesterId;
  bool get hasData => _financeData != null;
  bool get hasToken => _storage.hasMyUnpamToken;

  SemesterItem? get selectedSemesterItem {
    for (final s in _semesters) {
      if (s.idSemesterRegistrasi == _selectedSemesterId) return s;
    }
    return null;
  }

  Future<void> fetchSemesters() async {
    _isLoadingSemesters = true;
    notifyListeners();
    try {
      final list = await _financeService.fetchSemesters();
      if (list.isNotEmpty) {
        _semesters = list;
        if (selectedSemesterItem == null) {
          final active = list.firstWhere((s) => s.isActive, orElse: () => list.first);
          _selectedSemesterId = active.idSemesterRegistrasi;
        }
      }
    } finally {
      _isLoadingSemesters = false;
      notifyListeners();
    }
  }

  Future<void> selectSemester(String semesterId) async {
    if (_selectedSemesterId == semesterId) return;
    _selectedSemesterId = semesterId;
    await _storage.saveSelectedSemester(semesterId);
    notifyListeners();
    await fetchFinanceData(forceRefresh: true);
  }

  Future<void> fetchFinanceData({bool forceRefresh = false}) async {
    if (_isLoading || (!forceRefresh && _financeData != null)) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _financeData = await _financeService.fetchFinanceData(semester: _selectedSemesterId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchSemesters();
    await fetchFinanceData(forceRefresh: true);
  }

  void clear() {
    _financeData = null;
    _errorMessage = null;
    notifyListeners();
  }
}
