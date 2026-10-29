import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/schedule_service.dart';
import '../../../../theme/app_theme.dart';
import '../providers/schedule_provider.dart';
import '../../domain/models/schedule_model.dart';
import '../widgets/today_schedule_card.dart';
import '../widgets/weekly_schedule_view.dart';
import '../widgets/deadline_list_tile.dart';

/// Layar utama Jadwal Kuliah & Deadline Tracker.
///
/// Menampilkan tiga sub-tab: Hari Ini, Mingguan, dan Deadline.
/// Mendukung pemisahan dan filter matkul Tatap Muka vs Online secara jelas.
class ScheduleScreen extends StatefulWidget {
  /// Callback untuk membuka portal MyUnpam di tab jadwal kuliah.
  final VoidCallback? onOpenMyUnpamJadwal;

  /// Callback untuk membuka portal Mentari di tab deadline/tugas.
  final VoidCallback? onOpenMentariDeadline;

  /// Callback untuk membuka URL deadline langsung di portal Mentari The PAMs.
  final void Function(String url)? onOpenDeadlineUrl;

  /// Callback untuk memicu sinkronisasi jadwal dari MyUnpam secara langsung.
  final Future<void> Function()? onSyncSchedule;

  /// Callback untuk memicu sinkronisasi deadline dari Mentari secara langsung.
  final Future<void> Function()? onSyncDeadline;

  /// Tab awal yang aktif (0: Hari Ini, 1: Mingguan, 2: Deadline).
  final int initialTabIndex;

  const ScheduleScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onOpenMyUnpamJadwal,
    this.onOpenMentariDeadline,
    this.onOpenDeadlineUrl,
    this.onSyncSchedule,
    this.onSyncDeadline,
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
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );

    // Otomatis tarik jadwal secara native jika belum tersedia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ScheduleProvider>();
      if (!provider.hasSchedules) {
        provider.syncScheduleWithPortal();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _triggerActiveSync() async {
    final isDeadlineTab = _tabController.index == 2;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isDeadlineTab
            ? 'Menyinkronkan deadline dari Mentari LMS...'
            : 'Menyinkronkan jadwal kuliah dari My UNPAM...'),
        duration: const Duration(seconds: 2),
      ),
    );

    if (isDeadlineTab) {
      if (widget.onSyncDeadline != null) {
        await widget.onSyncDeadline!.call();
      } else if (mounted) {
        await context.read<ScheduleProvider>().syncDeadlinesWithMentari();
      }
    } else {
      if (widget.onSyncSchedule != null) {
        await widget.onSyncSchedule!.call();
      } else if (mounted) {
        await context.read<ScheduleProvider>().syncScheduleWithPortal(forceRefresh: true);
      }
    }
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
              'Tatap Muka & Online • Sinkron Otomatis',
              style: TextStyle(color: Colors.white60, fontSize: 10.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppTheme.accentGold, size: 22),
            tooltip: 'Sinkronkan data secara native',
            onPressed: _triggerActiveSync,
          ),
          Consumer<ScheduleProvider>(
            builder: (_, provider, __) {
              final lastSync = provider.lastScheduleSync;
              return Tooltip(
                message: lastSync != null
                    ? 'Terakhir sync: ${DateFormat('HH:mm, dd MMM', 'id_ID').format(lastSync)}\n\nTekan tombol sync atau tarik layar ke bawah untuk memperbarui.'
                    : 'Belum pernah sync.\nTekan tombol sync untuk sinkronisasi native.',
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
          _TodayTab(
            onOpenMyUnpam: widget.onOpenMyUnpamJadwal,
            onSyncSchedule: widget.onSyncSchedule,
          ),
          _WeeklyTab(
            onOpenMyUnpam: widget.onOpenMyUnpamJadwal,
            onSyncSchedule: widget.onSyncSchedule,
          ),
          _DeadlineTab(
            onOpenMentari: widget.onOpenMentariDeadline,
            onOpenDeadlineUrl: widget.onOpenDeadlineUrl,
            onSyncDeadline: widget.onSyncDeadline,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Hari Ini
// ─────────────────────────────────────────────────────────────────────────────

class _TodayTab extends StatefulWidget {
  final VoidCallback? onOpenMyUnpam;
  final Future<void> Function()? onSyncSchedule;

  const _TodayTab({this.onOpenMyUnpam, this.onSyncSchedule});

  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  String _selectedMode = 'Semua'; // 'Semua', 'Tatap Muka', 'Online'

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (_, provider, __) {
        final today = DateTime.now();
        final rawSchedule = provider.todaySchedule;
        final todaySchedule = rawSchedule.where((s) {
          if (_selectedMode == 'Tatap Muka') return s.isOffline;
          if (_selectedMode == 'Online') return s.isOnline;
          return true;
        }).toList();

        final countTm = rawSchedule.where((s) => s.isOffline).length;
        final countOl = rawSchedule.where((s) => s.isOnline).length;

        return RefreshIndicator(
          color: AppTheme.accentGold,
          backgroundColor: AppTheme.primaryBlue,
          onRefresh: () async {
            if (widget.onSyncSchedule != null) {
              await widget.onSyncSchedule!();
            } else {
              await provider.syncScheduleWithPortal(forceRefresh: true);
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              const SizedBox(height: 12),

              // Filter Mode Kuliah Hari Ini (Semua, Tatap Muka, Online) jika ada jadwal
              if (rawSchedule.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip('Semua (${rawSchedule.length})', 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tatap Muka ($countTm)', 'Tatap Muka'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Online ($countOl)', 'Online'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (provider.isScheduleLoading && !provider.hasSchedules)
                const _LoadingPlaceholder(message: 'Memuat jadwal kuliah...')
              else if (rawSchedule.isEmpty)
                _EmptyState(
                  icon: Icons.event_available_outlined,
                  title: provider.hasSchedules
                      ? 'Tidak ada kuliah hari ini'
                      : 'Jadwal belum tersedia',
                  subtitle: provider.hasSchedules
                      ? 'Nikmati hari liburmu! 🎉'
                      : 'Tarik ke bawah atau tekan tombol untuk sinkronisasi langsung dari My UNPAM.',
                  buttonLabel: provider.hasSchedules
                      ? null
                      : 'Sinkronkan Jadwal Sekarang',
                  buttonIcon: Icons.sync_rounded,
                  onButtonTap: () async {
                    if (widget.onSyncSchedule != null) {
                      await widget.onSyncSchedule!();
                    } else {
                      await provider.syncScheduleWithPortal(forceRefresh: true);
                    }
                  },
                )
              else if (todaySchedule.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Center(
                    child: Text(
                      'Tidak ada kuliah $_selectedMode untuk hari ini.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ),
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
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedMode == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : AppTheme.cardBorder,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
          ),
        ),
      ),
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
  final Future<void> Function()? onSyncSchedule;

  const _WeeklyTab({this.onOpenMyUnpam, this.onSyncSchedule});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (_, provider, __) {
        return RefreshIndicator(
          color: AppTheme.accentGold,
          backgroundColor: AppTheme.primaryBlue,
          onRefresh: () async {
            if (onSyncSchedule != null) {
              await onSyncSchedule!();
            } else {
              await provider.syncScheduleWithPortal(forceRefresh: true);
            }
          },
          child: Builder(
            builder: (context) {
              if (provider.isScheduleLoading && !provider.hasSchedules) {
                return const _LoadingPlaceholder(message: 'Memuat jadwal...');
              }

              if (!provider.hasSchedules) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    _EmptyState(
                      icon: Icons.calendar_today_outlined,
                      title: 'Jadwal belum tersedia',
                      subtitle:
                          'Tarik ke bawah atau tekan tombol untuk sinkronisasi jadwal kuliah langsung dari My UNPAM.',
                      buttonLabel: 'Sinkronkan Jadwal Sekarang',
                      buttonIcon: Icons.sync_rounded,
                      onButtonTap: () async {
                        if (onSyncSchedule != null) {
                          await onSyncSchedule!();
                        } else {
                          await provider.syncScheduleWithPortal(forceRefresh: true);
                        }
                      },
                    ),
                  ],
                );
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 14, bottom: 24),
                children: [
                  WeeklyScheduleView(weeklySchedule: provider.weeklySchedule),
                ],
              );
            },
          ),
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
  final void Function(String url)? onOpenDeadlineUrl;
  final Future<void> Function()? onSyncDeadline;

  const _DeadlineTab({
    this.onOpenMentari,
    this.onOpenDeadlineUrl,
    this.onSyncDeadline,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (_, provider, __) {
        return RefreshIndicator(
          color: AppTheme.accentGold,
          backgroundColor: AppTheme.primaryBlue,
          onRefresh: () async {
            if (onSyncDeadline != null) {
              await onSyncDeadline!();
            } else {
              await provider.syncDeadlinesWithMentari();
            }
          },
          child: Builder(
            builder: (context) {
              if (provider.isDeadlineLoading && !provider.hasDeadlines) {
                return const _LoadingPlaceholder(message: 'Memuat deadline...');
              }

              final upcoming = provider.upcomingDeadlines;
              final overdue = provider.overdueDeadlines;

              if (!provider.hasDeadlines) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    _EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'Deadline belum tersedia',
                      subtitle:
                          'Tarik ke bawah atau tekan tombol untuk sinkronisasi deadline tugas langsung dari Mentari LMS.',
                      buttonLabel: 'Sinkronkan Deadline Sekarang',
                      buttonIcon: Icons.sync_rounded,
                      onButtonTap: () async {
                        if (onSyncDeadline != null) {
                          await onSyncDeadline!();
                        } else {
                          await provider.syncDeadlinesWithMentari();
                        }
                      },
                    ),
                  ],
                );
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                        onTap: () => _openDeadline(context, d.url),
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
                        onTap: () => _openDeadline(context, d.url),
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
                            'Deadline disinkronkan langsung dari Mentari LMS.',
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
          ),
        );
      },
    );
  }

  void _openDeadline(BuildContext context, String url) async {
    final targetUrl = url.isNotEmpty ? url : 'https://mentari.unpam.ac.id/';
    if (onOpenDeadlineUrl != null) {
      onOpenDeadlineUrl!(targetUrl);
      return;
    }
    if (ScheduleService.globalDeadlineNavigator != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScheduleService.globalDeadlineNavigator!(targetUrl);
      return;
    }
    final uri = Uri.tryParse(targetUrl);
    if (uri != null && await canLaunchUrl(uri)) {
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
  final IconData buttonIcon;
  final VoidCallback? onButtonTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.buttonIcon = Icons.open_in_new_rounded,
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
                icon: Icon(buttonIcon, size: 16),
                label: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
