import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/core/utils/formatters.dart';
import 'package:c360/features/attendance/domain/entities/day_summary.dart';
import 'package:flutter/material.dart';

class WeekChart extends StatelessWidget {
  const WeekChart({super.key, required this.days, required this.today});

  final List<DaySummary> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final day in days)
          Expanded(
            child: Semantics(
              label: '${formatDay(day.day)}: ${formatDuration(day.worked)}',
              excludeSemantics: true,
              child: Column(
                children: [
                  Text(
                    day.worked == Duration.zero ? '–' : (day.worked.inMinutes / 60).toStringAsFixed(1),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 26,
                    height: 70,
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: p.secondary, borderRadius: BorderRadius.circular(6)),
                    child: FractionallySizedBox(
                      heightFactor: (day.worked.inMinutes / 720).clamp(0.0, 1.0),
                      widthFactor: 1,
                      child: const ColoredBox(color: Brand.gold),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatWeekday(day.day),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: day.day == today ? p.accentForeground : p.mutedForeground,
                      fontWeight: day.day == today ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
