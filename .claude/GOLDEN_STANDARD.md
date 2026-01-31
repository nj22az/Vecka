# 情報デザイン Golden Standard

> **Last Updated:** 2026-01-31
> **Single Source of Truth for Onsen Planner Design System**

This document is the definitive reference for the 情報デザイン (Jōhō Dezain) design system as implemented in Onsen Planner. It serves as the golden standard for future apps built with this foundation.

---

## Quick Stats

| Metric | Count |
|--------|-------|
| **Swift Files** | 112 total (100 app + 12 widget) |
| **SwiftUI Views** | 44 views |
| **Design Components** | 50+ in JohoDesignSystem.swift (~4000 LOC) |
| **SwiftData Models** | 11 models |
| **Localizations** | 9 languages |
| **Widget Variants** | 4 (Small, Medium, Large, WorldClock) |
| **Supported Regions** | 16 countries |

---

## Color System (Authoritative)

### The 6-Color Semantic Palette

Every color has ONE clear meaning. No overlap, no confusion.

| Color | Hex | Japanese | Meaning | Usage |
|-------|-----|----------|---------|-------|
| **Yellow** | `#FFE566` | 今 (ima) | NOW | Today, notes, current moment |
| **Cyan** | `#A5F3FC` | 予定 (yotei) | SCHEDULED | Events, trips, calendar items |
| **Pink** | `#FECDD3` | 祝 (iwai) | CELEBRATION | Holidays, birthdays, special days |
| **Green** | `#4ADE80` | 金 (kane) | MONEY | Expenses, financial items |
| **Purple** | `#E9D5FF` | 人 (hito) | PEOPLE | Contacts, relationships |
| **Red** | `#E53935` | 警告 | ALERT | System warnings only |

### Structural Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Black** | `#000000` | Borders, text, authority, system UI |
| **White** | `#FFFFFF` | Container backgrounds |

### Light Tints (Bento Backgrounds)

| Tint | Hex | Usage |
|------|-----|-------|
| Yellow Light | `#FEF3C7` | Notes backgrounds |
| Cyan Light | `#CFFAFE` | Events backgrounds |
| Pink Light | `#FED7E2` | Celebrations backgrounds |
| Green Light | `#D1FAE5` | Expenses backgrounds |
| Purple Light | `#F3E8FF` | Contacts backgrounds |
| Red Light | `#FECACA` | Alerts backgrounds |

### Category Colors (Star Page)

| Category | Color | Code |
|----------|-------|------|
| Holidays | Pink | `JohoColors.pink` |
| Observances | Cyan | `JohoColors.cyan` |
| Memos | Yellow | `JohoColors.yellow` |

### Deprecated Colors (Migration Reference)

| Deprecated | Now Aliased To | Historical Hex | Reason |
|------------|----------------|----------------|--------|
| `cream` | `yellow` | #FFFBF5 | 6-color simplification |
| `orange` | `cyan` | #FDBA74 | 6-color simplification |

---

## Component Registry

All components prefixed with `Joho*` are in `JohoDesignSystem.swift`.

### Layout Components

| Component | Line | Purpose |
|-----------|------|---------|
| `JohoContainer` | 563 | Bordered container with optional zone color |
| `JohoCard` | 914 | White card with black border |
| `JohoSectionBox` | 805 | Colored section with title pill |
| `JohoFormSection` | 836 | White form with black header |
| `JohoFormField` | 887 | Form field with label |
| `JohoCalendarContainer` | 2023 | Calendar grid wrapper |

### Header Components

| Component | Line | Purpose |
|-----------|------|---------|
| `JohoPageHeader` | 1135 | Simple page header (title + badge) |
| `JohoEditorHeader` | 1171 | Editor sheet header (back + icon + save) |
| `JohoMonthSelector` | 1959 | Month navigation arrows |

### Display Components

| Component | Line | Purpose |
|-----------|------|---------|
| `JohoPill` | 607 | Label badges (black/white/colored) |
| `JohoIndicatorCircle` | 707 | Type indicator dots |
| `JohoDayCell` | 934 | Calendar day cell |
| `JohoWeekBadge` | 993 | Large week number display |
| `JohoListRow` | 1047 | Standard list row with icon |
| `JohoStatBox` | 1104 | Statistics display box |
| `JohoIconBadge` | 1267 | Small icon with badge |
| `JohoTodayBanner` | 1880 | Today highlight banner |
| `JohoEmptyState` | 1669 | Empty content placeholder |
| `JohoMetricRow` | 1237 | Metric display row |

### Interactive Components

| Component | Line | Purpose |
|-----------|------|---------|
| `JohoActionButton` | 2192 | Action button with icon |
| `JohoToggle` | 1630 | 情報デザイン toggle switch |
| `JohoToggleRow` | 1426 | Toggle with label |
| `JohoSearchField` | 1333 | Search input field |
| `JohoIconButton` | 1290 | Circular icon button |
| `JohoDivider` | 1467 | Black divider line |

### Calendar Components

| Component | Line | Purpose |
|-----------|------|---------|
| `JohoWeekdayHeader` | 2039 | Day of week header row |
| `JohoWeekNumberCell` | 2072 | Week number in grid |
| `JohoCalendarDayCell` | 2106 | Full calendar day cell |
| `JohoCalendarPicker` | 2630 | Date picker (replaces iOS DatePicker) |
| `JohoMonthYearPicker` | 3557 | Month/Year picker |
| `JohoYearPicker` | 2284 | Year stepper control |

### Picker Components

| Component | Line | Purpose |
|-----------|------|---------|
| `JohoTypeSelector` | 2350 | Entry type selector |
| `JohoTypeSuggestionPill` | 2392 | Type suggestion pill |
| `JohoSFSymbolPickerSheet` | 3003 | SF Symbol picker |
| `JohoColorPickerSheet` | 3245 | Color picker |

### View Modifiers

| Modifier | Line | Purpose |
|----------|------|---------|
| `.johoBackground()` | 2449 | Dark app background |
| `.johoNavigation()` | 2464 | Navigation style |
| `.johoListStyle()` | 2480 | List appearance |
| `.johoBento()` | 2493 | Bento card style |
| `.johoAccentedBento()` | 2514 | Colored bento card |
| `.johoSectionHeader()` | 2537 | Section header style |
| `.johoInteractiveCell()` | 2551 | Touch feedback cell |
| `.johoCalendarPicker()` | 2930 | Calendar picker overlay |
| `.johoMonthYearPicker()` | 3747 | Month/year picker overlay |

---

## View Registry

### Main Pages (5)

| Page | File | Icon |
|------|------|------|
| Calendar | `ModernCalendarView.swift` | `calendar` |
| Special Days (Star) | `SpecialDaysListView.swift` | `star.fill` |
| Tools | `DashboardView.swift` | `wrench.and.screwdriver` |
| Contacts | `ContactListView.swift` | `person.2` |
| Settings | `SettingsView.swift` | `gearshape` |

### Feature Views

| Feature | Files |
|---------|-------|
| Notes | `NotesListView.swift`, `DailyNotesView.swift`, `MemoEditorView.swift` |
| Events | `CountdownListView.swift`, `CountdownViews.swift` |
| Trips | `TripListView.swift` |
| Expenses | `ExpenseListView.swift`, `ExpenseEntryView.swift` |
| Contacts | `ContactListView.swift`, `ContactDetailView.swift` |

### Navigation Views

| View | File | Purpose |
|------|------|---------|
| `SwipeNavigationContainer` | `SwipeNavigationContainer.swift` | Main navigation container |
| `IconStripSidebar` | `IconStripSidebar.swift` | iPad left edge sidebar |
| `IconStripDock` | `IconStripDock.swift` | iPad compact dock |
| `PhoneLibraryView` | `PhoneLibraryView.swift` | iPhone library tab |
| `AppSidebar` | `AppSidebar.swift` | Navigation enum + legacy grid |

### Calendar Views

| View | File | Purpose |
|------|------|---------|
| `CalendarGridView` | `CalendarGridView.swift` | Month grid display |
| `DayDetailSheet` | `DayDetailSheet.swift` | Day detail modal |
| `DayDashboardView` | `DayDashboardView.swift` | Day overview |

### Editor Sheets

| Sheet | File |
|-------|------|
| Special Day Editor | `JohoEditorSheets.swift` |
| Memo Editor | `MemoEditorView.swift` |
| Unified Entry Creator | `UnifiedEntryCreator.swift` |

---

## Model Registry

### SwiftData Models (11)

| Model | File | Relationships |
|-------|------|---------------|
| `DailyNote` | `Memo.swift` | - |
| `HolidayRule` | `HolidayRule.swift` | - |
| `CalendarRule` | `CalendarRule.swift` | - |
| `CountdownEvent` | `CountdownModels.swift` | - |
| `ExpenseCategory` | (ExpenseModels) | → ExpenseItems |
| `ExpenseTemplate` | (ExpenseModels) | - |
| `ExpenseItem` | (ExpenseModels) | → ExpenseCategory |
| `TravelTrip` | (TripModels) | → MileageEntries |
| `MileageEntry` | (TripModels) | → TravelTrip |
| `ExchangeRate` | (CurrencyModels) | - |
| `SavedLocation` | (LocationModels) | - |

### Contact Models (8 in ContactModels.swift)

| Model | Purpose |
|-------|---------|
| `Contact` | Main contact entity |
| `ContactPhoneNumber` | Phone number storage |
| `ContactEmail` | Email storage |
| `ContactAddress` | Address storage |
| `ContactSocialProfile` | Social media links |
| `ContactURL` | Website URLs |
| `ContactDate` | Important dates |
| `ContactRelation` | Relationship links |

---

## Golden Patterns

### Pattern 1: Bento Page Header

```swift
// From Star Page (SpecialDaysListView.swift)
private var headerWithYearPicker: some View {
    VStack(spacing: 0) {
        HStack(spacing: 12) {
            // Icon zone
            Image(systemName: "star.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(JohoColors.black)
                .frame(width: 40, height: 40)
                .background(PageHeaderColor.specialDays.lightBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: 1.5))

            // Title + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text("SPECIAL DAYS")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("Holidays & Events")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }

            Spacer()

            // Year picker
            JohoYearPicker(year: $year)
        }
        .padding(12)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(JohoColors.black, lineWidth: 2))
    }
}
```

### Pattern 2: Bento Row (List Item)

```swift
// Structure: LEFT | CENTER | RIGHT with vertical dividers
HStack(spacing: 0) {
    // LEFT: Type indicator (28pt)
    Circle()
        .fill(accentColor)
        .frame(width: 10, height: 10)
        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
        .frame(width: 28)

    // Divider
    Rectangle()
        .fill(JohoColors.black)
        .frame(width: 1.5)

    // CENTER: Title (flexible)
    Text(item.title)
        .font(.system(size: 16, weight: .medium, design: .rounded))
        .padding(.horizontal, 12)

    Spacer()

    // Divider
    Rectangle()
        .fill(JohoColors.black)
        .frame(width: 1.5)

    // RIGHT: Pills + icons (72pt)
    HStack(spacing: 8) {
        CountryPill(code: "SWE")
        Image(systemName: "star.fill")
    }
    .frame(width: 72)
}
.frame(height: 44) // Touch target
.background(JohoColors.white)
.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
.overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
    .stroke(JohoColors.black, lineWidth: 1.5))
```

### Pattern 3: Editor Sheet

```swift
.sheet(isPresented: $showEditor) {
    NavigationStack {
        VStack(spacing: 0) {
            JohoEditorHeader(
                title: "EDIT MEMO",
                subtitle: "Personal note",
                icon: "doc.text",
                accentColor: JohoColors.yellow,
                isValid: !text.isEmpty,
                onBack: { showEditor = false },
                onSave: { saveAndClose() }
            )

            // Form content (no scroll)
            VStack(spacing: 12) {
                JohoFormField(label: "CONTENT") {
                    TextField("", text: $text)
                }
            }
            .padding(12)

            Spacer()
        }
        .background(JohoColors.white)
    }
    .presentationBackground(JohoColors.black)
    .presentationDragIndicator(.hidden)
}
```

### Pattern 4: Type Indicator Circles

```swift
// Standard indicator with semantic color
Circle()
    .fill(entryType.accentColor)  // From semantic palette
    .frame(width: 10, height: 10)
    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))

// Type → Color mapping
extension EntryType {
    var accentColor: Color {
        switch self {
        case .note: return JohoColors.yellow      // NOW
        case .trip, .event: return JohoColors.cyan    // SCHEDULED
        case .holiday, .birthday: return JohoColors.pink // CELEBRATION
        case .expense: return JohoColors.green    // MONEY
        case .contact: return JohoColors.purple   // PEOPLE
        }
    }
}
```

---

## Border Specifications

| Element | Width |
|---------|-------|
| Day cells | 1pt |
| List rows | 1.5pt |
| Buttons | 2pt |
| Selected/Today | 2.5pt |
| Containers/Cards | 3pt |

---

## Typography Scale

| Scale | Size | Weight | Usage |
|-------|------|--------|-------|
| displayLarge | 48pt | heavy | Hero numbers |
| displayMedium | 32pt | bold | Section titles |
| headline | 18pt | bold | Card titles |
| body | 16pt | medium | Content |
| bodySmall | 14pt | medium | Secondary |
| label | 12pt | bold | Pills, badges (UPPERCASE) |
| labelSmall | 10pt | bold | Timestamps |

**Rules:**
- ALWAYS use `.design(.rounded)`
- NEVER use weights below `.medium`
- Labels and pills are ALWAYS UPPERCASE

---

## See Also

- `.claude/design-system.md` — Visual specification details
- `.claude/architecture.md` — Technical structure
- `.claude/layout-rules.md` — Interaction rules
- `.claude/COMPONENT_GLOSSARY.md` — Component details
- `.claude/FILE_REGISTRY.md` — Complete file inventory
- `.claude/NEW_APP_GUIDE.md` — Building new apps

---

*This document is the authoritative reference. When in doubt, this wins.*
