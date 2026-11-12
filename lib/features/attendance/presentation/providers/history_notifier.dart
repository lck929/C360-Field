import 'package:c360/core/di/core_providers.dart';
import 'package:c360/core/error/app_exception.dart';
import 'package:c360/features/attendance/di/attendance_providers.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryView {
  const HistoryView({this.records = const [], this.error});

  final List<AttendanceRecord> records;
  final String? error;
}

final _employeeIdProvider = Provider<String?>((ref) => ref.watch(employeeProvider.select((e) => e?.employeeId)));

class HistoryNotifier extends AsyncNotifier<HistoryView> {
  @override
  Future<HistoryView> build() async {
    final employeeId = ref.watch(_employeeIdProvider);
    if (employeeId == null) return const HistoryView();

    final result = await ref.read(loadHistoryProvider)(employeeId, days: ref.read(configProvider).historyDays);
    final failure = result.failure;
    if (failure == null) return HistoryView(records: result.records);

    if (failure.type == FailureType.unauthorized) {
      Future.microtask(() => ref.read(authProvider.notifier).expireSession());
    }
    return HistoryView(
      records: result.records,
      error: failure.type == FailureType.network
          ? 'You’re offline. Showing what’s saved on this phone.'
          : 'Couldn’t refresh from the server. Showing what’s saved on this phone.',
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final historyProvider = AsyncNotifierProvider<HistoryNotifier, HistoryView>(HistoryNotifier.new);

final cachedHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final employeeId = ref.watch(_employeeIdProvider);
  if (employeeId == null) return const [];
  return ref.read(getCachedHistoryProvider)(employeeId);
});
