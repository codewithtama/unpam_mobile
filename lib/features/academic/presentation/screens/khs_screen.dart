import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../../domain/models/khs_model.dart';
import '../providers/academic_portal_provider.dart';
import '../widgets/portal_ai_assist.dart';
import '../widgets/portal_state_views.dart';

class KhsScreen extends StatefulWidget {
  const KhsScreen({super.key});

  @override
  State<KhsScreen> createState() => _KhsScreenState();
}

class _KhsScreenState extends State<KhsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AcademicPortalProvider>();
      if (!p.khs.hasData) p.fetchKhs();
    });
  }

  Future<void> _refresh() =>
      context.read<AcademicPortalProvider>().fetchKhs(forceRefresh: true);

  Color _getGradeColor(String grade) {
    final g = grade.trim().toUpperCase();
    if (g.startsWith('A')) return AppTheme.successGreen;
    if (g.startsWith('B')) return AppTheme.primaryLight;
    if (g.startsWith('C')) return AppTheme.accentGold;
    if (g.startsWith('D') || g.startsWith('E')) return AppTheme.dangerRed;
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final khsResource = provider.khs;
    final khs = khsResource.data;

    return PortalPageScaffold(
      title: 'Kartu Hasil Studi',
      isLoading: khsResource.isLoading && !khsResource.hasData,
      onRefresh: _refresh,
      aiContext: PortalAiContext(
        pageTitle: 'KHS',
        label: 'Kartu Hasil Studi',
        buildPageText: () => PortalAiText.khs(khs),
      ),
      body: Builder(
        builder: (context) {
          if (khs == null) {
            if (khsResource.isLoading) {
              return const PortalLoadingView(message: 'Memuat Kartu Hasil Studi...');
            }
            return PortalErrorView(
              icon: Icons.grade_rounded,
              title: 'Gagal Memuat KHS',
              message: khsResource.error,
              onRetry: _refresh,
            );
          }

          if (khs.courses.isEmpty) {
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
                        Icons.grade_rounded,
                        size: 48,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Nilai KHS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Data Kartu Hasil Studi semester ini belum dipublikasikan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    if (khsResource.error != null)
                      PortalSyncBanner(message: khsResource.error!, onRetry: _refresh),
                    _buildHeaderCard(khs),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Hasil Studi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          '${khs.courses.length} Mata Kuliah',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: khs.courses.length,
                  itemBuilder: (context, index) =>
                      _buildKhsCard(khs.courses[index]),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(KhsResponse khs) {
    final semesterName = khs.semester?.namaSemesterRegistrasi ?? 'Semester Aktif';
    final ipsText = khs.ips != null ? khs.ips!.toStringAsFixed(2) : '-';
    final totalSks = khs.totalSks;
    final sksLulus = khs.mutu?.sksLulus ?? totalSks;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grade_rounded,
                  color: AppTheme.accentGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KARTU HASIL STUDI (KHS)',
                      style: TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      semesterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ipsText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'IPS Semester',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('SKS Diambil', '$totalSks SKS'),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildStatColumn('SKS Lulus', '$sksLulus SKS'),
                if (khs.mutu != null) ...[
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  _buildStatColumn('Total Mutu', khs.mutu!.totalMutuAmbil),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildKhsCard(KhsCourseItem item) {
    final gradeColor = _getGradeColor(item.grade);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: gradeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gradeColor.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              item.grade,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: gradeColor,
              ),
            ),
          ),
          title: Text(
            item.namaMataKuliah,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  '${item.sksCount} SKS',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  '• Kelas ${item.kelas}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  '• Mutu ${item.mutu}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgGrey,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rincian Komponen Nilai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildScoreBadge('Absen', item.nilaiAbsen ?? '-'),
                        _buildScoreBadge('Tugas', item.nilaiTugas ?? '-'),
                        _buildScoreBadge('Quiz', item.nilaiQuiz ?? '-'),
                        _buildScoreBadge('UTS', item.nilaiUts ?? '-'),
                        _buildScoreBadge('UAS', item.nilaiUas ?? '-'),
                      ],
                    ),
                    if (item.aktifitasPartisipatif != null || item.hasilProyek != null) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 12, color: AppTheme.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (item.aktifitasPartisipatif != null)
                            _buildScoreBadge('Partisipatif', item.aktifitasPartisipatif!),
                          if (item.hasilProyek != null)
                            _buildScoreBadge('Proyek', item.hasilProyek!),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
