import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_detail_model.dart';
import '../theme/app_theme.dart';
import 'quiz_dialog.dart';

class SubSectionTile extends StatelessWidget {
  final SubSection item;
  final String? sectionTitle;
  final ValueChanged<bool?>? onToggleCompletion;

  const SubSectionTile({
    super.key,
    required this.item,
    this.sectionTitle,
    this.onToggleCompletion,
  });

  IconData _getIcon() {
    switch (item.kodeTemplate) {
      case 'PRE_TEST':
      case 'POST_TEST':
        return Icons.quiz_rounded;
      case 'PENUGASAN_TERSTRUKTUR':
        return Icons.assignment_rounded;
      case 'FORUM_DISKUSI':
        return Icons.forum_rounded;
      case 'POWER_POINT':
        return Icons.slideshow_rounded;
      case 'BUKU_ISBN':
        return Icons.menu_book_rounded;
      case 'VIDEO_AJAR':
        return Icons.play_circle_fill_rounded;
      case 'LINK_VCON':
        return Icons.video_camera_front_rounded;
      case 'KUESIONER':
        return Icons.poll_rounded;
      case 'RPS':
        return Icons.description_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Color _getTypeColor() {
    switch (item.kodeTemplate) {
      case 'PRE_TEST':
      case 'POST_TEST':
        return const Color(0xFFD97706); // Amber
      case 'PENUGASAN_TERSTRUKTUR':
        return const Color(0xFF2563EB); // Royal Blue
      case 'FORUM_DISKUSI':
        return const Color(0xFF9333EA); // Purple
      case 'POWER_POINT':
        return const Color(0xFFEA580C); // Orange
      case 'LINK_VCON':
        return const Color(0xFF0D9488); // Teal
      case 'KUESIONER':
        return const Color(0xFF0284C7); // Cyan
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  Future<void> _handleAction(BuildContext context) async {
    if (item.settingQuiz != null) {
      showDialog(
        context: context,
        builder: (ctx) => QuizDialog(item: item),
      );
      return;
    }

    if (item.link != null && item.link!.isNotEmpty) {
      final uri = Uri.parse(item.link!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: ${item.link}')),
        );
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(item.warningAlert ?? 'Konten belum tersedia atau belum dibuka oleh dosen.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();
    final bool isCompleted = item.completion;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? AppTheme.successGreen.withOpacity(0.3) : AppTheme.cardBorder,
          width: isCompleted ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Pertemuan Asal (jika ada) & Badge Tipe
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (sectionTitle != null)
                  Text(
                    sectionTitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.typeLabel,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Baris Konten: Icon, Judul, dan Checkbox Penyelesaian
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon tipe aktivitas
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(), size: 20, color: typeColor),
                ),
                const SizedBox(width: 12),

                // Judul & Info tambahan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.judul,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppTheme.textMuted : AppTheme.textDark,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (item.settingQuiz != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Durasi: ${item.settingQuiz!.duration} Menit',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Checkbox status pengerjaan (Interaktif untuk demo)
                IconButton(
                  tooltip: isCompleted ? 'Tandai Belum Selesai' : 'Tandai Selesai',
                  onPressed: () {
                    if (onToggleCompletion != null) {
                      onToggleCompletion!(!isCompleted);
                    }
                  },
                  icon: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: isCompleted ? AppTheme.successGreen : AppTheme.textMuted,
                    size: 24,
                  ),
                ),
              ],
            ),

            // Warning Alert jika ada (misal: "Silakan selesaikan Pretest terlebih dahulu")
            if (item.warningAlert != null && item.warningAlert!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.accentGold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.warningAlert!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Button (Buka Kuis, Unduh File, atau Masuk Meet)
            if (item.settingQuiz != null || (item.link != null && item.link!.isNotEmpty)) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleAction(context),
                  icon: Icon(
                    item.settingQuiz != null
                        ? Icons.play_arrow_rounded
                        : (item.kodeTemplate == 'LINK_VCON'
                            ? Icons.videocam_rounded
                            : Icons.open_in_new_rounded),
                    size: 16,
                  ),
                  label: Text(
                    item.settingQuiz != null
                        ? 'Kerjakan Kuis'
                        : (item.kodeTemplate == 'LINK_VCON'
                            ? 'Buka Google Meet'
                            : 'Buka File / Link Materi'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: typeColor,
                    side: BorderSide(color: typeColor.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
