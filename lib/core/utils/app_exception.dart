class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException(this.message, [this.prefix]);

  @override
  String toString() {
    return "$prefix: $message";
  }
}

class BadRequestException extends AppException {
  BadRequestException(String message) : super(message, "Bad Request");
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(message, "Unauthorized");
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message, "Not Found");
}

class ServerException extends AppException {
  ServerException(String message) : super(message, "Server Error");
}

class BadResponseException extends AppException {
  BadResponseException(String message) : super(message, "Invalid Response");
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, "Network Error");
} 