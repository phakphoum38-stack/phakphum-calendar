# Business Rules

## Known shift categories

- Portable (P)
- GEN
- 14 ชั้น
- IPD
- CT
- ER
- CT-IPD
- CT-ER

## Known time mappings

| Category | Period | Start | End |
|---|---|---:|---:|
| Portable | เช้า | 08:00 | 16:00 |
| Portable | บ่าย | 16:00 | 00:00 next day |
| Portable | ดึก | 00:00 | 08:00 |
| IPD | เช้า | 08:00 | 16:00 |
| IPD | บ่าย | 16:00 | 08:00 next day |
| CT-IPD | เช้า | 08:00 | 16:00 |
| CT-IPD | บ่าย | 16:00 | 08:00 next day |
| CT-ER | เช้า | 08:00 | 16:00 |
| CT-ER | บ่าย | 16:00 | 08:00 next day |
| ER | เช้า | 08:00 | 16:00 |
| ER | บ่าย | 16:00 | 00:00 next day |
| ER | ดึก | 00:00 | 08:00 |
| GEN | เช้า | 07:30 | 12:00 |
| GEN | บ่าย | 16:30 | 20:00 |
| 14 ชั้น | เช้า | 07:00 | 08:00 |

Unknown CT time mappings remain unconfirmed and must not be guessed.

## Color meanings

| Color | Meaning |
|---|---|
| Graphite | Own shift |
| Tomato | Other person's shift |
| Default blue | Clinic shift |
| Lavender + Tomato | Major exchange |
| Purple + Avocado | Clinic exchange |
| Banana | Borrow name, free |
| Parrot | Borrow name, paid |
| Lavender | Give shift away |

Exact Google color IDs or RGB values are still required before implementation.

## Relationship rules

### Own shift
The original owner and actual worker are the user.

### Received shift
A different person's name may remain in the cell while the color indicates an exchange.
The system must retain the source owner and identify the user as actual worker.

### Given-away shift
When the user is the original owner but the color indicates the shift was given away:

- identify the receiver;
- do not count the shift as the user's work;
- delete an existing synchronized event when applicable.

### Night-to-morning OFF validation
A night shift may imply an OFF or restricted morning on the following day.
In version 1.0 this is a validation warning unless a confirmed rule later requires an OFF event.
