# Onsen Planner (Vecka)

iOS 18+ week number app with semantic color coding.
Built with SwiftUI, SwiftData, WidgetKit.

## Build

```bash
./build.sh build    # Debug build
./build.sh test     # Run tests
./build.sh clean    # Clean
```

Or open `Vecka.xcodeproj` in Xcode 16+.

## Structure

```
Vecka/                  # Main app
├── Core/               # Week calculation
├── Models/             # SwiftData models
├── Views/              # SwiftUI views
├── Services/           # External APIs
├── JohoDesignSystem.swift
└── Intents/            # Siri Shortcuts

VeckaWidget/            # Widget extension
```

## Design System (JohoColors)

| Color | Hex | Use |
|-------|-----|-----|
| Yellow | `#FFE566` | Today, notes |
| Cyan | `#A5F3FC` | Events, trips |
| Pink | `#FECDD3` | Holidays |
| Green | `#4ADE80` | Money |
| Purple | `#E9D5FF` | People |
| Red | `#E53935` | Alerts only |

## Icon System (IconCatalog)

All SF Symbol references go through `IconCatalog` in `JohoSymbols.swift` — no hardcoded strings in views.

### 3-Tier Resolution
1. **User override** — `symbolName` on model (user picked via JohoIconPicker)
2. **Category setting** — `CategoryIconSettings.icon(for:)` (theme-defined)
3. **Catalog default** — `IconCatalog.*` constants

### Key Constants
| Constant | Symbol | Use |
|----------|--------|-----|
| `.memo` | `note.text` | Notes, memos |
| `.person` | `person.fill` | Single person |
| `.people` | `person.2.fill` | Groups |
| `.calendar` | `calendar` | Calendar nav |
| `.event` | `calendar.badge.clock` | Events, countdowns |
| `.settings` | `gearshape` | Settings (outline) |
| `.holiday` | `star.fill` | Bank holidays |
| `.observance` | `sparkles` | Observances |
| `.birthday` | `birthday.cake.fill` | Birthdays |
| `.trip` | `airplane` | Trips |
| `.expense` | locale-aware | Money (SEK/EUR/USD/etc.) |

### Currency Icons
Use `IconCatalog.currencyIcon(for: currencyCode)` — returns locale-appropriate symbol (e.g., `swedishkronasign.circle.fill` for SEK).

### Components
- **`JohoSticker`** — Universal avatar/badge (circle or squircle, photo/initials/icon, optional badge overlay)
- **`JohoIconPicker`** — `.johoIconPicker(isPresented:selection:accentColor:)` view modifier
- **`JohoSFSymbolPickerSheet`** — Full SF Symbol picker with search and categories

## Architecture Principles

### Data-Driven, Not Hardcoded
Presentation data (icons, colors, labels, codes) should come from JSON or database — never from switch statements in enums. When you see a switch that maps a type to an icon/color/label, that's a sign it should be a data lookup instead. The goal is: **add a new type by adding a JSON entry, not by editing Swift code**.

Currently being consolidated:
- `DisplayCategory`, `SpecialDayType`, `EntryType` → will become `CategoryEngine` loading from `category-definitions.json`
- `CategoryIconSettings` + `CategoryColorSettings` → will merge into engine's user override layer
- `MemoType` stays as SwiftData discriminator but loses all presentation logic

### Sticker-First Icon Rendering
Every icon in the app should render through `JohoSticker` — the universal visual component with shape, border, colored background, and optional badge. Plain `Image(systemName:)` on its own is not enough. Icons should look like physical stickers you'd stamp into a paper planner. This applies to memo rows, holiday cards, countdown headers, shareable cards, and detail sheet heroes — not just contact avatars.

### Three Data Models, Three Groups
The app has exactly 3 data models and 3 display groups:

| Group | Model | What |
|-------|-------|------|
| Holiday | `HolidayRule` (`isBankHoliday: true`) | Bank holidays |
| Observance | `HolidayRule` (`isBankHoliday: false`) | Cultural days |
| Memo | `Memo` (with type flavors: note, trip, expense, event) | User entries |

Birthdays are a date field on `Contact`, displayed alongside memos. Everything else is a memo with optional enrichments (amount, place, countdown date). There is no separate "birthday model" or "event model."

## Rules

- Always use `IconCatalog.*` (no hardcoded SF Symbol strings)
- Always use `JohoColors.*` (no raw colors)
- Always use `JohoSticker` for icon rendering (no bare `Image(systemName:)` for content icons)
- Always use `.continuous` corners (squircles)
- Always use `.rounded` font design
- Always use black borders on containers
- Never use gradients or glass materials
- Never hardcode presentation data in switch statements — use data lookups
- Never add a new enum case when a JSON entry would do
