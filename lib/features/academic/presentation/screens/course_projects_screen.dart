import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../../domain/models/course_project_model.dart';
import '../providers/academic_portal_provider.dart';
import '../widgets/portal_ai_assist.dart';
import '../widgets/portal_state_views.dart';

class CourseProjectsScreen extends StatefulWidget {
  const CourseProjectsScreen({super.key});

  @override
  State<CourseProjectsScreen> createState() => _CourseProjectsScreenState();
}

class _CourseProjectsScreenState extends State<CourseProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AcademicPortalProvider>();
      if (!p.courseProjects.hasData) p.fetchCourseProjects();
    });
  }

  Future<void> _refresh() =>
      context.read<AcademicPortalProvider>().fetchCourseProjects(forceRefresh: true);

  Future<void> _openAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final projectsResource = provider.courseProjects;
    final projectsResponse = projectsResource.data;
    final projects = projectsResponse?.projects;

    return PortalPageScaffold(
      title: 'Penugasan Proyek',
      isLoading: projectsResource.isLoading && !projectsResource.hasData,
      onRefresh: _refresh,
      aiContext: PortalAiContext(
        pageTitle: 'Penugasan Proyek',
        label: 'Penugasan Proyek',
        buildPageText: () => PortalAiText.courseProjects(projectsResponse),
      ),
      body: Builder(
        builder: (context) {
          if (projects == null) {
            if (projectsResource.isLoading) {
              return const PortalLoadingView(message: 'Memuat penugasan proyek...');
            }
            return PortalErrorView(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Gagal Memuat Proyek',
              message: projectsResource.error,
              onRetry: _refresh,
            );
          }

          if (projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        size: 48,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Penugasan Proyek',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tidak ada daftar tugas proyek mata kuliah yang aktif.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (projectsResource.error != null)
                PortalSyncBanner(message: projectsResource.error!, onRetry: _refresh),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: AppTheme.accentGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROYEK & TUGAS BESAR',
                            style: TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${projects.length} Tugas Terdaftar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...projects.map(_buildProjectCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProjectCard(CourseProjectItem item) {
    final (Color statusColor, String statusText) = item.isApproved
        ? (AppTheme.successGreen, 'Disetujui')
        : item.pengajuanExpired
            ? (AppTheme.dangerRed, 'Kedaluwarsa')
            : (AppTheme.accentGold, 'Menunggu Validasi');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.namaMataKuliah,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Pertemuan ${item.pertemuanKe}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.sks} SKS',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
              if (item.nilai != null && item.nilai!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '• Nilai: ${item.nilai}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.namaDosenPengampu,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
              if (item.fileLampiran != null && item.fileLampiran!.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.attachment_rounded, size: 16),
                  label: const Text('Lampiran', style: TextStyle(fontSize: 12)),
                  onPressed: () => _openAttachment(item.fileLampiran!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
