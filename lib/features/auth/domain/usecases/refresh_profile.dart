import 'package:c360/features/auth/domain/entities/employee.dart';
import 'package:c360/features/auth/domain/repositories/auth_repository.dart';

class RefreshProfile {
  const RefreshProfile(this._repository);

  final AuthRepository _repository;

  Future<Employee> call() => _repository.refreshProfile();
}
