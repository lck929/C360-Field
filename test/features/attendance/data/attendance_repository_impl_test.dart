import 'dart:io';

import 'package:c360/core/error/app_exception.dart';
import 'package:c360/core/error/error_codes.dart';
import 'package:c360/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:c360/features/attendance/data/datasources/history_cache_local_data_source.dart';
import 'package:c360/features/attendance/data/datasources/record_queue_local_data_source.dart';
import 'package:c360/features/attendance/data/datasources/selfie_local_data_source.dart';
import 'package:c360/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../../../helpers/fakes.dart';

class _FakeRemote implements AttendanceRemoteDataSource {
  final submittedPaths = <String>[];

  @override
  Future<String> submit(AttendanceRecord record, String selfiePath) async {
    submittedPaths.add(selfiePath);
    return 'ATT-1';
  }

  @override
  Future<List<AttendanceRecord>> history(String employeeId, DateTime from, DateTime to) async =>
      [testRecord('ATT-9', status: SyncStatus.verified, serverId: 'ATT-9')];
}

void main() {
  late Directory dir;
  late _FakeRemote remote;
  late FileSelfieStore selfies;

  Future<AttendanceRepositoryImpl> repository() async => AttendanceRepositoryImpl(
        remote: remote,
        queue: HiveRecordQueue(await Hive.openBox<String>('queue')),
        cache: HiveHistoryCache(await Hive.openBox<String>('app')),
        selfies: selfies,
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('c360_test');
    Hive.init(dir.path);
    remote = _FakeRemote();
    selfies = FileSelfieStore(maxBytes: 500 * 1024, baseDirectory: () async => dir);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('queued records survive the app being killed', () async {
    await (await repository()).saveRecord(testRecord('in').copyWith(attempts: 2, error: 'Service unavailable'));
    await Hive.close();

    final record = await (await repository()).record('in');

    expect(record!.status, SyncStatus.pending);
    expect(record.attempts, 2);
    expect(record.error, 'Service unavailable');
    expect(record.capturedAt, DateTime(2026, 11, 10, 7));
  });

  test('saving the same clientId twice keeps one record', () async {
    final repo = await repository();

    await repo.saveRecord(testRecord('in'));
    await repo.saveRecord(testRecord('in').copyWith(status: SyncStatus.verified));

    expect(await repo.records(), hasLength(1));
  });

  test('submits with the stored photo path', () async {
    final photo = File('${dir.path}${Platform.pathSeparator}selfies${Platform.pathSeparator}in.jpg');
    await photo.create(recursive: true);

    final id = await (await repository()).submit(testRecord('in'));

    expect(id, 'ATT-1');
    expect(remote.submittedPaths.single, photo.path);
  });

  test('a missing photo is a final rejection, not a retry', () async {
    await expectLater(
      (await repository()).submit(testRecord('in')),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', FailureType.rejected)
          .having((e) => e.code, 'code', ErrorCodes.missingPhoto)),
    );
  });

  test('fetched history is cached for offline use', () async {
    final repo = await repository();

    await repo.fetchHistory('SCL10234', DateTime(2026, 11, 1), DateTime(2026, 11, 10));

    expect((await repo.cachedHistory('SCL10234')).single.serverId, 'ATT-9');
  });
}
