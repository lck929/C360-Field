import 'dart:convert';

import 'package:c360/core/storage/token_storage.dart';
import 'package:c360/features/auth/data/models/employee_model.dart';
import 'package:c360/features/auth/domain/entities/employee.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AuthLocalDataSource {
  Future<void> saveToken(String token, DateTime expiresAt);

  Future<String?> token();

  Future<DateTime?> expiresAt();

  Future<void> saveEmployeeId(String id);

  Future<String?> employeeId();

  Future<void> saveEmployee(Employee employee);

  Future<Employee?> employee();

  Future<void> clearToken();

  Future<void> clear();
}

class SecureAuthLocalDataSource implements AuthLocalDataSource {
  SecureAuthLocalDataSource(this._tokens, [FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final TokenStorage _tokens;
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveToken(String token, DateTime expiresAt) => _tokens.save(token, expiresAt);

  @override
  Future<String?> token() => _tokens.token();

  @override
  Future<DateTime?> expiresAt() => _tokens.expiresAt();

  @override
  Future<void> saveEmployeeId(String id) => _storage.write(key: 'employeeId', value: id);

  @override
  Future<String?> employeeId() => _storage.read(key: 'employeeId');

  @override
  Future<void> saveEmployee(Employee employee) async {
    await saveEmployeeId(employee.employeeId);
    await _storage.write(key: 'profile', value: jsonEncode(EmployeeModel.toJson(employee)));
  }

  @override
  Future<Employee?> employee() async {
    final raw = await _storage.read(key: 'profile');
    if (raw == null) return null;
    try {
      return EmployeeModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearToken() => _tokens.clear();

  @override
  Future<void> clear() async {
    await _tokens.clear();
    await _storage.delete(key: 'profile');
  }
}
