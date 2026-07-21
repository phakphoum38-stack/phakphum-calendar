import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/audit_entry.dart';
import '../models/saved_sheet.dart';
import '../models/shift_alert.dart';
import '../models/tool_definition.dart';

class SettingsService {
  static const _nameKey = 'target_name';
  static const _archiveKey = 'archive_original';
  static const _autoRefreshKey = 'auto_refresh';
  static const _refreshSecondsKey = 'refresh_seconds';
  static const _googleWebClientIdKey = 'google_web_client_id';
  static const _auditKey = 'audit_log';
  static const _pinnedToolIdsKey = 'pinned_tool_ids';
  static const _savedSheetsKey = 'saved_sheets';
  static const _alertDecisionsKey = 'shift_alert_decisions';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('passkey_sha256');
    // Older builds stored one global source URL. Remove it so switching Google
    // accounts can never expose or reuse another account's original Sheet.
    await prefs.remove('source_url');
    await prefs.remove('target_name');
    await prefs.remove('target_year');
    await prefs.remove('target_month');
    await prefs.remove('calendar_defaults_version');
    final defaults = AppSettings.defaults();
    return AppSettings(
      targetName: defaults.targetName,
      year: null,
      month: null,
      archiveOriginal: prefs.getBool(_archiveKey) ?? defaults.archiveOriginal,
      autoRefresh: prefs.getBool(_autoRefreshKey) ?? defaults.autoRefresh,
      refreshSeconds:
          (prefs.getInt(_refreshSecondsKey) ?? defaults.refreshSeconds).clamp(
            1,
            10,
          ),
      googleWebClientId:
          prefs.getString(_googleWebClientIdKey) ?? defaults.googleWebClientId,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_nameKey),
      prefs.remove('target_year'),
      prefs.remove('target_month'),
      prefs.setBool(_archiveKey, settings.archiveOriginal),
      prefs.setBool(_autoRefreshKey, settings.autoRefresh),
      prefs.setInt(_refreshSecondsKey, settings.refreshSeconds.clamp(1, 10)),
      prefs.setString(_googleWebClientIdKey, settings.googleWebClientId),
    ]);
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

  Future<Set<String>> loadPinnedToolIds() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_pinnedToolIdsKey);
    if (saved == null) return {...defaultPinnedToolIds};
    return saved.where((id) => toolById(id) != null).toSet();
  }

  Future<void> savePinnedToolIds(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final validIds = ids.where((id) => toolById(id) != null).toSet().toList()
      ..sort();
    await prefs.setStringList(_pinnedToolIdsKey, validIds);
  }

  Future<List<SavedSheet>> loadSavedSheets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedSheetsKey) ?? const [];
    return raw
        .map((item) {
          try {
            return SavedSheet.fromJson(
              Map<String, Object?>.from(jsonDecode(item) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<SavedSheet>()
        .toList();
  }

  Future<void> saveSavedSheets(Iterable<SavedSheet> sheets) async {
    final prefs = await SharedPreferences.getInstance();
    final records = sheets.toList()
      ..sort((left, right) => right.savedAt.compareTo(left.savedAt));
    await prefs.setStringList(
      _savedSheetsKey,
      records.take(100).map((sheet) => jsonEncode(sheet.toJson())).toList(),
    );
  }

  Future<Map<String, ShiftAlertDecision>> loadAlertDecisions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alertDecisionsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final values = Map<String, Object?>.from(jsonDecode(raw) as Map);
      return {
        for (final entry in values.entries)
          if (ShiftAlertDecision.values.any(
            (decision) => decision.name == entry.value,
          ))
            entry.key: ShiftAlertDecision.values.byName('${entry.value}'),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAlertDecision(
    String alertId,
    ShiftAlertDecision decision,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final decisions = await loadAlertDecisions();
    decisions[alertId] = decision;
    if (decisions.length > 500) decisions.remove(decisions.keys.first);
    await prefs.setString(
      _alertDecisionsKey,
      jsonEncode({
        for (final entry in decisions.entries) entry.key: entry.value.name,
      }),
    );
  }
}
