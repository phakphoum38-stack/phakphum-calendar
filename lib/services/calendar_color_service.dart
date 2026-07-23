class CalendarColorOption {
  const CalendarColorOption({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.aliases,
  });

  final String id;
  final String name;
  final int colorValue;
  final List<String> aliases;
}

class CalendarColorService {
  const CalendarColorService();

  static const options = <CalendarColorOption>[
    CalendarColorOption(
      id: '1',
      name: 'ลาเวนเดอร์',
      colorValue: 0xFF7986CB,
      aliases: ['lavender', 'ม่วงอ่อน'],
    ),
    CalendarColorOption(
      id: '2',
      name: 'เซจ',
      colorValue: 0xFF33B679,
      aliases: ['sage', 'เขียวอ่อน'],
    ),
    CalendarColorOption(
      id: '3',
      name: 'องุ่น',
      colorValue: 0xFF8E24AA,
      aliases: ['grape', 'ม่วง'],
    ),
    CalendarColorOption(
      id: '4',
      name: 'ฟลามิงโก',
      colorValue: 0xFFE67C73,
      aliases: ['flamingo', 'ชมพู'],
    ),
    CalendarColorOption(
      id: '5',
      name: 'กล้วย',
      colorValue: 0xFFF6BF26,
      aliases: ['banana', 'เหลือง'],
    ),
    CalendarColorOption(
      id: '6',
      name: 'ส้ม',
      colorValue: 0xFFF4511E,
      aliases: ['tangerine', 'orange'],
    ),
    CalendarColorOption(
      id: '7',
      name: 'นกยูง',
      colorValue: 0xFF039BE5,
      aliases: ['peacock', 'ฟ้า'],
    ),
    CalendarColorOption(
      id: '8',
      name: 'กราไฟต์',
      colorValue: 0xFF616161,
      aliases: ['graphite', 'เทา'],
    ),
    CalendarColorOption(
      id: '9',
      name: 'บลูเบอร์รี',
      colorValue: 0xFF3F51B5,
      aliases: ['blueberry', 'น้ำเงิน'],
    ),
    CalendarColorOption(
      id: '10',
      name: 'โหระพา',
      colorValue: 0xFF0B8043,
      aliases: ['basil', 'เขียว'],
    ),
    CalendarColorOption(
      id: '11',
      name: 'มะเขือเทศ',
      colorValue: 0xFFD50000,
      aliases: ['tomato', 'แดง'],
    ),
  ];

  static CalendarColorOption? byId(String? id) {
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  static CalendarColorOption? parseCommand(String command) {
    final value = command.trim().toLowerCase().replaceFirst(
      RegExp(r'^(สี|color)\s*[:=]?\s*'),
      '',
    );
    if (value.isEmpty || value == 'default' || value == 'ค่าเริ่มต้น') {
      return null;
    }
    for (final option in options) {
      if (value == option.id ||
          value == option.name.toLowerCase() ||
          option.aliases.any((alias) => value == alias.toLowerCase())) {
        return option;
      }
    }
    throw const FormatException(
      'ไม่พบสีตามคำสั่ง กรุณาใช้เลข 1–11 หรือชื่อสีที่แสดง',
    );
  }
}
