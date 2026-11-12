import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/domain/entities/day_summary.dart';

DateTime dayOf(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DaySummary summarizeDay(Iterable<AttendanceRecord> records, DateTime day, DateTime now) {
  final target = dayOf(day);
  final counted = records.where((r) => r.status != SyncStatus.rejected && dayOf(r.capturedAt) == target).toList()
    ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

  final checkIn = counted.where((r) => r.type == AttendanceType.checkIn).firstOrNull;
  final checkOut = checkIn == null
      ? null
      : counted.reversed
          .where((r) => r.type == AttendanceType.checkOut && !r.capturedAt.isBefore(checkIn.capturedAt))
          .firstOrNull;

  var worked = Duration.zero;
  if (checkIn != null && checkOut != null) {
    worked = checkOut.capturedAt.difference(checkIn.capturedAt);
  } else if (checkIn != null && target == dayOf(now)) {
    worked = now.difference(checkIn.capturedAt);
  }
  return DaySummary(
    day: target,
    checkIn: checkIn,
    checkOut: checkOut,
    worked: worked.isNegative ? Duration.zero : worked,
  );
}

List<DaySummary> lastDays(Iterable<AttendanceRecord> records, DateTime now, {int count = 7}) {
  final today = dayOf(now);
  return List.generate(
    count,
    (i) => summarizeDay(records, DateTime(today.year, today.month, today.day - (count - 1 - i)), now),
  );
}

List<AttendanceRecord> mergeHistory(Iterable<AttendanceRecord> server, Iterable<AttendanceRecord> local) {
  final serverIds = {for (final r in server) r.serverId};
  return [
    ...server,
    for (final r in local)
      if (r.serverId == null || !serverIds.contains(r.serverId)) r,
  ]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
}

List<AttendanceRecord> verifiedMissingOnServer(
  Iterable<AttendanceRecord> local,
  Iterable<AttendanceRecord> server, {
  required String employeeId,
  required DateTime from,
  required DateTime to,
}) {
  final serverIds = {for (final r in server) r.serverId};
  final start = dayOf(from);
  final end = dayOf(to);
  return [
    for (final r in local)
      if (r.employeeId == employeeId &&
          r.status == SyncStatus.verified &&
          r.serverId != null &&
          !serverIds.contains(r.serverId) &&
          !dayOf(r.capturedAt).isBefore(start) &&
          !dayOf(r.capturedAt).isAfter(end))
        r,
  ];
}

List<DaySummary> groupByDay(Iterable<AttendanceRecord> records, DateTime now) {
  final days = records.map((r) => dayOf(r.capturedAt)).toSet().toList()..sort((a, b) => b.compareTo(a));
  return [for (final day in days) summarizeDay(records, day, now)];
}

List<AttendanceRecord> recordsOn(Iterable<AttendanceRecord> records, DateTime day) =>
    records.where((r) => dayOf(r.capturedAt) == day).toList()..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
