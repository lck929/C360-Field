import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';

class GetRecord {
  const GetRecord(this._repository);

  final AttendanceRepository _repository;

  Future<AttendanceRecord?> call(String clientId) => _repository.record(clientId);
}
