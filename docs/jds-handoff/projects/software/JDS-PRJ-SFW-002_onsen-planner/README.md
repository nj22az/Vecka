# JDS-PRJ-SFW-002 — Onsen Planner

**Doc No:** JDS-PRJ-SFW-002
**Rev:** A
**Status:** CURRENT
**Date:** 2026-05-27
**Author:** Nils Johansson

---

## Scope

Onsen Planner (internal name **Vecka**) is an iOS 18+ app for working with ISO 8601 week numbers, calendar overlays, holidays, contacts, trips, expenses, memos, and countdowns. Built with SwiftUI, SwiftData, WidgetKit, EventKit, and the Contacts framework. Portrait-only on iPhone, all-but-upside-down on iPad.

## Source of truth

This entry is a **project card**. The authoritative project and design-system documentation lives next to the code in [`nj22az/onsen_planner`](https://github.com/nj22az/onsen_planner):

- Project card (mirror of this file): [`docs/JDS-PRJ-SFW-002_onsen-planner.md`](https://github.com/nj22az/onsen_planner/blob/main/docs/JDS-PRJ-SFW-002_onsen-planner.md)
- Design-system manual: [`docs/JDS-MAN-SFW-001_joho-design-system.md`](https://github.com/nj22az/onsen_planner/blob/main/docs/JDS-MAN-SFW-001_joho-design-system.md) (currently Rev B)
- Document changelog: [`docs/CHANGELOG.md`](https://github.com/nj22az/onsen_planner/blob/main/docs/CHANGELOG.md)

## Surfaces

| Surface | Bundle ID |
|---|---|
| Main app | `Johansson.Vecka` |
| Widget extension | `Johansson.Vecka.VeckaWidget` |
| Siri Intents | shortcuts via `AppShortcuts` |

## Build

```bash
./build.sh build      # Debug
./build.sh lint       # Joho Design System linter
./build.sh test       # Lint, then unit tests
./build.sh widget-test
./build.sh archive    # Release archive
```

## Related JDS documents

- `JDS-MAN-SFW-001` — Joho Design System Manual (stored in `nj22az/onsen_planner` at `docs/`). Currently at Rev B.

## Open items

- CloudKit sync disabled; pending schema rework.
- No `JDS-LOG-SFW-…` release-notes document yet; will be created at first versioned release.
- 136 legacy `Color(hex:)` literals across 18 files tracked by a ratchet allowlist (`scripts/lint-allowlist.txt` in onsen_planner). Burn-down is ongoing.
