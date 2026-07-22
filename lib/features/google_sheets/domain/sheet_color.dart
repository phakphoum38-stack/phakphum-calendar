class SheetColor {
  const SheetColor({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 1,
  });

  final double red;
  final double green;
  final double blue;
  final double alpha;

  int get red255 => (red.clamp(0, 1) * 255).round();
  int get green255 => (green.clamp(0, 1) * 255).round();
  int get blue255 => (blue.clamp(0, 1) * 255).round();
  int get alpha255 => (alpha.clamp(0, 1) * 255).round();

  String get hex {
    String channel(int value) =>
        value.toRadixString(16).padLeft(2, '0').toUpperCase();

    return '#${channel(red255)}${channel(green255)}${channel(blue255)}';
  }

  double distanceTo(SheetColor other) {
    final redDifference = red - other.red;
    final greenDifference = green - other.green;
    final blueDifference = blue - other.blue;

    return (redDifference * redDifference) +
        (greenDifference * greenDifference) +
        (blueDifference * blueDifference);
  }

  @override
  bool operator ==(Object other) {
    return other is SheetColor &&
        other.red == red &&
        other.green == green &&
        other.blue == blue &&
        other.alpha == alpha;
  }

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);
}
