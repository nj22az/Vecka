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

## Documentation

The authoritative design-system and project documentation lives in [`docs/`](docs/), following [Johansson Documentation System (JDS)](https://github.com/nj22az/JDS_Documentation) conventions:

- [`docs/JDS-MAN-SFW-001_joho-design-system.md`](docs/JDS-MAN-SFW-001_joho-design-system.md) — **the source of truth** for colors, typography, dimensions, IconCatalog, components, modifiers, and house rules.
- [`docs/JDS-PRJ-SFW-002_onsen-planner.md`](docs/JDS-PRJ-SFW-002_onsen-planner.md) — project card (scope, surfaces, tech inventory).
- [`docs/CHANGELOG.md`](docs/CHANGELOG.md) — document revision log.

The tables below are a **quick reference**. When they conflict with `JDS-MAN-SFW-001`, the manual wins.

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

## Rules

- Always use `IconCatalog.*` (no hardcoded SF Symbol strings)
- Always use `JohoColors.*` (no raw colors)
- Always use `.continuous` corners (squircles)
- Always use `.rounded` font design
- Always use black borders on containers
- Never use gradients or glass materials
