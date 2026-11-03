/// Typed domain exception hierarchy with zero dependency on Firebase SDKs.
sealed class AppException implements Exception {
  const AppException(this.debugMessage);

  final String debugMessage;

  @override
  String toString() => '$runtimeType: $debugMessage';
}

final class NetworkException extends AppException {
  const NetworkException([super.debugMessage = 'Network unavailable']);
}

final class AuthCancelledException extends AppException {
  const AuthCancelledException([super.debugMessage = 'User cancelled sign-in']);
}

final class AuthFailedException extends AppException {
  const AuthFailedException([super.debugMessage = 'Authentication failed']);
}

final class PermissionDeniedException extends AppException {
  const PermissionDeniedException([super.debugMessage = 'Permission denied']);
}

final class ValidationException extends AppException {
  const ValidationException([super.debugMessage = 'Validation error']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.debugMessage = 'Document not found']);
}

final class StorageException extends AppException {
  const StorageException([super.debugMessage = 'Storage operation failed']);
}

final class UnexpectedException extends AppException {
  const UnexpectedException([super.debugMessage = 'Unexpected error']);
}

