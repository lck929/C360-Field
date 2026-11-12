import 'dart:async';

import 'package:c360/core/error/app_exception.dart';
import 'package:c360/core/error/error_codes.dart';
import 'package:c360/core/network/connectivity_service.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:c360/features/auth/domain/entities/employee.dart';
import 'package:c360/features/auth/domain/entities/restored_session.dart';
import 'package:c360/features/auth/domain/repositories/auth_repository.dart';

const testEmployee = Employee(
  employeeId: 'SCL10234',
  name: 'Ravi Kumar',
  trade: 'Steel fixer',
  faceEnrolled: true,
  projectId: 'PRJ-HRT2-TB',
  projectName: 'Sobha Hartland II, Tower B',
  wifiBssids: ['3c:84:6a:1f:22:b0'],
  shiftStart: '07:00',
  shiftEnd: '17:00',
);

AttendanceRecord testRecord(
  String id, {
  AttendanceType type = AttendanceType.checkIn,
  DateTime? at,
  int hour = 7,
  String employeeId = 'SCL10234',
  SyncStatus status = SyncStatus.pending,
  String? serverId,
}) =>
    AttendanceRecord(
      clientId: id,
      employeeId: employeeId,
      type: type,
      capturedAt: at ?? DateTime(2026, 11, 10, hour),
      bssid: '3c:84:6a:1f:22:b0',
      selfie: '$id.jpg',
      status: status,
      serverId: serverId,
    );

class FakeConnectivity implements ConnectivityService {
  bool online = true;

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> changes() => const Stream.empty();
}

class FakeAttendanceRepository implements AttendanceRepository {
  final stored = <String, AttendanceRecord>{};
  final deletedSelfies = <String>{};
  final missingSelfies = <String>{};
  final submitScript = <String, List<AppException>>{};
  final submitted = <String>[];
  final cache = <AttendanceRecord>[];
  AppException? historyFailure;
  List<AttendanceRecord> serverHistory = const [];
  Completer<void>? gate;
  final _changes = StreamController<List<AttendanceRecord>>.broadcast();

  @override
  Stream<List<AttendanceRecord>> watchRecords(String employeeId) async* {
    yield stored.values.where((r) => r.employeeId == employeeId).toList();
    yield* _changes.stream.map((all) => all.where((r) => r.employeeId == employeeId).toList());
  }

  @override
  Future<List<AttendanceRecord>> records() async => stored.values.toList();

  @override
  Future<AttendanceRecord?> record(String clientId) async => stored[clientId];

  @override
  Future<void> saveRecord(AttendanceRecord record) async {
    stored[record.clientId] = record;
    _changes.add(stored.values.toList());
  }

  @override
  Future<void> deleteRecord(AttendanceRecord record) async {
    deletedSelfies.add(record.selfie);
    stored.remove(record.clientId);
    _changes.add(stored.values.toList());
  }

  @override
  Future<String> saveSelfie(String photoPath, String clientId) async => '$clientId.jpg';

  @override
  Future<void> deleteSelfie(AttendanceRecord record) async => deletedSelfies.add(record.selfie);

  @override
  Future<String> submit(AttendanceRecord record) async {
    if (missingSelfies.contains(record.selfie)) {
      throw const AppException(FailureType.rejected, 'Missing photo', code: ErrorCodes.missingPhoto);
    }
    submitted.add(record.clientId);
    if (gate != null) await gate!.future;
    final steps = submitScript[record.clientId];
    if (steps != null && steps.isNotEmpty) throw steps.removeAt(0);
    return 'ATT-${record.clientId}';
  }

  @override
  Future<List<AttendanceRecord>> fetchHistory(String employeeId, DateTime from, DateTime to) async {
    final failure = historyFailure;
    if (failure != null) throw failure;
    return serverHistory;
  }

  @override
  Future<List<AttendanceRecord>> cachedHistory(String employeeId) async => cache;
}

class FakeAuthRepository implements AuthRepository {
  String? lastEmployeeId;

  @override
  Future<RestoredSession> restoreSession() async => const RestoredSession();

  @override
  Future<Employee> signIn(String employeeId, String password) async {
    lastEmployeeId = employeeId;
    if (password == 'wrong') {
      throw const AppException(FailureType.rejected, 'Invalid', code: ErrorCodes.invalidCredentials);
    }
    return testEmployee;
  }

  @override
  Future<Employee> signInWithMicrosoft() async => testEmployee;

  @override
  Future<Employee> refreshProfile() async => testEmployee;

  @override
  Future<void> endSession() async {}

  @override
  Future<void> signOut() async {}
}
