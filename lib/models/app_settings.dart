class AppSettings {
  const AppSettings({
    required this.sourceUrl,
    required this.targetName,
    required this.year,
    required this.month,
    required this.archiveOriginal,
    required this.autoRefresh,
    required this.refreshSeconds,
    required this.googleWebClientId,
  });

  static const defaultSourceUrl = '';

  factory AppSettings.defaults({DateTime? now}) {
    final current = now ?? DateTime.now();
    return AppSettings(
      sourceUrl: defaultSourceUrl,
      targetName: '',
      year: current.year,
      month: current.month,
      archiveOriginal: true,
      autoRefresh: false,
      refreshSeconds: 5,
      googleWebClientId: '',
    );
  }

  final String sourceUrl;
  final String targetName;
  final int year;
  final int month;
  final bool archiveOriginal;
  final bool autoRefresh;
  final int refreshSeconds;
  final String googleWebClientId;

  AppSettings copyWith({
    String? sourceUrl,
    String? targetName,
    int? year,
    int? month,
    bool? archiveOriginal,
    bool? autoRefresh,
    int? refreshSeconds,
    String? googleWebClientId,
  }) => AppSettings(
    sourceUrl: sourceUrl ?? this.sourceUrl,
    targetName: targetName ?? this.targetName,
    year: year ?? this.year,
    month: month ?? this.month,
    archiveOriginal: archiveOriginal ?? this.archiveOriginal,
    autoRefresh: autoRefresh ?? this.autoRefresh,
    refreshSeconds: refreshSeconds ?? this.refreshSeconds,
    googleWebClientId: googleWebClientId ?? this.googleWebClientId,
  );
}
