import 'package:c360/core/di/core_providers.dart';
import 'package:c360/features/auth/data/datasources/auth_api_data_source.dart';
import 'package:c360/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:c360/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:c360/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:c360/features/auth/data/datasources/microsoft_auth_data_source.dart';
import 'package:c360/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:c360/features/auth/domain/repositories/auth_repository.dart';
import 'package:c360/features/auth/domain/usecases/end_session.dart';
import 'package:c360/features/auth/domain/usecases/refresh_profile.dart';
import 'package:c360/features/auth/domain/usecases/restore_session.dart';
import 'package:c360/features/auth/domain/usecases/sign_in.dart';
import 'package:c360/features/auth/domain/usecases/sign_in_with_microsoft.dart';
import 'package:c360/features/auth/domain/usecases/sign_out.dart';
import 'package:c360/features/site_check/di/site_check_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => SecureAuthLocalDataSource(ref.watch(tokenStorageProvider)),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  if (!ref.watch(configProvider).useMockApi) return AuthApiDataSource(ref.watch(dioProvider));
  return AuthMockDataSource(
    server: ref.watch(mockServerProvider),
    employeeId: ref.watch(authLocalDataSourceProvider).employeeId,
  );
});

final microsoftAuthDataSourceProvider = Provider<MicrosoftAuthDataSource>(
  (ref) => ref.watch(configProvider).useMockApi
      ? const MockMicrosoftAuthDataSource()
      : const EntraMicrosoftAuthDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
    microsoft: ref.watch(microsoftAuthDataSourceProvider),
    clock: ref.watch(clockProvider),
  ),
);

final restoreSessionProvider = Provider((ref) => RestoreSession(ref.watch(authRepositoryProvider)));
final signInProvider = Provider((ref) => SignIn(ref.watch(authRepositoryProvider)));
final signInWithMicrosoftProvider = Provider((ref) => SignInWithMicrosoft(ref.watch(authRepositoryProvider)));
final refreshProfileProvider = Provider((ref) => RefreshProfile(ref.watch(authRepositoryProvider)));
final endSessionProvider = Provider((ref) => EndSession(ref.watch(authRepositoryProvider)));
final signOutProvider = Provider((ref) => SignOut(ref.watch(authRepositoryProvider)));
