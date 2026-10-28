import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/schedule_model.dart';

const List<String> _dayNames = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];

/// Tampilan jadwal kuliah mingguan per hari.
class WeeklyScheduleView extends StatefulWidget {
  final Map<int, List<CourseSchedule>> weeklySchedule;

  const WeeklyScheduleView({super.key, required this.weeklySchedule});

  @override
  State<WeeklyScheduleView> createState() => _WeeklyScheduleViewState();
}

class _WeeklyScheduleViewState extends State<WeeklyScheduleView> {
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    // Default ke hari ini, atau hari pertama yang ada jadwalnya
    final today = DateTime.now().weekday;
    if (widget.weeklySchedule.containsKey(today)) {
      _selectedDay = today;
    } else {
      _selectedDay = widget.weeklySchedule.isNotEmpty
          ? widget.weeklySchedule.keys.first
          : today;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleForDay = widget.weeklySchedule[_selectedDay] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Selector
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 7,
            itemBuilder: (context, i) {
              final dayIndex = i + 1; // 1=Senin, 7=Minggu
              final hasSchedule =
                  widget.weeklySchedule.containsKey(dayIndex) &&
                      widget.weeklySchedule[dayIndex]!.isNotEmpty;
              final isSelected = _selectedDay == dayIndex;
              final isToday = DateTime.now().weekday == dayIndex;

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = dayIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday && !isSelected
                          ? AppTheme.primaryLight.withOpacity(0.5)
                          : isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _dayNames[i].substring(0, 3),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textDark,
                        ),
                      ),
                      if (hasSchedule) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.8)
                                : AppTheme.accentGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Schedule list untuk hari yang dipilih
        if (scheduleForDay.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_available_outlined,
                      size: 36, color: AppTheme.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada kuliah pada hari ${_dayNames[_selectedDay - 1]}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...scheduleForDay.map((s) => _WeeklyScheduleItem(schedule: s)),
      ],
    );
  }
}

class _WeeklyScheduleItem extends StatelessWidget {
  final CourseSchedule schedule;

  const _WeeklyScheduleItem({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.namaMataKuliah,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${schedule.jamMulai} – ${schedule.jamSelesai}'
                  '${schedule.ruang.isNotEmpty ? ' · ${schedule.ruang}' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            schedule.kode,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

