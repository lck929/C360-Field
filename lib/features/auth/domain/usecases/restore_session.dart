import 'package:c360/features/auth/domain/entities/restored_session.dart';
import 'package:c360/features/auth/domain/repositories/auth_repository.dart';

class RestoreSession {
  const RestoreSession(this._repository);

  final AuthRepository _repository;

  Future<RestoredSession> call() => _repository.restoreSession();
}
