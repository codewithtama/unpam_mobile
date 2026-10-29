import '../../../schedule/presentation/screens/schedule_screen.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/my_unpam_session.dart';
import '../../data/portal_ai_text.dart';
import '../providers/academic_portal_provider.dart';
import '../providers/finance_provider.dart';
import '../../../../theme/app_theme.dart';
import '../widgets/portal_ai_assist.dart';
import '../widgets/portal_state_views.dart';
import 'academic_grades_screen.dart';
import 'attendance_screen.dart';
import 'finance_screen.dart';
import 'seminar_certificate_screen.dart';
import 'student_profile_screen.dart';

class AcademicHubScreen extends StatefulWidget {
  final void Function(String url)? onOpenDeadlineUrl;

  const AcademicHubScreen({super.key, this.onOpenDeadlineUrl});

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
  List<_HubMenu> get _menus => [
    _HubMenu('Biodata', 'Data diri & akademik', Icons.badge_rounded, AppTheme.primaryBlue,
        (_) => const StudentProfileScreen()),
    _HubMenu('Keuangan', 'Tagihan & pembayaran', Icons.account_balance_wallet_rounded,
        AppTheme.accentGold, (_) => const FinanceScreen()),
    _HubMenu('Nilai', 'Rangkuman & IPK', Icons.assessment_rounded, AppTheme.primaryLight,
        (_) => const AcademicGradesScreen()),
    _HubMenu('Jadwal & Deadline', 'Jadwal kuliah & tugas', Icons.calendar_today_rounded, AppTheme.primaryBlue,
        (ctx) => ScheduleScreen(
          onOpenDeadlineUrl: (url) {
            Navigator.pop(ctx);
            if (widget.onOpenDeadlineUrl != null) {
              widget.onOpenDeadlineUrl!(url);
            }
          },
          onSyncSchedule: () => ctx.read<ScheduleProvider>().syncScheduleWithPortal(forceRefresh: true),
          onSyncDeadline: () => ctx.read<ScheduleProvider>().syncDeadlinesWithMentari(),
        )),
    _HubMenu('Presensi', 'Kehadiran per matkul', Icons.how_to_reg_rounded, AppTheme.accentGold,
        (_) => const AttendanceScreen()),
    _HubMenu('Sertifikat', 'Seminar & kegiatan', Icons.card_membership_rounded, AppTheme.primaryLight,
        (_) => const SeminarCertificateScreen()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final portal = context.read<AcademicPortalProvider>();
      if (!portal.biodata.hasData) portal.fetchBiodata();
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
      PortalAiText.grades(portal.grades.data),
      PortalAiText.schedule(portal.schedule.data),
      PortalAiText.finance(finance.financeData),
    ].where((part) => part.isNotEmpty).join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    return PortalPageScaffold(
      title: 'Akademik',
      isLoading: context.watch<AcademicPortalProvider>().biodata.isLoading,
      onRefresh: _refresh,
      aiContext: PortalAiContext(
        pageTitle: 'Akademik',
        label: 'Data Akademik',
        buildPageText: _buildAiSummary,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildStudentCard(),
          const SizedBox(height: 14),
          _buildSessionCard(),
          const SizedBox(height: 20),
          const Text(
            'Layanan My UNPAM',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: _menus.map(_buildMenuTile).toList(),
          ),
        ],
      ),
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
      child: Row(
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
                  biodata == null ? 'Hubungkan akun untuk memuat profil' : 'NIM ${biodata.nim}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5),
                ),
                if (prodi != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    prodi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (biodata?.ipkSemesterBerjalan != null)
            Column(
              children: [
                Text(
                  biodata!.ipkSemesterBerjalan!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'IPK',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
        ],
      ),
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
