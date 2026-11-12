import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';

class GetCachedHistory {
  const GetCachedHistory(this._repository);

  final AttendanceRepository _repository;

  Future<List<AttendanceRecord>> call(String employeeId) => _repository.cachedHistory(employeeId);
}
