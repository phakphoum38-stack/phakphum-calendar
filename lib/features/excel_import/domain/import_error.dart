enum ImportErrorCode {
  unsupportedExtension,
  emptyFile,
  fileTooLarge,
  fileSelectionFailed,
  invalidWorkbook,
  worksheetNotFound,
  worksheetReadFailed,
}

class ImportError {
  const ImportError({required this.code, required this.message});

  final ImportErrorCode code;
  final String message;
}
