# Shift Calendar Engine 3.0

เอกสารสถาปัตยกรรมผลิตภัณฑ์และโครงสร้างหน้าจอฉบับใช้งาน

## เป้าหมาย

Shift Calendar Engine (SCE) 3.0 คือระบบบริหารตารางเวรหลายแพลตฟอร์มสำหรับ
Web, Android, iOS, Windows, macOS และ Linux โดยใช้ตารางเวร (Roster) เป็น
source of truth เดียว ระบบต้องรองรับหลายองค์กร หลายหน่วยงาน ทีม และผู้ใช้
โดยไม่ผูกกฎ เวลาทำงาน สี อัตราค่าตอบแทน หรือปฏิทินไว้ในโค้ด

กระบวนการหลัก:

```text
บุคลากร
→ สร้างหรือนำเข้าตารางเวร
→ Rule / Conflict / Policy evaluation
→ Preview และยืนยัน
→ บันทึก canonical Schedule
→ แลกเวรและอนุมัติ
→ คำนวณเงินเวรและ OT
→ รายงานและเอกสาร A4
→ Sync เฉพาะเวรของผู้ใช้ไป Google Calendar
→ History และ Audit Log
```

## เมนูหลัก

บนมือถือใช้ Material 3 `NavigationBar` และบนหน้าจอกว้างใช้
`NavigationRail` หรือ sidebar:

1. Dashboard
2. ตารางเวร
3. บุคลากร
4. แลกเวร
5. รายงาน
6. ตั้งค่า

## Dashboard

Dashboard แสดงเวรวันนี้ พรุ่งนี้ และเวรถัดไป เวลา สถานที่ ผู้ร่วมเวร
สถานะเวร จำนวนเวร ชั่วโมง OT รายได้โดยประมาณ คำขอแลกเวร Conflict
สถานะและผล Google Calendar sync ล่าสุด พร้อม quick actions สำหรับสร้างเวร
นำเข้า ตรวจสอบ Sync เปิดตารางรายเดือน และดูรายงาน

การ์ดหลัก:

- My Next Shift
- Today Summary
- Pending Exchange Requests
- Monthly Income Estimate
- Calendar Sync Status
- Conflict Warning

## ตารางเวร

รองรับ Month, Week, Day, Timeline, Department, Employee และ A4 view พร้อม
ตัวกรองเดือน ปี หน่วยงาน ตำแหน่ง ประเภทเวร บุคลากร สถานะ Conflict
รายการแลก และการอนุมัติ

การทำงานสำคัญ:

- เพิ่ม แก้ไข ลบ คัดลอก ย้าย และ drag-and-drop
- กำหนดบุคลากร หลายรายการ recurring และ template
- Standard Template, Override และ Free Style
- Manual และ auto assignment
- Preview ก่อนบันทึกและก่อน Sync
- Import Excel / Google Sheets
- Export PDF / Excel / CSV และ Print A4
- รองรับหลายเวรต่อวัน หลายคนต่อเวร วันหยุด วันลา สี หมายเหตุ และสถานะ

ข้อมูลรายการเวรต้องเก็บรหัส ชื่อ วันที่ เวลา overnight บุคลากร บทบาท
หน่วยงาน สถานที่ สี รายละเอียด Calendar/Reminder อัตรา/OT สถานะ
Sync ID, Source ID และ audit metadata

## บุคลากร

Employee Directory เก็บรหัส คำนำหน้า ชื่อ ชื่อแสดง รูป ตำแหน่ง หน่วยงาน
ทีม ช่องทางติดต่อ Google account/calendar สี สถานะการทำงาน สิทธิ์
ความสามารถทำเวร เวลาทำงาน อัตราเฉพาะบุคคล วันลา วันหยุด และหมายเหตุ

ต้องค้นหา กรอง นำเข้า ส่งออก เปิด/ปิดใช้งาน ดูเวร ประวัติแลก OT รายได้
วันลา ความพร้อม และกำหนดสิทธิ์ได้

## แลกเวร

รองรับคำขอใหม่ รอตอบรับ รออนุมัติ อนุมัติ ปฏิเสธ ยกเลิก และประวัติ
รวมทั้งแลกคนต่อคน ฝากเวร รับแทน เวรว่าง หลายรายการ และค่าตอบแทน

```text
Request
→ Receiver acceptance
→ Approval
→ Conflict validation
→ Canonical Schedule mutation
→ Payroll recalculation
→ Calendar preview/sync
→ Audit history
```

## รายงาน เงินเวร และ OT

รายงานต้องรองรับภาพรวม จำนวนเวร เงินเวร OT รายบุคคล รายหน่วยงาน
การแลก วันลา Calendar Sync และ Audit Log พร้อมตัวกรองและ export
PDF, Excel, CSV, A4, Share และ Google Drive

อัตราค่าตอบแทนเป็นข้อมูลตั้งค่า ไม่ hard-code โดยใช้ลำดับ:

1. Assignment override
2. Employee override
3. Department rate
4. Shift template rate
5. Workspace default

รองรับ fixed rate, hourly, OT, on-call, holiday/night multiplier,
allowances, deductions, preview สูตร, audit และการ lock งวด

## Settings และ Profile

Settings ประกอบด้วย Workspace, Organization/Hospital, Personal Profile,
Shift Templates, Rule Engine, Policy Engine, Allowance & Payroll,
Calendar Mapping, Google Account, Notifications, Holidays & Leave,
Import/Export, Backup/Restore, Appearance, Language, Security และ Developer

Workspace แยกข้อมูลและค่าตั้งทั้งหมดออกจาก workspace อื่นอย่างชัดเจน
Personal Profile เป็น override และต้องไม่แก้ Hospital Profile

Shift Template ต้องแก้รหัส ชื่อย่อ เวลา overnight สี icon calendar
reminder สถานที่ อัตรา OT/holiday rules roles/departments สถานะ และลำดับได้

## Rules, Policies, Conflicts และ Preview

Rule Engine เป็นการตรวจเงื่อนไขแบบ composable มีลำดับ เปิด/ปิดได้ และกำหนด
Error, Warning หรือ Information ต่อ Workspace/Profile

กฎหลักครอบคลุม duplicate, overlap, overnight, leave, holiday, continuous
hours, minimum rest, shift limits, role/department eligibility, calendar,
sync ID, Google event และ invalid/empty source data

Policy Engine กำหนดการตอบสนอง ได้แก่ Ask, Allow, Block, Warn, Merge, Split,
Create, Update, Delete, Skip, Retry, Notify, Require Approval และ Override

ทุก bulk mutation ต้องผ่าน Preview ที่จำแนก Create, Update, Delete,
Unchanged, Skip, Conflict, Warning, Error และ Auto Fixed ผู้ใช้ต้องเลือก
ยืนยันทั้งหมดหรือบางรายการ แก้ไข กรอง ยกเลิก และ export preview ได้

## Google Sheets

```text
Google Sheets
→ Sheet Parser
→ Relationship Engine
→ Shift Mapper
→ Rule Engine
→ Conflict Engine
→ Preview
→ Canonical ScheduleRepository
→ Calendar Workflow
```

รองรับ spreadsheet/sheet/range selection, column mapping, cell validation,
บุคลากร เวร วันที่ เวลา หน่วยงาน หมายเหตุ การแลก เงินเวร Source ID,
checksum, incremental diff, history และ demo mode

## Google Calendar

```text
Canonical Schedule
→ UserShiftEventMapper
→ CalendarEventCandidate
→ CalendarDiffEngine
→ WorkflowPreviewBuilder
→ ShiftCalendarWorkflowController
→ CalendarSyncCoordinator
→ CalendarSyncPlanBuilder
→ ResilientCalendarSyncExecutor
→ GoogleCalendarSyncGateway
```

Roster เป็น source of truth ส่งเฉพาะรายการอนุมัติและเฉพาะเวรของผู้ใช้
รองรับ preview, create/update/delete/skip, retry/resume, history, stable
sync IDs, duplicate prevention, provider-event protection, multiple calendars,
offline queue และ demo mode

## เอกสารและการพิมพ์

รองรับ A4 portrait/landscape รายเดือน รายสัปดาห์ รายบุคคล รายหน่วยงาน
เงินเวร OT และการแลก มีโลโก้ ชื่อหน่วยงาน เดือน/ปี วันที่พิมพ์ legend
หมายเหตุ ลายเซ็น เลขหน้า และ export/print/share/Drive

## Notifications, Permissions และ Audit

แจ้งเตือน in-app, push, email และ calendar reminder สำหรับเวร การแลก
การอนุมัติ Conflict Import Sync และ Google authorization

บทบาทเริ่มต้น: Owner, Administrator, Manager, Approver, Scheduler,
Employee และ Viewer สิทธิ์ต้องตรวจที่ application boundary

Audit เก็บ actor, timestamp, action, before/after, device, workspace,
source, result และ controlled error สำหรับ Login, Import, Schedule CRUD,
Exchange, Rate/Profile change, Sync, Export, Backup และ Restore

## Backup

Export/restore Workspace, Profiles, Templates, Rules, Policies, Allowances,
Calendar mappings, Notifications, Roster และ Employees เป็น versioned JSON
หรือ encrypted ZIP พร้อม preview, merge/replace, automatic backup และ history

## โครงสร้างเป้าหมาย

```text
lib/
├── app/
├── core/
│   ├── config/
│   ├── errors/
│   ├── localization/
│   ├── navigation/
│   ├── permissions/
│   ├── storage/
│   ├── theme/
│   └── utils/
├── features/
│   ├── dashboard/
│   ├── roster/{builder,viewer,editor,printing,import_export}/
│   ├── employees/
│   ├── shift_exchange/
│   ├── payroll/
│   ├── allowance_rules/
│   ├── reports/
│   ├── profiles/{workspace,hospital,personal}/
│   ├── shift_templates/
│   ├── rules/
│   ├── policies/
│   ├── conflicts/
│   ├── sheets/
│   ├── calendar_sync/
│   ├── workflow/
│   ├── notifications/
│   ├── history/
│   ├── backup/
│   └── settings/
├── models/
├── services/
└── main.dart
```

โครงสร้างนี้เป็นทิศทางการย้ายแบบ incremental ไม่ใช่คำสั่งให้ทำสำเนา
โมเดลหรือย้าย compatibility code โดยไม่จำเป็น Canonical `Schedule`,
`ScheduleRepository`, `RuleEvaluator` และ Calendar Workflow เดิมยังเป็น
production boundary หลัก

## แผนพัฒนา

1. Navigation, Dashboard และหน้า top-level responsive
2. Employee Directory, Shift Templates, canonical roster editor และ A4
3. Rule, Conflict, Policy และ Preview engines
4. Exchange, approval, history และ notification
5. Payroll, OT, allowances, summary และ export
6. Google Sheets mapping, relationship และ incremental diff
7. Calendar workflow integration, preview, sync, retry และ history
8. Workspace, profiles, backup และ profile import/export
9. Testing, performance, security, offline support และ release

## กฎการพัฒนา

- ตรวจ repository ก่อนแก้และห้ามลบ Calendar Workflow เดิม
- Canonical Schedule/Roster เป็น source of truth
- ห้าม duplicate model, parser, rule evaluator หรือ service
- แยก Domain, Application, Infrastructure และ Presentation
- Business logic ห้ามอยู่ใน widget
- ใช้ repository interfaces และ AppDependencies เป็น composition root
- UI ต้อง responsive และรองรับ demo mode
- Bulk changes ต้องมี preview; delete ต้องยืนยัน; ข้อมูลสำคัญต้องมี audit
- Google Calendar รับเฉพาะข้อมูลของผู้ใช้ที่ได้รับอนุญาต
- ทุก phase ต้องเพิ่ม tests และผ่าน `dart format .`, `flutter analyze`,
  `flutter test` และ CI
