import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/mentari_course_model.dart';
import '../../domain/models/mentari_module_model.dart';
import '../../domain/models/mentari_section_model.dart';
import '../providers/mentari_provider.dart';
import '../widgets/mentari_activity_tile.dart';
import '../widgets/mentari_quiz_modal.dart';

class MentariCourseDetailScreen extends StatefulWidget {
  final MentariCourseModel course;

  const MentariCourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<MentariCourseDetailScreen> createState() => _MentariCourseDetailScreenState();
}

class _MentariCourseDetailScreenState extends State<MentariCourseDetailScreen> {
  final Set<int> _expandedSectionIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MentariProvider>().fetchCourseSections(widget.course.id);
    });
  }

  void _handleActivityTap(MentariModuleModel module) {
    if (module.type == MentariModuleType.quiz ||
        module.type == MentariModuleType.assign ||
        module.type == MentariModuleType.attendance ||
        module.type == MentariModuleType.forum) {
      MentariQuizModal.show(
        context,
        title: module.name,
        url: module.url,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MentariProvider>();
    final sections = provider.getSectionsForCourse(widget.course.id);
    final isLoading = provider.isLoadingSections && sections.isEmpty;
    final color = widget.course.accentColor;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(widget.course.cleanTitle),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Materi',
            onPressed: () =>
                provider.fetchCourseSections(widget.course.id, forceRefresh: true),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 14),
                  Text('Memuat 21 pertemuan...', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppTheme.primaryBlue,
              onRefresh: () =>
                  provider.fetchCourseSections(widget.course.id, forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                          '${sections.length} Bagian Pertemuan Perkuliahan',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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
                            'Modul pertemuan belum dipublikasikan oleh dosen pengampu atau sesi Anda perlu diperbarui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                            onPressed: () => provider.fetchCourseSections(widget.course.id, forceRefresh: true),
                            icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                            label: const Text('Muat Ulang', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...sections.map((sec) => _buildSectionAccordion(sec)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionAccordion(MentariSectionModel section) {
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
          // Header click to expand
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

          // Content body
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
                        onTap: _handleActivityTap,
                        onOpenInAppBrowser: (url) => MentariQuizModal.show(
                          context,
                          title: m.name,
                          url: url,
                        ),
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

