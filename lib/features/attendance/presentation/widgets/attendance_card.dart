import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/core/utils/formatters.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/entities/day_summary.dart';
import 'package:flutter/material.dart';

class AttendanceCard extends StatelessWidget {
  const AttendanceCard({super.key, required this.today, required this.now, required this.onAction});

  final DaySummary today;
  final DateTime now;
  final ValueChanged<AttendanceType> onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final checkIn = today.checkIn;
    final (label, time, subtitle) = switch (today.phase) {
      TodayPhase.notCheckedIn => ('Not checked in', formatHm(now), 'Connect to the site Wi-Fi, then check in.'),
      TodayPhase.checkedIn => (
          'Checked in at',
          formatHm(checkIn!.capturedAt),
          'On site for ${formatDuration(today.worked)}${checkIn.isQueued ? '. Waiting to sync.' : '.'}',
        ),
      TodayPhase.checkedOut => (
          'Checked out at',
          formatHm(today.checkOut!.capturedAt),
          'Shift complete. ${formatDuration(today.worked)} on site today.',
        ),
    };
    final action = today.nextAction;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(20),
        border: const Border(top: BorderSide(color: Brand.gold, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Brand.panelLabel)),
          const SizedBox(height: 8),
          Text(time, style: serif(size: 58, weight: FontWeight.w500, color: Brand.gold, height: 1)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 13.5, color: p.panelForeground)),
          if (action != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('attendanceAction'),
              style: FilledButton.styleFrom(foregroundColor: Palette.dark.background),
              onPressed: () => onAction(action),
              child: Text(action.label),
            ),
          ],
        ],
      ),
    );
  }
}
