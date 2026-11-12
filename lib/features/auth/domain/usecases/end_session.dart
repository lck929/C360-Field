import 'package:c360/features/auth/domain/repositories/auth_repository.dart';

class EndSession {
  const EndSession(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.endSession();
}
