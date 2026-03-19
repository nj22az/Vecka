# Vecka (Onsen Planner)

iOS week number app with calendar, holidays, memos, contacts, expenses, countdowns, and world clocks. Built with SwiftUI, SwiftData, and WidgetKit.

Designed around a semantic color system where each color encodes meaning: yellow for notes, cyan for events, pink for holidays, green for money, purple for people.

## Requirements

- iOS 18.0+
- Xcode 16+
- Swift 6

No environment variables, API keys, or external services required. All data is stored locally via SwiftData with App Groups for widget sync.

## Build & Run

```bash
./build.sh build    # Debug build
./build.sh test     # Run tests
./build.sh clean    # Clean build artifacts
```

Or open `Vecka.xcodeproj` in Xcode and run on simulator or device.

## Folder Structure

```
Vecka/
├── Core/                   # Business logic & calculations
│   ├── WeekCalculator      # ISO 8601 week math
│   ├── PersonnummerParser  # Swedish ID validation
│   ├── CategoryEngine      # JSON-driven category definitions
│   ├── HolidayRegionSelection
│   └── AppInitializer
│
├── DesignSystem/           # Joho Design System
│   ├── JohoFoundations    # Colors (JohoColors), hex parsing, dimensions
│   ├── JohoTokens         # Spacing, radius, border, opacity, durations
│   ├── JohoSymbols        # IconCatalog (all SF Symbol references)
│   ├── JohoComponents     # Containers, cards, stickers, badges
│   ├── JohoCalendarWidgets # Today banner, week displays, fact cards
│   ├── JohoSettings       # SF Symbol picker, form controls
│   └── JohoViewModifiers  # .johoEditField, .johoIconPicker
│
├── Models/                 # SwiftData models & data types
│   ├── Memo               # Notes, expenses, trips, countdowns (unified)
│   ├── ContactModels       # Contacts, groups, phone/email/address
│   ├── HolidayRule         # Bank holidays & observances
│   ├── CountdownModels     # EventTask, CustomCountdown
│   ├── CalendarModels      # Day, Week, Month structs
│   ├── ConfigurationModels # App preferences, themes
│   └── HolidayEngine      # Holiday date calculation (Computus, lunar)
│
├── Services/               # External integrations & persistence
│   ├── HolidayManager     # Holiday JSON loading, caching, file sync
│   ├── ConfigurationManager # UserDefaults persistence
│   ├── ContactsManager     # iOS Contacts framework bridge
│   ├── SimplePDFRenderer   # PDF export engine
│   ├── CSVExportService    # Memo export to CSV
│   └── RandomFactProvider  # Daily fact selection
│
├── Views/
│   ├── Calendar/           # Main calendar, grid, dashboard, day detail
│   ├── Entries/            # Memos, notes, expenses, trips, countdowns
│   ├── Contacts/           # Contact list, detail, picker
│   ├── Holidays/           # Special days, database explorer, region pickers
│   ├── Landing/            # Star page with month grid
│   ├── Sharing/            # Shareable cards, PDF export UI
│   ├── Settings/           # Settings, developer tools, onboarding
│   └── Common/             # Shared components, navigation, utilities
│
├── Intents/                # Siri Shortcuts
└── Resources/              # JSON data, localizations (8 languages)

VeckaWidget/                # Home screen widget extension
├── Views/                  # Small, Medium, Large widget layouts
├── Components/             # DayCell, BackgroundPattern
└── Provider.swift          # Timeline provider
```

## Design System

All UI is built on the Joho Design System with strict rules:

- **Colors** via `JohoColors.*` — no raw hex in views
- **Icons** via `IconCatalog.*` — no hardcoded SF Symbol strings
- **Spacing** via `JohoDimensions.*` — consistent padding/margins
- **Corners** always `.continuous` (squircles)
- **Font design** always `.rounded`
- **Containers** have black borders, no gradients or glass materials

### Semantic Colors

| Color | Constant | Use |
|-------|----------|-----|
| Yellow `#FFE566` | `JohoColors.yellow` | Today, notes |
| Cyan `#A5F3FC` | `JohoColors.cyan` | Events, trips |
| Pink `#FECDD3` | `JohoColors.pink` | Holidays |
| Green `#4ADE80` | `JohoColors.green` | Money |
| Purple `#E9D5FF` | `JohoColors.purple` | People |
| Red `#E53935` | `JohoColors.red` | Alerts only |

## Localization

Supported languages: English, Swedish, German, Japanese, Korean, Thai, Vietnamese, Chinese (Simplified & Traditional).
