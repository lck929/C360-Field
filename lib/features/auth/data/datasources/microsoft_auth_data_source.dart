import 'package:c360/core/error/app_exception.dart';

abstract interface class MicrosoftAuthDataSource {
  Future<String> idToken();
}

class EntraMicrosoftAuthDataSource implements MicrosoftAuthDataSource {
  const EntraMicrosoftAuthDataSource();

  @override
  Future<String> idToken() async => throw const AppException(
        FailureType.rejected,
        'Microsoft sign-in isn’t set up for this build yet. Use your Employee ID.',
      );
}

class MockMicrosoftAuthDataSource implements MicrosoftAuthDataSource {
  const MockMicrosoftAuthDataSource();

  @override
  Future<String> idToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return 'mock-entra-id-token';
  }
}
