import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/schedule_model.dart';

/// Kartu jadwal kuliah untuk satu sesi pertemuan.
class TodayScheduleCard extends StatelessWidget {
  final CourseSchedule schedule;
  final bool isOngoing;

  const TodayScheduleCard({
    super.key,
    required this.schedule,
    this.isOngoing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isOngoing
            ? AppTheme.primaryBlue.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOngoing
              ? AppTheme.primaryBlue.withOpacity(0.4)
              : AppTheme.cardBorder,
          width: isOngoing ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            // Kolom Waktu
            SizedBox(
              width: 62,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    schedule.jamMulai,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isOngoing
                          ? AppTheme.primaryBlue
                          : AppTheme.textDark,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    width: 1.5,
                    height: 16,
                    color: AppTheme.cardBorder,
                  ),
                  Text(
                    schedule.jamSelesai,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1.5,
              height: 74,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isOngoing
                        ? AppTheme.primaryBlue
                        : AppTheme.primaryBlue.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Kolom Detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          schedule.namaMataKuliah,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildModeBadge(),
                      if (isOngoing) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Berlangsung',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.tag_rounded, schedule.kode),
                  if (schedule.ruang.isNotEmpty)
                    _buildInfoRow(
                      schedule.isOnline
                          ? Icons.laptop_chromebook_rounded
                          : Icons.room_outlined,
                      schedule.ruang,
                    ),
                  if (schedule.dosen.isNotEmpty)
                    _buildInfoRow(Icons.person_outline_rounded, schedule.dosen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBadge() {
    final isOnline = schedule.isOnline;
    final Color badgeBg = isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final Color badgeText = isOnline ? const Color(0xFF1D4ED8) : const Color(0xFF15803D);
    final Color badgeBorder = isOnline ? const Color(0xFFBFDBFE) : const Color(0xFFBBF7D0);
    final IconData badgeIcon = isOnline ? Icons.laptop_chromebook_rounded : Icons.apartment_rounded;
    final String label = isOnline ? 'Online' : 'Tatap Muka';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 10, color: badgeText),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
