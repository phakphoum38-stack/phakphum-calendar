class AppSettings {
  const AppSettings({
    required this.sourceUrl,
    required this.targetName,
    required this.year,
    required this.month,
    required this.archiveOriginal,
    required this.autoRefresh,
    required this.refreshSeconds,
  });

  static const defaultSourceUrl =
      'https://docs.google.com/spreadsheets/d/'
      '1kppXtjpD6Vm5MIf58bIiQa5dQ0SDpC1xVnz-CrAwpSE/edit?gid=2123533299';

  factory AppSettings.defaults() => const AppSettings(
    sourceUrl: defaultSourceUrl,
    targetName: 'ภาคภูมิ',
    year: 2026,
    month: 8,
    archiveOriginal: true,
    autoRefresh: false,
    refreshSeconds: 5,
  );

  final String sourceUrl;
  final String targetName;
  final int year;
  final int month;
  final bool archiveOriginal;
  final bool autoRefresh;
  final int refreshSeconds;

  AppSettings copyWith({
    String? sourceUrl,
    String? targetName,
    int? year,
    int? month,
    bool? archiveOriginal,
    bool? autoRefresh,
    int? refreshSeconds,
  }) => AppSettings(
    sourceUrl: sourceUrl ?? this.sourceUrl,
    targetName: targetName ?? this.targetName,
    year: year ?? this.year,
    month: month ?? this.month,
    archiveOriginal: archiveOriginal ?? this.archiveOriginal,
    autoRefresh: autoRefresh ?? this.autoRefresh,
    refreshSeconds: refreshSeconds ?? this.refreshSeconds,
  );
}
