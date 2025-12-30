# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WeekGrid is an iOS app displaying ISO 8601 week numbers with dynamic planetary color associations. Built with SwiftUI, SwiftData, and WidgetKit, it features Swedish holiday integration, custom countdowns, and comprehensive Siri Shortcuts support. The app targets iOS 18.0+ and follows Apple HIG design principles with authentic glassmorphism materials.

**Project folder name**: `Vecka` (legacy, kept for backwards compatibility)
**App name**: `WeekGrid`

## Build Commands

### Quick Start
```bash
# Build the app (Debug)
./build.sh build

# Build for release
./build.sh build-release

# Run tests
./build.sh test

# Clean build artifacts
./build.sh clean

# Validate project structure
./build.sh validate
```

### Xcode Commands
```bash
# Build for simulator
xcodebuild build -project Vecka.xcodeproj -scheme Vecka \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Run tests
xcodebuild test -project Vecka.xcodeproj -scheme Vecka \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# List available simulators
xcrun simctl list devices available
```

### Widget-Specific Build
```bash
# Test widget extension build
./build.sh widget-test

# Or directly with xcodebuild (target is VeckaWidgetExtension)
xcodebuild build -project Vecka.xcodeproj -scheme Vecka \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Code Quality
```bash
# Run SwiftLint (install with: brew install swiftlint)
swiftlint lint

# Auto-fix correctable issues
swiftlint --fix

# Check for TODO/FIXME comments
grep -r "TODO\|FIXME" --include="*.swift" .
```

## Architecture Overview

### Multi-Target Structure
- **Vecka**: Main app target (iOS 18.0+)
- **VeckaWidgetExtension**: Widget extension target with small/medium/large variants
- **VeckaTests**: Unit test suite
- **VeckaUITests**: UI automation tests

**Note**: Code sharing between app and widget happens through direct file inclusion in both targets. When adding new files that should be accessible from widgets, ensure the file is added to both the Vecka and VeckaWidgetExtension targets in Xcode's Target Membership settings.

### Core Architecture Pattern: Manager + Model + View

The app uses a sophisticated manager-based architecture with SwiftData persistence:

**1. Core Calculator Layer** (`Vecka/Core/`)
- `WeekCalculator`: Thread-safe ISO 8601 week calculation with caching
  - Singleton pattern with configurable calendar rules
  - Dictionary-based cache keyed by week/year
  - Supports custom calendar configurations from database

**2. Model Layer** (`Vecka/Models/`)
- SwiftData models for persistence:
  - `HolidayRule`: Database-driven holiday definitions
  - `CalendarRule`: Configurable ISO 8601 calendar systems
  - `CountdownEvent`: User-created countdown events
  - `DailyNote`: Daily note entries
- Pure Swift structs:
  - `Holiday`: Computed holiday instances
  - `CalendarModels`: Supporting types

**3. Manager Layer** (Singleton Pattern)
- `HolidayManager`: Holiday calculation and caching
  - Uses `HolidayEngine` for date calculation algorithms
  - Supports fixed, Easter-relative, floating, nth-weekday, and lunar holidays
  - Caches computed holidays by year
- `CalendarManager`: Calendar rule management
  - Loads/saves ISO 8601 calendar configurations
  - Integrates with WeekCalculator for dynamic calendar updates
- `CountdownManager`: Countdown event management
  - Handles predefined and custom countdown events
  - Calculates next occurrence for annual events

**4. Engine Layer** (`Vecka/Models/HolidayEngine.swift`)
- Pure algorithm implementations:
  - Anonymous Gregorian Computus for Easter calculations
  - Floating weekday finder (e.g., "Saturday between June 20-26")
  - Nth weekday calculator (e.g., "2nd Sunday in November")
  - Lunar calendar conversion for Asian holidays

**5. View Layer** (`Vecka/Views/`, root views)
- **ModernCalendarView**: Modern Apple HIG-compliant UI (current default)
  - iPad: NavigationSplitView with AppSidebar
  - iPhone: TabView with Calendar/Library/Settings tabs
- **ContentView**: Simple wrapper that instantiates ModernCalendarView
- **AppSidebar**: Left sidebar for iPad NavigationSplitView
- **PhoneLibraryView**: Library/favorites view for iPhone TabView
- Modular view components (15 active in `Vecka/Views/`):
  - Calendar: `CalendarGridView`, `DayDashboardView`, `OverviewDashboardView`
  - Notes: `DailyNotesView`, `NotesListView`
  - Holidays: `HolidayListView`, `ObservancesListView`
  - Weather: `WeatherForecastView` (backend complete, UI ready for re-enablement)
  - Expenses: `ExpenseListView`, `ExpenseEntryView`
  - Travel: `TripListView`
  - Export: `PDFExportView`
  - Location: `LocationManagerView`, `LocationSearchView`

**6. Services Layer** (`Vecka/Services/`)
- Weather: `WeatherService` (WeatherKit integration), `WeatherIconMapper`, `WeatherLocalization`
- Travel & Expenses: `TravelManager`, `ExpenseManager`, `CurrencyService`
- PDF Export: `PDFExportService`, `PDFRenderer`, `PDFExportModels`

**7. Core Utilities** (`Vecka/Core/`)
- `AppInitializer`: Centralized app initialization and data seeding
- `WeekCalculator`: Thread-safe ISO 8601 week calculations
- Migration helpers: `NotesMigration`, `CountdownMigration`
- Settings: `HolidayRegionSelection`

### Design System (`DesignSystem.swift`)
- **Planetary Color Associations**: 7 colors for each weekday (Monday=Moon/Silver, Tuesday=Fire/Red, etc.)
- **Apple Semantic Colors**: Auto-adapting light/dark mode using `.systemBackground`, `.label`, etc.
- **Typography System**: Apple HIG-compliant font scale
- **Thread-Safe Utilities**: Safe hex color parsing with clamping

### Data Flow Pattern
```
User Action → View
           ↓
     Manager.shared (cache check)
           ↓
     SwiftData Query / Engine Calculation
           ↓
     Cache Update → View Update
```

### Performance Optimizations
1. **Calendar Singleton**: Cached ISO 8601 calendar eliminates repeated allocations
2. **Manager Caching**: Each manager implements dictionary-based caching with intelligent invalidation
3. **WeekInfo Caching**: Week calculations cached by week/year key
4. **Thread Safety**: Concurrent queue for WeekCalculator with barrier writes

## Key Technical Details

### ISO 8601 Calendar Configuration
All week calculations use a consistent ISO 8601 calendar:
```swift
var calendar = Calendar(identifier: .gregorian)
calendar.firstWeekday = 2        // Monday
calendar.minimumDaysInFirstWeek = 4  // ISO 8601 standard
calendar.locale = Locale(identifier: "sv_SE")
```

Access via `Calendar.iso8601` extension or `WeekCalculator.shared`.

### Holiday Calculation System
Holidays are defined as SwiftData `HolidayRule` entities with five types:
- **Fixed**: Specific month/day (e.g., Christmas: Dec 25)
- **Easter-relative**: Days offset from Easter (e.g., Good Friday: Easter - 2)
- **Floating**: Specific weekday in date range (e.g., Midsummer: Saturday Jun 20-26)
- **Nth weekday**: Ordinal weekday in month (e.g., Mother's Day: Last Sunday in May)
- **Lunar**: Chinese calendar conversion (e.g., Tet: 1st day of 1st lunar month)

### Siri Shortcuts Integration (`Vecka/Intents/`)
- `CurrentWeekIntent`: "What week is it?"
- `WeekOverviewIntent`: "Show week overview"
- `WeekForDateIntent`: Get week for specific date
- `AppShortcuts.swift`: Defines Siri phrase triggers

### Widget Deep Linking
Widgets use `vecka://` URL scheme:
- `vecka://today`: Navigate to current week
- `vecka://week/{weekNumber}/{year}`: Navigate to specific week
- `vecka://calendar`: Navigate to calendar view

## Important Conventions

### File Organization
- Core logic in `Vecka/Core/`
- Data models in `Vecka/Models/`
- Reusable views in `Vecka/Views/`
- App Intents in `Vecka/Intents/`
- Root views (`ContentView`, `MainCalendarView`, `SettingsView`) at `Vecka/` level

### Localization
- Primary: Swedish (sv_SE)
- Secondary: English, Japanese, Korean, German, Vietnamese, Thai, Chinese (Simplified & Traditional)
- Use `Localization` struct for all user-facing strings
- Holiday names localized via `HolidayRule.localizedName`
- Localization files in `Vecka/*.lproj/Localizable.strings`

### SwiftData Context Usage
The app uses `AppInitializer` for centralized initialization and data seeding:
```swift
// In VeckaApp.swift
.modelContainer(for: [
    DailyNote.self,
    HolidayRule.self,
    CalendarRule.self,
    CountdownEvent.self,
    // Expense system models
    ExpenseCategory.self,
    ExpenseTemplate.self,
    ExpenseItem.self,
    TravelTrip.self,
    MileageEntry.self,
    ExchangeRate.self,
    // Location
    SavedLocation.self
])
```

Initialization managed by `AppInitializer.swift` which seeds:
- **CalendarManager**: Swedish (ISO 8601, active) and US calendar rules
- **HolidayManager**: 20+ Swedish holidays with Easter calculations
- **CountdownManager**: Predefined countdown events (New Year, Christmas, etc.)

When adding new SwiftData models, add them to both the `modelContainer(for:)` list in `VeckaApp.swift` and update `AppInitializer.swift` if seeding is needed.

### Apple HIG Compliance
- Minimum 44pt touch targets
- 8-point grid system spacing
- Semantic colors for light/dark mode
- `.ultraThinMaterial` backgrounds for glassmorphism
- Proper accessibility labels (foundation in place)

### XPC-Safe Operations
All code must handle Xcode preview environment gracefully:
- Wrap XPC calls in do-catch blocks
- Provide fallback values for previews
- Test in both simulator and preview canvas

## Testing

### Unit Tests (`VeckaTests/VeckaTests.swift`)
Focus on core business logic:
- Week calculation accuracy
- Holiday date computation
- Calendar rule application
- Countdown next-occurrence logic

### UI Tests (`VeckaUITests/`)
Automated UI testing for:
- Navigation flows
- Widget interaction
- Settings configuration
- Launch performance

## Common Development Tasks

### Working with Travel & Expenses
The app includes a comprehensive travel and expense tracking system:

**Data Models** (`Vecka/Models/ExpenseModels.swift`, `Vecka/Models/BusinessRules.swift`):
- `TravelTrip`: Trip container with start/end dates, destination, purpose
- `ExpenseItem`: Individual expenses with category, amount, currency, receipt
- `MileageEntry`: Vehicle mileage tracking with distance and rate
- `ExpenseCategory`: User-defined expense categories
- `ExpenseTemplate`: Reusable expense templates
- `ExchangeRate`: Currency conversion rates

**Services**:
- `ExpenseManager`: CRUD operations for expenses and trips
- `TravelManager`: Trip management and report generation
- `CurrencyService`: Currency conversion with cached rates

**Views**:
- `TripListView`: Browse and manage trips
- `ExpenseListView`: View expenses for a trip
- `ExpenseEntryView`: Add/edit individual expenses

**PDF Export Integration**:
Expense data is included in PDF exports via `PDFExportService` and `PDFRenderer`.

### Adding a New Holiday
1. Define `HolidayRule` in SwiftData (edit `HolidayManager.seedDefaultRules`)
2. Specify type (fixed/Easter-relative/floating/nth-weekday/lunar)
3. Add localized name for all supported languages
4. `HolidayEngine` automatically calculates the date
5. Example:
```swift
let valentines = HolidayRule(
    id: "valentines-day",
    name: "Valentine's Day",
    localizedName: ["en": "Valentine's Day", "sv": "Alla hjärtans dag"],
    type: .fixed,
    month: 2, day: 14,
    regionCode: "INTL"
)
context.insert(valentines)
```

### Adding a New Calendar Configuration
1. Create `CalendarRule` entity with desired settings in `CalendarManager.seedDefaultRules`
2. `CalendarManager` loads on app initialization
3. `WeekCalculator` updates dynamically via `configure(with:)`
4. Example for UK:
```swift
let ukRule = CalendarRule(
    regionCode: "UK",
    identifier: "gregorian",
    firstWeekday: 2,  // Monday
    minimumDaysInFirstWeek: 4,  // ISO 8601
    localeIdentifier: "en_GB",
    isActive: false
)
```

### Modifying UI Layout
- **Current UI**: `ModernCalendarView.swift` (Apple HIG-compliant)
  - iPad: Three-column NavigationSplitView (AppSidebar → month list → calendar detail)
  - iPhone: TabView with Calendar/Library/Settings tabs
  - Calendar grid in `CalendarGridView.swift`
- **ContentView**: Simple wrapper instantiating ModernCalendarView
- Navigation managed via `NavigationManager` environmentObject
- See `TODO_VECKA_FEATURES.md` for planned UI improvements

### Adding Siri Shortcuts
1. Create Intent in `Vecka/Intents/YourIntent.swift`
2. Implement `AppIntent` protocol with `perform()` method
3. Add to `AppShortcuts.swift` with phrase triggers
4. Test via Shortcuts app or "Hey Siri"
5. Example:
```swift
struct MyIntent: AppIntent {
    static var title: LocalizedStringResource = "My Action"

    func perform() async throws -> some IntentResult {
        // Your logic here
        return .result()
    }
}
```

### Working with Daily Notes
The daily notes feature is fully implemented:
1. SwiftData model: `DailyNote.swift` with text, color, and symbol support
2. UI Components: `DailyNotesView.swift`, `NotesListView.swift`, `NoteColorPicker.swift`
3. Editing: Tap any day in calendar grid to view/edit notes
4. Features: 8 preset colors, 50+ SF Symbols, auto-save with debouncing
5. Integration: Notes appear in calendar grid and PDF exports

## Build Configuration

### Bundle Identifiers
- Main App: `Johansson.Vecka` (legacy identifier, will update for App Store)
- Widget: `Johansson.Vecka.VeckaWidget`
- **App Store Name**: WeekGrid

### Deployment Targets
- Main App: iOS 18.0+
- Widget: iOS 18.0+
- Development Team: P4LGU6F45C
- Xcode Version: 16.2+
- Swift Version: Swift 6.0

### Capabilities & Entitlements
- App Sandbox enabled
- Siri & Shortcuts integration
- WeatherKit (requires paid Apple Developer account)
- Location services (for weather)
- EventKit (calendar access for widget)
- File access: read-only user-selected files for PDF export

### CI/CD Pipeline
GitHub Actions workflow (`.github/workflows/ios-build.yml`) runs on push/PR:
- Build validation
- Widget-specific validation
- Unit tests (continue-on-error enabled)
- SwiftLint code quality checks
- Build artifact archival

## Widget Implementation

### Widget Architecture
- **Provider**: `VeckaWidget/Provider.swift` - Timeline provider with EventKit integration
- **Entry Model**: `VeckaWidgetEntry` - Contains week info, holidays, countdown, and calendar events
- **Views**: Separate view files in `VeckaWidget/Views/`
  - `SmallWidgetView.swift`: Week number with planetary color
  - `MediumWidgetView.swift`: Week number + date range
  - `LargeWidgetView.swift`: Full 7-day calendar with events
- **Theme**: `VeckaWidget/Theme.swift` - Shared styling and colors
- **Components**: Reusable UI in `VeckaWidget/Components/`

### Widget Sizes
- **Small (2x2)**: Week number with dynamic planetary color
- **Medium (4x2)**: Week number + date range + next countdown
- **Large (4x4)**: Full 7-day calendar with today highlighting, holidays, and calendar events

### Timeline Management
- Widget refreshes at midnight for accurate week transitions
- Timeline provider calculates next midnight and schedules update
- Calendar events fetched via EventKit (requires user permission)
- Falls back gracefully if calendar access denied

### Widget Deep Linking
All widget views support deep linking via `vecka://` URL scheme. Handle in `VeckaApp.swift`:
```swift
.onOpenURL { url in
    handleWidgetURL(url)
}
```

### Adding Widget Features
1. Update `VeckaWidgetEntry` with new data
2. Modify `Provider.swift` to fetch/calculate data
3. Update widget view files to display new data
4. Ensure data is available in both app and widget targets
5. Test in widget gallery and on home screen

## Design Philosophy

### Planetary Color System
Week numbers dynamically change color based on the selected day's planetary association:
- Monday (Moon): Silver (#C0C0C0)
- Tuesday (Mars): Red (#E53E3E)
- Wednesday (Mercury): Blue (#1B6DEF)
- Thursday (Jupiter): Green (#38A169)
- Friday (Venus): Dark Gold (#B8860B)
- Saturday (Saturn): Brown (#8B4513)
- Sunday (Sun): Golden (#FFD700)

### Swedish Cultural Integration
Authentic Swedish holiday calendar with proper timezone handling (Europe/Stockholm) and cultural significance preservation.

### Performance-First Architecture
- Multi-level caching (Calendar, WeekInfo, Holiday, Countdown)
- Cached singletons prevent repeated allocations
- Thread-safe concurrent access with barrier writes
- Intelligent cache invalidation on date/rule changes

## Known Architecture Patterns

### Manager Singleton Pattern
```swift
class XManager {
    static let shared = XManager()
    private var cache: [Key: Value] = [:]

    func initialize(context: ModelContext) {
        // Seed database, load initial data
    }

    func getData() -> Value {
        // Check cache → Query SwiftData → Update cache → Return
    }
}
```

All managers (`HolidayManager`, `CalendarManager`, `CountdownManager`) follow this pattern with caching for performance.

### View State Management
- `@State`: Local UI state within a view
- `@StateObject`: Shared managers (deprecated pattern, migrating to @Observable)
- `@Query`: SwiftData queries in views
- `@Environment(NavigationManager.self)`: Navigation state across views

### SwiftData Integration
Models conform to SwiftData's `@Model` macro. Queries use `@Query` property wrapper in views or explicit ModelContext queries in managers.

### Navigation Pattern
Deep linking and widget taps handled via `NavigationManager`:
```swift
// In VeckaApp.swift
.onOpenURL { url in
    handleWidgetURL(url)  // Parses vecka:// URLs
}

// NavigationManager propagates to views
class NavigationManager: ObservableObject {
    @Published var targetDate = Date()
    @Published var shouldScrollToWeek = false

    func navigateToWeek(_ weekNumber: Int, year: Int) { ... }
}
```

### Performance Best Practices
1. **Use Calendar.iso8601 extension**: Reuses cached calendar instance
2. **Manager caching**: All managers cache computed results
3. **SwiftData @Query**: Automatic UI updates on data changes
4. **Debouncing**: Notes auto-save uses 500ms debounce (see `DailyNotesView`)
5. **Background processing**: Weather and PDF generation on background threads

## Debugging Tips

### Week Calculation Issues
- Verify `Calendar.iso8601` configuration (firstWeekday=2, minimumDaysInFirstWeek=4)
- Check cache invalidation in `WeekCalculator`
- Use `Log.i()` for debug output

### Holiday Calculation Problems
- Verify `HolidayRule` data in SwiftData
- Test `HolidayEngine` algorithm directly
- Check Easter calculation for moveable holidays
- Validate timezone (Europe/Stockholm for Swedish holidays)

### Widget Not Updating
- Verify timeline provider midnight calculation
- Check widget URL scheme handling in `VeckaApp`
- Ensure shared code compiles for widget target

### Build Failures
- Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Verify code signing settings (usually disabled for simulator)
- Check target membership for new files

## Project Documentation

### Active Documentation
- `CLAUDE.md`: Project instructions and architecture guide (this file)
- `TODO_VECKA_FEATURES.md`: Feature roadmap with detailed task breakdowns
- `REMAINING_ISSUES.md`: Deferred issues and known limitations
- `DEVELOPMENT_REPORT_2025-12-13.md`: Most recent development status
- `COMPLETE_REBUILD_PLAN.md`: Long-term vision and feature planning
- `TESTFLIGHT_AUDIT.md`: TestFlight readiness checklist

### Archived Documentation
Historical work logs are archived in `Documentation/Archive/`:
- Completed HIG implementation audits
- Completed UI redesign documentation
- Completed feature implementation logs
- Refactoring completion reports

Reference archived documentation when understanding past design decisions or implementation history.

## Project Status (December 2025)

### Completed Cleanup (2025-12-15 & 2025-12-27)
**Orphaned Code Removal (2025-12-15):**
- Deleted `AnalogClockView.swift` (5.6k LOC) - Unused StandBy mode component
- Deleted `WeatherComponents.swift` (11.8k LOC) - Unintegrated UI components
- Total code reduction: 17,400 LOC (8.9% of codebase)

**Database & Code Optimization (2025-12-27):**

**Phase 1 - Zero-Risk Deletions:**
- Deleted 3 unused display components: `ClockDisplay.swift`, `MonthYearDisplay.swift`, `WeekNumberDisplay.swift` (~200 LOC)
- Deleted `ExportService.swift` - duplicate export functionality (~100 LOC)
- Removed 3 unused SwiftData models from container: `ReimbursementRate`, `ExpensePolicy`, `ApprovalWorkflow`
- Database reduced from 15 to 12 active models (20% reduction)

**Phase 2 - Aggressive Cleanup:**
- Removed ~250 LOC of commented Weather code from `SettingsView.swift` and `ModernCalendarView.swift`
- Deleted Business Rules system: `RuleEngine.swift`, `BusinessRules.swift` (~1,000 LOC)
- Deleted 12 unused view components (~2,000 LOC):
  - Countdown: `CountdownManagementView.swift`
  - Holidays: `HolidayRuleEditorView.swift`
  - Notes: `NoteColorPicker.swift`, `NoteAppearancePickerViews.swift`, `DayNotesBar.swift`
  - Expenses: `DailyExpensesView.swift`, `MileageListView.swift`, `MileageEntryView.swift`, `TripReportPreviewView.swift`
  - Weather: `WeatherStatusBanner.swift`, `WeatherBadge.swift`, `WeatherSetupAssistant.swift`

**Total Cleanup Impact:**
- **~3,550 LOC removed** in Phase 1 + Phase 2
- **3 SwiftData models removed** from container
- **19 files deleted** (4 core files + 12 views + 3 display components)
- Reduced memory footprint, faster initialization, cleaner codebase

**Documentation Reorganization:**
- Archived 18 completed work logs to `Documentation/Archive/`
- Deleted 7 superseded planning documents
- Reduced active documentation from 32 to 7 essential files

**Weather Feature Status:**
- ✅ Backend: WeatherService.swift fully functional with WeatherKit integration
- ✅ Settings: Weather toggle and location management implemented
- ✅ UI: Full weather display components implemented
  - `WeatherForecastView`: Detailed weather display
  - `WeatherBadge`: Calendar day weather indicators
  - `WeatherStatusBanner`: Current conditions
  - `WeatherSetupAssistant`: First-time setup flow
- ✅ Integration: Weather data in calendar grid and PDF exports
- ⚠️ Requires: Paid Apple Developer account for WeatherKit access

### Current Architecture State
**Build Status**: ✅ 100% passing (0 errors, 0 warnings)
**Code Health**: ⭐⭐⭐⭐☆ (4/5 - Good with clear improvement path)
**Features**: 98% complete
- ✅ Calendar grid with ISO 8601 week numbers
- ✅ Daily notes with colors and symbols
- ✅ Swedish holidays with 20+ observances
- ✅ Custom countdown events
- ✅ Weather integration (WeatherKit)
- ✅ PDF export system
- ✅ Travel & expense tracking
- ✅ Widget extension (small/medium/large)
- ✅ Siri Shortcuts integration
- ⚠️ Minor polish items in REMAINING_ISSUES.md

**Known Opportunities:**
- ContentView is a simple pass-through wrapper (could be eliminated, but provides flexibility)
- Countdown models split across `CountdownEvent.swift`, `CountdownManager.swift`, `CountdownModels.swift`
- Services layer could benefit from protocol-based architecture for better testability
- See `REMAINING_ISSUES.md` for detailed list of deferred improvements

## References

- ISO 8601 Week Date: https://en.wikipedia.org/wiki/ISO_week_date
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- WidgetKit Documentation: https://developer.apple.com/documentation/widgetkit
- App Intents: https://developer.apple.com/documentation/appintents
- SwiftData: https://developer.apple.com/documentation/swiftdata
