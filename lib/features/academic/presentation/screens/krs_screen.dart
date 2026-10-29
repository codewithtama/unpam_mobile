import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../../domain/models/krs_model.dart';
import '../providers/academic_portal_provider.dart';
import '../widgets/portal_ai_assist.dart';
import '../widgets/portal_state_views.dart';

class KrsScreen extends StatefulWidget {
  const KrsScreen({super.key});

  @override
  State<KrsScreen> createState() => _KrsScreenState();
}

class _KrsScreenState extends State<KrsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AcademicPortalProvider>();
      if (!p.krs.hasData) p.fetchKrs();
    });
  }

  Future<void> _refresh() =>
      context.read<AcademicPortalProvider>().fetchKrs(forceRefresh: true);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final krsResource = provider.krs;
    final krs = krsResource.data;

    return PortalPageScaffold(
      title: 'Kartu Rencana Studi',
      isLoading: krsResource.isLoading && !krsResource.hasData,
      onRefresh: _refresh,
      aiContext: PortalAiContext(
        pageTitle: 'KRS',
        label: 'Kartu Rencana Studi',
        buildPageText: () => PortalAiText.krs(krs),
      ),
      body: Builder(
        builder: (context) {
          if (krs == null) {
            if (krsResource.isLoading) {
              return const PortalLoadingView(message: 'Memuat Kartu Rencana Studi...');
            }
            return PortalErrorView(
              icon: Icons.receipt_long_rounded,
              title: 'Gagal Memuat KRS',
              message: krsResource.error,
              onRetry: _refresh,
            );
          }

          if (krs.courses.isEmpty) {
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
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada KRS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Data rencana studi semester aktif belum tersedia.',
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
              if (krsResource.error != null)
                PortalSyncBanner(message: krsResource.error!, onRetry: _refresh),
              _buildHeaderCard(krs),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mata Kuliah Dikontrak',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${krs.courses.length} Mata Kuliah',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...krs.courses.map(_buildCourseCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(KrsResponse krs) {
    final semesterName = krs.semester?.namaSemesterRegistrasi ?? 'Semester Aktif';
    final totalSks = krs.totalSks;
    final sksLulus = krs.mutu?.sksLulus ?? 0;

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
                  Icons.receipt_long_rounded,
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
                      'KARTU RENCANA STUDI',
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
                _buildStatColumn('SKS Dikontrak', '$totalSks SKS'),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildStatColumn('Total SKS Lulus', '$sksLulus SKS'),
                if (krs.mutu != null) ...[
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  _buildStatColumn('Total Mutu', krs.mutu!.totalMutuLulus),
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

  Widget _buildCourseCard(KrsCourseItem course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                  course.namaMataKuliah,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${course.sks} SKS',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (course.idKelas.isNotEmpty)
                _buildTag(Icons.meeting_room_outlined, 'Kelas ${course.idKelas}'),
              if (course.idMataKuliah.isNotEmpty)
                _buildTag(Icons.code_rounded, course.idMataKuliah),
              if (course.namaKurikulum != null)
                _buildTag(Icons.bookmark_border_rounded, course.namaKurikulum!),
            ],
          ),
          if (course.namaDosenPengampu != null &&
              course.namaDosenPengampu!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    course.namaDosenPengampu!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
