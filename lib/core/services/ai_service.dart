import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import '../../models/ai_message_model.dart';

class AiService {
  final StorageService _storage;
  final Dio _dio = Dio();

  final Map<String, AiMessage> _cache = {};
  DateTime? _rateLimitedUntil;

  AiService(this._storage) {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Memproses prompt mahasiswa: jika ada API key Gemini dan belum kena cooldown rate-limit,
  /// panggil Gemini API; jika tidak ada atau kena rate-limit, gunakan built-in domain engine.
  Future<AiMessage> askAssistant({
    required String prompt,
    String? courseName,
    List<String>? availableCourses,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final cleanPrompt = prompt.trim();
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;
    final cacheKey = '${courseName ?? "all"}_${cleanPrompt.toLowerCase()}';

    // 1. Cek Cache Lokal jika teks saja (Hemat 100% token & cegah redundansi API call)
    if (!hasImage && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: cached.content,
        isUser: false,
        timestamp: DateTime.now(),
        type: cached.type,
        quizItems: cached.quizItems,
        relatedCourseName: cached.relatedCourseName,
      );
    }

    final apiKey = _storage.getGeminiApiKey();

    // 2. Proteksi Cooldown Rate-Limit: jika barusan kena 429, jangan spam ke Google
    final now = DateTime.now();
    final inCooldown = _rateLimitedUntil != null && now.isBefore(_rateLimitedUntil!);

    if (apiKey != null && apiKey.isNotEmpty && !inCooldown) {
      try {
        final result = await _askGemini(
          apiKey: apiKey,
          prompt: cleanPrompt,
          courseName: courseName,
          imageBytes: imageBytes,
          mimeType: mimeType,
        );
        if (!hasImage) _cache[cacheKey] = result;
        return result;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 429) {
          // Cooldown 60 detik agar tidak membakar limit akun
          _rateLimitedUntil = now.add(const Duration(minutes: 1));
        }
        return _generateDomainResponse(
          prompt: cleanPrompt,
          courseName: courseName,
          hasImage: hasImage,
          rateLimitNote: code == 429
              ? '⚠️ *Batas kuota Gemini (Rate Limit 429) tercapai. Asisten dialihkan sementara ke engine cerdas UNPAM offline untuk melindungi kuota Anda.*'
              : null,
        );
      } catch (_) {
        return _generateDomainResponse(
          prompt: cleanPrompt,
          courseName: courseName,
          hasImage: hasImage,
        );
      }
    }

    // Default mode: Intelligent UNPAM Campus Engine
    final result = _generateDomainResponse(
      prompt: cleanPrompt,
      courseName: courseName,
      hasImage: hasImage,
      rateLimitNote: inCooldown
          ? '⏳ *Gemini API dalam masa cooldown hemat kuota. Menggunakan engine cerdas UNPAM offline.*'
          : null,
    );
    if (!hasImage) _cache[cacheKey] = result;
    return result;
  }

  Future<AiMessage> _askGemini({
    required String apiKey,
    required String prompt,
    String? courseName,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    final systemPrompt =
        'Anda adalah "UNPAM AI Study Assistant", asisten akademik cerdas untuk mahasiswa Universitas Pamulang. '
        'Bantu mahasiswa memahami materi kuliah, rangkuman pertemuan, persiapan kuis, dan tugas pemrograman. '
        'Bahasa: Bahasa Indonesia yang ramah, jelas, ringkas, terstruktur, dan edukatif. '
        'Jika terdapat gambar lampiran (screenshot kuis/soal), baca teks soal pada gambar secara teliti, tentukan jawaban yang benar, dan berikan pembahasan yang jelas. '
        'Jika pengguna meminta kuis/latihan soal teks, sertakan 3 soal pilihan ganda di akhir dengan format JSON khusus dalam tag ```json_quiz [{"question": "...", "options": ["A. ...", "B. ...", "C. ...", "D. ..."], "correctIndex": 0, "explanation": "..."}] ```. '
        'Konteks mata kuliah saat ini: ${courseName ?? "Umum / Teknik Informatika"}.';

    final List<Map<String, dynamic>> parts = [];
    if (imageBytes != null && imageBytes.isNotEmpty) {
      parts.add({
        'inlineData': {
          'mimeType': mimeType ?? 'image/jpeg',
          'data': base64Encode(imageBytes),
        }
      });
    }

    parts.add({
      'text': '$systemPrompt\n\n'
          '${imageBytes != null ? "Perintah OCR Vision: Bacalah teks dan soal pada screenshot gambar di atas secara teliti. Berikan jawaban yang tepat dan pembahasan rasionalnya.\n\n" : ""}'
          'Pertanyaan / Permintaan Mahasiswa:\n$prompt'
    });

    final body = {
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': 0.6,
        'maxOutputTokens': 1000,
      }
    };

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
      ),
    );

    final candidates = response.data?['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Respons Gemini kosong.');
    }

    final text = candidates.first['content']?['parts']?[0]?['text']?.toString() ??
        'Tidak ada respons.';

    // Check if JSON quiz is embedded
    List<QuizItem>? quizItems;
    final quizRegex = RegExp(r'```json_quiz\s*([\s\S]*?)\s*```');
    final match = quizRegex.firstMatch(text);
    String cleanContent = text;

    if (match != null) {
      try {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          final List<dynamic> decoded = jsonDecode(jsonStr);
          quizItems = decoded.map((e) => QuizItem.fromJson(e as Map<String, dynamic>)).toList();
          cleanContent = text.replaceFirst(match.group(0)!, '').trim();
        }
      } catch (_) {}
    }

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: cleanContent,
      isUser: false,
      timestamp: DateTime.now(),
      type: quizItems != null ? AiMessageType.quiz : AiMessageType.text,
      quizItems: quizItems,
      relatedCourseName: courseName,
    );
  }

  /// Engine bawaan cerdas & interaktif yang siap pakai tanpa harus bayar / input API key.
  AiMessage _generateDomainResponse({
    required String prompt,
    String? courseName,
    String? rateLimitNote,
    bool hasImage = false,
  }) {
    final lower = prompt.toLowerCase();
    final course = courseName ?? 'Mata Kuliah Terpilih';
    final imageNote = hasImage
        ? '📷 *Screenshot Layar Diterima:*\n'
        : '';
    final prefix = rateLimitNote != null ? '$rateLimitNote\n\n$imageNote' : imageNote;

    // 1. Kuis / Latihan Soal
    if (lower.contains('kuis') || lower.contains('soal') || lower.contains('test') || lower.contains('pretest') || hasImage) {
      final quizItems = _buildSimulatedQuiz(course);
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '${prefix}Berikut latihan soal adaptif untuk mata kuliah **$course** guna persiapan kuis/ujian Anda. Pilih jawaban langsung di bawah untuk melihat pembahasan otomatis:',
        isUser: false,
        timestamp: DateTime.now(),
        type: AiMessageType.quiz,
        quizItems: quizItems,
        relatedCourseName: course,
      );
    }

    // 2. Rangkuman Materi
    if (lower.contains('rangkum') || lower.contains('ringkas') || lower.contains('materi')) {
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '''$prefix📌 **Rangkuman Esensial: $course**

Berikut intisari materi utama dan konsep kunci yang sering diujikan pada sesi perkuliahan ini:

1. **Konsep Fondasi**:
   - Memahami arsitektur inti dan metodologi penyelesaian masalah berbasis modul terstruktur.
   - Pemisahan tanggung jawab (*Separation of Concerns*) antara data model, logika bisnis, dan antarmuka.

2. **Poin-Poin Kunci yang Harus Diingat**:
   - Aturan sintaksis dan prinsip desain standar industri (*Clean Architecture*).
   - Penanganan error runtime melalui validasi input awal (*Fail-Fast Principle*).
   - Penggunaan struktur data efisien untuk meminimalkan kompleksitas waktu (Big-O).

3. **Tips Menghadapi Kuis & Forum**:
   - Gunakan argumentasi yang didukung contoh kasus nyata saat mengisi forum diskusi.
   - Teliti batasan waktu pengerjaan kuis di portal Sakura sebelum menekan tombol Mulai.

💡 *Butuh latihan soal atau contoh kasus praktis untuk materi ini? Coba tanyakan "Buatkan kuis latihan untuk $course"!*''',
        isUser: false,
        timestamp: DateTime.now(),
        type: AiMessageType.summary,
        relatedCourseName: course,
      );
    }

    // 3. Draft Forum Diskusi
    if (lower.contains('forum') || lower.contains('diskusi') || lower.contains('tanggapan')) {
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '''$prefix💬 **Draft Tanggapan Forum Diskusi LMS**
*Mata Kuliah: $course*

---
**Salam Bapak/Ibu Dosen dan Rekan-Rekan Mahasiswa,**

Izin menyampaikan tanggapan dan pandangan saya terkait topik perkuliahan pada pertemuan ini:

Berdasarkan modul pembelajaran yang telah dipelajari, implementasi konsep ini memberikan solusi efisien terhadap kendala skalabilitas dan keterbacaan program. Dalam penerapannya di lingkungan industri, pendekatan modular memudahkan proses *debugging*, meningkatkan pemeliharaan kode (*maintainability*), serta meminimalkan redundansi data.

Sebagai contoh implementasi nyata, pembagian layer controller dan repository memungkinkan pengujian unit (*unit testing*) secara terisolasi tanpa mempengaruhi ketergantungan layer lain.

Demikian tanggapan dari saya, mohon arahan dan masukan dari Bapak/Ibu Dosen serta rekan-rekan sekalian. Terima kasih.
---

📋 *Anda dapat menyalin draft ini dan menyesuaikannya dengan studi kasus spesifik di modul pertemuan Anda.*''',
        isUser: false,
        timestamp: DateTime.now(),
        type: AiMessageType.discussionDraft,
        relatedCourseName: course,
      );
    }

    // 4. Bantuan Kode / Pemrograman
    if (lower.contains('kode') || lower.contains('code') || lower.contains('fungsi') || lower.contains('class') || lower.contains('coding')) {
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '''$prefix💻 **Panduan Implementasi Kode Bersih ($course)**

Berikut contoh struktur implementasi pola arsitektur yang aman dan efisien:

```dart
// Contoh penerapan State Management & Error Handling yang tangguh
class AcademicRepository {
  Future<List<String>> fetchCourseModules(String courseId) async {
    try {
      // 1. Validasi parameter input
      if (courseId.trim().isEmpty) {
        throw ArgumentError('Course ID tidak boleh kosong.');
      }
      
      // 2. Simulasi eksekusi I/O dengan timeout
      final result = await Future.delayed(
        const Duration(milliseconds: 400),
        () => ['Pertemuan 1: Pengantar', 'Pertemuan 2: Teori Dasar'],
      );
      
      return result;
    } catch (e) {
      // Selalu log context error dan lempar typed exception
      throw Exception('Gagal memuat modul untuk \$courseId: \$e');
    }
  }
}
```

**Karakteristik penting:**
- Validasi awal (*guard clauses*) untuk mencegah nilai `null` atau `empty`.
- Penanganan pengecualian bertipe (*typed exception*).
- Hindari hardcode konfigurasi; pisahkan dalam kelas konstanta.''',
        isUser: false,
        timestamp: DateTime.now(),
        type: AiMessageType.text,
        relatedCourseName: course,
      );
    }

    // 5. Default Academic Advice
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '''${prefix}Halo! Saya **UNPAM AI Study Assistant** siap membantu studi Anda di Universitas Pamulang.

Saya dapat membantu Anda dalam:
• 📝 **Latihan Kuis & Soal**: Coba ketik *"Buat kuis latihan untuk $course"*
• 📚 **Rangkum Materi**: Coba ketik *"Rangkum materi utama $course"*
• 💬 **Draft Forum Diskusi**: Coba ketik *"Buatkan draft jawaban forum diskusi"*
• 💡 **Penjelasan Konsep**: Tanyakan teori, algoritma, atau konsep kuliah yang ingin Anda pahami lebih dalam.

Silakan pilih topik cepat di bawah atau tulis pertanyaan Anda secara spesifik!''',
      isUser: false,
      timestamp: DateTime.now(),
      type: AiMessageType.text,
      relatedCourseName: course,
    );
  }

  List<QuizItem> _buildSimulatedQuiz(String course) {
    return [
      QuizItem(
        question: 'Dalam pengembangan aplikasi berorientasi objek di $course, apa tujuan utama penerapan enkapsulasi (*encapsulation*)?',
        options: [
          'Menyembunyikan detail implementasi internal dan melindungi integritas state data objek',
          'Membuat semua variabel dapat diakses secara publik dari file manapun',
          'Mempercepat proses kompilasi tanpa perlu pembuatan getter atau setter',
          'Menggabungkan semua fungsi menjadi satu fungsi global raksasa',
        ],
        correctIndex: 0,
        explanation: 'Enkapsulasi membungkus data dan metode ke dalam satu unit, membatasi akses langsung dari luar objek untuk mencegah manipulasi data yang tidak valid.',
      ),
      QuizItem(
        question: 'Manakah prinsip penanganan error yang direkomendasikan saat mengakses REST API atau Database?',
        options: [
          'Menggunakan blok catch kosong agar aplikasi tidak menampilkan pesan error',
          'Menerapkan timeout, try-catch bertipe, dan memberikan feedback jelas kepada user',
          'Membiarkan aplikasi crash jika koneksi internet terputus',
          'Menyimpan token autentikasi di URL query parameter secara terbuka',
        ],
        correctIndex: 1,
        explanation: 'Penanganan error yang baik wajib menangani timeout, menangkap exception secara spesifik, dan menampilkan pesan yang ramah pengguna.',
      ),
      QuizItem(
        question: 'Apa fungsi utama status "Completion" pada setiap sub-section di LMS Sakura UNPAM?',
        options: [
          'Menghapus materi dari server pusat setelah selesai dibaca',
          'Mencatat ketercapaian dan pemenuhan syarat kelulusan absensi aktivitas mahasiswa',
          'Mengirimkan email otomatis ke seluruh dosen fakultas',
          'Mengunci mahasiswa agar tidak dapat mengakses pertemuan berikutnya',
        ],
        correctIndex: 1,
        explanation: 'Completion di LMS mencatat keikutsertaan mahasiswa dalam mengakses materi, menyelesaikan kuis, atau mengirimkan tugas pada pertemuan terkait.',
      ),
    ];
  }
}
