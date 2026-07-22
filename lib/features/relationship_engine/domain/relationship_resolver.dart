import 'relationship_resolution.dart';

abstract interface class RelationshipResolver {
  RelationshipResolution resolve(RelationshipResolutionInput input);
}
