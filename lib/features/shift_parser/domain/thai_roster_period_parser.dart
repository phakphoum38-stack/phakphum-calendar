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

  /// ชื่อเดือนทั้งหมดถูกเก็บในรูปแบบที่ตัดจุดและช่องว่างแล้ว
  ///
  /// ตัวอย่าง:
  /// - ก.ค. -> กค
  /// - กค.  -> กค
  /// - กรกฎาคม -> กรกฎาคม
  static const Map<String, int> _months = <String, int>{
    'มกราคม': 1,
    'มค': 1,
    'กุมภาพันธ์': 2,
    'กพ': 2,
    'มีนาคม': 3,
    'มีค': 3,
    'เมษายน': 4,
    'เมย': 4,
    'พฤษภาคม': 5,
    'พค': 5,
    'มิถุนายน': 6,
    'มิย': 6,
    'กรกฎาคม': 7,
    'กค': 7,
    'สิงหาคม': 8,
    'สค': 8,
    'กันยายน': 9,
    'กย': 9,
    'ตุลาคม': 10,
    'ตค': 10,
    'พฤศจิกายน': 11,
    'พย': 11,
    'ธันวาคม': 12,
    'ธค': 12,
  };

  ThaiRosterPeriod parse(String text) {
    final normalizedText = _normalizeText(text);

    /*
     * รองรับตัวอย่าง:
     *
     * 16 กรกฎาคม 2569
     * 16 กรกฎาคม พ.ศ. 2569
     * 16 ก.ค. 69
     * 16 กค69
     * 16 กค.69
     * 15 สค.69
     *
     * กลุ่มข้อมูล:
     * 1 = วัน
     * 2 = เดือนภาษาไทย
     * 3 = ปี
     */
    final datePattern = RegExp(
      r'(\d{1,2})\s*'
      r'([\u0E01-\u0E5B.]+?)'
      r'\s*(\d{2,4})',
    );

    final matches = datePattern.allMatches(normalizedText).toList();

    if (matches.length < 2) {
      throw FormatException(
        'ไม่พบช่วงวันที่ในข้อความ: $text',
      );
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

  String _normalizeText(String text) {
    return text
        // พ.ศ. / พ. ศ. / พศ / พศ.
        .replaceAll(
          RegExp(r'พ\s*\.\s*ศ\s*\.?'),
          '',
        )
        .replaceAll(
          RegExp(r'พ\s*ศ\s*\.?'),
          '',
        )

        // เปลี่ยนขีดชนิดต่าง ๆ ให้เป็นขีดมาตรฐาน
        .replaceAll(
          RegExp(r'[–—−]'),
          '-',
        )

        // รวมช่องว่างซ้ำ
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  DateTime _readDate(RegExpMatch match) {
    final dayText = match.group(1);
    final rawMonthText = match.group(2);
    final yearText = match.group(3);

    if (dayText == null ||
        rawMonthText == null ||
        yearText == null) {
      throw const FormatException(
        'ข้อมูลวันที่ไม่ครบถ้วน',
      );
    }

    final day = int.tryParse(dayText);

    if (day == null) {
      throw FormatException(
        'วันไม่ถูกต้อง: $dayText',
      );
    }

    final monthText = _normalizeMonth(rawMonthText);
    final month = _months[monthText];

    if (month == null) {
      throw FormatException(
        'ไม่รู้จักเดือนไทย: $rawMonthText',
      );
    }

    final parsedYear = int.tryParse(yearText);

    if (parsedYear == null) {
      throw FormatException(
        'ปีไม่ถูกต้อง: $yearText',
      );
    }

    final year = _toGregorianYear(parsedYear);

    final date = DateTime(
      year,
      month,
      day,
    );

    // DateTime จะปรับวันที่เกินเดือนไปเดือนถัดไปอัตโนมัติ
    // จึงต้องตรวจสอบค่าที่สร้างแล้วอีกครั้ง
    if (date.year != year ||
        date.month != month ||
        date.day != day) {
      throw FormatException(
        'วันที่ไม่ถูกต้อง: $dayText $rawMonthText $yearText',
      );
    }

    return date;
  }

  String _normalizeMonth(String monthText) {
    return monthText
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
  }

  int _toGregorianYear(int year) {
    var resolvedYear = year;

    // ปี พ.ศ. แบบ 2 หลัก เช่น 69 -> 2569
    if (resolvedYear >= 0 && resolvedYear < 100) {
      resolvedYear += 2500;
    }

    // แปลงปี พ.ศ. เป็น ค.ศ.
    if (resolvedYear >= 2400) {
      resolvedYear -= 543;
    }

    return resolvedYear;
  }
}
