# Release Process

## Versioning

ใช้ Semantic Versioning:

- `MAJOR` เปลี่ยน behavior/API ที่เข้ากันไม่ได้
- `MINOR` เพิ่มฟีเจอร์ที่เข้ากันได้
- `PATCH` แก้ bug โดยไม่เปลี่ยน contract

## Release checklist

1. CI validation และ tests ผ่านทั้งหมด
2. ทดสอบ parser กับตัวอย่างตารางเวรจริงที่ลบข้อมูลระบุตัวบุคคลแล้ว
3. ทดสอบ Preview, conflict decision และ duplicate protection
4. ทดสอบ Calendar write ด้วยบัญชีทดสอบ
5. ตรวจ OAuth configuration ของแต่ละ platform
6. ตรวจว่าไม่มี secret หรือข้อมูลจริงใน artifact/log
7. อัปเดต `CHANGELOG.md`, `ROADMAP.md` และ version ใน `pubspec.yaml`
8. สร้าง tag เช่น `v0.7.0`
9. ดาวน์โหลดและ smoke-test artifacts จาก GitHub Actions
10. เผยแพร่แบบ staged rollout ก่อน production เต็มรูปแบบ

## Rollback

- เก็บ release artifact ก่อนหน้าอย่างน้อยหนึ่งรุ่น
- Calendar events ต้องค้นหาได้ด้วย managed sync ID
- เมื่อพบปัญหา ให้หยุด rollout, ปิด feature flag ที่เกี่ยวข้อง และออก patch
