import 'package:http/http.dart' as http;

import '../../../services/drive_ownership_service.dart';

/// ตรวจว่า Google Sheets สามารถเข้าถึงได้จากบัญชีที่ล็อกอินอยู่
abstract interface class SpreadsheetOwnershipVerifier {
  /// แจ้งข้อผิดพลาดเมื่อบัญชีปัจจุบันไม่สามารถเข้าถึงไฟล์ได้
  Future<void> requireCurrentAccountOwnership(String spreadsheetId);
}

/// Google Drive metadata adapter สำหรับตรวจสิทธิ์เข้าถึงไฟล์ต้นทาง
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
    await gateway.requireAccessibleSpreadsheet(client, spreadsheetId);
  }
}
