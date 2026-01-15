# Chapter 12: Data Display

> "Numbers are data. Tables are stories. Calendars are maps."

---

Data display is the heart of Joho Dezain. Information-dense interfaces require careful attention to how numbers, dates, lists, and tables present their content. Every display pattern follows consistent rules for clarity and quick comprehension.

---

## Calendar Grid

The calendar grid is a core Joho Dezain pattern—a dense, scannable display of temporal data.

```
┌─────────────────────────────────────────────────────────────┐
│  M   │  T   │  W   │  T   │  F   │  S   │  S   │           │
├──────┼──────┼──────┼──────┼──────┼──────┼──────┤           │
│  1   │  2   │  3   │  4   │  5   │  6   │  7   │  Week 1   │
│  ●   │      │  ●●  │      │      │      │  ●   │           │
├──────┼──────┼──────┼──────┼──────┼──────┼──────┤           │
│  8   │  9   │ 10   │ 11   │ 12   │ 13   │ 14   │  Week 2   │
│      │  ●   │      │      │  ●   │      │      │           │
└──────┴──────┴──────┴──────┴──────┴──────┴──────┘           │
```

### Day Cell Implementation

```swift
struct JohoDayCell: View {
    let day: Int
    let indicators: [Color]
    var isToday: Bool = false
    var isSunday: Bool = false
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: JohoSpacing.xs) {
            // Day number
            Text(String(day))
                .font(.johoBody)
                .monospacedDigit()
                .foregroundStyle(dayColor)

            // Indicator dots
            if !indicators.isEmpty {
                HStack(spacing: 2) {
                    ForEach(indicators.prefix(3), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoSpacing.sm)
        .background(cellBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(JohoColors.black, lineWidth: isSelected ? 2.5 : 1)
        )
    }

    private var dayColor: Color {
        if isSunday { return JohoColors.red }
        return JohoColors.black
    }

    private var cellBackground: Color {
        if isToday { return JohoColors.yellow }
        if isSelected { return JohoColors.yellow.opacity(0.3) }
        return JohoColors.white
    }
}
```

### Calendar Grid Implementation

```swift
struct JohoCalendarGrid: View {
    let weeks: [[DayData]]
    @Binding var selectedDay: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: JohoSpacing.xs), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            // Day headers
            HStack(spacing: JohoSpacing.xs) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.johoLabel)
                        .foregroundStyle(day == "S" ? JohoColors.red : JohoColors.black)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, JohoSpacing.sm)
            .background(JohoColors.black)
            .foregroundStyle(JohoColors.white)

            // Day grid
            LazyVGrid(columns: columns, spacing: JohoSpacing.xs) {
                ForEach(weeks.flatMap { $0 }) { day in
                    JohoDayCell(
                        day: day.number,
                        indicators: day.indicators,
                        isToday: day.isToday,
                        isSunday: day.isSunday,
                        isSelected: selectedDay == day.number
                    )
                    .onTapGesture { selectedDay = day.number }
                }
            }
            .padding(JohoSpacing.xs)
        }
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

**Calendar Grid Rules:**
- Day headers on black background
- Sunday column in red
- Today highlighted in yellow
- Indicator dots show content types
- 1pt cell borders, 3pt outer border

---

## Week Row

A compact horizontal representation of a week.

```
┌─────────────────────────────────────────────────────────────┐
│ WK 42 │ M │ T │ W │ T │ F │ S │ S │  Oct 14 - Oct 20       │
│       │ ● │   │●● │   │   │   │ ● │                         │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoWeekRow: View {
    let weekNumber: Int
    let days: [DayData]
    let dateRange: String
    var isCurrentWeek: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Week number
            Text("WK \(weekNumber)")
                .font(.johoLabel)
                .monospacedDigit()
                .foregroundStyle(JohoColors.white)
                .frame(width: 56)
                .padding(.vertical, JohoSpacing.md)
                .background(isCurrentWeek ? JohoColors.yellow : JohoColors.black)
                .foregroundStyle(isCurrentWeek ? JohoColors.black : JohoColors.white)

            // Day cells
            ForEach(days) { day in
                VStack(spacing: 2) {
                    Text(day.initial)
                        .font(.johoLabelSmall)
                        .foregroundStyle(day.isSunday ? JohoColors.red : JohoColors.black.opacity(0.6))

                    HStack(spacing: 1) {
                        ForEach(day.indicators.prefix(2), id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 5, height: 5)
                                .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, JohoSpacing.sm)
                .background(day.isToday ? JohoColors.yellow : JohoColors.white)
                .overlay(
                    Rectangle()
                        .stroke(JohoColors.black, lineWidth: 1)
                )
            }

            // Date range
            Text(dateRange)
                .font(.johoBodySmall)
                .foregroundStyle(JohoColors.black.opacity(0.6))
                .frame(width: 120)
                .padding(.horizontal, JohoSpacing.sm)
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

## Data Tables

Tables for structured data follow clear alignment rules.

```
┌─────────────────────────────────────────────────────────────┐
│  NAME               │  TYPE      │  DATE         │  AMOUNT │
├─────────────────────┼────────────┼───────────────┼─────────┤
│  Groceries          │  Expense   │  Oct 14       │  $45.00 │
├─────────────────────┼────────────┼───────────────┼─────────┤
│  Client Meeting     │  Event     │  Oct 15       │  -      │
├─────────────────────┼────────────┼───────────────┼─────────┤
│  Flight to NYC      │  Trip      │  Oct 20       │ $320.00 │
└─────────────────────┴────────────┴───────────────┴─────────┘
```

### Implementation

```swift
struct JohoDataTable<Item: Identifiable>: View {
    let columns: [TableColumn<Item>]
    let items: [Item]

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(columns) { column in
                    Text(column.title.uppercased())
                        .font(.johoLabel)
                        .foregroundStyle(JohoColors.white)
                        .frame(width: column.width, alignment: column.alignment)
                        .padding(.vertical, JohoSpacing.md)
                        .padding(.horizontal, JohoSpacing.sm)
                }
            }
            .background(JohoColors.black)

            // Data rows
            ForEach(items) { item in
                HStack(spacing: 0) {
                    ForEach(columns) { column in
                        column.content(item)
                            .font(.johoBody)
                            .foregroundStyle(JohoColors.black)
                            .frame(width: column.width, alignment: column.alignment)
                            .padding(.vertical, JohoSpacing.md)
                            .padding(.horizontal, JohoSpacing.sm)
                    }
                }
                .background(JohoColors.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(JohoColors.black),
                    alignment: .bottom
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 2)
        )
    }
}

struct TableColumn<Item>: Identifiable {
    let id = UUID()
    let title: String
    let width: CGFloat?
    let alignment: Alignment
    let content: (Item) -> AnyView
}
```

**Table Rules:**
- Header row on black background
- Column headers uppercase
- Text columns left-aligned
- Number columns right-aligned
- Monospaced digits for all numbers
- 1pt row separators
- 2pt outer border

---

## Statistics Cards

Display key metrics prominently.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  │
│   │               │  │               │  │               │  │
│   │     127       │  │      8        │  │    $2,340     │  │
│   │               │  │               │  │               │  │
│   │   EVENTS      │  │   HOLIDAYS    │  │   EXPENSES    │  │
│   │               │  │               │  │               │  │
│   └───────────────┘  └───────────────┘  └───────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoStatCard: View {
    let value: String
    let label: String
    var accentColor: Color = JohoColors.white

    var body: some View {
        VStack(spacing: JohoSpacing.sm) {
            Text(value)
                .font(.johoDisplayMedium)
                .monospacedDigit()
                .foregroundStyle(JohoColors.black)

            Text(label.uppercased())
                .font(.johoLabel)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoSpacing.xl)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 2)
        )
    }
}

// Usage
HStack(spacing: JohoSpacing.sm) {
    JohoStatCard(value: "127", label: "Events", accentColor: JohoColors.cyan)
    JohoStatCard(value: "8", label: "Holidays", accentColor: JohoColors.pink)
    JohoStatCard(value: "$2,340", label: "Expenses", accentColor: JohoColors.green)
}
```

---

## List Rows

Standard rows for displaying items in a list.

```
┌─────────────────────────────────────────────────────────────┐
│  ●  Team Meeting                               9:00 AM  >  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  ●  Christmas Day                              Dec 25   🔒  │
│     National holiday                                       │
└─────────────────────────────────────────────────────────────┘
```

### Basic Row

```swift
struct JohoListRow: View {
    let title: String
    let subtitle: String?
    let indicatorColor: Color?
    let trailing: String?
    var showChevron: Bool = true
    var isLocked: Bool = false

    var body: some View {
        HStack(spacing: JohoSpacing.md) {
            // Indicator
            if let color = indicatorColor {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
            }

            // Content
            VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                Text(title)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.johoBodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }

            Spacer()

            // Trailing
            if let trailing = trailing {
                Text(trailing)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }

            // Lock or chevron
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            }
        }
        .padding(JohoSpacing.md)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

---

## Progress Indicators

Show progress through a process or timeline.

### Linear Progress

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░  42%    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoProgressBar: View {
    let progress: Double  // 0.0 to 1.0
    var accentColor: Color = JohoColors.cyan

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(JohoColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(JohoColors.black, lineWidth: 2)
                    )

                // Fill
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * progress)
                    .padding(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(JohoColors.black, lineWidth: 1)
                            .padding(2)
                    )
            }
        }
        .frame(height: 24)
    }
}
```

### Step Progress

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│     ●────────●────────○────────○────────○                  │
│     1        2        3        4        5                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoStepProgress: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...totalSteps, id: \.self) { step in
                // Step circle
                Circle()
                    .fill(step <= currentStep ? JohoColors.black : JohoColors.white)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(JohoColors.black, lineWidth: 2)
                    )

                // Connector line (not after last step)
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? JohoColors.black : JohoColors.black.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
    }
}
```

---

## Number Formatting

Numbers must be formatted consistently throughout.

### Currency

```swift
extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    static var joho: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: Locale.current.currency?.identifier ?? "USD")
    }
}

// Usage
Text(amount, format: .joho)
    .font(.johoBody)
    .monospacedDigit()
```

### Dates

```swift
struct JohoDateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// Usage
Text(JohoDateFormatter.shortDate.string(from: date))
```

### Week Numbers

```swift
// Always use String() for week numbers to avoid locale formatting
Text("Week \(String(weekNumber))")
    .font(.johoHeadline)
    .monospacedDigit()
```

---

## Empty States

When data is empty, show meaningful empty states.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                         📅                                  │
│                                                             │
│                   No Events Today                          │
│                                                             │
│           Tap + to add your first event                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoEmptyDataState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: JohoSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(JohoColors.black.opacity(0.3))

            VStack(spacing: JohoSpacing.sm) {
                Text(title)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                Text(message)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                JohoButton(title: actionTitle, action: action, style: .primary)
            }
        }
        .padding(JohoSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

---

## Loading States

Show loading states with clear indicators.

```swift
struct JohoLoadingState: View {
    let message: String

    var body: some View {
        VStack(spacing: JohoSpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: JohoColors.black))
                .scaleEffect(1.5)

            Text(message)
                .font(.johoBodySmall)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .padding(JohoSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           Joho Dezain DATA DISPLAY REFERENCE                │
│                                                             │
│   CALENDARS:                                               │
│   • Sunday column red                                      │
│   • Today yellow background                                │
│   • Indicator dots show content types                      │
│   • 1pt cell borders, 3pt outer                           │
│                                                             │
│   TABLES:                                                  │
│   • Header on black background                             │
│   • Column headers uppercase                               │
│   • Text left-aligned, numbers right-aligned              │
│   • Monospaced digits always                              │
│                                                             │
│   FORMATTING:                                              │
│   • Use String(number) not "\(number)"                     │
│   • Currency: .currency(code:)                            │
│   • Always .monospacedDigit()                             │
│                                                             │
│   STATES:                                                  │
│   • Empty: icon + title + message                         │
│   • Loading: spinner + message                            │
│   • All states have 3pt borders                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Part 4 — Case Study: Onsen Planner*

