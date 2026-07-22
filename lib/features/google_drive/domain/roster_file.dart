class RosterFile {
  const RosterFile({
    required this.id,
    required this.name,
    this.modifiedTime,
    this.webViewLink,
  });

  final String id;
  final String name;
  final DateTime? modifiedTime;
  final String? webViewLink;
}
