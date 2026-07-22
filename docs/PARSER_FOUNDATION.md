# Shift Parser Foundation

## Purpose

The parser foundation converts Google Sheets API responses into a stable,
testable representation before hospital-specific parsing begins.

## Extracted cell information

Each populated API cell can carry:

- zero-based row and column indexes;
- A1 coordinate;
- formatted value;
- effective raw value;
- formula;
- effective background color;
- effective number format;
- merged-range membership;
- merged-range anchor coordinate.

## Merged ranges

Google Sheets merged ranges use zero-based, end-exclusive grid coordinates.
SCE preserves this exact model and calculates the anchor as the top-left cell.

## Background colors

SCE prefers `backgroundColorStyle.rgbColor` and falls back to the deprecated
`backgroundColor` field. Theme-color resolution is not implemented yet.

Colors are stored as normalized red, green, blue, and alpha values from 0 to 1.
Business meanings are resolved through configurable rules and tolerance rather
than hardcoded color names.

## Important limitation

The exact Google color values used by the hospital roster are still unknown.
Graphite, Tomato, Lavender, Purple, Avocado, Banana, Parrot, and default blue
must be sampled from a real roster before activating relationship rules.

## Next parser step

Create a roster layout profile that identifies:

- date headers;
- employee-name column;
- shift rows or columns;
- category labels;
- user identity;
- original owner and actual worker fields.

No layout assumption should be added until a sample roster is available.
