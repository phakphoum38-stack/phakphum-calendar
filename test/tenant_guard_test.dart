import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/tenancy/application/tenant_guard.dart';
import 'package:phakphum_calendar/features/tenancy/domain/tenant.dart';

void main() {
  test('allows active tenant and blocks cross-tenant access', () async {
    final repository = _TenantRepository(
      Tenant(
        id: 'tenant-a',
        slug: 'hospital-a',
        displayName: 'Hospital A',
        plan: TenantPlan.enterprise,
        status: TenantStatus.active,
        createdAt: DateTime(2026),
      ),
    );
    final guard = TenantGuard(repository);

    final tenant = await guard.requireAccessible('tenant-a');
    expect(tenant.id, 'tenant-a');

    expect(
      () => guard.requireSameTenant(
        context: const TenantContext(
          tenantId: 'tenant-a',
          organizationId: 'org-a',
          actorId: 'user-1',
          actorRole: 'admin',
        ),
        resourceTenantId: 'tenant-b',
      ),
      throwsA(isA<TenantAccessException>()),
    );
  });

  test('blocks suspended tenant', () async {
    final guard = TenantGuard(
      _TenantRepository(
        Tenant(
          id: 'tenant-a',
          slug: 'hospital-a',
          displayName: 'Hospital A',
          plan: TenantPlan.professional,
          status: TenantStatus.suspended,
          createdAt: DateTime(2026),
        ),
      ),
    );

    expect(
      () => guard.requireAccessible('tenant-a'),
      throwsA(isA<TenantAccessException>()),
    );
  });
}

class _TenantRepository implements TenantRepository {
  _TenantRepository(this.tenant);

  final Tenant tenant;

  @override
  Future<Tenant?> findById(String tenantId) async =>
      tenant.id == tenantId ? tenant : null;

  @override
  Future<Tenant?> findBySlug(String slug) async =>
      tenant.slug == slug ? tenant : null;

  @override
  Future<void> save(Tenant tenant) async {}
}
