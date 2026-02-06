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

## Rules

- Always use `JohoColors.*` (no raw colors)
- Always use `.continuous` corners (squircles)
- Always use `.rounded` font design
- Always use black borders on containers
- Never use gradients or glass materials
