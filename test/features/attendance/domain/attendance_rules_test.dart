import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/entities/day_summary.dart';
import 'package:c360/features/attendance/domain/rules/attendance_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 11, 10, 12);
  AttendanceRecord inAt(int hour, {SyncStatus status = SyncStatus.verified, int day = 10}) =>
      testRecord('in$day$hour', at: DateTime(2026, 11, day, hour), status: status);
  AttendanceRecord outAt(int hour) =>
      testRecord('out$hour', type: AttendanceType.checkOut, hour: hour, status: SyncStatus.verified);

  test('offers check in when nothing is recorded today', () {
    final today = summarizeDay([inAt(7, day: 9)], now, now);

    expect(today.phase, TodayPhase.notCheckedIn);
    expect(today.nextAction, AttendanceType.checkIn);
  });

  test('offers check out after check in and counts time on site so far', () {
    final today = summarizeDay([inAt(7, status: SyncStatus.pending)], now, now);

    expect(today.nextAction, AttendanceType.checkOut);
    expect(today.worked, const Duration(hours: 5));
  });

  test('completes the day after check out', () {
    final today = summarizeDay([inAt(7), outAt(17)], now, now);

    expect(today.phase, TodayPhase.checkedOut);
    expect(today.nextAction, isNull);
    expect(today.worked, const Duration(hours: 10));
  });

  test('ignores rejected records', () {
    expect(summarizeDay([inAt(7, status: SyncStatus.rejected)], now, now).nextAction, AttendanceType.checkIn);
  });

  test('ignores a check out earlier than the check in', () {
    expect(summarizeDay([outAt(6), inAt(7)], now, now).phase, TodayPhase.checkedIn);
  });

  test('builds the last seven days ending today', () {
    final days = lastDays([inAt(7), outAt(17)], now);

    expect(days, hasLength(7));
    expect(days.first.day, DateTime(2026, 11, 4));
    expect(days.last.worked, const Duration(hours: 10));
  });

  test('merges local records with server history without duplicates', () {
    final server = [testRecord('ATT-1', serverId: 'ATT-1', status: SyncStatus.verified)];
    final local = [
      testRecord('c1', serverId: 'ATT-1', status: SyncStatus.verified),
      testRecord('c2', type: AttendanceType.checkOut, hour: 17),
    ];

    expect(mergeHistory(server, local).map((r) => r.clientId), ['c2', 'ATT-1']);
  });

  test('groups records by day, newest day first', () {
    final days = groupByDay([inAt(7, day: 9), inAt(7)], now);

    expect(days.map((d) => d.day), [DateTime(2026, 11, 10), DateTime(2026, 11, 9)]);
  });
}
