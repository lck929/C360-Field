import 'package:c360/core/error/app_exception.dart';
import 'package:c360/features/attendance/domain/entities/history_result.dart';
import 'package:c360/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:c360/features/attendance/domain/rules/attendance_rules.dart';
import 'package:c360/features/attendance/domain/usecases/refresh_history.dart';

class LoadHistory {
  const LoadHistory({required AttendanceRepository repository, required DateTime Function() clock})
      : _repository = repository,
        _clock = clock;

  final AttendanceRepository _repository;
  final DateTime Function() _clock;

  Future<HistoryResult> call(String employeeId, {required int days}) async {
    final today = dayOf(_clock());
    final from = DateTime(today.year, today.month, today.day - (days - 1));
    try {
      return HistoryResult(records: await RefreshHistory(_repository)(employeeId, from, today));
    } on AppException catch (e) {
      return HistoryResult(records: await _repository.cachedHistory(employeeId), failure: e);
    }
  }
}
