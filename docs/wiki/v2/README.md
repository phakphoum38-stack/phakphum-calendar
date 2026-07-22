# Version 2.0 Foundation

Version 2.0 ยกระดับแอปจากปฏิทินเวรส่วนบุคคลเป็นระบบที่รองรับองค์กรและแผนก โดยวางแกนกลางที่ไม่ผูกกับฐานข้อมูลหรือผู้ให้บริการ Cloud รายใด

## โมดูลที่เพิ่มแล้ว

- `organization`: โรงพยาบาลและแผนกแบบหลายองค์กร
- `access_control`: RBAC สำหรับ Staff, Incharge, Manager และ Admin
- `shift_exchange`: สถานะคำขอแลกเวรและบริการอนุมัติ
- `audit`: สัญญา Audit Log ที่บันทึกผู้กระทำ เวลา และข้อมูลประกอบ
- `rule_engine`: กฎตรวจเวรซ้อน เวลาพักขั้นต่ำ และชั่วโมงทำงานสูงสุด

## ขอบเขตความปลอดภัย

- Domain model ไม่มี token หรือข้อมูลรับรอง
- การอนุมัติแลกเวรตรวจสิทธิ์ก่อนเปลี่ยนสถานะ
- ทุกการอนุมัติผ่าน application service ต้องสร้าง Audit Event
- กฎที่เป็น blocking ต้องหยุดการ Sync จนกว่าผู้มีสิทธิ์แก้ไข

## งานถัดไป

1. เพิ่ม persistent repository สำหรับองค์กร บุคลากร และคำขอแลกเวร
2. เชื่อม Rule Engine เข้ากับ Simulation Preview
3. เพิ่มหน้า Organization Switcher และ Shift Exchange Inbox
4. เพิ่ม optimistic concurrency และ offline outbox
5. เพิ่ม Cloud API พร้อม tenant isolation
