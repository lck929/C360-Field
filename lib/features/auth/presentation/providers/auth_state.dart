import 'package:c360/features/auth/domain/entities/employee.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class SignedOut extends AuthState {
  const SignedOut({this.notice, this.lastEmployeeId});

  final String? notice;
  final String? lastEmployeeId;
}

class SignedIn extends AuthState {
  const SignedIn(this.employee);

  final Employee employee;
}
