# คู่มือติดตั้งและใช้งาน Shift Tools

คู่มือนี้ครอบคลุมการติดตั้งแอป การตั้งค่า Google การนำเข้าตารางเวร
การตรวจสอบก่อนซิงก์ การออกรายงาน และการติดตั้ง Laravel API สำหรับผู้ดูแลระบบ

## 1. เลือกวิธีติดตั้งแอป

### Web / PWA

1. เปิด `https://phakphoum38-stack.github.io/phakphum-calendar/`
2. ใช้ Chrome, Edge หรือ Safari รุ่นปัจจุบัน
3. กด **ติดตั้งแอป** จากแถบที่อยู่หรือเมนูของเบราว์เซอร์เมื่อต้องการใช้แบบ PWA
4. บน iPhone/iPad ใช้ Safari → Share → **Add to Home Screen**

### Android


sha256sum -c SHA256SUMS.txt
## Quick Start (Local development)

Follow these steps for a fast local development setup. Prefer using the Docker commands
if you don't have matching platform tool versions locally.

1. Install Flutter SDK (stable) and ensure `flutter` is on your PATH. Verify with:

```bash
flutter --version
```

2. Run the Flutter app (from repo root):

```bash
flutter pub get
flutter run
```

3. Backend (Laravel) local setup — recommended: Docker fallback if your PHP version
   does not match project requirements (project requires PHP >= 8.4):

Local (if PHP & Composer match project requirement):

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

Docker (when local PHP is older than project requirement):

```bash
# Install composer deps using the official composer image
1. ล็อกอินด้วยบัญชี Google ที่ได้รับอนุญาต

# Serve with PHP 8.4 container (adjust port mapping as needed)
2. เลือกไฟล์จาก Drive หรือวาง URL/Spreadsheet ID
  sh -c "php artisan migrate --seed && php artisan serve --host=0.0.0.0 --port=8000"
```

4. Health checks (once backend is running):

```bash
curl http://127.0.0.1:8000/api/v1/health
curl http://127.0.0.1:8000/api/v1/ready
```

Notes:
- If `composer install` fails due to PHP version, use the Docker commands above.
- Keep your Flutter SDK on the stable channel for compatibility with CI artifacts.

## เวลาเวรมาตรฐานและการแมปสี

ส่วนนี้สรุปเวลาเวรมาตรฐาน การสร้างรายการ OFF สำหรับเวรดึก การแมปสีจากไฟล์หลักไปยัง Google Calendar และพฤติกรรมเมื่อพบรายการชน

เวลาเวรมาตรฐาน (ประเภทเวร → เวลา):

- P1/P2/P3/P4 เช้า: 08:00–16:00
- P1/P2/P3/P4 บ่าย: 16:00–00:00
- P1/P2/P3/P4 ดึก: 00:00–08:00
- IPD เช้า: 08:00–16:00
- IPD บ่าย: 16:00–08:00 (วันถัดไป)
- CT IPD เช้า: 08:00–16:00
- CT IPD บ่าย: 16:00–08:00 (วันถัดไป)
- CT ER เช้า: 08:00–16:00
- CT ER บ่าย: 16:00–08:00 (วันถัดไป)
- ER เช้า: 08:00–16:00
- ER บ่าย: 16:00–00:00
- ER ดึก: 00:00–08:00
- GEN เช้า: 07:30–12:00
- GEN บ่าย: 16:30–20:00
- 14 ชั้น เช้า: 07:00–08:00

สีจากไฟล์หลักไปยัง Google Calendar

แอปจะอ่านสีพื้นหลังจาก Google Sheets (`effectiveFormat`) หรือจากรูปแบบเซลล์ในไฟล์ `.xlsx` เพื่อเสนอสี Calendar ที่จะใช้ในหน้า ตัวอย่าง ผู้ใช้สามารถแก้ประเภท เวลาหรือพิมพ์เลขสี 1–11 หรือชื่อสีเพื่อปรับก่อนบันทึก

ตารางตัวอย่างการแมปสี (สีในไฟล์หลัก → ความหมาย → สี Google Calendar):

 - กราไฟต์ → เวรของตัวเอง → กราไฟต์
 - มะเขือเทศ → เวรคนอื่น → มะเขือเทศ
3. เลือก worksheet
4. ตรวจ preview และจับคู่คอลัมน์เหมือน Excel

แอปไม่แก้ Google Sheets ต้นฉบับในขั้นตอนอ่านข้อมูล

## 6. ตรวจปฏิทินและกฎ

1. เปิดปฏิทินรายเดือนหลังนำเข้าสำเร็จ
2. เลือกวันเพื่อตรวจพนักงานและเวรทั้งหมด
3. ใช้ตัวกรองชื่อ ตำแหน่ง แผนก หรือประเภทเวร
4. ตรวจ Errors และ Warnings จาก Rule Engine
5. ห้ามซิงก์เมื่อมี blocking error

คำเตือนอนุญาตให้ดำเนินการได้เมื่อผู้ใช้ตรวจและยืนยันแล้ว

## 7. ซิงก์ Google Calendar

ลำดับการทำงานคือ Validation → Diff → Preview → Confirmation → Execution
→ History/Resume

1. เปรียบเทียบ Calendar ก่อนทุกครั้ง
2. ตรวจรายการเพิ่ม แก้ และลบ
3. แก้ blocking error ให้หมด
4. ตรวจ warning และรายการชน
5. กดยืนยันเมื่อผลลัพธ์ถูกต้อง
6. หากเกิด partial failure ให้ใช้ Retry/Resume เดิม ห้ามเริ่มสร้างรายการซ้ำ

Shift Tools ใช้ stable sync ID ป้องกันกิจกรรมซ้ำ การเปลี่ยนภาษาไม่มีผลต่อ ID

## 8. สร้างรายงาน PDF

1. เปิดแท็บ **รายงาน**
2. เลือกเดือนและแผนก
3. กด **สร้างตัวอย่าง**
4. ตรวจตาราง คำอธิบายเวร สรุป และช่องลายเซ็น
5. เลือก **พิมพ์** หรือ **บันทึก / แชร์ PDF**

รายงาน A4 รองรับภาษาไทยและอังกฤษ ชื่อพนักงาน รหัสเวร และชื่อแผนกเป็นข้อมูลจริง
จึงไม่ถูกแปลอัตโนมัติ

## 9. ติดตั้ง Laravel API สำหรับผู้ดูแลระบบ

Laravel API อยู่ใน `backend/` และไม่จำเป็นต่อการเปิดแอป Flutter ในโหมดปัจจุบัน

### ติดตั้งด้วย PHP และ Composer

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate
php artisan serve
```

ตรวจระบบ:

```bash
curl http://127.0.0.1:8000/api/v1/health
curl http://127.0.0.1:8000/api/v1/ready
```

### ติดตั้งด้วย Docker โดยไม่ลง PHP ในเครื่อง

```bash
docker run --rm -v "$PWD/backend:/app" -w /app composer:2 composer install
docker run --rm -p 8000:8000 -v "$PWD/backend:/app" -w /app php:8.4-cli \
  php artisan serve --host=0.0.0.0 --port=8000
```

สำหรับ production ให้ใช้เว็บเซิร์ฟเวอร์และฐานข้อมูลที่องค์กรดูแล ตั้ง `APP_ENV=production`,
`APP_DEBUG=false`, HTTPS, secret management, log retention และ monitoring
อย่าใช้ `php artisan serve` เป็น production server

## 10. API สำหรับตรวจปัญหา

| Endpoint | การใช้งาน |
| --- | --- |
| `GET /api/v1/health` | ตรวจ process ว่ายังทำงาน |
| `GET /api/v1/ready` | ตรวจว่าฐานข้อมูลพร้อม |
| `POST /api/v1/diagnostics/client-errors` | รับ error report ที่ validate และ rate-limit |

Diagnostics API ไม่ควรรับ OAuth token, URL ชีตส่วนตัว, ตารางเวร, ชื่อพนักงาน
หรือข้อมูลส่วนบุคคล ระบบตอบ `X-Request-ID` เพื่อใช้จับคู่เหตุการณ์ใน log

## 11. แก้ปัญหาเบื้องต้น

- **Google Login ไม่ทำงาน:** ตรวจ OAuth client, origin, bundle ID และ API ที่เปิดใช้งาน
- **ไม่พบชีต:** ตรวจว่าบัญชีปัจจุบันเป็นเจ้าของไฟล์และมีสิทธิ์อ่าน
- **นำเข้าไม่ครบ:** preview แสดง 50 แถว แต่ summary ต้องนับทุกแถว
- **PDF ภาษาไทยเป็นสี่เหลี่ยม:** ตรวจเครือข่ายสำหรับโหลดฟอนต์และลองสร้างใหม่
- **Calendar มี warning:** อย่าฝืนซิงก์จนกว่าจะตรวจรายการชน
- **API ตอบ 503 ที่ `/ready`:** ตรวจ `DB_CONNECTION` และสิทธิ์ฐานข้อมูล
- **GitHub Actions ไม่ผ่าน:** เปิด log ของ job ที่ล้ม แก้ที่ต้นเหตุ แล้ว rerun failed jobs

## 12. ความปลอดภัย

- ห้าม commit `.env`, token, key, roster จริง หรือข้อมูลส่วนบุคคล
- ใช้ read-only Google scopes เมื่อเพียงพอ
- ตรวจ preview ก่อน external write
- ใช้ HTTPS สำหรับ API production
- สำรองฐานข้อมูลและกำหนด retention ของ diagnostic logs

ดูรายละเอียดเพิ่มเติมที่ [SECURITY.md](../SECURITY.md)
<<<<<<< Updated upstream
=======

## Quick Start (Local development)

Follow these steps for a fast local development setup. Prefer using the Docker commands
if you don't have matching platform tool versions locally.

1. Install Flutter SDK (stable) and ensure `flutter` is on your PATH. Verify with:

```bash
flutter --version
```

2. Run the Flutter app (from repo root):

```bash
flutter pub get
flutter run
```

3. Backend (Laravel) local setup — recommended: Docker fallback if your PHP version
   does not match project requirements (project requires PHP >= 8.4):

Local (if PHP & Composer match project requirement):

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

Docker (when local PHP is older than project requirement):

```bash
# Install composer deps using the official composer image
docker run --rm -v "$PWD/backend:/app" -w /app composer:2 composer install

# Serve with PHP 8.4 container (adjust port mapping as needed)
docker run --rm -p 8000:8000 -v "$PWD/backend:/app" -w /app php:8.4-cli \
  sh -c "php artisan migrate --seed && php artisan serve --host=0.0.0.0 --port=8000"
```

4. Health checks (once backend is running):

```bash
curl http://127.0.0.1:8000/api/v1/health
curl http://127.0.0.1:8000/api/v1/ready
```

Notes:
- If `composer install` fails due to PHP version, use the Docker commands above.
- Keep your Flutter SDK on the stable channel for compatibility with CI artifacts.

## เวลาเวรมาตรฐานและการแมปสี

ส่วนนี้สรุปเวลาเวรมาตรฐาน การสร้างรายการ OFF สำหรับเวรดึก การแมปสีจากไฟล์หลักไปยัง Google Calendar และพฤติกรรมเมื่อพบรายการชน

เวลาเวรมาตรฐาน (ประเภทเวร → เวลา):

- P1/P2/P3/P4 เช้า: 08:00–16:00
- P1/P2/P3/P4 บ่าย: 16:00–00:00
- P1/P2/P3/P4 ดึก: 00:00–08:00
- IPD เช้า: 08:00–16:00
- IPD บ่าย: 16:00–08:00 (วันถัดไป)
- CT IPD เช้า: 08:00–16:00
- CT IPD บ่าย: 16:00–08:00 (วันถัดไป)
- CT ER เช้า: 08:00–16:00
- CT ER บ่าย: 16:00–08:00 (วันถัดไป)
- ER เช้า: 08:00–16:00
- ER บ่าย: 16:00–00:00
- ER ดึก: 00:00–08:00
- GEN เช้า: 07:30–12:00
- GEN บ่าย: 16:30–20:00
- 14 ชั้น เช้า: 07:00–08:00

สีจากไฟล์หลักไปยัง Google Calendar

แอปจะอ่านสีพื้นหลังจาก Google Sheets (`effectiveFormat`) หรือจากรูปแบบเซลล์ในไฟล์ `.xlsx` เพื่อเสนอสี Calendar ที่จะใช้ในหน้า ตัวอย่าง ผู้ใช้สามารถแก้ประเภท เวลาหรือพิมพ์เลขสี 1–11 หรือชื่อสีเพื่อปรับก่อนบันทึก

ตารางตัวอย่างการแมปสี (สีในไฟล์หลัก → ความหมาย → สี Google Calendar):

 - กราไฟต์ → เวรของตัวเอง → กราไฟต์
 - มะเขือเทศ → เวรคนอื่น → มะเขือเทศ
 - ฟ้า → เวรคลินิก → ฟ้า
 - ลาเวนเดอร์ → แลกเวรใหญ่ → มะเขือเทศ
 - เผือก → เวรคลินิก (แบบพิเศษ) → อะโวคาโด
 - กล้วยหอม → ยืมชื่อเวร (ไม่จ่าย) → กล้วย/เหลือง
 - นกแก้ว → ยืมชื่อเวร (จ่าย) → เขียว
 - ลาเวนเดอร์ → ยกเวร → ลาเวนเดอร์

หมายเหตุ: เนื่องจาก `แลกเวรใหญ่` และ `ยกเวร` ใช้สีลาเวนเดอร์ต้นทางเหมือนกัน แอปจะเตือนให้ผู้ใช้ตรวจประเภทในหน้า ตัวอย่าง แทนการเดาส่งสีโดยอัตโนมัติ

เวรดึก, OFF และการตรวจรายการชน

- เวรที่ทำงานช่วง 00:00–08:00 จะสร้างรายการ `OFF` อัตโนมัติในช่วง 08:00–16:00 ของวันเดียวกัน (รายการพักหลังเวรดึก)
- ชื่อกิจกรรมใน Calendar จะใช้ชื่อเวรจากชีตพร้อมรหัส เช่น `P1 เช้า (UP1)` และรายการพักใช้ชื่อ `OFF`
- แอปตรวจการชนกันในหลายชั้น: เวรในชีตชนกัน, เวรชนช่วง `OFF`, เวรชนกิจกรรมเดิมใน Google Calendar, และกิจกรรม Calendar ที่ชนช่วง `OFF` (08:00–16:00)
- กิจกรรม Calendar ที่ตั้งเป็นว่าง (transparent) และกิจกรรมที่แอปเคยสร้างเองจะไม่ถูกแจ้งซ้ำ
- เมื่อพบรายการชน แอปจะแจ้งป็อปอัพและหยุดการเขียน Calendar จนกว่าจะให้ผู้ใช้เลือกหนึ่งใน: รับทราบและคงไว้, ยืนยันรายการ, หรือไม่นำเข้าปฏิทิน
- ก่อนการเขียนจริง แอปจะอ่าน Calendar อีกครั้งเพื่อป้องกันการชนกับกิจกรรมที่เพิ่มหลังการเปรียบเทียบครั้งแรก
- รายการชนจาก Calendar มีปุ่ม `เปิดกิจกรรม` และ `ลบกิจกรรม` — การลบจะขอสิทธิ์เขียนและขอการยืนยันจากผู้ใช้ก่อนดำเนินการ
- การตัดสินใจและการยกเว้นที่ผู้ใช้เลือกจะถูกเก็บไว้เฉพาะในอุปกรณ์/เบราว์เซอร์ของผู้นั้นเท่านั้น ไม่ถูกอัปโหลดไปยัง repository

แท็บบันทึก (Save sheet references)

- `เปิด` — เปิดชีตจริงด้วยบัญชีที่ล็อกอิน (การแก้ไขขึ้นกับสิทธิ์ Google ของบัญชี)
- `ลบ` — ลบเฉพาะรายการอ้างอิงในแอป ไม่ลบไฟล์ Google Sheets ต้นทาง
- `สร้างชีตเดือนล่วงหน้า` — คัดลอกแท็บต้นแบบเป็นแท็บใหม่ ผู้ใช้ต้องตรวจวันที่และรายชื่อในแท็บใหม่ก่อนใช้งาน

Auto refresh และสำเนาต้นฉบับ

- Auto refresh สามารถตั้งช่วง 1–60 วินาทีได้ (รอบใหม่จะไม่ซ้อนกับรอบที่ยังทำงาน)
- ระวังช่วง 1 วินาที อาจกระทบโควตา Google Sheets API — เมื่อพบ `429` ให้เพิ่มช่วงเป็น 2–10 วินาที
- เมื่อเปิดการเก็บสำเนา แอปจะสร้างสำเนาต้นฉบับใน Drive หนึ่งครั้งต่อไฟล์และเดือนก่อนซิงก์ โดยไม่แก้หรือไม่ลบไฟล์ต้นฉบับ
- ไฟล์ที่อัปโหลดจากเครื่อง (local files) จะไม่ถูก Auto refresh และจะไม่ถูกอัปโหลดไป Drive อัตโนมัติ

ค่าเริ่มต้นและความยืดหยุ่น

ผู้ใช้สามารถแก้ไขประเภท เวลาชื่อเวร และสีได้อย่างยืดหยุ่น ค่าเริ่มต้นของฟิลด์จะเป็นค่าว่างเพื่อบังคับให้ผู้ใช้ยืนยันก่อนบันทึก


>>>>>>> Stashed changes
