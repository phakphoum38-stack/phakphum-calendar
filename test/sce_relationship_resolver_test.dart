import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/models/shift_record.dart';
import 'package:phakphum_calendar/features/relationship_engine/application/default_relationship_resolver.dart';
import 'package:phakphum_calendar/features/relationship_engine/domain/relationship_resolution.dart';

void main() {
  const resolver = DefaultRelationshipResolver();

  test('received shift keeps original owner and assigns user as worker', () {
    final result = resolver.resolve(
      const RelationshipResolutionInput(
        cellText: 'สมชาย',
        userAliases: ['ภาคภูมิ'],
        colorMeaning: 'received',
      ),
    );

    expect(result.type, ShiftRelationshipType.received);
    expect(result.originalOwner, 'สมชาย');
    expect(result.actualWorker, 'ภาคภูมิ');
    expect(result.transferFrom, 'สมชาย');
  });

  test('given-away shift assigns receiver as actual worker', () {
    final result = resolver.resolve(
      const RelationshipResolutionInput(
        cellText: 'สมหญิง',
        userAliases: ['ภาคภูมิ'],
        colorMeaning: 'givenAway',
      ),
    );

    expect(result.type, ShiftRelationshipType.givenAway);
    expect(result.originalOwner, 'ภาคภูมิ');
    expect(result.actualWorker, 'สมหญิง');
    expect(result.transferTo, 'สมหญิง');
  });
}
