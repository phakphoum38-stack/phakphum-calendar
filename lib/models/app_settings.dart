class AppSettings {
  const AppSettings({
    required this.targetName,
    required this.year,
    required this.month,
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
      archiveOriginal: true,
      autoRefresh: false,
      refreshSeconds: 5,
      googleWebClientId: '',
    );
  }

  final String targetName;
  final int? year;
  final int? month;
  final bool archiveOriginal;
  final bool autoRefresh;
  final int refreshSeconds;
  final String googleWebClientId;

  AppSettings copyWith({
    String? targetName,
    int? year,
    int? month,
    bool? archiveOriginal,
    bool? autoRefresh,
    int? refreshSeconds,
    String? googleWebClientId,
  }) => AppSettings(
    targetName: targetName ?? this.targetName,
    year: year ?? this.year,
    month: month ?? this.month,
    archiveOriginal: archiveOriginal ?? this.archiveOriginal,
    autoRefresh: autoRefresh ?? this.autoRefresh,
    refreshSeconds: refreshSeconds ?? this.refreshSeconds,
    googleWebClientId: googleWebClientId ?? this.googleWebClientId,
  );

  AppSettings clearRosterSelection() => AppSettings(
    targetName: '',
    year: null,
    month: null,
    archiveOriginal: archiveOriginal,
    autoRefresh: autoRefresh,
    refreshSeconds: refreshSeconds,
    googleWebClientId: googleWebClientId,
  );
}
