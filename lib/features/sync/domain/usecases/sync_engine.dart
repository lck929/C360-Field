import 'package:c360/core/error/app_exception.dart';
import 'package:c360/core/network/connectivity_service.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:c360/features/sync/domain/entities/sync_report.dart';
import 'package:c360/features/sync/domain/policies/backoff_policy.dart';

class SyncEngine {
  SyncEngine({
    required this.repository,
    required this.connectivity,
    required this.backoff,
    required this.clock,
  });

  final AttendanceRepository repository;
  final ConnectivityService connectivity;
  final BackoffPolicy backoff;
  final DateTime Function() clock;

  Future<SyncReport>? _running;
  bool _rerun = false;
  bool _rerunForced = false;

  Future<void> recoverInterrupted() async {
    for (final record in (await repository.records()).where((r) => r.status == SyncStatus.syncing)) {
      await repository.saveRecord(record.copyWith(status: SyncStatus.pending));
    }
  }

  Future<void> prune({required Duration olderThan}) async {
    final cutoff = clock().subtract(olderThan);
    for (final record in (await repository.records()).where((r) => !r.isQueued && r.capturedAt.isBefore(cutoff))) {
      await repository.deleteRecord(record);
    }
  }

  Future<SyncReport> run({required String employeeId, bool force = false}) {
    final running = _running;
    if (running != null) {
      _rerun = true;
      _rerunForced = _rerunForced || force;
      return running;
    }
    return _running = _loop(employeeId, force).whenComplete(() => _running = null);
  }

  Future<SyncReport> _loop(String employeeId, bool force) async {
    var report = await _drain(employeeId, force);
    while (_rerun && report.stop != SyncStop.unauthorized) {
      final forced = _rerunForced;
      _rerun = false;
      _rerunForced = false;
      report = report.then(await _drain(employeeId, forced));
    }
    _rerun = false;
    _rerunForced = false;
    return report;
  }

  Future<SyncReport> _drain(String employeeId, bool force) async {
    var verified = 0;
    var rejected = 0;

    while (true) {
      final pending = (await repository.records())
          .where((r) => r.employeeId == employeeId && r.status == SyncStatus.pending)
          .toList()
        ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
      if (pending.isEmpty) return SyncReport(verified: verified, rejected: rejected);
      final next = pending.first;

      final dueAt = next.nextAttemptAt;
      if (!force && dueAt != null && dueAt.isAfter(clock())) {
        return SyncReport(verified: verified, rejected: rejected, stop: SyncStop.waiting, retryAt: dueAt);
      }
      if (!await connectivity.isOnline()) {
        return SyncReport(verified: verified, rejected: rejected, stop: SyncStop.offline);
      }

      await repository.saveRecord(next.copyWith(status: SyncStatus.syncing));

      try {
        final serverId = await repository.submit(next);
        await repository.saveRecord(next.copyWith(status: SyncStatus.verified, serverId: serverId, clearRetry: true));
        await repository.deleteSelfie(next);
        verified++;
      } on AppException catch (e) {
        if (e.type == FailureType.unauthorized) {
          await repository.saveRecord(next.copyWith(status: SyncStatus.pending));
          return SyncReport(verified: verified, rejected: rejected, stop: SyncStop.unauthorized);
        }
        if (e.isRetryable) {
          final retryAt = await _retryLater(next, e.message);
          return SyncReport(verified: verified, rejected: rejected, stop: SyncStop.waiting, retryAt: retryAt);
        }
        await repository.saveRecord(
          next.copyWith(status: SyncStatus.rejected, error: e.message, errorCode: e.code, clearRetry: true),
        );
        await repository.deleteSelfie(next);
        rejected++;
      } catch (_) {
        final retryAt = await _retryLater(next, 'Unexpected error');
        return SyncReport(verified: verified, rejected: rejected, stop: SyncStop.waiting, retryAt: retryAt);
      }
    }
  }

  Future<DateTime> _retryLater(AttendanceRecord record, String message) async {
    final attempts = record.attempts + 1;
    final retryAt = clock().add(backoff.delayFor(attempts));
    await repository.saveRecord(
      record.copyWith(status: SyncStatus.pending, attempts: attempts, nextAttemptAt: retryAt, error: message),
    );
    return retryAt;
  }
}
