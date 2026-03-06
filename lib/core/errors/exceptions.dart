class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.stackTrace});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.stackTrace});
}

class ServerException extends AppException {
  final int statusCode;
  const ServerException(super.message, {required this.statusCode, super.stackTrace});
}

class CacheException extends AppException {
  const CacheException(super.message, {super.stackTrace});
}
