import 'roster_file.dart';

abstract interface class DriveGateway {
  Future<List<RosterFile>> listSpreadsheets({
    int pageSize = 50,
    String? pageToken,
  });
}
