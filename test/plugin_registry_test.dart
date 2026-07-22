import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/plugin_system/application/plugin_registry.dart';
import 'package:phakphum_calendar/features/plugin_system/domain/platform_plugin.dart';

void main() {
  test('registers and enables a tenant-scoped plugin', () async {
    final registry = PluginRegistry();
    final plugin = _FakePlugin();
    registry.register(plugin);

    await registry.enable(
      pluginId: 'hospital.rules.th',
      context: const PluginContext(
        tenantId: 'tenant-a',
        organizationId: 'org-a',
        configuration: <String, Object?>{'minimumRestHours': 8},
      ),
    );

    expect(plugin.initialized, isTrue);
    expect(registry.manifests.single.id, 'hospital.rules.th');
  });

  test('rejects duplicate plugin IDs', () {
    final registry = PluginRegistry()..register(_FakePlugin());
    expect(
      () => registry.register(_FakePlugin()),
      throwsA(isA<PluginRegistryException>()),
    );
  });
}

class _FakePlugin implements PlatformPlugin {
  bool initialized = false;

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'hospital.rules.th',
        name: 'Thai Hospital Rules',
        version: '1.0.0',
        minimumPlatformVersion: '3.0.0',
        capabilities: <String>{'schedule-rules'},
      );

  @override
  Future<void> dispose() async {
    initialized = false;
  }

  @override
  Future<void> initialize(PluginContext context) async {
    initialized = true;
  }
}
