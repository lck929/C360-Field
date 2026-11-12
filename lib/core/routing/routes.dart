import 'package:c360/features/attendance/domain/entities/attendance_record.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const history = '/history';
  static const sync = '/sync';
  static const profile = '/profile';
  static const checkPattern = '/attendance/:type';

  static String check(AttendanceType type) => '/attendance/${type == AttendanceType.checkIn ? 'in' : 'out'}';

  static AttendanceType typeOf(String? segment) => segment == 'out' ? AttendanceType.checkOut : AttendanceType.checkIn;
}
