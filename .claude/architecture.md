# Onsen Planner Architecture

> **Last Updated:** 2026-01-31
> Reference this file when adding features, understanding code structure, or modifying data flow.

## Multi-Target Structure

| Target | Description | iOS Version |
|--------|-------------|-------------|
| **Vecka** | Main app | iOS 18.0+ |
| **VeckaWidgetExtension** | Widget (S/M/L) | iOS 18.0+ |
| **VeckaTests** | Unit tests | - |
| **VeckaUITests** | UI automation | - |

**Code Sharing:** Files shared between app and widget via Target Membership in Xcode.

---

## Architecture Pattern: Manager + Model + View

```
User Action → View
           ↓
     Manager.shared (cache check)
           ↓
     SwiftData Query / Engine Calculation
           ↓
     Cache Update → View Update
```

### Layer Overview

**1. Core Calculator** (`Vecka/Core/`)
- `WeekCalculator`: Thread-safe ISO 8601 week calculation with caching

**2. Models** (`Vecka/Models/`)
- SwiftData: `HolidayRule`, `CalendarRule`, `CountdownEvent`, `DailyNote`
- Pure Swift: `Holiday`, `CalendarModels`

**3. Managers** (Singleton Pattern)
- `HolidayManager`: Holiday calculation and caching
- `CalendarManager`: Calendar rule management
- `CountdownManager`: Countdown event management

**4. Engine** (`Vecka/Models/HolidayEngine.swift`)
- Easter calculations, floating weekday finder, lunar calendar conversion

**5. Views** (`Vecka/Views/`)
- `ModernCalendarView`: Main calendar UI
- `AppSidebar`: iPad NavigationSplitView sidebar
- `PhoneLibraryView`: iPhone TabView library

**6. Services** (`Vecka/Services/`)
- Weather, Travel & Expenses, PDF Export, Currency

---

## File Organization

```
Vecka/
├── Core/                    # Week calculation logic
├── Models/                  # SwiftData models, structs
├── Views/                   # SwiftUI views
├── Services/                # External integrations
├── Intents/                 # Siri Shortcuts
├── JohoDesignSystem.swift   # Design system components
└── Localization.swift       # i18n strings
```

---

## SwiftData Models

```swift
.modelContainer(for: [
    DailyNote.self,
    HolidayRule.self,
    CalendarRule.self,
    CountdownEvent.self,
    ExpenseCategory.self,
    ExpenseTemplate.self,
    ExpenseItem.self,
    TravelTrip.self,
    MileageEntry.self,
    ExchangeRate.self,
    SavedLocation.self
])
```

---

## ISO 8601 Calendar Configuration

```swift
var calendar = Calendar(identifier: .gregorian)
calendar.firstWeekday = 2           // Monday
calendar.minimumDaysInFirstWeek = 4 // ISO 8601 standard
calendar.locale = Locale(identifier: "sv_SE")
```

---

## Holiday Calculation System

**Six Rule Types** (see `HolidayRuleType`):
1. `fixed` — Fixed date (e.g., Dec 25)
2. `easterRelative` — Days from Easter Sunday (e.g., Good Friday = -2)
3. `floating` — Weekday within date range (e.g., Midsummer = Sat in Jun 20-26)
4. `nthWeekday` — Nth weekday of month (e.g., Thanksgiving = 4th Thu in Nov)
5. `lunar` — Lunar calendar date (e.g., Tết = 1st day of 1st lunar month)
6. `astronomical` — Equinoxes/solstices (e.g., 春分の日)

**Supported Regions (16 Countries):**

| Region | Countries |
|--------|-----------|
| Nordic | SE, NO, DK, FI, IS |
| Europe | DE, GB, FR, IT, NL |
| Asia | JP, CN, HK, TH, VN |
| Americas | US |

Maximum 2 regions selectable (enforced by `HolidayRegionSelection`).

**Adding Holidays:** Add `HolidayRule` entries in `HolidayManager.seedSwedishRules()`.

---

## Widget Implementation

### Architecture
- **Provider**: Timeline provider with EventKit integration
- **Views**: `SmallWidgetView`, `MediumWidgetView`, `LargeWidgetView`
- **Theme**: 情報デザイン styling

### Sizes
- **Small**: Week number with semantic color
- **Medium**: Week number + date range + countdown
- **Large**: Full 7-day calendar with events

### Deep Linking
- `vecka://today` → Current week
- `vecka://week/{weekNumber}/{year}` → Specific week
- `vecka://calendar` → Calendar view

---

## Siri Shortcuts

| Intent | Phrase |
|--------|--------|
| `CurrentWeekIntent` | "What week is it?" |
| `WeekOverviewIntent` | "Show week overview" |
| `WeekForDateIntent` | Get week for specific date |

---

## Bundle Identifiers

| Target | Identifier |
|--------|------------|
| Main App | `Johansson.Vecka` |
| Widget | `Johansson.Vecka.VeckaWidget` |

**App Store Name:** Onsen Planner

---

## Localization

- **Primary:** Swedish (sv_SE)
- **Secondary:** English, Japanese, Korean, German, Vietnamese, Thai, Chinese

Use `Localization` struct for all user-facing strings.

---

## Common Tasks

### Adding a New View

1. Create file in `Vecka/Views/`
2. Use `JohoColors` for all colors
3. Ensure all containers have borders
4. Use `.design(.rounded)` for fonts
5. Add to widget target if needed

### Adding a Holiday

```swift
let holiday = HolidayRule(
    id: "unique-id",
    name: "Holiday Name",
    localizedName: ["en": "English", "sv": "Svenska"],
    type: .fixed,
    month: 12, day: 25,
    regionCode: "SE"
)
context.insert(holiday)
```

### Adding a SwiftData Model

1. Create `@Model` class in `Vecka/Models/`
2. Add to `.modelContainer(for: [...])` in app entry
3. If widget needs it, add to both targets

---

## Data Export System

### Exportable Data Types

All data logged to calendar days must be exportable. The `EntryType` enum defines the 6 entry types:

| Entry Type | SwiftData Model | Key Fields | Export Formats |
|------------|-----------------|------------|----------------|
| **Note** | `DailyNote` | content, color, priority, symbol, scheduledAt, duration | PDF |
| **Expense** | `ExpenseItem` | amount, currency, category, merchant, description, isReimbursable | PDF, CSV |
| **Trip** | `TravelTrip` | tripName, destination, purpose, tripType, startDate, endDate | PDF |
| **Holiday** | `HolidayRule` | name, region, isBankHoliday, type, localName | PDF |
| **Event** | `CountdownEvent` | title, targetDate, icon, colorHex | PDF |
| **Birthday** | `Contact.birthday` | givenName, familyName, birthday | PDF, VCF |
| **Mileage** | `MileageEntry` | distance, startLocation, endLocation, purpose, date | PDF, CSV |

### Export Services

| Service | Location | Output |
|---------|----------|--------|
| `SimplePDFExportService` | `Services/SimplePDFRenderer.swift` | PDF (day/week/month) |
| `PDFExportService` | `Services/PDFExportService.swift` | PDF (detailed reports) |
| `ContactExportService` | `Services/ContactExportService.swift` | PDF (contact directory) |
| `CSVExportService` | `Services/CSVExportService.swift` | CSV (expenses, mileage) |

### Export Entry Points

| View | Export Button | Formats |
|------|---------------|---------|
| Calendar Page Header | Export menu (day/week/month) | PDF |
| Contacts List Header | Export button | PDF, VCF |
| Expenses List | Menu → Export | PDF, CSV |
| Contact Detail | Share button | VCF, QR PNG |

### Adding New Export Format

1. Create export service in `Vecka/Services/`
2. Add export option to relevant view
3. Use `ShareSheet` for iOS share functionality
4. Update this documentation

---

## Debugging Tips

### Week Calculation Issues
- Verify `Calendar.iso8601` configuration
- Check cache invalidation in `WeekCalculator`

### Widget Not Updating
- Verify timeline provider midnight calculation
- Check widget URL scheme handling

### Design System Issues
- Run audit commands (see `.claude/design-system.md`)
- Check `JohoDesignSystem.swift` for component usage

---

## See Also

- `.claude/GOLDEN_STANDARD.md` — Authoritative design reference
- `.claude/FILE_REGISTRY.md` — Complete file inventory
- `.claude/widgets.md` — Widget implementation
- `.claude/design-system.md` — Visual specification
