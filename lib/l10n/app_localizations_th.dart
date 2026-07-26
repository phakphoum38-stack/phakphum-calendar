// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Shift Tools';

  @override
  String get appSubtitle => 'พื้นที่จัดการตารางเวร';

  @override
  String get switchLanguage => 'เปลี่ยนภาษา';

  @override
  String get home => 'หน้าแรก';

  @override
  String get preview => 'ตัวอย่าง';

  @override
  String get notifications => 'แจ้งเตือน';

  @override
  String get history => 'บันทึก';

  @override
  String get reports => 'รายงาน';

  @override
  String get settings => 'ตั้งค่า';

  @override
  String get tools => 'เครื่องมือ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get close => 'ปิด';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get save => 'บันทึก';

  @override
  String get delete => 'ลบ';

  @override
  String get next => 'ถัดไป';

  @override
  String get reset => 'รีเซ็ต';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get errors => 'ข้อผิดพลาด';

  @override
  String get warnings => 'คำเตือน';

  @override
  String get rules => 'กฎ';

  @override
  String get validationTitle => 'ผลการตรวจสอบกฎ';

  @override
  String get importExcel => 'นำเข้า Excel';

  @override
  String get importSchedule => 'นำเข้าตารางเวร';

  @override
  String get importDescription =>
      'เลือกไฟล์ .xlsx หรือ Google Sheets เพื่อตรวจสอบก่อนเลือกเวิร์กชีต';

  @override
  String get selectExcelFile => 'เลือกไฟล์ Excel';

  @override
  String get loadGoogleSheets => 'โหลด Google Sheets';

  @override
  String get googleSheetsInputLabel => 'URL หรือรหัสสเปรดชีต Google Sheets';

  @override
  String get columnMapping => 'จับคู่คอลัมน์';

  @override
  String get mapExcelColumns => 'จับคู่คอลัมน์ Excel';

  @override
  String get requiredMappingHelp => 'ต้องจับคู่ฟิลด์ที่จำเป็นก่อนดำเนินการต่อ';

  @override
  String get editColumnMapping => 'แก้ไขการจับคู่คอลัมน์';

  @override
  String get nextColumnMapping => 'ถัดไป: จับคู่คอลัมน์';

  @override
  String get importSummary => 'สรุปการนำเข้า';

  @override
  String get importCompleted => 'นำเข้าเสร็จแล้ว';

  @override
  String importCreatedRecords(int recordCount, int rowCount) {
    return 'สร้างรายการเวร $recordCount รายการ จากข้อมูล $rowCount แถว';
  }

  @override
  String scheduleSaveFailed(String message) {
    return 'ไม่สามารถบันทึกตารางเวรได้: $message';
  }

  @override
  String get viewMonthCalendar => 'ดูปฏิทินรายเดือน';

  @override
  String get issues => 'รายการที่ต้องตรวจสอบ';

  @override
  String get monthCalendar => 'ปฏิทินรายเดือน';

  @override
  String get monthlySchedule => 'ตารางเวรรายเดือน';

  @override
  String get noShiftsThisMonth => 'ไม่มีเวรในเดือนนี้';

  @override
  String get noMatchingAssignments => 'ไม่มีรายการที่ตรงกับตัวกรองที่ใช้งาน';

  @override
  String get previousMonth => 'เดือนก่อนหน้า';

  @override
  String get nextMonth => 'เดือนถัดไป';

  @override
  String get reportEmptySchedule =>
      'ไม่มีข้อมูลตารางเวร สามารถสร้างรายงานเปล่าได้';

  @override
  String get reportPreviewPrompt => 'เลือกตัวกรองแล้วกด “สร้างตัวอย่าง”';

  @override
  String get month => 'เดือน';

  @override
  String get department => 'แผนก';

  @override
  String get allDepartments => 'ทุกแผนก';

  @override
  String get generatePreview => 'สร้างตัวอย่าง';

  @override
  String get print => 'พิมพ์';

  @override
  String get saveSharePdf => 'บันทึก / แชร์ PDF';

  @override
  String get reportDefaultTitle => 'รายงานตารางเวรประจำเดือน';

  @override
  String get reportGeneratedAt => 'จัดทำเมื่อ';

  @override
  String get reportEmployee => 'พนักงาน';

  @override
  String get reportPosition => 'ตำแหน่ง';

  @override
  String get reportNoData => 'ไม่มีข้อมูลตารางเวรในเดือนที่เลือก';

  @override
  String get reportSummary => 'สรุป';

  @override
  String get reportLegend => 'คำอธิบายเวร';

  @override
  String get reportNotes => 'หมายเหตุ';

  @override
  String get reportEmployeeCount => 'จำนวนพนักงาน';

  @override
  String get reportAssignmentCount => 'จำนวนเวร';

  @override
  String get reportPreparedBy => 'ผู้จัดทำ';

  @override
  String get reportCheckedBy => 'ผู้ตรวจสอบ';

  @override
  String get reportApprovedBy => 'ผู้อนุมัติ';

  @override
  String get reportDate => 'วันที่';

  @override
  String get weekdayMondayShort => 'จ.';

  @override
  String get weekdayTuesdayShort => 'อ.';

  @override
  String get weekdayWednesdayShort => 'พ.';

  @override
  String get weekdayThursdayShort => 'พฤ.';

  @override
  String get weekdayFridayShort => 'ศ.';

  @override
  String get weekdaySaturdayShort => 'ส.';

  @override
  String get weekdaySundayShort => 'อา.';

  @override
  String get googleAccessTitle => 'อนุญาตการเข้าถึง Google';

  @override
  String get googleAccessLater => 'ไว้ภายหลัง';

  @override
  String get googleAccessAllow => 'อนุญาตการเข้าถึง';

  @override
  String get googleSyncConfirmTitle => 'ยืนยันการเปลี่ยนแปลงปฏิทิน';

  @override
  String get googleSyncConfirm => 'ยืนยันและทำต่อ';

  @override
  String get googleSyncNoWriteBeforeConfirm =>
      'จะไม่มีการเขียนข้อมูลลง Google Calendar ก่อนยืนยัน';

  @override
  String get unexpectedError => 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง';
}
