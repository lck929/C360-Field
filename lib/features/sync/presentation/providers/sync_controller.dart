import 'dart:async';

import 'package:c360/core/di/core_providers.dart';
import 'package:c360/features/attendance/presentation/providers/history_notifier.dart';
import 'package:c360/features/attendance/presentation/providers/records_providers.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:c360/features/auth/presentation/providers/auth_state.dart';
import 'package:c360/features/sync/di/sync_providers.dart';
import 'package:c360/features/sync/domain/entities/sync_report.dart';
import 'package:c360/features/sync/presentation/providers/sync_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncController extends Notifier<SyncState> {
  static const _lastSyncedKey = 'lastSyncedAt';

  Timer? _timer;

  @override
  SyncState build() {
    ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
      if (previous?.value == false && next.value == true) {
        if (ref.read(queuedRecordsProvider).isNotEmpty) {
          state = state.copyWith(notice: 'Back online. Syncing waiting records…');
        }
        unawaited(sync(force: true));
      }
    });
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is SignedIn && previous is! SignedIn) unawaited(sync());
    });
    ref.onDispose(() => _timer?.cancel());
    Future.microtask(_start);
    return const SyncState();
  }

  Future<void> _start() async {
    final saved = DateTime.tryParse(await ref.read(preferencesProvider).get(_lastSyncedKey) ?? '');
    if (!ref.mounted) return;
    if (saved != null) state = state.copyWith(lastSyncedAt: saved.toLocal());

    final engine = ref.read(syncEngineProvider);
    await engine.recoverInterrupted();
    await engine.prune(olderThan: Duration(days: ref.read(configProvider).historyDays));
    if (ref.mounted) await sync();
  }

  Future<void> sync({bool force = false, bool silent = false}) async {
    final auth = ref.read(authProvider);
    if (auth is! SignedIn) return;

    state = state.copyWith(syncing: true);
    final report = await ref.read(syncEngineProvider).run(employeeId: auth.employee.employeeId, force: force);
    if (!ref.mounted) return;

    _scheduleRetry(report.retryAt);
    if (report.stop == SyncStop.unauthorized) unawaited(ref.read(authProvider.notifier).expireSession());

    final count = report.processed;
    final now = ref.read(clockProvider)();
    if (count > 0) {
      await ref.read(preferencesProvider).put(_lastSyncedKey, now.toUtc().toIso8601String());
      ref.invalidate(historyProvider);
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      syncing: false,
      lastSyncedAt: count > 0 ? now : null,
      notice: count > 0 && !silent ? 'Synced $count ${count == 1 ? 'record' : 'records'}' : null,
    );
  }

  void _scheduleRetry(DateTime? retryAt) {
    _timer?.cancel();
    if (retryAt == null) return;
    final delay = retryAt.difference(ref.read(clockProvider)());
    _timer = Timer(delay < const Duration(seconds: 1) ? const Duration(seconds: 1) : delay, () => sync());
  }
}

final syncProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);
