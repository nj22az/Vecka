# Documentation Changelog

Logs all changes to documents under `docs/`. Follows JDS conventions: one heading per revision, newest first. System-level changes (registry entries in `nj22az/JDS_Documentation`) are noted but not duplicated.

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
