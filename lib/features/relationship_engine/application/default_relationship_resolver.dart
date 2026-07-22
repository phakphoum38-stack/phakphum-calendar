import '../../../core/models/shift_record.dart';
import '../domain/relationship_resolution.dart';
import '../domain/relationship_resolver.dart';

class DefaultRelationshipResolver implements RelationshipResolver {
  const DefaultRelationshipResolver();

  @override
  RelationshipResolution resolve(RelationshipResolutionInput input) {
    final text = input.cellText?.trim();
    final normalizedAliases = input.userAliases
        .map((alias) => alias.trim().toLowerCase())
        .where((alias) => alias.isNotEmpty)
        .toSet();

    final isUserName =
        text != null && normalizedAliases.contains(text.toLowerCase());

    switch (input.colorMeaning) {
      case 'ownShift':
        return RelationshipResolution(
          type: ShiftRelationshipType.own,
          originalOwner: text,
          actualWorker: text,
          warning: isUserName
              ? null
              : 'สีระบุว่าเป็นเวรของผู้ใช้ แต่ชื่อไม่ตรงกับชื่อผู้ใช้',
        );

      case 'otherPersonShift':
        return RelationshipResolution(
          type: ShiftRelationshipType.other,
          originalOwner: text,
          actualWorker: text,
        );

      case 'received':
      case 'majorExchange':
      case 'clinicExchange':
        return RelationshipResolution(
          type: input.colorMeaning == 'majorExchange'
              ? ShiftRelationshipType.majorExchange
              : input.colorMeaning == 'clinicExchange'
              ? ShiftRelationshipType.clinicExchange
              : ShiftRelationshipType.received,
          originalOwner: text,
          actualWorker: input.userAliases.isEmpty
              ? null
              : input.userAliases.first,
          transferFrom: text,
          warning: text == null ? 'ไม่พบชื่อเจ้าของเวรเดิมในเซลล์' : null,
        );

      case 'givenAway':
        return RelationshipResolution(
          type: ShiftRelationshipType.givenAway,
          originalOwner: input.userAliases.isEmpty
              ? null
              : input.userAliases.first,
          actualWorker: text,
          transferTo: text,
          warning: text == null ? 'ไม่พบชื่อผู้รับเวร' : null,
        );

      case 'borrowedFree':
        return RelationshipResolution(
          type: ShiftRelationshipType.borrowedFree,
          originalOwner: text,
          actualWorker: input.userAliases.isEmpty
              ? null
              : input.userAliases.first,
          transferFrom: text,
        );

      case 'borrowedPaid':
        return RelationshipResolution(
          type: ShiftRelationshipType.borrowedPaid,
          originalOwner: text,
          actualWorker: input.userAliases.isEmpty
              ? null
              : input.userAliases.first,
          transferFrom: text,
        );

      default:
        return RelationshipResolution(
          type: ShiftRelationshipType.unknown,
          originalOwner: text,
          actualWorker: null,
          warning: 'ไม่สามารถระบุความสัมพันธ์จากสีและข้อความได้',
        );
    }
  }
}
