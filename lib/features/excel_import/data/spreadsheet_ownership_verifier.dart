import 'package:http/http.dart' as http;

import '../../../services/drive_ownership_service.dart';

/// Verifies that a spreadsheet belongs to the currently authorized account.
abstract interface class SpreadsheetOwnershipVerifier {
  /// Throws a controlled error unless [spreadsheetId] is an owned Google Sheet.
  Future<void> requireCurrentAccountOwnership(String spreadsheetId);
}

/// Google Drive metadata adapter for import-source ownership checks.
class GoogleDriveSpreadsheetOwnershipVerifier
    implements SpreadsheetOwnershipVerifier {
  const GoogleDriveSpreadsheetOwnershipVerifier({
    required this.client,
    required this.gateway,
  });

  final http.Client client;
  final DriveOwnershipGateway gateway;

  @override
  Future<void> requireCurrentAccountOwnership(String spreadsheetId) async {
    await gateway.requireOwnedSpreadsheet(client, spreadsheetId);
  }
}
