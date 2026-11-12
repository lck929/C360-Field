import 'dart:convert';

import 'package:c360/features/attendance/data/models/attendance_record_model.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

abstract interface class RecordQueueLocalDataSource {
  Future<List<AttendanceRecord>> all();

  Future<AttendanceRecord?> find(String clientId);

  Future<void> save(AttendanceRecord record);

  Future<void> remove(String clientId);

  Stream<List<AttendanceRecord>> watch();
}

class HiveRecordQueue implements RecordQueueLocalDataSource {
  HiveRecordQueue(this._box);

  final Box<String> _box;

  List<AttendanceRecord> _all() => _box.values.map(_decode).whereType<AttendanceRecord>().toList();

  @override
  Future<List<AttendanceRecord>> all() async => _all();

  @override
  Future<AttendanceRecord?> find(String clientId) async {
    final raw = _box.get(clientId);
    return raw == null ? null : _decode(raw);
  }

  @override
  Future<void> save(AttendanceRecord record) =>
      _box.put(record.clientId, jsonEncode(AttendanceRecordModel.toJson(record)));

  @override
  Future<void> remove(String clientId) => _box.delete(clientId);

  @override
  Stream<List<AttendanceRecord>> watch() async* {
    yield _all();
    yield* _box.watch().map((_) => _all());
  }

  AttendanceRecord? _decode(String raw) {
    try {
      return AttendanceRecordModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Skipping unreadable queue entry: $e');
      return null;
    }
  }
}
