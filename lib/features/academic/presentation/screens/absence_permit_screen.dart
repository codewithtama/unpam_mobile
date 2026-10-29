import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../../domain/models/absence_permit_model.dart';
import '../providers/academic_portal_provider.dart';
import '../widgets/portal_ai_assist.dart';
import '../widgets/portal_state_views.dart';

class AbsencePermitScreen extends StatefulWidget {
  const AbsencePermitScreen({super.key});

  @override
  State<AbsencePermitScreen> createState() => _AbsencePermitScreenState();
}

class _AbsencePermitScreenState extends State<AbsencePermitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AcademicPortalProvider>();
      if (!p.absencePermits.hasData) p.fetchAbsencePermits();
    });
  }

  Future<void> _refresh() =>
      context.read<AcademicPortalProvider>().fetchAbsencePermits(forceRefresh: true);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final permitResource = provider.absencePermits;
    final permitResponse = permitResource.data;
    final permits = permitResponse?.permits;

    return PortalPageScaffold(
      title: 'Pengajuan Izin & Absen',
      isLoading: permitResource.isLoading && !permitResource.hasData,
      onRefresh: _refresh,
      aiContext: PortalAiContext(
        pageTitle: 'Pengajuan Izin',
        label: 'Pengajuan Izin',
        buildPageText: () => PortalAiText.absencePermits(permitResponse),
      ),
      body: Builder(
        builder: (context) {
          if (permits == null) {
            if (permitResource.isLoading) {
              return const PortalLoadingView(message: 'Memuat pengajuan izin...');
            }
            return PortalErrorView(
              icon: Icons.event_busy_rounded,
              title: 'Gagal Memuat Pengajuan Izin',
              message: permitResource.error,
              onRetry: _refresh,
            );
          }

          if (permits.isEmpty) {
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
                        Icons.event_busy_rounded,
                        size: 48,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Pengajuan Izin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tidak ada riwayat pengajuan izin tidak hadir atau absen jalan.',
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
              if (permitResource.error != null)
                PortalSyncBanner(message: permitResource.error!, onRetry: _refresh),
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
                        Icons.event_busy_rounded,
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
                            'IZIN & ABSEN JALAN',
                            style: TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${permits.length} Pengajuan Tercatat',
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
              ...permits.map(_buildPermitCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermitCard(AbsencePermitItem item) {
    final (Color statusColor, String statusText) = item.isApproved
        ? (AppTheme.successGreen, 'Disetujui')
        : item.status?.toLowerCase() == 'ditolak'
            ? (AppTheme.dangerRed, 'Ditolak')
            : (AppTheme.accentGold, item.status ?? 'Menunggu Persetujuan');

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
                  item.namaMataKuliah ?? 'Perkuliahan',
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
          const SizedBox(height: 6),
          Row(
            children: [
              if (item.pertemuanKe != null) ...[
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
              ],
              if (item.jenisIzin != null)
                Text(
                  item.jenisIzin!,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              if (item.tanggal != null) ...[
                const Spacer(),
                Text(
                  item.tanggal!,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ],
            ],
          ),
          if (item.alasan != null && item.alasan!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.alasan!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
