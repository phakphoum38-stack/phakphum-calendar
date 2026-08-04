class ThaiRosterPeriod {
  const ThaiRosterPeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class ThaiRosterPeriodParser {
  const ThaiRosterPeriodParser();

  static const Map<String, int> _months = <String, int>{
    'มกราคม': 1,
    'ม.ค.': 1,
    'มค': 1,
    'กุมภาพันธ์': 2,
    'ก.พ.': 2,
    'กพ': 2,
    'มีนาคม': 3,
    'มี.ค.': 3,
    'มีค': 3,
    'เมษายน': 4,
    'เม.ย.': 4,
    'เมย': 4,
    'พฤษภาคม': 5,
    'พ.ค.': 5,
    'พค': 5,
    'มิถุนายน': 6,
    'มิ.ย.': 6,
    'มิย': 6,
    'กรกฎาคม': 7,
    'ก.ค.': 7,
    'กค': 7,
    'สิงหาคม': 8,
    'ส.ค.': 8,
    'สค': 8,
    'กันยายน': 9,
    'ก.ย.': 9,
    'กย': 9,
    'ตุลาคม': 10,
    'ต.ค.': 10,
    'ตค': 10,
    'พฤศจิกายน': 11,
    'พ.ย.': 11,
    'พย': 11,
    'ธันวาคม': 12,
    'ธ.ค.': 12,
    'ธค': 12,
  };

  ThaiRosterPeriod parse(String text) {
    final normalized = text
        .replaceAll('พ.ศ.', '')
        .replaceAll('พ.ศ', '')
        .replaceAll('พศ.', '')
        .replaceAll('พศ', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final tokens = RegExp(
      r'(\d{1,2})\s*([ก-๙.]+)(?:\s*(\d{2,4}))?',
    ).allMatches(normalized).toList();

    if (tokens.length < 2) {
      throw FormatException('ไม่พบช่วงวันที่ในข้อความ: $text');
    }

    final startToken = _readToken(tokens.first);
    final endToken = _readToken(tokens[1]);
    final years = _resolveYears(startToken: startToken, endToken: endToken);

    final start = _checkedDate(
      year: years.$1,
      month: startToken.month,
      day: startToken.day,
      source: text,
    );
    final end = _checkedDate(
      year: years.$2,
      month: endToken.month,
      day: endToken.day,
      source: text,
    );

    if (end.isBefore(start)) {
      throw FormatException('วันสิ้นสุดอยู่ก่อนวันเริ่มต้น: $text');
    }

    return ThaiRosterPeriod(start: start, end: end);
  }

  _DateToken _readToken(RegExpMatch match) {
    final day = int.parse(match.group(1)!);
    final monthText = match.group(2)!.trim();
    final normalizedMonth = monthText.replaceAll('.', '');
    final month = _months[monthText] ?? _months[normalizedMonth];
    if (month == null) {
      throw FormatException('ไม่รู้จักเดือนไทย: $monthText');
    }

    final rawYear = match.group(3);
    return _DateToken(
      day: day,
      month: month,
      year: rawYear == null ? null : _normalizeYear(int.parse(rawYear)),
    );
  }

  (int, int) _resolveYears({
    required _DateToken startToken,
    required _DateToken endToken,
  }) {
    final explicitStartYear = startToken.year;
    final explicitEndYear = endToken.year;

    if (explicitStartYear == null && explicitEndYear == null) {
      throw const FormatException('ช่วงวันที่ต้องระบุปีอย่างน้อยหนึ่งครั้ง');
    }

    if (explicitStartYear != null && explicitEndYear != null) {
      return (explicitStartYear, explicitEndYear);
    }

    if (explicitEndYear != null) {
      final startYear = startToken.month > endToken.month
          ? explicitEndYear - 1
          : explicitEndYear;
      return (startYear, explicitEndYear);
    }

    final startYear = explicitStartYear!;
    final endYear = endToken.month < startToken.month
        ? startYear + 1
        : startYear;
    return (startYear, endYear);
  }

  int _normalizeYear(int year) {
    if (year < 100) year += 2500;
    if (year >= 2400) year -= 543;
    return year;
  }

  DateTime _checkedDate({
    required int year,
    required int month,
    required int day,
    required String source,
  }) {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException('วันที่ไม่มีอยู่จริงในปฏิทิน: $source');
    }
    return date;
  }
}

class _DateToken {
  const _DateToken({required this.day, required this.month, this.year});

  final int day;
  final int month;
  final int? year;
}
