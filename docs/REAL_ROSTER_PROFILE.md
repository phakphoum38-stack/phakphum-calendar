# Real Hospital Roster Profile

Sprint 5 is based on the supplied workbook `ตารางเวร จนท.xlsx`.

## Observed layout

- Worksheets cover periods from the 16th of one month through the 15th of the next.
- The date-number row is either row 1 or row 2, identified by the label `วันที่`.
- Column A contains shift labels.
- Daily assignments begin in column B.
- Core sections include Portable, IPD, CT IPD, CT ER, and ER.
- Portable rows use P1-P4 slots with เช้า, บ่าย, or ดึก.
- The period text contains Thai Buddhist calendar years.

## Important discovery about colors

Cell colors in the supplied roster appear to identify staff members visually.
They are not reliable evidence of transfer relationships. Therefore SCE detects
received and given-away shifts by comparing the original and current worker text
at the same date/category/period/slot position.

Colors are preserved as metadata but are not used as the primary ownership rule.

## Comparison rules

At a stable position key:

- Other person -> user: received shift
- User -> other person: given-away shift
- Same user -> same user: unchanged own shift
- Other -> other: unrelated to the user

The user alias list should include `ภาคภูมิ` and any spelling variants used by the roster.
