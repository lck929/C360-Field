import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:c360/core/error/error_codes.dart';
import 'package:c360/core/mock/mock_server.dart';
import 'package:c360/core/network/api_client.dart';
import 'package:c360/core/utils/bssid.dart';
import 'package:c360/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:c360/features/attendance/data/models/attendance_record_model.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/rules/attendance_rules.dart';

class AttendanceMockDataSource implements AttendanceRemoteDataSource {
  AttendanceMockDataSource(this._server);

  static const _recordsKey = 'mock:records';

  final MockServer _server;
  final _random = Random();

  @override
  Future<String> submit(AttendanceRecord record, String selfiePath) async {
    await _server.reach();
    final rows = _load();
    final existing = rows.where((r) => r['clientId'] == record.clientId).firstOrNull;
    if (existing != null) return existing['id'] as String;

    if (!(await _server.registeredBssids()).contains(normalizeBssid(record.bssid))) {
      throw httpFailure(403, 'BSSID not registered for the project', code: ErrorCodes.notOnSiteNetwork);
    }
    final selfie = File(selfiePath);
    if (!await selfie.exists() || await selfie.length() == 0) {
      throw httpFailure(422, 'No usable face in the image', code: ErrorCodes.noFaceFound);
    }
    if (!_server.settings.faceMatches) {
      throw httpFailure(422, 'Selfie doesn’t match the enrolled face', code: ErrorCodes.faceNotMatched);
    }

    final sameDay = rows.where(
      (r) =>
          r['employeeId'] == record.employeeId &&
          dayOf(DateTime.parse(r['capturedAt'] as String)) == dayOf(record.capturedAt),
    );
    final hasIn = sameDay.any((r) => r['type'] == 'IN');
    final hasOut = sameDay.any((r) => r['type'] == 'OUT');
    if (record.type == AttendanceType.checkIn ? hasIn : (!hasIn || hasOut)) {
      throw httpFailure(409, 'Out of sequence', code: ErrorCodes.sequenceError);
    }

    final id = _newId();
    rows.add(_row(id, record.clientId, record.employeeId, record.type, record.capturedAt));
    await _save(rows);
    return id;
  }

  @override
  Future<List<AttendanceRecord>> history(String employeeId, DateTime from, DateTime to) async {
    await _server.reach();
    await _seed(employeeId);
    final start = dayOf(from);
    final end = dayOf(to).add(const Duration(days: 1));
    return _load()
        .where((r) => r['employeeId'] == employeeId)
        .map((r) => AttendanceRecordModel.fromServer(r, employeeId))
        .where((r) => !r.capturedAt.isBefore(start) && r.capturedAt.isBefore(end))
        .toList();
  }

  Future<void> _seed(String employeeId) async {
    final box = _server.box;
    if (box.get('mock:seeded:$employeeId') != null) return;
    final rows = _load();
    final today = dayOf(DateTime.now());
    var added = 0;
    for (var offset = 1; added < 5; offset++) {
      final day = DateTime(today.year, today.month, today.day - offset);
      if (day.weekday == DateTime.sunday) continue;
      final checkIn = DateTime(day.year, day.month, day.day, 6, 46 + (added * 5) % 13);
      final checkOut = DateTime(day.year, day.month, day.day, 17, (added * 11) % 16);
      rows
        ..add(_row(_newId(), 'seed-${checkIn.millisecondsSinceEpoch}', employeeId, AttendanceType.checkIn, checkIn))
        ..add(_row(_newId(), 'seed-${checkOut.millisecondsSinceEpoch}', employeeId, AttendanceType.checkOut, checkOut));
      added++;
    }
    await _save(rows);
    await box.put('mock:seeded:$employeeId', 'true');
  }

  String _newId() => 'ATT-${10000 + _random.nextInt(89999)}';

  Map<String, dynamic> _row(String id, String clientId, String employeeId, AttendanceType type, DateTime at) => {
        'id': id,
        'clientId': clientId,
        'employeeId': employeeId,
        'type': type.api,
        'capturedAt': at.toUtc().toIso8601String(),
        'status': 'VERIFIED',
      };

  List<Map<String, dynamic>> _load() {
    final raw = _server.box.get(_recordsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _save(List<Map<String, dynamic>> rows) => _server.box.put(_recordsKey, jsonEncode(rows));
}
