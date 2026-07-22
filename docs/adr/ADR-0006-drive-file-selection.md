# ADR-0006: Drive spreadsheet selection strategy

- Status: Proposed
- Date: 2026-07-22

## Context

The product requirement specifies Google Drive Picker. Google provides different
integration paths for web, Android, and other environments.

## Interim decision

Implement a testable Drive API spreadsheet browser as the first functional selection
surface while retaining `RosterFilePicker` as the product-level abstraction.

This browser:

- requests Drive read-only access;
- lists only Google Sheets files;
- does not upload, move, copy, or modify Drive files;
- supports original/current file selection.

## Required follow-up

Replace or complement the browser with the official Google Picker experience on each
supported platform after platform-specific setup and testing.

## Consequences

The project can proceed with parsing and comparison before all native picker integrations
are complete, without changing the domain contract later.
