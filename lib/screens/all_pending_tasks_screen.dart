import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sub_section_tile.dart';

class AllPendingTasksScreen extends StatelessWidget {
  const AllPendingTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseProv = context.watch<CourseProvider>();
    final pending = courseProv.pendingTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas & Kuis Pending'),
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFFBEB),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: AppTheme.accentGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ditemukan ${pending.length} aktivitas kuis & tugas yang belum diselesaikan.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List Tugas Pending
          Expanded(
            child: pending.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Semua Tugas Telah Selesai!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tidak ada kuis atau tugas yang tertunda.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: pending.length,
                    itemBuilder: (ctx, index) {
                      final item = pending[index];
                      return SubSectionTile(
                        item: item.subSection,
                        courseKode: courseProv.selectedCourse?.kodeCourse,
                        courseName: courseProv.selectedCourse?.namaMataKuliah,
                        sectionTitle: '${item.sectionTitle}${item.meetingTitle != null ? ' - ${item.meetingTitle}' : ''}',
                        onToggleCompletion: (_) {
                          courseProv.toggleTaskCompletion(item.subSection);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
