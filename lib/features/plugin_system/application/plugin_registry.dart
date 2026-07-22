import '../domain/platform_plugin.dart';

class PluginRegistryException implements Exception {
  const PluginRegistryException(this.message);

  final String message;

  @override
  String toString() => 'PluginRegistryException: $message';
}

class PluginRegistry {
  final Map<String, PlatformPlugin> _plugins = <String, PlatformPlugin>{};

  Iterable<PluginManifest> get manifests =>
      _plugins.values.map((plugin) => plugin.manifest);

  void register(PlatformPlugin plugin) {
    final id = plugin.manifest.id.trim();
    if (id.isEmpty) {
      throw const PluginRegistryException('Plugin ID cannot be empty.');
    }
    if (_plugins.containsKey(id)) {
      throw PluginRegistryException('Plugin $id is already registered.');
    }
    _plugins[id] = plugin;
  }

  PlatformPlugin requirePlugin(String pluginId) {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      throw PluginRegistryException('Plugin $pluginId is not registered.');
    }
    return plugin;
  }

  Future<void> enable({
    required String pluginId,
    required PluginContext context,
  }) async {
    await requirePlugin(pluginId).initialize(context);
  }

  Future<void> disable(String pluginId) async {
    await requirePlugin(pluginId).dispose();
  }
}
