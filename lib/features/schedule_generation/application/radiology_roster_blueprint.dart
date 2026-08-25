import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_month.dart';
import '../../../domain/entities/shift_type.dart';
import '../domain/monthly_roster_blueprint.dart';
import '../domain/staff_group.dart';

class RadiologyRosterBlueprint {
  const RadiologyRosterBlueprint();

  static const allStaffGroups = <StaffGroup>{
    StaffGroup.radiologicTechnologist,
    StaffGroup.laboratoryOfficer,
    StaffGroup.nurse,
    StaffGroup.administrator,
  };

  MonthlyRosterBlueprint build() => MonthlyRosterBlueprint(
    shiftTypes: _shiftTypes,
    slots: [
      _slot(
        id: 'incharge-morning',
        label: 'INCHARGE',
        location: 'INCHARGE',
        period: DutyPeriod.morning,
        shiftTypeId: 'morning',
        groups: const {StaffGroup.radiologicTechnologist},
      ),
      for (final location in const [
        'CT IPD',
        'IPD',
        'PORT 1',
        'PORT 2',
        'PORT 3',
        'PORT 4',
        'CT ER',
      ])
        for (final period in DutyPeriod.values)
          _slot(
            id: '${_slug(location)}-${period.name}',
            label: '$location ${_periodLabel(period)}',
            location: location,
            period: period,
            shiftTypeId: period.name,
            groups: allStaffGroups,
          ),
    ],
  );

  Schedule emptySchedule(DateTime month) => Schedule(
    id:
        'radiology-${month.year}-'
        '${month.month.toString().padLeft(2, '0')}',
    name: 'ตารางเวรฝ่ายรังสีวิทยาวินิจฉัย',
    months: [ScheduleMonth.empty(DateTime(month.year, month.month))],
  );

  static RosterDutySlot _slot({
    required String id,
    required String label,
    required String location,
    required DutyPeriod period,
    required String shiftTypeId,
    required Set<StaffGroup> groups,
  }) => RosterDutySlot(
    id: id,
    label: label,
    location: location,
    period: period,
    shiftTypeId: shiftTypeId,
    allowedGroups: groups,
  );

  static String _periodLabel(DutyPeriod period) => switch (period) {
    DutyPeriod.morning => 'เช้า',
    DutyPeriod.afternoon => 'บ่าย',
    DutyPeriod.night => 'ดึก',
  };

  static String _slug(String value) => value.toLowerCase().replaceAll(' ', '-');

  static const _shiftTypes = <ShiftType>[
    ShiftType(
      id: 'morning',
      code: 'M',
      name: 'เวรเช้า',
      color: 0xFF039BE5,
      startTime: Duration(hours: 8),
      endTime: Duration(hours: 16),
      workingHours: 8,
    ),
    ShiftType(
      id: 'afternoon',
      code: 'A',
      name: 'เวรบ่าย',
      color: 0xFFF6BF26,
      startTime: Duration(hours: 16),
      endTime: Duration(hours: 24),
      workingHours: 8,
    ),
    ShiftType(
      id: 'night',
      code: 'N',
      name: 'เวรดึก',
      color: 0xFF7986CB,
      startTime: Duration.zero,
      endTime: Duration(hours: 8),
      workingHours: 8,
    ),
  ];
}
