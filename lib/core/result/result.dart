sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure<T> failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(value: final value) => onSuccess(value),
      Failure<T>() => onFailure(this as Failure<T>),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

sealed class Failure<T> extends Result<T> implements Exception {
  const Failure(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

final class ValidationFailure<T> extends Failure<T> {
  const ValidationFailure(
    super.message, {
    this.fieldErrors = const {},
    super.cause,
    super.stackTrace,
  });

  final Map<String, String> fieldErrors;
}

final class NetworkFailure<T> extends Failure<T> {
  const NetworkFailure(
    super.message, {
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;
}

final class ImportFailure<T> extends Failure<T> {
  const ImportFailure(
    super.message, {
    this.rowNumber,
    this.column,
    super.cause,
    super.stackTrace,
  });

  final int? rowNumber;
  final String? column;
}

/// Represents a controlled local persistence failure.
final class PersistenceFailure<T> extends Failure<T> {
  /// Creates a persistence failure while retaining its original cause.
  const PersistenceFailure(super.message, {super.cause, super.stackTrace});
}
