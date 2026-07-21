# Phakphum Shift Calendar

Flutter app สำหรับอ่านตารางเวรจาก Google Sheets, ตรวจรายการก่อนบันทึก และสร้างกิจกรรมใน Google Calendar บน Android, iOS, Web, Windows, macOS และ Linux

## ระบบที่รองรับ

| ระบบ | เปิดและใช้งาน UI | Google Sign-In/API |
| --- | --- | --- |
| Android | รองรับ | รองรับ |
| iOS | รองรับ | รองรับเมื่อตั้ง OAuth |
| Web | รองรับ | รองรับเมื่อตั้ง OAuth |
| macOS | รองรับ | รองรับเมื่อตั้ง OAuth และ URL scheme |
| Windows | รองรับ | แพ็กเกจ `google_sign_in` ยังไม่รองรับ ให้ใช้เวอร์ชัน Web สำหรับงาน Google |
| Linux | รองรับ | แพ็กเกจ `google_sign_in` ยังไม่รองรับ ให้ใช้เวอร์ชัน Web สำหรับงาน Google |

## ความสามารถ

- หลัง Google Login แอปแสดงป๊อปอัปขอสิทธิ์อ่าน Sheets/Calendar ทันที และตรวจสิทธิ์เดิมก่อนเพื่อไม่ขอซ้ำโดยไม่จำเป็น
- อ่าน Google Sheets ด้วย `spreadsheets.readonly` โดยไม่แก้ไขต้นฉบับ
- ค้นหาเวรตามชื่อ/เดือน/ปี และแปลงเวลา P1–P4, IPD, CT IPD, CT ER, ER, GEN และ 14 ชั้น
- รีเฟรชทันที หรือ Auto refresh ทุก 1–10 วินาที (ไม่เริ่มรอบใหม่ถ้ารอบเดิมยังทำงาน)
- Preview, เลือก/ไม่เลือก และกำหนดสีแต่ละกิจกรรมก่อนเขียน
- เปรียบเทียบ Calendar และกันรายการซ้ำ ทั้งอีเวนต์จากแอปและอีเวนต์เดิมที่ชื่อ/เวลาเดียวกัน
- สร้างสำเนาไฟล์ต้นฉบับประจำเดือนใน Google Drive โดยไม่สร้างซ้ำเดือนเดิม
- สร้างแท็บเดือนล่วงหน้าจากแท็บต้นแบบหลังล็อกอิน Google และกดยืนยันรายการ
- Audit log เก็บในเครื่องสูงสุด 200 รายการ

## ขอบเขตความปลอดภัย

การอ่านเวรไม่มีคำสั่งเขียน Google Sheets ส่วนการสร้างสำเนา Drive, เขียน Calendar และสร้างแท็บเดือนล่วงหน้าต้องล็อกอิน Google และอนุญาตสิทธิ์ที่เกี่ยวข้อง แอปไม่เพิ่มผู้เข้าร่วม ไม่ส่งคำเชิญ และไม่สร้าง Google Meet

ฟังก์ชัน “สร้างชีตเดือนล่วงหน้า” ทำสำเนาเต็มของแท็บต้นแบบเป็นแท็บใหม่ จึงควรตรวจและแก้วันที่/รายชื่อในแท็บใหม่ก่อนนำมาใช้ แอปไม่แก้แท็บต้นแบบ

Auto refresh ใช้ batch read หนึ่งครั้งต่อรอบหลังโหลดรายชื่อแท็บครั้งแรก ช่วง 1 วินาทีอาจแตะโควตาอ่าน 60 requests/นาที/ผู้ใช้ของ Sheets API หากพบ `429` ให้เพิ่มช่วงเป็น 2–10 วินาที

## ตั้งค่า Google Cloud

1. สร้าง Google Cloud project และ OAuth consent screen
2. เปิด API:
   - Google Sheets API
   - Google Calendar API
   - Google Drive API
3. สร้าง OAuth Client IDs:
   - Web: เพิ่ม Authorized JavaScript origins ให้ตรงกับ URL ที่เปิดแอป เช่น `http://localhost:8080` และ URL ของ GitHub Pages
   - Android: package `com.phakphoum.phakphum_calendar` พร้อม SHA-1/SHA-256 ของ signing key
   - iOS: bundle ID `com.phakphoum.phakphumCalendar`
   - macOS: bundle ID `com.phakphoum.phakphumCalendar`
4. สำหรับ iOS/macOS นำ Client ID และ Reversed Client ID ไปตั้งผ่าน GitHub secrets หรือแทนค่า placeholder ใน `ios/Runner/Info.plist`/`macos/Runner/Info.plist` เฉพาะเครื่อง build

Scopes ที่แอปขอ:

- `spreadsheets.readonly` และ `calendar.events.readonly` — ขอพร้อมกันจากป๊อปอัปหลังล็อกอิน เพื่ออ่านตารางเวรและตรวจรายการซ้ำ
- `calendar.events` — สร้างกิจกรรม
- `drive` — ค้นหา/สร้างสำเนาไฟล์ต้นฉบับที่มีอยู่แล้ว
- `spreadsheets` — ทำสำเนาแท็บเดือนล่วงหน้าเมื่อผู้ใช้กดสั่ง

สิทธิ์ `drive` และ `spreadsheets` เป็นสิทธิ์กว้างที่ขอเฉพาะเมื่อใช้ฟังก์ชันเขียนที่เกี่ยวข้อง แอป production อาจต้องผ่าน OAuth verification ของ Google

## รันในเครื่อง

ติดตั้ง Flutter SDK และ toolchain ของระบบนั้น แล้วรัน:

```powershell
flutter pub get
flutter run -d windows
flutter run -d chrome --web-port=8080
```

บน macOS หรือ Linux เปลี่ยน device เป็น `macos` หรือ `linux` ตามลำดับ ส่วน Android/iOS เลือก emulator, simulator หรืออุปกรณ์จาก `flutter devices`

สำหรับ Web ที่ต้องใช้ Google Login:

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 `
  --dart-define=GOOGLE_WEB_CLIENT_ID="YOUR_WEB_CLIENT_ID" `
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
```

Web OAuth Client ID เป็นข้อมูลสาธารณะ ไม่ใช่ Client Secret หากไม่ได้ส่งผ่าน `--dart-define` ให้กด **ตั้งค่า Google OAuth** บนหน้าแรก วาง Web Client ID แล้วแอปจะเปิดปุ่ม Google Login โดยไม่ต้อง build ใหม่ ค่าจะถูกเก็บไว้เฉพาะใน browser profile นั้น

## ตรวจและ build ในเครื่อง

```powershell
flutter analyze
flutter test
flutter build web --release `
  --dart-define=GOOGLE_WEB_CLIENT_ID="YOUR_WEB_CLIENT_ID"
flutter build apk --release `
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
flutter build windows --release
```

การ build iOS และ macOS ต้องใช้ macOS/Xcode:

```bash
flutter build ios --release --no-codesign
flutter build macos --release \
  --dart-define=GOOGLE_MACOS_CLIENT_ID="YOUR_MACOS_CLIENT_ID" \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
```

การ build Linux ต้องทำบน Linux ที่ติดตั้ง GTK development packages:

```bash
flutter build linux --release
```

## GitHub Actions และ secrets

Workflows:

- `Validate Flutter` — analyze + tests
- `Build Android APK` — APK และ `SHA256SUMS.txt`
- `Build iOS IPA (Unsigned)` — unsigned IPA และ checksum
- `Build and Deploy Web` — web artifact และ GitHub Pages
- `Build Desktop Apps` — ZIP/TAR.GZ สำหรับ Windows, macOS และ Linux พร้อม checksum

ตั้ง secrets ใน GitHub repository:

- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID`
- `GOOGLE_REVERSED_CLIENT_ID`
- `GOOGLE_MACOS_CLIENT_ID`
- `GOOGLE_MACOS_REVERSED_CLIENT_ID`

Android workflow ใช้ debug signing key ของ Flutter template จึงเหมาะกับการทดสอบ ไม่ใช่ Play Store release signing ส่วน IPA เป็น unsigned archive: ใช้ตรวจหรือส่งต่อไปขั้นตอน signing ได้ แต่ติดตั้งบน iPhone ปกติไม่ได้จนกว่าจะเซ็นด้วย Apple certificate/provisioning profile

เปิด GitHub Pages ที่ **Settings → Pages → Source: GitHub Actions** ก่อนรัน Web workflow บนสาขา `main`
