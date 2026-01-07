# Holiday Calculation System

> Database-driven holiday engine for WeekGrid

## Architecture Overview

The holiday system uses a **database-driven architecture** where all dates are calculated on-the-fly from stored rules. **Zero hardcoded dates** - the system stores calculation logic, not actual dates.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      HOLIDAY SYSTEM ARCHITECTURE                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────┐                                                  │
│  │    HolidayRule     │ ─── SwiftData Model (The "DNA")                  │
│  │                    │                                                  │
│  │  • name            │ ─── Localization key (holiday.midsommardagen)    │
│  │  • region          │ ─── "SE", "US", "VN", or "" (global)             │
│  │  • isRedDay        │ ─── true = public holiday, false = observance    │
│  │  • type            │ ─── Algorithm selector (see below)               │
│  │  • month           │ ─── Month (1-12)                                 │
│  │  • day             │ ─── Day (1-31)                                   │
│  │  • daysOffset      │ ─── Days from Easter (-2, 0, +39, +49)           │
│  │  • weekday         │ ─── 1=Sunday, 2=Monday... 7=Saturday             │
│  │  • ordinal         │ ─── 1=1st, 2=2nd, 3=3rd, 4=4th, -1=Last          │
│  │  • dayRangeStart   │ ─── Start of date range (e.g., 20)               │
│  │  • dayRangeEnd     │ ─── End of date range (e.g., 26)                 │
│  └────────────────────┘                                                  │
│           │                                                              │
│           ▼                                                              │
│  ┌────────────────────┐                                                  │
│  │   HolidayEngine    │ ─── Pure calculation logic (The "Brain")         │
│  │                    │                                                  │
│  │  calculateDate()   │ ─── Input: (Rule, Year) → Output: Date           │
│  │                    │                                                  │
│  │  Algorithms:       │                                                  │
│  │  • fixed()         │ ─── Same date every year                         │
│  │  • easterRelative()│ ─── Relative to Easter Sunday                    │
│  │  • floating()      │ ─── Weekday within date range                    │
│  │  • nthWeekday()    │ ─── Nth occurrence of weekday in month           │
│  │  • lunar()         │ ─── Lunar calendar conversion                    │
│  │  • astronomical()  │ ─── Solstices and equinoxes                      │
│  └────────────────────┘                                                  │
│           │                                                              │
│           ▼                                                              │
│  ┌────────────────────┐    ┌────────────────────┐                        │
│  │  HolidayManager    │───▶│   HolidayCache     │ ─── [Date: [Items]]    │
│  │   (Orchestrator)   │    │   (5-year window)  │                        │
│  └────────────────────┘    └────────────────────┘                        │
│                                     │                                    │
│                                     ▼                                    │
│                              ┌────────────┐                              │
│                              │     UI     │ ─── Calendar, Lists, Widgets │
│                              └────────────┘                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Holiday Rule Types (6 total)

### 1. Fixed (`HolidayRuleType.fixed`)

**Description:** Same date every year.

**Required Fields:**
- `month` (1-12)
- `day` (1-31)

**Algorithm:** Direct date construction.

```swift
// Example: Christmas Day - December 25
HolidayRule(
    name: "Christmas Day",
    region: "US",
    isRedDay: true,
    type: .fixed,
    month: 12,
    day: 25
)

// Calculation
DateComponents(year: year, month: 12, day: 25).date
```

**Swedish Examples:**
| Holiday | Month | Day |
|---------|-------|-----|
| Nyårsdagen | 1 | 1 |
| Trettondedag jul | 1 | 6 |
| Första maj | 5 | 1 |
| Sveriges nationaldag | 6 | 6 |
| Julafton | 12 | 24 |
| Juldagen | 12 | 25 |
| Annandag jul | 12 | 26 |
| Nyårsafton | 12 | 31 |

---

### 2. Easter Relative (`HolidayRuleType.easterRelative`)

**Description:** Calculated relative to Easter Sunday.

**Required Fields:**
- `daysOffset` (integer, can be negative)

**Algorithm:** Anonymous Gregorian Computus + offset.

```swift
// Example: Good Friday - 2 days before Easter
HolidayRule(
    name: "holiday.langfredagen",
    isRedDay: true,
    type: .easterRelative,
    daysOffset: -2
)

// Calculation
let easter = easterSunday(year: year)
calendar.date(byAdding: .day, value: -2, to: easter)
```

**Easter-relative holidays:**
| Holiday | Offset | Description |
|---------|--------|-------------|
| Långfredagen | -2 | Good Friday |
| Påskdagen | 0 | Easter Sunday |
| Annandag påsk | +1 | Easter Monday |
| Kristi himmelsfärdsdag | +39 | Ascension Day |
| Pingstdagen | +49 | Pentecost |

#### Easter Sunday Algorithm (Anonymous Gregorian Computus)

This algorithm computes Easter Sunday for any year between 1900-2099:

```swift
func easterSunday(year: Int) -> Date {
    let a = year % 19
    let b = year / 100
    let c = year % 100
    let d = b / 4
    let e = b % 4
    let f = (b + 8) / 25
    let g = (b - f + 1) / 3
    let h = (19 * a + b - d - g + 15) % 30
    let i = c / 4
    let k = c % 4
    let l = (32 + 2 * e + 2 * i - h - k) % 7
    let m = (a + 11 * h + 22 * l) / 451
    let month = (h + l - 7 * m + 114) / 31
    let day = ((h + l - 7 * m + 114) % 31) + 1

    return Calendar.iso8601.date(from: DateComponents(year: year, month: month, day: day))!
}
```

**Easter Sunday dates for reference:**
| Year | Date |
|------|------|
| 2024 | March 31 |
| 2025 | April 20 |
| 2026 | April 5 |
| 2027 | March 28 |
| 2028 | April 16 |

---

### 3. Floating (`HolidayRuleType.floating`)

**Description:** Specific weekday within a date range.

**Required Fields:**
- `month` (1-12)
- `weekday` (1=Sunday, 7=Saturday)
- `dayRangeStart` (e.g., 20)
- `dayRangeEnd` (e.g., 26)

**Algorithm:** Iterate through range, find first matching weekday.

```swift
// Example: Midsommardagen - Saturday between June 20-26
HolidayRule(
    name: "holiday.midsommardagen",
    isRedDay: true,
    type: .floating,
    month: 6,
    weekday: 7,        // Saturday
    dayRangeStart: 20,
    dayRangeEnd: 26
)

// Calculation
func findWeekday(_ weekday: Int, in year: Int, month: Int, range: ClosedRange<Int>) -> Date? {
    var currentDate = DateComponents(year: year, month: month, day: range.lowerBound).date!
    while calendar.component(.day, from: currentDate) <= range.upperBound {
        if calendar.component(.weekday, from: currentDate) == weekday {
            return currentDate
        }
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
    }
    return nil
}
```

**Swedish floating holidays:**
| Holiday | Month | Weekday | Range |
|---------|-------|---------|-------|
| Midsommardagen | 6 | Saturday (7) | 20-26 |
| Midsommarafton | 6 | Friday (6) | 19-25 |

---

### 4. Nth Weekday (`HolidayRuleType.nthWeekday`)

**Description:** The Nth occurrence of a weekday in a month.

**Required Fields:**
- `month` (1-12)
- `weekday` (1=Sunday, 7=Saturday)
- `ordinal` (1, 2, 3, 4, or -1 for last)

**Algorithm:** Count weekday occurrences from start (or end for -1).

```swift
// Example: Mother's Day - Last Sunday in May
HolidayRule(
    name: "holiday.mors_dag",
    isRedDay: false,
    type: .nthWeekday,
    month: 5,
    weekday: 1,     // Sunday
    ordinal: -1     // Last
)

// Example: Father's Day - 2nd Sunday in November
HolidayRule(
    name: "holiday.fars_dag",
    isRedDay: false,
    type: .nthWeekday,
    month: 11,
    weekday: 1,     // Sunday
    ordinal: 2      // 2nd
)

// Calculation for ordinal = -1 (last)
func findLastWeekday(_ weekday: Int, in year: Int, month: Int) -> Date? {
    let endOfMonth = DateComponents(year: year, month: month + 1, day: 0).date!
    var currentDate = endOfMonth
    for _ in 0..<7 {
        if calendar.component(.weekday, from: currentDate) == weekday {
            return currentDate
        }
        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
    }
    return nil
}

// Calculation for ordinal = N (1st, 2nd, 3rd, 4th)
func findNthWeekday(_ ordinal: Int, weekday: Int, in year: Int, month: Int) -> Date? {
    var currentDate = DateComponents(year: year, month: month, day: 1).date!
    var count = 0
    while calendar.component(.month, from: currentDate) == month {
        if calendar.component(.weekday, from: currentDate) == weekday {
            count += 1
            if count == ordinal {
                return currentDate
            }
        }
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
    }
    return nil
}
```

**Nth Weekday holidays:**
| Holiday | Region | Month | Weekday | Ordinal |
|---------|--------|-------|---------|---------|
| Mors dag (SE) | SE | 5 | Sunday | -1 (last) |
| Fars dag (SE) | SE | 11 | Sunday | 2 |
| Mother's Day (US) | US | 5 | Sunday | 2 |
| Father's Day (US) | US | 6 | Sunday | 3 |
| MLK Day | US | 1 | Monday | 3 |
| Presidents' Day | US | 2 | Monday | 3 |
| Memorial Day | US | 5 | Monday | -1 (last) |
| Labor Day | US | 9 | Monday | 1 |
| Columbus Day | US | 10 | Monday | 2 |
| Thanksgiving | US | 11 | Thursday | 4 |
| Alla helgons dag | SE | 11 | Saturday | 1 |

---

### 5. Lunar (`HolidayRuleType.lunar`)

**Description:** Lunar calendar date converted to Gregorian.

**Required Fields:**
- `month` (lunar month, 1-12)
- `day` (lunar day, 1-30)

**Algorithm:** Uses iOS Calendar(identifier: .chinese) for conversion.

```swift
// Example: Tet (Vietnamese New Year) - 1st day of 1st Lunar Month
HolidayRule(
    name: "Tết Nguyên Đán",
    region: "VN",
    isRedDay: true,
    type: .lunar,
    month: 1,
    day: 1
)

// Calculation
func calculateLunarDate(month: Int, day: Int, inGregorianYear year: Int) -> Date? {
    let chinese = Calendar(identifier: .chinese)

    // Find Chinese year overlapping Gregorian year
    let midYear = DateComponents(year: year, month: 6, day: 15).date!
    let chineseYear = chinese.component(.year, from: midYear)

    // Convert lunar date to Gregorian
    var targetComps = DateComponents()
    targetComps.year = chineseYear
    targetComps.month = month
    targetComps.day = day

    return chinese.date(from: targetComps)
}
```

**Vietnamese lunar holidays:**
| Holiday | Lunar Month | Lunar Day |
|---------|-------------|-----------|
| Tết Nguyên Đán | 1 | 1 |
| Giỗ Tổ Hùng Vương | 3 | 10 |
| Tết Trung Thu | 8 | 15 |

---

### 6. Astronomical (`HolidayRuleType.astronomical`)

**Description:** Solstices and equinoxes calculated from orbital mechanics.

**Required Fields:**
- `month` (3, 6, 9, or 12 - identifies which event)

**Algorithm:** Simplified Meeus formula (accurate to the day).

```swift
// Example: Summer Solstice
HolidayRule(
    name: "holiday.sommarsolstand",
    isRedDay: false,
    type: .astronomical,
    month: 6
)

// Calculation (Simplified Meeus Algorithm)
func calculateAstronomicalDate(month: Int, year: Int) -> Date? {
    let Y = Double(year - 2000)
    var day: Double = 0.0

    switch month {
    case 3:  // Spring Equinox
        day = 20.2088 + 0.2422 * Y - floor(Y / 4.0)
    case 6:  // Summer Solstice
        day = 20.9126 + 0.2422 * Y - floor(Y / 4.0)
    case 9:  // Autumn Equinox
        day = 22.5444 + 0.2422 * Y - floor(Y / 4.0)
    case 12: // Winter Solstice
        day = 21.4800 + 0.2422 * Y - floor(Y / 4.0)
    default:
        return nil
    }

    return DateComponents(year: year, month: month, day: Int(day)).date
}
```

**Astronomical events:**
| Event | Month | Typical Date Range |
|-------|-------|-------------------|
| Vårdagjämning (Spring Equinox) | 3 | March 19-21 |
| Sommarsolstånd (Summer Solstice) | 6 | June 20-22 |
| Höstdagjämning (Autumn Equinox) | 9 | September 22-24 |
| Vintersolstånd (Winter Solstice) | 12 | December 20-22 |

---

## Validation Rules

Each rule type requires specific fields. The system validates on creation:

| Type | Required Fields | Valid Ranges |
|------|-----------------|--------------|
| `fixed` | month, day | month: 1-12, day: 1-31 |
| `easterRelative` | daysOffset | any integer |
| `floating` | month, weekday, dayRangeStart, dayRangeEnd | weekday: 1-7, start <= end |
| `nthWeekday` | month, weekday, ordinal | ordinal: 1-4 or -1 |
| `lunar` | month, day | lunar month: 1-12, day: 1-30 |
| `astronomical` | month | must be 3, 6, 9, or 12 |

---

## Supported Regions

| Code | Country | Bank Holidays | Observances |
|------|---------|---------------|-------------|
| SE | Sweden | 12 | 8 |
| US | United States | 11 | 5 |
| VN | Vietnam | 6 | 1 |

**Max selectable regions:** 2 (user can choose up to 2 regions)

---

## Cache System

The HolidayManager maintains a 5-year cache window:
- Current year
- 2 years before
- 2 years after

Cache is invalidated when:
- User changes selected regions
- User toggles "Show Holidays" setting
- App navigates to a year outside the current cache window

---

## User Modifications

Users can:
1. **Add custom rules** - Creates new HolidayRule with `userModifiedAt` timestamp
2. **Edit existing rules** - Sets `titleOverride`, `symbolName`, `iconColor`, `notes`
3. **Delete custom rules** - Only rules with `userModifiedAt` can be deleted

System rules (seeded on app launch) are **protected** from deletion but can be customized.

---

## File Locations

| File | Purpose |
|------|---------|
| `Vecka/Models/HolidayRule.swift` | SwiftData model (the "DNA") |
| `Vecka/Models/HolidayEngine.swift` | Calculation algorithms (the "Brain") |
| `Vecka/Models/HolidayManager.swift` | Orchestrator and cache |

---

## Adding New Holiday Types

To add a new calculation type:

1. Add case to `HolidayRuleType` enum in `HolidayRule.swift`
2. Add required fields to `HolidayRule` model
3. Implement algorithm in `HolidayEngine.calculateDate()`
4. Add validation in `HolidayRule.validationError`
5. Seed initial rules in `HolidayManager.seedSwedishRules()`

---

## Weekday Reference

| Value | Day |
|-------|-----|
| 1 | Sunday |
| 2 | Monday |
| 3 | Tuesday |
| 4 | Wednesday |
| 5 | Thursday |
| 6 | Friday |
| 7 | Saturday |

This follows the iOS Calendar convention where Sunday = 1.
