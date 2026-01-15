# Component Glossary

A complete reference of all pages, views, and reusable components in Onsen Planner.

---

## Page Naming Convention

| Internal Name | Display Name | Icon | File |
|---------------|--------------|------|------|
| **Calendar Page** | Calendar | `calendar` | `ModernCalendarView.swift` |
| **Star Page** | Special Days | `star.fill` | `SpecialDaysListView.swift` |
| **Tools Page** | Tools / Workspace | `wrench.and.screwdriver` | `DashboardView.swift` |
| **Contacts Page** | Contacts | `person.2` | `ContactListView.swift` |
| **Settings Page** | Settings | `gearshape` | `SettingsView.swift` |
| **Notes Page** | Notes | `doc.text` | `NotesListView.swift` |
| **Events Page** | Countdowns | `timer` | `CountdownListView.swift` |
| **Trips Page** | Trips | `airplane` | `TripListView.swift` |
| **Expenses Page** | Expenses | `dollarsign.circle` | `ExpenseListView.swift` |

**Golden Standard:** Star Page (`SpecialDaysListView.swift`) - All pages should follow this pattern.

---

## Navigation Structure

### iPad (NavigationSplitView)
```
┌──────────────────────────────────────────────────────────────┐
│ IconStripSidebar │              Content                      │
│ (left edge)      │         (main area)                       │
│                  │                                           │
│  [📅]            │    ┌────────────────────────────────┐     │
│  [🔧]            │    │  Page Header                   │     │
│  [👥]            │    │  (Bento compartmentalized)     │     │
│  [⭐]            │    ├────────────────────────────────┤     │
│  [⚙️]            │    │  Content                       │     │
│                  │    │  (Sections, Lists, Grids)      │     │
│                  │    └────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

### iPhone (TabView + NavigationStack)
```
┌─────────────────────────┐
│  Page Header            │
├─────────────────────────┤
│  Content                │
│  (scrollable)           │
│                         │
├─────────────────────────┤
│ [📅] [📚] [⚙️]          │  ← TabView
└─────────────────────────┘
```

---

## Navigation Components

| Component | File | Purpose | Used By |
|-----------|------|---------|---------|
| `SidebarSelection` | `AppSidebar.swift:13` | Enum for all navigation destinations | iPad navigation |
| `AppSidebar` | `AppSidebar.swift:56` | Grid of large icons (legacy) | - |
| `IconStripSidebar` | `IconStripSidebar.swift:13` | Thin vertical icon strip | iPad left edge |
| `IconStripDock` | `IconStripDock.swift:13` | Horizontal bottom dock | iPad compact |
| `PhoneLibraryView` | `PhoneLibraryView.swift:12` | iPhone library tab content | iPhone TabView |

---

## Reusable Components (JohoDesignSystem.swift)

### Layout Components

| Component | Line | Purpose | Should Use? |
|-----------|------|---------|-------------|
| `Squircle` | 253 | Continuous corner shape | ✅ Always |
| `JohoContainer` | 268 | Bordered container with optional zone color | ✅ Yes |
| `JohoCard` | 569 | White card with black border | ✅ Yes |
| `JohoSectionBox` | 456 | Colored section with title pill | ✅ Yes |
| `JohoFormSection` | 495 | White form with black header | ✅ Editors |
| `JohoFormField` | 546 | Form field with label | ✅ Editors |
| `JohoCalendarContainer` | 1309 | Calendar grid wrapper | ✅ Calendar |

### Header Components

| Component | Line | Purpose | Used By |
|-----------|------|---------|---------|
| `JohoPageHeader` | 787 | Simple page header (title + badge) | Many pages |
| `JohoEditorHeader` | 823 | Editor sheet header (back + icon + save) | Editor sheets |

⚠️ **MISSING:** Star Page's `headerWithYearPicker` is NOT in JohoDesignSystem. It should be extracted!

### Display Components

| Component | Line | Purpose |
|-----------|------|---------|
| `JohoPill` | 313 | Label badges (black/white/colored) |
| `JohoIndicatorCircle` | 409 | Type indicator dots (●○) |
| `JohoDayCell` | 589 | Calendar day cell |
| `JohoWeekBadge` | 643 | Large week number display |
| `JohoListRow` | 697 | Standard list row with icon |
| `JohoStatBox` | 758 | Statistics display box |
| `JohoIconBadge` | 928 | Small icon with badge |
| `JohoTodayBanner` | 1158 | Today highlight banner |
| `JohoEmptyState` | 1092 | Empty content placeholder |

### Interactive Components

| Component | Line | Purpose |
|-----------|------|---------|
| `JohoActionButton` | 1470 | Action button with icon |
| `JohoToggle` | 1057 | 情報デザイン toggle switch |
| `JohoToggleRow` | 949 | Toggle with label |
| `JohoMetricRow` | 902 | Metric display row |
| `JohoDivider` | 990 | Black divider line |

### Calendar Components

| Component | Line | Purpose |
|-----------|------|---------|
| `JohoMonthSelector` | 1237 | Month navigation arrows |
| `JohoWeekdayHeader` | 1327 | Day of week header row |
| `JohoWeekNumberCell` | 1358 | Week number in grid |
| `JohoCalendarDayCell` | 1389 | Full calendar day cell |

---

## Components That Should Be Unified

### 1. Year Picker (HIGH PRIORITY)

**Current State:** Implemented inline in Star Page only.

**Found in:**
- `SpecialDaysListView.swift:931` - `bentoYearPicker` (Star Page)
- `ModernCalendarView.swift` - Different implementation
- `ExpenseListView.swift` - Different implementation
- `CountdownViews.swift` - Different implementation

**Action:** Extract to `JohoYearPicker` in JohoDesignSystem.swift

```swift
// PROPOSED: JohoYearPicker
struct JohoYearPicker: View {
    @Binding var year: Int
    var minYear: Int = 2000
    var maxYear: Int = 2100

    var body: some View {
        HStack(spacing: 4) {
            Button { year -= 1 } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 24, height: 44)
            }

            Text(String(year))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(JohoColors.black)
                .fixedSize()

            Button { year += 1 } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 24, height: 44)
            }
        }
    }
}
```

### 2. Page Header with Controls (HIGH PRIORITY)

**Current State:** Star Page has `headerWithYearPicker`, others use simpler `JohoPageHeader`.

**Action:** Create `JohoBentoPageHeader` that matches Star Page:

```
┌────────────────────────────────────────────────────────────────┐
│ ┌──────┬──────────────────────────────────────┬───────────────┐│
│ │ ICON │ TITLE                                │ [CONTROLS]    ││
│ │ 40pt │ Subtitle (optional)                  │  < 2026 >     ││
│ └──────┴──────────────────────────────────────┴───────────────┘│
│ ┌──────────────────────────────────────────────────────────────┐│
│ │ STATS ROW: ●13 ○11 ◆5                                       ││
│ └──────────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────┘
```

### 3. Stats Indicator Row (MEDIUM)

**Current State:** `bentoStatsRow` in Star Page, different in other views.

**Action:** Extract to `JohoStatsRow`:

```swift
struct JohoStatsRow: View {
    let stats: [(count: Int, color: Color)]
    // ...
}
```

### 4. Bento Row (MEDIUM)

**Current State:** Inline in Star Page's `itemRow(for:)`.

**Action:** Extract to `JohoBentoRow`:

```
┌─────┬──────────────────────────────┬─────────────────┐
│ ●   │ Title                        │ [Pills] [Icon]  │
│28pt │ flexible                     │ 72pt            │
└─────┴──────────────────────────────┴─────────────────┘
```

### 5. Country Pill (LOW)

**Current State:** `CountryPill` exists but location unclear.

**Action:** Ensure it's in JohoDesignSystem.swift and documented.

### 6. Icon Picker (LOW)

**Current State:** `JohoIconPicker` in CountdownViews.swift.

**Action:** Move to JohoDesignSystem.swift for reuse.

---

## View-Specific Components

### Star Page (`SpecialDaysListView.swift`)

| Component | Lines | Description |
|-----------|-------|-------------|
| `headerWithYearPicker` | 812-927 | Bento header with year stepper |
| `bentoYearPicker` | 931-964 | Year stepper control |
| `bentoStatsRow` | 968-1002 | Colored indicator counts |
| `monthGrid` | ~1004+ | 3-column month flipcards |
| `MonthFlipcard` | - | Individual month card |
| `SectionBox` | - | Collapsible type sections |
| `itemRow(for:)` | - | Bento row for entries |

### Calendar Page (`ModernCalendarView.swift`)

| Component | Description |
|-----------|-------------|
| Month navigation | Different from Star Page |
| Calendar grid | Uses `CalendarGridView` |
| Week detail panel | Side panel on iPad |

### Editor Sheets (Various)

| Sheet | File | Uses `JohoEditorHeader`? |
|-------|------|-------------------------|
| `JohoSpecialDayEditorSheet` | SpecialDaysListView.swift:2511 | Should ✅ |
| `JohoContactEditorSheet` | ContactDetailView.swift:626 | Should ✅ |
| `JohoTripEditorSheet` | TripListView.swift:418 | Should ✅ |
| `JohoExpenseEditorSheet` | ExpenseEntryView.swift:16 | Should ✅ |
| `JohoNoteEditorSheet` | DailyNotesView.swift:386 | Should ✅ |

---

## Unification Priority List

### Phase 1: Core Components
1. [ ] Extract `JohoYearPicker` from Star Page
2. [ ] Create `JohoBentoPageHeader` (header + controls + stats)
3. [ ] Ensure all editors use `JohoEditorHeader`

### Phase 2: Row Components
4. [ ] Extract `JohoBentoRow` pattern
5. [ ] Extract `JohoStatsRow` pattern
6. [ ] Standardize swipe actions across all lists

### Phase 3: Cleanup
7. [ ] Move `JohoIconPicker` to JohoDesignSystem
8. [ ] Document `CountryPill` location
9. [ ] Audit all pages against Star Page

---

## How to Reference This Document

When working with Claude:

```
"Check COMPONENT_GLOSSARY.md - I need to use [component name]"

"What component should I use for [description]?"

"The year picker needs to be unified - see COMPONENT_GLOSSARY.md"

"Apply the Star Page header pattern to [ViewName] -
 see headerWithYearPicker in the glossary"
```

---

## File Quick Reference

| Purpose | File |
|---------|------|
| Design system components | `Vecka/JohoDesignSystem.swift` |
| Star Page (golden standard) | `Vecka/Views/SpecialDaysListView.swift` |
| Navigation enum | `Vecka/Views/AppSidebar.swift` |
| iPad sidebar | `Vecka/Views/IconStripSidebar.swift` |
| Colors & fonts | `JohoDesignSystem.swift:48-226` |
| All Joho components | `JohoDesignSystem.swift:268-1500` |
