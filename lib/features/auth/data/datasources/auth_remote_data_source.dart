import 'package:c360/features/auth/domain/entities/employee.dart';

typedef LoginResponse = ({String token, int expiresIn});

abstract interface class AuthRemoteDataSource {
  Future<LoginResponse> login(String employeeId, String password);

  Future<LoginResponse> loginWithMicrosoft(String idToken);

  Future<Employee> me();
}
