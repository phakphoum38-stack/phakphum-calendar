import 'package:flutter/foundation.dart';

@immutable
class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  final String code;
  final String message;
  final Map<String, Object?> details;

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    'details': details,
  };
}

@immutable
class ApiResponse<T> {
  const ApiResponse.success({required this.data, required this.correlationId})
    : error = null;

  const ApiResponse.failure({required this.error, required this.correlationId})
    : data = null;

  final T? data;
  final ApiError? error;
  final String correlationId;

  bool get isSuccess => error == null;
}

@immutable
class PageRequest {
  const PageRequest({this.cursor, this.limit = 50})
    : assert(limit > 0),
      assert(limit <= 200);

  final String? cursor;
  final int limit;
}

@immutable
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final bool hasMore;
  final String? nextCursor;
}
