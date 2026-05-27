# Onsen Planner (Vecka)

iOS 18+ week-number app with semantic color coding. Built with SwiftUI, SwiftData, and WidgetKit.

## Build

```bash
./build.sh build      # Debug build
./build.sh test       # Run tests
./build.sh widget-test # Build widget target only
./build.sh archive    # Release archive
./build.sh clean
```

Or open `Vecka.xcodeproj` in Xcode 16+.

## Documentation

The repo is documented under the **Johansson Documentation System (JDS)** conventions — numbered documents with revision headers and a changelog. Start in [`docs/`](docs/):

| Doc | Purpose |
|---|---|
| [`docs/JDS-PRJ-SFW-002_onsen-planner.md`](docs/JDS-PRJ-SFW-002_onsen-planner.md) | Project card — scope, surfaces, tech inventory |
| [`docs/JDS-MAN-SFW-001_joho-design-system.md`](docs/JDS-MAN-SFW-001_joho-design-system.md) | Joho Design System manual — colors, icons, components, modifiers, rules |
| [`docs/CHANGELOG.md`](docs/CHANGELOG.md) | Document-level revision log |

The parent system catalogue lives at [nj22az/JDS_Documentation](https://github.com/nj22az/JDS_Documentation).

## Project structure

```
Vecka/                 Main app
├── Core/              Week calculation, category engine, region selection
├── Models/            SwiftData models, holiday engine, theme presets
├── Views/             SwiftUI views
├── Services/          External APIs (Contacts, calendars, lunar, PDF, CSV)
├── Intents/           Siri Shortcuts
├── JohoSymbols.swift  IconCatalog
├── JohoColors via JohoFoundations.swift
├── JohoTokens.swift   Typography & dimensions
├── JohoComponents.swift
├── JohoViewModifiers.swift
└── JohoSettings.swift Theme cache, category color overrides

VeckaWidget/           Widget extension
VeckaTests/            Unit tests
VeckaUITests/          UI tests
```

## House rules

The Joho Design System enforces a strict visual language. Don't hardcode SF Symbol strings or raw colors — see the [design-system manual](docs/JDS-MAN-SFW-001_joho-design-system.md) for the full ruleset.
