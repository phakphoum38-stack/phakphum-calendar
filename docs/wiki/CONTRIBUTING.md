# Contributing Guide

## Workflow

1. สร้าง branch จาก `main`
2. ใช้ชื่อเช่น `feat/rule-engine-core` หรือ `fix/thai-period-parser`
3. แก้โค้ดพร้อม test
4. รัน validation ในเครื่อง
5. เปิด Pull Request พร้อมสรุปผลกระทบและหลักฐานการทดสอบ
6. Merge เมื่อ CI ผ่านและ review เรียบร้อย

## Pull Request checklist

- [ ] อธิบายปัญหาและแนวทางแก้
- [ ] มี test สำหรับ behavior ใหม่หรือ bug fix
- [ ] `dart format`, `flutter analyze`, `flutter test` ผ่าน
- [ ] ไม่มี token, secret, URL ส่วนตัว หรือข้อมูลจริง
- [ ] อัปเดต docs/CHANGELOG เมื่อจำเป็น
- [ ] UI ที่เปลี่ยนมีภาพประกอบหรือคำอธิบายผลลัพธ์

## Review priorities

1. ความปลอดภัยของตารางเวรและข้อมูลส่วนตัว
2. ความถูกต้องของเวลา วันที่ และ conflict
3. ป้องกันการสร้าง Calendar ซ้ำ
4. ความสามารถในการย้อนกลับ/ทำต่อเมื่อ sync ล้มเหลว
5. ความอ่านง่ายและความสามารถในการทดสอบ
