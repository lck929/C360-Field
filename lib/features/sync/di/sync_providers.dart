import 'package:c360/core/di/core_providers.dart';
import 'package:c360/features/attendance/di/attendance_providers.dart';
import 'package:c360/features/sync/domain/policies/backoff_policy.dart';
import 'package:c360/features/sync/domain/usecases/sync_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backoffPolicyProvider = Provider<BackoffPolicy>((ref) => BackoffPolicy());

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    repository: ref.watch(attendanceRepositoryProvider),
    connectivity: ref.watch(connectivityProvider),
    backoff: ref.watch(backoffPolicyProvider),
    clock: ref.watch(clockProvider),
  ),
);
