class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? code;

  const ApiException(this.message, {this.statusCode, this.code});

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isUnprocessable => statusCode == 422;

  @override
  String toString() => 'ApiException(${statusCode ?? '-'}): $message';
}
