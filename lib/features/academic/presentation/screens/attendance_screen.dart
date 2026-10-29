import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/attendance_model.dart';
import '../providers/academic_portal_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../widgets/portal_state_views.dart';
import '../widgets/portal_ai_assist.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _expandedCourseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AcademicPortalProvider>();
      if (!provider.attendance.hasData) {
        provider.fetchAttendanceCourses();
      }
    });
  }

  void _toggleCourseDetail(AttendanceCourseItem course) {
    setState(() {
      if (_expandedCourseId == course.idMataKuliah) {
        _expandedCourseId = null;
      } else {
        _expandedCourseId = course.idMataKuliah;
      }
    });

    if (_expandedCourseId == course.idMataKuliah) {
      final provider = context.read<AcademicPortalProvider>();
      provider.fetchAttendanceMeetings(
        idKelas: course.idKelas,
        idMatakuliah: course.idMataKuliah,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final resource = provider.attendance;

    return PortalPageScaffold(
      title: 'Presensi Perkuliahan',
      isLoading: resource.isLoading,
      onRefresh: () => provider.fetchAttendanceCourses(forceRefresh: true),
      body: _buildBody(provider, resource),
      aiContext: PortalAiContext(
        pageTitle: 'Presensi Perkuliahan',
        label: 'Presensi',
        buildPageText: () => PortalAiText.attendance(
          provider.attendance.data,
          (c) => provider.meetings(c.idKelas, c.idMataKuliah).data,
        ),
      ),
    );
  }

  Widget _buildBody(AcademicPortalProvider provider, PortalResource<List<AttendanceCourseItem>> resource) {
    final courses = resource.data;
    Future<void> retry() => provider.fetchAttendanceCourses(forceRefresh: true);

    if (courses == null) {
      if (resource.isLoading) {
        return const PortalLoadingView(message: 'Memuat daftar presensi...');
      }
      return PortalErrorView(
        icon: Icons.event_busy_rounded,
        title: 'Gagal Memuat Presensi',
        message: resource.error,
        onRetry: retry,
      );
    }


    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (resource.error != null)
          PortalSyncBanner(message: resource.error!, onRetry: retry),
        _buildHeaderBanner(courses),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mata Kuliah Semester Ini (${courses.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (courses.isEmpty)
          _buildEmptyCourses()
        else
          ...courses.map((course) => _buildCourseAttendanceTile(provider, course)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeaderBanner(List<AttendanceCourseItem> courses) {
    final semesterName = courses.isNotEmpty
        ? courses.first.namaSemesterRegistrasi
        : 'Semester Berjalan';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rekap Presensi Kuliah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  semesterName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseAttendanceTile(
    AcademicPortalProvider provider,
    AttendanceCourseItem course,
  ) {
    final isExpanded = _expandedCourseId == course.idMataKuliah;
    final meetingResource = provider.meetings(course.idKelas, course.idMataKuliah);
    final meetings = meetingResource.data;
    final isLoadingMeetings = meetingResource.isLoading;
    final errorMeetings = meetingResource.error;

    AttendanceSummary? summary;
    if (meetings != null) {
      summary = AttendanceSummary(meetings);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? AppTheme.primaryBlue.withOpacity(0.4) : AppTheme.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleCourseDetail(course),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: AppTheme.primaryBlue,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.namaMataKuliah,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              course.idMataKuliah,
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
                              '${course.sks} SKS',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
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
                              'Kelas: ${course.idKelas}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        if (summary != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: summary.recorded == 0
                                        ? 1.0
                                        : (summary.attended / summary.recorded)
                                            .clamp(0.0, 1.0),
                                    backgroundColor: AppTheme.cardBorder,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      summary.percentage >= 75
                                          ? AppTheme.successGreen
                                          : AppTheme.accentGold,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${summary.attended}/${summary.recorded} Hadir (${summary.percentage.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: summary.percentage >= 75
                                      ? AppTheme.successGreen
                                      : AppTheme.accentGold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            const Divider(height: 1),
            if (isLoadingMeetings)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Memuat riwayat pertemuan...',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else if (errorMeetings != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  errorMeetings,
                  style: const TextStyle(fontSize: 12, color: AppTheme.dangerRed),
                ),
              )
            else if (meetings != null)
              _buildMeetingList(meetings),
          ],
        ],
      ),
    );
  }

  Widget _buildMeetingList(List<AttendanceMeetingItem> meetings) {
    if (meetings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Belum ada data pertemuan untuk mata kuliah ini.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      );
    }

    return Container(
      color: AppTheme.bgGrey,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rincian Pertemuan',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                'Total: ${meetings.length} Pertemuan',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...meetings.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final m = entry.value;
            return _buildMeetingRow(idx, m);
          }),
        ],
      ),
    );
  }

  Widget _buildMeetingRow(int meetingNumber, AttendanceMeetingItem m) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (m.isAttended) {
      statusColor = AppTheme.successGreen;
      statusText = 'Hadir';
      statusIcon = Icons.check_circle_rounded;
    } else if (m.isAbsent) {
      statusColor = AppTheme.dangerRed;
      statusText = 'Absen';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = AppTheme.textMuted;
      statusText = 'Mendatang';
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$meetingNumber',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.formattedDateRange,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (m.jenisPerkuliahan != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: m.isOnline
                              ? AppTheme.accentGoldLight
                              : AppTheme.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          m.jenisPerkuliahan!,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: m.isOnline
                                ? AppTheme.accentGold
                                : AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  m.ketJam != null && m.ketJam!.isNotEmpty
                      ? 'Jam: ${m.ketJam}'
                      : 'Waktu belum ditentukan',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                if (m.isRecorded) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Presensi: ${m.formattedPresensiTime} (${m.presensiBy ?? 'Sistem'})',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCourses() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.event_note_outlined,
                size: 52, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'Belum ada daftar mata kuliah presensi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Daftar presensi akan tampil setelah semester aktif dimulai',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
