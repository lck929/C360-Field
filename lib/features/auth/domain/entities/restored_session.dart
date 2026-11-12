import 'package:c360/features/auth/domain/entities/employee.dart';

class RestoredSession {
  const RestoredSession({this.employee, this.expired = false, this.lastEmployeeId});

  final Employee? employee;
  final bool expired;
  final String? lastEmployeeId;
}
