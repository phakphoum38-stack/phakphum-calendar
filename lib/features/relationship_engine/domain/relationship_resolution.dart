import '../../../core/models/shift_record.dart';

class RelationshipResolutionInput {
  const RelationshipResolutionInput({
    required this.cellText,
    required this.userAliases,
    required this.colorMeaning,
  });

  final String? cellText;
  final List<String> userAliases;
  final String colorMeaning;
}

class RelationshipResolution {
  const RelationshipResolution({
    required this.type,
    required this.originalOwner,
    required this.actualWorker,
    this.transferFrom,
    this.transferTo,
    this.warning,
  });

  final ShiftRelationshipType type;
  final String? originalOwner;
  final String? actualWorker;
  final String? transferFrom;
  final String? transferTo;
  final String? warning;
}
