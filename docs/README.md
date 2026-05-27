# Onsen Planner — Documentation

This folder is the **source of truth** for Onsen Planner's project and design documentation.
It follows the [Johansson Documentation System (JDS)](https://github.com/nj22az/JDS_Documentation) conventions:

- Every document carries an identifier of the form `JDS-<CATEGORY>-<DOMAIN>-<NUMBER>`.
- Every document carries a header block with `Doc No`, `Rev`, `Status`, `Date`, `Author`.
- Revisions advance alphabetically (A, B, C…, omitting I, O, Q, S, X, Z).
- Status is either `CURRENT` or `SUPERSEDED`.
- Changes are logged in [`CHANGELOG.md`](CHANGELOG.md).

The parent JDS register at [`nj22az/JDS_Documentation`](https://github.com/nj22az/JDS_Documentation) carries a mirror entry for this project at `projects/software/JDS-PRJ-SFW-002_onsen-planner/` — that copy is a project card; the manual itself stays here next to the code.

## Documents

| Doc No | Title | Status |
|---|---|---|
| [`JDS-PRJ-SFW-002`](JDS-PRJ-SFW-002_onsen-planner.md) | Onsen Planner — Project Card | CURRENT (Rev A) |
| [`JDS-MAN-SFW-001`](JDS-MAN-SFW-001_joho-design-system.md) | Joho Design System Manual | CURRENT (Rev B) |

## JDS_Documentation hand-off

[`jds-handoff/`](jds-handoff/) holds copy-ready content for the parent `nj22az/JDS_Documentation` repo (project card + register additions). See [`jds-handoff/README.md`](jds-handoff/README.md) for the apply instructions.

## How to update

1. Edit the document. Bump the `Rev` letter in the header block and update the `Date`.
2. Add an entry under the new revision heading in [`CHANGELOG.md`](CHANGELOG.md).
3. If a document is replaced rather than revised, mark the old revision `SUPERSEDED` and create a new file at the next available number.
4. When a `JDS-PRJ-…` or `JDS-MAN-…` document is created, mirror the register entry into `jds/registry/document-register.md` in the JDS_Documentation repo.

## Conventions specific to this repo

- **SFW domain.** All documents here use the `SFW` (software) domain code because Onsen Planner is a software project. Mechanical/marine domains do not apply.
- **No hard-coded paths in docs.** When referencing Swift source, use repo-relative paths (e.g. `Vecka/JohoFoundations.swift`).
- **Tables over prose** for tokens, components, and constants — they're the parts that change.
