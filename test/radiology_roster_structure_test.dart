import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/schedule_generation/application/monthly_roster_request_builder.dart';
import 'package:phakphum_calendar/features/schedule_generation/application/radiology_roster_blueprint.dart';
import 'package:phakphum_calendar/features/schedule_generation/application/schedule_generator.dart';
import 'package:phakphum_calendar/features/schedule_generation/data/radiology_staff_directory_parser.dart';
import 'package:phakphum_calendar/features/schedule_generation/domain/roster_staffing_rule.dart';
import 'package:phakphum_calendar/features/schedule_generation/domain/staff_group.dart';
import 'package:phakphum_calendar/models/shift.dart';

void main() {
  test('parses staff sets while excluding phone numbers', () {
    const parser = RadiologyStaffDirectoryParser();
    final directory = parser.parse([
      const SheetSnapshot(
        title: 'นักรังสีการแพทย์',
        rows: [
          ['บุคลากร A', null, 'บุคลากร B'],
          ['081-111-1111', null, '082-222-2222'],
        ],
      ),
      const SheetSnapshot(
        title: 'จนท.ห้องปฏิบัติการ',
        rows: [
          ['บุคลากร C', null, 'บุคลากร D'],
          ['083-333-3333', null, '084-444-4444'],
        ],
      ),
      const SheetSnapshot(
        title: 'พยาบาล',
        rows: [
          ['บุคลากร E'],
          ['085-555-5555'],
        ],
      ),
      const SheetSnapshot(
        title: 'ธุระการ',
        rows: [
          ['บุคลากร F'],
          ['086-666-6666'],
        ],
      ),
      const SheetSnapshot(
        title: 'อินชาร์จ',
        rows: [
          ['1     บุคลากร A', '2     บุคลากร B'],
        ],
      ),
    ]);

    expect(
      directory
          .employeesFor(StaffGroup.radiologicTechnologist)
          .map((employee) => employee.fullName),
      ['บุคลากร A', 'บุคลากร B'],
    );
    expect(
      directory
          .employeesFor(StaffGroup.laboratoryOfficer)
          .map((employee) => employee.fullName),
      ['บุคลากร C', 'บุคลากร D'],
    );
    expect(directory.inChargeEligible, hasLength(2));
    expect(
      directory.allEmployees.any(
        (employee) => employee.fullName.contains('081-'),
      ),
      isFalse,
    );
  });

  test('builds configurable monthly coverage from the reference slots', () {
    const blueprintFactory = RadiologyRosterBlueprint();
    final blueprint = blueprintFactory.build();
    final directory = const RadiologyStaffDirectoryParser().parse([
      const SheetSnapshot(
        title: 'จนท.ห้องปฏิบัติการ',
        rows: [
          ['บุคลากร A', null, 'บุคลากร B'],
          ['083-333-3333', null, '084-444-4444'],
        ],
      ),
    ]);
    final request = const MonthlyRosterRequestBuilder().build(
      month: DateTime(2026, 8),
      directory: directory,
      blueprint: blueprint,
      lockedDutyPointsByEmployeeId: {directory.allEmployees.last.id: 'CT IPD'},
      staffingRules: const [
        RosterStaffingRule(
          slotId: 'ct-ipd-morning',
          staffGroup: StaffGroup.laboratoryOfficer,
          requiredEmployees: 1,
          weekdays: {1, 2, 3, 4, 5},
        ),
      ],
    );

    expect(blueprint.slots, hasLength(22));
    expect(request.coverageRequirements, hasLength(21));
    expect(
      request.coverageRequirements.every(
        (requirement) => requirement.location == 'CT IPD',
      ),
      isTrue,
    );

    final generated = const ScheduleGenerator().autoAssign(request);
    expect(generated.assignmentsCreated, 21);
    expect(generated.uncoveredRequirements, isEmpty);
    final assignedEmployees = generated.schedule.months
        .expand((month) => month.days)
        .expand((day) => day.assignments)
        .map((assignment) => assignment.employee.id)
        .toSet();
    expect(assignedEmployees, {directory.allEmployees.last.id});
  });
}
