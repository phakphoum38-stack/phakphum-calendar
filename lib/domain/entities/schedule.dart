import 'schedule_month.dart';

/// Canonical schedule aggregate for all new scheduling code.
///
/// Legacy and provider-specific records enter and leave this aggregate through
/// explicit adapters so their compatibility metadata does not leak into the
/// scheduling domain.
class Schedule {
  Schedule({
    required this.id,
    required this.name,
    List<ScheduleMonth> months = const [],
  }) : months = List.unmodifiable(months);

  final String id;
  final String name;
  final List<ScheduleMonth> months;

  ScheduleMonth? month(DateTime date) {
    for (final month in months) {
      if (month.month.year == date.year && month.month.month == date.month) {
        return month;
      }
    }
    return null;
  }

  Schedule copyWith({String? id, String? name, List<ScheduleMonth>? months}) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      months: months ?? this.months,
    );
  }

  Schedule replaceMonth(ScheduleMonth updatedMonth) {
    final hasMonth = months.any(
      (month) =>
          month.month.year == updatedMonth.month.year &&
          month.month.month == updatedMonth.month.month,
    );
    return copyWith(
      months: [
        for (final month in months)
          if (month.month.year == updatedMonth.month.year &&
              month.month.month == updatedMonth.month.month)
            updatedMonth
          else
            month,
        if (!hasMonth) updatedMonth,
      ],
    );
  }
}
