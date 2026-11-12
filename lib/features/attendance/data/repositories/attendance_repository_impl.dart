import 'package:c360/core/error/app_exception.dart';
import 'package:c360/core/error/error_codes.dart';
import 'package:c360/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:c360/features/attendance/data/datasources/history_cache_local_data_source.dart';
import 'package:c360/features/attendance/data/datasources/record_queue_local_data_source.dart';
import 'package:c360/features/attendance/data/datasources/selfie_local_data_source.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl({
    required AttendanceRemoteDataSource remote,
    required RecordQueueLocalDataSource queue,
    required HistoryCacheLocalDataSource cache,
    required SelfieLocalDataSource selfies,
  })  : _remote = remote,
        _queue = queue,
        _cache = cache,
        _selfies = selfies;

  final AttendanceRemoteDataSource _remote;
  final RecordQueueLocalDataSource _queue;
  final HistoryCacheLocalDataSource _cache;
  final SelfieLocalDataSource _selfies;

  @override
  Stream<List<AttendanceRecord>> watchRecords(String employeeId) =>
      _queue.watch().map((all) => all.where((r) => r.employeeId == employeeId).toList());

  @override
  Future<List<AttendanceRecord>> records() => _queue.all();

  @override
  Future<AttendanceRecord?> record(String clientId) => _queue.find(clientId);

  @override
  Future<void> saveRecord(AttendanceRecord record) => _queue.save(record);

  @override
  Future<void> deleteRecord(AttendanceRecord record) async {
    await _selfies.delete(record.selfie);
    await _queue.remove(record.clientId);
  }

  @override
  Future<String> saveSelfie(String photoPath, String clientId) => _selfies.save(photoPath, clientId);

  @override
  Future<void> deleteSelfie(AttendanceRecord record) => _selfies.delete(record.selfie);

  @override
  Future<String> submit(AttendanceRecord record) async {
    final selfiePath = await _selfies.path(record.selfie);
    if (selfiePath == null) {
      throw const AppException(
        FailureType.rejected,
        'The photo for this record is missing on this phone',
        code: ErrorCodes.missingPhoto,
      );
    }
    return _remote.submit(record, selfiePath);
  }

  @override
  Future<List<AttendanceRecord>> fetchHistory(String employeeId, DateTime from, DateTime to) async {
    final records = await _remote.history(employeeId, from, to);
    await _cache.write(employeeId, records);
    return records;
  }

  @override
  Future<List<AttendanceRecord>> cachedHistory(String employeeId) => _cache.read(employeeId);
}
