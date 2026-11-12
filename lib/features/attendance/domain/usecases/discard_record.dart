import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';

class DiscardRecord {
  const DiscardRecord(this._repository);

  final AttendanceRepository _repository;

  Future<void> call(AttendanceRecord record) => _repository.deleteRecord(record);
}
