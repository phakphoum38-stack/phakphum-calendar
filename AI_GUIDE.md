# AI Development Guide

Before modifying code, an AI assistant must read:

1. `MASTER_PLAN.md`
2. `PROJECT_CONSTITUTION.md`
3. `PROJECT_RULES.md`
4. `BUSINESS_RULES.md`
5. `DATA_MODEL.md`
6. relevant ADRs

## Required behavior

- Do not invent unconfirmed business rules.
- State assumptions explicitly.
- Prefer small, testable changes.
- Do not place secrets in source control.
- Update documentation when behavior changes.
- Create an ADR for structural decisions.
- Preserve separation between parser, rules, and synchronization.
- Include tests for new domain behavior.

## Change report format

Each meaningful change should report:

- files created or modified;
- behavior added;
- tests added;
- commands run;
- known limitations;
- next recommended task.
