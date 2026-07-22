abstract interface class IdempotencyRepository {
  Future<Object?> read({required String tenantId, required String key});

  Future<void> write({
    required String tenantId,
    required String key,
    required Object result,
  });
}

class IdempotencyService {
  const IdempotencyService(this._repository);

  final IdempotencyRepository _repository;

  Future<T> execute<T extends Object>({
    required String tenantId,
    required String key,
    required Future<T> Function() operation,
  }) async {
    final previous = await _repository.read(tenantId: tenantId, key: key);
    if (previous != null) {
      if (previous is! T) {
        throw StateError('Stored idempotent result has an unexpected type.');
      }
      return previous;
    }

    final result = await operation();
    await _repository.write(tenantId: tenantId, key: key, result: result);
    return result;
  }
}
