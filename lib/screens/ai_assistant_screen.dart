import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/ai_provider.dart';
import '../models/ai_message_model.dart';
import '../theme/app_theme.dart';
import 'ai_paraphrase_screen.dart';
import '../models/ai_model_config.dart';

class AiAssistantScreen extends StatefulWidget {
  final String? initialPrompt;

  const AiAssistantScreen({super.key, this.initialPrompt});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiThinkingIndicator extends StatefulWidget {
  const _AiThinkingIndicator();

  @override
  State<_AiThinkingIndicator> createState() => _AiThinkingIndicatorState();
}

class _AiThinkingIndicatorState extends State<_AiThinkingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotScale(double t, double shift) {
    final wave = math.sin((t * math.pi * 2) + shift);
    return 0.75 + ((wave + 1) * 0.17);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_alt_rounded, color: AppTheme.primaryBlue, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'The PAMs AI sedang merangkai jawaban terbaik...',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final t = _controller.value;
                  return Row(
                    children: [
                      _buildDot(_dotScale(t, 0)),
                      const SizedBox(width: 4),
                      _buildDot(_dotScale(t, math.pi / 1.9)),
                      const SizedBox(width: 4),
                      _buildDot(_dotScale(t, math.pi / 0.95)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(double scale) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _selectedImageMime;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialPrompt);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickScreenshot() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageMime = picked.mimeType ?? 'image/jpeg';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih screenshot: $e')),
      );
    }
  }

  void _handleSend([String? presetText]) {
    final text = presetText ?? _textController.text.trim();
    final hasImg = _selectedImageBytes != null && _selectedImageBytes!.isNotEmpty;
    if (text.isEmpty && !hasImg) return;

    final selectedCourse = context.read<AiProvider>().selectedCourseName;
    final courses = (selectedCourse != null && selectedCourse.isNotEmpty)
        ? [selectedCourse]
        : null;

    final imgBytes = _selectedImageBytes;
    final imgMime = _selectedImageMime;

    setState(() {
      _selectedImageBytes = null;
      _selectedImageMime = null;
    });

    context.read<AiProvider>().sendMessage(
      text,
      availableCourses: courses,
      imageBytes: imgBytes,
      mimeType: imgMime,
    );
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiProvider>();
    final activeFocus = aiProv.selectedCourseName;
    const commonCourses = [
      'Pemrograman Mobile',
      'Basis Data',
      'Kecerdasan Buatan',
      'Rekayasa Perangkat Lunak',
      'Jaringan Komputer',
      'Struktur Data & Algoritma',
      'Pemrograman Web',
      'Sistem Operasi',
      'Etika Profesi & Keorganisasian',
    ];
    final allCourses = <String>{
      if (activeFocus != null && activeFocus.isNotEmpty) activeFocus,
      ...commonCourses,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 22),
            SizedBox(width: 8),
            Text('The PAMs AI'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mode Split-Screen (Konsultasi Sambil Lihat Portal)',
            icon: const Icon(
              Icons.vertical_split_rounded,
              color: AppTheme.accentGold,
              size: 21,
            ),
            onPressed: () {
              Navigator.pop(context, 'open_split_screen');
            },
          ),
          IconButton(
            tooltip: 'Ganti Model AI & Kunci API',
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _showModelSelectorDialog(context),
          ),
          IconButton(
            tooltip: 'AI Parafrase Akademik',
            icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiParaphraseScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Bersihkan Riwayat Chat',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              aiProv.clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Riwayat percakapan dibersihkan.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Engine Status Indicator Banner (Interactive Model Selector)
          Material(
            color: aiProv.hasKeyForActiveModel
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFF1F5F9),
            child: InkWell(
              onTap: () => _showModelSelectorDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      aiProv.activeModel.supportsVision
                          ? Icons.remove_red_eye_rounded
                          : Icons.psychology_rounded,
                      size: 16,
                      color: aiProv.hasKeyForActiveModel
                          ? const Color(0xFFD97706)
                          : AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Model: ${aiProv.activeModel.name}${aiProv.activeModel.supportsVision ? " (Vision OCR)" : ""}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: aiProv.hasKeyForActiveModel
                              ? const Color(0xFF92400E)
                              : AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ganti',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_right_rounded, size: 16, color: AppTheme.primaryBlue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),

          // Course Context Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.school_outlined, size: 18, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                const Text(
                  'Fokus MK:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: allCourses.contains(aiProv.selectedCourseName)
                          ? aiProv.selectedCourseName
                          : null,
                      isExpanded: true,
                      hint: const Text('Semua Mata Kuliah (Umum)', style: TextStyle(fontSize: 12)),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Mata Kuliah (Umum)', style: TextStyle(fontSize: 12)),
                        ),
                        ...allCourses.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        aiProv.setSelectedCourse(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),

          // Quick Action Prompt Chips
          Container(
            height: 48,
            color: AppTheme.bgGrey,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildQuickChip('📷 Tanya dari Screenshot', _pickScreenshot),
                _buildQuickChip('📝 Buat Kuis Latihan', () {
                  final mk = aiProv.selectedCourseName ?? 'Mata Kuliah';
                  _handleSend('Buatkan kuis latihan 3 soal pilihan ganda untuk $mk');
                }),
                _buildQuickChip('📚 Rangkum Materi Kuliah', () {
                  final mk = aiProv.selectedCourseName ?? 'Mata Kuliah';
                  _handleSend('Rangkum materi utama untuk mata kuliah $mk');
                }),
                _buildQuickChip('💬 Opini Forum Diskusi', () {
                  final mk = aiProv.selectedCourseName ?? 'Mata Kuliah';
                  _handleSend('Bantu susun pandangan atau opini akademis untuk diskusi $mk');
                }),
                _buildQuickChip('💡 Tips Belajar Kuis & Ujian', () {
                  _handleSend('Berikan tips strategi belajar efektif menghadapi Pretest dan Post-test perkuliahan');
                }),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: aiProv.messages.length,
              itemBuilder: (ctx, index) {
                final msg = aiProv.messages[index];
                return _buildMessageItem(ctx, msg, aiProv);
              },
            ),
          ),

          // Loading Indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: aiProv.isLoading
                ? const Padding(
                    key: ValueKey('ai_loading_indicator'),
                    padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: _AiThinkingIndicator(),
                  )
                : const SizedBox.shrink(key: ValueKey('ai_loading_empty')),
          ),

          // Preview Thumbnail jika screenshot dipilih
          if (_selectedImageBytes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Screenshot Soal Terlampir',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Text(
                          'Tekan kirim agar AI membaca teks dan menjawab soal pada gambar',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: AppTheme.dangerRed, size: 20),
                    tooltip: 'Hapus Screenshot',
                    onPressed: () => setState(() {
                      _selectedImageBytes = null;
                      _selectedImageMime = null;
                    }),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Tombol lampirkan foto/screenshot
                  IconButton(
                    tooltip: 'Lampirkan Screenshot Soal',
                    icon: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryLight, size: 24),
                    onPressed: aiProv.isLoading ? null : _pickScreenshot,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: _selectedImageBytes != null
                            ? 'Beri pertanyaan tambahan (opsional)...'
                            : 'Tanyakan materi kuliah, kuis, atau tugas...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.cardBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: aiProv.isLoading ? null : () => _handleSend(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppTheme.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, AiMessage msg, AiProvider aiProv) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    msg.imageBytes!,
                    width: 200,
                    height: 130,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                msg.content,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Assistant Message Bubble
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Assistant
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, size: 14, color: AppTheme.accentGold),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'The PAMs AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textMuted),
                    tooltip: 'Salin Jawaban',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: msg.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Teks berhasil disalin ke clipboard!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Content Body
              Text(
                msg.content,
                style: const TextStyle(fontSize: 13.5, color: AppTheme.textDark, height: 1.45),
              ),

              // Interactive Quiz Cards (jika respons berisi latihan kuis)
              if (msg.quizItems != null && msg.quizItems!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...msg.quizItems!.asMap().entries.map((entry) {
                  final qIdx = entry.key;
                  final q = entry.value;
                  return _buildQuizCard(msg.id, qIdx, q, aiProv);
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(
    String messageId,
    int qIdx,
    QuizItem quiz,
    AiProvider aiProv,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Soal ${qIdx + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            quiz.question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),

          // Options
          ...quiz.options.asMap().entries.map((optEntry) {
            final optIdx = optEntry.key;
            final optText = optEntry.value;
            final isSelected = quiz.userSelectedIndex == optIdx;
            final isAnswered = quiz.isAnswered;
            final isCorrect = optIdx == quiz.correctIndex;

            Color bgColor = Colors.white;
            Color borderColor = AppTheme.cardBorder;
            Color textColor = AppTheme.textDark;

            if (isAnswered) {
              if (isCorrect) {
                bgColor = AppTheme.successGreen.withOpacity(0.12);
                borderColor = AppTheme.successGreen;
                textColor = AppTheme.successGreen;
              } else if (isSelected && !isCorrect) {
                bgColor = AppTheme.dangerRed.withOpacity(0.1);
                borderColor = AppTheme.dangerRed;
                textColor = AppTheme.dangerRed;
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: isAnswered
                    ? null
                    : () {
                        aiProv.answerQuizOption(
                          messageId: messageId,
                          questionIndex: qIdx,
                          selectedIndex: optIdx,
                        );
                      },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAnswered
                            ? (isCorrect
                                ? Icons.check_circle_rounded
                                : (isSelected ? Icons.cancel_rounded : Icons.radio_button_unchecked))
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: textColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          optText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Penjelasan setelah dijawab
          if (quiz.isAnswered) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '💡 Pembahasan: ${quiz.explanation}',
                style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showModelSelectorDialog(BuildContext context) {
    final aiProv = context.read<AiProvider>();
    AiModelOption? editingOption;
    final keyController = TextEditingController();
    bool obscure = true;
    bool isSaving = false;
    String? statusMessage;
    bool? isSuccess;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final activeOption = editingOption ?? aiProv.activeModel;
            final isEditing = editingOption != null;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.psychology_alt_rounded, color: AppTheme.primaryBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Kunci API ${activeOption.shortName}' : 'Pilih Model & Mesin AI',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              Text(
                                isEditing
                                    ? 'Kelola atau perbarui API Key untuk model ini'
                                    : 'Gunakan Gemini 3.7, DeepSeek V4, Claude 5.5, Qwen 3.8, GPT-5.5, atau Cloud AI',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (isEditing)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {
                              setModalState(() {
                                editingOption = null;
                                statusMessage = null;
                              });
                            },
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: isEditing
                          ? _buildKeyConfigForm(
                              ctx: ctx,
                              option: activeOption,
                              controller: keyController,
                              obscure: obscure,
                              isSaving: isSaving,
                              statusMessage: statusMessage,
                              isSuccess: isSuccess,
                              aiProv: aiProv,
                              onToggleObscure: () => setModalState(() => obscure = !obscure),
                              onSave: () async {
                                final text = keyController.text.trim();
                                setModalState(() {
                                  isSaving = true;
                                  statusMessage = 'Memverifikasi API Key ke server ${activeOption.shortName}...';
                                  isSuccess = null;
                                });

                                final ok = await aiProv.validateAndSaveProviderApiKey(
                                  activeOption.provider,
                                  text,
                                );

                                if (!ctx.mounted) return;
                                setModalState(() {
                                  isSaving = false;
                                  if (ok) {
                                    statusMessage = '✅ Kunci valid! Model ${activeOption.shortName} siap digunakan.';
                                    isSuccess = true;
                                  } else {
                                    statusMessage = '❌ Kunci tidak valid atau server tidak merespons.';
                                    isSuccess = false;
                                  }
                                });

                                if (ok) {
                                  await aiProv.setActiveModel(activeOption.id);
                                  await Future.delayed(const Duration(milliseconds: 600));
                                  if (ctx.mounted) {
                                    setModalState(() => editingOption = null);
                                  }
                                }
                              },
                              onDelete: () async {
                                setModalState(() => isSaving = true);
                                await aiProv.removeProviderApiKey(activeOption.provider);
                                keyController.clear();
                                if (!ctx.mounted) return;
                                setModalState(() {
                                  isSaving = false;
                                  editingOption = null;
                                });
                              },
                            )
                          : Column(
                              children: aiProv.availableModels.map((opt) {
                                final isSelected = opt.id == aiProv.activeModel.id;
                                final hasKey = aiProv.hasKeyForModel(opt);

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppTheme.primaryBlue
                                          : AppTheme.cardBorder,
                                      width: isSelected ? 1.8 : 1,
                                    ),
                                  ),
                                  color: isSelected
                                      ? AppTheme.primaryBlue.withOpacity(0.04)
                                      : Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isSelected
                                          ? AppTheme.primaryBlue
                                          : Colors.grey.shade100,
                                      child: Icon(
                                        _getIconForProvider(opt.provider),
                                        size: 18,
                                        color: isSelected ? Colors.white : AppTheme.primaryBlue,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            opt.name,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              fontSize: 13,
                                              color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                                            ),
                                          ),
                                        ),
                                        if (opt.supportsVision)
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.purple.shade200),
                                            ),
                                            child: const Text(
                                              'OCR',
                                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.purple),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        opt.description,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (opt.provider != AiProviderType.freeCloud)
                                          IconButton(
                                            icon: Icon(
                                              Icons.key_rounded,
                                              size: 18,
                                              color: hasKey ? AppTheme.accentGold : Colors.grey.shade400,
                                            ),
                                            tooltip: hasKey ? 'Edit API Key' : 'Pasang API Key',
                                            onPressed: () {
                                              keyController.text = aiProv.getApiKeyForProvider(opt.provider);
                                              setModalState(() {
                                                editingOption = opt;
                                                statusMessage = null;
                                                isSuccess = null;
                                              });
                                            },
                                          ),
                                        Radio<String>(
                                          value: opt.id,
                                          groupValue: aiProv.activeModel.id,
                                          activeColor: AppTheme.primaryBlue,
                                          onChanged: (val) async {
                                            if (val != null) {
                                              if (opt.provider != AiProviderType.freeCloud && !hasKey) {
                                                keyController.text = aiProv.getApiKeyForProvider(opt.provider);
                                                setModalState(() {
                                                  editingOption = opt;
                                                  statusMessage = null;
                                                  isSuccess = null;
                                                });
                                                return;
                                              }
                                              await aiProv.setActiveModel(val);
                                              if (ctx.mounted) Navigator.pop(ctx);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      if (opt.provider != AiProviderType.freeCloud && !hasKey) {
                                        keyController.text = aiProv.getApiKeyForProvider(opt.provider);
                                        setModalState(() {
                                          editingOption = opt;
                                          statusMessage = null;
                                          isSuccess = null;
                                        });
                                        return;
                                      }
                                      await aiProv.setActiveModel(opt.id);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForProvider(AiProviderType provider) {
    switch (provider) {
      case AiProviderType.gemini:
        return Icons.auto_awesome;
      case AiProviderType.deepseek:
        return Icons.psychology_rounded;
      case AiProviderType.claude:
        return Icons.forum_rounded;
      case AiProviderType.qwen:
        return Icons.language_rounded;
      case AiProviderType.openai:
        return Icons.bolt_rounded;
      case AiProviderType.openrouter:
        return Icons.hub_rounded;
      case AiProviderType.freeCloud:
        return Icons.cloud_done_rounded;
    }
  }

  Widget _buildKeyConfigForm({
    required BuildContext ctx,
    required AiModelOption option,
    required TextEditingController controller,
    required bool obscure,
    required bool isSaving,
    required String? statusMessage,
    required bool? isSuccess,
    required AiProvider aiProv,
    required VoidCallback onToggleObscure,
    required VoidCallback onSave,
    required VoidCallback onDelete,
  }) {
    final hasKey = aiProv.hasKeyForModel(option);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasKey ? AppTheme.successGreen.withOpacity(0.08) : AppTheme.primaryBlue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasKey ? AppTheme.successGreen.withOpacity(0.3) : AppTheme.primaryBlue.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasKey ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                size: 20,
                color: hasKey ? AppTheme.successGreen : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasKey
                      ? 'Kunci API ${option.shortName} tersimpan dan siap digunakan.'
                      : 'Masukkan API Key resmi ${option.shortName} untuk mengaktifkan model ini.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          option.description,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
        ),
        if (option.apiKeyDocsUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final uri = Uri.parse(option.apiKeyDocsUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.primaryBlue),
                const SizedBox(width: 4),
                Text(
                  'Dapatkan API Key di ${option.shortName} Console',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Kunci API ${option.shortName}',
            hintText: 'Tempel / paste API Key di sini...',
            isDense: true,
            prefixIcon: const Icon(Icons.key_outlined, size: 18),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: onToggleObscure,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (statusMessage != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (isSaving)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  size: 16,
                  color: isSuccess == true ? AppTheme.successGreen : AppTheme.dangerRed,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isSuccess == true ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (hasKey)
              TextButton(
                onPressed: isSaving ? null : onDelete,
                child: const Text('Hapus Key', style: TextStyle(color: AppTheme.dangerRed)),
              ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(isSaving ? 'Memverifikasi...' : 'Simpan & Aktifkan'),
            ),
          ],
        ),
      ],
    );
  }

}
