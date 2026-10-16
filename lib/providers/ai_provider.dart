import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/services/ai_service.dart';
import '../core/services/storage_service.dart';
import '../models/ai_message_model.dart';
import '../models/paraphrase_model.dart';

class AiProvider extends ChangeNotifier {
  final AiService _aiService;
  final StorageService _storage;

  final List<AiMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCourseName;

  AiProvider(this._aiService, this._storage) {
    _initWelcomeMessage();
  }

  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCourseName => _selectedCourseName;
  bool get hasCustomApiKey =>
      _storage.getGeminiApiKey() != null && _storage.getGeminiApiKey()!.isNotEmpty;

  void _initWelcomeMessage() {
    _messages.add(
      AiMessage(
        id: 'welcome_msg',
        content:
            'Halo! Saya **UNPAM AI**, siap mendampingi perkuliahan Anda. '
            'Anda dapat menanyakan materi kuliah, meng-upload screenshot soal kuis/tugas, '
            'atau meminta rangkuman dan analisis jawaban langsung dari layar modul perkuliahan.',
        isUser: false,
        timestamp: DateTime.now(),
        type: AiMessageType.text,
      ),
    );
  }

  void setSelectedCourse(String? course) {
    _selectedCourseName = course;
    notifyListeners();
  }

  Future<void> sendMessage(
    String text, {
    List<String>? availableCourses,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final query = text.trim();
    if (query.isEmpty && (imageBytes == null || imageBytes.isEmpty)) return;

    // Tambah pesan user ke list (termasuk thumbnail gambar jika ada)
    final userMsg = AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: query.isEmpty
          ? 'Tolong baca dan jawab pertanyaan pada screenshot gambar ini.'
          : query,
      isUser: true,
      timestamp: DateTime.now(),
      relatedCourseName: _selectedCourseName,
      imageBytes: imageBytes,
    );
    _messages.add(userMsg);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final assistantMsg = await _aiService.askAssistant(
        prompt: query.isEmpty
            ? 'Analisis soal pada gambar di atas dan berikan jawaban yang benar serta alasannya.'
            : query,
        courseName: _selectedCourseName,
        availableCourses: availableCourses,
        imageBytes: imageBytes,
        mimeType: mimeType,
      );
      _messages.add(assistantMsg);
    } catch (e) {
      _errorMessage = 'Gagal memproses permintaan: $e';
      _messages.add(
        AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Maaf, terjadi kendala saat menghubungi asisten. Silakan coba lagi.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Interaktif: Mahasiswa menjawab opsi kuis
  void answerQuizOption({
    required String messageId,
    required int questionIndex,
    required int selectedIndex,
  }) {
    final msgIndex = _messages.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final msg = _messages[msgIndex];
    if (msg.quizItems == null || questionIndex >= msg.quizItems!.length) return;

    msg.quizItems![questionIndex].userSelectedIndex = selectedIndex;
    notifyListeners();
  }

  Future<void> updateGeminiApiKey(String key) async {
    await _storage.saveGeminiApiKey(key);
    notifyListeners();
  }

  Future<bool> validateAndSaveApiKey(String key) async {
    final clean = key.trim();
    if (clean.isEmpty) {
      await removeGeminiApiKey();
      return true;
    }
    final valid = await _aiService.validateGeminiApiKey(clean);
    if (valid) {
      await _storage.saveGeminiApiKey(clean);
      notifyListeners();
    }
    return valid;
  }

  Future<void> removeGeminiApiKey() async {
    await _storage.saveGeminiApiKey('');
    notifyListeners();
  }

  String getGeminiApiKey() {
    return _storage.getGeminiApiKey() ?? '';
  }

  Future<String> generateForumReply({
    required String topic,
    String? courseName,
  }) async {
    return await _aiService.generateForumReply(
      topic: topic,
      courseName: courseName ?? _selectedCourseName,
    );
  }

  Future<List<Map<String, dynamic>>> solveQuizQuestions({
    required List<Map<String, dynamic>> questions,
    String? courseName,
  }) async {
    return await _aiService.solveQuizQuestions(
      questions: questions,
      courseName: courseName ?? _selectedCourseName,
    );
  }

  Future<ParaphraseResult> paraphraseText({
    required String text,
    required ParaphraseMode mode,
    bool includeCitationAdvice = false,
    String? courseName,
  }) async {
    return await _aiService.paraphraseAcademicText(
      text: text,
      mode: mode,
      includeCitationAdvice: includeCitationAdvice,
      courseName: courseName ?? _selectedCourseName,
    );
  }

  void clearChat() {
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
  }
}

