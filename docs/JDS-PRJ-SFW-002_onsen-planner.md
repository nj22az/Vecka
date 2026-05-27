# JDS-PRJ-SFW-002 — Onsen Planner

**Doc No:** JDS-PRJ-SFW-002
**Rev:** A
**Status:** CURRENT
**Date:** 2026-05-27
**Author:** Nils Johansson

---

## Scope

Onsen Planner (internal name **Vecka**) is an iOS 18+ app for working with ISO 8601 week numbers, calendar overlays, holidays, contacts, trips, expenses, memos, and countdowns. The app uses semantic color coding (one color per concept) drawn from the Joho Design System and exposes its data through home-screen widgets and Siri Shortcuts.

Built with SwiftUI, SwiftData, WidgetKit, EventKit, and the Contacts framework. Targets iOS 18.0+ for the main app, iOS 17.0+ for the widget extension.

## Surfaces

| Surface | Bundle ID | Notes |
|---|---|---|
| Main app | `Johansson.Vecka` | iOS 18+, portrait-only on iPhone, all-but-upside-down on iPad |
| Widget extension | `Johansson.Vecka.VeckaWidget` | iOS 17+, multiple sizes, deep-links via `vecka://` scheme |
| Siri Intents | — | `CurrentWeekIntent`, `WeekOverviewIntent`, `WeekForDateIntent`, shortcuts via `AppShortcuts` |

## Tech inventory

- **UI:** SwiftUI exclusively. No UIKit views (UIKit only via `AppDelegate` for orientation lock and appearance defaults).
- **Persistence:** SwiftData with a fallback chain — primary store → local-only → in-memory (last resort to keep the app launchable on a corrupted store).
- **CloudKit:** disabled at the configuration level (`cloudKitDatabase: .none`) pending model updates for CloudKit compatibility (inverse relationships, optional attributes, no unique constraints).
- **External data:** EventKit (calendars), Contacts, Core Location (weather context, optional), Photos, Camera (QR import).
- **Build:** `./build.sh build|test|widget-test|archive|clean`. Uses `xcodebuild` with code signing disabled for local builds. Default destination is iPhone 17 Pro simulator.

## Source layout

| Folder | Contents |
|---|---|
| `Vecka/Core/` | Week calculation, category engine, region selection, personnummer parser, app initializer |
| `Vecka/Models/` | SwiftData models, holiday engine, calendar rules, theme presets, world clocks, facts, memos |
| `Vecka/Views/` | All SwiftUI views (calendar, landing, contacts, special days, settings, sheets, mascots, sharables) |
| `Vecka/Services/` | External APIs (CSV/PDF export, lunar calendar, world clock sync, contacts, random facts, month theme sync) |
| `Vecka/Intents/` | Siri Shortcuts intents |
| `Vecka/JohoSymbols.swift` | `IconCatalog` and Japanese symbol vocabulary |
| `Vecka/JohoFoundations.swift` | `JohoColors`, `JohoScheme`, `SystemUIAccent`, `JohoColorMode`, hex/luminance helpers |
| `Vecka/JohoTokens.swift` | `JohoFont`, `JohoDimensions`, `SectionZone`, `JohoCardSize`, `Squircle`, `HalfCircle` |
| `Vecka/JohoComponents.swift` | Reusable UI components |
| `Vecka/JohoViewModifiers.swift` | `.johoBackground()`, `.johoNavigation()`, `.johoBordered()`, etc. |
| `Vecka/JohoSettings.swift` | `JohoThemeCache`, category color/icon overrides |
| `VeckaWidget/` | Widget extension (provider, views, holiday engine, month theme, facts) |
| `VeckaTests/`, `VeckaUITests/` | Unit and UI tests |

## Design system

The app's visual language is the **Joho Design System** — documented in full at [`JDS-MAN-SFW-001`](JDS-MAN-SFW-001_joho-design-system.md). Anything visual (colors, icons, layout primitives) flows through that manual; this card does not duplicate it.

## Cross-references

- **External register:** `nj22az/JDS_Documentation` → `projects/software/JDS-PRJ-SFW-002_onsen-planner/`
- **Manual:** [`JDS-MAN-SFW-001_joho-design-system.md`](JDS-MAN-SFW-001_joho-design-system.md)
- **Source:** [`github.com/nj22az/onsen_planner`](https://github.com/nj22az/onsen_planner)

## Open items

- CloudKit sync remains disabled; re-enabling requires schema rework (inverse relationships, optional attributes, removal of unique constraints).
- No `docs/` PDF artifacts yet; `md2pdf.py` from the JDS_Documentation repo can be run against this folder when needed.
- No public release notes document. Will be created as `JDS-LOG-SFW-XXX` when the first versioned release ships.
