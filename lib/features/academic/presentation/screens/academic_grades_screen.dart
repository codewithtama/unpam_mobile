import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/academic_grades_model.dart';
import '../providers/academic_portal_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../widgets/portal_state_views.dart';
import '../widgets/portal_ai_assist.dart';

class AcademicGradesScreen extends StatefulWidget {
  const AcademicGradesScreen({super.key});

  @override
  State<AcademicGradesScreen> createState() => _AcademicGradesScreenState();
}

class _AcademicGradesScreenState extends State<AcademicGradesScreen> {
  int _selectedSemesterFilter = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AcademicPortalProvider>();
      if (!provider.grades.hasData) {
        provider.fetchGrades();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getGradeColor(String grade) {
    final g = grade.toUpperCase().trim();
    if (g.startsWith('A')) return AppTheme.successGreen;
    if (g.startsWith('B')) return AppTheme.primaryLight;
    if (g.startsWith('C')) return AppTheme.accentGold;
    if (g.startsWith('D')) return AppTheme.dangerRed;
    if (g.startsWith('E')) return AppTheme.dangerRed;
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final resource = provider.grades;

    return PortalPageScaffold(
      title: 'Rangkuman Nilai',
      isLoading: resource.isLoading,
      onRefresh: () => provider.fetchGrades(forceRefresh: true),
      body: _buildBody(provider, resource),
      aiContext: PortalAiContext(
        pageTitle: 'Rangkuman Nilai',
        label: 'Nilai',
        buildPageText: () => PortalAiText.grades(provider.grades.data),
      ),
    );
  }

  Widget _buildBody(AcademicPortalProvider provider, PortalResource<AcademicGradesResponse> resource) {
    final data = resource.data;
    Future<void> retry() => provider.fetchGrades(forceRefresh: true);

    if (data == null) {
      if (resource.isLoading) {
        return const PortalLoadingView(message: 'Memuat transkrip nilai...');
      }
      return PortalErrorView(
        icon: Icons.assignment_late_rounded,
        title: 'Gagal Memuat Nilai',
        message: resource.error,
        onRetry: retry,
      );
    }


    final grouped = data.groupedBySemester;
    final availableSemesters = grouped.keys.toList()..sort();

    List<CourseGradeItem> displayCourses = [];
    if (_selectedSemesterFilter == 0) {
      displayCourses = data.rangkuman;
    } else {
      displayCourses = grouped[_selectedSemesterFilter] ?? [];
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      displayCourses = displayCourses.where((c) {
        return c.snama.toLowerCase().contains(q) ||
            c.idmtk.toLowerCase().contains(q) ||
            c.fgrade.toLowerCase().contains(q);
      }).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (resource.error != null)
          PortalSyncBanner(message: resource.error!, onRetry: retry),
        _buildHeroGpaCard(data),
        const SizedBox(height: 16),
        _buildSearchField(),
        const SizedBox(height: 12),
        _buildSemesterFilterChips(availableSemesters),
        const SizedBox(height: 16),
        if (_selectedSemesterFilter > 0)
          _buildSemesterPerformanceCard(data, _selectedSemesterFilter),
        _buildCourseListHeader(displayCourses.length),
        const SizedBox(height: 10),
        if (displayCourses.isEmpty)
          _buildEmptyResults()
        else
          ...displayCourses.map((c) => _buildCourseCard(c)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeroGpaCard(AcademicGradesResponse data) {
    final sksLulus = data.mutu?.totalSksPassed ?? 0;
    final sksAmbil = data.mutu?.totalSksTaken ?? 0;
    final totalMutu = data.mutu?.totalMutuPassed ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Indeks Prestasi Kumulatif',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        data.ipk,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ 4.00',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  size: 36,
                  color: AppTheme.accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGpaMetric('SKS Lulus', '$sksLulus SKS'),
                Container(height: 22, width: 1, color: Colors.white.withOpacity(0.2)),
                _buildGpaMetric('SKS Diambil', '$sksAmbil SKS'),
                Container(height: 22, width: 1, color: Colors.white.withOpacity(0.2)),
                _buildGpaMetric('Total Mutu', totalMutu.toStringAsFixed(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpaMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari mata kuliah atau kode...',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSemesterFilterChips(List<int> semesters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Semua Semester'),
            selected: _selectedSemesterFilter == 0,
            onSelected: (selected) {
              if (selected) setState(() => _selectedSemesterFilter = 0);
            },
            selectedColor: AppTheme.primaryBlue,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _selectedSemesterFilter == 0 ? Colors.white : AppTheme.textDark,
            ),
          ),
          const SizedBox(width: 8),
          ...semesters.map((s) {
            final isSelected = _selectedSemesterFilter == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('Semester $s'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedSemesterFilter = s);
                },
                selectedColor: AppTheme.primaryBlue,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textDark,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSemesterPerformanceCard(AcademicGradesResponse data, int semesterNum) {
    final ips = data.calculateSemesterGpa(semesterNum);
    final sks = data.calculateSemesterSks(semesterNum);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Indeks Prestasi Semester (IPS) $semesterNum',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                ips.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$sks SKS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseListHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daftar Nilai ($count Mata Kuliah)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(CourseGradeItem course) {
    final gradeColor = _getGradeColor(course.fgrade);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: gradeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gradeColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                course.fgrade,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.snama,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      course.idmtk,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppTheme.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sem ${course.isemester}',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppTheme.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${course.sks} SKS',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Mutu: ${course.ambilMutu}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bobot: ${course.imutu}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'Tidak ada mata kuliah yang cocok',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci pencarian atau filter semester',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
