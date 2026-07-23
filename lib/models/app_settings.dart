import 'roster_period.dart';

class AppSettings {
  const AppSettings({
    required this.targetName,
    required this.year,
    required this.month,
    this.periods = const [],
    required this.archiveOriginal,
    required this.autoRefresh,
    required this.refreshSeconds,
    required this.googleWebClientId,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      targetName: '',
      year: null,
      month: null,
      periods: [],
      archiveOriginal: true,
      autoRefresh: false,
      refreshSeconds: 5,
      googleWebClientId: '',
    );
  }

  final String targetName;
  final int? year;
  final int? month;
  final List<RosterPeriod> periods;
  final bool archiveOriginal;
  final bool autoRefresh;
  final int refreshSeconds;
  final String googleWebClientId;

  List<RosterPeriod> get effectivePeriods {
    if (periods.isNotEmpty) {
      final unique = periods.toSet().toList()
        ..sort((left, right) => left.key.compareTo(right.key));
      return List.unmodifiable(unique);
    }
    if (year == null || month == null) return const [];
    return [RosterPeriod(year: year!, month: month!)];
  }

  AppSettings copyWith({
    String? targetName,
    int? year,
    int? month,
    List<RosterPeriod>? periods,
    bool? archiveOriginal,
    bool? autoRefresh,
    int? refreshSeconds,
    String? googleWebClientId,
  }) => AppSettings(
    targetName: targetName ?? this.targetName,
    year: year ?? this.year,
    month: month ?? this.month,
    periods: periods ?? this.periods,
    archiveOriginal: archiveOriginal ?? this.archiveOriginal,
    autoRefresh: autoRefresh ?? this.autoRefresh,
    refreshSeconds: refreshSeconds ?? this.refreshSeconds,
    googleWebClientId: googleWebClientId ?? this.googleWebClientId,
  );

  AppSettings clearRosterSelection() => AppSettings(
    targetName: '',
    year: null,
    month: null,
    periods: const [],
    archiveOriginal: archiveOriginal,
    autoRefresh: autoRefresh,
    refreshSeconds: refreshSeconds,
    googleWebClientId: googleWebClientId,
  );
}
