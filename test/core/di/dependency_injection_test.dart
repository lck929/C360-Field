import 'package:c360/core/config/app_config.dart';
import 'package:c360/core/di/core_providers.dart';
import 'package:c360/features/attendance/data/datasources/attendance_api_data_source.dart';
import 'package:c360/features/attendance/data/datasources/selfie_local_data_source.dart';
import 'package:c360/features/attendance/di/attendance_providers.dart';
import 'package:c360/features/auth/data/datasources/auth_api_data_source.dart';
import 'package:c360/features/auth/data/datasources/microsoft_auth_data_source.dart';
import 'package:c360/features/auth/di/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const realApi = AppConfig(apiBaseUrl: 'https://api.example.com/v1');

  test('uses the mock API when no base URL is passed', () {
    final config = AppConfig.fromEnvironment();

    expect(config.apiBaseUrl, isEmpty);
    expect(config.useMockApi, isTrue);
  });

  test('a base URL wires the real API data sources and Entra sign-in', () {
    final container = ProviderContainer(overrides: [configProvider.overrideWithValue(realApi)]);
    addTearDown(container.dispose);

    expect(container.read(authRemoteDataSourceProvider), isA<AuthApiDataSource>());
    expect(container.read(attendanceRemoteDataSourceProvider), isA<AttendanceApiDataSource>());
    expect(container.read(microsoftAuthDataSourceProvider), isA<EntraMicrosoftAuthDataSource>());
  });

  test('config values reach the data sources that use them', () {
    final container = ProviderContainer(
      overrides: [
        configProvider.overrideWithValue(
          const AppConfig(apiBaseUrl: 'https://api.example.com/v1', maxSelfieBytes: 300 * 1024),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect((container.read(selfieDataSourceProvider) as FileSelfieStore).maxBytes, 300 * 1024);
  });
}
