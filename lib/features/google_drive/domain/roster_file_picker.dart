import 'roster_file.dart';

abstract interface class RosterFilePicker {
  Future<RosterFile?> pickSpreadsheet();
}
