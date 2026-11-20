import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../schedule/presentation/screens/schedule_screen.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../data/my_unpam_session.dart';
import '../../data/portal_ai_text.dart';
import '../providers/academic_portal_provider.dart';
import '../providers/finance_provider.dart';
import '../../../../theme/app_theme.dart';
import '../widgets/portal_ai_assist.dart';
import '../widgets/portal_state_views.dart';
import 'academic_documents_screen.dart';
import 'academic_grades_screen.dart';
import 'absence_permit_screen.dart';
import 'attendance_screen.dart';
import 'course_projects_screen.dart';
import 'finance_screen.dart';
import 'khs_screen.dart';
import 'krs_screen.dart';
import 'seminar_certificate_screen.dart';
import 'student_profile_screen.dart';
import 'thesis_screen.dart';

class AcademicHubScreen extends StatefulWidget {
  final void Function(String url)? onOpenDeadlineUrl;
  final bool isEmbedded;

  const AcademicHubScreen({
    super.key,
    this.onOpenDeadlineUrl,
    this.isEmbedded = false,
  });

  @override
  State<AcademicHubScreen> createState() => _AcademicHubScreenState();
}

class _HubMenu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const _HubMenu(this.title, this.subtitle, this.icon, this.color, this.builder);
}

class _AcademicHubScreenState extends State<AcademicHubScreen> {
  List<_HubMenu> get _coreAcademicMenus => [
        _HubMenu(
          'Biodata',
          'Data diri & profil',
          Icons.badge_rounded,
          AppTheme.primaryBlue,
          (_) => const StudentProfileScreen(),
        ),
        _HubMenu(
          'KRS',
          'Rencana studi aktif',
          Icons.receipt_long_rounded,
          AppTheme.accentGold,
          (_) => const KrsScreen(),
        ),
        _HubMenu(
          'KHS',
          'Hasil studi & nilai',
          Icons.grade_rounded,
          AppTheme.primaryLight,
          (_) => const KhsScreen(),
        ),
        _HubMenu(
          'Transkrip',
          'Rangkuman & IPK',
          Icons.assessment_rounded,
          AppTheme.primaryBlue,
          (_) => const AcademicGradesScreen(),
        ),
        _HubMenu(
          'Jadwal & Tugas',
          'Jadwal kuliah & deadline',
          Icons.calendar_today_rounded,
          AppTheme.accentGold,
          (ctx) => ScheduleScreen(
            onOpenDeadlineUrl: (url) {
              Navigator.pop(ctx);
              if (widget.onOpenDeadlineUrl != null) {
                widget.onOpenDeadlineUrl!(url);
              }
            },
            onSyncSchedule: () =>
                ctx.read<ScheduleProvider>().syncScheduleWithPortal(forceRefresh: true),
            onSyncDeadline: () =>
                ctx.read<ScheduleProvider>().syncDeadlinesWithMentari(),
          ),
        ),
        _HubMenu(
          'Presensi',
          'Kehadiran per matkul',
          Icons.how_to_reg_rounded,
          AppTheme.primaryLight,
          (_) => const AttendanceScreen(),
        ),
      ];

  List<_HubMenu> get _administrationMenus => [
        _HubMenu(
          'Keuangan',
          'Tagihan & pembayaran',
          Icons.account_balance_wallet_rounded,
          AppTheme.accentGold,
          (_) => const FinanceScreen(),
        ),
        _HubMenu(
          'Dokumen',
          'Panduan & berkas resmi',
          Icons.folder_shared_rounded,
          AppTheme.primaryBlue,
          (_) => const AcademicDocumentsScreen(),
        ),
        _HubMenu(
          'Sertifikat',
          'Seminar & event',
          Icons.card_membership_rounded,
          AppTheme.primaryLight,
          (_) => const SeminarCertificateScreen(),
        ),
      ];

  List<_HubMenu> get _specialProgramMenus => [
        _HubMenu(
          'Tugas Akhir',
          'Skripsi & bimbingan',
          Icons.menu_book_rounded,
          AppTheme.primaryBlue,
          (_) => const ThesisScreen(),
        ),
        _HubMenu(
          'Proyek Kuliah',
          'Tugas besar & MBKM',
          Icons.assignment_turned_in_rounded,
          AppTheme.accentGold,
          (_) => const CourseProjectsScreen(),
        ),
        _HubMenu(
          'Pengajuan Izin',
          'Izin & absen jalan',
          Icons.event_busy_rounded,
          AppTheme.primaryLight,
          (_) => const AbsencePermitScreen(),
        ),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final portal = context.read<AcademicPortalProvider>();
      if (!portal.biodata.hasData && !portal.biodata.isLoading) {
        portal.fetchBiodata();
      }

      final finance = context.read<FinanceProvider>();
      if (finance.financeData == null && !finance.isLoading) {
        finance.fetchFinanceData();
      }

      final schedule = context.read<ScheduleProvider>();
      if (!schedule.hasSchedules && !schedule.isScheduleLoading) {
        schedule.syncScheduleWithPortal();
      }
    });
  }

  Future<void> _refresh() async {
    final portal = context.read<AcademicPortalProvider>();
    final finance = context.read<FinanceProvider>();
    final schedule = context.read<ScheduleProvider>();
    await Future.wait([
      portal.refreshAll(),
      finance.refresh(),
      schedule.syncScheduleWithPortal(forceRefresh: true),
    ]);
  }

  String _buildAiSummary() {
    final portal = context.read<AcademicPortalProvider>();
    final finance = context.read<FinanceProvider>();
    return [
      PortalAiText.biodata(portal.biodata.data),
      PortalAiText.krs(portal.krs.data),
      PortalAiText.khs(portal.khs.data),
      PortalAiText.grades(portal.grades.data),
      PortalAiText.schedule(portal.schedule.data),
      PortalAiText.finance(finance.financeData),
      PortalAiText.thesis(portal.thesis.data),
      PortalAiText.courseProjects(portal.courseProjects.data),
      PortalAiText.absencePermits(portal.absencePermits.data),
      PortalAiText.documents(portal.documents.data),
    ].where((part) => part.isNotEmpty).join('\n\n');
  }

  Widget _buildContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _buildStudentCard(),
        const SizedBox(height: 14),
        _buildSessionCard(),
        _buildFinancialSummaryCard(),
        _buildTodayClassesCard(),
        const SizedBox(height: 22),
        _buildSectionHeader('Akademik Perkuliahan', Icons.school_rounded),
        const SizedBox(height: 10),
        _buildMenuGrid(_coreAcademicMenus),
        const SizedBox(height: 22),
        _buildSectionHeader('Administrasi & Dokumen', Icons.business_center_rounded),
        const SizedBox(height: 10),
        _buildMenuGrid(_administrationMenus),
        const SizedBox(height: 22),
        _buildSectionHeader('Program & Bimbingan', Icons.auto_stories_rounded),
        const SizedBox(height: 10),
        _buildMenuGrid(_specialProgramMenus),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      final isLoading = context.watch<AcademicPortalProvider>().biodata.isLoading;
      return Container(
        color: AppTheme.bgGrey,
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppTheme.primaryBlue,
              backgroundColor: Colors.white,
              onRefresh: _refresh,
              child: _buildContent(),
            ),
            if (isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  color: AppTheme.accentGold,
                ),
              ),
          ],
        ),
      );
    }

    return PortalPageScaffold(
      title: 'MyUnpam',
      isLoading: context.watch<AcademicPortalProvider>().biodata.isLoading,
      onRefresh: _refresh,
      aiContext: PortalAiContext(
        pageTitle: 'MyUnpam',
        label: 'Data Akademik MyUnpam',
        buildPageText: _buildAiSummary,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(List<_HubMenu> menus) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: menus.map(_buildMenuTile).toList(),
    );
  }

  Widget _buildStudentCard() {
    final biodata = context.watch<AcademicPortalProvider>().biodata.data;
    final name = biodata?.namaMahasiswa ?? 'Mahasiswa UNPAM';
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
    final prodi = biodata?.programStudi?.namaProdi;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text(
                  initials.isEmpty ? 'UN' : initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      biodata == null
                          ? 'Hubungkan akun untuk memuat profil'
                          : 'NIM ${biodata.nim}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12.5,
                      ),
                    ),
                    if (prodi != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        prodi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (biodata?.ipkSemesterBerjalan != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        biodata!.ipkSemesterBerjalan!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'IPK',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (biodata != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStudentStatItem(
                    label: 'Semester',
                    value: biodata.semester != null ? 'Sem. ${biodata.semester}' : '-',
                    icon: Icons.calendar_today_rounded,
                  ),
                  Container(width: 1, height: 20, color: Colors.white24),
                  _buildStudentStatItem(
                    label: 'SKS Lulus',
                    value: biodata.sksSemesterBerjalan != null
                        ? '${biodata.sksSemesterBerjalan} SKS'
                        : '-',
                    icon: Icons.credit_score_rounded,
                  ),
                  Container(width: 1, height: 20, color: Colors.white24),
                  _buildStudentStatItem(
                    label: 'Status',
                    value: biodata.statusMahasiswa?.namaStatusMahasiswa ?? 'Aktif',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.accentGold),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionCard() {
    final session = context.watch<MyUnpamSession>();
    final (Color color, IconData icon, String title, String subtitle) = switch (session.status) {
      PortalSessionStatus.active => (
          AppTheme.successGreen,
          Icons.verified_user_rounded,
          'Sesi Terhubung',
          'Satu UNPAM & My UNPAM aktif',
        ),
      PortalSessionStatus.refreshing => (
          AppTheme.primaryLight,
          Icons.sync_rounded,
          'Menyegarkan Sesi',
          'Mengecek Satu UNPAM lalu My UNPAM...',
        ),
      PortalSessionStatus.expired => (
          AppTheme.dangerRed,
          Icons.lock_person_rounded,
          'Perlu Login Ulang',
          'Sesi Satu UNPAM & My UNPAM berakhir',
        ),
      PortalSessionStatus.unknown => (
          AppTheme.accentGold,
          Icons.cloud_sync_rounded,
          'Sesi Tersimpan',
          'Akan diperiksa otomatis saat memuat data',
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: session.isRefreshing ? null : () => reconnectPortal(context, _refresh),
            child: Text(session.needsLogin ? 'Hubungkan' : 'Hubungkan Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    final finance = context.watch<FinanceProvider>();
    final data = finance.financeData;
    if (data == null && !finance.isLoading) return const SizedBox.shrink();

    final isPaidOff = data != null && data.totalUnpaidAmount == 0;
    final remainingBill = data?.totalUnpaidAmount ?? 0;
    final color = isPaidOff ? AppTheme.successGreen : AppTheme.accentGold;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaidOff ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaidOff ? 'Keuangan SPP Lunas' : 'Tagihan Semester Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isPaidOff ? AppTheme.successGreen : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPaidOff
                      ? 'Tidak ada kewajiban pembayaran tertunda'
                      : 'Sisa: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(remainingBill)}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceScreen()),
            ),
            child: const Text('Rincian'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayClassesCard() {
    final schedule = context.watch<ScheduleProvider>();
    final today = schedule.todaySchedule;
    if (today.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 14),
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
            children: [
              const Icon(Icons.access_time_filled_rounded,
                  size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Kuliah Hari Ini (${today.length} Matkul)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ScheduleScreen(
                      onOpenDeadlineUrl: widget.onOpenDeadlineUrl,
                    ),
                  ),
                ),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...today.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isOnline
                            ? AppTheme.accentGold.withOpacity(0.15)
                            : AppTheme.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.jamMulai.isNotEmpty
                            ? item.jamMulai
                            : (item.isOnline ? 'Online' : 'TM'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: item.isOnline
                              ? AppTheme.accentGold
                              : AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.namaMataKuliah,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    if (item.ruang.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.ruang,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMenuTile(_HubMenu menu) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: menu.builder)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: menu.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(menu.icon, color: menu.color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    menu.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
