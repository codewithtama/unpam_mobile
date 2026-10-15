import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_course_model.dart';
import '../models/course_detail_model.dart';
import '../providers/course_provider.dart';
import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sub_section_tile.dart';
import '../widgets/mentari_course_sync_sheet.dart';
import 'ai_assistant_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseItem course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchStudentController = TextEditingController();
  String _searchStudentQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourseDetail(widget.course);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchStudentController.dispose();
    super.dispose();
  }

  void _openSyncSheet() {
    MentariCourseSyncSheet.show(
      context,
      course: widget.course,
      onCourseSynced: (detail) {
        context.read<CourseProvider>().setCourseDetailDirectly(widget.course, detail);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseProv = context.watch<CourseProvider>();
    final detail = courseProv.courseDetail;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.namaMataKuliah),
        actions: [
          IconButton(
            tooltip: 'Sinkronkan Data Kelas (Mentari)',
            icon: const Icon(Icons.sync_rounded),
            onPressed: _openSyncSheet,
          ),
          IconButton(
            tooltip: 'Tanya AI seputar matkul ini',
            icon: const Icon(Icons.auto_awesome, color: AppTheme.accentGold),
            onPressed: () {
              context.read<AiProvider>().setSelectedCourse(widget.course.namaMataKuliah);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.assignment_late_outlined, size: 18),
              text: 'Pending (${courseProv.pendingTasks.length})',
            ),
            Tab(
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              text: 'Pertemuan (${detail?.data.length ?? 0})',
            ),
            Tab(
              icon: const Icon(Icons.people_outline_rounded, size: 18),
              text: 'Peserta (${detail?.peserta.length ?? 0})',
            ),
          ],
        ),
      ),
      body: courseProv.isLoading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? _buildErrorState(courseProv)
              : Column(
                  children: [
                    // Course Header Summary & Progress Bar
                    _buildCourseSummaryBanner(courseProv, detail),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Tugas Belum Selesai (Pending Tasks)
                          _buildPendingTasksTab(courseProv),

                          // Tab 2: Seluruh Pertemuan (1 - 21)
                          _buildAllSectionsTab(courseProv, detail),

                          // Tab 3: Teman Sekelas (Peserta 41 Mahasiswa)
                          _buildStudentsTab(detail),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState(CourseProvider courseProv) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 18),
            const Text(
              'Gagal Memuat Data Kelas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              courseProv.errorMessage ??
                  'Akses langsung dibatasi oleh sistem proteksi Cloudflare UNPAM. Sinkronkan data menggunakan sesi browser Mentari.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openSyncSheet,
                icon: const Icon(Icons.sync_rounded, size: 20),
                label: const Text(
                  'Sinkronkan via Web Mentari',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => courseProv.loadCourseDetail(widget.course, forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi Langsung'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textDark,
                  side: const BorderSide(color: AppTheme.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSummaryBanner(CourseProvider courseProv, CourseDetailResponse detail) {
    final progress = courseProv.progressPercentage;
    final totalTasks = courseProv.pendingTasks.length + courseProv.completedTasks.length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.coursename,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dosen: ${widget.course.namaDosen}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.course.sks} SKS',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Aktivitas & Tugas: ${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                '${courseProv.completedTasks.length}/$totalTasks Selesai',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.cardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTasksTab(CourseProvider courseProv) {
    final pending = courseProv.pendingTasks;

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 56, color: AppTheme.successGreen),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hebat! Semua Tugas Sudah Selesai',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tidak ada kuis atau tugas yang pending saat ini.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: pending.length,
      itemBuilder: (ctx, index) {
        final task = pending[index];
        return SubSectionTile(
          item: task.subSection,
          courseKode: widget.course.kodeCourse,
          courseName: widget.course.namaMataKuliah,
          sectionTitle: '${task.sectionTitle}${task.meetingTitle != null ? ' - ${task.meetingTitle}' : ''}',
          onToggleCompletion: (_) {
            courseProv.toggleTaskCompletion(task.subSection);
          },
        );
      },
    );
  }

  Widget _buildAllSectionsTab(CourseProvider courseProv, CourseDetailResponse detail) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: detail.data.length,
      itemBuilder: (ctx, index) {
        final section = detail.data[index];
        final completedCount = section.subSection.where((s) => s.completion).length;
        final totalCount = section.subSection.length;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryLight.withOpacity(0.12),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryLight,
                  fontSize: 13,
                ),
              ),
            ),
            title: Text(
              section.namaSection,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.namaPertemuan != null && section.namaPertemuan!.isNotEmpty)
                  Text(
                    section.namaPertemuan!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  'Selesai $completedCount dari $totalCount item',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: completedCount == totalCount ? AppTheme.successGreen : AppTheme.accentGold,
                  ),
                ),
              ],
            ),
            children: section.subSection.map((sub) {
              return SubSectionTile(
                item: sub,
                sectionTitle: section.namaPertemuan ?? section.namaSection,
                courseKode: widget.course.kodeCourse,
                courseName: widget.course.namaMataKuliah,
                onToggleCompletion: (_) {
                  courseProv.toggleTaskCompletion(sub);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStudentsTab(CourseDetailResponse detail) {
    final filtered = detail.peserta.where((p) {
      if (_searchStudentQuery.isEmpty) return true;
      return p.namaMahasiswa.toLowerCase().contains(_searchStudentQuery.toLowerCase()) ||
          p.nim.contains(_searchStudentQuery);
    }).toList();

    return Column(
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _searchStudentController,
            onChanged: (val) => setState(() => _searchStudentQuery = val),
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIM mahasiswa...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchStudentQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchStudentController.clear();
                        setState(() => _searchStudentQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // List Mahasiswa
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.cardBorder),
            itemBuilder: (ctx, index) {
              final student = filtered[index];
              final initials = student.namaMahasiswa.isNotEmpty
                  ? student.namaMahasiswa.substring(0, 1)
                  : '?';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryLight.withOpacity(0.12),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  student.namaMahasiswa,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  'NIM: ${student.nim} • ${student.alamatEmail}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
