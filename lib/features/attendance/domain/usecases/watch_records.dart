import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';

class WatchRecords {
  const WatchRecords(this._repository);

  final AttendanceRepository _repository;

  Stream<List<AttendanceRecord>> call(String employeeId) => _repository.watchRecords(employeeId);
}
