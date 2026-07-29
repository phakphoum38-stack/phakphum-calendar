import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MonthlyRosterTemplate {
  const MonthlyRosterTemplate({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.rowLabels,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> rowLabels;
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
        decoded['formatVersion'] != 1 ||
        decoded['templates'] is! List) {
      throw const FormatException('ข้อมูลเทมเพลตรายเดือนไม่ถูกต้อง');
    }
    return List.unmodifiable(
      (decoded['templates'] as List).map((raw) {
        if (raw is! Map<String, dynamic>) {
          throw const FormatException('ข้อมูลเทมเพลตรายเดือนไม่ถูกต้อง');
        }
        final rows = raw['rowLabels'];
        final start = DateTime.tryParse('${raw['startDate']}');
        final end = DateTime.tryParse('${raw['endDate']}');
        if (raw['id'] is! String ||
            raw['title'] is! String ||
            rows is! List ||
            start == null ||
            end == null) {
          throw const FormatException('ข้อมูลเทมเพลตรายเดือนไม่ครบ');
        }
        return MonthlyRosterTemplate(
          id: raw['id'] as String,
          title: raw['title'] as String,
          startDate: start,
          endDate: end,
          rowLabels: List.unmodifiable(rows.map((row) => '$row')),
        );
      }),
    );
  }

  Future<void> saveAll(List<MonthlyRosterTemplate> templates) async {
    await (await _store).setString(
      storageKey,
      jsonEncode({
        'formatVersion': 1,
        'templates': [
          for (final template in templates)
            {
              'id': template.id,
              'title': template.title,
              'startDate': template.startDate.toIso8601String(),
              'endDate': template.endDate.toIso8601String(),
              'rowLabels': template.rowLabels,
            },
        ],
      }),
    );
  }
}
