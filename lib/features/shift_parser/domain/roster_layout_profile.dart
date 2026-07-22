class RosterLayoutProfile {
  const RosterLayoutProfile({
    required this.profileId,
    required this.profileName,
    required this.dateHeaderRows,
    required this.nameColumns,
    required this.shiftLabelColumns,
    required this.dataStartRow,
    this.dataEndRow,
    this.acceptedDatePatterns = const <String>[],
    this.userAliases = const <String>[],
  });

  final String profileId;
  final String profileName;
  final List<int> dateHeaderRows;
  final List<int> nameColumns;
  final List<int> shiftLabelColumns;
  final int dataStartRow;
  final int? dataEndRow;
  final List<String> acceptedDatePatterns;
  final List<String> userAliases;

  bool get isConfigured =>
      dateHeaderRows.isNotEmpty &&
      nameColumns.isNotEmpty &&
      shiftLabelColumns.isNotEmpty;
}
