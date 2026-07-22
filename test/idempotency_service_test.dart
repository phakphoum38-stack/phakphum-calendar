import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/api/application/idempotency_service.dart';

void main() {
  test('executes operation once for the same tenant and key', () async {
    final repository = _MemoryIdempotencyRepository();
    final service = IdempotencyService(repository);
    var calls = 0;

    Future<String> operation() async {
      calls += 1;
      return 'created';
    }

    final first = await service.execute<String>(
      tenantId: 'tenant-a',
      key: 'request-1',
      operation: operation,
    );
    final second = await service.execute<String>(
      tenantId: 'tenant-a',
      key: 'request-1',
      operation: operation,
    );

    expect(first, 'created');
    expect(second, 'created');
    expect(calls, 1);
  });
}

class _MemoryIdempotencyRepository implements IdempotencyRepository {
  final Map<String, Object> _values = <String, Object>{};

  @override
  Future<Object?> read({required String tenantId, required String key}) async =>
      _values['$tenantId:$key'];

  @override
  Future<void> write({
    required String tenantId,
    required String key,
    required Object result,
  }) async {
    _values['$tenantId:$key'] = result;
  }
}
