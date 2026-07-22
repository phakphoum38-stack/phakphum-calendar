import 'package:flutter/foundation.dart';

enum TenantPlan { community, professional, enterprise }

enum TenantStatus { trial, active, suspended, archived }

@immutable
class Tenant {
  const Tenant({
    required this.id,
    required this.slug,
    required this.displayName,
    required this.plan,
    required this.status,
    required this.createdAt,
    this.primaryDomain,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String slug;
  final String displayName;
  final TenantPlan plan;
  final TenantStatus status;
  final DateTime createdAt;
  final String? primaryDomain;
  final Map<String, Object?> metadata;

  bool get canAccessPlatform =>
      status == TenantStatus.trial || status == TenantStatus.active;
}

@immutable
class TenantContext {
  const TenantContext({
    required this.tenantId,
    required this.organizationId,
    required this.actorId,
    required this.actorRole,
    this.departmentId,
    this.correlationId,
  });

  final String tenantId;
  final String organizationId;
  final String actorId;
  final String actorRole;
  final String? departmentId;
  final String? correlationId;
}

abstract interface class TenantRepository {
  Future<Tenant?> findById(String tenantId);

  Future<Tenant?> findBySlug(String slug);

  Future<void> save(Tenant tenant);
}
