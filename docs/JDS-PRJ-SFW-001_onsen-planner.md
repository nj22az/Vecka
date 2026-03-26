**Document:** JDS-PRJ-SFW-001
**Revision:** A
**Date:** 2026-03-26
**Status:** Active
**Author:** Nils Johansson

* * *

## What Is This?

**Onsen Planner** (internal name: Vecka) is an iOS 18+ week number planner built on **情報デザイン** (Joho Dezain) — Japanese information design principles borrowed from OTC medicine packaging (Muhi, Rohto). Every piece of information carries a semantic color. Every icon resolves through a single catalog. No gradients, no glass materials — just bold borders, continuous corners, and clarity.

The app unifies five personal organization functions — **notes, expenses, trips, countdowns, and contacts** — into a single week-anchored interface with ISO 8601 week numbers, Home Screen widgets, and 8-language localization.

* * *

## The Design Language

```
COLOR        HEX       KANJI    MEANING         USE
─────────────────────────────────────────────────────
Yellow       #FFE566   今 ima    NOW             Today, notes, personal memos
Cyan         #A5F3FC   予定       SCHEDULED       Events, trips, calendar items
Pink         #FECDD3   祝 iwai   CELEBRATION     Holidays, birthdays
Green        #4ADE80   金 kane   MONEY           Expenses, financial tracking
Purple       #E9D5FF   人 hito   PEOPLE          Contacts, relationships
Red          #E53935   警告       ALERT           Warnings and errors only
```

Six colors. Six meanings. No overlap. The system derives foreground contrast automatically per mode (light/dark/OLED) using WCAG 2.1 luminance calculations.

* * *

## How the App Is Organised

```
Vecka/
├── Core/                     ← Week math, category engine, holiday regions
│   ├── WeekCalculator        Thread-safe ISO 8601 calculation
│   ├── CategoryEngine        JSON-driven category definitions
│   └── HolidayRegionSelection
│
├── DesignSystem/             ← The Joho Design System (5 files)
│   ├── JohoFoundations      6-color palette, hex conversion, contrast
│   ├── JohoTokens           Typography, spacing, dimensions, shapes
│   ├── JohoSymbols           IconCatalog (150+ constants), pickers
│   ├── JohoComponents        Buttons, cards, badges, stickers
│   └── JohoSettings          Configuration UI controls
│
├── Models/                   ← SwiftData persistence
│   ├── Memo                  Unified model (note/expense/trip/countdown)
│   ├── Contact               Full contact with 7 child models + vCard
│   ├── HolidayRule           Region-aware, Computus/lunar support
│   ├── JohoTheme             3 locked presets (Light/Dark/Earth)
│   ├── WorldClock            400+ cities, day/night indicators
│   └── CalendarModels        Day → Week → Month hierarchy
│
├── Views/                    ← SwiftUI interface
│   ├── Calendar/             ModernCalendarView (iPad 3-column, iPhone stack)
│   ├── Entries/              Memo creation: notes, expenses, trips, countdowns
│   ├── Contacts/             Contact list, detail, group filtering
│   ├── Holidays/             Special days explorer, region selector
│   ├── Landing/              Star page — bento card layout, month grid
│   ├── Settings/             Theme, color mode, region, developer tools
│   └── Sharing/              PDF export, vCard generation, CSV
│
└── Services/                 ← External integrations

VeckaWidget/                  ← WidgetKit extension
├── Small                     Week hero + daily fact
├── Medium                    Calendar grid + upcoming events
└── Large                     Full month view with color indicators
```

* * *

## Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| **Unified Memo model** (single `@Model`, type discriminator) | One query surface, content-aware computed properties, 14 factory methods instead of 4 separate models |
| **Three-tier icon resolution** (user override → category setting → catalog default) | Users can personalize without breaking the system; all paths resolve through `IconCatalog` |
| **JSON-driven configuration** (categories, themes, symbols) | Database-level flexibility without code changes; graceful fallbacks when JSON fails |
| **OLED-first dark mode** (true black canvas, elevated surfaces) | Battery efficiency on OLED panels; soft off-white text (#F0F0F0) reduces eye strain |
| **Thread-safe caching** (NSLock on WeekCalculator, NSCache on CurrencyFormatter) | Week calculations are hot-path; formatter allocation is expensive |
| **App Group shared container** | Widget reads holidays and facts without full model access |

* * *

## The Priority System

Uses **Maru-Batsu** (○×△) — Japanese evaluation symbols:

| Symbol | Priority | Meaning |
|--------|----------|---------|
| ◎ | High | Double circle — outstanding, must-do |
| ○ | Normal | Circle — standard, acceptable |
| △ | Low | Triangle — caution, defer if needed |

* * *

## How to Build

```bash
./build.sh build    # Debug build
./build.sh test     # Run tests
./build.sh clean    # Clean build artifacts
```

Requires Xcode 16+, iOS 18+ deployment target. SwiftData local-only (CloudKit disabled pending model stabilization).

* * *

## Related Documents

| Type | Reference | Description |
|------|-----------|-------------|
| Design System | `Vecka/DesignSystem/` | 5-file Joho Design System |
| Data Definitions | `Vecka/Models/` | SwiftData models, 10 files |
| Localization | `Vecka/Localization.swift` | 8 languages (EN, SV, DE, JA, KO, TH, VI, ZH) |
| Widget | `VeckaWidget/` | 3-size WidgetKit extension |
| Category Definitions | `category-definitions.json` | JSON-driven category engine source |
| Theme Presets | `theme-presets.json` | Light/Dark/Earth theme configurations |
| Symbol Library | `joho-symbols.json` | SF Symbol picker sections |

* * *

## Revision History

| Rev | Date | Description |
|-----|------|-------------|
| A | 2026-03-26 | Initial project description in JDS format |
