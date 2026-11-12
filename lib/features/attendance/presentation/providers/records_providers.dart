import 'package:c360/features/attendance/di/attendance_providers.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/rules/attendance_rules.dart';
import 'package:c360/features/attendance/presentation/providers/history_notifier.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localRecordsProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final employeeId = ref.watch(employeeProvider.select((e) => e?.employeeId));
  if (employeeId == null) return Stream.value(const []);
  return ref.watch(watchRecordsProvider)(employeeId);
});

final queuedRecordsProvider = Provider<List<AttendanceRecord>>((ref) {
  final records = ref.watch(localRecordsProvider).value ?? const [];
  return records.where((r) => r.isQueued).toList()..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
});

final attendanceProvider = Provider<List<AttendanceRecord>>((ref) {
  final server = ref.watch(historyProvider).value?.records ?? ref.watch(cachedHistoryProvider).value ?? const [];
  return mergeHistory(server, ref.watch(localRecordsProvider).value ?? const []);
});
