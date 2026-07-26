class ColumnMapping {
  const ColumnMapping({
    this.dateColumn,
    this.shiftColumn,
    this.employeeColumn,
    this.departmentColumn,
    this.locationColumn,
    this.notesColumn,
  });

  static const _unchanged = Object();

  final String? dateColumn;
  final String? shiftColumn;
  final String? employeeColumn;
  final String? departmentColumn;
  final String? locationColumn;
  final String? notesColumn;

  ColumnMapping copyWith({
    Object? dateColumn = _unchanged,
    Object? shiftColumn = _unchanged,
    Object? employeeColumn = _unchanged,
    Object? departmentColumn = _unchanged,
    Object? locationColumn = _unchanged,
    Object? notesColumn = _unchanged,
  }) {
    return ColumnMapping(
      dateColumn: identical(dateColumn, _unchanged)
          ? this.dateColumn
          : dateColumn as String?,
      shiftColumn: identical(shiftColumn, _unchanged)
          ? this.shiftColumn
          : shiftColumn as String?,
      employeeColumn: identical(employeeColumn, _unchanged)
          ? this.employeeColumn
          : employeeColumn as String?,
      departmentColumn: identical(departmentColumn, _unchanged)
          ? this.departmentColumn
          : departmentColumn as String?,
      locationColumn: identical(locationColumn, _unchanged)
          ? this.locationColumn
          : locationColumn as String?,
      notesColumn: identical(notesColumn, _unchanged)
          ? this.notesColumn
          : notesColumn as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'dateColumn': dateColumn,
    'shiftColumn': shiftColumn,
    'employeeColumn': employeeColumn,
    'departmentColumn': departmentColumn,
    'locationColumn': locationColumn,
    'notesColumn': notesColumn,
  };

  factory ColumnMapping.fromJson(Map<String, Object?> json) {
    return ColumnMapping(
      dateColumn: json['dateColumn'] as String?,
      shiftColumn: json['shiftColumn'] as String?,
      employeeColumn: json['employeeColumn'] as String?,
      departmentColumn: json['departmentColumn'] as String?,
      locationColumn: json['locationColumn'] as String?,
      notesColumn: json['notesColumn'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ColumnMapping &&
            dateColumn == other.dateColumn &&
            shiftColumn == other.shiftColumn &&
            employeeColumn == other.employeeColumn &&
            departmentColumn == other.departmentColumn &&
            locationColumn == other.locationColumn &&
            notesColumn == other.notesColumn;
  }

  @override
  int get hashCode => Object.hash(
    dateColumn,
    shiftColumn,
    employeeColumn,
    departmentColumn,
    locationColumn,
    notesColumn,
  );
}
