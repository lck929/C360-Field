import 'dart:convert';

import 'package:c360/features/attendance/data/models/attendance_record_model.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:hive/hive.dart';

abstract interface class HistoryCacheLocalDataSource {
  Future<List<AttendanceRecord>> read(String employeeId);

  Future<void> write(String employeeId, List<AttendanceRecord> records);
}

class HiveHistoryCache implements HistoryCacheLocalDataSource {
  HiveHistoryCache(this._box);

  final Box<String> _box;

  @override
  Future<List<AttendanceRecord>> read(String employeeId) async {
    final raw = _box.get('history:$employeeId');
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => AttendanceRecordModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> write(String employeeId, List<AttendanceRecord> records) =>
      _box.put('history:$employeeId', jsonEncode(records.map(AttendanceRecordModel.toJson).toList()));
}
