/// Locale-aware report copy kept independent from Flutter widget localization.
class ReportLabels {
  const ReportLabels({this.languageCode = 'th'});

  final String languageCode;

  factory ReportLabels.forLanguageCode(String languageCode) =>
      ReportLabels(languageCode: languageCode == 'en' ? 'en' : 'th');

  bool get _english => languageCode == 'en';
  String get defaultTitle =>
      _english ? 'Monthly Staff Schedule Report' : 'รายงานตารางเวรประจำเดือน';
  String get generatedAt => _english ? 'Generated at' : 'จัดทำเมื่อ';
  String get department => _english ? 'Department' : 'แผนก';
  String get employee => _english ? 'Employee' : 'พนักงาน';
  String get position => _english ? 'Position' : 'ตำแหน่ง';
  String get noData => _english
      ? 'No schedule data for the selected month'
      : 'ไม่มีข้อมูลตารางเวรในเดือนที่เลือก';
  String get summary => _english ? 'Summary' : 'สรุป';
  String get legend => _english ? 'Shift legend' : 'คำอธิบายเวร';
  String get notes => _english ? 'Notes' : 'หมายเหตุ';
  String get employees => _english ? 'Employees' : 'จำนวนพนักงาน';
  String get assignments => _english ? 'Assignments' : 'จำนวนเวร';
  String get preparedBy => _english ? 'Prepared by' : 'ผู้จัดทำ';
  String get checkedBy => _english ? 'Checked by' : 'ผู้ตรวจสอบ';
  String get approvedBy => _english ? 'Approved by' : 'ผู้อนุมัติ';
  String get date => _english ? 'Date' : 'วันที่';

  List<String> get shortWeekdays => _english
      ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : const ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
}
