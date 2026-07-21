# Phakphum Shift Calendar

แอป Flutter สำหรับอ่านตารางเวรจาก Google Sheets แบบ read-only ตรวจรายการก่อนบันทึก และเพิ่มเวรที่ยืนยันแล้วลง Google Calendar รองรับ UI บน Web, Android, iOS, Windows, macOS และ Linux

- แอปไม่ฝังลิงก์ชีต บัญชี Google, OAuth Client ID, token หรือผลลัพธ์ตารางเวรไว้ในซอร์สโค้ด
- ชื่อที่ใช้ค้นหาเวรอ่านจากชื่อโปรไฟล์ของบัญชี Google ที่ล็อกอินโดยอัตโนมัติ จึงไม่มีช่องกรอกชื่อผู้ค้นหา
- ช่องชีต ชื่อ เดือน และปีเริ่มต้นว่าง ไม่มีค่าของผู้ใช้ฝังในแอปหรือ repository ผู้ใช้เลือกเดือนและปี ค.ศ. เองก่อนอ่าน
- ไอคอนแอปเป็นรูปชีตและปฏิทินบนทุกแพลตฟอร์มที่โปรเจกต์สร้างให้

## สถานะของแต่ละระบบ

| ระบบ | เปิด UI | Google Sign-In/API ในแอป native | ไฟล์จาก GitHub Actions |
| --- | --- | --- | --- |
| Web | รองรับ | รองรับเมื่อตั้ง Web OAuth | `phakphum-calendar-web` และ GitHub Pages |
| Android | รองรับ | รองรับเมื่อตั้ง Android OAuth | `phakphum-calendar-android-apk` |
| iOS | รองรับ | รองรับเมื่อตั้ง iOS OAuth | `phakphum-calendar-ios-unsigned-ipa` |
| Windows | รองรับ | ยังไม่รองรับโดยแพ็กเกจที่ใช้ ให้เปิด Web สำหรับงาน Google | `phakphum-calendar-windows` |
| macOS | รองรับ | รองรับเมื่อตั้ง macOS OAuth และ URL scheme | `phakphum-calendar-macos` |
| Linux | รองรับ | ยังไม่รองรับโดยแพ็กเกจที่ใช้ ให้เปิด Web สำหรับงาน Google | `phakphum-calendar-linux` |

รายการระบบปฏิบัติการที่ Flutter รุ่นปัจจุบันรองรับดูได้จาก [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms)

## วิธีใช้งาน

### 1. เตรียม Google Sheets

1. ให้ตารางมีชื่อผู้ปฏิบัติงานตรงกับชื่อเต็ม ชื่อจริง หรือนามสกุลในโปรไฟล์ Google ที่จะล็อกอิน
2. Google Sheets ต้นฉบับต้องเป็นไฟล์ที่บัญชีนั้นเป็นเจ้าของ ไม่ใช่ไฟล์ของบัญชีอื่นที่แชร์มา
3. คัดลอก URL ของชีตจากเบราว์เซอร์ แอปไม่กำหนดชีตส่วนกลางและไม่ส่ง URL นี้ขึ้น GitHub

ตัวอ่านรองรับเวร P1–P4, IPD, CT IPD, CT ER, ER, GEN และ 14 ชั้นตามรูปแบบตารางของโปรเจกต์

### 2. ล็อกอินและอนุญาตสิทธิ์

1. เปิดแอปแล้วกด **เข้าสู่ระบบด้วย Google**
2. เลือกบัญชี Google ที่เป็นเจ้าของชีตต้นฉบับ
3. เมื่อป็อปอัพสิทธิ์ปรากฏ ให้ตรวจรายการสิทธิ์ก่อนอนุญาต
4. แอปจะใช้ชื่อโปรไฟล์ Google เพื่อค้นหาเวรโดยอัตโนมัติ หากไม่พบเวร ให้ตรวจว่าชื่อในโปรไฟล์ตรงกับชื่อในชีต

แอปตรวจสิทธิ์อ่านที่เคยอนุญาตก่อน จึงไม่ควรแสดงป็อปอัพซ้ำโดยไม่จำเป็น ขั้นตอนอ่านใช้ Drive metadata แบบ read-only เพื่อตรวจ `ownedByMe` สิทธิ์เขียน Calendar, สำเนา Drive และสร้างแท็บชีตจะถูกขอเมื่อผู้ใช้เรียกฟังก์ชันนั้น

### 3. อ่านและตรวจตารางเวร

1. วาง URL ในช่อง **ลิงก์ Google Sheets ต้นฉบับ** ช่องนี้เริ่มต้นว่างและเปลี่ยนตามบัญชีที่ล็อกอิน
2. เลือก **เดือน** และ **ปี ค.ศ.** ซึ่งเริ่มต้นว่าง
3. เปิดหรือปิด **เก็บสำเนาต้นฉบับใน Drive** ตามต้องการ
4. กด **รีเฟรช/อ่านใหม่ตอนนี้** แอปจะยืนยันก่อนว่าไฟล์เป็นของบัญชีปัจจุบัน แล้วบันทึกเป็นไฟล์หลักของบัญชีนั้นเฉพาะในเครื่อง
5. ไปแท็บ **ตัวอย่าง** เพื่อตรวจวัน เวลา ประเภทเวร สี และเลือกว่าจะนำรายการใดไปใช้
6. กด **เปรียบเทียบ Calendar** เพื่อตรวจรายการซ้ำและเวลาที่ชนกับกิจกรรมเดิม
7. ถ้ามีป็อปอัพแจ้งเตือน ให้เปิดแท็บ **แจ้งเตือน** แล้วตัดสินใจทุกรายการ
8. ตรวจตัวเลข “อ่านพบ / เลือกไว้ / มีใน Calendar / รอเพิ่ม / แจ้งเตือนค้าง” ก่อนดำเนินการ
9. กด **ยืนยันและบันทึก Calendar** เฉพาะเมื่อรายการถูกต้อง

แอปอ่านชีตต้นฉบับด้วย `spreadsheets.readonly` และไม่มีคำสั่งแก้เซลล์ในขั้นตอนอ่านเวร การเขียน Calendar จะเกิดหลังผู้ใช้กดยืนยันเท่านั้น

#### เวลาเวรมาตรฐาน

| ประเภทเวร | เวลา |
|---|---|
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

#### สีจากไฟล์หลักไป Google Calendar

แอปต้องใช้ลิงก์ Google Sheets ต้นฉบับเพื่ออ่าน `effectiveFormat` และค่าสีพื้นหลังของเซลล์ ข้อความที่คัดลอกมาวางไม่มีข้อมูลสี หน้า **ตัวอย่าง** จะแสดงทั้งสีจากไฟล์หลักและสี Calendar ที่จะใช้ โดยผู้ใช้ยังแก้ประเภทก่อนบันทึกได้

| สีในไฟล์หลัก | ความหมาย | สี Google Calendar |
|---|---|---|
| กราไฟต์ | เวรของตัวเอง | กราไฟต์ |
| มะเขือเทศ | เวรคนอื่น | มะเขือเทศ |
| ฟ้า | เวรคลินิก | ฟ้า |
| ลาเวนเดอร์ | แลกเวรใหญ่ | มะเขือเทศ |
| เผือก | เวรคลินิก (แบบพิเศษ) | อะโวคาโด |
| กล้วยหอม | ยืมชื่อเวร (ไม่จ่าย) | กล้วย/เหลือง |
| นกแก้ว | ยืมชื่อเวร (จ่าย) | เขียว |
| ลาเวนเดอร์ | ยกเวร | ลาเวนเดอร์ |

เนื่องจาก **แลกเวรใหญ่** และ **ยกเวร** ใช้สีลาเวนเดอร์ต้นทางเหมือนกัน แอปจะแสดงคำเตือนให้ตรวจประเภทในหน้า **ตัวอย่าง** แทนการเดาแล้วส่งสีผิด

#### เวรดึก, OFF และป็อปอัพรายการชน

- เวรดึกทุกเวรที่ทำงาน 00:00–08:00 จะสร้างรายการ `OFF` 08:00–16:00 ของวันเดียวกันอัตโนมัติ
- ชื่อกิจกรรมใน Calendar ใช้ชื่อเวรจากชีตพร้อมรหัส เช่น `P1 เช้า (UP1)` และรายการพักใช้ `OFF — เวรออฟหลังเวรดึก`
- แอปตรวจเวรที่ซ้อนกันในชีต, เวรที่ชนช่วง OFF, เวรที่ชนกิจกรรมเดิมใน Google Calendar และกิจกรรม Calendar ที่ชนช่วง OFF 08:00–16:00
- กิจกรรม Calendar ที่ตั้งเป็นว่าง (`transparent`) และกิจกรรมที่แอปเคยสร้างเองจะไม่ถูกแจ้งซ้ำ
- ถ้าพบรายการชน แอปจะแสดงป็อปอัพและหยุดการเขียน Calendar จนกว่าจะเลือก **รับทราบและคงไว้**, **ยืนยันรายการ** หรือ **ไม่นำเข้าปฏิทิน**
- ก่อนเขียนจริง แอปจะอ่าน Calendar ซ้ำอีกครั้งเพื่อป้องกันกิจกรรมใหม่ที่ถูกเพิ่มหลังการเปรียบเทียบครั้งแรก
- การตัดสินใจแจ้งเตือนเก็บในพื้นที่ของแอปบนเครื่องนั้นเท่านั้น ไม่ถูก commit หรืออัปโหลดไปยัง repository

### 4. ใช้แท็บบันทึก

- **บันทึกชีตปัจจุบัน** เก็บ URL อ้างอิงไว้เฉพาะอุปกรณ์/เบราว์เซอร์และแยกตามบัญชี Google
- **ใช้ไฟล์นี้** เปลี่ยนไฟล์หลักเฉพาะของบัญชีที่ล็อกอิน หลังตรวจความเป็นเจ้าของซ้ำ
- **เปิดดู** เปิดชีตจริงด้วยบัญชีที่ล็อกอิน ผู้ใช้จะแก้ชีตได้ตามสิทธิ์ที่ Google กำหนด
- **ลบ** ลบเฉพาะรายการอ้างอิงในแอป ไม่ลบไฟล์ Google Sheets จริง
- **สร้างชีตเดือนล่วงหน้า** ทำสำเนาแท็บต้นแบบเป็นแท็บใหม่ ผู้ใช้ควรตรวจวันที่และรายชื่อในแท็บใหม่ก่อนใช้งาน

### 5. Auto refresh และสำเนาต้นฉบับ

- Auto refresh เลือกช่วง 1–10 วินาทีได้ รอบใหม่จะไม่เริ่มซ้อนกับรอบที่ยังทำงาน
- ช่วง 1 วินาทีอาจแตะโควตา Google Sheets API หากพบ `429` ให้เพิ่มเป็น 2–10 วินาที
- เมื่อเปิดการเก็บสำเนา แอปสร้างสำเนาต้นฉบับใน Drive หนึ่งครั้งต่อไฟล์และเดือนก่อนซิงก์ โดยไม่แก้หรือลบไฟล์ต้นฉบับ

## ติดตั้งจาก GitHub Actions

หน้า repository: [phakphoum38-stack/phakphum-calendar](https://github.com/phakphoum38-stack/phakphum-calendar)

1. เปิดแท็บ **Actions**
2. เลือก workflow ของระบบที่ต้องการ
3. เปิด run ล่าสุดที่สำเร็จบนสาขา `main`
4. เลื่อนลงส่วน **Artifacts** แล้วดาวน์โหลด artifact ตามตารางด้านบน
5. แตก ZIP ที่ GitHub สร้างครอบ artifact ก่อน แล้วจึงใช้ไฟล์แอปภายใน

GitHub กำหนดให้ผู้ดาวน์โหลด artifact ล็อกอินและมีสิทธิ์อ่าน repository ขั้นตอนมาตรฐานดูได้ที่ [Downloading workflow artifacts](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts?tool=webui)

ดาวน์โหลดผ่าน GitHub CLI ได้เช่นกัน:

```powershell
gh auth login
gh run list --repo phakphoum38-stack/phakphum-calendar
gh run download RUN_ID --repo phakphoum38-stack/phakphum-calendar
```

### ตรวจ SHA-256 ก่อนติดตั้ง

แต่ละ artifact มี `SHA256SUMS.txt` ยกเว้น Web artifact ที่ GitHub Pages นำไป deploy โดยตรง

Windows PowerShell:

```powershell
Get-FileHash .\phakphum-calendar-windows.zip -Algorithm SHA256
Get-Content .\SHA256SUMS.txt
```

macOS:

```bash
shasum -a 256 phakphum-calendar-macos.zip
cat SHA256SUMS.txt
```

Linux:

```bash
sha256sum -c SHA256SUMS.txt
```

ค่า hash ที่คำนวณต้องตรงกับบรรทัดของไฟล์นั้นใน `SHA256SUMS.txt`

## ติดตั้ง Web / PWA

1. เปิด [GitHub Pages ของแอป](https://phakphoum38-stack.github.io/phakphum-calendar/) ด้วย Chrome, Edge หรือ Safari รุ่นปัจจุบัน
2. หากเว็บแจ้งว่ายังไม่ได้ตั้ง OAuth ให้กด **ตั้งค่า Google OAuth** แล้ววาง Web Client ID ของโปรเจกต์ Google Cloud ที่เชื่อถือได้
3. ใน Chrome/Edge กดไอคอนติดตั้งที่แถบที่อยู่ หรือเมนู **Install app / ติดตั้งแอป** เพื่อใช้แบบ PWA
4. iPhone/iPad ใช้ Safari → Share → **Add to Home Screen**

Web Client ID ไม่ใช่ Client Secret แต่ควรใช้เฉพาะ ID ของโปรเจกต์ที่ตั้ง Authorized JavaScript origins ตรงกับ URL นี้ ค่าที่กรอกจากหน้าแอปเก็บใน browser profile ปัจจุบัน

## ติดตั้ง Android

1. ดาวน์โหลด `phakphum-calendar-android-apk`
2. แตกไฟล์และตรวจ SHA-256 ของ `app-release.apk`
3. ส่ง APK ไปยังโทรศัพท์แล้วเปิดไฟล์
4. Android อาจขออนุญาต **Install unknown apps** สำหรับแอปที่ใช้เปิด APK ให้อนุญาตเฉพาะแหล่งที่เชื่อถือได้
5. ติดตั้งแล้วเปิด **Shift Calendar**

ข้อจำกัด: workflow ปัจจุบัน build แบบ release แต่ลงนามด้วย debug key ของโปรเจกต์ จึงเหมาะสำหรับทดสอบ ไม่ใช่ไฟล์สำหรับเผยแพร่ Play Store การใช้งานจริงควรตั้ง release keystore และเก็บรหัสผ่านใน GitHub Secrets

## ติดตั้ง iOS / iPadOS

artifact `phakphum-calendar-ios-unsigned-ipa` เป็น IPA ที่ยังไม่ลงลายเซ็น จึงติดตั้งบน iPhone/iPad ปกติโดยตรงไม่ได้

1. ดาวน์โหลดและตรวจ SHA-256 ของ `phakphum-calendar-unsigned.ipa`
2. ใช้ macOS/Xcode เปิดโปรเจกต์ `ios/Runner.xcworkspace`
3. เลือก Apple Developer Team และ bundle identifier ที่บัญชีมีสิทธิ์ใช้
4. ตั้ง iOS OAuth Client ID และ Reversed Client ID ให้ตรงกับ bundle ID
5. สร้าง signed archive จาก Xcode แล้วติดตั้งผ่านวิธีแจกจ่ายของ Apple ที่ทีมเลือก

หากต้องการเพียงตรวจโครงสร้าง build ใช้ unsigned IPA ได้ แต่การติดตั้งจริงต้องมี Apple certificate และ provisioning profile

## ติดตั้ง Windows

1. ดาวน์โหลด `phakphum-calendar-windows`
2. แตก artifact แล้วตรวจ `phakphum-calendar-windows.zip`
3. แตก `phakphum-calendar-windows.zip` อีกครั้ง โดยเก็บ `.exe`, `.dll` และโฟลเดอร์ `data` ไว้ด้วยกัน
4. เปิด `phakphum_calendar.exe`

ไฟล์ยังไม่ได้เซ็น Authenticode จึงอาจมีคำเตือน Windows SmartScreen ให้ตรวจ source, workflow run และ SHA-256 ก่อนใช้งาน Google Sign-In native ยังไม่รองรับบน Windows ในเวอร์ชันนี้ ให้กด **Google Login ใช้ผ่าน Web** เพื่อเปิดเว็บแอป

## ติดตั้ง macOS

1. ดาวน์โหลด `phakphum-calendar-macos`
2. ตรวจ SHA-256 แล้วแตก `phakphum-calendar-macos.zip`
3. ย้าย `phakphum_calendar.app` ไปที่ `/Applications`
4. เปิดแอปและอนุญาตสิทธิ์ตามนโยบายของเครื่อง

artifact ยังไม่ได้ notarize/sign สำหรับการแจกจ่ายสาธารณะ macOS อาจป้องกันการเปิด ผู้เผยแพร่ควรลงลายเซ็นด้วย Developer ID และ notarize ก่อนแจกจ่ายให้ผู้ใช้ทั่วไป

## ติดตั้ง Linux

ตัวอย่างสำหรับ Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y libgtk-3-0 libstdc++6
tar -xzf phakphum-calendar-linux.tar.gz
cd bundle
./phakphum_calendar
```

ต้องเก็บ executable, `data` และ `lib` ไว้ในโครงสร้างเดิม ไอคอนแอปอยู่ใน `bundle/data/app_icon.png` Google Sign-In native ยังไม่รองรับบน Linux ในเวอร์ชันนี้ ให้ใช้ Web สำหรับงาน Google

## ตั้งค่า Google Cloud

อ่านภาพรวม OAuth 2.0 ได้จาก [Google Identity OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)

1. สร้างหรือเลือก Google Cloud project
2. เปิด API ต่อไปนี้:
   - Google Sheets API
   - Google Calendar API
   - Google Drive API
3. ตั้ง OAuth consent screen/Google Auth Platform:
   - ใส่ชื่อแอป อีเมลสนับสนุน และอีเมลติดต่อ
   - เลือก Audience ให้ตรงกับการใช้งาน Internal หรือ External
   - ถ้ายังอยู่โหมด Testing ให้เพิ่มทุกบัญชีที่ต้องใช้ใน Test users
   - เพิ่ม scopes ที่แอปใช้และเผยแพร่ consent screen เมื่อพร้อม
4. สร้าง OAuth Client ตามระบบ:
   - Web: เพิ่ม Authorized JavaScript origins เช่น `http://localhost:8080` และ `https://phakphoum38-stack.github.io`
   - Android: package `com.phakphoum.phakphum_calendar` พร้อม SHA-1/SHA-256 ของ signing key
   - iOS: bundle ID `com.phakphoum.phakphumCalendar`
   - macOS: bundle ID `com.phakphoum.phakphumCalendar` และ URL scheme จาก Reversed Client ID
5. ห้าม commit Client Secret, access token, refresh token, service-account key หรือไฟล์ข้อมูลบัญชีลง repository

Scopes ที่แอปขอ:

- `spreadsheets.readonly` และ `calendar.events.readonly` — อ่านตารางและตรวจรายการซ้ำ
- `drive.metadata.readonly` — ตรวจว่าไฟล์ชีตหลักเป็นของบัญชีที่ล็อกอิน โดยไม่อ่านหรือแก้เนื้อหาไฟล์ผ่าน Drive
- `calendar.events` — สร้างกิจกรรมหลังผู้ใช้ยืนยัน
- `drive` — ค้นหา/สร้างสำเนาต้นฉบับเมื่อเปิดฟังก์ชันเก็บสำเนา
- `spreadsheets` — สร้างสำเนาแท็บเดือนล่วงหน้าเมื่อผู้ใช้กดสั่ง

สิทธิ์ `drive` และ `spreadsheets` มีขอบเขตกว้างและอาจทำให้แอป production ต้องผ่าน OAuth verification ของ Google

## GitHub Secrets

ตั้งค่าที่ **Repository → Settings → Secrets and variables → Actions**:

- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID`
- `GOOGLE_REVERSED_CLIENT_ID`
- `GOOGLE_MACOS_CLIENT_ID`
- `GOOGLE_MACOS_REVERSED_CLIENT_ID`

workflow จะนำค่าไปใส่เฉพาะตอน build ไม่มีไฟล์บัญชี ลิงก์ชีต หรือผลลัพธ์เวรถูกอัปโหลดเป็น artifact

## Build จากซอร์ส

ติดตั้ง Flutter ตาม [Install Flutter](https://docs.flutter.dev/get-started/install) และ toolchain ของระบบ จากนั้นรันขั้นตอนร่วม:

```powershell
git clone https://github.com/phakphoum38-stack/phakphum-calendar.git
cd phakphum-calendar
flutter doctor -v
flutter pub get
flutter analyze
flutter test
```

### Web

```powershell
flutter run -d chrome --web-port=8080 `
  --dart-define=GOOGLE_WEB_CLIENT_ID="YOUR_WEB_CLIENT_ID" `
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"

flutter build web --release `
  --dart-define=GOOGLE_WEB_CLIENT_ID="YOUR_WEB_CLIENT_ID" `
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
```

### Android

ต้องมี Android SDK และ JDK 17:

```powershell
flutter devices
flutter run -d DEVICE_ID `
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
flutter build apk --release `
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
```

ดู SHA ของ signing key:

```powershell
cd android
.\gradlew signingReport
```

### iOS

ต้องใช้ macOS, Xcode และ Apple toolchain:

```bash
flutter run -d DEVICE_ID \
  --dart-define=GOOGLE_IOS_CLIENT_ID="YOUR_IOS_CLIENT_ID" \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"

flutter build ios --release --no-codesign \
  --dart-define=GOOGLE_IOS_CLIENT_ID="YOUR_IOS_CLIENT_ID" \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
```

### Windows

ต้องมี Visual Studio พร้อม workload **Desktop development with C++**:

```powershell
flutter config --enable-windows-desktop
flutter run -d windows
flutter build windows --release
```

### macOS

```bash
flutter config --enable-macos-desktop
flutter run -d macos \
  --dart-define=GOOGLE_MACOS_CLIENT_ID="YOUR_MACOS_CLIENT_ID" \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
flutter build macos --release \
  --dart-define=GOOGLE_MACOS_CLIENT_ID="YOUR_MACOS_CLIENT_ID" \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID"
```

### Linux

ตัวอย่าง dependency สำหรับ Ubuntu/Debian ใช้ชุดเดียวกับ CI:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
flutter config --enable-linux-desktop
flutter run -d linux
flutter build linux --release
```

### สร้างไอคอนใหม่

ไฟล์ต้นฉบับอยู่ที่ `assets/app_icon_master.png`:

```powershell
flutter pub get
dart run flutter_launcher_icons
```

คำสั่งนี้สร้างไอคอน Android, iOS, Web, Windows และ macOS ส่วน Linux จะนำไฟล์ต้นฉบับไปไว้ใน bundle ผ่าน CMake

## Workflows

- `Validate Flutter` — `flutter analyze` และ `flutter test`
- `Build Android APK` — release APK สำหรับทดสอบและ SHA-256
- `Build iOS IPA (Unsigned)` — unsigned IPA และ SHA-256
- `Build and Deploy Web` — Web artifact และ GitHub Pages
- `Build Desktop Apps` — Windows ZIP, macOS ZIP และ Linux TAR.GZ พร้อม SHA-256

ทุก workflow รองรับ **Run workflow** และจะทำงานอัตโนมัติเมื่อไฟล์ที่เกี่ยวข้องถูก push เข้า `main`

## ข้อมูลที่เก็บและขอบเขตความปลอดภัย

- ช่องชีต ชื่อ เดือน และปีเริ่มต้นว่าง; เดือน/ปีที่เลือกใช้เฉพาะรอบใช้งานและไม่ถูกฝังใน build
- URL ชีตที่ตรวจแล้ว, ค่า OAuth ที่กรอกจาก UI, แถบเครื่องมือ, บันทึก และ audit log เก็บใน local storage ของอุปกรณ์/เบราว์เซอร์
- รายการชีตที่บันทึกแยกด้วย Google account ID แบบ opaque และต้องผ่าน `ownedByMe` ไม่บันทึกรหัสผ่านหรือ Google token เอง
- Audit log เก็บสูงสุด 200 รายการในเครื่อง
- การลบรายการชีตในแท็บบันทึกไม่ลบไฟล์ Google Sheets
- แอปไม่เพิ่มผู้เข้าร่วม ไม่ส่งคำเชิญ และไม่สร้าง Google Meet
- repository และ build artifacts ต้องมีเฉพาะซอร์ส/ไฟล์แอป ห้ามรวมไฟล์ชีต ผลลัพธ์เวร อีเมล token หรือข้อมูลบัญชี
