import 'package:c360/core/utils/bssid.dart';
import 'package:c360/features/auth/domain/entities/employee.dart';

abstract final class EmployeeModel {
  static Employee fromJson(Map<String, dynamic> json) {
    final project = json['project'] as Map<String, dynamic>;
    final shift = project['shift'] as Map<String, dynamic>? ?? const {};
    return Employee(
      employeeId: json['employeeId'] as String,
      name: json['name'] as String? ?? '',
      trade: json['trade'] as String? ?? '',
      faceEnrolled: json['faceEnrolled'] as bool? ?? false,
      projectId: project['id'] as String,
      projectName: project['name'] as String? ?? '',
      wifiBssids: (project['wifiBssids'] as List? ?? const []).whereType<String>().map(normalizeBssid).toList(),
      shiftStart: shift['start'] as String? ?? '',
      shiftEnd: shift['end'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toJson(Employee e) => {
        'employeeId': e.employeeId,
        'name': e.name,
        'trade': e.trade,
        'faceEnrolled': e.faceEnrolled,
        'project': {
          'id': e.projectId,
          'name': e.projectName,
          'wifiBssids': e.wifiBssids,
          'shift': {'start': e.shiftStart, 'end': e.shiftEnd},
        },
      };
}
