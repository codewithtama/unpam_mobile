import 'package:flutter/material.dart';
import '../models/course_detail_model.dart';
import '../theme/app_theme.dart';
import '../screens/mentari_activity_screen.dart';

class QuizDialog extends StatelessWidget {
  final SubSection item;
  final String? courseKode;
  final String? courseName;
  final String? sectionTitle;

  const QuizDialog({
    super.key,
    required this.item,
    this.courseKode,
    this.courseName,
    this.sectionTitle,
  });

  @override
  Widget build(BuildContext context) {
    final quiz = item.settingQuiz;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.quiz_rounded, color: AppTheme.accentGold, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  item.typeLabel,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SinglefulDetailContent(item: item, quiz: quiz),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MentariActivityScreen(
                  item: item,
                  courseKode: courseKode,
                  courseName: courseName,
                  sectionTitle: sectionTitle,
                ),
              ),
            );
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Mulai Kuis di Web'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

class SinglefulDetailContent extends StatelessWidget {
  final SubSection item;
  final QuizSetting? quiz;

  const SinglefulDetailContent({super.key, required this.item, this.quiz});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        if (quiz != null) ...[
          _buildInfoRow(
            icon: Icons.timer_outlined,
            title: 'Waktu Pengerjaan',
            value: '${quiz!.duration} Menit',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.format_list_bulleted_rounded,
            title: 'Tipe Soal',
            value: quiz!.tipeQuiz == 'MULTIPLE_CHOICE' ? 'Pilihan Ganda' : quiz!.tipeQuiz,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.shuffle_rounded,
            title: 'Acak Pilihan Jawaban',
            value: quiz!.shuffleJawaban ? 'Ya' : 'Tidak',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.layers_outlined,
            title: 'Tampilan Soal',
            value: quiz!.onePagePerQuestion ? '1 Halaman Per Soal' : 'Semua Soal',
          ),
        ],
        const SizedBox(height: 14),
        if (item.warningAlert != null && item.warningAlert!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.dangerRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.warningAlert!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.successGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kuis terbuka dan siap dikerjakan.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
      ],
    );
  }
}
