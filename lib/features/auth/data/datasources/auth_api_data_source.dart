import 'package:c360/core/network/api_client.dart';
import 'package:c360/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:c360/features/auth/data/models/employee_model.dart';
import 'package:c360/features/auth/domain/entities/employee.dart';
import 'package:dio/dio.dart';

class AuthApiDataSource implements AuthRemoteDataSource {
  AuthApiDataSource(this._dio);

  final Dio _dio;

  @override
  Future<LoginResponse> login(String employeeId, String password) => guardRequest(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'employeeId': employeeId, 'password': password},
          options: publicRequest,
        );
        return _loginResponse(res.data!);
      });

  @override
  Future<LoginResponse> loginWithMicrosoft(String idToken) => guardRequest(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/microsoft',
          data: {'idToken': idToken},
          options: publicRequest,
        );
        return _loginResponse(res.data!);
      });

  @override
  Future<Employee> me() => guardRequest(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me');
        return EmployeeModel.fromJson(res.data!);
      });

  LoginResponse _loginResponse(Map<String, dynamic> json) =>
      (token: json['token'] as String, expiresIn: (json['expiresIn'] as num).toInt());
}
