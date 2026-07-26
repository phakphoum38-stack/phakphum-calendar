// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shift Tools';

  @override
  String get appSubtitle => 'Schedule workspace';

  @override
  String get switchLanguage => 'Switch language';

  @override
  String get home => 'Home';

  @override
  String get preview => 'Preview';

  @override
  String get notifications => 'Notifications';

  @override
  String get history => 'History';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get tools => 'Tools';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get next => 'Next';

  @override
  String get reset => 'Reset';

  @override
  String get retry => 'Retry';

  @override
  String get errors => 'Errors';

  @override
  String get warnings => 'Warnings';

  @override
  String get rules => 'Rules';

  @override
  String get validationTitle => 'Rule Validation';

  @override
  String get importExcel => 'Import Excel';

  @override
  String get importSchedule => 'Import schedule';

  @override
  String get importDescription =>
      'Select an .xlsx file or Google Sheets document, then review it before choosing a worksheet.';

  @override
  String get selectExcelFile => 'Select Excel File';

  @override
  String get loadGoogleSheets => 'Load Google Sheets';

  @override
  String get googleSheetsInputLabel => 'Google Sheets URL or spreadsheet ID';

  @override
  String get columnMapping => 'Column Mapping';

  @override
  String get mapExcelColumns => 'Map Excel columns';

  @override
  String get requiredMappingHelp =>
      'Required fields must be mapped before continuing.';

  @override
  String get editColumnMapping => 'Edit Column Mapping';

  @override
  String get nextColumnMapping => 'Next: Column Mapping';

  @override
  String get importSummary => 'Import Summary';

  @override
  String get importCompleted => 'Import completed';

  @override
  String importCreatedRecords(int recordCount, int rowCount) {
    return '$recordCount Shift Records created from $rowCount data rows.';
  }

  @override
  String scheduleSaveFailed(String message) {
    return 'Schedule could not be saved: $message';
  }

  @override
  String get viewMonthCalendar => 'View Month Calendar';

  @override
  String get issues => 'Issues';

  @override
  String get monthCalendar => 'Month Calendar';

  @override
  String get monthlySchedule => 'Monthly Schedule';

  @override
  String get noShiftsThisMonth => 'No shifts scheduled for this month.';

  @override
  String get noMatchingAssignments =>
      'No assignments match the active filters.';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get reportEmptySchedule =>
      'No schedule data is available. You can still create an empty report.';

  @override
  String get reportPreviewPrompt =>
      'Select filters, then choose “Generate preview”.';

  @override
  String get month => 'Month';

  @override
  String get department => 'Department';

  @override
  String get allDepartments => 'All departments';

  @override
  String get generatePreview => 'Generate preview';

  @override
  String get print => 'Print';

  @override
  String get saveSharePdf => 'Save / share PDF';

  @override
  String get reportDefaultTitle => 'Monthly Staff Schedule Report';

  @override
  String get reportGeneratedAt => 'Generated at';

  @override
  String get reportEmployee => 'Employee';

  @override
  String get reportPosition => 'Position';

  @override
  String get reportNoData => 'No schedule data for the selected month';

  @override
  String get reportSummary => 'Summary';

  @override
  String get reportLegend => 'Shift legend';

  @override
  String get reportNotes => 'Notes';

  @override
  String get reportEmployeeCount => 'Employees';

  @override
  String get reportAssignmentCount => 'Assignments';

  @override
  String get reportPreparedBy => 'Prepared by';

  @override
  String get reportCheckedBy => 'Checked by';

  @override
  String get reportApprovedBy => 'Approved by';

  @override
  String get reportDate => 'Date';

  @override
  String get weekdayMondayShort => 'Mon';

  @override
  String get weekdayTuesdayShort => 'Tue';

  @override
  String get weekdayWednesdayShort => 'Wed';

  @override
  String get weekdayThursdayShort => 'Thu';

  @override
  String get weekdayFridayShort => 'Fri';

  @override
  String get weekdaySaturdayShort => 'Sat';

  @override
  String get weekdaySundayShort => 'Sun';

  @override
  String get googleAccessTitle => 'Allow Google access';

  @override
  String get googleAccessLater => 'Later';

  @override
  String get googleAccessAllow => 'Allow access';

  @override
  String get googleSyncConfirmTitle => 'Confirm calendar changes';

  @override
  String get googleSyncConfirm => 'Confirm and continue';

  @override
  String get googleSyncNoWriteBeforeConfirm =>
      'Nothing is written to Google Calendar before confirmation.';

  @override
  String get unexpectedError => 'Something went wrong. Please try again.';
}
