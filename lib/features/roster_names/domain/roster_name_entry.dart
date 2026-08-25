import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RosterNameEntry {
  const RosterNameEntry({
    required this.id,
    required this.name,
    required this.statuses,
    this.lockedDutyPoint,
  });

  final String id;
  final String name;
  final List<String> statuses;
  final String? lockedDutyPoint;
}

class RosterNameRepository {
  RosterNameRepository([this._preferences]);

  static const storageKey = 'shift_tools.roster_names.v1';
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<RosterNameEntry>> load() async {
    final source = (await _store).getString(storageKey);
    if (source == null) return const [];
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        !{1, 2}.contains(decoded['formatVersion']) ||
        decoded['entries'] is! List) {
      throw const FormatException('ข้อมูลรายชื่อไม่ถูกต้อง');
    }
    return List.unmodifiable(
      (decoded['entries'] as List).map((raw) {
        if (raw is! Map<String, dynamic> ||
            raw['id'] is! String ||
            raw['name'] is! String ||
            raw['statuses'] is! List) {
          throw const FormatException('ข้อมูลรายชื่อไม่ครบ');
        }
        return RosterNameEntry(
          id: raw['id'] as String,
          name: raw['name'] as String,
          statuses: List.unmodifiable(
            (raw['statuses'] as List).map((status) => '$status'),
          ),
          lockedDutyPoint: switch (raw['lockedDutyPoint']) {
            final String value when value.trim().isNotEmpty => value,
            _ => null,
          },
        );
      }),
    );
  }

  Future<void> saveAll(List<RosterNameEntry> entries) async {
    await (await _store).setString(
      storageKey,
      jsonEncode({
        'formatVersion': 2,
        'entries': [
          for (final entry in entries)
            {
              'id': entry.id,
              'name': entry.name,
              'statuses': entry.statuses,
              'lockedDutyPoint': entry.lockedDutyPoint,
            },
        ],
      }),
    );
  }
}
