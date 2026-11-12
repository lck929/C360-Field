enum FailureType { network, unauthorized, rejected, server }

class AppException implements Exception {
  const AppException(this.type, this.message, {this.code});

  const AppException.network() : this(FailureType.network, 'No network connection');

  final FailureType type;
  final String message;
  final String? code;

  bool get isRetryable => type == FailureType.network || type == FailureType.server;

  @override
  String toString() => 'AppException($type, $code): $message';
}
