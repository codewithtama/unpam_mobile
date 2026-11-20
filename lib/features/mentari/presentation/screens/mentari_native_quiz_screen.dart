import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/cloudflare_clearance_modal.dart';
import '../../../../theme/app_theme.dart';
import '../../../ai_assistant/presentation/providers/ai_provider.dart';
import '../../domain/models/mentari_interactive_models.dart';
import '../../domain/models/mentari_module_model.dart';
import '../providers/mentari_provider.dart';

class MentariNativeQuizScreen extends StatefulWidget {
  final MentariModuleModel module;
  final String courseTitle;
  final String sectionTitle;

  const MentariNativeQuizScreen({
    super.key,
    required this.module,
    required this.courseTitle,
    required this.sectionTitle,
  });

  @override
  State<MentariNativeQuizScreen> createState() => _MentariNativeQuizScreenState();
}

class _MentariNativeQuizScreenState extends State<MentariNativeQuizScreen> {
  List<MentariQuizQuestionModel> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSolvingWithAi = false;
  bool _isSubmitting = false;
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.module.quizDurationMinutes * 60;
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<MentariProvider>();
      final loaded = await provider.service.fetchQuizQuestions(
        widget.module,
        courseTitle: widget.courseTitle,
        sectionTitle: widget.sectionTitle,
      );
      if (!mounted) return;
      setState(() {
        _questions = loaded;
        _isLoading = false;
      });
      _startTimer();
    } on CloudflareChallengeException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final cleared = await CloudflareClearanceModal.show(
        context,
        targetUrl: e.targetUrl,
        portalTitle: 'Mentari LMS',
      );
      if (cleared == true && mounted) {
        await _loadQuestions();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectOption(int questionIndex, String optionId) {
    if (questionIndex < 0 || questionIndex >= _questions.length) return;
    setState(() {
      _questions[questionIndex] = _questions[questionIndex].copyWith(
        selectedOptionId: optionId,
      );
    });
  }

  Future<void> _solveWithAi() async {
    if (_questions.isEmpty || _isSolvingWithAi) return;
    setState(() => _isSolvingWithAi = true);

    try {
      final aiProv = context.read<AiProvider>();
      final payload = _questions.map((q) {
        return {
          'index': q.number,
          'question': q.questionText,
          'options': q.options.map((o) => '${o.label}. ${o.text}').toList(),
        };
      }).toList();

      final results = await aiProv.solveQuizQuestions(
        questions: payload,
        courseName: widget.courseTitle,
      );

      if (!mounted) return;

      setState(() {
        for (var i = 0; i < _questions.length; i++) {
          final q = _questions[i];
          Map<String, dynamic>? match;
          for (final r in results) {
            final idx = (r['index'] as num?)?.toInt();
            if (idx == q.number || idx == i + 1 || idx == i) {
              match = r;
              break;
            }
          }
          if (match == null && i < results.length) {
            match = results[i];
          }
          if (match != null) {
            final bestIndex = (match['bestOptionIndex'] as num?)?.toInt() ?? 0;
            final clamped = bestIndex.clamp(0, q.options.length - 1);
            final recommendedId = q.options.isNotEmpty ? q.options[clamped].id : 'A';
            final reason = (match['reason'] ?? match['explanation'] ?? 'Direkomendasikan berdasarkan analisis materi perkuliahan.').toString();

            _questions[i] = q.copyWith(
              aiRecommendedOptionId: recommendedId,
              selectedOptionId: q.selectedOptionId ?? recommendedId,
              aiExplanation: reason,
            );
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The PAMs AI telah menganalisis soal dan menandai rekomendasi jawaban.'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menganalisis dengan AI: $e'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSolvingWithAi = false);
    }
  }

  Future<void> _submitQuiz() async {
    final answeredCount = _questions.where((q) => q.selectedOptionId != null).length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kirim Jawaban Kuis?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Anda telah menjawab $answeredCount dari ${_questions.length} soal pada ${widget.module.name}.\n\nKirim dan simpan hasil pengerjaan sekarang?',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Periksa Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim Jawaban'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final answers = <String, String>{};
      for (final q in _questions) {
        if (q.selectedOptionId != null) {
          answers[q.id] = q.selectedOptionId!;
        }
      }

      final provider = context.read<MentariProvider>();
      await provider.service.submitQuizAnswers(widget.module, answers);
      provider.markModuleCompleted(widget.module.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.module.name} berhasil dikirim dan diselesaikan!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions.isNotEmpty ? _questions[_currentIndex] : null;
    final answeredCount = _questions.where((q) => q.selectedOptionId != null).length;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module.name,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.sectionTitle} • ${widget.courseTitle}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 15, color: AppTheme.accentGold),
                const SizedBox(width: 4),
                Text(
                  _formatTimer(_remainingSeconds),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Verifikasi Cloudflare',
            icon: const Icon(Icons.verified_user_outlined, size: 20),
            onPressed: () {
              CloudflareClearanceModal.show(
                context,
                targetUrl: ApiConstants.mentariBaseUrl,
                portalTitle: 'Mentari LMS',
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 12),
                  Text('Memuat lembar soal kuis native...', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : Column(
              children: [
                // Baris Navigasi Nomor Soal & Tombol AI Solver
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Terjawab: $answeredCount / ${_questions.length} Soal',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isSolvingWithAi ? null : _solveWithAi,
                            icon: _isSolvingWithAi
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome_rounded, size: 16),
                            label: Text(
                              _isSolvingWithAi ? 'Menganalisis...' : 'AI Quiz Solver',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _questions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, idx) {
                            final q = _questions[idx];
                            final isCurrent = idx == _currentIndex;
                            final isAnswered = q.selectedOptionId != null;
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() => _currentIndex = idx),
                              child: Container(
                                width: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.primaryBlue
                                      : (isAnswered
                                          ? AppTheme.successGreen.withOpacity(0.15)
                                          : AppTheme.bgGrey),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isCurrent
                                        ? AppTheme.primaryBlue
                                        : (isAnswered ? AppTheme.successGreen : AppTheme.cardBorder),
                                  ),
                                ),
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? Colors.white
                                        : (isAnswered ? AppTheme.successGreen : AppTheme.textDark),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),

                // Isi Soal & Pilihan Jawaban
                if (currentQuestion != null)
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Pertanyaan ${currentQuestion.number}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentQuestion.questionText,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Daftar Pilihan Ganda
                        ...currentQuestion.options.map((opt) {
                          final isSelected = currentQuestion.selectedOptionId == opt.id;
                          final isAiRecommended = currentQuestion.aiRecommendedOptionId == opt.id;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryBlue.withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : (isAiRecommended ? AppTheme.accentGold : AppTheme.cardBorder),
                                width: isSelected || isAiRecommended ? 1.6 : 1.0,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _selectOption(_currentIndex, opt.id),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryBlue
                                            : AppTheme.bgGrey,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        opt.label,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            opt.text,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              height: 1.35,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          if (isAiRecommended) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentGold.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.auto_awesome, size: 12, color: AppTheme.accentGold),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Rekomendasi The PAMs AI',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.accentGold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        if (currentQuestion.aiExplanation != null &&
                            currentQuestion.aiExplanation!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.accentGold.withOpacity(0.35)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.psychology_rounded, color: AppTheme.accentGold, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Pembahasan The PAMs AI',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentQuestion.aiExplanation!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.textDark,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Bottom Bar Navigasi Soal & Submit
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.cardBorder)),
                  ),
                  child: Row(
                    children: [
                      if (_currentIndex > 0)
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _currentIndex--),
                          icon: const Icon(Icons.chevron_left_rounded, size: 18),
                          label: const Text('Sebelumnya'),
                        ),
                      const Spacer(),
                      if (_currentIndex < _questions.length - 1)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => setState(() => _currentIndex++),
                          icon: const Icon(Icons.chevron_right_rounded, size: 18),
                          label: const Text('Selanjutnya'),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isSubmitting ? null : _submitQuiz,
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Jawaban'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
