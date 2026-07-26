import 'import_file.dart';
import 'worksheet_info.dart';

class WorkbookInfo {
  WorkbookInfo({required this.file, required List<WorksheetInfo> worksheets})
    : worksheets = List.unmodifiable(worksheets);

  final ImportFile file;
  final List<WorksheetInfo> worksheets;

  int get worksheetCount => worksheets.length;
}
