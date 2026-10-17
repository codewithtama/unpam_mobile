import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import '../../models/ai_message_model.dart';
import '../../models/paraphrase_model.dart';
import '../../models/ai_model_config.dart';

class AiService {
  final StorageService _storage;
  final Dio _dio = Dio();

  final Map<String, AiMessage> _cache = {};
  DateTime? _rateLimitedUntil;

  AiService(this._storage) {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 45),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Memvalidasi keaslian API Key untuk setiap provider LLM
  Future<bool> validateApiKey(AiProviderType provider, String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) return false;

    try {
      switch (provider) {
        case AiProviderType.gemini:
          final url =
              'https://generativelanguage.googleapis.com/v1beta/models?key=$cleanKey';
          final res = await _dio.get<Map<String, dynamic>>(
            url,
            options: Options(
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );
          return res.statusCode == 200;

        case AiProviderType.deepseek:
          final res = await _dio.get<Map<String, dynamic>>(
            'https://api.deepseek.com/models',
            options: Options(
              headers: {'Authorization': 'Bearer $cleanKey'},
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );
          return res.statusCode == 200;

        case AiProviderType.claude:
          try {
            final res = await _dio.get<Map<String, dynamic>>(
              'https://api.anthropic.com/v1/models',
              options: Options(
                headers: {
                  'x-api-key': cleanKey,
                  'anthropic-version': '2023-06-01',
                },
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );
            if (res.statusCode == 200) return true;
          } catch (_) {}

          final resMsg = await _dio.post<Map<String, dynamic>>(
            'https://api.anthropic.com/v1/messages',
            data: {
              'model': 'claude-haiku-5-5',
              'max_tokens': 10,
              'messages': [
                {'role': 'user', 'content': 'hi'}
              ],
            },
            options: Options(
              headers: {
                'x-api-key': cleanKey,
                'anthropic-version': '2023-06-01',
                'content-type': 'application/json',
              },
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );
          return resMsg.statusCode == 200;

        case AiProviderType.openai:
          final res = await _dio.get<Map<String, dynamic>>(
            'https://api.openai.com/v1/models',
            options: Options(
              headers: {'Authorization': 'Bearer $cleanKey'},
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );
          return res.statusCode == 200;

        case AiProviderType.qwen:
          try {
            final res = await _dio.get<Map<String, dynamic>>(
              'https://dashscope-intl.aliyuncs.com/compatible-mode/v1/models',
              options: Options(
                headers: {'Authorization': 'Bearer $cleanKey'},
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );
            if (res.statusCode == 200) return true;
          } catch (_) {}

          final resMainland = await _dio.get<Map<String, dynamic>>(
            'https://dashscope.aliyuncs.com/compatible-mode/v1/models',
            options: Options(
              headers: {'Authorization': 'Bearer $cleanKey'},
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );
          return resMainland.statusCode == 200;

        case AiProviderType.openrouter:
          final res = await _dio.get<Map<String, dynamic>>(
            'https://openrouter.ai/api/v1/auth/key',
            options: Options(
              headers: {'Authorization': 'Bearer $cleanKey'},
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );
          return res.statusCode == 200;

        case AiProviderType.freeCloud:
          return true;
      }
    } catch (_) {
      return false;
    }
  }

  /// Backward compatibility untuk validasi Gemini API Key
  Future<bool> validateGeminiApiKey(String key) async {
    return validateApiKey(AiProviderType.gemini, key);
  }

  /// Memproses prompt mahasiswa menggunakan model AI aktif yang dipilih
  Future<AiMessage> askAssistant({
    required String prompt,
    String? courseName,
    List<String>? availableCourses,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final cleanPrompt = prompt.trim();
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;
    final activeModelId = _storage.getActiveAiModelId();
    final activeOption = AiModelOption.getById(activeModelId);
    final cacheKey = '${activeModelId}_${courseName ?? "all"}_${cleanPrompt.toLowerCase()}';

    // 1. Cek Cache jika teks saja (hemat waktu & kuota token)
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

    final apiKey = _storage.getProviderApiKey(activeOption.provider);
    final now = DateTime.now();
    final inCooldown = _rateLimitedUntil != null && now.isBefore(_rateLimitedUntil!);

    // JIKA USER MEMILIH MODEL DENGAN API KEY & MEMILIKI KEY VALID
    if (activeOption.provider != AiProviderType.freeCloud &&
        apiKey != null &&
        apiKey.isNotEmpty &&
        !inCooldown) {
      try {
        // Cek jika gambar dikirimkan ke model yang belum mendukung Vision
        if (hasImage && !activeOption.supportsVision) {
          // Jika ada kunci Gemini tersimpan, otomatis pinjam mata Vision Gemini
          final geminiKey = _storage.getGeminiApiKey();
          if (geminiKey != null && geminiKey.isNotEmpty) {
            return await _askGemini(
              apiKey: geminiKey,
              prompt: cleanPrompt,
              courseName: courseName,
              imageBytes: imageBytes,
              mimeType: mimeType,
            );
          }
          return AiMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                'Model ${activeOption.name} berfokus pada penalaran teks murni dan belum mendukung input gambar screenshot secara langsung.\n\n'
                '💡 Saran: Untuk menganalisis screenshot soal kuis dengan Vision OCR, pilih model **Google Gemini** atau **Anthropic Claude 3.5** melalui pemilih model di bagian atas.',
            isUser: false,
            timestamp: DateTime.now(),
            relatedCourseName: courseName,
          );
        }

        final resultText = await _executeModelCall(
          option: activeOption,
          apiKey: apiKey,
          prompt: cleanPrompt,
          courseName: courseName,
          imageBytes: imageBytes,
          mimeType: mimeType,
        );

        final msg = _parseQuizAndBuildMessage(resultText, courseName);
        if (!hasImage) _cache[cacheKey] = msg;
        return msg;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 429) {
          _rateLimitedUntil = now.add(const Duration(seconds: 45));
          if (!hasImage) {
            return await _askFreeCloudAi(
              prompt: cleanPrompt,
              courseName: courseName,
              rateLimitNotice:
                  '[Info] Batas kuota ${activeOption.shortName} (Rate Limit 429) tercapai. Asisten otomatis beralih ke Cloud AI untuk menjawab soal Anda.\n\n',
            );
          }
        } else if (code == 401 || code == 403) {
          return AiMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                '[Error] API Key ${activeOption.shortName} Ditolak ($code)\n\n'
                'Kunci API yang tersimpan tidak valid atau saldo akun habis. Silakan periksa kunci API Anda melalui tombol pengaturan model.',
            isUser: false,
            timestamp: DateTime.now(),
            relatedCourseName: courseName,
          );
        }

        // Fallback ke Cloud AI jika terjadi gangguan jaringan pada provider
        if (!hasImage) {
          return await _askFreeCloudAi(
            prompt: cleanPrompt,
            courseName: courseName,
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

    // JIKA TIDAK ADA KEY ATAU MODEL FREE_CLOUD DIPILIH
    if (hasImage) {
      final geminiKey = _storage.getGeminiApiKey();
      if (geminiKey != null && geminiKey.isNotEmpty) {
        return await _askGemini(
          apiKey: geminiKey,
          prompt: cleanPrompt,
          courseName: courseName,
          imageBytes: imageBytes,
          mimeType: mimeType,
        );
      }
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            '[Screenshot Gambar Diterima]\n\n'
            'Untuk membaca dan menganalisis soal kuis langsung dari screenshot gambar menggunakan Vision OCR, silakan masukkan API Key Gemini atau Claude Anda di menu pengaturan model (ikon kunci / model di kanan atas).\n\n'
            'Catatan: Untuk pertanyaan berupa teks atau soal yang diekstrak langsung dari web portal LMS, Anda dapat langsung bertanya tanpa memerlukan API Key!',
        isUser: false,
        timestamp: DateTime.now(),
        relatedCourseName: courseName,
      );
    }

    final result = await _askFreeCloudAi(
      prompt: cleanPrompt,
      courseName: courseName,
    );
    _cache[cacheKey] = result;
    return result;
  }

  /// Eksekutor panggilan API ke masing-masing provider LLM
  Future<String> _executeModelCall({
    required AiModelOption option,
    required String apiKey,
    required String prompt,
    String? courseName,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final systemPrompt =
        'Anda adalah UNPAM AI, asisten akademik cerdas untuk mahasiswa Universitas Pamulang. '
        'Jawab pertanyaan atau tugas mahasiswa secara tepat, mendalam, akurat, to-the-point, dan edukatif dalam Bahasa Indonesia yang profesional dan ramah. '
        'Jika pertanyaan adalah soal kuis pilihan ganda, sebutkan opsi jawaban yang benar secara tegas di awal, kemudian berikan pembahasan rasional dan konsep dasarnya. '
        'Jika pertanyaan adalah tugas pemrograman, berikan kode solusi yang bersih, modular, aman, dan siap dijalankan beserta penjelasannya. '
        'Jika pengguna meminta latihan soal/kuis, sertakan 2-3 soal pilihan ganda di akhir dengan format JSON khusus dalam tag ```json_quiz [{"question": "...", "options": ["A. ...", "B. ...", "C. ...", "D. ..."], "correctIndex": 0, "explanation": "..."}] ```. '
        'Konteks Mata Kuliah: ${courseName ?? "Umum / Universitas Pamulang"}.';

    switch (option.provider) {
      case AiProviderType.gemini:
        final geminiMsg = await _askGemini(
          apiKey: apiKey,
          prompt: prompt,
          courseName: courseName,
          imageBytes: imageBytes,
          mimeType: mimeType,
        );
        return geminiMsg.content;

      case AiProviderType.deepseek:
        final modelsToTry = [
          option.defaultModelId,
          ..._deepseekCandidateModels.where((m) => m != option.defaultModelId),
        ];
        DioException? lastDeepseekErr;
        for (final m in modelsToTry) {
          try {
            return await _callOpenAiCompatible(
              url: 'https://api.deepseek.com/chat/completions',
              apiKey: apiKey,
              model: m,
              systemPrompt: systemPrompt,
              userPrompt: prompt,
            );
          } on DioException catch (e) {
            lastDeepseekErr = e;
            final code = e.response?.statusCode;
            if (code == 401 || code == 403 || code == 429) rethrow;
            continue;
          }
        }
        if (lastDeepseekErr != null) throw lastDeepseekErr;
        throw Exception('DeepSeek API tidak memberikan respons');

      case AiProviderType.claude:
        return await _callClaude(
          apiKey: apiKey,
          model: option.defaultModelId,
          systemPrompt: systemPrompt,
          userPrompt: prompt,
          imageBytes: imageBytes,
          mimeType: mimeType,
        );

      case AiProviderType.qwen:
        final qwenModelsToTry = [
          option.defaultModelId,
          ..._qwenCandidateModels.where((m) => m != option.defaultModelId),
        ];
        final endpoints = [
          'https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions',
          'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
        ];
        DioException? lastQwenErr;
        for (final url in endpoints) {
          for (final m in qwenModelsToTry) {
            try {
              return await _callOpenAiCompatible(
                url: url,
                apiKey: apiKey,
                model: m,
                systemPrompt: systemPrompt,
                userPrompt: prompt,
              );
            } on DioException catch (e) {
              lastQwenErr = e;
              final code = e.response?.statusCode;
              if (code == 401 || code == 403) {
                // Mungkin region akun berbeda (intl vs mainland), coba endpoint berikutnya
                break;
              }
              if (code == 429) rethrow;
              continue;
            }
          }
        }
        if (lastQwenErr != null) throw lastQwenErr;
        throw Exception('Alibaba Qwen DashScope API tidak memberikan respons');

      case AiProviderType.openai:
        return await _callOpenAiWithVision(
          url: 'https://api.openai.com/v1/chat/completions',
          apiKey: apiKey,
          model: option.defaultModelId,
          systemPrompt: systemPrompt,
          userPrompt: prompt,
          imageBytes: imageBytes,
          mimeType: mimeType,
        );

      case AiProviderType.openrouter:
        return await _callOpenAiWithVision(
          url: 'https://openrouter.ai/api/v1/chat/completions',
          apiKey: apiKey,
          model: option.defaultModelId,
          systemPrompt: systemPrompt,
          userPrompt: prompt,
          imageBytes: imageBytes,
          mimeType: mimeType,
          extraHeaders: {
            'HTTP-Referer': 'https://mentari.unpam.ac.id',
            'X-Title': 'UNPAM Mobile App',
          },
        );

      case AiProviderType.freeCloud:
        final cloudMsg = await _askFreeCloudAi(
          prompt: prompt,
          courseName: courseName,
        );
        return cloudMsg.content;
    }
  }

  // --- Implementasi Protokol Provider Khusus ---

  static const List<String> _geminiCandidateModels = [
    'gemini-3.7-flash',
    'gemini-3.5-flash',
    'gemini-flash-latest',
    'gemini-3.1-pro-preview',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static const List<String> _claudeCandidateModels = [
    'claude-sonnet-5-5',
    'claude-haiku-5-5',
    'claude-opus-5-5',
    'claude-fable-5-1',
    'claude-3-7-sonnet-20250219',
    'claude-3-5-sonnet-20241022',
    'claude-3-haiku-20240307',
  ];

  static const List<String> _deepseekCandidateModels = [
    'deepseek-v4-flash',
    'deepseek-v4-pro',
    'deepseek-chat',
  ];

  static const List<String> _qwenCandidateModels = [
    'qwen3.8-max',
    'qwen3.7-max',
    'qwen-max',
    'qwen-plus',
    'qwen-turbo',
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
        'Anda adalah UNPAM AI, asisten akademik cerdas untuk mahasiswa Universitas Pamulang. '
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
          options: Options(headers: {'Content-Type': 'application/json'}),
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
        if (code == 400 || code == 401 || code == 403 || code == 429) {
          rethrow;
        }
        continue;
      }
    }

    if (lastDioError != null) throw lastDioError;
    throw Exception('Tidak ada model Gemini yang merespons.');
  }

  /// Protokol Anthropic Claude (Messages API) dengan fallback model cerdas
  Future<String> _callClaude({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final List<Map<String, dynamic>> contentParts = [];
    if (imageBytes != null && imageBytes.isNotEmpty) {
      contentParts.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': mimeType ?? 'image/jpeg',
          'data': base64Encode(imageBytes),
        }
      });
    }

    contentParts.add({
      'type': 'text',
      'text': userPrompt,
    });

    final modelsToTry = [
      model,
      ..._claudeCandidateModels.where((m) => m != model),
    ];

    DioException? lastDioError;
    for (final candidate in modelsToTry) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          'https://api.anthropic.com/v1/messages',
          data: {
            'model': candidate,
            'max_tokens': 2048,
            'system': systemPrompt,
            'messages': [
              {'role': 'user', 'content': contentParts}
            ],
          },
          options: Options(
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 50),
          ),
        );

        final content = response.data?['content'] as List<dynamic>?;
        if (content != null && content.isNotEmpty) {
          final text = content.first['text']?.toString() ?? '';
          if (text.isNotEmpty) return text;
        }
      } on DioException catch (e) {
        lastDioError = e;
        final code = e.response?.statusCode;
        if (code == 401 || code == 403 || code == 429) {
          rethrow;
        }
        continue;
      }
    }

    if (lastDioError != null) throw lastDioError;
    throw Exception('Respons kosong dari Claude API');
  }

  /// Protokol OpenAI-Compatible Standard (DeepSeek, Qwen, Groq, dll)
  Future<String> _callOpenAiCompatible({
    required String url,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.4,
      },
      options: Options(
        headers: headers,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 50),
      ),
    );

    final choices = response.data?['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final msg = choices.first['message'];
      final content = msg?['content']?.toString() ?? '';
      if (content.isNotEmpty) return content;
      final reasoning = msg?['reasoning_content']?.toString() ?? '';
      if (reasoning.isNotEmpty) return reasoning;
    }
    throw Exception('Respons kosong dari server $model');
  }

  /// Protokol OpenAI Vision Multimodal (GPT-4o & OpenRouter Vision)
  Future<String> _callOpenAiWithVision({
    required String url,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    Uint8List? imageBytes,
    String? mimeType,
    Map<String, String>? extraHeaders,
  }) async {
    final List<Map<String, dynamic>> userContent = [];
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final b64 = base64Encode(imageBytes);
      final media = mimeType ?? 'image/jpeg';
      userContent.add({
        'type': 'image_url',
        'image_url': {'url': 'data:$media;base64,$b64'}
      });
    }

    userContent.add({
      'type': 'text',
      'text': userPrompt,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userContent},
        ],
        'temperature': 0.4,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          ...?extraHeaders,
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 50),
      ),
    );

    final choices = response.data?['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final msg = choices.first['message'];
      final text = msg?['content']?.toString() ?? '';
      if (text.isNotEmpty) return text;
      final reasoning = msg?['reasoning_content']?.toString() ?? '';
      if (reasoning.isNotEmpty) return reasoning;
    }
    throw Exception('Respons kosong dari model $model');
  }

  /// Engine Real Cloud LLM Bebas API Key
  Future<AiMessage> _askFreeCloudAi({
    required String prompt,
    String? courseName,
    String? rateLimitNotice,
  }) async {
    final systemPrompt =
        'Anda adalah UNPAM AI, asisten akademik cerdas untuk mahasiswa Universitas Pamulang. '
        'Jawab pertanyaan atau tugas mahasiswa secara tepat, to-the-point, akurat, dan edukatif dalam Bahasa Indonesia. '
        'Jika pertanyaan adalah soal kuis pilihan ganda, sebutkan opsi jawaban yang benar beserta penjelasan lengkapnya. '
        'Jika pertanyaan berupa tugas pemrograman, sertakan contoh kode yang benar dan penjelasannya. '
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
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 35),
        ),
      );

      final rawData = response.data?.toString() ?? '';
      if (rawData.trim().isNotEmpty) {
        final content = rateLimitNotice != null ? '$rateLimitNotice$rawData' : rawData;
        return _parseQuizAndBuildMessage(content, courseName);
      }
    } catch (_) {
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
              'Tidak dapat memuat jawaban dari server AI ($err). Pastikan perangkat Anda terhubung ke internet, atau masukkan API Key Anda untuk koneksi langsung.',
          isUser: false,
          timestamp: DateTime.now(),
          relatedCourseName: courseName,
        );
      }
    }

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content:
          'Maaf, server AI saat ini sedang sibuk. Silakan ulangi pertanyaan Anda atau gunakan API Key kustom Anda untuk prioritas akses instan.',
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

  /// Menghubungi LLM aktif untuk menghasilkan string mentah (Diskusi, Kuis, Parafrase)
  Future<String> askRawLlm({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final activeModelId = _storage.getActiveAiModelId();
    final activeOption = AiModelOption.getById(activeModelId);
    final apiKey = _storage.getProviderApiKey(activeOption.provider);

    if (activeOption.provider != AiProviderType.freeCloud && apiKey != null && apiKey.isNotEmpty) {
      try {
        return await _executeModelCall(
          option: activeOption,
          apiKey: apiKey,
          prompt: userPrompt,
        );
      } catch (_) {
        // Fallback otomatis ke Cloud AI jika terjadi kendala pada model aktif
      }
    }

    // Fallback ke Cloud AI (Pollinations API)
    try {
      final response = await _dio.post<dynamic>(
        'https://text.pollinations.ai/',
        data: {
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt}
          ],
          'model': 'openai',
          'jsonMode': false,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 35),
        ),
      );
      final rawData = response.data?.toString() ?? '';
      if (rawData.trim().isNotEmpty) return rawData.trim();
    } catch (_) {
      try {
        final query = '$systemPrompt\n\n$userPrompt';
        final getUrl = 'https://text.pollinations.ai/${Uri.encodeComponent(query.substring(0, query.length.clamp(0, 1500)))}';
        final res = await _dio.get<dynamic>(getUrl);
        final rawData = res.data?.toString() ?? '';
        if (rawData.trim().isNotEmpty) return rawData.trim();
      } catch (err) {
        throw Exception('Gagal menghubungi server AI ($err). Pastikan koneksi internet stabil.');
      }
    }

    throw Exception('Layanan AI tidak memberikan respons.');
  }

  /// Membantu menyusun tanggapan diskusi perkuliahan yang mengalir alami dan bernalar akademis
  Future<String> generateForumReply({
    required String topic,
    String? courseName,
  }) async {
    const systemPrompt =
        'Anda adalah seorang mahasiswa aktif dan kritis di Universitas Pamulang yang sedang berpartisipasi dalam Forum Diskusi perkuliahan. '
        'Tuliskan tanggapan atau opini diskusi dengan gaya bahasa manusiawi yang alami, lugas, mengalir, dan bernalar akademis.\n'
        'Pedoman penting agar tulisan terdengar seperti buatan manusia orisinal:\n'
        '1. Hindari kalimat pembuka klise bot AI seperti "Tentu, berikut adalah tanggapan saya...", "Sebagai mahasiswa...", atau pengantar basa-basi kosong. Langsung masuk ke inti argumen atau sudut pandang Anda.\n'
        '2. Gunakan gaya bahasa Indonesia yang luwes, santun, dan logis. Sajikan penalaran yang jelas serta contoh konkret kontekstual di dunia nyata/industri.\n'
        '3. Susun dalam bentuk paragraf naratif yang runtut dan berbobot (hindari format bullet-points yang berlebihan dan kaku).\n'
        '4. Akhiri dengan simpulan padat dan salam penutup standar mahasiswa yang bersahabat (misalnya: "Sekian tanggapan dari saya, mohon koreksi dan masukannya. Terima kasih."). JANGAN gunakan emoji apapun.';

    final userPrompt =
        'Mata Kuliah: ${courseName ?? "Perkuliahan UNPAM"}\n\n'
        'Topik / Pertanyaan Diskusi Dosen:\n"""\n$topic\n"""\n\n'
        'Tuliskan draf tanggapan diskusi forum yang bernalar akademis dan mengalir alami:';

    return await askRawLlm(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );
  }

  /// Menelaah butir soal kuis perkuliahan dan memberikan rekomendasi rujukan jawaban
  Future<List<Map<String, dynamic>>> solveQuizQuestions({
    required List<Map<String, dynamic>> questions,
    String? courseName,
  }) async {
    const systemPrompt =
        'Anda adalah rekan belajar dan tutor akademik Universitas Pamulang yang teliti dan berwawasan luas. '
        'Tugas Anda adalah menelaah setiap butir soal kuis perkuliahan dan merekomendasikan opsi jawaban yang paling tepat berdasarkan konsep materi yang benar.\n'
        'Berikan ulasan telaah singkat (1-2 kalimat bernada edukatif, wajar, dan logis seperti catatan belajar mahasiswa) pada kolom "reason".\n'
        'Wajib kembalikan HANYA format JSON valid tanpa tag codeblock markdown atau teks pembuka/penutup:\n'
        '[{"index": 0, "correctOptionIndex": 1, "correctOptionText": "B. ...", "confidence": 95, "reason": "Berdasarkan prinsip dasar..."}]\n'
        'Perhatikan bahwa "index" harus sesuai dengan index soal yang diberikan (0, 1, ...), dan "correctOptionIndex" adalah indeks opsi (0 untuk opsi ke-1, 1 untuk opsi ke-2, dst). JANGAN gunakan emoji.';

    final buffer = StringBuffer();
    buffer.writeln('Mata Kuliah: ${courseName ?? "Perkuliahan UNPAM"}\n');
    buffer.writeln('Telaah daftar soal pilihan ganda berikut dan berikan rekomendasi rujukan jawaban yang paling tepat:\n');

    for (final q in questions) {
      buffer.writeln('Soal #${q['index']}: ${q['questionText']}');
      final opts = q['options'] as List<dynamic>? ?? [];
      for (int i = 0; i < opts.length; i++) {
        final opt = opts[i];
        final text = opt['optionText'] ?? '';
        buffer.writeln('  - Opsi $i: $text');
      }
      buffer.writeln('');
    }

    final raw = await askRawLlm(
      systemPrompt: systemPrompt,
      userPrompt: buffer.toString(),
    );

    // Bersihkan pembungkus code block jika ada
    String jsonStr = raw.trim();
    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7);
    } else if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.substring(3);
    }
    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 3);
    }
    jsonStr = jsonStr.trim();

    final startIdx = jsonStr.indexOf('[');
    final endIdx = jsonStr.lastIndexOf(']');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      jsonStr = jsonStr.substring(startIdx, endIdx + 1);
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      final List<Map<String, dynamic>> fallbackList = [];
      for (final q in questions) {
        fallbackList.add({
          'index': q['index'],
          'correctOptionIndex': 0,
          'correctOptionText': '',
          'confidence': 70,
          'reason': 'Analisis otomatis AI (fallback parsing).',
        });
      }
      return fallbackList;
    }
  }

  /// Menganalisis butir kuesioner dosen / evaluasi perkuliahan Mentari
  Future<Map<String, dynamic>> analyzeQuestionnaire({
    required List<Map<String, dynamic>> questions,
    String? courseName,
    bool includeFeedbackDraft = true,
  }) async {
    const systemPrompt =
        'Anda adalah asisten akademik Universitas Pamulang yang bertugas menelaah evaluasi perkuliahan dan kuesioner dosen secara objektif, santun, dan konstruktif.\n'
        'Tugas Anda:\n'
        '1. Telaah setiap butir kuesioner perkuliahan/dosen.\n'
        '2. Tentukan rekomendasi indeks opsi jawaban yang paling tepat ("recommendedOptionIndex", dimulai dari 0). Untuk butir positif mengenai kelancaran perkuliahan (kehadiran tepat waktu, materi LMS tersedia, bimbingan baik), utamakan opsi "Ya" atau evaluasi positif tertinggi (misal Sangat Baik / Sangat Setuju). Jika ada butir bernada negatif/kendala, sesuaikan secara logis.\n'
        '3. Buatkan draf catatan saran/masukan untuk dosen ("feedbackSuggestion") yang santun, apresiatif, konstruktif, dan bernalar akademis (2-3 kalimat, tanpa emoji).\n'
        'Wajib kembalikan HANYA format JSON valid tanpa code block markdown atau teks pembuka/penutup:\n'
        '{\n'
        '  "answers": [\n'
        '    {"index": 0, "recommendedOptionIndex": 0, "reason": "Evaluasi positif pelaksanaan perkuliahan."}\n'
        '  ],\n'
        '  "feedbackSuggestion": "Penyampaian materi dan modul pembelajaran di LMS sangat jelas dan terstruktur dengan baik. Terima kasih kepada Bapak/Ibu dosen atas dedikasi dan bimbingannya."\n'
        '}\n'
        'JANGAN gunakan emoji apa pun.';

    final buffer = StringBuffer();
    buffer.writeln('Mata Kuliah / Halaman: ${courseName ?? "Evaluasi Perkuliahan UNPAM"}\n');
    buffer.writeln('Daftar Butir Kuesioner:\n');

    for (final q in questions) {
      buffer.writeln('Butir #${q['index']}: ${q['questionText']}');
      final opts = q['options'] as List<dynamic>? ?? [];
      for (int i = 0; i < opts.length; i++) {
        final opt = opts[i];
        final text = opt['optionText'] ?? '';
        buffer.writeln('  - Opsi $i: $text');
      }
      buffer.writeln('');
    }

    try {
      final raw = await askRawLlm(
        systemPrompt: systemPrompt,
        userPrompt: buffer.toString(),
      );

      String jsonStr = raw.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final startIdx = jsonStr.indexOf('{');
      final endIdx = jsonStr.lastIndexOf('}');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        jsonStr = jsonStr.substring(startIdx, endIdx + 1);
      }

      final Map<String, dynamic> decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> answersList = decoded['answers'] as List<dynamic>? ?? [];
      final parsedAnswers = answersList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final feedback = (decoded['feedbackSuggestion'] ?? '').toString();

      return {
        'answers': parsedAnswers,
        'feedbackSuggestion': feedback.isNotEmpty
            ? feedback
            : 'Penyampaian materi dan modul ajar di LMS sangat lengkap dan terstruktur. Terima kasih kepada Bapak/Ibu dosen atas bimbingannya.',
      };
    } catch (_) {
      // Fallback lokal cerdas jika offline atau parsing gagal
      final List<Map<String, dynamic>> fallbackAnswers = [];
      for (final q in questions) {
        final opts = q['options'] as List<dynamic>? ?? [];
        int bestIdx = 0;
        for (int i = 0; i < opts.length; i++) {
          final optText = (opts[i]['optionText'] ?? '').toString().toLowerCase();
          if (optText.contains('ya') ||
              optText.contains('sangat baik') ||
              optText.contains('sangat setuju') ||
              optText == '4' ||
              optText == '5') {
            bestIdx = i;
            break;
          }
        }
        fallbackAnswers.add({
          'index': q['index'],
          'recommendedOptionIndex': bestIdx,
          'reason': 'Rekomendasi evaluasi positif perkuliahan.',
        });
      }

      return {
        'answers': fallbackAnswers,
        'feedbackSuggestion':
            'Penyampaian materi dan modul ajar di LMS sangat lengkap dan terstruktur. Terima kasih kepada Bapak/Ibu dosen atas dedikasi dan bimbingannya.',
      };
    }
  }

  /// Melakukan parafrase cerdas terhadap draf tugas/teks mahasiswa
  Future<ParaphraseResult> paraphraseAcademicText({
    required String text,
    required ParaphraseMode mode,
    bool includeCitationAdvice = false,
    String? courseName,
  }) async {
    String modeInstruction;
    switch (mode) {
      case ParaphraseMode.academic:
        modeInstruction =
            'Gaya Akademis & Baku: Gunakan kosakata baku Bahasa Indonesia (PUEBI/KBBI), struktur kalimat formal ragam ilmiah, transisi logis antarparagraf, dan terminologi yang tepat untuk karya ilmiah/makalah.';
        break;
      case ParaphraseMode.humanizer:
        modeInstruction =
            'Gaya Lugas & Alami (Humanizer Orisinal): Rombak total struktur kalimat agar mengalir santun, luwes, dan bernalar seperti pemikiran asli mahasiswa Indonesia. Variasikan panjang kalimat. HINDARI struktur kaku atau frasa pengantar khas bot AI agar tidak terdeteksi plagiat / AI detector.';
        break;
      case ParaphraseMode.concise:
        modeInstruction =
            'Gaya Ringkas & Padat: Pangkas kalimat bertele-tele dan redudansi kata. Sampaikan gagasan utama dalam kalimat yang padat, tajam, dan langsung ke inti permasalahan tanpa menghilangkan substansi.';
        break;
      case ParaphraseMode.expansive:
        modeInstruction =
            'Gaya Ekspansif & Analitis: Elaborasi ide dasar menjadi pemaparan naratif yang mendalam, lengkapi dengan penalaran sebab-akibat atau contoh aplikasi nyata di lapangan/industri yang relevan.';
        break;
    }

    final systemPrompt =
        'Anda adalah pakar penulisan akademik dan editor bahasa profesional untuk civitas akademika Universitas Pamulang.\n'
        'Tugas Anda: Melakukan parafrase berkualitas tinggi terhadap teks mahasiswa berdasarkan mode yang diminta.\n\n'
        'Aturan Khusus:\n'
        '1. $modeInstruction\n'
        '2. Jangan tambahkan kata pembuka/penutup seperti "Berikut adalah hasil parafrasenya:" atau "Semoga membantu".\n'
        '3. ${includeCitationAdvice ? 'Di akhir teks, tambahkan baris pemisah "---SITASI---" lalu sertakan 1-2 contoh format sitasi referensi yang relevan dalam format APA 7th Edition.' : 'Jangan sertakan format sitasi kecuali diminta.'}\n'
        '4. JANGAN gunakan emoji apa pun.';

    final userPrompt =
        'Konteks Mata Kuliah: ${courseName ?? "Umum / Universitas Pamulang"}\n\n'
        'Teks Asli Mahasiswa:\n"""\n$text\n"""\n\n'
        'Hasil Parafrase:';

    final raw = await askRawLlm(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    String paraphrased = raw.trim();
    String? citationAdvice;

    if (includeCitationAdvice && paraphrased.contains('---SITASI---')) {
      final parts = paraphrased.split('---SITASI---');
      paraphrased = parts[0].trim();
      if (parts.length > 1) {
        citationAdvice = parts[1].trim();
      }
    }

    final origWords = ParaphraseResult.countWords(text);
    final resWords = ParaphraseResult.countWords(paraphrased);

    return ParaphraseResult(
      originalText: text,
      paraphrasedText: paraphrased,
      mode: mode,
      originalWordCount: origWords,
      resultWordCount: resWords,
      citationAdvice: citationAdvice,
    );
  }
}
