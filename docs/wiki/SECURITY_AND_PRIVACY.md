# Security and Privacy

## ข้อมูลที่ห้ามเก็บใน Repository

- OAuth client secret และ access/refresh token
- service-account key
- URL หรือ ID ของชีตส่วนตัว
- ชื่อจริง ตารางเวรจริง เบอร์โทร หรือข้อมูลผู้ป่วย
- screenshot ที่มีข้อมูลระบุตัวบุคคล

## แนวทางสิทธิ์ Google

- ใช้ scope แบบ read-only สำหรับการค้นหาและอ่านเมื่อเพียงพอ
- ขอสิทธิ์เขียน Calendar เฉพาะเมื่อผู้ใช้เริ่มการซิงก์
- แสดง Preview และขอการยืนยันก่อนเขียน
- ตรวจ ownership และบัญชีที่ใช้งานให้ชัดเจน

## Local data

- เก็บเฉพาะข้อมูลที่จำเป็น
- แยกข้อมูลตามบัญชี Google
- มีคำสั่งล้างประวัติ/การตั้งค่าในอนาคต
- ข้อมูลที่ persist ต้องมี schema version และรองรับ migration

## Incident handling

เมื่อสงสัยว่า secret รั่ว:

1. ยกเลิกหรือ rotate credential ทันที
2. ลบ secret ออกจากประวัติ Git ไม่ใช่แค่ commit ล่าสุด
3. ตรวจ logs และการใช้งานผิดปกติ
4. บันทึกเหตุการณ์และเพิ่มมาตรการป้องกันซ้ำ
