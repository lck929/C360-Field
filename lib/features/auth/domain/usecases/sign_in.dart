import 'package:c360/features/auth/domain/entities/employee.dart';
import 'package:c360/features/auth/domain/repositories/auth_repository.dart';

class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Employee> call(String employeeId, String password) =>
      _repository.signIn(employeeId.trim().toUpperCase(), password);
}
