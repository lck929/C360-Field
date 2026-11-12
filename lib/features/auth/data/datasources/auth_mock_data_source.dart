import 'package:c360/core/error/error_codes.dart';
import 'package:c360/core/mock/mock_server.dart';
import 'package:c360/core/network/api_client.dart';
import 'package:c360/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:c360/features/auth/data/models/employee_model.dart';
import 'package:c360/features/auth/domain/entities/employee.dart';

class AuthMockDataSource implements AuthRemoteDataSource {
  AuthMockDataSource({required MockServer server, required Future<String?> Function() employeeId})
      : _server = server,
        _employeeId = employeeId;

  static const _sessionSeconds = 8 * 60 * 60;

  final MockServer _server;
  final Future<String?> Function() _employeeId;

  @override
  Future<LoginResponse> login(String employeeId, String password) async {
    await _server.reach();
    if (password == 'wrong') {
      throw httpFailure(401, 'Employee ID or password is incorrect', code: ErrorCodes.invalidCredentials);
    }
    return (token: 'mock.$employeeId.${DateTime.now().millisecondsSinceEpoch}', expiresIn: _sessionSeconds);
  }

  @override
  Future<LoginResponse> loginWithMicrosoft(String idToken) async {
    await _server.reach();
    return (token: 'mock.entra.${DateTime.now().millisecondsSinceEpoch}', expiresIn: _sessionSeconds);
  }

  @override
  Future<Employee> me() async {
    await _server.reach();
    return EmployeeModel.fromJson({
      'employeeId': await _employeeId() ?? 'SCL10234',
      'name': 'Ravi Kumar',
      'trade': 'Steel fixer',
      'faceEnrolled': true,
      'project': {
        'id': 'PRJ-HRT2-TB',
        'name': 'Sobha Hartland II, Tower B',
        'wifiBssids': await _server.registeredBssids(),
        'shift': {'start': '07:00', 'end': '17:00'},
      },
    });
  }
}
