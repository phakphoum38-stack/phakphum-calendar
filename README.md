# Phakphum Shift Calendar

[![Validate Flutter](https://github.com/phakphoum38-stack/phakphum-calendar/actions/workflows/validate.yml/badge.svg)](https://github.com/phakphoum38-stack/phakphum-calendar/actions/workflows/validate.yml)
[![Android APK](https://github.com/phakphoum38-stack/phakphum-calendar/actions/workflows/android.yml/badge.svg)](https://github.com/phakphoum38-stack/phakphum-calendar/actions/workflows/android.yml)
[![iOS IPA](https://github.com/phakphoum38-stack/phakphum-calendar/actions/workflows/ios.yml/badge.svg)](https://github.com/phakphoum38-stack/phakphum-calendar/actions/workflows/ios.yml)

แอป Flutter สำหรับอ่านตารางเวรจาก Google Sheets แบบ Read-only ตรวจเวรซ้อนและเวรออฟ แล้วสร้างกิจกรรมใน Google Calendar บน Android, iOS และ Web

- เวอร์ชันปัจจุบัน: `1.1.0+2`
- Android package: `com.phakphoum.phakphum_calendar`
- iOS bundle ID: `com.phakphoum.phakphumCalendar`
- Time zone: `Asia/Bangkok`

## ความสามารถหลัก

- ล็อกอินด้วยบัญชี Google และขอสิทธิ์เฉพาะเมื่อจำเป็น
- อ่าน Google Sheets ด้วย `spreadsheets.readonly` โดยไม่แก้ไฟล์ต้นฉบับ
- ค้นหาเวรตามชื่อ เดือน และปี
- รีเฟรชทันทีหรือ Auto refresh ทุก 1–10 วินาที
- Preview และเลือกกิจกรรมที่จะบันทึก พร้อมกำหนดประเภท/สี
- เปรียบเทียบกับ Google Calendar และไม่สร้างกิจกรรมเดิมซ้ำ
- สร้างเวร `OFF` เวลา 08:00–16:00 หลังเวรดึก 00:00–08:00
- ตรวจเวรซ้อนจากชีต เวรที่ชนช่วง OFF และเวรที่ชนกิจกรรมใน Calendar
- บล็อกการซิงก์ Calendar จนกว่าจะแก้แจ้งเตือนที่ค้างครบ
- เก็บสำเนาไฟล์ต้นฉบับประจำเดือนใน Google Drive โดยไม่สร้างซ้ำ
- สร้างแท็บเดือนล่วงหน้าจากแท็บต้นแบบเมื่อผู้ใช้สั่งและยืนยัน passkey
- เก็บ Audit log ในอุปกรณ์สูงสุด 200 รายการ
- มีแท็บ `Adsite ตารางเวร` แบบว่างสำหรับเพิ่มข้อมูลในภายหลัง

## ขั้นตอนใช้งาน

1. เปิดแอปและกด **เข้าสู่ระบบด้วย Google**
2. ใส่ลิงก์ Google Sheets ชื่อที่ต้องค้นหา เดือน และปี
3. กด **รีเฟรช/อ่านใหม่ตอนนี้**
4. กด **เปรียบเทียบ Calendar** เพื่อค้นหากิจกรรมภายนอกที่ชนกัน
5. เปิดแท็บ **แจ้งเตือน** แล้วตัดสินใจทุกรายการ
6. ตรวจรายการและสีในแท็บ **ตัวอย่าง**
7. กด **ยืนยันและบันทึก Calendar** แล้วใส่ passkey ของแอป

Google Sheets ต้นฉบับจะไม่ถูกแก้ระหว่างการอ่านและรีเฟรช

## เวลาเวรที่รองรับ

| ประเภทเวร | เวลา |
|---|---:|
| P1/P2/P3/P4 เช้า | 08:00–16:00 |
| P1/P2/P3/P4 บ่าย | 16:00–00:00 |
| P1/P2/P3/P4 ดึก | 00:00–08:00 |
| IPD เช้า | 08:00–16:00 |
| IPD บ่าย | 16:00–08:00 วันถัดไป |
| CT IPD เช้า | 08:00–16:00 |
| CT IPD บ่าย | 16:00–08:00 วันถัดไป |
| CT ER เช้า | 08:00–16:00 |
| CT ER บ่าย | 16:00–08:00 วันถัดไป |
| ER เช้า | 08:00–16:00 |
| ER บ่าย | 16:00–00:00 |
| ER ดึก | 00:00–08:00 |
| GEN เช้า | 07:30–12:00 |
| GEN บ่าย | 16:30–20:00 |
| 14 ชั้น เช้า | 07:00–08:00 |

## เวรออฟและการแจ้งเตือน

เมื่อพบเวรดึกเวลา 00:00–08:00 แอปจะสร้างกิจกรรม `OFF` เวลา 08:00–16:00 ในวันเดียวกันโดยอัตโนมัติ

| การแจ้งเตือน | เงื่อนไข |
|---|---|
| เวรออฟหลังเวรดึก | พบเวรดึกและสร้างช่วง OFF แล้ว |
| เวรชนช่วงออฟ | มีเวรอื่นทับช่วง OFF 08:00–16:00 |
| เวรซ้อนจากตารางเวร | เวรเช้า/บ่าย/ดึกหรือเวรอื่นจากชีตมีเวลาทับกัน |
| เวรชนกิจกรรมใน Calendar | เวรจากชีตทับกิจกรรม Busy ที่มีอยู่ใน Google Calendar |

ความหมายของปุ่ม:

| ปุ่ม | ผลลัพธ์ |
|---|---|
| `ยอมรับ` | รับทราบคำเตือนและคงข้อมูลตามตารางเวร |
| `รับเวร` | ยืนยันรับเวรที่ชน หากชน OFF แอปจะไม่นำ OFF รายการนั้นไปบันทึก |
| `ยกเลิก` | เอาเวรที่ชนออกจากรายการที่จะบันทึก Calendar |

การตัดสินใจถูกเก็บไว้ในอุปกรณ์เพื่อไม่ให้ Auto refresh ทุก 1–10 วินาทีทำให้สถานะกลับเป็นค่าเดิม

## สี Google Calendar

| ประเภท | สี |
|---|---|
| เวรของตัวเอง | กราไฟต์ |
| เวรคนอื่น | มะเขือเทศ |
| เวรคลินิก | ฟ้า |
| เวรออฟหลังเวรดึก | ลาเวนเดอร์ |
| แลกเวรใหญ่ | องุ่น |
| ยกเวร | ลาเวนเดอร์ |
| ยืมชื่อเวร (ไม่จ่าย) | เหลือง/กล้วย |
| ยืมชื่อเวร (จ่าย) | เขียว |

## แท็บภายในแอป

| แท็บ | การใช้งาน |
|---|---|
| หน้าแรก | ตั้งค่าแหล่งข้อมูล รีเฟรช เปรียบเทียบ และซิงก์ Calendar |
| ตัวอย่าง | ตรวจ เลือก/ไม่เลือก และเปลี่ยนประเภทสีของกิจกรรม |
| แจ้งเตือน | ตรวจเวรออฟและเวรซ้อน พร้อมบันทึกการตัดสินใจ |
| Adsite ตารางเวร | หน้าว่างสำหรับอัปเดตข้อมูลในภายหลัง |
| บันทึก | Audit log ของการอ่าน เขียน สำเนา และเหตุการณ์ผิดพลาด |
| ตั้งค่า | Passkey ความปลอดภัย และการสร้างแท็บเดือนล่วงหน้า |

## Passkey คืออะไร

Passkey เป็นรหัสที่ผู้ใช้ตั้งเองอย่างน้อย 6 ตัวอักษร ใช้ยืนยันก่อนทำรายการที่เขียนข้อมูล เช่น สร้างสำเนา Drive สร้างแท็บใหม่ หรือเขียน Calendar

- ไม่ใช่รหัสผ่าน Google
- ไม่ควรใช้รหัสเดียวกับบัญชี Google
- แอปเก็บเฉพาะ SHA-256 ของ passkey ในอุปกรณ์
- ผู้พัฒนาและ GitHub ไม่ได้รับข้อความ passkey จริง

## ขอบเขตความปลอดภัย

- ขั้นตอนอ่านเวรใช้ Google Sheets แบบ Read-only
- แอปไม่เพิ่มผู้เข้าร่วม ไม่ส่งคำเชิญ และไม่สร้าง Google Meet
- การสร้างกิจกรรมใช้ `sendUpdates: none`
- การสร้างแท็บล่วงหน้าเป็นการทำสำเนาแท็บต้นแบบ ไม่แก้แท็บต้นแบบ
- ไฟล์ตารางเวร `.xlsx`, `.csv`, `.ics` และโฟลเดอร์ผลลัพธ์ถูกกันออกจาก Git
- Auto refresh จะไม่เริ่มรอบใหม่ถ้ารอบก่อนยังทำงาน

ช่วงรีเฟรช 1 วินาทีอาจแตะโควตา Sheets API หากพบ `429` ควรเปลี่ยนเป็น 2–10 วินาที

## ตั้งค่า Google Cloud

1. สร้าง Google Cloud project และ OAuth consent screen
2. เปิด API ต่อไปนี้:
   - Google Sheets API
   - Google Calendar API
   - Google Drive API
3. สร้าง OAuth Client IDs:
   - Web: เพิ่ม Authorized JavaScript origins เช่น `http://localhost:8080`
   - Android: package `com.phakphoum.phakphum_calendar` พร้อม SHA-1/SHA-256 ของ signing key
   - iOS: bundle ID `com.phakphoum.phakphumCalendar`
4. เพิ่มบัญชีทดสอบใน OAuth consent screen หากแอปยังอยู่ในโหมด Testing

Scopes ที่ขอตามการทำงาน:

| Scope | ใช้เมื่อ |
|---|---|
| `spreadsheets.readonly` | อ่านเวรและ Auto refresh |
| `calendar.events.readonly` | เปรียบเทียบเวรกับ Calendar |
| `calendar.events` | สร้างกิจกรรมใน Calendar |
| `drive` | ค้นหาและสร้างสำเนาไฟล์ต้นฉบับ |
| `spreadsheets` | ทำสำเนาแท็บเดือนล่วงหน้า |

สิทธิ์ `drive` และ `spreadsheets` ขอเฉพาะเมื่อผู้ใช้กดฟังก์ชันที่เกี่ยวข้อง แอป production อาจต้องผ่าน OAuth verification ของ Google

## GitHub Secrets

เปิด **Settings → Secrets and variables → Actions** แล้วเพิ่ม Repository secrets:

| Secret | แพลตฟอร์ม |
|---|---|
| `GOOGLE_WEB_CLIENT_ID` | Web |
| `GOOGLE_SERVER_CLIENT_ID` | Android/iOS/Web |
| `GOOGLE_IOS_CLIENT_ID` | iOS |
| `GOOGLE_REVERSED_CLIENT_ID` | iOS URL scheme |

หากยังไม่ใส่ Secrets ตัวแอปและ artifacts ยัง build ได้ แต่ Google Login จะยังไม่พร้อมใช้งาน

## รันในเครื่อง

ต้องติดตั้ง Flutter stable และตรวจด้วย `flutter doctor` ก่อน

### Web

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 `
  --dart-define=GOOGLE_WEB_CLIENT_ID="YOUR_WEB_CLIENT_ID" `
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
```

### Android

```powershell
flutter build apk --release `
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
```

ไฟล์จะอยู่ที่ `build/app/outputs/flutter-apk/app-release.apk`

### iOS

ต้องใช้ macOS และ Xcode:

```bash
flutter build ios --release --no-codesign \
  --dart-define=GOOGLE_IOS_CLIENT_ID="YOUR_IOS_CLIENT_ID" \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
```

คำสั่งนี้สร้าง unsigned `Runner.app` ส่วน workflow จะจัดเป็น unsigned IPA ให้อัตโนมัติ

## ตรวจสอบโค้ด

```powershell
flutter analyze
flutter test
flutter build web --release
```

ชุดทดสอบครอบคลุม parser ตารางเวร การสร้าง OFF การตรวจชน การตัดสินใจรับเวร และ layout ขนาด 1280×900 กับ 390×844

## GitHub Actions และ Artifacts

| Workflow | ผลลัพธ์ |
|---|---|
| `Validate Flutter` | `flutter analyze` และ `flutter test` |
| `Build Android APK` | `app-release.apk` และ `SHA256SUMS.txt` |
| `Build iOS IPA (Unsigned)` | `phakphum-calendar-unsigned.ipa` และ `SHA256SUMS.txt` |
| `Build and Deploy Web` | Web artifact และ GitHub Pages เมื่อบัญชีรองรับ |

วิธีดาวน์โหลด:

1. เปิดแท็บ **Actions** ของ repository
2. เลือก workflow และ run ที่ต้องการ
3. เลื่อนลงไปที่หัวข้อ **Artifacts**
4. ดาวน์โหลดไฟล์ ZIP แล้วแตกไฟล์ก่อนใช้งาน

ชื่อ artifacts:

- `phakphum-calendar-android-apk`
- `phakphum-calendar-ios-unsigned-ipa`
- `phakphum-calendar-web`

## ตรวจ SHA-256

PowerShell:

```powershell
Get-FileHash -Algorithm SHA256 .\app-release.apk
Get-Content .\SHA256SUMS.txt
```

macOS/Linux:

```bash
sha256sum -c SHA256SUMS.txt
```

ค่า hash ของไฟล์ต้องตรงกับ `SHA256SUMS.txt` ที่มาจาก workflow run เดียวกัน

## ข้อจำกัดของ artifacts

- Android workflow ใช้ debug signing key ของ Flutter template เหมาะสำหรับทดสอบ ไม่ใช่ Play Store release signing
- iOS IPA เป็น unsigned จึงติดตั้งบน iPhone ปกติหรือส่ง App Store ไม่ได้จนกว่าจะเซ็นด้วย Apple certificate และ provisioning profile
- Web artifact ต้องเสิร์ฟผ่าน HTTP server ไม่ควรเปิด `index.html` ด้วย `file://` โดยตรง
- GitHub Free ไม่รองรับ Pages สำหรับ Private repository นี้ จึงดาวน์โหลด Web artifact มารันเองได้ แต่ยังไม่มี Pages URL จนกว่าจะเปลี่ยนเป็น Public หรือใช้แผนที่รองรับ Private Pages

## โครงสร้างสำคัญ

```text
lib/
├── controller/          # state, refresh, alert decisions, Calendar sync
├── models/              # shift, alert, settings, audit models
├── services/            # Sheets, Calendar, Drive, parser, conflict engine
└── ui/                  # responsive pages and navigation
test/                    # parser, conflict, controller, desktop/mobile tests
.github/workflows/       # validation and platform builds
```

## สถานะ Adsite ตารางเวร

แท็บ `Adsite ตารางเวร` ตั้งใจเว้นว่างไว้ก่อน ยังไม่มีการอ่านหรือเขียนแหล่งข้อมูล Adsite เมื่อรูปแบบตารางพร้อมจึงค่อยเพิ่ม parser และกติกาการซิงก์โดยไม่กระทบ Google Sheets ต้นฉบับ
