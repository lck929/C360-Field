import 'package:c360/core/error/app_exception.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';

class HistoryResult {
  const HistoryResult({required this.records, this.failure});

  final List<AttendanceRecord> records;
  final AppException? failure;
}
