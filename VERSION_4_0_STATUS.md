# Phakphum Calendar v4.0

## ขอบเขตการปรับปรุง

- ปรับ Branding เป็น Phakphum Calendar v4.0
- เพิ่ม Hospital Workspace hero บน Dashboard
- ปรับ Material 3 theme, cards, navigation, buttons และ form fields
- ปรับ responsive layout สำหรับมือถือ แท็บเล็ต และเดสก์ท็อป
- คงตรรกะเดิมของ Google Sign-In, การอ่าน Google Sheets แบบ read-only,
  การตรวจรายการซ้ำ และ guarded Google Calendar sync
- อัปเดต Web title และ metadata
- อัปเดตเวอร์ชันเป็น 4.0.0+10

## หลักการด้านข้อมูล

Version 4.0 ไม่เปลี่ยนกฎความปลอดภัยของข้อมูลเดิม:

1. ขอสิทธิ์ Google ตามความจำเป็น
2. อ่านชีตต้นฉบับแบบ read-only
3. ตรวจสิทธิ์ความเป็นเจ้าของไฟล์ก่อนใช้งาน
4. เปรียบเทียบ Calendar ก่อนบันทึก
5. บันทึก Audit และแสดง Notification ตาม controller เดิม
