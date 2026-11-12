import 'package:c360/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:c360/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:c360/features/auth/data/datasources/microsoft_auth_data_source.dart';
import 'package:c360/features/auth/domain/entities/employee.dart';
import 'package:c360/features/auth/domain/entities/restored_session.dart';
import 'package:c360/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required MicrosoftAuthDataSource microsoft,
    required DateTime Function() clock,
  })  : _remote = remote,
        _local = local,
        _microsoft = microsoft,
        _clock = clock;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final MicrosoftAuthDataSource _microsoft;
  final DateTime Function() _clock;

  @override
  Future<RestoredSession> restoreSession() async {
    final employeeId = await _local.employeeId();
    final token = await _local.token();
    if (token == null || token.isEmpty) return RestoredSession(lastEmployeeId: employeeId);

    final expiresAt = await _local.expiresAt();
    if (expiresAt == null || !expiresAt.isAfter(_clock())) {
      await _local.clearToken();
      return RestoredSession(expired: true, lastEmployeeId: employeeId);
    }

    final cached = await _local.employee();
    if (cached != null) return RestoredSession(employee: cached, lastEmployeeId: employeeId);

    try {
      return RestoredSession(employee: await refreshProfile(), lastEmployeeId: employeeId);
    } catch (_) {
      return RestoredSession(lastEmployeeId: employeeId);
    }
  }

  @override
  Future<Employee> signIn(String employeeId, String password) async {
    await _local.saveEmployeeId(employeeId);
    return _startSession(await _remote.login(employeeId, password));
  }

  @override
  Future<Employee> signInWithMicrosoft() async =>
      _startSession(await _remote.loginWithMicrosoft(await _microsoft.idToken()));

  @override
  Future<Employee> refreshProfile() async {
    final employee = await _remote.me();
    await _local.saveEmployee(employee);
    return employee;
  }

  @override
  Future<void> endSession() => _local.clearToken();

  @override
  Future<void> signOut() => _local.clear();

  Future<Employee> _startSession(LoginResponse login) async {
    await _local.saveToken(login.token, _clock().add(Duration(seconds: login.expiresIn)));
    try {
      return await refreshProfile();
    } catch (_) {
      await _local.clearToken();
      rethrow;
    }
  }
}
