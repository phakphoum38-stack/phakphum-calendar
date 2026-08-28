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

1. เปิดหน้า Actions ของ repository
2. ดาวน์โหลด artifact `phakphum-calendar-android-apk` จาก run ที่สำเร็จ
3. แตก ZIP และตรวจ `SHA256SUMS.txt`
4. เปิด `app-release.apk` แล้วอนุญาตติดตั้งจากแหล่งนี้เฉพาะเมื่อเชื่อถือได้

APK จาก CI ยังไม่ใช่ไฟล์สำหรับ Play Store และอาจใช้ debug signing
ห้ามใช้เป็น production release จนกว่าจะตั้ง release keystore ใน GitHub Secrets

### Windows

1. ดาวน์โหลด artifact `phakphum-calendar-windows`
2. แตก artifact และ ZIP ด้านใน
3. เก็บไฟล์ `.exe`, `.dll` และโฟลเดอร์ `data` ไว้ด้วยกัน
4. เปิด `phakphum_calendar.exe`

Google Sign-In แบบ native ยังไม่รองรับใน Windows workflow ปัจจุบัน
ให้ใช้ Web/PWA เมื่อต้องทำงานกับ Google

### macOS

1. ดาวน์โหลดและแตก `phakphum-calendar-macos`
2. ย้ายแอปไป `/Applications`
3. ตรวจลายเซ็นและแหล่งที่มาของ artifact ก่อนอนุญาตให้เปิด

artifact ปัจจุบันอาจยังไม่ notarize จึงไม่ควรแจกจ่ายสาธารณะโดยไม่ลงนาม

### Linux

ติดตั้ง runtime ที่จำเป็นบน Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y libgtk-3-0 libstdc++6
tar -xzf phakphum-calendar-linux.tar.gz
./phakphum_calendar
```

## 2. ตรวจสอบไฟล์ก่อนติดตั้ง

เปรียบเทียบ SHA-256 กับ `SHA256SUMS.txt` ที่อยู่ใน artifact:

```bash
# Linux
sha256sum -c SHA256SUMS.txt

# macOS
shasum -a 256 FILE_NAME
```

Windows PowerShell:

```powershell
Get-FileHash .\FILE_NAME -Algorithm SHA256
Get-Content .\SHA256SUMS.txt
```

## 3. ตั้งค่า Google Cloud

1. สร้างหรือเลือก Google Cloud project ที่องค์กรควบคุม
2. เปิด Google Sheets API, Google Drive API และ Google Calendar API
3. ตั้ง OAuth consent screen
4. สร้าง OAuth Client สำหรับแพลตฟอร์มที่ใช้งาน
5. Web ต้องเพิ่ม GitHub Pages URL ใน Authorized JavaScript origins
6. ห้าม commit Client Secret, access token, refresh token หรือ service-account key

รายละเอียดแพลตฟอร์มและค่า OAuth อยู่ที่ [GOOGLE_SETUP.md](GOOGLE_SETUP.md)

## 4. เลือกภาษา

Shift Tools รองรับภาษาไทยและอังกฤษ กดไอคอนรูปโลกบน AppBar เพื่อสลับภาษา
การสลับภาษามีผลเฉพาะข้อความแสดงผล ไม่เปลี่ยนวันที่ที่จัดเก็บ Schedule ID,
sync ID หรือข้อมูลตารางเวร

## 5. นำเข้าตารางเวร

### Excel

1. เปิด **นำเข้า Excel**
2. เลือกไฟล์ `.xlsx`
3. เลือก worksheet
4. ตรวจ preview 50 แถวแรก
5. จับคู่คอลัมน์ Date, Shift และ Employee
6. จับคู่ Department, Location และ Notes เมื่อตารางมีข้อมูล
7. ตรวจ error/warning แล้วจึงดำเนินการนำเข้า

preview จำกัด 50 แถวเพื่อความลื่นไหล แต่การนำเข้าจริงอ่านทุกแถว

### Google Sheets

1. ล็อกอินด้วยบัญชี Google ที่ได้รับอนุญาต
2. เลือกไฟล์จาก Drive หรือวาง URL/Spreadsheet ID
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

