import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/cloudflare_clearance_modal.dart';
import '../../../../core/services/file_download_service.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/mentari_course_model.dart';
import '../../domain/models/mentari_interactive_models.dart';
import '../../domain/models/mentari_module_model.dart';
import '../../domain/models/mentari_section_model.dart';
import '../providers/mentari_provider.dart';
import '../widgets/mentari_activity_tile.dart';
import 'mentari_native_assignment_screen.dart';
import 'mentari_native_forum_screen.dart';
import 'mentari_native_quiz_screen.dart';

class MentariCourseDetailScreen extends StatefulWidget {
  final MentariCourseModel course;

  const MentariCourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<MentariCourseDetailScreen> createState() => _MentariCourseDetailScreenState();
}

class _MentariCourseDetailScreenState extends State<MentariCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  final Set<int> _expandedSectionIds = {};
  final TextEditingController _participantSearchController = TextEditingController();
  late final TabController _tabController;
  String _participantQuery = '';

  String? get _resolvedCourseCode =>
      widget.course.courseCode ??
      (widget.course.idNumber.isNotEmpty ? widget.course.idNumber : null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MentariProvider>().fetchCourseSections(
            widget.course.id,
            courseCode: _resolvedCourseCode,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _participantSearchController.dispose();
    super.dispose();
  }

  Future<void> _handleActivityTap(
    MentariModuleModel module, {
    MentariSectionModel? section,
  }) async {
    if (module.warningAlert != null && module.warningAlert!.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.accentGold, size: 22),
              SizedBox(width: 8),
              Text('Informasi Aktivitas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            module.warningAlert!,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buka Mode Native'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    if (!mounted) return;
    final sectionTitle = section?.name ?? 'Pertemuan';

    switch (module.type) {
      case MentariModuleType.quiz:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MentariNativeQuizScreen(
              module: module,
              courseTitle: widget.course.cleanTitle,
              sectionTitle: sectionTitle,
            ),
          ),
        );
      case MentariModuleType.forum:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MentariNativeForumScreen(
              module: module,
              courseTitle: widget.course.cleanTitle,
              sectionTitle: sectionTitle,
            ),
          ),
        );
      case MentariModuleType.assign:
      case MentariModuleType.attendance:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MentariNativeAssignmentScreen(
              module: module,
              courseTitle: widget.course.cleanTitle,
              sectionTitle: sectionTitle,
            ),
          ),
        );
      case MentariModuleType.resource:
        final target = module.fileUrl ?? module.url;
        if (target.isNotEmpty) {
          await FileDownloadService().downloadAndOpenFile(
            url: target,
            customFileName: module.fileName ?? '${module.name}.pdf',
          );
        }
      case MentariModuleType.url:
      case MentariModuleType.page:
      case MentariModuleType.other:
        if (module.url.isNotEmpty) {
          final uri = Uri.tryParse(module.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MentariProvider>();
    final sections = provider.getSectionsForCourse(widget.course.id);
    final participants = provider.getParticipantsForCourse(widget.course.id);
    final isLoading = provider.isLoadingSections && sections.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(widget.course.cleanTitle),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: 'Verifikasi Cloudflare',
            onPressed: () async {
              final cleared = await CloudflareClearanceModal.show(
                context,
                targetUrl: ApiConstants.mentariBaseUrl,
                portalTitle: 'Mentari LMS',
              );
              if (cleared == true && mounted) {
                provider.fetchCourseSections(
                  widget.course.id,
                  courseCode: _resolvedCourseCode,
                  forceRefresh: true,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Materi',
            onPressed: () => provider.fetchCourseSections(
              widget.course.id,
              courseCode: _resolvedCourseCode,
              forceRefresh: true,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.accentGold,
          indicatorWeight: 2.5,
          tabs: [
            Tab(text: 'Pertemuan (${sections.length})'),
            Tab(text: 'Peserta Kelas (${participants.length})'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 14),
                  Text('Memuat 21 pertemuan native...', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMeetingsTab(provider, sections),
                _buildParticipantsTab(participants),
              ],
            ),
    );
  }

  Widget _buildMeetingsTab(
    MentariProvider provider,
    List<MentariSectionModel> sections,
  ) {
    final color = widget.course.accentColor;

    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: () => provider.fetchCourseSections(
        widget.course.id,
        courseCode: _resolvedCourseCode,
        forceRefresh: true,
      ),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.course.cleanCode.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.course.cleanCode,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Text(
                        widget.course.cleanTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${sections.length} Bagian Pertemuan Perkuliahan • 100% Native Mode',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (sections.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.auto_stories_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum Ada Materi Tersedia',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Modul pertemuan belum dipublikasikan atau sesi Cloudflare Anda perlu diverifikasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                              onPressed: () => provider.fetchCourseSections(
                                widget.course.id,
                                courseCode: _resolvedCourseCode,
                                forceRefresh: true,
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                              label: const Text('Muat Ulang', style: TextStyle(color: Colors.white)),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final cleared = await CloudflareClearanceModal.show(
                                  context,
                                  targetUrl: ApiConstants.mentariBaseUrl,
                                  portalTitle: 'Mentari LMS',
                                );
                                if (cleared == true && mounted) {
                                  provider.fetchCourseSections(
                                    widget.course.id,
                                    courseCode: _resolvedCourseCode,
                                    forceRefresh: true,
                                  );
                                }
                              },
                              icon: const Icon(Icons.verified_user_rounded, size: 18),
                              label: const Text('Verifikasi Cloudflare'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
          if (sections.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
              sliver: SliverList.builder(
                itemCount: sections.length,
                itemBuilder: (ctx, idx) => _buildSectionAccordion(provider, sections[idx]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(List<MentariParticipantModel> participants) {
    final q = _participantQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? participants
        : participants.where((p) {
            return p.namaMahasiswa.toLowerCase().contains(q) ||
                p.nim.toLowerCase().contains(q);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: _participantSearchController,
            onChanged: (v) => setState(() => _participantQuery = v),
            decoration: const InputDecoration(
              hintText: 'Cari nama atau NIM teman sekelas...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Daftar peserta kelas belum tersedia.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final p = filtered[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                            child: Text(
                              p.initials,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.namaMahasiswa,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  'NIM: ${p.nim}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textMuted,
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
      ],
    );
  }

  Widget _buildSectionAccordion(
    MentariProvider provider,
    MentariSectionModel section,
  ) {
    final isExpanded = _expandedSectionIds.contains(section.id) ||
        (_expandedSectionIds.isEmpty && section.sectionNumber <= 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                if (_expandedSectionIds.contains(section.id)) {
                  _expandedSectionIds.remove(section.id);
                } else {
                  _expandedSectionIds.add(section.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: section.sectionNumber > 0
                          ? AppTheme.primaryBlue.withOpacity(0.1)
                          : AppTheme.accentGold.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        section.sectionNumber > 0 ? '${section.sectionNumber}' : 'i',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: section.sectionNumber > 0
                              ? AppTheme.primaryBlue
                              : AppTheme.accentGold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        if (section.modules.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${section.modules.length} aktivitas perkuliahan',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppTheme.cardBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.summary.isNotEmpty) ...[
                    Text(
                      section.summary,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (section.modules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Belum ada berkas atau penugasan di pertemuan ini.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ...section.modules.map(
                      (m) => MentariActivityTile(
                        module: m,
                        onTap: (mod) => _handleActivityTap(mod, section: section),
                        onOpenInAppBrowser: (_) => _handleActivityTap(m, section: section),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
