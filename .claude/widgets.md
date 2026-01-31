# Widget Implementation

> **Last Updated:** 2026-01-31
> **Current widget architecture and implementation details**

---

## Overview

Onsen Planner provides **4 widget variants** following 情報デザイン principles:

| Widget | Size | Primary Purpose |
|--------|------|-----------------|
| **Small** | systemSmall | Week number hero display |
| **Medium** | systemMedium | World clock grid |
| **Large** | systemLarge | Full month calendar |
| **World Clock** | (Medium variant) | Multi-timezone display |

---

## Widget Files (12 total)

### Core

| File | Purpose |
|------|---------|
| `VeckaWidget.swift` | Entry point, widget configuration |
| `Provider.swift` | Timeline provider (VeckaWidgetProvider) |
| `Theme.swift` | Widget-specific theme (JohoWidget namespace) |

### Views

| File | Purpose |
|------|---------|
| `SmallWidgetView.swift` | Small widget - week number hero |
| `MediumWidgetView.swift` | Medium widget - week + mini calendar |
| `LargeWidgetView.swift` | Large widget - full month calendar |
| `WorldClockWidgetView.swift` | World clock grid display |

### Components

| File | Purpose |
|------|---------|
| `DayCell.swift` | Reusable day cell component |
| `BackgroundPattern.swift` | Background pattern options |

### Supporting

| File | Purpose |
|------|---------|
| `WidgetHolidayEngine.swift` | Lightweight holiday calculation |
| `WidgetRandomFact.swift` | Random fact for widgets |
| `SharedWorldClock.swift` | Shared world clock data |

---

## Widget Entry

```swift
struct VeckaWidgetEntry: TimelineEntry {
    let date: Date
    let weekNumber: Int
    let year: Int
    let holidays: [Holiday]
    let worldClocks: [WorldClock]
    let randomFact: String?
}
```

---

## Small Widget

**Purpose:** Hero week number display with today's date.

**Layout:**
```
┌─────────────────────┐
│    JAN 2026         │  ← Month/Year header
│                     │
│        2            │  ← Week number (hero size)
│       WEEK          │  ← Label
│                     │
│   (11) SUN          │  ← Today badge + weekday
└─────────────────────┘
```

**Key Features:**
- Week number as central hero element (56pt)
- Today highlighted with yellow circle
- Sunday/holidays shown in red
- Month/year in header

---

## Medium Widget

**Purpose:** World clock grid with local time context.

**Layout:**
```
┌────────────┬─────────────────────────┐
│   JAN      │    SE   │   JP   │  US  │
│   2026     │  Stock. │ Tokyo  │ NYC  │
│            │   🕐    │   🕐   │  🕐  │
│     2      │  14:44  │ 22:44  │08:44 │
│   WEEK     │  ☀ +8   │ 🌙 -1  │☀ -6  │
│   (11)     │         │        │      │
└────────────┴─────────────────────────┘
```

**Key Features:**
- Left panel: Week number + today
- Right panel: Up to 3 world clocks
- Analog clock faces (44pt)
- Day/night indicators
- UTC offset display

---

## Large Widget

**Purpose:** Full month calendar with week numbers.

**Layout:**
```
┌─────────────────────────────────────────┐
│  January 2026                      [W2] │
├─────────────────────────────────────────┤
│  W   M   T   W   T   F   S   S         │
│  1       1   2   3  ★4                  │
│  2   5   6★  7   8   9  10 (11)        │  ← Today circled
│  3  12  13  14  15  16  17  18         │
│  4  19  20  21  22  23  24  25         │
│  5  26  27  28  29  30  31             │
└─────────────────────────────────────────┘
```

**Key Features:**
- Week number column on left
- Current week badge in header
- Today highlighted with yellow
- Holiday stars (★)
- Sunday in red

---

## Theme (JohoWidget Namespace)

Widget-specific theme values:

```swift
enum JohoWidget {
    enum Colors {
        static let yellow = Color(hex: "FFE566")
        static let cyan = Color(hex: "A5F3FC")
        static let pink = Color(hex: "FECDD3")
        static let green = Color(hex: "4ADE80")
        // ...same as main app
    }

    enum Typography {
        static let weekNumberSmall = 56  // Small widget hero
        static let weekNumberMedium = 48 // Medium widget
        static let dayNumber = 14        // Calendar day
        // ...
    }

    enum CellSize {
        static let small = 18            // Small widget cells
        static let large = 26            // Large widget cells
    }
}
```

---

## Timeline Provider

```swift
struct VeckaWidgetProvider: TimelineProvider {
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<VeckaWidgetEntry>) -> Void) {
        // Update at midnight
        let midnight = Calendar.iso8601.startOfDay(for: Date())
            .addingTimeInterval(86400)

        let entry = VeckaWidgetEntry(
            date: Date(),
            weekNumber: currentWeek,
            year: currentYear,
            holidays: todayHolidays,
            worldClocks: configuredClocks,
            randomFact: randomFact
        )

        let timeline = Timeline(
            entries: [entry],
            policy: .after(midnight)
        )
        completion(timeline)
    }
}
```

---

## Deep Linking

Widgets support URL-based navigation:

| URL | Action |
|-----|--------|
| `vecka://today` | Open to current week |
| `vecka://week/{weekNumber}/{year}` | Open to specific week |
| `vecka://calendar` | Open calendar view |

---

## 情報デザイン Compliance

Widgets follow the same design principles as the main app:

### Required

- [x] Black borders on containers
- [x] White content backgrounds
- [x] Squircle corners (`.continuous`)
- [x] Rounded typography
- [x] Semantic colors only
- [x] Today in yellow

### Widget-Specific

- [x] Content visible at a glance
- [x] No interactivity beyond tap
- [x] Clear information hierarchy
- [x] Consistent with main app styling

---

## See Also

- `.claude/GOLDEN_STANDARD.md` — Color/component reference
- `.claude/design-system.md` — Visual specification
- `VeckaWidget/Theme.swift` — Widget theme source
