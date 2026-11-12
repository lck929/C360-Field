import 'package:c360/core/error/app_exception.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/usecases/capture_attendance.dart';
import 'package:c360/features/attendance/domain/usecases/load_history.dart';
import 'package:c360/features/attendance/domain/usecases/refresh_history.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  late FakeAttendanceRepository repository;
  final now = DateTime(2026, 11, 10, 7, 5);

  setUp(() => repository = FakeAttendanceRepository());

  test('capturing saves a pending record with a new clientId, the BSSID and the photo', () async {
    final capture = CaptureAttendance(repository: repository, clock: () => now, newId: () => 'uuid-1');

    final record = await capture(
      employeeId: 'SCL10234',
      type: AttendanceType.checkIn,
      photoPath: '/tmp/photo.jpg',
      bssid: '3c:84:6a:1f:22:b0',
    );

    expect(record.clientId, 'uuid-1');
    expect(record.status, SyncStatus.pending);
    expect(record.capturedAt, now);
    expect(record.selfie, 'uuid-1.jpg');
    expect(repository.stored['uuid-1']!.bssid, '3c:84:6a:1f:22:b0');
  });

  test('loading history returns server records when online', () async {
    repository.serverHistory = [testRecord('ATT-1', status: SyncStatus.verified)];

    final result = await LoadHistory(repository: repository, clock: () => now)('SCL10234', days: 14);

    expect(result.records.single.clientId, 'ATT-1');
    expect(result.failure, isNull);
  });

  test('loading history falls back to the cache and reports the failure when offline', () async {
    repository
      ..historyFailure = const AppException.network()
      ..cache.add(testRecord('cached', status: SyncStatus.verified));

    final result = await LoadHistory(repository: repository, clock: () => now)('SCL10234', days: 14);

    expect(result.records.single.clientId, 'cached');
    expect(result.failure?.type, FailureType.network);
  });

  test('refreshing history removes verified records the server no longer has', () async {
    repository
      ..stored['kept'] = testRecord('kept', serverId: 'ATT-1', status: SyncStatus.verified)
      ..stored['deleted'] = testRecord('deleted', serverId: 'ATT-2', status: SyncStatus.verified, hour: 17)
      ..stored['waiting'] = testRecord('waiting', hour: 18)
      ..stored['old'] = testRecord('old', serverId: 'ATT-3', status: SyncStatus.verified, at: DateTime(2026, 10, 1, 7))
      ..serverHistory = [testRecord('ATT-1', serverId: 'ATT-1', status: SyncStatus.verified)];

    final records = await RefreshHistory(repository)('SCL10234', DateTime(2026, 10, 28), DateTime(2026, 11, 10));

    expect(records.single.serverId, 'ATT-1');
    expect(repository.stored.keys, unorderedEquals(['kept', 'waiting', 'old']));
  });

  test('a failed refresh leaves the local records alone', () async {
    repository
      ..stored['verified'] = testRecord('verified', serverId: 'ATT-9', status: SyncStatus.verified)
      ..historyFailure = const AppException.network();

    await LoadHistory(repository: repository, clock: () => now)('SCL10234', days: 14);

    expect(repository.stored.keys, ['verified']);
  });
}
