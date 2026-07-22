# Software Design Description

## Layers

### Presentation
Flutter screens, widgets, navigation, and view state.

### Application
Use cases such as select roster files, compare rosters, preview synchronization,
confirm synchronization, and load dashboard.

### Domain
ShiftRecord, relationships, validation rules, diff models, and interfaces.

### Infrastructure
Google Sign-In, Drive Picker, Sheets API, Calendar API, secure storage,
local history database, and logging.

## Dependency direction

```text
Presentation -> Application -> Domain
Infrastructure -> Domain interfaces
```

The Domain layer must not import Flutter, Google SDKs, HTTP clients, or database packages.

## Primary use cases

1. Sign in with Google.
2. Select original roster.
3. Select current roster.
4. Parse both rosters.
5. Resolve relationships.
6. Validate business rules.
7. Produce simulation and diff.
8. Preview changes.
9. Confirm synchronization.
10. Write history.
11. Display dashboard.
