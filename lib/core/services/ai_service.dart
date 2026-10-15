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
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 35),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Memvalidasi keaslian Gemini API Key via endpoint models resmi Google tanpa menghabiskan kuota token
  Future<bool> validateGeminiApiKey(String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) return false;

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models?key=$cleanKey';

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Memproses prompt mahasiswa secara cerdas menggunakan Real LLM Engine:
  /// 1. Jika ada Gemini API Key: gunakan Google Gemini 1.5/2.0 Flash (Multimodal OCR gambar + teks).
  /// 2. Jika tidak ada Gemini API Key atau terkena limit: gunakan Cloud AI Engine (OpenAI/LLaMA) untuk menghasilkan jawaban asli, BUKAN template statis.
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

    // 1. Cek Cache jika teks saja (hemat waktu & token)
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
    final now = DateTime.now();
    final inCooldown = _rateLimitedUntil != null && now.isBefore(_rateLimitedUntil!);

    // JIKA USER MENYEDIAKAN GEMINI API KEY & TIDAK COOLDOWN
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
          _rateLimitedUntil = now.add(const Duration(seconds: 45));
          // Fallback ke Cloud AI jika bukan gambar
          if (!hasImage) {
            return await _askFreeCloudAi(
              prompt: cleanPrompt,
              courseName: courseName,
              rateLimitNotice:
                  '⚠️ *Batas kuota Gemini (Rate Limit 429) tercapai. Asisten otomatis beralih ke Cloud AI untuk menjawab soal Anda.*\n\n',
            );
          } else {
            return AiMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  '⚠️ Kuota request Google Gemini API Anda mencapai batas harian / menit (Rate Limit 429). Mohon tunggu sekitar 1 menit sebelum mengirim gambar kembali.',
              isUser: false,
              timestamp: DateTime.now(),
              relatedCourseName: courseName,
            );
          }
        } else if (code == 400 || code == 403) {
          return AiMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                '❌ **API Key Google Gemini Tidak Valid / Akses Ditolak ($code)**\n\n'
                'Google menolak kunci API yang tersimpan. Silakan periksa kembali API Key Anda melalui tombol kunci 🔑 di pojok kanan atas.',
            isUser: false,
            timestamp: DateTime.now(),
            relatedCourseName: courseName,
          );
        }

        // Jika error jaringan lain pada Gemini, fallback ke Cloud AI
        if (!hasImage) {
          return await _askFreeCloudAi(
            prompt: cleanPrompt,
            courseName: courseName,
          );
        } else {
          return AiMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                'Gagal menghubungi server Gemini (${e.message}). Pastikan koneksi internet Anda stabil.',
            isUser: false,
            timestamp: DateTime.now(),
            relatedCourseName: courseName,
          );
        }
      } catch (e) {
        if (!hasImage) {
          return await _askFreeCloudAi(
            prompt: cleanPrompt,
            courseName: courseName,
          );
        }
        return AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Terjadi kendala saat menganalisis gambar: $e',
          isUser: false,
          timestamp: DateTime.now(),
          relatedCourseName: courseName,
        );
      }
    }

    // JIKA TIDAK ADA GEMINI API KEY
    // Jika melampirkan gambar tanpa Gemini API Key:
    if (hasImage) {
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            '📷 **Screenshot Gambar Diterima**\n\n'
            'Untuk membaca dan menganalisis soal kuis langsung dari screenshot gambar dengan Google Vision AI, silakan masukkan **Google Gemini API Key** Anda.\n\n'
            'API Key ini **100% Gratis** resmi dari Google:\n'
            '1. Ketuk tombol kunci 🔑 di pojok kanan atas layar ini.\n'
            '2. Buka link Google AI Studio dan salin API Key Anda.\n'
            '3. Tempel dan simpan di aplikasi.\n\n'
            '*Catatan: Untuk pertanyaan berupa teks atau soal yang diekstrak langsung dari web portal, Anda dapat langsung bertanya tanpa memerlukan API Key!*',
        isUser: false,
        timestamp: DateTime.now(),
        relatedCourseName: courseName,
      );
    }

    // Eksekusi Real Cloud AI (Zero Setup, Real Answers)
    final result = await _askFreeCloudAi(
      prompt: cleanPrompt,
      courseName: courseName,
    );
    _cache[cacheKey] = result;
    return result;
  }

  static const List<String> _geminiCandidateModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-3.8-flash',
    'gemini-flash-latest',
    'gemini-2.5-flash',
    'gemini-1.5-flash',
  ];

  /// Engine Google Gemini (Multimodal Vision OCR & Fast Text)
  Future<AiMessage> _askGemini({
    required String apiKey,
    required String prompt,
    String? courseName,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final systemPrompt =
        'Anda adalah UNPAM AI Study Assistant, asisten akademik cerdas untuk mahasiswa Universitas Pamulang. '
        'Jawab pertanyaan atau tugas mahasiswa secara tepat, mendalam, akurat, to-the-point, dan edukatif dalam Bahasa Indonesia yang profesional dan ramah. '
        'Jika pertanyaan adalah soal kuis pilihan ganda, sebutkan opsi jawaban yang benar secara tegas di awal, kemudian berikan pembahasan rasional dan konsep dasarnya. '
        'Jika pertanyaan adalah tugas pemrograman, berikan kode solusi yang bersih, modular, aman, dan siap dijalankan beserta penjelasannya. '
        'Jika pengguna meminta latihan soal/kuis, sertakan 2-3 soal pilihan ganda di akhir dengan format JSON khusus dalam tag ```json_quiz [{"question": "...", "options": ["A. ...", "B. ...", "C. ...", "D. ..."], "correctIndex": 0, "explanation": "..."}] ```. '
        'Konteks Mata Kuliah: ${courseName ?? "Umum / Universitas Pamulang"}.';

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
          '${imageBytes != null ? "Perintah OCR Vision: Bacalah teks soal, pilihan opsi, atau instruksi pada gambar screenshot ini secara teliti. Berikan jawaban yang tepat dan analisis pembahasannya.\n\n" : ""}'
          'Pertanyaan / Teks Mahasiswa:\n$prompt'
    });

    final body = {
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 1800,
      }
    };

    DioException? lastDioError;

    for (final model in _geminiCandidateModels) {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      try {
        final response = await _dio.post<Map<String, dynamic>>(
          url,
          data: body,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

        final candidates = response.data?['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates.first['content']?['parts']?[0]?['text']?.toString() ?? '';
          if (text.isNotEmpty) {
            return _parseQuizAndBuildMessage(text, courseName);
          }
        }
      } on DioException catch (e) {
        lastDioError = e;
        final code = e.response?.statusCode;
        if (code == 400 || code == 403) {
          rethrow;
        }
        if (code == 429) {
          rethrow;
        }
        continue;
      }
    }

    if (lastDioError != null) {
      throw lastDioError;
    }

    throw Exception('Tidak ada model Gemini yang merespons.');
  }

  /// Engine Real Cloud LLM (OpenAI / LLaMA) Bebas API Key
  Future<AiMessage> _askFreeCloudAi({
    required String prompt,
    String? courseName,
    String? rateLimitNotice,
  }) async {
    final systemPrompt =
        'Anda adalah UNPAM AI Study Assistant, asisten akademik cerdas untuk mahasiswa Universitas Pamulang. '
        'Jawab pertanyaan atau tugas mahasiswa secara tepat, to-the-point, akurat, dan edukatif dalam Bahasa Indonesia. '
        'Jika pertanyaan adalah soal kuis pilihan ganda, sebutkan opsi jawaban yang benar beserta penjelasan lengkapnya. '
        'Jika pertanyaan berupa tugas pemrograman, sertakan contoh kode yang benar dan penjelasannya. '
        'Jangan memberikan jawaban template kosong atau jawaban umum yang tidak berhubungan. Jawablah langsung sesuai pertanyaan yang diajukan. '
        'Konteks mata kuliah saat ini: ${courseName ?? "Umum Universitas Pamulang"}.';

    try {
      final response = await _dio.post<dynamic>(
        'https://text.pollinations.ai/',
        data: {
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt}
          ],
          'model': 'openai',
          'jsonMode': false,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final rawData = response.data?.toString() ?? '';
      if (rawData.trim().isNotEmpty) {
        final content = rateLimitNotice != null ? '$rateLimitNotice$rawData' : rawData;
        return _parseQuizAndBuildMessage(content, courseName);
      }
    } catch (_) {
      // Fallback ke GET endpoint jika POST mengalami kendala
      try {
        final query = '$systemPrompt\n\nPertanyaan: $prompt';
        final getUrl = 'https://text.pollinations.ai/${Uri.encodeComponent(query.substring(0, query.length.clamp(0, 1500)))}';
        final res = await _dio.get<dynamic>(getUrl);
        final rawData = res.data?.toString() ?? '';
        if (rawData.trim().isNotEmpty) {
          final content = rateLimitNotice != null ? '$rateLimitNotice$rawData' : rawData;
          return _parseQuizAndBuildMessage(content, courseName);
        }
      } catch (err) {
        return AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content:
              'Tidak dapat memuat jawaban dari server AI ($err). Pastikan perangkat Anda terhubung ke internet, atau gunakan API Key Gemini Anda sendiri untuk koneksi langsung.',
          isUser: false,
          timestamp: DateTime.now(),
          relatedCourseName: courseName,
        );
      }
    }

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content:
          'Maaf, server AI saat ini sedang sibuk. Silakan ulangi pertanyaan Anda atau masukkan Google Gemini API Key Anda untuk prioritas akses instan.',
      isUser: false,
      timestamp: DateTime.now(),
      relatedCourseName: courseName,
    );
  }

  AiMessage _parseQuizAndBuildMessage(String text, String? courseName) {
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
}
