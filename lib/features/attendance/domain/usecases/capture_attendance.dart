import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';

class CaptureAttendance {
  const CaptureAttendance({
    required AttendanceRepository repository,
    required DateTime Function() clock,
    required String Function() newId,
  })  : _repository = repository,
        _clock = clock,
        _newId = newId;

  final AttendanceRepository _repository;
  final DateTime Function() _clock;
  final String Function() _newId;

  Future<AttendanceRecord> call({
    required String employeeId,
    required AttendanceType type,
    required String photoPath,
    required String bssid,
  }) async {
    final clientId = _newId();
    final record = AttendanceRecord(
      clientId: clientId,
      employeeId: employeeId,
      type: type,
      capturedAt: _clock(),
      bssid: bssid,
      selfie: await _repository.saveSelfie(photoPath, clientId),
    );
    await _repository.saveRecord(record);
    return record;
  }
}
