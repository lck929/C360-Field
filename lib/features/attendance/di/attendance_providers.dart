import 'package:c360/core/di/core_providers.dart';
import 'package:c360/core/storage/app_boxes.dart';
import 'package:c360/features/attendance/data/datasources/attendance_api_data_source.dart';
import 'package:c360/features/attendance/data/datasources/attendance_mock_data_source.dart';
import 'package:c360/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:c360/features/attendance/data/datasources/face_detection_data_source.dart';
import 'package:c360/features/attendance/data/datasources/history_cache_local_data_source.dart';
import 'package:c360/features/attendance/data/datasources/record_queue_local_data_source.dart';
import 'package:c360/features/attendance/data/datasources/selfie_local_data_source.dart';
import 'package:c360/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:c360/features/attendance/domain/usecases/capture_attendance.dart';
import 'package:c360/features/attendance/domain/usecases/discard_record.dart';
import 'package:c360/features/attendance/domain/usecases/get_cached_history.dart';
import 'package:c360/features/attendance/domain/usecases/get_record.dart';
import 'package:c360/features/attendance/domain/usecases/load_history.dart';
import 'package:c360/features/attendance/domain/usecases/watch_records.dart';
import 'package:c360/features/site_check/di/site_check_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>((ref) {
  if (!ref.watch(configProvider).useMockApi) return AttendanceApiDataSource(ref.watch(dioProvider));
  return AttendanceMockDataSource(ref.watch(mockServerProvider));
});

final recordQueueDataSourceProvider = Provider<RecordQueueLocalDataSource>((ref) => HiveRecordQueue(AppBoxes.queue));

final historyCacheDataSourceProvider = Provider<HistoryCacheLocalDataSource>((ref) => HiveHistoryCache(AppBoxes.app));

final selfieDataSourceProvider = Provider<SelfieLocalDataSource>(
  (ref) => FileSelfieStore(maxBytes: ref.watch(configProvider).maxSelfieBytes),
);

final faceDetectionProvider = Provider<FaceDetectionDataSource>((ref) {
  final detector = FaceDetectionDataSource();
  ref.onDispose(detector.close);
  return detector;
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(
    remote: ref.watch(attendanceRemoteDataSourceProvider),
    queue: ref.watch(recordQueueDataSourceProvider),
    cache: ref.watch(historyCacheDataSourceProvider),
    selfies: ref.watch(selfieDataSourceProvider),
  ),
);

final watchRecordsProvider = Provider((ref) => WatchRecords(ref.watch(attendanceRepositoryProvider)));
final getRecordProvider = Provider((ref) => GetRecord(ref.watch(attendanceRepositoryProvider)));
final discardRecordProvider = Provider((ref) => DiscardRecord(ref.watch(attendanceRepositoryProvider)));
final getCachedHistoryProvider = Provider((ref) => GetCachedHistory(ref.watch(attendanceRepositoryProvider)));

final captureAttendanceProvider = Provider(
  (ref) => CaptureAttendance(
    repository: ref.watch(attendanceRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final loadHistoryProvider = Provider(
  (ref) => LoadHistory(repository: ref.watch(attendanceRepositoryProvider), clock: ref.watch(clockProvider)),
);
