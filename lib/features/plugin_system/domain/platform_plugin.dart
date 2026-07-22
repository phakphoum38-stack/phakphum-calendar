import 'package:flutter/foundation.dart';

@immutable
class PluginManifest {
  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.minimumPlatformVersion,
    required this.capabilities,
    this.publisher,
  });

  final String id;
  final String name;
  final String version;
  final String minimumPlatformVersion;
  final Set<String> capabilities;
  final String? publisher;
}

abstract interface class PlatformPlugin {
  PluginManifest get manifest;

  Future<void> initialize(PluginContext context);

  Future<void> dispose();
}

@immutable
class PluginContext {
  const PluginContext({
    required this.tenantId,
    required this.organizationId,
    required this.configuration,
  });

  final String tenantId;
  final String organizationId;
  final Map<String, Object?> configuration;
}

enum PluginState { registered, enabled, disabled, failed }

@immutable
class InstalledPlugin {
  const InstalledPlugin({
    required this.tenantId,
    required this.manifest,
    required this.state,
    this.configuration = const <String, Object?>{},
    this.failureMessage,
  });

  final String tenantId;
  final PluginManifest manifest;
  final PluginState state;
  final Map<String, Object?> configuration;
  final String? failureMessage;
}
