import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:c360/features/attendance/domain/rules/attendance_rules.dart';

class RefreshHistory {
  const RefreshHistory(this._repository);

  final AttendanceRepository _repository;

  Future<List<AttendanceRecord>> call(String employeeId, DateTime from, DateTime to) async {
    final before = await _repository.records();
    final server = await _repository.fetchHistory(employeeId, from, to);
    final stale = verifiedMissingOnServer(before, server, employeeId: employeeId, from: from, to: to);
    for (final record in stale) {
      await _repository.deleteRecord(record);
    }
    return server;
  }
}
