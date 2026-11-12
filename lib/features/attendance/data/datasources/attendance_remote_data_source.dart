import 'package:c360/features/attendance/domain/entities/attendance_record.dart';

abstract interface class AttendanceRemoteDataSource {
  Future<String> submit(AttendanceRecord record, String selfiePath);

  Future<List<AttendanceRecord>> history(String employeeId, DateTime from, DateTime to);
}
