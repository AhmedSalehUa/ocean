/// The shared `{success, message, data, meta}` envelope used by the delivery API.
class ApiEnvelope<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;

  const ApiEnvelope({
    required this.success,
    required this.message,
    this.data,
    this.meta,
  });

  static ApiEnvelope<T> parse<T>(
    Map<String, dynamic> json,
    T Function(dynamic raw) parser,
  ) {
    return ApiEnvelope<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] == null ? null : parser(json['data']),
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}
