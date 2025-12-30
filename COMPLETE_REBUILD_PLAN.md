# Vecka - Complete Production App Rebuild Plan

## Vision
A **professional, production-quality iOS/iPadOS calendar app** focused on ISO 8601 week numbers, fully integrated with the Apple ecosystem.

## Core Features

### 1. Week Number Display (Primary Feature)
- **Always visible** ISO 8601 week number
- Works in **all contexts**: portrait, landscape, widgets, Siri
- Beautiful, accessible design following Apple HIG

### 2. Full Calendar Integration
- Visual month calendar with week numbers
- Week-at-a-glance view
- Quick date navigation
- Holiday markers (Swedish + customizable)

### 3. Apple Ecosystem Integration

#### Siri & Shortcuts
- "Hey Siri, what week is it?" → "It's week 48"
- "Hey Siri, what week is December 25th?"
- Custom shortcuts for week queries
- App Intents (iOS 16+) for enhanced Siri

#### Widgets
- **Small**: Week number only
- **Medium**: Week number + current week calendar
- **Large**: Month view with week numbers
- **Lock Screen**: Week number widget (iOS 16+)
- **StandBy**: Large week number display

#### Live Activities (iOS 16.1+)
- Week countdown on Dynamic Island
- Live updates for week changes

### 4. Charts & Visualizations
Following Apple Charts HIG:
- **Week Progress Chart**: Visual bar showing progress through current week
- **Month Progress Chart**: Ring/arc showing month completion
- **Year Overview**: Heat map of weeks throughout the year
- **Accessibility**: Full Audio Graphs support

### 5. Data & Persistence
- CloudKit sync across devices
- Custom events/notes per week
- Week favorites/bookmarks
- Export capabilities (Calendar, PDF)

## Technical Architecture

### App Structure
```
Vecka/
├── App/
│   ├── VeckaApp.swift
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Core/
│   ├── Models/
│   │   ├── WeekData.swift
│   │   ├── CalendarEvent.swift
│   │   └── UserPreferences.swift
│   ├── Services/
│   │   ├── WeekCalculator.swift
│   │   ├── CalendarService.swift
│   │   ├── CloudKitService.swift
│   │   └── NotificationService.swift
│   └── Utilities/
│       ├── ISO8601Calendar.swift
│       └── Formatters.swift
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   ├── Calendar/
│   │   ├── MonthCalendarView.swift
│   │   ├── WeekView.swift
│   │   └── CalendarViewModel.swift
│   ├── Charts/
│   │   ├── WeekProgressChart.swift
│   │   ├── MonthProgressChart.swift
│   │   └── YearHeatMap.swift
│   └── Settings/
│       └── SettingsView.swift
├── Widgets/
│   ├── VeckaWidget.swift
│   ├── LockScreenWidget.swift
│   └── StandByWidget.swift
├── Intents/
│   ├── WeekNumberIntent.swift
│   ├── DateToWeekIntent.swift
│   └── IntentHandler.swift
└── DesignSystem/
    ├── Colors.swift
    ├── Typography.swift
    ├── Components/
    └── Layouts/
```

### Key Technologies

1. **SwiftUI** - Modern, declarative UI
2. **Swift Charts** - Data visualization with accessibility
3. **App Intents** - Siri integration (iOS 16+)
4. **WidgetKit** - Home screen, Lock Screen, StandBy widgets
5. **CloudKit** - Cross-device sync
6. **Combine** - Reactive data flow
7. **SwiftData** - Local persistence (iOS 17+)
8. **EventKit** - Calendar integration

## User Experience Flows

### Flow 1: Quick Week Check
```
Launch App → See Week Number immediately
      ↓
Glance at week progress chart
      ↓
Done (< 2 seconds)
```

### Flow 2: Siri Query
```
"Hey Siri, what week is it?"
      ↓
Siri: "It's week 48 of 2025"
      ↓
[Optional] Tap to open app
```

### Flow 3: Widget Glance
```
Look at home screen widget
      ↓
See week number + current day highlighted
      ↓
Tap to see full month (optional)
```

### Flow 4: Planning/Navigation
```
Open app → See current week
      ↓
Swipe to view month calendar
      ↓
Tap any date → See week number
      ↓
Add note/event to week
```

## Design System (HIG-Compliant)

### Visual Hierarchy
1. **Primary**: Week number (largest, bold)
2. **Secondary**: Current date, month name
3. **Tertiary**: Calendar grid, charts
4. **Utility**: Settings, navigation

### Color Strategy
- **Dynamic Colors**: Adapt to light/dark mode
- **Week Colors**: Optional planetary color system (current)
- **Accent**: System blue for interactive elements
- **Semantic**: Red for holidays, blue for today

### Typography Scale
```swift
.weekNumberDisplay: 120pt, bold, rounded (hero)
.weekLabel: 14pt, semibold, uppercase
.dateDisplay: 24pt, semibold
.body: 17pt, regular
.caption: 13pt, regular
```

### Spacing (8pt Grid)
```swift
.micro: 4pt
.small: 8pt
.medium: 16pt
.large: 24pt
.xlarge: 32pt
.xxlarge: 48pt
```

## Charts Implementation

### 1. Week Progress Chart (Bar)
```
Monday ■■■■■■■■■■ (100% complete)
Tuesday ■■■■■■□□□□ (60% complete)
Wednesday ■■□□□□□□□□ (20% complete)
...
```
**Accessibility**: "Tuesday, 60% complete, 14 hours remaining"

### 2. Month Progress (Ring)
```
    ●●●●●●●●
  ●●        ●●
 ●    48%     ●
●              ●
 ●           ●
  ●●        ●●
    ●●●●●●●●
```
**Accessibility**: "Month is 48% complete, 16 days remaining"

### 3. Year Heat Map
```
W1  ████ ████ ████ ████ ████
W10 ████ ████ ░░░░ ░░░░ ░░░░
W20 ████ ████ ████ ░░░░ ░░░░
...
```
**Accessibility**: "Week 48 of 52, completed weeks shown in dark"

## Siri Integration (App Intents)

### Intent 1: CurrentWeekIntent
```swift
struct CurrentWeekIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Current Week"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let weekNumber = WeekCalculator.shared.currentWeekNumber()
        let year = WeekCalculator.shared.currentYear()

        return .result(
            dialog: "It's week \(weekNumber) of \(year)"
        )
    }
}
```

**Phrases**:
- "What week is it?"
- "What's the current week number?"
- "Tell me the week"

### Intent 2: WeekForDateIntent
```swift
struct WeekForDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Week for Date"

    @Parameter(title: "Date")
    var date: Date

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let weekNumber = WeekCalculator.shared.weekNumber(for: date)

        return .result(
            dialog: "\(date.formatted(.dateTime.month().day())) is in week \(weekNumber)"
        )
    }
}
```

**Phrases**:
- "What week is Christmas?"
- "What week is December 25th?"
- "Find week number for next Friday"

### Intent 3: WeekOverviewIntent
```swift
struct WeekOverviewIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Week Overview"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let info = WeekCalculator.shared.currentWeekInfo()

        return .result(
            dialog: """
            Week \(info.weekNumber): \(info.dateRange).
            \(info.daysRemaining) days remaining in this week.
            """
        )
    }
}
```

## Widget Suite

### Small Widget (2x2)
```
┌─────────┐
│  WEEK   │
│   48    │ ← Large number
│  2025   │ ← Year
└─────────┘
```

### Medium Widget (4x2)
```
┌───────────────────┐
│ WEEK 48     2025  │
│ Mon Tue Wed Thu Fri Sat Sun │
│  ●   ●   ○   ○   ○   ○   ○  │
└───────────────────┘
```

### Large Widget (4x4)
```
┌───────────────────────┐
│ WEEK 48         2025  │
├───────────────────────┤
│  M  T  W  T  F  S  S  │
│           1  2  3  4  │
│  5  6  7  8  9 10 11  │
│ 12 13 14 15 16 17 18  │
│ 19 20 21●22 23 24 25  │
│ 26 27 28 29 30        │
└───────────────────────┘
```

### Lock Screen Widget
```
Circular:  ┌───┐
           │48 │
           └───┘

Rectangular: WEEK 48 • 2025
```

## Accessibility

### VoiceOver
- Detailed descriptions for all UI elements
- Logical navigation order
- Audio Graphs for charts
- Rotor support for quick navigation

### Dynamic Type
- All text scales appropriately
- Layouts adapt to text size
- Minimum touch targets maintained

### Reduce Motion
- Simplified animations
- No parallax effects
- Static transitions

### Voice Control
- All controls have clear labels
- Number overlays for commands
- Custom voice commands

## Implementation Phases

### Phase 1: Core Foundation (Week 1)
- [ ] ISO 8601 week calculation service
- [ ] Basic home screen with week number
- [ ] Simple month calendar view
- [ ] Settings structure

### Phase 2: Widgets (Week 1)
- [ ] Small widget implementation
- [ ] Medium widget implementation
- [ ] Large widget implementation
- [ ] Lock screen widgets

### Phase 3: Siri Integration (Week 2)
- [ ] App Intents framework
- [ ] Current week intent
- [ ] Week for date intent
- [ ] Shortcuts donations
- [ ] Siri suggestions

### Phase 4: Charts & Visualizations (Week 2)
- [ ] Week progress chart
- [ ] Month progress chart
- [ ] Year heat map
- [ ] Audio Graphs support

### Phase 5: Data & Sync (Week 3)
- [ ] SwiftData models
- [ ] CloudKit integration
- [ ] Custom events/notes
- [ ] Import/export

### Phase 6: Polish & Testing (Week 3)
- [ ] Accessibility audit
- [ ] Performance optimization
- [ ] Localization (Swedish, English)
- [ ] App Store preparation

## Success Metrics

### User Experience
- [ ] Week number visible in < 1 second
- [ ] Siri query responds in < 2 seconds
- [ ] Widget updates within 15 minutes
- [ ] All interactions feel instant (< 100ms)

### Accessibility
- [ ] VoiceOver success rate > 95%
- [ ] All touch targets ≥ 44pt
- [ ] Color contrast ratio ≥ 4.5:1
- [ ] Supports all text sizes

### Technical
- [ ] App size < 10MB
- [ ] Memory usage < 50MB
- [ ] Battery impact: Low
- [ ] Zero crashes

## App Store Preparation

### Screenshots
1. Hero: Large week number on beautiful gradient
2. Calendar: Month view with week numbers
3. Widgets: All widget sizes showcased
4. Charts: Week/month progress visualizations
5. Siri: Siri interaction example

### Keywords
- Week number
- ISO 8601
- Calendar
- Week counter
- Swedish weeks
- Vecka

### Description
"Vecka is the most beautiful way to view ISO 8601 week numbers on your iPhone and iPad. With Siri integration, gorgeous widgets, and comprehensive calendar views, you'll never need to ask 'what week is it?' again."

---

**Next Steps**: Begin Phase 1 implementation with core week calculation and basic UI.
