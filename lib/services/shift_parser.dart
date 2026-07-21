import '../models/shift.dart';

class ShiftParser {
  const ShiftParser();

  List<Shift> parse({
    required List<SheetSnapshot> snapshots,
    required String targetName,
    Iterable<String> targetAliases = const [],
    required int year,
    required int month,
  }) {
    final targets = <String>{
      targetName,
      ...targetAliases,
    }.map(_compact).where((value) => value.length >= 2).toSet();
    if (targets.isEmpty) {
      throw const FormatException('กรุณาระบุชื่อผู้ปฏิบัติงาน');
    }
    final found = <String, Shift>{};

    for (final snapshot in snapshots) {
      Map<int, DateTime> activeDates = const {};
      var previousWasGen = false;
      for (var rowIndex = 0; rowIndex < snapshot.rows.length; rowIndex++) {
        final row = snapshot.rows[rowIndex];
        if (_isDateHeader(row)) {
          activeDates = _datesForHeader(
            snapshot: snapshot,
            headerIndex: rowIndex,
            fallbackYear: year,
            fallbackMonth: month,
          );
          previousWasGen = false;
          continue;
        }
        if (activeDates.isEmpty) continue;

        final label = _textAt(row, 0).trim();
        _ShiftRule? rule;
        if (label.isEmpty && previousWasGen) {
          rule = const _ShiftRule(
            code: 'AG',
            startHour: 16,
            startMinute: 30,
            endHour: 20,
            endMinute: 0,
            category: ShiftCategory.clinic,
          );
        } else {
          rule = _ruleForLabel(label);
        }
        previousWasGen = _normalizeLabel(label) == 'GEN';
        if (rule == null) continue;

        for (final entry in activeDates.entries) {
          final date = entry.value;
          if (date.year != year || date.month != month) continue;
          final assigned = _textAt(row, entry.key).trim();
          final compactAssigned = _compact(assigned);
          if (assigned.isEmpty || !targets.any(compactAssigned.contains)) {
            continue;
          }
          final start = DateTime(
            date.year,
            date.month,
            date.day,
            rule.startHour,
            rule.startMinute,
          );
          var end = DateTime(
            date.year,
            date.month,
            date.day,
            rule.endHour,
            rule.endMinute,
          );
          if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
          final shift = Shift(
            code: rule.code,
            rowLabel: label.isEmpty ? 'GEN บ่าย' : label,
            assignedName: assigned,
            start: start,
            end: end,
            sheetTitle: snapshot.title,
            cell: '${_columnName(entry.key + 1)}${rowIndex + 1}',
            category: rule.category,
          );
          found.putIfAbsent(shift.sourceKey, () => shift);
        }
      }
    }

    final result = found.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  bool _isDateHeader(List<Object?> row) {
    var count = 0;
    for (var i = 1; i < row.length; i++) {
      if (_dayNumber(row[i]) != null) count++;
    }
    return count >= 7;
  }

  Map<int, DateTime> _datesForHeader({
    required SheetSnapshot snapshot,
    required int headerIndex,
    required int fallbackYear,
    required int fallbackMonth,
  }) {
    final row = snapshot.rows[headerIndex];
    final headingParts = <String>[snapshot.title];
    final first = (headerIndex - 5).clamp(0, snapshot.rows.length - 1);
    final last = (headerIndex + 3).clamp(0, snapshot.rows.length - 1);
    for (var i = first; i <= last; i++) {
      if (i == headerIndex) continue;
      headingParts.add(snapshot.rows[i].map((cell) => '$cell').join(' '));
    }
    final inferred = _firstThaiDate(headingParts.join(' '));
    final numeric = <MapEntry<int, int>>[];
    for (var column = 1; column < row.length; column++) {
      final day = _dayNumber(row[column]);
      if (day != null) numeric.add(MapEntry(column, day));
    }
    if (numeric.isEmpty) return const {};

    var currentYear = inferred?.year ?? fallbackYear;
    var currentMonth = inferred?.month ?? fallbackMonth;
    final firstDay = numeric.first.value;
    if (inferred != null && firstDay < inferred.day) {
      currentMonth++;
      if (currentMonth == 13) {
        currentMonth = 1;
        currentYear++;
      }
    }

    final result = <int, DateTime>{};
    var previousDay = firstDay;
    for (var index = 0; index < numeric.length; index++) {
      final entry = numeric[index];
      if (index > 0 && entry.value < previousDay) {
        currentMonth++;
        if (currentMonth == 13) {
          currentMonth = 1;
          currentYear++;
        }
      }
      result[entry.key] = DateTime(currentYear, currentMonth, entry.value);
      previousDay = entry.value;
    }
    return result;
  }

  DateTime? _firstThaiDate(String text) {
    const months = <String, int>{
      'มกราคม': 1,
      'กุมภาพันธ์': 2,
      'มีนาคม': 3,
      'เมษายน': 4,
      'พฤษภาคม': 5,
      'มิถุนายน': 6,
      'กรกฎาคม': 7,
      'สิงหาคม': 8,
      'กันยายน': 9,
      'ตุลาคม': 10,
      'พฤศจิกายน': 11,
      'ธันวาคม': 12,
    };
    final monthPattern = months.keys.join('|');
    final match = RegExp(
      '(\\d{1,2})\\s*($monthPattern)\\s*'
      '(?:พ\\s*\\.?\\s*ศ\\s*\\.?\\s*)?(\\d{4})',
    ).firstMatch(text);
    if (match == null) return null;
    var parsedYear = int.parse(match.group(3)!);
    if (parsedYear > 2400) parsedYear -= 543;
    return DateTime(
      parsedYear,
      months[match.group(2)!]!,
      int.parse(match.group(1)!),
    );
  }

  _ShiftRule? _ruleForLabel(String label) {
    final value = _normalizeLabel(label);
    if (value == 'ER' || value == 'CT') {
      return _ShiftRule(
        code: 'U$value',
        startHour: 8,
        startMinute: 0,
        endHour: 16,
        endMinute: 0,
      );
    }
    if (value == 'GEN') {
      return const _ShiftRule(
        code: 'UG',
        startHour: 7,
        startMinute: 30,
        endHour: 12,
        endMinute: 0,
        category: ShiftCategory.clinic,
      );
    }
    if (value.contains('14ชั้น')) {
      return const _ShiftRule(
        code: 'U14',
        startHour: 7,
        startMinute: 0,
        endHour: 8,
        endMinute: 0,
      );
    }

    final p = RegExp(r'^P([1-4])(เช้า|บ่าย|ดึก)$').firstMatch(value);
    if (p != null) return _threePartRule('P${p.group(1)}', p.group(2)!);
    for (final base in const ['CTIPD', 'CTER', 'IPD', 'ER']) {
      if (value.startsWith(base)) {
        final period = value.substring(base.length);
        return _departmentRule(base, period);
      }
    }
    return null;
  }

  _ShiftRule? _departmentRule(String base, String period) {
    final display = switch (base) {
      'CTIPD' => 'CTIPD',
      'CTER' => 'CTER',
      _ => base,
    };
    if (period == 'เช้า') {
      return _ShiftRule(
        code: 'U$display',
        startHour: 8,
        startMinute: 0,
        endHour: 16,
        endMinute: 0,
      );
    }
    if (period == 'บ่าย') {
      final overnight = base != 'ER';
      return _ShiftRule(
        code: 'A$display',
        startHour: 16,
        startMinute: 0,
        endHour: overnight ? 8 : 0,
        endMinute: 0,
      );
    }
    if (period == 'ดึก' && base == 'ER') {
      return const _ShiftRule(
        code: 'NER',
        startHour: 0,
        startMinute: 0,
        endHour: 8,
        endMinute: 0,
      );
    }
    return null;
  }

  _ShiftRule? _threePartRule(String base, String period) => switch (period) {
    'เช้า' => _ShiftRule(
      code: 'U$base',
      startHour: 8,
      startMinute: 0,
      endHour: 16,
      endMinute: 0,
    ),
    'บ่าย' => _ShiftRule(
      code: 'A$base',
      startHour: 16,
      startMinute: 0,
      endHour: 0,
      endMinute: 0,
    ),
    'ดึก' => _ShiftRule(
      code: 'N$base',
      startHour: 0,
      startMinute: 0,
      endHour: 8,
      endMinute: 0,
    ),
    _ => null,
  };

  int? _dayNumber(Object? value) {
    final number = value is num
        ? value.toInt()
        : int.tryParse(value?.toString().trim() ?? '');
    return number != null && number >= 1 && number <= 31 ? number : null;
  }

  String _textAt(List<Object?> row, int index) =>
      index < row.length ? row[index]?.toString() ?? '' : '';

  String _normalizeLabel(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[\s.\-_]+'), '');

  String _compact(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();

  String _columnName(int column) {
    var current = column;
    var result = '';
    while (current > 0) {
      current--;
      result = String.fromCharCode(65 + current % 26) + result;
      current ~/= 26;
    }
    return result;
  }
}

class _ShiftRule {
  const _ShiftRule({
    required this.code,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.category = ShiftCategory.own,
  });

  final String code;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final ShiftCategory category;
}
