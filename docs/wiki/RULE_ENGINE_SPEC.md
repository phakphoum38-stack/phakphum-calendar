# Rule Engine Specification

## วัตถุประสงค์

Rule Engine แปลงเวรต้นทางเป็นผลลัพธ์ที่ตรวจสอบได้ เช่น การเพิ่ม OFF หลังเวรดึก การห้ามเวรต่อเนื่องที่ไม่ปลอดภัย และการแจ้ง conflict โดยไม่ผูกกับ UI หรือ Google Calendar

## Domain model เป้าหมาย

```dart
class ShiftRule {
  final String id;
  final String name;
  final bool enabled;
  final RuleCondition condition;
  final List<RuleAction> actions;
  final RuleSeverity severity;
  final int priority;
}
```

แนวคิดหลัก:

- `RuleCondition` ตรวจชนิดเวร หน่วยงาน เวลา วัน หรือเวรก่อนหน้า/ถัดไป
- `RuleAction` เพิ่ม OFF, สร้าง warning, block sync หรือเสนอการแก้ไข
- `RuleSeverity` แบ่ง `info`, `warning`, `blocking`
- `priority` ทำให้ผลลัพธ์ deterministic

## กฎเริ่มต้น

| Rule ID | เงื่อนไข | ผลลัพธ์ | ระดับ |
|---|---|---|---|
| `night_rest_same_day` | เวร 00:00–08:00 | เพิ่ม OFF 08:00–16:00 วันเดียวกัน | warning/block เมื่อชน |
| `afternoon_to_morning` | เวรบ่ายตามด้วยเวรเช้าระยะพักต่ำกว่ากำหนด | แจ้งเตือน | warning |
| `overlapping_shifts` | เวรซ้อนเวลา | หยุด Sync จนตัดสินใจ | blocking |
| `unknown_shift_time` | รหัสเวรไม่มีเวลา | หยุด Sync | blocking |
| `duplicate_managed_event` | มี managed event เดิมตรงกัน | ไม่สร้างซ้ำ | info |

## Execution contract

Input:

- รายการเวรที่ normalize แล้ว
- ช่วงวันที่
- hospital profile
- rule set version

Output:

- รายการเดิมและรายการที่สร้างเพิ่ม
- warnings/conflicts พร้อม rule ID
- blocked items
- audit trace ว่ากฎใดเปลี่ยนอะไร

## Safety

- Rule Engine ห้ามเขียน Calendar โดยตรง
- กฎที่สร้าง/ลบรายการต้องแสดงใน Simulation Preview
- กฎที่เปลี่ยนความหมายเวรต้องมี version และ migration note
- ผลลัพธ์ของชุดกฎเดียวกันกับ input เดียวกันต้องเหมือนกันเสมอ
