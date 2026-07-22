# Coding Standards

## Dart และ Flutter

- ใช้ `dart format` กับไฟล์ Dart ทั้งหมด
- `flutter analyze` ต้องไม่มี error และ warning ใหม่
- ใช้ immutable model และ `const` constructor เมื่อทำได้
- หลีกเลี่ยง `dynamic`; ระบุชนิดข้อมูลและ nullability ให้ชัดเจน
- ชื่อ class ใช้ `UpperCamelCase`, ตัวแปรและเมธอดใช้ `lowerCamelCase`
- ไฟล์ใช้ `snake_case.dart`

## Design rules

- หนึ่ง class ควรมีหน้าที่หลักหนึ่งอย่าง
- ห้ามเรียก Google API โดยตรงจาก Widget
- ห้ามเก็บ business rule ไว้ในสี ป้ายข้อความ หรือเงื่อนไข UI
- เวลาและวันที่ต้องส่งผ่าน model ที่ระบุ timezone/ความหมายชัดเจน
- Error ที่ผู้ใช้แก้ได้ควรเป็น typed result หรือ domain exception ที่แปลข้อความได้

## Testing requirement

การเปลี่ยนแปลงต่อไปนี้ต้องมี test:

- รูปแบบวันที่ภาษาไทยใหม่
- รหัสเวรหรือเวลาเวรใหม่
- กฎ OFF/พักหลังเวร
- conflict rule
- calendar diff และ sync behavior
- JSON codec หรือ persisted state

## Commit convention

```text
feat: add configurable night-shift rest rule
fix: parse compact Thai Buddhist date ranges
refactor: isolate calendar sync orchestration
 test: cover cross-month roster periods
docs: add production release checklist
```

ห้าม commit secret, token, `.env`, service-account JSON หรือข้อมูลจริงของบุคลากร/ผู้ป่วย
