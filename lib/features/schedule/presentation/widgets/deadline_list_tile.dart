import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/schedule_model.dart';

/// Tile satu item deadline dengan indikator countdown dan urgensi warna.
class DeadlineListTile extends StatelessWidget {
  final CourseDeadline deadline;
  final VoidCallback? onTap;

  const DeadlineListTile({
    super.key,
    required this.deadline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _urgencyColor();
    final countdownText = _countdownText();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: urgencyColor.withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: urgencyColor.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji tipe
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    deadline.tipe.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            deadline.namaTugas,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Countdown badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgencyColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            countdownText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            deadline.namaMataKuliah,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _formatDueDate(),
                          style: TextStyle(
                            fontSize: 12,
                            color: deadline.isDueSoon
                                ? urgencyColor
                                : AppTheme.textMuted,
                            fontWeight: deadline.isDueSoon
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _urgencyColor() {
    if (deadline.isOverdue) return Colors.grey.shade500;
    final days = deadline.daysUntilDue;
    if (days == 0) return AppTheme.dangerRed;
    if (days <= 3) return AppTheme.accentGold;
    return AppTheme.primaryBlue;
  }

  String _countdownText() {
    if (deadline.isOverdue) return 'Terlewat';
    final days = deadline.daysUntilDue;
    if (days == 0) return 'Hari ini';
    if (days == 1) return 'Besok';
    return '$days hari lagi';
  }

  String _formatDueDate() {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dt = deadline.dueDate;
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

