# Testing Guide

## ชุดตรวจขั้นต่ำก่อน Merge

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## ระดับการทดสอบ

- Unit tests: parser, rules, diff, sync plan, codecs
- Widget tests: preview, warning decisions, empty/error states
- Integration tests: sign-in → read sheet → preview → sync ด้วย test doubles
- Platform builds: Web, Android, iOS, Windows, macOS และ Linux ผ่าน GitHub Actions

## Parser matrix

ควรครอบคลุมอย่างน้อย:

- `16 กรกฎาคม พ.ศ. 2569 - 15 สิงหาคม พ.ศ. 2569`
- `16 กค69-15 สค.69`
- เดือนเดียวกันและข้ามเดือน
- ปี พ.ศ. 2 หลักและ 4 หลัก
- ช่องว่าง จุด และ dash หลายรูปแบบ
- วันที่ไม่ถูกต้องและชื่อเดือนไม่รู้จัก

## Definition of Done

งานหนึ่งถือว่าเสร็จเมื่อ:

- behavior ตรง acceptance criteria
- test ใหม่ผ่านและ test เดิมไม่พัง
- analyzer/formatter ผ่าน
- มีเอกสารเมื่อ behavior สำหรับผู้ใช้หรือ API เปลี่ยน
- ไม่มี secret หรือข้อมูลส่วนตัวใน diff
