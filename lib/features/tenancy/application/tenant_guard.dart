import '../domain/tenant.dart';

class TenantAccessException implements Exception {
  const TenantAccessException(this.message);

  final String message;

  @override
  String toString() => 'TenantAccessException: $message';
}

class TenantGuard {
  const TenantGuard(this._repository);

  final TenantRepository _repository;

  Future<Tenant> requireAccessible(String tenantId) async {
    final tenant = await _repository.findById(tenantId);
    if (tenant == null) {
      throw const TenantAccessException('Tenant not found.');
    }
    if (!tenant.canAccessPlatform) {
      throw TenantAccessException(
        'Tenant ${tenant.id} is not permitted to access the platform.',
      );
    }
    return tenant;
  }

  void requireSameTenant({
    required TenantContext context,
    required String resourceTenantId,
  }) {
    if (context.tenantId != resourceTenantId) {
      throw const TenantAccessException(
        'Cross-tenant resource access is not allowed.',
      );
    }
  }
}
