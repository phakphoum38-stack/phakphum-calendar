# Comparison and Relationship Foundation

## Added in this increment

- Configurable roster layout profile
- Known shift-time catalog
- Relationship resolver contract and default implementation
- Calendar event candidate model
- Diff engine
- Simulation summary model

## Important boundaries

The default relationship resolver is intentionally conservative.
It only applies meanings that are already known from the approved color mapping.

The system still needs a real roster sample before it can determine:

- which cells represent dates;
- which cells contain owners or workers;
- how combined colors are represented;
- whether names are abbreviated;
- how CT shifts are timed.

## Diff behavior

The diff engine uses stable Sync IDs and classifies events as:

- Add
- Update
- Delete
- Unchanged

A given-away shift is represented with `shouldExist = false`. When an event with the same
Sync ID already exists, it is placed in the delete list.

## Safety

The comparison layer does not directly call Google Calendar.
It only produces a simulation plan for preview and confirmation.
