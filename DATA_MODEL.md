# Data Model

## ShiftRecord

Proposed fields:

```text
id
spreadsheetId
sheetId
sourceCell
sourceRow
sourceColumn
date
category
period
startDateTime
endDateTime
originalOwner
actualWorker
transferFrom
transferTo
relationshipType
status
backgroundColor
rawValue
syncId
warnings
```

## RelationshipType

Proposed values:

```text
own
other
received
givenAway
majorExchange
clinicExchange
borrowedFree
borrowedPaid
unknown
```

## ShiftStatus

Proposed values:

```text
valid
warning
blocked
removed
```

## CalendarDiff

```text
toAdd
toUpdate
toDelete
unchanged
blocked
```

## Sync ID

Recommended deterministic composition:

```text
spreadsheetId | sheetId | sourceCell | date | category | period
```

The final implementation should hash or safely encode this value before storing it in
Google Calendar extended properties.
