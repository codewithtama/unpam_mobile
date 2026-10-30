import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Modal bottom sheet untuk menganalisis dan mengisi butir kuesioner evaluasi dosen.
class QuestionnaireSolverDialog extends StatefulWidget {
  final String pageTitle;
  final List<Map<String, dynamic>> questions;
  final bool hasFeedbackField;
  final Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> questions,
    String courseName,
  ) onAnalyzeAi;
  final Future<int> Function({
    required List<Map<String, dynamic>> answers,
    required String feedback,
    required bool autoCheck,
  }) onApplyQuestionnaire;

  const QuestionnaireSolverDialog({
    super.key,
    required this.pageTitle,
    required this.questions,
    required this.hasFeedbackField,
    required this.onAnalyzeAi,
    required this.onApplyQuestionnaire,
  });

  static Future<void> show({
    required BuildContext context,
    required String pageTitle,
    required List<Map<String, dynamic>> questions,
    required bool hasFeedbackField,
    required Future<Map<String, dynamic>> Function(
      List<Map<String, dynamic>> questions,
      String courseName,
    ) onAnalyzeAi,
    required Future<int> Function({
      required List<Map<String, dynamic>> answers,
      required String feedback,
      required bool autoCheck,
    }) onApplyQuestionnaire,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => QuestionnaireSolverDialog(
        pageTitle: pageTitle,
        questions: questions,
        hasFeedbackField: hasFeedbackField,
        onAnalyzeAi: onAnalyzeAi,
        onApplyQuestionnaire: onApplyQuestionnaire,
      ),
    );
  }

  @override
  State<QuestionnaireSolverDialog> createState() => _QuestionnaireSolverDialogState();
}

class _QuestionnaireSolverDialogState extends State<QuestionnaireSolverDialog> {
  final Map<int, int> _selectedOptions = {};
  late final TextEditingController _feedbackController;
  bool _autoCheckInWeb = true;
  bool _isAnalyzingAi = false;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController(
      text:
          'Penyampaian materi perkuliahan sangat jelas dan modul di LMS lengkap serta mudah dipahami. Terima kasih kepada Bapak/Ibu dosen atas bimbingannya.',
    );

    // Inisialisasi opsi default yang ramah
    for (int i = 0; i < widget.questions.length; i++) {
      final opts = widget.questions[i]['options'] as List<dynamic>? ?? [];
      int bestIdx = 0;
      for (int j = 0; j < opts.length; j++) {
        final text = (opts[j]['optionText'] ?? '').toString().toLowerCase();
        if (text == 'ya' ||
            text.startsWith('ya') ||
            text.contains('sangat baik') ||
            text.contains('sangat setuju') ||
            text == '4' ||
            text == '5') {
          bestIdx = j;
          break;
        }
      }
      _selectedOptions[i] = bestIdx;
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      expand: false,
      builder: (scrollCtx, scrollController) {
        return Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Colors.teal.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Pengisi Kuesioner (${widget.questions.length} Butir)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Halaman: ${widget.pageTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Quick Mode Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          for (int i = 0; i < widget.questions.length; i++) {
                            final opts = widget.questions[i]['options'] as List<dynamic>? ?? [];
                            int yaIdx = 0;
                            for (int j = 0; j < opts.length; j++) {
                              final text = (opts[j]['optionText'] ?? '').toString().toLowerCase();
                              if (text == 'ya' || text.startsWith('ya') || text.contains('sangat')) {
                                yaIdx = j;
                                break;
                              }
                            }
                            _selectedOptions[i] = yaIdx;
                          }
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade800,
                        side: BorderSide(color: Colors.teal.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text(
                        'Semua "Ya" / Baik',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzingAi
                          ? null
                          : () async {
                              setState(() => _isAnalyzingAi = true);
                              try {
                                final result = await widget.onAnalyzeAi(
                                  widget.questions,
                                  widget.pageTitle,
                                );
                                final answers = result['answers'] as List<dynamic>? ?? [];
                                for (final ans in answers) {
                                  final idx = (ans['index'] as num?)?.toInt();
                                  final optIdx = (ans['recommendedOptionIndex'] as num?)?.toInt();
                                  if (idx != null && optIdx != null && idx >= 0 && idx < widget.questions.length) {
                                    _selectedOptions[idx] = optIdx;
                                  }
                                }
                                final feedback = (result['feedbackSuggestion'] ?? '').toString();
                                if (feedback.isNotEmpty) {
                                  _feedbackController.text = feedback;
                                }
                              } catch (e) {
                                debugPrint('Gagal analisis AI kuesioner: $e');
                              } finally {
                                if (mounted) {
                                  setState(() => _isAnalyzingAi = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: _isAnalyzingAi
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(
                        _isAnalyzingAi ? 'Menelaah...' : 'Analisis AI',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Toggle Switch Centang Otomatis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Centang otomatis pilihan di lembar kuesioner web',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: _autoCheckInWeb,
                    activeColor: Colors.teal.shade700,
                    onChanged: (val) {
                      setState(() => _autoCheckInWeb = val);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Daftar Butir Soal Kuesioner
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: widget.questions.length + (widget.hasFeedbackField ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  if (idx == widget.questions.length) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.rate_review_rounded, size: 18, color: AppTheme.accentGold),
                              SizedBox(width: 8),
                              Text(
                                'Catatan & Saran untuk Dosen',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _feedbackController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Tuliskan masukan atau apresiasi untuk dosen...',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final q = widget.questions[idx];
                  final qNum = (q['number'] ?? '${idx + 1}').toString();
                  final qText = (q['questionText'] ?? '').toString();
                  final opts = q['options'] as List<dynamic>? ?? [];
                  final currentSelected = _selectedOptions[idx] ?? 0;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$qNum. $qText',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: List.generate(opts.length, (optIdx) {
                            final opt = opts[optIdx];
                            final optText = (opt['optionText'] ?? 'Opsi ${optIdx + 1}').toString();
                            final isChosen = currentSelected == optIdx;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedOptions[idx] = optIdx;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isChosen ? Colors.teal.shade50 : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isChosen ? Colors.teal.shade600 : Colors.grey.shade300,
                                    width: isChosen ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isChosen
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 16,
                                      color: isChosen ? Colors.teal.shade700 : Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      optText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                                        color: isChosen ? Colors.teal.shade900 : AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isApplying
                          ? null
                          : () async {
                              setState(() => _isApplying = true);

                              final List<Map<String, dynamic>> answersPayload = [];
                              _selectedOptions.forEach((qIdx, optIdx) {
                                answersPayload.add({
                                  'index': qIdx,
                                  'optionIndex': optIdx,
                                });
                              });

                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final count = await widget.onApplyQuestionnaire(
                                answers: answersPayload,
                                feedback: widget.hasFeedbackField
                                    ? _feedbackController.text.trim()
                                    : '',
                                autoCheck: _autoCheckInWeb,
                              );
                              navigator.pop();

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Berhasil mengisi $count butir kuesioner! Periksa kembali halaman sebelum menekan tombol Simpan di Mentari.',
                                  ),
                                  backgroundColor: Colors.teal.shade800,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: _isApplying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text(
                        'Isi Kuesioner Sekarang',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
