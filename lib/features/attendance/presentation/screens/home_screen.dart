import 'package:c360/core/di/core_providers.dart';
import 'package:c360/core/routing/routes.dart';
import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/core/utils/formatters.dart';
import 'package:c360/core/widgets/avatar.dart';
import 'package:c360/features/attendance/domain/rules/attendance_rules.dart';
import 'package:c360/features/attendance/presentation/providers/history_notifier.dart';
import 'package:c360/features/attendance/presentation/providers/records_providers.dart';
import 'package:c360/features/attendance/presentation/widgets/attendance_card.dart';
import 'package:c360/features/attendance/presentation/widgets/pending_banner.dart';
import 'package:c360/features/attendance/presentation/widgets/week_chart.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(employeeProvider);
    if (employee == null) return const SizedBox.shrink();

    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider)();
    final records = ref.watch(attendanceProvider);
    final pending = ref.watch(queuedRecordsProvider).length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(historyProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${greetingFor(now)},', style: TextStyle(color: p.mutedForeground)),
                        Text(employee.firstName, style: Theme.of(context).textTheme.headlineLarge),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Profile',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.go(Routes.profile),
                      child: Avatar(initials: employee.initials),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Brand.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(employee.projectName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        Text('Shift ${employee.shiftLabel}', style: TextStyle(fontSize: 13.5, color: p.mutedForeground)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AttendanceCard(
                today: summarizeDay(records, now, now),
                now: now,
                onAction: (type) => context.push(Routes.check(type)),
              ),
              if (pending > 0) ...[
                const SizedBox(height: 12),
                PendingBanner(count: pending, onTap: () => context.go(Routes.sync)),
              ],
              const SizedBox(height: 26),
              Text('This week', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              WeekChart(days: lastDays(records, now), today: dayOf(now)),
            ],
          ),
        ),
      ),
    );
  }
}
