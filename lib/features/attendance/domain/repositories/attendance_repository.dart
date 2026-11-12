import 'package:c360/features/attendance/domain/entities/attendance_record.dart';

abstract interface class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchRecords(String employeeId);

  Future<List<AttendanceRecord>> records();

  Future<AttendanceRecord?> record(String clientId);

  Future<void> saveRecord(AttendanceRecord record);

  Future<void> deleteRecord(AttendanceRecord record);

  Future<String> saveSelfie(String photoPath, String clientId);

  Future<void> deleteSelfie(AttendanceRecord record);

  Future<String> submit(AttendanceRecord record);

  Future<List<AttendanceRecord>> fetchHistory(String employeeId, DateTime from, DateTime to);

  Future<List<AttendanceRecord>> cachedHistory(String employeeId);
}
