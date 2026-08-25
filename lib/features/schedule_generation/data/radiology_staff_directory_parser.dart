import '../../../domain/entities/employee.dart';
import '../../../models/shift.dart';
import '../domain/staff_directory.dart';
import '../domain/staff_group.dart';

/// Reads the master personnel workbook without retaining phone numbers.
///
/// Monthly personnel files can later implement the same directory boundary;
/// the roster generator only consumes [StaffDirectory].
class RadiologyStaffDirectoryParser {
  const RadiologyStaffDirectoryParser();

  StaffDirectory parse(List<SheetSnapshot> snapshots) {
    final byTitle = {
      for (final snapshot in snapshots) snapshot.title.trim(): snapshot,
    };
    final groups = <StaffGroup, List<Employee>>{};

    for (final group in StaffGroup.values) {
      final snapshot = byTitle[group.sourceSheetTitle];
      groups[group] = snapshot == null
          ? const <Employee>[]
          : _employees(group, _namesFromDirectory(snapshot));
    }

    final inChargeNames = _inChargeNames(byTitle['อินชาร์จ']);
    final eligibleIds = groups[StaffGroup.radiologicTechnologist]!
        .where(
          (employee) => inChargeNames.contains(_normalize(employee.fullName)),
        )
        .map((employee) => employee.id)
        .toSet();

    return StaffDirectory(
      groups: groups,
      inChargeEligibleEmployeeIds: eligibleIds,
    );
  }

  List<Employee> _employees(StaffGroup group, List<String> names) {
    final department = StaffDirectory.departmentFor(group);
    return [
      for (var index = 0; index < names.length; index++)
        Employee(
          id: '${group.id}:${_identifier(names[index])}',
          employeeCode:
              '${group.code}-${(index + 1).toString().padLeft(3, '0')}',
          firstName: names[index],
          lastName: '',
          nickname: '',
          department: department,
          position: group.thaiName,
        ),
    ];
  }

  List<String> _namesFromDirectory(SheetSnapshot snapshot) {
    final names = <String>{};
    for (final row in snapshot.rows) {
      for (final value in row) {
        if (value == null) continue;
        final text = '$value'.trim();
        if (_isPersonName(text)) names.add(_cleanName(text));
      }
    }
    return names.toList(growable: false);
  }

  Set<String> _inChargeNames(SheetSnapshot? snapshot) {
    if (snapshot == null) return const {};
    final names = <String>{};
    for (final row in snapshot.rows.take(10)) {
      for (final value in row) {
        final match = RegExp(r'^\s*\d{1,2}\s+(.+?)\s*$').firstMatch('$value');
        if (match != null) names.add(_normalize(match.group(1)!));
      }
    }
    return names;
  }

  bool _isPersonName(String value) =>
      value.isNotEmpty &&
      !_phonePattern.hasMatch(value.replaceAll(' ', '')) &&
      RegExp(r'[ก-๙A-Za-z]').hasMatch(value);

  String _cleanName(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _normalize(String value) => _cleanName(
    value,
  ).replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').toLowerCase();

  String _identifier(String value) => _normalize(value).replaceAll(' ', '-');

  static final _phonePattern = RegExp(r'^\+?\d[\d-]{7,}$');
}
