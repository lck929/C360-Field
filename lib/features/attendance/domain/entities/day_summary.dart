import 'package:c360/features/attendance/domain/entities/attendance_record.dart';

enum TodayPhase { notCheckedIn, checkedIn, checkedOut }

class DaySummary {
  const DaySummary({required this.day, this.checkIn, this.checkOut, this.worked = Duration.zero});

  final DateTime day;
  final AttendanceRecord? checkIn;
  final AttendanceRecord? checkOut;
  final Duration worked;

  TodayPhase get phase => checkOut != null
      ? TodayPhase.checkedOut
      : checkIn != null
          ? TodayPhase.checkedIn
          : TodayPhase.notCheckedIn;

  AttendanceType? get nextAction => switch (phase) {
        TodayPhase.notCheckedIn => AttendanceType.checkIn,
        TodayPhase.checkedIn => AttendanceType.checkOut,
        TodayPhase.checkedOut => null,
      };
}
