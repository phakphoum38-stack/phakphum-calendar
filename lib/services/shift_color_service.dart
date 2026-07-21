import '../models/shift.dart';

class RosterColorMatch {
  const RosterColorMatch({
    required this.sourceName,
    required this.category,
    this.requiresReview = false,
  });

  final String sourceName;
  final ShiftCategory category;
  final bool requiresReview;
}

class ShiftColorService {
  const ShiftColorService();

  static RosterColorMatch? classify(int? colorValue) {
    if (colorValue == null) return null;
    _RosterColorSwatch? closest;
    var closestDistance = 1 << 30;
    for (final swatch in _swatches) {
      final distance = _distance(colorValue, swatch.colorValue);
      if (distance < closestDistance) {
        closest = swatch;
        closestDistance = distance;
      }
    }
    if (closest == null || closestDistance > 1800) return null;
    return RosterColorMatch(
      sourceName: closest.sourceName,
      category: closest.category,
      requiresReview: closest.requiresReview,
    );
  }

  static int _distance(int left, int right) {
    final red = ((left >> 16) & 0xFF) - ((right >> 16) & 0xFF);
    final green = ((left >> 8) & 0xFF) - ((right >> 8) & 0xFF);
    final blue = (left & 0xFF) - (right & 0xFF);
    return red * red + green * green + blue * blue;
  }

  static const _swatches = <_RosterColorSwatch>[
    _RosterColorSwatch(0xFF616161, 'กราไฟต์', ShiftCategory.own),
    _RosterColorSwatch(0xFFE1E1E1, 'กราไฟต์', ShiftCategory.own),
    _RosterColorSwatch(0xFFB7B7B7, 'กราไฟต์', ShiftCategory.own),
    _RosterColorSwatch(0xFFD50000, 'มะเขือเทศ', ShiftCategory.other),
    _RosterColorSwatch(0xFFDC2127, 'มะเขือเทศ', ShiftCategory.other),
    _RosterColorSwatch(0xFFE67C73, 'มะเขือเทศ', ShiftCategory.other),
    _RosterColorSwatch(0xFFF4CCCC, 'มะเขือเทศ', ShiftCategory.other),
    _RosterColorSwatch(0xFF039BE5, 'ฟ้า', ShiftCategory.clinic),
    _RosterColorSwatch(0xFF5484ED, 'ฟ้า', ShiftCategory.clinic),
    _RosterColorSwatch(0xFF4285F4, 'ฟ้า', ShiftCategory.clinic),
    _RosterColorSwatch(0xFF8E24AA, 'เผือก', ShiftCategory.specialClinic),
    _RosterColorSwatch(0xFFDBADFF, 'เผือก', ShiftCategory.specialClinic),
    _RosterColorSwatch(0xFFB39DDB, 'เผือก', ShiftCategory.specialClinic),
    _RosterColorSwatch(
      0xFF7986CB,
      'ลาเวนเดอร์',
      ShiftCategory.given,
      requiresReview: true,
    ),
    _RosterColorSwatch(
      0xFFA4BDFC,
      'ลาเวนเดอร์',
      ShiftCategory.given,
      requiresReview: true,
    ),
    _RosterColorSwatch(0xFFF6BF26, 'กล้วยหอม', ShiftCategory.borrowedUnpaid),
    _RosterColorSwatch(0xFFFBD75B, 'กล้วยหอม', ShiftCategory.borrowedUnpaid),
    _RosterColorSwatch(0xFFFFE599, 'กล้วยหอม', ShiftCategory.borrowedUnpaid),
    _RosterColorSwatch(0xFF33B679, 'นกแก้ว', ShiftCategory.borrowedPaid),
    _RosterColorSwatch(0xFF51B749, 'นกแก้ว', ShiftCategory.borrowedPaid),
    _RosterColorSwatch(0xFF7AE7BF, 'นกแก้ว', ShiftCategory.borrowedPaid),
  ];
}

class _RosterColorSwatch {
  const _RosterColorSwatch(
    this.colorValue,
    this.sourceName,
    this.category, {
    this.requiresReview = false,
  });

  final int colorValue;
  final String sourceName;
  final ShiftCategory category;
  final bool requiresReview;
}
