# Chapter 13: App Architecture

> "Design systems don't exist in theory. They exist in shipping products."

---

Part 4 demonstrates Joho Dezain through a real production app: WeekGrid. This iOS calendar app displays ISO 8601 week numbers with semantic color coding. Every screen, every component, and every interaction follows the Joho Dezain principles we've covered.

---

## WeekGrid Overview

**What it does:** Displays week numbers with visual indication of holidays, events, and special days.

**Core features:**
- ISO 8601 week number display
- Multi-region holiday support (Sweden, United States, Vietnam)
- Custom events and countdowns
- Daily notes
- Widgets (small, medium, large)
- Siri Shortcuts

**Technical stack:**
- SwiftUI
- SwiftData for persistence
- WidgetKit for home screen widgets
- App Intents for Siri integration

---

## Architecture Pattern

WeekGrid uses a Manager + Model + View pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   User Action                                               │
│       ↓                                                     │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                    View Layer                       │   │
│   │  (SwiftUI Views using Joho Dezain components)        │   │
│   └───────────────────────┬─────────────────────────────┘   │
│                           ↓                                 │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              Manager Layer (Singleton)              │   │
│   │        (Cache check → Query → Cache update)         │   │
│   └───────────────────────┬─────────────────────────────┘   │
│                           ↓                                 │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                   Model Layer                       │   │
│   │           (SwiftData + Pure Swift structs)          │   │
│   └───────────────────────┬─────────────────────────────┘   │
│                           ↓                                 │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                  Engine Layer                       │   │
│   │  (Calculations: Easter, Lunar, Week numbers)        │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
Vecka/
├── Core/                    # Week calculation logic
│   └── WeekCalculator.swift
│
├── Models/                  # Data models
│   ├── HolidayRule.swift    # SwiftData model
│   ├── CalendarRule.swift   # SwiftData model
│   ├── CountdownEvent.swift # SwiftData model
│   ├── DailyNote.swift      # SwiftData model
│   ├── Holiday.swift        # Pure Swift struct
│   └── HolidayEngine.swift  # Calculation engine
│
├── Views/                   # UI components
│   ├── ModernCalendarView.swift
│   ├── AppSidebar.swift
│   ├── PhoneLibraryView.swift
│   └── ... (all views)
│
├── Services/                # External integrations
│   ├── WeatherService.swift
│   ├── PDFExportService.swift
│   └── CurrencyService.swift
│
├── Intents/                 # Siri Shortcuts
│   └── CurrentWeekIntent.swift
│
├── JohoDesignSystem.swift   # Design system components
└── Localization.swift       # i18n strings
```

---

## The Core Engine

### Week Calculation

ISO 8601 week numbers are the foundation. The calculator uses a properly configured calendar:

```swift
struct WeekCalculator {
    static let shared = WeekCalculator()

    private let calendar: Calendar

    init() {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2              // Monday
        cal.minimumDaysInFirstWeek = 4    // ISO 8601
        cal.locale = Locale(identifier: "sv_SE")
        self.calendar = cal
    }

    func weekNumber(for date: Date) -> Int {
        calendar.component(.weekOfYear, from: date)
    }

    func year(for date: Date) -> Int {
        // ISO week year may differ from calendar year
        calendar.component(.yearForWeekOfYear, from: date)
    }
}
```

**Why `minimumDaysInFirstWeek = 4`?**

ISO 8601 defines that week 1 is the week containing January 4th (or equivalently, the week containing the first Thursday of the year). This means:
- Some years start with week 52 or 53 from the previous year
- Some years end with week 1 of the next year

This matches how most of Europe counts weeks.

### Holiday Engine

Holidays come in five types:

```swift
enum HolidayType: String, Codable {
    case fixed           // Dec 25 every year
    case easterRelative  // Good Friday = Easter - 2 days
    case floating        // Midsummer Eve (Friday between June 19-25)
    case nthWeekday      // Thanksgiving (4th Thursday of November)
    case lunar           // Tết (Lunar New Year)
}
```

Each type requires different calculation logic:

```swift
struct HolidayEngine {
    // Fixed: Simple month + day
    static func fixedDate(month: Int, day: Int, year: Int) -> Date? {
        DateComponents(calendar: .current, year: year, month: month, day: day).date
    }

    // Easter: Computus algorithm (complex astronomical calculation)
    static func easterDate(year: Int) -> Date {
        // Gregorian Computus implementation
        let a = year % 19
        let b = year / 100
        let c = year % 100
        // ... full algorithm
    }

    // Floating: Find specific weekday in date range
    static func floatingDate(weekday: Int, monthRange: Range<Int>, year: Int) -> Date? {
        // Find Friday between June 19-25, etc.
    }

    // Nth Weekday: Find nth occurrence of weekday in month
    static func nthWeekday(n: Int, weekday: Int, month: Int, year: Int) -> Date? {
        // 4th Thursday of November, etc.
    }

    // Lunar: Convert lunar calendar date to Gregorian
    static func lunarDate(lunarMonth: Int, lunarDay: Int, year: Int) -> Date? {
        // Chinese calendar conversion
    }
}
```

---

## SwiftData Models

### HolidayRule

```swift
@Model
final class HolidayRule {
    @Attribute(.unique) var id: String
    var name: String
    var localizedName: [String: String]  // ["en": "Christmas", "sv": "Jul"]
    var type: HolidayType
    var month: Int?
    var day: Int?
    var easterOffset: Int?
    var nthOccurrence: Int?
    var weekday: Int?
    var regionCode: String
    var isSystemProvided: Bool  // True = locked, no swipe actions
    var color: String  // Hex color code

    // Computed: Get the date for a specific year
    func date(for year: Int) -> Date? {
        switch type {
        case .fixed:
            return HolidayEngine.fixedDate(month: month!, day: day!, year: year)
        case .easterRelative:
            let easter = HolidayEngine.easterDate(year: year)
            return Calendar.current.date(byAdding: .day, value: easterOffset!, to: easter)
        // ... other types
        }
    }
}
```

### DailyNote

```swift
@Model
final class DailyNote {
    @Attribute(.unique) var dateKey: String  // "2026-01-08"
    var content: String
    var createdAt: Date
    var modifiedAt: Date

    var date: Date {
        // Parse dateKey to Date
    }
}
```

---

## Manager Layer

Managers handle business logic and caching:

```swift
@MainActor
class HolidayManager: ObservableObject {
    static let shared = HolidayManager()

    @Published var holidays: [Holiday] = []
    private var cache: [Int: [Holiday]] = [:]  // Year → Holidays

    func getHolidays(for year: Int, context: ModelContext) -> [Holiday] {
        // Check cache first
        if let cached = cache[year] {
            return cached
        }

        // Query SwiftData
        let rules = try? context.fetch(FetchDescriptor<HolidayRule>())

        // Calculate dates for year
        let holidays = rules?.compactMap { rule in
            guard let date = rule.date(for: year) else { return nil }
            return Holiday(
                id: rule.id,
                name: rule.localizedName(for: Locale.current),
                date: date,
                type: rule.isSystemProvided ? .system : .user,
                color: Color(hex: rule.color)
            )
        } ?? []

        // Update cache
        cache[year] = holidays
        self.holidays = holidays

        return holidays
    }
}
```

---

## View Layer

Views consume managers and display using Joho Dezain components.

### Basic View Structure

```swift
struct WeekDetailView: View {
    let weekNumber: Int
    let year: Int

    @EnvironmentObject var holidayManager: HolidayManager
    @Environment(\.modelContext) var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: JohoSpacing.sm) {
                // Bento header
                JohoBentoHeader(
                    weekNumber: weekNumber,
                    monthYear: monthYearString,
                    onPrevious: { /* navigate */ },
                    onNext: { /* navigate */ },
                    onToday: { /* jump to today */ }
                )

                // Day cards
                ForEach(days) { day in
                    JohoCard {
                        DayContent(day: day)
                    }
                }
            }
            .padding(.horizontal, JohoSpacing.lg)
            .padding(.top, JohoSpacing.sm)  // Max 8pt!
        }
        .background(JohoColors.white)
    }
}
```

---

## Multi-Target Support

WeekGrid shares code between the main app and widget extension:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                    Shared Code                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  WeekCalculator    HolidayEngine    SwiftData Models │   │
│   │  JohoDesignSystem  JohoColors       Localization    │   │
│   └─────────────────────────────────────────────────────┘   │
│                           ↑                                 │
│             ┌─────────────┴─────────────┐                  │
│             │                           │                   │
│   ┌─────────┴───────┐       ┌───────────┴───────┐          │
│   │   Main App      │       │   Widget Extension │          │
│   │                 │       │                    │          │
│   │  Full UI        │       │  Timeline Provider │          │
│   │  Navigation     │       │  Compact Views     │          │
│   │  Services       │       │                    │          │
│   └─────────────────┘       └────────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Target membership in Xcode determines which files are compiled into which target.

---

## Navigation Architecture

### iPad: NavigationSplitView

```swift
struct ContentView: View {
    @State private var selectedTab: Tab = .week

    var body: some View {
        NavigationSplitView {
            AppSidebar(selection: $selectedTab)
        } detail: {
            switch selectedTab {
            case .week:
                WeekView()
            case .year:
                YearView()
            case .star:
                StarPage()
            case .settings:
                SettingsView()
            }
        }
    }
}
```

### iPhone: TabView

```swift
struct ContentView: View {
    @State private var selectedTab: Tab = .week

    var body: some View {
        TabView(selection: $selectedTab) {
            WeekView()
                .tabItem { Label("Week", systemImage: "calendar") }
                .tag(Tab.week)

            YearView()
                .tabItem { Label("Year", systemImage: "calendar.badge.plus") }
                .tag(Tab.year)

            StarPage()
                .tabItem { Label("Star", systemImage: "star") }
                .tag(Tab.star)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(Tab.settings)
        }
    }
}
```

---

## Deep Linking

The app supports URL-based navigation:

```swift
enum DeepLink {
    case today
    case week(number: Int, year: Int)
    case calendar

    init?(url: URL) {
        guard url.scheme == "vecka" else { return nil }

        switch url.host {
        case "today":
            self = .today
        case "week":
            // Parse /weekNumber/year from path
            let components = url.pathComponents.filter { $0 != "/" }
            guard components.count >= 2,
                  let week = Int(components[0]),
                  let year = Int(components[1]) else { return nil }
            self = .week(number: week, year: year)
        case "calendar":
            self = .calendar
        default:
            return nil
        }
    }
}
```

---

## Design System Integration

Every view imports and uses the design system:

```swift
// JohoDesignSystem.swift provides:

struct JohoColors {
    static let black = Color(hex: "000000")
    static let white = Color(hex: "FFFFFF")
    static let yellow = Color(hex: "FFE566")
    static let cyan = Color(hex: "A5F3FC")
    static let pink = Color(hex: "FECDD3")
    // ... all semantic colors
}

struct JohoSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    // ... all spacing tokens
}

extension Font {
    static let johoDisplayLarge = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let johoHeadline = Font.system(size: 18, weight: .bold, design: .rounded)
    // ... all typography styles
}
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           WEEKGRID ARCHITECTURE REFERENCE                  │
│                                                             │
│   PATTERN: Manager + Model + View                          │
│                                                             │
│   LAYERS:                                                  │
│   • View: SwiftUI + Joho Dezain components                  │
│   • Manager: Business logic + caching (singleton)          │
│   • Model: SwiftData + pure Swift structs                  │
│   • Engine: Complex calculations                           │
│                                                             │
│   TARGETS:                                                 │
│   • Vecka (main app)                                       │
│   • VeckaWidgetExtension (widgets)                         │
│   • VeckaTests / VeckaUITests                              │
│                                                             │
│   SHARED CODE:                                             │
│   • WeekCalculator, HolidayEngine                          │
│   • SwiftData models                                       │
│   • JohoDesignSystem                                       │
│                                                             │
│   DEEP LINKS:                                              │
│   • vecka://today                                          │
│   • vecka://week/{number}/{year}                           │
│   • vecka://calendar                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 14 — Calendar Design*

