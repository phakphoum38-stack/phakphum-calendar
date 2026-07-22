class ThaiRosterPeriod {
  const ThaiRosterPeriod({
    required this.start,
    required this.end,
  });

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
    final normalized = _normalize(text);

    final matches = RegExp(
      r'(\d{1,2})\s*'
      r'(มกราคม|ม\.ค\.|มค|'
      r'กุมภาพันธ์|ก\.พ\.|กพ|'
      r'มีนาคม|มี\.ค\.|มีค|'
      r'เมษายน|เม\.ย\.|เมย|'
      r'พฤษภาคม|พ\.ค\.|พค|'
      r'มิถุนายน|มิ\.ย\.|มิย|'
      r'กรกฎาคม|ก\.ค\.|กค|'
      r'สิงหาคม|ส\.ค\.|สค|'
      r'กันยายน|ก\.ย\.|กย|'
      r'ตุลาคม|ต\.ค\.|ตค|'
      r'พฤศจิกายน|พ\.ย\.|พย|'
      r'ธันวาคม|ธ\.ค\.|ธค)'
      r'\s*(\d{2,4})',
    ).allMatches(normalized).toList();

    if (matches.length < 2) {
      throw FormatException('ไม่พบช่วงวันที่ในข้อความ: $text');
    }

    final start = _readDate(matches[0]);
    final end = _readDate(matches[1]);

    if (end.isBefore(start)) {
      throw FormatException(
        'วันที่สิ้นสุดอยู่ก่อนวันที่เริ่มต้น: $text',
      );
    }

    return ThaiRosterPeriod(
      start: start,
      end: end,
    );
  }

  String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'พ\s*\.\s*ศ\s*\.?'), '')
        .replaceAll(RegExp(r'พ\s*ศ\s*\.?'), '')
        .replaceAll(RegExp(r'[–—−]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime _readDate(RegExpMatch match) {
    final dayText = match.group(1);
    final monthText = match.group(2);
    final yearText = match.group(3);

    if (dayText == null || monthText == null || yearText == null) {
      throw const FormatException('ข้อมูลวันที่ไม่ครบ');
    }

    final day = int.parse(dayText);
    final month = _months[monthText];

    if (month == null) {
      throw FormatException('ไม่รู้จักเดือนไทย: $monthText');
    }

    var year = int.parse(yearText);

    if (year < 100) {
      year += 2500;
    }

    if (year >= 2400) {
      year -= 543;
    }

    final date = DateTime(year, month, day);

    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException(
        'วันที่ไม่ถูกต้อง: $dayText $monthText $yearText',
      );
    }

    return date;
  }
}
