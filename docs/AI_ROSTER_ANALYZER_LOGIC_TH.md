# AI Roster Analyzer Logic TH

เอกสารนี้เพิ่มตรรกะกลางสำหรับให้แอปอ่านข้อมูลเวรจาก Excel, Google Sheets, Google Calendar, ตารางที่วางเข้ามาเอง และตารางที่ผู้ใช้กรอกเอง โดยมีเป้าหมายให้ระบบเข้าใจว่าแถวหรือช่องข้อมูลใดคือเวร คนประจำ คนแทน คนเสริม คนออฟ คนลา คนขาด หรือแอดไซต์ แล้วรวมเป็นแผนเวรรายวันได้

## เป้าหมาย

1. อ่านข้อมูลเวรจากหลายแหล่งโดยไม่ยึดติดกับรูปแบบตารางเดียว
2. แปลงข้อมูลที่อ่านได้ให้เป็นโครงสร้างกลางเดียวกัน
3. จำแนกประเภทของรายการเวร เช่น เวรปกติ เวรประจำ คนแทน คนเสริม คนออฟ คนลา คนขาด รับเวร แลกเวร และแอดไซต์
4. สร้าง Daily Roster Plan เพื่อให้แอปใช้ต่อกับหน้า UI, Calendar Sync, รายงาน และระบบตรวจความผิดปกติ
5. เก็บ raw cells และ confidence เพื่อให้ผู้ใช้ตรวจทานย้อนหลังได้

## แหล่งข้อมูลที่รองรับ

- Excel Workbook
- Google Sheets
- Google Calendar
- Pasted Table
- Manual Table

ทุกแหล่งข้อมูลต้องถูก normalize เข้าเป็น `RosterInputFrame` ก่อน แล้วส่งเข้า `AiRosterAnalyzer.analyzeFrames()`

## โครงสร้างข้อมูลกลาง

### RosterInputFrame

ใช้แทนหนึ่งตารางหรือหนึ่งช่วงข้อมูล มีข้อมูลหลักดังนี้

- source: แหล่งข้อมูล เช่น Excel, Google Sheet, Calendar
- columns: รายชื่อคอลัมน์
- rows: แถวข้อมูลแบบ key/value

### RosterAnalysisRecord

ใช้แทนหนึ่งรายการที่ AI Analyzer อ่านได้ เช่น

- วันที่
- ประเภทเวร
- ชื่อคน
- ชื่อเวรหรือบทบาท
- จุด/ไซต์/แผนก
- คนที่เกี่ยวข้อง เช่น คนแทนหรือคนรับเวร
- confidence
- notes
- rawCells

### DailyRosterPlan

ใช้รวมรายการทั้งหมดต่อวัน และแยกได้ว่าอะไรคือ duty records หรือ unavailable records

## ประเภทเวรที่ระบบรู้จัก

| ประเภท | ความหมาย |
|---|---|
| primaryDuty | เวรปกติ เช่น เวรเช้า เวรบ่าย เวรดึก ER CT IPD |
| regularStaff | คนประจำ หรือเจ้าของหน้าที่ประจำ |
| replacement | คนแทน หรือคนรับแทน |
| extraStaff | คนเสริม backup support |
| offDuty | ออฟ หยุด พักเวร |
| leave | ลาป่วย ลากิจ ลาพักร้อน หรือ leave |
| absent | ขาด ไม่มา absent missing |
| receivedExchange | รับเวร รับต่อ รับแทน |
| givenExchange | แลกเวร ให้เวร ส่งเวร |
| onsite | แอดไซต์ add site onsite site |
| unknown | อ่านเจอแต่ยังไม่มั่นใจ |

## วิธีอ่านตาราง

ระบบตรวจชื่อคอลัมน์ก่อน เช่น

- วันที่: date, day, วันที่, วัน, เวรวันที่
- คน: name, person, staff, employee, ชื่อ, คนอยู่เวร, ผู้ปฏิบัติงาน, บุคลากร
- เวร/บทบาท: shift, duty, role, ward, เวร, หน้าที่, ตำแหน่ง, แผนก
- ไซต์: site, location, station, จุด, ไซต์, แอดไซต์, สถานที่
- คนที่เกี่ยวข้อง: แทน, รับต่อ, แลก, ผู้แทน, replacement, exchange
- หมายเหตุ: note, remark, comment, หมายเหตุ, บันทึก

ถ้าไม่พบคอลัมน์ชัดเจน ระบบยังพยายามอ่านจาก raw text ของแถวนั้น และลด confidence ลง

## วิธีจำแนกประเภทเวร

ตัววิเคราะห์ใช้ keyword และ pattern ทั้งภาษาไทยและอังกฤษ เช่น

- ออฟ, หยุด, off -> offDuty
- ลาป่วย, ลากิจ, leave -> leave
- ขาด, ไม่มา, absent -> absent
- รับเวร, รับต่อ, received -> receivedExchange
- แลกเวร, ให้เวร, swap out -> givenExchange
- แทน, replacement -> replacement
- เสริม, backup, support -> extraStaff
- แอดไซต์, add site, onsite -> onsite
- ประจำ, regular, owner -> regularStaff
- เวร, เช้า, บ่าย, ดึก, ER, CT, IPD -> primaryDuty

## การตรวจความผิดปกติรายวัน

`DailyRosterPlan` จะมี warnings เช่น

- มีคนถูกจัดเวร ทั้งที่วันเดียวกันถูกระบุว่าออฟ/ลา/ขาด
- มีรายการที่ระบบยังจำแนกไม่ได้
- ข้อมูลวันที่หรือชื่อคนไม่ชัดเจน

## แนวทางต่อยอดเข้าหน้าแอป

ขั้นถัดไปควรต่อ AI Analyzer เข้ากับจุดเหล่านี้

1. Excel Import: หลังอ่านไฟล์ ให้แปลงแถวเป็น `RosterInputFrame`
2. Google Sheets Import: หลังอ่าน range ให้แปลงเป็น `RosterInputFrame`
3. Calendar Import: แปลง event title/description/time เป็น `RosterInputFrame`
4. Dashboard: แสดงจำนวนเวร รายการ warning และคนที่ขาด/ลา/ออฟ
5. Schedule Workspace: เปิดให้ผู้ใช้กดตรวจทานและยืนยันก่อนบันทึกลง canonical schedule
6. Calendar Sync: ใช้เฉพาะรายการที่ผ่านการยืนยันหรือ confidence สูงพอ

## ข้อกำหนดสำคัญ

- ห้ามแก้ Excel/Google Sheet ต้นฉบับโดยอัตโนมัติ
- ห้ามสร้าง Calendar event โดยไม่ให้ผู้ใช้ preview และยืนยันก่อน
- ต้องเก็บ rawCells ทุกครั้งเพื่อ audit ได้
- ถ้า confidence ต่ำ ต้องแสดงให้ผู้ใช้ตรวจสอบ ไม่ควร sync ทันที
- การอ่านเวรต้องรองรับทุกเดือน ทุกปี และช่วงเวลายาว โดยไม่ hard-code เฉพาะวันใดวันหนึ่ง

## ไฟล์โค้ดที่เพิ่ม

- `lib/features/ai_roster_analyzer/domain/roster_analysis_models.dart`
- `lib/features/ai_roster_analyzer/application/ai_roster_analyzer.dart`
- `lib/features/ai_roster_analyzer/ai_roster_analyzer.dart`
