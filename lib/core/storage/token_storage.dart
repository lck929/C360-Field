import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock));

  final FlutterSecureStorage _storage;

  Future<void> save(String token, DateTime expiresAt) async {
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'expiresAt', value: expiresAt.toUtc().toIso8601String());
  }

  Future<String?> token() => _storage.read(key: 'token');

  Future<DateTime?> expiresAt() async => DateTime.tryParse(await _storage.read(key: 'expiresAt') ?? '');

  Future<void> clear() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'expiresAt');
  }
}
