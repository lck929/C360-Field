import 'dart:async';

import 'package:c360/core/error/app_exception.dart';
import 'package:c360/core/error/error_codes.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/sync/domain/entities/sync_report.dart';
import 'package:c360/features/sync/domain/policies/backoff_policy.dart';
import 'package:c360/features/sync/domain/usecases/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  const employee = 'SCL10234';
  const serverDown = AppException(FailureType.server, 'Service unavailable');

  late FakeAttendanceRepository repository;
  late FakeConnectivity connectivity;
  late DateTime now;
  late SyncEngine engine;

  setUp(() {
    repository = FakeAttendanceRepository();
    connectivity = FakeConnectivity();
    now = DateTime(2026, 11, 10, 9);
    engine = SyncEngine(
      repository: repository,
      connectivity: connectivity,
      backoff: BackoffPolicy(jitter: 0),
      clock: () => now,
    );
  });

  test('sends pending records oldest first, marks them verified and deletes the photo', () async {
    await repository.saveRecord(testRecord('out', type: AttendanceType.checkOut, hour: 17));
    await repository.saveRecord(testRecord('in'));

    final report = await engine.run(employeeId: employee);

    expect(repository.submitted, ['in', 'out']);
    expect(report.verified, 2);
    expect(repository.stored['in']!.status, SyncStatus.verified);
    expect(repository.stored['in']!.serverId, 'ATT-in');
    expect(repository.deletedSelfies, containsAll(['in.jpg', 'out.jpg']));
  });

  test('keeps a record pending with backoff and stops the queue when the server is down', () async {
    await repository.saveRecord(testRecord('in'));
    await repository.saveRecord(testRecord('out', type: AttendanceType.checkOut, hour: 17));
    repository.submitScript['in'] = [serverDown];

    final report = await engine.run(employeeId: employee);

    final record = repository.stored['in']!;
    expect(record.status, SyncStatus.pending);
    expect(record.attempts, 1);
    expect(record.nextAttemptAt, now.add(const Duration(seconds: 5)));
    expect(record.error, 'Service unavailable');
    expect(repository.submitted, ['in'], reason: 'a check-out must not overtake its check-in');
    expect(report.stop, SyncStop.waiting);
    expect(repository.deletedSelfies, isEmpty);
  });

  test('waits for the retry time unless forced, and doubles the delay', () async {
    await repository.saveRecord(testRecord('in'));
    repository.submitScript['in'] = [serverDown, serverDown];

    await engine.run(employeeId: employee);
    await engine.run(employeeId: employee);
    expect(repository.submitted, ['in']);

    await engine.run(employeeId: employee, force: true);
    expect(repository.submitted, ['in', 'in']);
    expect(repository.stored['in']!.nextAttemptAt, now.add(const Duration(seconds: 10)));
  });

  test('retries with the same clientId and never creates a duplicate', () async {
    await repository.saveRecord(testRecord('in'));
    repository.submitScript['in'] = [const AppException.network()];

    await engine.run(employeeId: employee);
    await engine.run(employeeId: employee, force: true);

    expect(repository.submitted, ['in', 'in']);
    expect(repository.stored, hasLength(1));
    expect(repository.stored['in']!.status, SyncStatus.verified);
  });

  test('marks a face mismatch as rejected and carries on with the queue', () async {
    await repository.saveRecord(testRecord('in'));
    await repository.saveRecord(testRecord('out', type: AttendanceType.checkOut, hour: 17));
    repository.submitScript['in'] = [
      const AppException(FailureType.rejected, 'No match', code: ErrorCodes.faceNotMatched),
    ];

    final report = await engine.run(employeeId: employee);

    expect(repository.stored['in']!.status, SyncStatus.rejected);
    expect(repository.stored['in']!.errorCode, ErrorCodes.faceNotMatched);
    expect(repository.stored['out']!.status, SyncStatus.verified);
    expect(report.rejected, 1);
  });

  test('rejects a record whose photo is missing', () async {
    await repository.saveRecord(testRecord('in'));
    repository.missingSelfies.add('in.jpg');

    await engine.run(employeeId: employee);

    expect(repository.stored['in']!.status, SyncStatus.rejected);
    expect(repository.stored['in']!.errorCode, ErrorCodes.missingPhoto);
  });

  test('stops on an expired token and keeps the record pending without spending an attempt', () async {
    await repository.saveRecord(testRecord('in'));
    repository.submitScript['in'] = [
      const AppException(FailureType.unauthorized, 'Expired', code: ErrorCodes.tokenExpired),
    ];

    final report = await engine.run(employeeId: employee);

    expect(report.stop, SyncStop.unauthorized);
    expect(repository.stored['in']!.status, SyncStatus.pending);
    expect(repository.stored['in']!.attempts, 0);
  });

  test('sends nothing while offline', () async {
    await repository.saveRecord(testRecord('in'));
    connectivity.online = false;

    final report = await engine.run(employeeId: employee);

    expect(report.stop, SyncStop.offline);
    expect(repository.submitted, isEmpty);
  });

  test('resets records left syncing when the app was killed', () async {
    await repository.saveRecord(testRecord('in', status: SyncStatus.syncing));

    await engine.recoverInterrupted();
    await engine.run(employeeId: employee);

    expect(repository.stored['in']!.status, SyncStatus.verified);
  });

  test('joins a run already in progress instead of sending twice', () async {
    await repository.saveRecord(testRecord('in'));
    repository.gate = Completer<void>();

    final first = engine.run(employeeId: employee);
    final second = engine.run(employeeId: employee);
    repository.gate!.complete();
    await Future.wait([first, second]);

    expect(repository.submitted, ['in']);
  });

  test('only syncs the signed-in employee', () async {
    await repository.saveRecord(testRecord('mine'));
    await repository.saveRecord(testRecord('theirs', employeeId: 'SCL99999'));

    await engine.run(employeeId: employee);

    expect(repository.submitted, ['mine']);
    expect(repository.stored['theirs']!.status, SyncStatus.pending);
  });

  test('prunes finished records older than the history window', () async {
    await repository.saveRecord(testRecord('old', at: DateTime(2026, 10, 1), status: SyncStatus.verified));
    await repository.saveRecord(testRecord('waiting', at: DateTime(2026, 10, 1)));

    await engine.prune(olderThan: const Duration(days: 14));

    expect(repository.stored.containsKey('old'), isFalse);
    expect(repository.stored.containsKey('waiting'), isTrue);
  });
}
