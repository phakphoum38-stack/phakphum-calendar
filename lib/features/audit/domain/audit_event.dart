import 'package:flutter/foundation.dart';

enum AuditAction {
  created,
  updated,
  approved,
  rejected,
  cancelled,
  synchronized,
}

@immutable
class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.organizationId,
    required this.actorId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.occurredAt,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String organizationId;
  final String actorId;
  final String entityType;
  final String entityId;
  final AuditAction action;
  final DateTime occurredAt;
  final Map<String, Object?> metadata;
}

abstract interface class AuditRepository {
  Future<void> append(AuditEvent event);

  Future<List<AuditEvent>> listByEntity({
    required String organizationId,
    required String entityType,
    required String entityId,
  });
}
