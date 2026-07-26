import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_day.dart';
import '../../../domain/entities/shift_assignment.dart';
import '../../../domain/entities/shift_type.dart';
import '../domain/monthly_report_options.dart';
import '../domain/monthly_schedule_report.dart';
import '../domain/report_labels.dart';

/// Maps a canonical schedule into one deterministic monthly report model.
class MonthlyScheduleReportMapper {
  const MonthlyScheduleReportMapper();

  MonthlyScheduleReport map(Schedule schedule, MonthlyReportOptions options) {
    final labels = ReportLabels.forLanguageCode(options.languageCode);
    final month = DateTime(options.month.year, options.month.month);
    final sourceMonth = schedule.month(month);
    final days = sourceMonth?.days.toList() ?? _emptyDays(month);
    days.sort((left, right) => left.date.compareTo(right.date));

    final assignments = <({ScheduleDay day, ShiftAssignment assignment})>[];
    for (final day in days) {
      for (final assignment in day.assignments) {
        if (options.departmentId != null &&
            assignment.employee.department.id != options.departmentId) {
          continue;
        }
        assignments.add((day: day, assignment: assignment));
      }
    }

    _validateEmployeeIdentity(assignments);
    final employeeEntries =
        <String, List<({ScheduleDay day, ShiftAssignment assignment})>>{};
    for (final entry in assignments) {
      employeeEntries
          .putIfAbsent(entry.assignment.employee.id, () => [])
          .add(entry);
    }
    final orderedEmployees = employeeEntries.entries.toList()
      ..sort((left, right) {
        final leftEmployee = left.value.first.assignment.employee;
        final rightEmployee = right.value.first.assignment.employee;
        return _compareText(
              leftEmployee.department.name,
              rightEmployee.department.name,
            )
            .nonZeroOr(
              () => _compareText(
                leftEmployee.displayName,
                rightEmployee.displayName,
              ),
            )
            .nonZeroOr(() => left.key.compareTo(right.key));
      });

    final rows = [
      for (final employeeEntry in orderedEmployees)
        _employeeRow(employeeEntry, days),
    ];
    final shifts = <String, ShiftType>{};
    for (final entry in assignments) {
      shifts[entry.assignment.shift.id] = entry.assignment.shift;
    }
    final legend = shifts.values.map(_legendEntry).toList()
      ..sort((left, right) {
        return _compareText(
          left.code,
          right.code,
        ).nonZeroOr(() => left.shiftId.compareTo(right.shiftId));
      });

    final departmentName = options.departmentId == null || assignments.isEmpty
        ? null
        : assignments.first.assignment.employee.department.name;

    return MonthlyScheduleReport(
      metadata: ReportMetadata(
        title: options.titleOverride?.trim().isNotEmpty == true
            ? options.titleOverride!.trim()
            : labels.defaultTitle,
        scheduleName: schedule.name,
        month: month,
        generatedAt: options.generatedAt,
        departmentName: departmentName,
      ),
      dates: [
        for (final day in days)
          ReportDateColumn(
            date: day.date,
            dayLabel: labels.shortWeekdays[day.date.weekday - 1],
            isWeekend:
                day.date.weekday == DateTime.saturday ||
                day.date.weekday == DateTime.sunday,
            holidayName: day.holidayName,
          ),
      ],
      rows: List.unmodifiable(rows),
      legend: List.unmodifiable(legend),
      statistics: _statistics(
        assignments,
        rows,
        includeDepartmentTotals: options.departmentId == null,
      ),
      notes: options.includeNotes ? _notes(assignments) : const [],
      signatureLabels: [
        labels.preparedBy,
        labels.checkedBy,
        labels.approvedBy,
        labels.date,
      ],
    );
  }

  List<ScheduleDay> _emptyDays(DateTime month) {
    final count = DateTime(month.year, month.month + 1, 0).day;
    return [
      for (var day = 1; day <= count; day++)
        ScheduleDay(date: DateTime(month.year, month.month, day)),
    ];
  }

  ReportEmployeeRow _employeeRow(
    MapEntry<String, List<({ScheduleDay day, ShiftAssignment assignment})>>
    entry,
    List<ScheduleDay> days,
  ) {
    final employee = entry.value.first.assignment.employee;
    final byDate =
        <DateTime, List<({ScheduleDay day, ShiftAssignment assignment})>>{};
    for (final assignment in entry.value) {
      byDate.putIfAbsent(assignment.day.date, () => []).add(assignment);
    }
    return ReportEmployeeRow(
      employeeId: employee.id,
      employeeName: employee.displayName,
      departmentId: employee.department.id,
      departmentName: employee.department.name,
      position: employee.position,
      cells: [
        for (final day in days) _cell(day.date, byDate[day.date] ?? const []),
      ],
      assignmentCount: entry.value.length,
    );
  }

  ReportScheduleCell _cell(
    DateTime date,
    List<({ScheduleDay day, ShiftAssignment assignment})> assignments,
  ) {
    final ordered = assignments.toList()
      ..sort((left, right) {
        return _compareText(
              left.assignment.shift.code,
              right.assignment.shift.code,
            )
            .nonZeroOr(
              () =>
                  left.assignment.shift.id.compareTo(right.assignment.shift.id),
            )
            .nonZeroOr(
              () => (left.assignment.location ?? '').compareTo(
                right.assignment.location ?? '',
              ),
            );
      });
    return ReportScheduleCell(
      date: date,
      shiftLabels: [
        for (final entry in ordered) _shiftLabel(entry.assignment.shift),
      ],
      locations: _unique([
        for (final entry in ordered) entry.assignment.location,
      ]),
      notes: _unique([for (final entry in ordered) entry.assignment.remark]),
    );
  }

  String _shiftLabel(ShiftType shift) {
    final code = shift.code.trim();
    return code.isEmpty ? shift.name.trim() : code;
  }

  ReportShiftLegendEntry _legendEntry(ShiftType shift) {
    final reliableTime =
        shift.workingHours > 0 &&
        shift.workingHours <= 24 &&
        shift.startTime != shift.endTime;
    return ReportShiftLegendEntry(
      shiftId: shift.id,
      code: _shiftLabel(shift),
      name: shift.name,
      color: shift.color,
      timeLabel: reliableTime
          ? '${_time(shift.startTime)}–${_time(shift.endTime)}'
          : null,
    );
  }

  ReportStatistics _statistics(
    List<({ScheduleDay day, ShiftAssignment assignment})> assignments,
    List<ReportEmployeeRow> rows, {
    required bool includeDepartmentTotals,
  }) {
    final byShift = <String, int>{};
    final byDepartment = <String, int>{};
    final byEmployee = <String, int>{};
    var reliableHours = 0.0;
    var allHoursReliable = true;
    for (final entry in assignments) {
      final assignment = entry.assignment;
      byShift.update(
        _shiftLabel(assignment.shift),
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (includeDepartmentTotals) {
        byDepartment.update(
          assignment.employee.department.name,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      byEmployee.update(
        assignment.employee.id,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (assignment.shift.workingHours <= 0 ||
          assignment.shift.workingHours > 24 ||
          assignment.shift.startTime == assignment.shift.endTime) {
        allHoursReliable = false;
      } else {
        reliableHours += assignment.shift.workingHours;
      }
    }
    return ReportStatistics(
      employeeCount: rows.length,
      assignmentCount: assignments.length,
      assignmentsByShift: _sortedCounts(byShift),
      assignmentsByDepartment: _sortedCounts(byDepartment),
      assignmentsByEmployee: Map.unmodifiable(byEmployee),
      reliableWorkingHours: assignments.isNotEmpty && allHoursReliable
          ? reliableHours
          : null,
    );
  }

  List<String> _notes(
    List<({ScheduleDay day, ShiftAssignment assignment})> assignments,
  ) {
    final notes = <String>[];
    for (final entry in assignments) {
      final location = entry.assignment.location?.trim() ?? '';
      final remark = entry.assignment.remark?.trim() ?? '';
      if (location.isEmpty && remark.isEmpty) continue;
      final details = [
        if (location.isNotEmpty) location,
        if (remark.isNotEmpty) remark,
      ].join(' — ');
      notes.add(
        '${_date(entry.day.date)} '
        '${entry.assignment.employee.displayName}: $details',
      );
    }
    return List.unmodifiable(notes);
  }

  void _validateEmployeeIdentity(
    List<({ScheduleDay day, ShiftAssignment assignment})> assignments,
  ) {
    final identities = <String, String>{};
    for (final entry in assignments) {
      final employee = entry.assignment.employee;
      final signature =
          '${employee.displayName}|${employee.department.id}|'
          '${employee.position}';
      final existing = identities[employee.id];
      if (existing != null && existing != signature) {
        throw FormatException(
          'Employee ${employee.id} has conflicting canonical identities.',
        );
      }
      identities[employee.id] = signature;
    }
  }

  Map<String, int> _sortedCounts(Map<String, int> source) {
    final keys = source.keys.toList()..sort(_compareText);
    return Map.unmodifiable({for (final key in keys) key: source[key]!});
  }

  List<String> _unique(List<String?> values) {
    final result = <String>[];
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty && !result.contains(normalized)) {
        result.add(normalized);
      }
    }
    return List.unmodifiable(result);
  }

  int _compareText(String left, String right) =>
      left.toLowerCase().compareTo(right.toLowerCase());

  String _time(Duration value) {
    final hours = value.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

extension on int {
  int nonZeroOr(int Function() fallback) => this == 0 ? fallback() : this;
}
