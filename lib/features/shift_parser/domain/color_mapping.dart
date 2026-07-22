import '../../google_sheets/domain/sheet_color.dart';

enum ShiftColorMeaning {
  ownShift,
  otherPersonShift,
  clinicShift,
  majorExchange,
  clinicExchange,
  borrowedFree,
  borrowedPaid,
  givenAway,
  unknown,
}

class ShiftColorRule {
  const ShiftColorRule({
    required this.name,
    required this.meaning,
    required this.color,
    this.tolerance = 0.0025,
  });

  final String name;
  final ShiftColorMeaning meaning;
  final SheetColor color;
  final double tolerance;

  bool matches(SheetColor candidate) =>
      color.distanceTo(candidate) <= tolerance;
}

class ShiftColorMapping {
  const ShiftColorMapping(this.rules);

  final List<ShiftColorRule> rules;

  ShiftColorMeaning resolve(SheetColor? color) {
    if (color == null) {
      return ShiftColorMeaning.unknown;
    }

    for (final rule in rules) {
      if (rule.matches(color)) {
        return rule.meaning;
      }
    }

    return ShiftColorMeaning.unknown;
  }
}
