import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../../domain/models/thesis_model.dart';
import '../providers/academic_portal_provider.dart';
import '../widgets/portal_ai_assist.dart';
import '../widgets/portal_state_views.dart';

class ThesisScreen extends StatefulWidget {
  const ThesisScreen({super.key});

  @override
  State<ThesisScreen> createState() => _ThesisScreenState();
}

class _ThesisScreenState extends State<ThesisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AcademicPortalProvider>();
      if (!p.thesis.hasData) p.fetchThesis();
    });
  }

  Future<void> _refresh() =>
      context.read<AcademicPortalProvider>().fetchThesis(forceRefresh: true);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final thesisResource = provider.thesis;
    final thesis = thesisResource.data;

    return PortalPageScaffold(
      title: 'Tugas Akhir & Skripsi',
      isLoading: thesisResource.isLoading && !thesisResource.hasData,
      onRefresh: _refresh,
      aiContext: PortalAiContext(
        pageTitle: 'Tugas Akhir',
        label: 'Tugas Akhir & Skripsi',
        buildPageText: () => PortalAiText.thesis(thesis),
      ),
      body: Builder(
        builder: (context) {
          if (thesis == null) {
            if (thesisResource.isLoading) {
              return const PortalLoadingView(message: 'Memuat data tugas akhir...');
            }
            return PortalErrorView(
              icon: Icons.menu_book_rounded,
              title: 'Gagal Memuat Tugas Akhir',
              message: thesisResource.error,
              onRetry: _refresh,
            );
          }

          if (!thesis.hasActiveThesis) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 48,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Mengambil Tugas Akhir',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Anda belum terdaftar dalam masa bimbingan proposal atau tugas akhir skripsi semester ini.',
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
              if (thesisResource.error != null)
                PortalSyncBanner(message: thesisResource.error!, onRetry: _refresh),
              _buildHeaderCard(thesis),
              const SizedBox(height: 14),
              _buildSupervisorsCard(thesis.supervisors),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Bimbingan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${thesis.guidanceHistory.length} Sesi Pertemuan',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (thesis.guidanceHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada catatan log bimbingan.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ),
                )
              else
                ...thesis.guidanceHistory.map(_buildGuidanceTile),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(ThesisResponse thesis) {
    final status = thesis.detail?.status ?? (thesis.isProposal ? 'Proposal' : 'Skripsi');
    final judul = thesis.detail?.judul ?? 'Belum ada judul penelitian';

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
                  Icons.menu_book_rounded,
                  color: AppTheme.accentGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thesis.isProposal ? 'PROPOSAL PENELITIAN' : 'TUGAS AKHIR / SKRIPSI',
                      style: const TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Judul Penelitian:',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            judul,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          if (thesis.detail?.abstrak != null) ...[
            const SizedBox(height: 10),
            Text(
              thesis.detail!.abstrak!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupervisorsCard(ThesisSupervisors? supervisors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.supervisor_account_rounded, size: 20, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text(
                'Dosen Pembimbing',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSupervisorRow('Pembimbing 1', supervisors?.pembimbing1 ?? 'Belum ditentukan'),
          const Divider(height: 16, color: AppTheme.cardBorder),
          _buildSupervisorRow('Pembimbing 2', supervisors?.pembimbing2 ?? 'Belum ditentukan'),
        ],
      ),
    );
  }

  Widget _buildSupervisorRow(String role, String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            role,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceTile(ThesisGuidanceItem item) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pertemuan ${item.pertemuanKe}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              if (item.tanggal != null)
                Text(
                  item.tanggal!,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
            ],
          ),
          if (item.materiBimbingan != null && item.materiBimbingan!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.materiBimbingan!,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
            ),
          ],
          if (item.catatan != null && item.catatan!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.catatan!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
