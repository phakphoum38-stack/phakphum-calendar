# Architecture Guide

## เป้าหมาย

Phakphum Calendar เป็นระบบนำเข้าตารางเวร ตรวจสอบความถูกต้อง จำลองผลลัพธ์ และซิงก์ปฏิทินอย่างปลอดภัย โดยออกแบบให้รองรับหลายโรงพยาบาล หลายรูปแบบชีต และหลายแพลตฟอร์มในอนาคต

## Data Flow

```text
Google Drive / Google Sheets
        ↓
Snapshot Normalizer
        ↓
Thai Roster Period Parser + Hospital Roster Parser
        ↓
Relationship / Rule Engine
        ↓
Simulation + Conflict Detection
        ↓
User Preview and Confirmation
        ↓
Calendar Sync Plan
        ↓
Google Calendar Gateway
        ↓
History / Resume / Audit
```

## Feature boundaries

```text
lib/features/
├── authentication/
├── google_drive/
├── google_sheets/
├── shift_parser/
├── relationship_engine/
├── rule_engine/          # เป้าหมาย Sprint ถัดไป
├── diff_engine/
├── simulation/
├── calendar_engine/
├── history/
└── workflow/
```

แต่ละ Feature ควรแบ่งเป็น:

- `domain/` — โมเดล กฎ และ interface ที่ไม่ขึ้นกับ Flutter
- `application/` — use case และ orchestration
- `infrastructure/` — Google APIs, local storage และ codecs
- `presentation/` — widgets, screens และ controllers ที่ผูกกับ UI

## Dependency rule

```text
presentation → application → domain
infrastructure → domain
```

`domain` ต้องไม่ import Flutter, Google API, SharedPreferences หรือ UI framework

## Reliability rules

- การเขียน Calendar ต้องมาจาก Sync Plan ที่ผ่าน Preview แล้ว
- ทุก Event ที่แอปสร้างต้องมี stable sync ID
- การเขียนหลายรายการต้องบันทึกผลรายรายการและรองรับ resume
- Parser ต้องคืน warning เมื่อข้อมูลไม่สมบูรณ์ แทนการ silently เดา
- Unknown shift time ต้อง block การซิงก์จนผู้ใช้แก้ไขหรือยืนยัน
