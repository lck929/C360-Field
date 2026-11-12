import 'package:c360/core/error/app_exception.dart';
import 'package:c360/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:c360/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:c360/features/auth/data/datasources/microsoft_auth_data_source.dart';
import 'package:c360/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:c360/features/auth/domain/entities/employee.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

class _FakeRemote implements AuthRemoteDataSource {
  bool meFails = false;

  @override
  Future<LoginResponse> login(String employeeId, String password) async => (token: 'token', expiresIn: 3600);

  @override
  Future<LoginResponse> loginWithMicrosoft(String idToken) async => (token: 'entra', expiresIn: 3600);

  @override
  Future<Employee> me() async {
    if (meFails) throw const AppException.network();
    return testEmployee;
  }
}

class _MemoryLocal implements AuthLocalDataSource {
  String? storedToken;
  DateTime? storedExpiry;
  String? storedEmployeeId;
  Employee? storedEmployee;

  @override
  Future<void> saveToken(String token, DateTime expiresAt) async {
    storedToken = token;
    storedExpiry = expiresAt;
  }

  @override
  Future<String?> token() async => storedToken;

  @override
  Future<DateTime?> expiresAt() async => storedExpiry;

  @override
  Future<void> saveEmployeeId(String id) async => storedEmployeeId = id;

  @override
  Future<String?> employeeId() async => storedEmployeeId;

  @override
  Future<void> saveEmployee(Employee employee) async {
    storedEmployeeId = employee.employeeId;
    storedEmployee = employee;
  }

  @override
  Future<Employee?> employee() async => storedEmployee;

  @override
  Future<void> clearToken() async {
    storedToken = null;
    storedExpiry = null;
  }

  @override
  Future<void> clear() async {
    await clearToken();
    storedEmployee = null;
  }
}

void main() {
  final now = DateTime(2026, 11, 10, 9);
  late _FakeRemote remote;
  late _MemoryLocal local;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _MemoryLocal();
    repository = AuthRepositoryImpl(
      remote: remote,
      local: local,
      microsoft: const MockMicrosoftAuthDataSource(),
      clock: () => now,
    );
  });

  test('signing in stores the token with its expiry and caches the profile', () async {
    final employee = await repository.signIn('SCL10234', 'secret');

    expect(employee.name, 'Ravi Kumar');
    expect(local.storedToken, 'token');
    expect(local.storedExpiry, now.add(const Duration(hours: 1)));
    expect(local.storedEmployee, isNotNull);
  });

  test('a failed profile load after login does not leave a half session', () async {
    remote.meFails = true;

    await expectLater(repository.signIn('SCL10234', 'secret'), throwsA(isA<AppException>()));
    expect(local.storedToken, isNull);
  });

  test('restoring an expired session clears the token and reports it expired', () async {
    local
      ..storedToken = 'old'
      ..storedExpiry = now.subtract(const Duration(minutes: 1))
      ..storedEmployeeId = 'SCL10234';

    final restored = await repository.restoreSession();

    expect(restored.expired, isTrue);
    expect(restored.employee, isNull);
    expect(restored.lastEmployeeId, 'SCL10234');
    expect(local.storedToken, isNull);
  });

  test('restoring a valid session uses the cached profile without the network', () async {
    remote.meFails = true;
    local
      ..storedToken = 'token'
      ..storedExpiry = now.add(const Duration(hours: 1))
      ..storedEmployee = testEmployee;

    final restored = await repository.restoreSession();

    expect(restored.employee?.employeeId, 'SCL10234');
  });
}
