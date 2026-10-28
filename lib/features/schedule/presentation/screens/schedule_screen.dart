import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../providers/schedule_provider.dart';
import '../../domain/models/schedule_model.dart';
import '../widgets/today_schedule_card.dart';
import '../widgets/weekly_schedule_view.dart';
import '../widgets/deadline_list_tile.dart';

/// Layar utama Jadwal Kuliah & Deadline Tracker.
///
/// Menampilkan tiga sub-tab: Hari Ini, Mingguan, dan Deadline.
/// Data diisi secara otomatis oleh JS scraper di portal WebView dan
/// disimpan di cache lokal via SharedPreferences.
class ScheduleScreen extends StatefulWidget {
  /// Callback untuk membuka portal MyUnpam di tab jadwal kuliah.
  final VoidCallback? onOpenMyUnpamJadwal;

  /// Callback untuk membuka portal Mentari di tab deadline/tugas.
  final VoidCallback? onOpenMentariDeadline;

  const ScheduleScreen({
    super.key,
    this.onOpenMyUnpamJadwal,
    this.onOpenMentariDeadline,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 14),
          child: const Center(
            child: Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.accentGold,
              size: 22,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal & Deadline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Sinkron otomatis dari portal',
              style: TextStyle(color: Colors.white60, fontSize: 10.5),
            ),
          ],
        ),
        actions: [
          Consumer<ScheduleProvider>(
            builder: (_, provider, __) {
              final lastSync = provider.lastScheduleSync;
              return Tooltip(
                message: lastSync != null
                    ? 'Terakhir sync: ${DateFormat('HH:mm, dd MMM', 'id_ID').format(lastSync)}\n\nBuka halaman Jadwal Kuliah di MyUnpam untuk sync ulang.'
                    : 'Belum pernah sync.\nBuka halaman Jadwal di MyUnpam.',
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    lastSync != null
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: lastSync != null
                        ? AppTheme.successGreen
                        : Colors.white54,
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentGold,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Hari Ini'),
            Tab(text: 'Mingguan'),
            Tab(text: 'Deadline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTab(onOpenMyUnpam: widget.onOpenMyUnpamJadwal),
          _WeeklyTab(onOpenMyUnpam: widget.onOpenMyUnpamJadwal),
          _DeadlineTab(onOpenMentari: widget.onOpenMentariDeadline),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Hari Ini
// ─────────────────────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final VoidCallback? onOpenMyUnpam;
  const _TodayTab({this.onOpenMyUnpam});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (_, provider, __) {
        final today = DateTime.now();
        final todaySchedule = provider.todaySchedule;

        return ListView(
          padding: const EdgeInsets.only(top: 14, bottom: 24),
          children: [
            // Header tanggal hari ini
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(today),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (provider.isScheduleLoading)
              const _LoadingPlaceholder(message: 'Memuat jadwal...')
            else if (todaySchedule.isEmpty)
              _EmptyState(
                icon: Icons.event_available_outlined,
                title: provider.hasSchedules
                    ? 'Tidak ada kuliah hari ini'
                    : 'Jadwal belum tersedia',
                subtitle: provider.hasSchedules
                    ? 'Nikmati hari liburmu! 🎉'
                    : 'Buka halaman Jadwal Kuliah di MyUnpam untuk sinkronisasi otomatis.',
                buttonLabel:
                    provider.hasSchedules ? null : 'Buka Jadwal di MyUnpam',
                onButtonTap: onOpenMyUnpam,
              )
            else ...[
              // Upcoming deadlines banner (jika ada yang mendesak)
              _buildUpcomingDeadlineBanner(context),
              // Jadwal cards
              ...todaySchedule.map(
                (s) => TodayScheduleCard(
                  schedule: s,
                  isOngoing: _isOngoing(s),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  bool _isOngoing(CourseSchedule s) {
    try {
      final now = DateTime.now();
      final parts = s.jamMulai.split(':');
      final endParts = s.jamSelesai.split(':');
      if (parts.length < 2 || endParts.length < 2) return false;
      final start = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      final end = DateTime(now.year, now.month, now.day,
          int.parse(endParts[0]), int.parse(endParts[1]));
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  Widget _buildUpcomingDeadlineBanner(BuildContext context) {
    final provider = context.read<ScheduleProvider>();
    final urgent =
        provider.upcomingDeadlines.where((d) => d.daysUntilDue <= 1).toList();
    if (urgent.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.dangerRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              urgent.length == 1
                  ? '⚠️ Deadline "${urgent.first.namaTugas}" ${urgent.first.daysUntilDue == 0 ? "hari ini!" : "besok!"}'
                  : '⚠️ ${urgent.length} deadline mendesak dalam 1 hari ke depan!',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.dangerRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Mingguan
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyTab extends StatelessWidget {
  final VoidCallback? onOpenMyUnpam;
  const _WeeklyTab({this.onOpenMyUnpam});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (_, provider, __) {
        if (provider.isScheduleLoading) {
          return const _LoadingPlaceholder(message: 'Memuat jadwal...');
        }

        if (!provider.hasSchedules) {
          return _EmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Jadwal belum tersedia',
            subtitle:
                'Buka halaman Jadwal Kuliah di MyUnpam untuk sinkronisasi jadwal secara otomatis.',
            buttonLabel: 'Buka Jadwal di MyUnpam',
            onButtonTap: onOpenMyUnpam,
          );
        }

        return ListView(
          padding: const EdgeInsets.only(top: 14, bottom: 24),
          children: [
            WeeklyScheduleView(weeklySchedule: provider.weeklySchedule),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Deadline
// ─────────────────────────────────────────────────────────────────────────────

class _DeadlineTab extends StatelessWidget {
  final VoidCallback? onOpenMentari;
  const _DeadlineTab({this.onOpenMentari});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (_, provider, __) {
        if (provider.isDeadlineLoading) {
          return const _LoadingPlaceholder(message: 'Memuat deadline...');
        }

        final upcoming = provider.upcomingDeadlines;
        final overdue = provider.overdueDeadlines;

        if (!provider.hasDeadlines) {
          return _EmptyState(
            icon: Icons.assignment_outlined,
            title: 'Deadline belum tersedia',
            subtitle:
                'Buka Mentari LMS dan navigasikan ke dashboard atau daftar tugas untuk sinkronisasi otomatis.',
            buttonLabel: 'Buka Mentari LMS',
            onButtonTap: onOpenMentari,
          );
        }

        return ListView(
          padding: const EdgeInsets.only(top: 14, bottom: 24),
          children: [
            if (upcoming.isNotEmpty) ...[
              _SectionHeader(
                title: 'Akan Datang (${upcoming.length})',
                icon: Icons.pending_actions_outlined,
                color: AppTheme.primaryBlue,
              ),
              ...upcoming.map(
                (d) => DeadlineListTile(
                  deadline: d,
                  onTap: d.url.isNotEmpty ? () => _openUrl(d.url) : null,
                ),
              ),
            ],
            if (overdue.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SectionHeader(
                title: 'Terlewat (${overdue.length})',
                icon: Icons.assignment_late_outlined,
                color: Colors.grey.shade500,
              ),
              ...overdue.map(
                (d) => DeadlineListTile(
                  deadline: d,
                  onTap: d.url.isNotEmpty ? () => _openUrl(d.url) : null,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Sync hint
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      size: 13, color: AppTheme.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Deadline diambil dari dashboard Mentari LMS. Buka Mentari untuk memperbarui.',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final String message;
  const _LoadingPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 42, color: AppTheme.primaryBlue.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onButtonTap,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
