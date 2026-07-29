import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MonthlyRosterShiftGroup {
  const MonthlyRosterShiftGroup({
    required this.id,
    required this.title,
    required this.rowLabels,
  });

  final String id;
  final String title;
  final List<String> rowLabels;
}

class MonthlyRosterTemplate {
  const MonthlyRosterTemplate({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.groups,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<MonthlyRosterShiftGroup> groups;

  List<String> get rowLabels => List.unmodifiable(
    groups.expand(
      (group) => group.rowLabels.map((row) => '${group.title} / $row'),
    ),
  );
}

class MonthlyRosterTemplateRepository {
  MonthlyRosterTemplateRepository([this._preferences]);

  static const storageKey = 'shift_tools.monthly_roster_templates.v1';
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<MonthlyRosterTemplate>> load() async {
    final source = (await _store).getString(storageKey);
    if (source == null) return const [];
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        !{1, 2}.contains(decoded['formatVersion']) ||
        decoded['templates'] is! List) {
      throw const FormatException('ข้อมูลเทมเพลตรายเดือนไม่ถูกต้อง');
    }
    return List.unmodifiable(
      (decoded['templates'] as List).map((raw) {
        if (raw is! Map<String, dynamic>) {
          throw const FormatException('ข้อมูลเทมเพลตรายเดือนไม่ถูกต้อง');
        }
        final start = DateTime.tryParse('${raw['startDate']}');
        final end = DateTime.tryParse('${raw['endDate']}');
        if (raw['id'] is! String ||
            raw['title'] is! String ||
            start == null ||
            end == null) {
          throw const FormatException('ข้อมูลเทมเพลตรายเดือนไม่ครบ');
        }
        final groups = raw['groups'] is List
            ? (raw['groups'] as List).map(_decodeGroup).toList(growable: false)
            : [
                MonthlyRosterShiftGroup(
                  id: '${raw['id']}-group-1',
                  title: 'กลุ่มเวร 1',
                  rowLabels: List.unmodifiable(
                    ((raw['rowLabels'] as List?) ?? const []).map(
                      (row) => '$row',
                    ),
                  ),
                ),
              ];
        return MonthlyRosterTemplate(
          id: raw['id'] as String,
          title: raw['title'] as String,
          startDate: start,
          endDate: end,
          groups: List.unmodifiable(groups),
        );
      }),
    );
  }

  static MonthlyRosterShiftGroup _decodeGroup(Object? raw) {
    if (raw is! Map<String, dynamic> ||
        raw['id'] is! String ||
        raw['title'] is! String ||
        raw['rowLabels'] is! List) {
      throw const FormatException('ข้อมูลกลุ่มเวรไม่ถูกต้อง');
    }
    return MonthlyRosterShiftGroup(
      id: raw['id'] as String,
      title: raw['title'] as String,
      rowLabels: List.unmodifiable(
        (raw['rowLabels'] as List).map((row) => '$row'),
      ),
    );
  }

  Future<void> saveAll(List<MonthlyRosterTemplate> templates) async {
    await (await _store).setString(
      storageKey,
      jsonEncode({
        'formatVersion': 2,
        'templates': [
          for (final template in templates)
            {
              'id': template.id,
              'title': template.title,
              'startDate': template.startDate.toIso8601String(),
              'endDate': template.endDate.toIso8601String(),
              'groups': [
                for (final group in template.groups)
                  {
                    'id': group.id,
                    'title': group.title,
                    'rowLabels': group.rowLabels,
                  },
              ],
            },
        ],
      }),
    );
  }
}
