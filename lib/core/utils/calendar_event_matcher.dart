/// Matches a roster shift to a pre-existing Calendar event without relying on
/// provider metadata.
class CalendarEventMatcher {
  const CalendarEventMatcher._();

  /// Removes trailing source codes such as `(UG)` from a user-facing event
  /// title while retaining the code in internal identities and metadata.
  static String calendarTitle(String value) {
    final trimmed = value.trim();
    final withoutCode = trimmed
        .replaceFirst(RegExp(r'(?:\s*\([^)]*\))+\s*$'), '')
        .trim();
    return withoutCode.isEmpty ? trimmed : withoutCode;
  }

  /// Returns true only when wall-clock ranges are identical and the normalized
  /// Calendar title represents the roster title or source label.
  static bool isEquivalent({
    required String rosterTitle,
    String? sourceLabel,
    required DateTime rosterStart,
    required DateTime rosterEnd,
    required String calendarTitle,
    required DateTime calendarStart,
    required DateTime calendarEnd,
  }) {
    if (!_sameWallTime(rosterStart, calendarStart) ||
        !_sameWallTime(rosterEnd, calendarEnd)) {
      return false;
    }
    final calendar = _normalizeTitle(calendarTitle);
    if (calendar.isEmpty) return false;
    final candidates = <String>{
      _normalizeTitle(rosterTitle),
      _normalizeTitle(sourceLabel ?? ''),
    }..removeWhere((value) => value.length < 2);
    return candidates.any(
      (candidate) =>
          calendar == candidate ||
          calendar.startsWith('$candidate ') ||
          candidate.startsWith('$calendar '),
    );
  }

  static bool _sameWallTime(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day &&
      left.hour == right.hour &&
      left.minute == right.minute &&
      left.second == right.second;

  static String _normalizeTitle(String value) => value
      .replaceAll(RegExp(r'\([^)]*\)'), ' ')
      .replaceAll(RegExp(r'[\[\]{}]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
}
