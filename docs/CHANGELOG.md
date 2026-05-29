# Documentation Changelog

Logs all changes to documents under `docs/`. Follows JDS conventions: one heading per revision, newest first. System-level changes (registry entries in `nj22az/JDS_Documentation`) are noted but not duplicated.

## Rev D — 2026-05-29

**JDS-MAN-SFW-001: fill DS-component documentation gaps; tighten validator.**

A JDS source-of-truth audit found the design-system surface in
`Vecka/JohoCalendarWidgets.swift` undocumented, and a naming bug in §7.10
where the SF Symbol picker was labeled `JohoSymbolPickerSheet` (which is
actually the Japanese-symbol picker) instead of `JohoSFSymbolPickerSheet`.

- §1 (Overview): added `Vecka/JohoCalendarWidgets.swift` to the file
  inventory.
- §7.1 (Containers): added `JohoCalendarContainer`.
- §7.7 (Buttons): added `JohoActionButton`.
- §7.10 (Pickers): rewrote — split `JohoSFSymbolPickerSheet` (SF Symbols,
  in `JohoSettings.swift`) from `JohoSymbolPickerSheet` (Japanese symbols,
  in `JohoSymbols.swift`); added `JohoCalendarPicker`,
  `JohoCalendarPickerSheet`, `JohoYearPicker`; removed the confusing
  `JohoIconPicker` row (the private struct of that name lives in
  `Vecka/Views/CountdownViews.swift` and is not DS API).
- §8 (View modifiers): broadened the leading source-location note to
  cover all four files modifiers now live in; added `.johoCalendarPicker(...)`,
  `.johoYearPicker(...)`, and `.johoColorMode(_:)`.

Companion validator changes (not docs): `scripts/validate-docs.sh` gained
§1 file-existence, §7.1–7.11 struct-existence, and §8 modifier-existence
checks; also fixed a latent prefix-match bug in `extract_section_rows`
(querying section "N.1" would also match "N.10" / "N.11" / "N.12").

## Rev C — 2026-05-29

**JDS-MAN-SFW-001: document automated enforcement.**

A JDS house-rule audit expanded `scripts/lint-design-system.sh` from 3 to
8 enforced rules. This revision documents that coverage.

- Added §10.1 (Automated enforcement): table mapping each house rule to its
  linter id and mode (strict vs. ratchet), and noting the two rules (black
  borders, status-bar legibility) that remain review-only.
- No token, icon, component, or modifier tables changed — `./build.sh
  validate-docs` still passes 52/52.

Companion code changes (not docs): linter now also enforces `colorraw`,
`corners`, `fonts`, `glass`, `weights`; small fixes converted 5 corners to
`.continuous`, 4 sub-`.medium` weights to `.medium`, and added `design:
.rounded` to 9 widget fonts.

## Rev B — 2026-05-27

**JDS-MAN-SFW-001: sync manual with post-cleanup code.**

The IconCatalog and JohoColors dead-code sweeps removed constants the
manual still listed. This revision drops the stale rows.

- §2.4 (Utility tokens): removed `eventPurple`, `inputBackground`,
  `editAction`, `deleteAction` rows — constants deleted from
  `Vecka/JohoFoundations.swift` because they had zero call sites.
- §6.2 (Icon Catalog key constants): removed `.countdown` row —
  constant deleted from `Vecka/JohoSymbols.swift`. Countdowns continue
  to use `.event` (same SF Symbol value), already documented.

No tokens added. No semantic changes. Register entry on the JDS side
needs to be bumped from Rev A to Rev B (see jds-handoff/ in this repo).

## Rev A — 2026-05-27

**Initial documentation set.**

- Created [`JDS-PRJ-SFW-002_onsen-planner.md`](JDS-PRJ-SFW-002_onsen-planner.md) — project card for Onsen Planner. Rev A, CURRENT.
- Created [`JDS-MAN-SFW-001_joho-design-system.md`](JDS-MAN-SFW-001_joho-design-system.md) — Joho Design System manual covering colors, typography, dimensions, icon catalog, components, view modifiers, theme system, and house rules. Rev A, CURRENT.
- Created [`README.md`](README.md) — folder entry point and JDS convention summary.
- Created root [`/README.md`](../README.md) — repo landing page with links into `docs/`.
- Added a Documentation pointer section to [`/CLAUDE.md`](../CLAUDE.md) so the design-system reference is discoverable from the agent context.

**Register entries to mirror into `nj22az/JDS_Documentation/jds/registry/document-register.md`:**

```
JDS-PRJ-SFW-002  Onsen Planner               Rev A  CURRENT  2026-05-27  Nils Johansson
JDS-MAN-SFW-001  Joho Design System Manual   Rev A  CURRENT  2026-05-27  Nils Johansson
```
