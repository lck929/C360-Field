import 'package:c360/features/auth/domain/entities/employee.dart';
import 'package:c360/features/auth/domain/entities/restored_session.dart';

abstract interface class AuthRepository {
  Future<RestoredSession> restoreSession();

  Future<Employee> signIn(String employeeId, String password);

  Future<Employee> signInWithMicrosoft();

  Future<Employee> refreshProfile();

  Future<void> endSession();

  Future<void> signOut();
}
