import 'package:c360/core/di/core_providers.dart';
import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/core/utils/formatters.dart';
import 'package:c360/core/widgets/empty_state.dart';
import 'package:c360/core/widgets/inline_alert.dart';
import 'package:c360/core/widgets/screen_header.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/rules/attendance_rules.dart';
import 'package:c360/features/attendance/presentation/providers/history_notifier.dart';
import 'package:c360/features/attendance/presentation/providers/records_providers.dart';
import 'package:c360/features/attendance/presentation/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final history = ref.watch(historyProvider);
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider)();
    final today = dayOf(now);
    final from = DateTime(today.year, today.month, today.day - (ref.watch(configProvider).historyDays - 1));
    final records = ref.watch(attendanceProvider).where((r) => !r.capturedAt.isBefore(from)).toList();
    final days = groupByDay(records, now);
    final error = history.value?.error;
    Future<void> refresh() => ref.read(historyProvider.notifier).refresh();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              const ScreenHeader(title: 'History', subtitle: 'Your check-ins and check-outs for the last two weeks.'),
              const SizedBox(height: 16),
              if (error != null && days.isNotEmpty) ...[
                InlineAlert(message: error, warning: true),
                const SizedBox(height: 12),
              ],
              if (history.isLoading && days.isEmpty)
                const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
              else if (days.isEmpty && error != null)
                EmptyState(
                  title: 'Couldn’t load history',
                  message: error,
                  action: OutlinedButton(onPressed: refresh, child: const Text('Try again')),
                )
              else if (days.isEmpty)
                const EmptyState(message: 'No attendance yet. Your first check-in will appear here.')
              else
                for (final day in days)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(formatDay(day.day), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                if (day.worked > Duration.zero)
                                  Text(
                                    formatDuration(day.worked),
                                    style: TextStyle(fontSize: 13, color: p.mutedForeground),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            for (final record in recordsOn(records, day.day))
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        record.type == AttendanceType.checkIn ? 'In' : 'Out',
                                        style: TextStyle(fontSize: 13, color: p.mutedForeground),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        formatHm(record.capturedAt),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    StatusChip(status: record.status),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
