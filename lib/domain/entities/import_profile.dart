class ImportProfile {
  ImportProfile({
    required this.id,
    required this.name,
    required Map<String, String> columnMappings,
    required this.createdAt,
    required this.updatedAt,
  }) : columnMappings = Map.unmodifiable(columnMappings);

  final String id;
  final String name;
  final Map<String, String> columnMappings;
  final DateTime createdAt;
  final DateTime updatedAt;

  ImportProfile copyWith({
    String? id,
    String? name,
    Map<String, String>? columnMappings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImportProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      columnMappings: columnMappings ?? this.columnMappings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
