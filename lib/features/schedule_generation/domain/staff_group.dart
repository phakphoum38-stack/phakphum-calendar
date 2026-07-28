enum StaffGroup {
  radiologicTechnologist,
  laboratoryOfficer,
  nurse,
  administrator,
}

extension StaffGroupInfo on StaffGroup {
  String get id => switch (this) {
    StaffGroup.radiologicTechnologist => 'radiologic-technologist',
    StaffGroup.laboratoryOfficer => 'laboratory-officer',
    StaffGroup.nurse => 'nurse',
    StaffGroup.administrator => 'administrator',
  };

  String get code => switch (this) {
    StaffGroup.radiologicTechnologist => 'RT',
    StaffGroup.laboratoryOfficer => 'LAB',
    StaffGroup.nurse => 'NURSE',
    StaffGroup.administrator => 'ADMIN',
  };

  String get thaiName => switch (this) {
    StaffGroup.radiologicTechnologist => 'นักรังสีการแพทย์',
    StaffGroup.laboratoryOfficer => 'เจ้าหน้าที่ห้องปฏิบัติการ',
    StaffGroup.nurse => 'พยาบาล',
    StaffGroup.administrator => 'ธุรการ',
  };

  String get sourceSheetTitle => switch (this) {
    StaffGroup.radiologicTechnologist => 'นักรังสีการแพทย์',
    StaffGroup.laboratoryOfficer => 'จนท.ห้องปฏิบัติการ',
    StaffGroup.nurse => 'พยาบาล',
    StaffGroup.administrator => 'ธุระการ',
  };
}
