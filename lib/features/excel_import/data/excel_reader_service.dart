import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';

import '../domain/excel_cell.dart';
import '../domain/excel_row.dart';
import '../domain/import_error.dart';
import '../domain/import_file.dart';
import '../domain/workbook_info.dart';
import '../domain/worksheet_info.dart';

typedef ExcelFilePicker = Future<ImportFile?> Function();

class ExcelReaderService {
  ExcelReaderService({this.filePicker});

  static const supportedExtension = 'xlsx';
  static const maxFileSizeInBytes = 15 * 1024 * 1024;
  static const maxPreviewRows = 50;

  final ExcelFilePicker? filePicker;
  excel.Excel? _workbook;

  Future<ImportFile?> pickFile() async {
    if (filePicker != null) return filePicker!();

    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [supportedExtension],
      allowMultiple: false,
      withData: true,
    );
    final platformFile = selection?.files.single;
    if (platformFile == null) return null;
    try {
      final bytes =
          platformFile.bytes ?? await platformFile.xFile.readAsBytes();
      return ImportFile(name: platformFile.name, bytes: bytes);
    } catch (_) {
      throw const ExcelReaderException(
        ImportError(
          code: ImportErrorCode.fileSelectionFailed,
          message: 'ไม่สามารถอ่านข้อมูลจากไฟล์ที่เลือกได้',
        ),
      );
    }
  }

  WorkbookInfo openWorkbook(ImportFile file) {
    final validationError = _validate(file);
    if (validationError != null) {
      throw ExcelReaderException(validationError);
    }

    try {
      _workbook = excel.Excel.decodeBytes(file.bytes);
      final worksheets = getWorksheets();
      if (worksheets.isEmpty) {
        throw const ExcelReaderException(
          ImportError(
            code: ImportErrorCode.invalidWorkbook,
            message: 'ไฟล์ Excel ไม่มี Worksheet ที่สามารถอ่านได้',
          ),
        );
      }
      return WorkbookInfo(file: file, worksheets: worksheets);
    } on ExcelReaderException {
      rethrow;
    } catch (_) {
      _workbook = null;
      throw const ExcelReaderException(
        ImportError(
          code: ImportErrorCode.invalidWorkbook,
          message: 'ไฟล์ Excel เสียหายหรือไม่ใช่ไฟล์ .xlsx ที่ถูกต้อง',
        ),
      );
    }
  }

  List<WorksheetInfo> getWorksheets() {
    final workbook = _workbook;
    if (workbook == null) return const [];

    return [
      for (final entry in workbook.tables.entries)
        WorksheetInfo(
          name: entry.key,
          rowCount: entry.value.rows.length,
          columnCount: entry.value.rows.fold<int>(
            0,
            (maximum, row) => row.length > maximum ? row.length : maximum,
          ),
        ),
    ];
  }

  List<ExcelRow> readWorksheet(WorksheetInfo worksheet) {
    return _readWorksheetRows(worksheet, limit: maxPreviewRows);
  }

  /// Reads every available row from [worksheet] for import processing.
  List<ExcelRow> readWorksheetForImport(WorksheetInfo worksheet) {
    return _readWorksheetRows(worksheet);
  }

  List<ExcelRow> _readWorksheetRows(WorksheetInfo worksheet, {int? limit}) {
    final sheet = _workbook?.tables[worksheet.name];
    if (sheet == null) {
      throw ExcelReaderException(
        ImportError(
          code: ImportErrorCode.worksheetNotFound,
          message: 'ไม่พบ Worksheet "${worksheet.name}"',
        ),
      );
    }

    try {
      final rowCount = limit == null || sheet.rows.length < limit
          ? sheet.rows.length
          : limit;
      return [
        for (var rowIndex = 0; rowIndex < rowCount; rowIndex++)
          ExcelRow(
            index: rowIndex,
            cells: [
              for (
                var columnIndex = 0;
                columnIndex < sheet.rows[rowIndex].length;
                columnIndex++
              )
                ExcelCell(
                  rowIndex: rowIndex,
                  columnIndex: columnIndex,
                  value: _cellValue(sheet.rows[rowIndex][columnIndex]?.value),
                ),
            ],
          ),
      ];
    } catch (_) {
      throw ExcelReaderException(
        ImportError(
          code: ImportErrorCode.worksheetReadFailed,
          message: 'ไม่สามารถอ่าน Worksheet "${worksheet.name}" ได้',
        ),
      );
    }
  }

  ImportError? _validate(ImportFile file) {
    if (file.extension != supportedExtension) {
      return const ImportError(
        code: ImportErrorCode.unsupportedExtension,
        message: 'รองรับเฉพาะไฟล์ Excel นามสกุล .xlsx',
      );
    }
    if (file.sizeInBytes == 0) {
      return const ImportError(
        code: ImportErrorCode.emptyFile,
        message: 'ไฟล์ Excel ไม่มีข้อมูล',
      );
    }
    if (file.sizeInBytes > maxFileSizeInBytes) {
      return const ImportError(
        code: ImportErrorCode.fileTooLarge,
        message: 'ไฟล์ Excel ต้องมีขนาดไม่เกิน 15 MB',
      );
    }
    return null;
  }

  Object? _cellValue(excel.CellValue? value) => switch (value) {
    null => null,
    excel.TextCellValue() => value.value.text,
    excel.IntCellValue() => value.value,
    excel.DoubleCellValue() => value.value,
    excel.BoolCellValue() => value.value,
    excel.DateCellValue() => value.asDateTimeLocal(),
    excel.DateTimeCellValue() => value.asDateTimeLocal(),
    excel.TimeCellValue() => value.asDuration(),
    excel.FormulaCellValue() => value.formula,
  };
}

class ExcelReaderException implements Exception {
  const ExcelReaderException(this.error);

  final ImportError error;

  @override
  String toString() => error.message;
}
