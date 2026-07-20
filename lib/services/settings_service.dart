import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/audit_entry.dart';

class SettingsService {
  static const _sourceKey = 'source_url';
  static const _nameKey = 'target_name';
  static const _yearKey = 'target_year';
  static const _monthKey = 'target_month';
  static const _archiveKey = 'archive_original';
  static const _autoRefreshKey = 'auto_refresh';
  static const _refreshSecondsKey = 'refresh_seconds';
  static const _passkeyHashKey = 'passkey_sha256';
  static const _auditKey = 'audit_log';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    return AppSettings(
      sourceUrl: prefs.getString(_sourceKey) ?? defaults.sourceUrl,
      targetName: prefs.getString(_nameKey) ?? defaults.targetName,
      year: prefs.getInt(_yearKey) ?? defaults.year,
      month: prefs.getInt(_monthKey) ?? defaults.month,
      archiveOriginal: prefs.getBool(_archiveKey) ?? defaults.archiveOriginal,
      autoRefresh: prefs.getBool(_autoRefreshKey) ?? defaults.autoRefresh,
      refreshSeconds:
          (prefs.getInt(_refreshSecondsKey) ?? defaults.refreshSeconds).clamp(
            1,
            10,
          ),
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_sourceKey, settings.sourceUrl),
      prefs.setString(_nameKey, settings.targetName),
      prefs.setInt(_yearKey, settings.year),
      prefs.setInt(_monthKey, settings.month),
      prefs.setBool(_archiveKey, settings.archiveOriginal),
      prefs.setBool(_autoRefreshKey, settings.autoRefresh),
      prefs.setInt(_refreshSecondsKey, settings.refreshSeconds.clamp(1, 10)),
    ]);
  }

  Future<bool> hasPasskey() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_passkeyHashKey) ?? '').isNotEmpty;
  }

  Future<void> setPasskey(String passkey) async {
    if (passkey.trim().length < 6) {
      throw ArgumentError('Passkey ต้องมีอย่างน้อย 6 ตัวอักษร');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passkeyHashKey, _hash(passkey));
  }

  Future<bool> verifyPasskey(String passkey) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_passkeyHashKey);
    return saved != null && saved == _hash(passkey);
  }

  Future<List<AuditEntry>> loadAudit() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_auditKey) ?? const [];
    return raw
        .map((item) {
          try {
            return AuditEntry.fromJson(
              Map<String, Object?>.from(jsonDecode(item) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<AuditEntry>()
        .toList();
  }

  Future<void> appendAudit(AuditEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_auditKey) ?? <String>[];
    entries.insert(0, jsonEncode(entry.toJson()));
    if (entries.length > 200) entries.removeRange(200, entries.length);
    await prefs.setStringList(_auditKey, entries);
  }

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
}
