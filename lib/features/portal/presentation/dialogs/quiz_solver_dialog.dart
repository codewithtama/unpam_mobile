import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Modal bottom sheet untuk menampilkan analisis soal kuis pilihan ganda bersama opsi jawaban rujukan AI.
class QuizSolverDialog extends StatefulWidget {
  final String pageTitle;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> solutions;
  final Future<int> Function({
    required List<Map<String, dynamic>> solutions,
    required bool autoSelect,
  }) onApplyHighlight;

  const QuizSolverDialog({
    super.key,
    required this.pageTitle,
    required this.questions,
    required this.solutions,
    required this.onApplyHighlight,
  });

  static Future<void> show({
    required BuildContext context,
    required String pageTitle,
    required List<Map<String, dynamic>> questions,
    required List<Map<String, dynamic>> solutions,
    required Future<int> Function({
      required List<Map<String, dynamic>> solutions,
      required bool autoSelect,
    }) onApplyHighlight,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => QuizSolverDialog(
        pageTitle: pageTitle,
        questions: questions,
        solutions: solutions,
        onApplyHighlight: onApplyHighlight,
      ),
    );
  }

  @override
  State<QuizSolverDialog> createState() => _QuizSolverDialogState();
}

class _QuizSolverDialogState extends State<QuizSolverDialog> {
  bool _autoSelectRadio = true;
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.fact_check_rounded, color: AppTheme.primaryBlue, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Quiz (${widget.questions.length} Soal)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Mata Kuliah: ${widget.pageTitle}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Bantu tandai opsi rujukan pada lembar kuis',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: _autoSelectRadio,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) {
                      setState(() => _autoSelectRadio = val);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: widget.questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final q = widget.questions[idx];
                  final qText = (q['questionText'] ?? '').toString();
                  final opts = q['options'] as List<dynamic>? ?? [];

                  final sol = widget.solutions.firstWhere(
                    (s) => s['index'] == idx || s['index'] == q['originalIndex'],
                    orElse: () => {
                      'correctOptionIndex': 0,
                      'correctOptionText': '',
                      'reason': 'Analisis rekomendasi AI.',
                    },
                  );

                  final correctOptIdx = (sol['correctOptionIndex'] as num?)?.toInt() ?? 0;
                  final reason = (sol['reason'] ?? '').toString();

                  String chosenText = '';
                  if (correctOptIdx >= 0 && correctOptIdx < opts.length) {
                    chosenText = (opts[correctOptIdx]['optionText'] ?? '').toString();
                  } else {
                    chosenText = (sol['correctOptionText'] ?? '').toString();
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soal ${idx + 1}: $qText',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rekomendasi Opsi: $chosenText',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                    if (reason.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ulasan Konsep: $reason',
                                        style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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
                      child: const Text('Tutup'),
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
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final count = await widget.onApplyHighlight(
                                solutions: widget.solutions,
                                autoSelect: _autoSelectRadio,
                              );
                              navigator.pop();

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Berhasil menandai $count opsi rujukan pada lembar kuis.',
                                  ),
                                  backgroundColor: Colors.green.shade800,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: _isApplying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.highlight_rounded, size: 18),
                      label: const Text(
                        'Tandai di Lembar Kuis',
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
