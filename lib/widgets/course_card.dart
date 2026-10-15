import 'package:flutter/material.dart';
import '../models/user_course_model.dart';
import '../theme/app_theme.dart';

class CourseCard extends StatelessWidget {
  final CourseItem course;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Bedakan warna aksen kartu berdasarkan SKS
    final bool is3Sks = course.sks == 3;
    final Color badgeBg = is3Sks ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final Color badgeText = is3Sks ? const Color(0xFF1D4ED8) : const Color(0xFF15803D);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: SKS Chip & Hari/Shift
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeText.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${course.sks} SKS',
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${course.namaHari} (Shift ${course.idShift})',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nama Mata Kuliah
              Text(
                course.namaMataKuliah,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Kode Kelas
              Text(
                'Kelas: ${course.idKelas} • Kode: ${course.idMataKuliah}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 20, thickness: 0.8, color: AppTheme.cardBorder),

              // Footer: Nama Dosen Pengampu & Arrow
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryLight.withOpacity(0.12),
                    child: const Icon(Icons.person_rounded, size: 16, color: AppTheme.primaryLight),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      course.namaDosen,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
