# Chapter 14: Calendar Design

> "A calendar is a year made visible."

---

The calendar is Onsen Planner's primary interface. It demonstrates how Joho Dezain handles dense, scannable information displays. Every decision—from cell size to color coding—serves rapid comprehension.

---

## Week Row Design

The fundamental unit is the week row. A full year is 52 or 53 week rows stacked vertically.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌────────┬───┬───┬───┬───┬───┬───┬───┬──────────────────┐  │
│  │        │ M │ T │ W │ T │ F │ S │ S │                  │  │
│  │ WK 42  ├───┼───┼───┼───┼───┼───┼───┤  Oct 14 - 20     │  │
│  │        │   │ ● │   │●● │   │   │ ● │                  │  │
│  └────────┴───┴───┴───┴───┴───┴───┴───┴──────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Anatomy of a Week Row

```swift
struct WeekRowView: View {
    let week: WeekData
    var isCurrentWeek: Bool = false
    var isExpanded: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // 1. Week number zone (fixed width)
            WeekNumberCell(
                number: week.number,
                isCurrent: isCurrentWeek
            )

            // 2. Day cells zone (7 equal columns)
            ForEach(week.days) { day in
                DayCell(
                    day: day,
                    isToday: day.isToday,
                    isSunday: day.isSunday
                )
            }

            // 3. Date range zone (fixed width)
            DateRangeCell(
                startDate: week.startDate,
                endDate: week.endDate
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

---

## Day Cell Design

Each day cell shows the day number and indicator dots for content.

### Cell States

```
┌───────────────────────────────────────────────────────────┐
│                                                           │
│   NORMAL          TODAY           SUNDAY        SELECTED  │
│                                                           │
│   ┌─────┐        ┌─────┐        ┌─────┐        ┌─────┐   │
│   │ 14  │        │ 15  │        │ 16  │        │ 17  │   │
│   │     │        │     │        │     │        │     │   │
│   │     │        │     │        │     │        │     │   │
│   └─────┘        └─────┘        └─────┘        └─────┘   │
│   White bg       Yellow bg      Red text       Yellow bg │
│   Black text     Black text     White bg       2.5pt     │
│   1pt border     1pt border     1pt border     border    │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct DayCell: View {
    let day: DayData
    var isToday: Bool = false
    var isSunday: Bool = false
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            // Day number
            Text(String(day.number))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(textColor)

            // Indicators (max 3)
            if !day.indicators.isEmpty {
                HStack(spacing: 1) {
                    ForEach(day.indicators.prefix(3), id: \.color) { indicator in
                        Circle()
                            .fill(indicator.color)
                            .frame(width: 5, height: 5)
                            .overlay(
                                Circle()
                                    .stroke(JohoColors.black, lineWidth: 0.5)
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoSpacing.sm)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(JohoColors.black, lineWidth: borderWidth)
        )
    }

    private var textColor: Color {
        isSunday ? JohoColors.red : JohoColors.black
    }

    private var backgroundColor: Color {
        if isToday { return JohoColors.yellow }
        if isSelected { return JohoColors.yellow.opacity(0.3) }
        return JohoColors.white
    }

    private var borderWidth: CGFloat {
        isSelected ? 2.5 : 1
    }
}
```

---

## Indicator Dots

Indicator dots are the Joho Dezain solution for showing content types without overwhelming the interface.

### Color Meanings

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ● Cyan #A5F3FC     Events (meetings, appointments)       │
│   ● Pink #FECDD3     Holidays (bank holidays, observances) │
│   ● Orange #FED7AA   Trips (travel, vacation)              │
│   ● Green #BBF7D0    Expenses (financial entries)          │
│   ● Purple #E9D5FF   Contacts (birthdays, anniversaries)   │
│   ● Yellow #FFE566   Notes (daily notes, reminders)        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct IndicatorDot: View {
    let color: Color
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(JohoColors.black, lineWidth: size > 6 ? 1.5 : 1)
            )
    }
}

// Size variants
enum IndicatorSize {
    case calendar  // 5pt - in calendar grid
    case collapsed // 6pt - in collapsed rows
    case expanded  // 8pt - in expanded content
    case legend    // 10pt - in legend/settings

    var diameter: CGFloat {
        switch self {
        case .calendar: return 5
        case .collapsed: return 6
        case .expanded: return 8
        case .legend: return 10
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .calendar, .collapsed: return 0.5
        case .expanded, .legend: return 1.5
        }
    }
}
```

**Critical Rule:** Every indicator dot MUST have a black border. Colored circles without borders break visual hierarchy.

---

## Expanded Week View

When a user taps a week row, it expands to show full content.

```
┌─────────────────────────────────────────────────────────────┐
│  WEEK 42                                                    │
│  October 14 - October 20, 2026                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  MONDAY 14                                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ● Team Standup                           9:00 AM    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  TUESDAY 15                                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ● Client Meeting                         2:00 PM    │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ● Project deadline                       5:00 PM    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  WEDNESDAY 16                                               │
│  No events                                                  │
│                                                             │
│  ...                                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct ExpandedWeekView: View {
    let week: WeekData
    @Binding var selectedDay: Int?

    var body: some View {
        JohoContainer {
            VStack(alignment: .leading, spacing: JohoSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                    Text("WEEK \(String(week.number))")
                        .font(.johoDisplayMedium)
                        .foregroundStyle(JohoColors.black)

                    Text(week.dateRangeString)
                        .font(.johoBodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Divider()
                    .background(JohoColors.black)

                // Days
                ForEach(week.days) { day in
                    DaySection(
                        day: day,
                        isSelected: selectedDay == day.number,
                        onTap: { selectedDay = day.number }
                    )
                }
            }
        }
    }
}

struct DaySection: View {
    let day: DayData
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: JohoSpacing.sm) {
            // Day header
            Button(action: onTap) {
                HStack {
                    Text(day.weekdayName.uppercased())
                        .font(.johoLabel)
                        .foregroundStyle(day.isSunday ? JohoColors.red : JohoColors.black)

                    Text(String(day.number))
                        .font(.johoLabel)
                        .foregroundStyle(day.isSunday ? JohoColors.red : JohoColors.black)

                    Spacer()

                    if day.isToday {
                        Text("TODAY")
                            .font(.johoLabel)
                            .foregroundStyle(JohoColors.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(JohoColors.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(JohoColors.black, lineWidth: 1.5)
                            )
                    }
                }
            }

            // Events for day
            if day.events.isEmpty {
                Text("No events")
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            } else {
                ForEach(day.events) { event in
                    EventRow(event: event)
                }
            }
        }
        .padding(.vertical, JohoSpacing.sm)
        .background(isSelected ? JohoColors.yellow.opacity(0.1) : Color.clear)
    }
}
```

---

## Year Overview

The year view shows all 52/53 weeks at once.

```
┌─────────────────────────────────────────────────────────────┐
│                         2026                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Q1                                                        │
│   WK 1  │░░░░░░░│░░░░░░░│░░░░░░░│  Jan 1 - 7               │
│   WK 2  │░░░░░░░│░░░░░░░│░░░░░░░│  Jan 8 - 14              │
│   ...                                                       │
│                                                             │
│   Q2                                                        │
│   WK 14 │░░░░░░░│░░░░░░░│░░░░░░░│  Apr 1 - 7               │
│   ...                                                       │
│                                                             │
│   Q3                                                        │
│   WK 27 │░░░░░░░│░░░░░░░│░░░░░░░│  Jul 1 - 7               │
│   ...                                                       │
│                                                             │
│   Q4                                                        │
│   WK 40 │░░░░░░░│░░░░░░░│░░░░░░░│  Oct 1 - 7               │
│   WK 41 │░░░░░░░│░░░░░░░│░░░░░░░│  Oct 8 - 14              │
│   WK 42 │███████│███████│███████│  Oct 15 - 21  ← Current   │
│   ...                                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct YearOverviewView: View {
    let year: Int
    @StateObject var holidayManager = HolidayManager.shared

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: JohoSpacing.sm) {
                    ForEach(quarters, id: \.number) { quarter in
                        QuarterSection(
                            quarter: quarter,
                            year: year
                        )
                    }
                }
                .padding(.horizontal, JohoSpacing.lg)
                .padding(.top, JohoSpacing.sm)
            }
            .onAppear {
                // Auto-scroll to current week
                proxy.scrollTo(currentWeekNumber, anchor: .center)
            }
        }
        .background(JohoColors.white)
    }

    private var quarters: [Quarter] {
        [
            Quarter(number: 1, weeks: 1...13),
            Quarter(number: 2, weeks: 14...26),
            Quarter(number: 3, weeks: 27...39),
            Quarter(number: 4, weeks: 40...52)
        ]
    }
}

struct QuarterSection: View {
    let quarter: Quarter
    let year: Int

    var body: some View {
        VStack(alignment: .leading, spacing: JohoSpacing.sm) {
            // Quarter header
            Text("Q\(quarter.number)")
                .font(.johoLabel)
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(JohoColors.black)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            // Weeks in quarter
            ForEach(Array(quarter.weeks), id: \.self) { weekNumber in
                CompactWeekRow(weekNumber: weekNumber, year: year)
                    .id(weekNumber)
            }
        }
    }
}
```

---

## Month Header Design

When scrolling through the calendar, month headers appear.

```
┌─────────────────────────────────────────────────────────────┐
│ ██████████████████████████████████████████████████████████ │
│ █                     OCTOBER 2026                       █ │
│ ██████████████████████████████████████████████████████████ │
│                                                             │
│  WK 40 │ M │ T │ W │ T │ F │ S │ S │  Sep 28 - Oct 4       │
│  ...                                                        │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct MonthHeader: View {
    let month: String
    let year: Int

    var body: some View {
        Text("\(month.uppercased()) \(String(year))")
            .font(.johoLabel)
            .foregroundStyle(JohoColors.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoSpacing.md)
            .background(JohoColors.black)
    }
}
```

---

## Holiday Row Design

Holidays have special treatment to make them scannable.

```
┌─────────────────────────────────────────────────────────────┐
│  ●  Christmas Day                               Dec 25  🔒  │
│     National holiday - Sweden, United States               │
└─────────────────────────────────────────────────────────────┘
```

### System vs. User Holidays

```swift
struct HolidayRow: View {
    let holiday: Holiday

    var body: some View {
        HStack(spacing: JohoSpacing.md) {
            // Indicator
            IndicatorDot(color: JohoColors.pink, size: 10)

            // Content
            VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                Text(holiday.name)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                Text(holiday.subtitle)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }

            Spacer()

            // Date
            Text(holiday.formattedDate)
                .font(.johoBodySmall)
                .foregroundStyle(JohoColors.black.opacity(0.6))

            // Lock icon for system holidays
            if holiday.isSystem {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            }
        }
        .padding(JohoSpacing.md)
        .background(JohoColors.pink.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

**Important:** System holidays (🔒) have no swipe actions. Users cannot edit or delete bank holidays.

---

## Calendar Accessibility

### VoiceOver

```swift
struct DayCell: View {
    // ...

    var body: some View {
        // ... visual content ...
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(day.events.isEmpty ? "No events" : "\(day.events.count) events")
    }

    private var accessibilityLabel: String {
        var label = "\(day.weekdayName) \(day.number)"
        if isToday { label += ", today" }
        if !day.indicators.isEmpty {
            label += ", has content"
        }
        return label
    }
}
```

### Dynamic Type

Calendar cells scale appropriately with Dynamic Type settings, though indicator dots maintain minimum sizes for visibility.

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           Joho Dezain CALENDAR REFERENCE                    │
│                                                             │
│   WEEK ROW ZONES:                                          │
│   1. Week number (fixed width)                             │
│   2. Day cells (7 equal columns)                           │
│   3. Date range (fixed width)                              │
│                                                             │
│   DAY CELL STATES:                                         │
│   • Normal: white bg, black text, 1pt border               │
│   • Today: yellow bg, black text, 1pt border               │
│   • Sunday: white bg, red text, 1pt border                 │
│   • Selected: yellow.opacity(0.3), 2.5pt border            │
│                                                             │
│   INDICATOR COLORS:                                        │
│   • Cyan: Events                                           │
│   • Pink: Holidays                                         │
│   • Orange: Trips                                          │
│   • Green: Expenses                                        │
│   • Purple: Contacts                                       │
│   • Yellow: Notes                                          │
│                                                             │
│   HOLIDAYS:                                                │
│   • System (🔒): No swipe actions                          │
│   • User: Swipe to edit/delete                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 15 — The "Star Page" Golden Standard*

