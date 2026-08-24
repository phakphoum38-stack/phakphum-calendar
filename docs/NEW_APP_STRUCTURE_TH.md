# โครงสร้างแอพใหม่: Shift Calendar Engine / Phakphum Calendar

เอกสารนี้กำหนดโครงสร้างแอพใหม่สำหรับโปรเจกต์ `phakphum-calendar` โดยยังรักษาโค้ดเดิมที่ใช้งานได้ และย้ายระบบทีละส่วนเข้าสู่โครงสร้าง Enterprise / Clean Architecture

## เป้าหมาย

1. แยก UI, Logic, Data, External API ออกจากกันชัดเจน
2. ทำให้แอพไม่ค้างเมื่อ Google OAuth, Storage, Calendar, Sheets หรือ Plugin ใด ๆ ช้า/ล้มเหลว
3. ให้ทุกข้อมูลเวรไหลเข้าสู่รูปแบบกลางเดียวกันก่อนใช้งาน
4. รองรับ Excel, Google Sheets, Calendar, Manual Table, และข้อมูลที่ผู้ใช้กรอกเอง
5. เพิ่ม AI Analyzer สำหรับอ่านตารางเวรแบบยืดหยุ่น โดยไม่ผูกกับรูปแบบไฟล์เดียว
6. รองรับการจัดเวร, คนประจำ, คนแทน, คนเสริม, คนออฟ, คนลา, คนขาด, รับเวร, แลกเวร, แอดไซต์ และรายวัน

## โครงสร้างหลักที่ควรใช้

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── di/
│   ├── result/
│   ├── errors/
│   ├── config/
│   ├── google/
│   ├── storage/
│   └── validation/
├── domain/
│   ├── entities/
│   ├── repositories/
│   ├── services/
│   └── value_objects/
├── features/
│   ├── ai_roster_analyzer/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── data/
│   │   └── presentation/
│   ├── roster_import/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── data/
│   │   └── presentation/
│   ├── roster_editor/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── data/
│   │   └── presentation/
│   ├── calendar_sync/
│   ├── google_drive/
│   ├── google_sheets/
│   ├── excel_import/
│   ├── employees/
│   ├── shift_templates/
│   ├── shift_exchange/
│   ├── reports/
│   ├── dashboard/
│   ├── history/
│   └── settings/
├── shared/
│   ├── widgets/
│   ├── formatters/
│   ├── extensions/
│   └── layout/
└── legacy/
    ├── controller/
    ├── services/
    ├── models/
    └── ui/
```

## หลักการย้ายโค้ด

โค้ดเดิมใน `lib/controller`, `lib/services`, `lib/models`, และ `lib/ui` ไม่ควรถูกลบทิ้งทันที ให้ย้ายเข้ากลุ่ม `legacy/` หรือทำ adapter เชื่อมกับ domain ใหม่ก่อน

แนวทางที่ปลอดภัยคือ:

```text
Legacy Source → Adapter → Canonical Domain Model → Feature Application Service → UI Controller → Widget
```

## One Truth Data Flow

ข้อมูลทุกแหล่งต้องถูกแปลงเป็นข้อมูลกลางก่อน

```text
Excel / Sheets / Calendar / Manual Table
→ RosterInputFrame
→ AiRosterAnalyzer
→ RosterAnalysisRecord
→ DailyRosterPlan
→ Canonical Schedule
→ Preview / Validate / Save / Calendar Sync
```

## Feature ใหม่ที่ต้องมี

### 1. ai_roster_analyzer

ทำหน้าที่อ่านและตีความข้อมูลเวรจากหลายรูปแบบ

- ตรวจวันที่
- ตรวจชื่อคน
- ตรวจชนิดเวร
- ตรวจไซต์/แผนก
- ตรวจคำว่า รับเวร, แลกเวร, แทน, เสริม, ออฟ, ลา, ขาด
- รวมผลเป็นรายวัน
- แจ้งเตือนข้อมูลที่ไม่แน่ใจ

### 2. roster_import

เป็นชั้นกลางสำหรับนำเข้าข้อมูลจากทุกแหล่ง

```text
ExcelImportAdapter
GoogleSheetsImportAdapter
CalendarImportAdapter
ManualTableImportAdapter
```

ทุก adapter ต้องคืนค่าเป็น `RosterInputFrame`

### 3. roster_editor

เป็นหน้าจอแก้ไขเวรหลัก

- ดูเวรรายวัน
- แก้ชื่อคน
- เพิ่มคนแทน
- เพิ่มคนเสริม
- ตั้งคนออฟ
- ตั้งคนลา
- ตั้งคนขาด
- Preview ก่อนบันทึก

### 4. calendar_sync

ต้องเป็นระบบ Preview-first

```text
Schedule → Desired Events → Diff → Confirm → Write → History
```

ห้ามเขียน Google Calendar ทันทีโดยไม่มี preview

### 5. app_startup_guard

ทุก service ที่อาจค้างต้องมี timeout/fallback

- Google OAuth
- SharedPreferences
- Calendar API
- Sheets API
- Drive API
- Local file picker

## โครงสร้าง Controller ใหม่

UI ไม่ควรเรียก service ภายนอกโดยตรง

```text
Widget
→ Presentation Controller
→ Application Service
→ Domain Model / Repository Contract
→ Infrastructure Adapter
```

ตัวอย่าง:

```text
RosterAnalyzerPage
→ RosterAnalyzerController
→ AiRosterAnalyzer
→ RosterInputFrame
→ RosterAnalysisResult
```

## โครงสร้างข้อมูลกลาง

```text
RosterAnalysisRecord
├── date
├── dutyKind
├── personName
├── roleLabel
├── siteLabel
├── relatedPersonName
├── confidence
├── notes
└── rawCells
```

```text
DailyRosterPlan
├── date
├── dutyRecords
├── unavailableRecords
├── replacementRecords
├── extraStaffRecords
├── exchangeRecords
└── warnings
```

## ลำดับทำงานถัดไป

### Phase 1 — Stabilize

- แก้ startup hang guard
- ใส่ timeout ให้ storage/auth
- ทำให้หน้าแรกเปิดได้แม้ service ภายนอกล้มเหลว

### Phase 2 — AI Roster Core

- เพิ่ม `ai_roster_analyzer`
- เพิ่ม model กลางสำหรับตารางเวร
- เพิ่ม analyzer แบบ deterministic
- เพิ่มเอกสารตรรกะ

### Phase 3 — Import Adapter

- สร้าง adapter แปลง Excel → RosterInputFrame
- สร้าง adapter แปลง Google Sheets → RosterInputFrame
- สร้าง adapter แปลง Calendar Events → RosterInputFrame
- รวมทุกแหล่งเป็น DailyRosterPlan

### Phase 4 — UI Integration

- เพิ่มหน้า AI Roster Analyzer
- เพิ่มปุ่มวิเคราะห์จากไฟล์/ชีต/ปฏิทิน
- แสดง warning และ confidence
- ให้ผู้ใช้กดยืนยันก่อนบันทึก

### Phase 5 — Calendar Write Safety

- Preview event diff ก่อนเขียน
- กันเวรซ้ำ
- กันลบข้อมูลที่ผู้ใช้เขียนเองโดยไม่มีหลักฐาน
- เก็บ sync history

## กฎสำคัญ

1. Domain ห้าม import Flutter
2. Application ห้ามรู้จัก Widget
3. Infrastructure เป็นฝ่ายคุยกับ Google/Excel/File/Storage
4. UI แสดงผลอย่างเดียว ไม่ถือ logic เวร
5. ทุกการเขียน Calendar ต้อง preview ก่อน
6. ทุก import ต้องเก็บ rawCells เพื่อย้อนดูหลักฐาน
7. ทุก analyzer ต้องคืน confidence และ warnings
8. Legacy ห้ามลบทันที ให้ adapter ก่อน
9. โครงสร้างใหม่ต้อง test ได้โดยไม่ต้องเปิด Google API
10. Documentation ต้องอัปเดตพร้อม code

## สรุป

โครงสร้างใหม่ควรวางเป็น Feature-first Clean Architecture โดยมี `ai_roster_analyzer` และ `roster_import` เป็นแกนกลางในการอ่านตารางเวรทุกแบบ จากนั้นแปลงเป็น canonical schedule ก่อนส่งให้ editor, validator, report และ calendar sync ใช้งานต่อ
