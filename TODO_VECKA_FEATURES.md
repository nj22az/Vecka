# Vecka App - Feature Development Roadmap

## Current Status
- ✅ Calendar grid with week numbers (ISO 8601)
- ✅ Sticky week header in toolbar
- ✅ Countdown system with favorites
- ✅ Swedish holidays support
- ✅ Weather backend (WeatherService) - UI pending
- ⚠️ Portrait layout needs decluttering
- ⚠️ Landscape layout needs refinement
- ⚠️ Day tap needs note creation flow
- ⚠️ Settings needs holiday region selector (limit: 2 regions)
- ⚠️ Lunar calendar integration needed

### Weather Feature Status
**Backend**: ✅ Complete
- WeatherService.swift integrated with WeatherKit
- Settings toggle implemented
- Location management functional
- Requires paid Apple Developer account

**UI**: ⚠️ Pending Implementation
- Weather display components not yet integrated
- Planned: Weather badges on calendar days
- Planned: Detailed weather view
- Backend ready for UI development

---

## Priority 0: Portrait Layout Decluttering 🧹

### Goal
Simplify iPhone portrait layout - remove clutter, make it clean like iOS Calendar app.

### Current Issues
- Countdown banner takes too much space
- No quick access to add notes when tapping a day
- Month header could be more integrated
- Too much vertical scrolling

### Improved Portrait Layout
```
┌─────────────────────────────┐
│ Today   Week 48     [⚙️]    │ ← Toolbar (sticky week header)
│         Nov 24-30           │
├─────────────────────────────┤
│                             │
│      November 2025          │ ← Month header (compact)
│  W  M  T  W  T  F  S  S     │
│ 44 27 28 29 30  1  2  3     │
│ 45  4  5  6  7  8  9 10     │
│ 46 11 12 13 14 15 16 17     │
│ 47 18 19 20●21 22 23 24     │ ← Day with note (•)
│ 48 25 26 27 28 29 30  1     │ ← Holiday (emoji 🎄)
│                             │
├─────────────────────────────┤
│ 📝 Quick Note               │ ← Appears when day selected
│ "Tap to add note..."        │ ← Tap opens note editor
├─────────────────────────────┤
│ 🎄 Christmas Eve (SE)       │ ← Holidays for selected week
│ 🎄 Christmas Day (SE)       │ ← Only show enabled regions
├─────────────────────────────┤
│ ✨ New Year • 38 days       │ ← Countdown (compact)
└─────────────────────────────┘
```

### Tasks

#### 0.1 Reduce Month Header Size
**File**: `CalendarGridView.swift`

- [ ] Make month name smaller (`.title3` instead of `.title2`)
- [ ] Make year more subtle (use `.caption` with secondary color)
- [ ] Add lunar date display (if enabled):
  ```
  November 2025
  甲辰年 十月 廿七 (Chinese)
  ```
- [ ] Tighter spacing (reduce padding from 24pt to 12pt)

**Acceptance Criteria**:
- ✅ Month header takes less vertical space
- ✅ Lunar date shows when enabled
- ✅ Still readable and clear
- ✅ Maintains proper hierarchy

**Estimated Effort**: 1-2 hours

#### 0.2 Add Day Tap Note Creation Flow
**Files**: `CalendarGridView.swift`, `MainCalendarView.swift`

- [ ] When day is tapped:
  - [ ] Highlight the day (existing behavior)
  - [ ] Show "Quick Note" section below calendar
  - [ ] Display existing note if present
  - [ ] Show "Tap to add note..." if no note
- [ ] Tapping "Quick Note" section:
  - [ ] Opens full note editor (sheet or navigation)
  - [ ] Pre-filled with day's date
  - [ ] Keyboard appears automatically
  - [ ] Save/Cancel buttons
- [ ] After saving note:
  - [ ] Day shows note indicator (small dot)
  - [ ] Quick Note section shows preview
  - [ ] Haptic feedback

**Acceptance Criteria**:
- ✅ Tapping any day shows Quick Note section
- ✅ Easy to add notes with minimal taps
- ✅ Days with notes show visual indicator
- ✅ Smooth animations (fade in/out)

**Estimated Effort**: 3-4 hours

#### 0.3 Compact Countdown Display
**File**: `CountdownBanner.swift`

- [ ] Reduce height of countdown banner
- [ ] Single line layout: "✨ New Year • 38 days"
- [ ] Remove large "DAYS" text
- [ ] Make it feel less dominant
- [ ] Optional: Hide countdown if no event selected

**Acceptance Criteria**:
- ✅ Countdown takes less vertical space
- ✅ Still readable and clear
- ✅ Consistent with new clean aesthetic
- ✅ Works with all countdown types

**Estimated Effort**: 1-2 hours

#### 0.4 Smart Holiday Display
**File**: `MainCalendarView.swift` (new section)

- [ ] Show holidays for selected week (not all months)
- [ ] Only show holidays from enabled regions
- [ ] Compact list format (emoji + name + region code)
- [ ] Maximum 3 holidays shown, "... and X more" if needed
- [ ] Empty state if no holidays in selected week

**Acceptance Criteria**:
- ✅ Holidays contextual to selected week
- ✅ Only shows enabled regions
- ✅ Doesn't clutter screen if many holidays
- ✅ Clear and scannable

**Estimated Effort**: 2-3 hours

---

## Priority 1: iPad Landscape Layout Optimization 🎯

### Goal
Make landscape view look like the StandBy clock screenshot - clean, no scrolling needed.

### Layout Structure
```
┌────────────────────────────────────────────────────────┐
│ Today           Week 48 • Nov 24-30            [⚙️]    │ ← Toolbar with week info
├────────────────────────────────────────────────────────┤
│                              │                         │
│  LEFT PANEL (40%)            │  RIGHT PANEL (60%)      │
│                              │                         │
│  ┌─────────────────────┐    │    November 2025        │
│  │ 📝 Notes & Info     │    │    W  M  T  W  T  F  S  │
│  │                     │    │   44 27 28 29 30  1  2  │
│  │ • Week notes        │    │   45  3  4  5  6  7  8  │
│  │ • Holidays          │    │   46 10 11 12 13 14 15  │
│  │ • Events            │    │   47 17 18 19 20●21 22  │
│  │                     │    │   48 24 25 26 27 28 29  │
│  └─────────────────────┘    │                         │
│                              │  ┌───────────────────┐  │
│  ┌─────────────────────┐    │  │ Countdown         │  │
│  │ ✨ New Year         │    │  │ 38 days           │  │
│  │ 38 DAYS             │    │  └───────────────────┘  │
│  └─────────────────────┘    │                         │
│                              │                         │
└────────────────────────────────────────────────────────┘
```

### Tasks

#### 1.1 Redesign Landscape Layout
**File**: `MainCalendarView.swift`

- [ ] Create 40/60 split (left panel / calendar)
- [ ] Left panel contains:
  - [ ] Notes section (scrollable if needed)
  - [ ] Holidays section
  - [ ] Countdown banner
- [ ] Right panel contains:
  - [ ] Calendar grid (non-scrollable, fits perfectly)
  - [ ] Optional: Small info cards below if space allows
- [ ] Ensure NO scrolling needed on iPad landscape
- [ ] Test on iPad Pro 13" and iPad Air 11"

**Acceptance Criteria**:
- ✅ All content visible without scrolling on iPad landscape
- ✅ Left panel shows notes/info/countdown
- ✅ Right panel shows full calendar grid
- ✅ Maintains sticky week header in toolbar
- ✅ Clean, balanced layout like StandBy clock example

**Estimated Effort**: 4-6 hours

---

## Priority 2: Notes System 📝

### Goal
Add ability to write and view notes for any day/week.

### Data Model

#### 2.1 Create Note Data Structure
**File**: `Models/NoteModels.swift` (NEW)

- [ ] Create `DayNote` struct:
  ```swift
  struct DayNote: Identifiable, Codable {
      let id: UUID
      let date: Date
      var content: String
      var createdAt: Date
      var modifiedAt: Date
  }
  ```
- [ ] Create `WeekNote` struct:
  ```swift
  struct WeekNote: Identifiable, Codable {
      let id: UUID
      let weekNumber: Int
      let year: Int
      var content: String
      var createdAt: Date
      var modifiedAt: Date
  }
  ```
- [ ] Create `NotesManager` class for persistence:
  ```swift
  @MainActor
  class NotesManager: ObservableObject {
      @Published var dayNotes: [Date: DayNote] = [:]
      @Published var weekNotes: [String: WeekNote] = [:]

      func saveNote(for date: Date, content: String)
      func getNote(for date: Date) -> DayNote?
      func saveWeekNote(weekNumber: Int, year: Int, content: String)
      func getWeekNote(weekNumber: Int, year: Int) -> WeekNote?
      func deleteNote(for date: Date)
      func deleteWeekNote(weekNumber: Int, year: Int)
  }
  ```

**Acceptance Criteria**:
- ✅ Notes persist across app launches (UserDefaults or FileManager)
- ✅ Each day can have one note
- ✅ Each week can have one note
- ✅ Notes include creation and modification timestamps

**Estimated Effort**: 2-3 hours

#### 2.2 Create Notes UI Components
**File**: `Views/NotesView.swift` (NEW)

- [ ] Create `NoteEditorView`:
  - [ ] Text editor with placeholder
  - [ ] Character count
  - [ ] Save/Cancel buttons
  - [ ] Keyboard toolbar with formatting options (optional)
- [ ] Create `NotesListView`:
  - [ ] Shows notes for selected day/week
  - [ ] Tap to edit
  - [ ] Swipe to delete
  - [ ] Empty state message
- [ ] Create `NoteCardView`:
  - [ ] Compact display of note content
  - [ ] Shows creation date
  - [ ] Preview text (first 100 chars)
  - [ ] Tap to expand/edit

**Acceptance Criteria**:
- ✅ Can add/edit/delete notes for any day
- ✅ Can add/edit/delete notes for any week
- ✅ Notes display in left panel on landscape
- ✅ Notes display below calendar on portrait
- ✅ Proper keyboard handling (doesn't cover content)

**Estimated Effort**: 3-4 hours

#### 2.3 Integrate Notes into Main UI
**Files**: `MainCalendarView.swift`, `CalendarGridView.swift`

- [ ] Add note indicator to calendar days (small dot)
- [ ] Show note count in week info if week has notes
- [ ] Display notes in left panel (landscape)
- [ ] Display notes below calendar (portrait)
- [ ] Add "Add Note" button when day/week selected
- [ ] Show existing note content when present

**Acceptance Criteria**:
- ✅ Days with notes show visual indicator
- ✅ Tapping day with note shows note content
- ✅ Easy to add new notes
- ✅ Works on both portrait and landscape

**Estimated Effort**: 2-3 hours

---

## Priority 3: International Holidays System 🌍

### Goal
Display holidays from multiple countries and cultural calendars.

### Data Model

#### 3.1 Expand Holiday System
**File**: `Models/HolidayModels.swift` (NEW or refactor from SwedishHolidays.swift)

- [ ] Create `HolidayRegion` enum:
  ```swift
  enum HolidayRegion: String, Codable, CaseIterable {
      case sweden = "Sweden"
      case usa = "United States"
      case uk = "United Kingdom"
      case germany = "Germany"
      case france = "France"
      case japan = "Japan"
      case india = "India"
      case china = "China"
      case islamic = "Islamic Calendar"
      case jewish = "Jewish Calendar"
      case custom = "Custom"
  }
  ```
- [ ] Create `Holiday` struct:
  ```swift
  struct Holiday: Identifiable, Codable, Hashable {
      let id: UUID
      let name: String
      let date: Date
      let region: HolidayRegion
      let isPublicHoliday: Bool
      let culturalSignificance: String?
      let emoji: String?
  }
  ```
- [ ] Create `HolidayProvider` protocol:
  ```swift
  protocol HolidayProvider {
      func getHolidays(for year: Int) -> [Holiday]
  }
  ```

**Acceptance Criteria**:
- ✅ Support for at least 8 countries/regions
- ✅ Support for Islamic and Jewish calendars
- ✅ Proper handling of moveable holidays (Easter, Ramadan, etc.)
- ✅ Emoji indicators for each holiday type

**Estimated Effort**: 4-6 hours

#### 3.2 Implement Holiday Providers
**Files**: `Holidays/SwedenHolidayProvider.swift`, `Holidays/USAHolidayProvider.swift`, etc.

- [ ] Refactor `SwedishHolidays.swift` into `SwedenHolidayProvider`
- [ ] Create `USAHolidayProvider`:
  - [ ] Major US holidays (Independence Day, Thanksgiving, etc.)
  - [ ] Federal holidays
- [ ] Create `UKHolidayProvider`:
  - [ ] Bank holidays
  - [ ] Major UK celebrations
- [ ] Create `IslamicHolidayProvider`:
  - [ ] Ramadan
  - [ ] Eid al-Fitr
  - [ ] Eid al-Adha
  - [ ] Use lunar calendar calculations
- [ ] Create `JewishHolidayProvider`:
  - [ ] Rosh Hashanah
  - [ ] Yom Kippur
  - [ ] Passover
  - [ ] Hanukkah
  - [ ] Use Hebrew calendar calculations
- [ ] Create `CustomHolidayProvider`:
  - [ ] User-defined holidays
  - [ ] Birthdays, anniversaries, etc.

**Acceptance Criteria**:
- ✅ Each provider returns accurate holidays for given year
- ✅ Moveable holidays calculated correctly
- ✅ Supports years 2020-2030 minimum
- ✅ Well-tested with unit tests

**Estimated Effort**: 8-12 hours (spread across multiple providers)

#### 3.3 Holiday Region Selector (Settings Wheel)
**File**: `Views/HolidaySettingsView.swift` (NEW)

**IMPORTANT**: User can select **MAXIMUM 2 REGIONS** to avoid clutter.

- [ ] Create region selector interface in Settings:
  - [ ] Grid/List of all available regions (20+ options)
  - [ ] Each region shows:
    - [ ] Flag emoji or icon
    - [ ] Region name
    - [ ] Holiday count (e.g., "12 holidays/year")
    - [ ] Checkmark if selected
  - [ ] Selection limit: 2 regions maximum
  - [ ] Show warning if trying to select 3rd region: "Maximum 2 regions allowed"
  - [ ] Allow deselecting to change regions
- [ ] Available regions (20+ total):
  ```swift
  // Western Countries
  - Sweden 🇸🇪
  - United States 🇺🇸
  - United Kingdom 🇬🇧
  - Canada 🇨🇦
  - Australia 🇦🇺
  - New Zealand 🇳🇿
  - Germany 🇩🇪
  - France 🇫🇷
  - Spain 🇪🇸
  - Italy 🇮🇹
  - Netherlands 🇳🇱

  // Asian Countries
  - China 🇨🇳
  - Japan 🇯🇵
  - South Korea 🇰🇷
  - India 🇮🇳
  - Thailand 🇹🇭
  - Singapore 🇸🇬
  - Vietnam 🇻🇳

  // Religious Calendars
  - Islamic Calendar ☪️
  - Jewish Calendar ✡️
  - Hindu Calendar 🕉️

  // Custom
  - Custom Holidays ⭐
  ```
- [ ] Preview section:
  - [ ] Shows next 5 holidays from selected regions
  - [ ] Tappable to see full year calendar
- [ ] Custom holiday creation:
  - [ ] Button to add custom holiday
  - [ ] Fields: Name, Date, Recurring (yes/no), Emoji
  - [ ] Custom holidays don't count toward 2-region limit
- [ ] Settings persistence:
  - [ ] Save selected regions to UserDefaults
  - [ ] Save custom holidays to persistent storage

**Acceptance Criteria**:
- ✅ User can select UP TO 2 REGIONS (hard limit)
- ✅ Clear error message if exceeding limit
- ✅ 20+ regions available to choose from
- ✅ Selections persist across app launches
- ✅ Can add unlimited custom holidays
- ✅ Preview shows upcoming holidays accurately
- ✅ Intuitive UI with flags/icons

**Estimated Effort**: 4-5 hours

#### 3.4 Holiday Display Integration
**Files**: `CalendarGridView.swift`, `NotesView.swift`

- [ ] Show holiday indicator on calendar days (emoji or dot)
- [ ] Display holiday name on day tap
- [ ] List holidays in notes panel (landscape)
- [ ] Show holidays for selected week
- [ ] Color-code holidays by region
- [ ] Handle multiple holidays on same day

**Acceptance Criteria**:
- ✅ Days with holidays show visual indicator
- ✅ Holiday names displayed clearly
- ✅ Multiple holidays handled gracefully
- ✅ Works on both portrait and landscape

**Estimated Effort**: 3-4 hours

---

## Priority 4: PDF Export System 📄

### Goal
Export week/month data as beautifully formatted PDF with notes, stats, and holidays.

### Architecture

#### 4.1 Create PDF Export Engine
**File**: `Export/PDFGenerator.swift` (NEW)

- [ ] Create `PDFExportOptions` struct:
  ```swift
  struct PDFExportOptions {
      var includeCalendar: Bool = true
      var includeNotes: Bool = true
      var includeHolidays: Bool = true
      var includeStats: Bool = true
      var includeCountdown: Bool = false
      var pageSize: PDFPageSize = .a4
      var orientation: PDFOrientation = .portrait
      var colorScheme: PDFColorScheme = .auto
  }
  ```
- [ ] Create `PDFGenerator` class:
  ```swift
  class PDFGenerator {
      func exportWeek(_ week: CalendarWeek, options: PDFExportOptions) -> Data
      func exportMonth(_ month: CalendarMonth, options: PDFExportOptions) -> Data
      func exportDateRange(from: Date, to: Date, options: PDFExportOptions) -> Data
  }
  ```

**Acceptance Criteria**:
- ✅ Generates valid PDF data
- ✅ Supports A4 and Letter page sizes
- ✅ Supports portrait and landscape
- ✅ Adapts to light/dark mode or user preference

**Estimated Effort**: 6-8 hours

#### 4.2 Design PDF Templates
**File**: `Export/PDFTemplates.swift` (NEW)

- [ ] Create week summary template:
  - [ ] Week number and year (large header)
  - [ ] Date range
  - [ ] Calendar grid for the week
  - [ ] Notes section (if notes exist)
  - [ ] Holidays section (if holidays exist)
  - [ ] Statistics (days completed, notes count, etc.)
  - [ ] Footer with export date
- [ ] Create month summary template:
  - [ ] Month and year (large header)
  - [ ] Full month calendar grid with week numbers
  - [ ] Week-by-week notes summary
  - [ ] Holiday list
  - [ ] Monthly statistics
  - [ ] Footer with export date
- [ ] Apply Apple-inspired design:
  - [ ] SF Pro typography
  - [ ] Clean margins (2cm all sides)
  - [ ] Proper spacing (8-point grid)
  - [ ] Professional color scheme
  - [ ] Icons for holidays and notes

**Acceptance Criteria**:
- ✅ PDFs look professional and polished
- ✅ Typography follows Apple HIG
- ✅ Proper page breaks for multi-page exports
- ✅ Consistent with app's visual design

**Estimated Effort**: 8-10 hours

#### 4.3 Statistics Calculation
**File**: `Models/StatisticsCalculator.swift` (NEW)

- [ ] Create statistics for week:
  - [ ] Days completed / Days remaining
  - [ ] Number of notes written
  - [ ] Number of holidays
  - [ ] Countdown progress (if applicable)
- [ ] Create statistics for month:
  - [ ] Total days
  - [ ] Week count
  - [ ] Notes count
  - [ ] Holidays count
  - [ ] Most productive week (most notes)
- [ ] Create statistics for date range:
  - [ ] Days spanned
  - [ ] Weeks spanned
  - [ ] Total notes
  - [ ] Total holidays

**Acceptance Criteria**:
- ✅ Accurate calculations
- ✅ Formatted strings for display
- ✅ Performance optimized for large date ranges

**Estimated Effort**: 2-3 hours

#### 4.4 Export UI Integration
**File**: `Views/ExportView.swift` (NEW)

- [ ] Create export options sheet:
  - [ ] Select export scope (week/month/range)
  - [ ] Toggle options (notes, holidays, stats, etc.)
  - [ ] Page size selection
  - [ ] Orientation selection
  - [ ] Color scheme selection
  - [ ] Preview button
- [ ] Add export button to toolbar
- [ ] Show share sheet with PDF
- [ ] Handle export errors gracefully

**Acceptance Criteria**:
- ✅ Easy to access from main view
- ✅ Preview before export
- ✅ Share to Files, Mail, etc.
- ✅ Error messages for failed exports

**Estimated Effort**: 4-5 hours

---

## Priority 5: Lunar Calendar Integration 🌙

### Goal
Display dual-date calendar showing both Gregorian and Lunar dates for selected calendar systems (Chinese, Islamic, Hebrew, Hindu).

### Lunar Calendar Systems

#### 5.1 Lunar Calendar Data Models
**File**: `Models/LunarCalendarModels.swift` (NEW)

- [ ] Create `LunarCalendarType` enum:
  ```swift
  enum LunarCalendarType: String, Codable, CaseIterable {
      case chinese = "Chinese (農曆)"
      case islamic = "Islamic (Hijri)"
      case hebrew = "Hebrew (עברי)"
      case hindu = "Hindu (Panchang)"
      case none = "Gregorian Only"
  }
  ```
- [ ] Create `LunarDate` struct:
  ```swift
  struct LunarDate: Codable {
      let calendarType: LunarCalendarType
      let year: String       // e.g., "甲辰年" (Chinese), "1446" (Islamic)
      let month: String      // e.g., "十月" (Chinese), "Ramadan" (Islamic)
      let day: String        // e.g., "廿七" (Chinese), "15" (Islamic)
      let formatted: String  // Complete formatted string
  }
  ```
- [ ] Create `LunarCalendarConverter` protocol:
  ```swift
  protocol LunarCalendarConverter {
      func convert(_ gregorianDate: Date) -> LunarDate
      func getMonthName(_ monthNumber: Int) -> String
      func getYearName(_ year: Int) -> String
  }
  ```

**Acceptance Criteria**:
- ✅ Supports 4 major lunar calendar systems
- ✅ Accurate conversions for dates 2000-2100
- ✅ Proper formatting in native scripts (Chinese characters, Arabic, Hebrew)
- ✅ Can be toggled on/off

**Estimated Effort**: 4-6 hours

#### 5.2 Implement Lunar Calendar Converters
**Files**: `LunarCalendars/ChineseCalendar.swift`, `LunarCalendars/IslamicCalendar.swift`, etc.

- [ ] Create `ChineseCalendarConverter`:
  - [ ] Sexagenary cycle (天干地支) calculation
  - [ ] Chinese month names (正月, 二月, etc.)
  - [ ] Traditional Chinese day numbers (初一, 初二, 廿七, etc.)
  - [ ] Leap month handling (閏月)
  - [ ] Zodiac year (鼠年, 牛年, etc.)
  - [ ] Format: "甲辰年 十月 廿七" or "Year of Dragon, 10th Month, 27th Day"

- [ ] Create `IslamicCalendarConverter`:
  - [ ] Hijri year calculation
  - [ ] Islamic month names (Muharram, Ramadan, etc.)
  - [ ] Day numbering (1-29/30)
  - [ ] Format: "15 Ramadan 1446 AH"

- [ ] Create `HebrewCalendarConverter`:
  - [ ] Hebrew year calculation
  - [ ] Hebrew month names (Tishrei, Nisan, etc.)
  - [ ] Hebrew day numbers
  - [ ] Leap year handling (Adar I, Adar II)
  - [ ] Format: "כ״ז כסלו התשפ״ה" (Hebrew) or "27 Kislev 5785" (Latin)

- [ ] Create `HinduCalendarConverter`:
  - [ ] Vikram Samvat or Saka Samvat calculation
  - [ ] Hindi month names (Chaitra, Vaishakha, etc.)
  - [ ] Tithi (lunar day) calculation
  - [ ] Paksha (waxing/waning) indication
  - [ ] Format: "Margashirsha Shukla 12, Vikram Samvat 2081"

**Acceptance Criteria**:
- ✅ Each converter produces accurate lunar dates
- ✅ Handles edge cases (leap years, month transitions)
- ✅ Supports both native script and Latin transliteration
- ✅ Well-tested with known date conversions

**Estimated Effort**: 10-15 hours (complex astronomical calculations)

#### 5.3 Lunar Calendar Settings
**File**: `Views/LunarCalendarSettingsView.swift` (NEW)

- [ ] Add to Settings wheel:
  - [ ] Section: "Lunar Calendar"
  - [ ] Picker: Select calendar type (Chinese, Islamic, Hebrew, Hindu, None)
  - [ ] Only ONE lunar calendar can be active at a time
  - [ ] Toggle: "Show in month header"
  - [ ] Toggle: "Show on day cells"
  - [ ] Preview of today's lunar date
- [ ] Display options:
  - [ ] Language preference (Native script vs. Latin)
  - [ ] Format preference (Full vs. Compact)
  - [ ] Examples shown for each option

**Acceptance Criteria**:
- ✅ User can select ONE lunar calendar type
- ✅ Can toggle display on/off for different UI areas
- ✅ Preview updates immediately
- ✅ Preferences persist across app launches

**Estimated Effort**: 2-3 hours

#### 5.4 Lunar Calendar Display Integration
**Files**: `CalendarGridView.swift`, `MainCalendarView.swift`

- [ ] Month header display:
  ```
  November 2025
  甲辰年 十月 (Chinese Lunar)
  ```
  - [ ] Show below Gregorian month/year
  - [ ] Smaller font (`.caption` style)
  - [ ] Secondary color
  - [ ] Only show if lunar calendar enabled

- [ ] Day cell display (optional):
  ```
  27    ← Gregorian day
  廿七  ← Lunar day (if enabled)
  ```
  - [ ] Show below Gregorian day number
  - [ ] Very small font (8-9pt)
  - [ ] Only show if "Show on day cells" enabled
  - [ ] May need to adjust cell height

- [ ] Day detail view (when day tapped):
  ```
  Wednesday, November 27, 2025
  甲辰年 十月 廿七 (Year of Dragon)
  ```
  - [ ] Show full lunar date
  - [ ] Include additional info (zodiac, etc.)

- [ ] PDF export integration:
  - [ ] Include lunar dates if enabled
  - [ ] Show in calendar header
  - [ ] Annotate special lunar dates

**Acceptance Criteria**:
- ✅ Lunar dates display correctly in all UI areas
- ✅ Proper formatting for each calendar type
- ✅ Doesn't clutter UI when disabled
- ✅ Works seamlessly with notes and holidays

**Estimated Effort**: 4-5 hours

#### 5.5 Special Lunar Dates Integration
**File**: `Models/LunarSpecialDates.swift` (NEW)

- [ ] Define important lunar dates for each calendar:

  **Chinese Calendar**:
  - [ ] Spring Festival (Chinese New Year) - 正月初一
  - [ ] Lantern Festival - 正月十五
  - [ ] Dragon Boat Festival - 五月初五
  - [ ] Mid-Autumn Festival - 八月十五
  - [ ] Double Ninth Festival - 九月初九

  **Islamic Calendar**:
  - [ ] First of Ramadan
  - [ ] Laylat al-Qadr (Night of Power)
  - [ ] Eid al-Fitr
  - [ ] Day of Arafah
  - [ ] Eid al-Adha
  - [ ] Islamic New Year

  **Hebrew Calendar**:
  - [ ] Rosh Hashanah (New Year)
  - [ ] Yom Kippur
  - [ ] Sukkot
  - [ ] Hanukkah
  - [ ] Purim
  - [ ] Passover (Pesach)

  **Hindu Calendar**:
  - [ ] Diwali
  - [ ] Holi
  - [ ] Navaratri
  - [ ] Janmashtami
  - [ ] Maha Shivaratri

- [ ] Highlight these dates on calendar with emoji indicators
- [ ] Show in holiday list if lunar calendar enabled
- [ ] Include in PDF exports

**Acceptance Criteria**:
- ✅ Major lunar festivals automatically detected
- ✅ Display alongside regional holidays
- ✅ Proper emoji indicators
- ✅ Accurate calculation of moveable festivals

**Estimated Effort**: 3-4 hours

---

## Implementation Order (Recommended - UPDATED)

### Phase 1: Layout & Notes (1-2 weeks)
1. ✅ Fix iPad landscape layout (Priority 1)
2. ✅ Implement notes data model (Priority 2.1)
3. ✅ Create notes UI components (Priority 2.2)
4. ✅ Integrate notes into main UI (Priority 2.3)

**Deliverable**: App with working landscape layout and full notes system.

### Phase 2: Holidays (1-2 weeks)
5. ✅ Expand holiday data model (Priority 3.1)
6. ✅ Implement 3-4 holiday providers (Priority 3.2)
7. ✅ Create holiday settings UI (Priority 3.3)
8. ✅ Integrate holidays into calendar (Priority 3.4)

**Deliverable**: App with multi-region holiday support.

### Phase 3: PDF Export (1-2 weeks)
9. ✅ Create PDF export engine (Priority 4.1)
10. ✅ Implement statistics calculator (Priority 4.3)
11. ✅ Design PDF templates (Priority 4.2)
12. ✅ Add export UI integration (Priority 4.4)

**Deliverable**: Complete app with PDF export functionality.

---

## Technical Considerations

### Data Persistence
- Use `FileManager` for notes (JSON files)
- Use `UserDefaults` for settings (holiday regions, export preferences)
- Consider Core Data if notes volume grows significantly

### Performance
- Lazy load notes (only fetch for visible date range)
- Cache holiday calculations (generate once per year)
- Optimize PDF generation (use background thread)

### Testing
- Unit tests for holiday calculations
- Unit tests for statistics
- UI tests for notes CRUD operations
- Integration test for PDF export

### Accessibility
- VoiceOver labels for all new UI elements
- Dynamic Type support for notes editor
- Proper color contrast in PDFs

---

## Success Metrics

### Phase 1 Complete
- ✅ iPad landscape layout fits all content without scrolling
- ✅ Users can create, edit, delete notes for any day/week
- ✅ Notes persist across app launches
- ✅ Build succeeds with no errors

### Phase 2 Complete
- ✅ Support for 8+ holiday regions
- ✅ Users can enable/disable holiday regions
- ✅ Holidays display correctly on calendar
- ✅ Moveable holidays calculate accurately

### Phase 3 Complete
- ✅ Users can export week/month as PDF
- ✅ PDFs are professionally formatted
- ✅ Export includes notes, holidays, and statistics
- ✅ Share sheet works with Files, Mail, etc.

---

## File Structure (After Completion)

```
Vecka/
├── Models/
│   ├── CalendarModels.swift          (existing)
│   ├── NoteModels.swift              (NEW - Priority 2.1)
│   ├── HolidayModels.swift           (NEW - Priority 3.1)
│   ├── StatisticsCalculator.swift   (NEW - Priority 4.3)
│   └── CountdownModels.swift         (existing)
│
├── Views/
│   ├── MainCalendarView.swift        (UPDATE - Priority 1)
│   ├── CalendarGridView.swift        (UPDATE - Priority 2.3, 3.4)
│   ├── WeekInfoCard.swift            (existing)
│   ├── NotesView.swift               (NEW - Priority 2.2)
│   ├── NoteEditorView.swift          (NEW - Priority 2.2)
│   ├── HolidaySettingsView.swift     (NEW - Priority 3.3)
│   ├── ExportView.swift              (NEW - Priority 4.4)
│   └── SettingsView.swift            (UPDATE - add holiday settings)
│
├── Holidays/
│   ├── HolidayProvider.swift         (NEW - Priority 3.1)
│   ├── SwedenHolidayProvider.swift   (REFACTOR - Priority 3.2)
│   ├── USAHolidayProvider.swift      (NEW - Priority 3.2)
│   ├── UKHolidayProvider.swift       (NEW - Priority 3.2)
│   ├── IslamicHolidayProvider.swift  (NEW - Priority 3.2)
│   ├── JewishHolidayProvider.swift   (NEW - Priority 3.2)
│   └── CustomHolidayProvider.swift   (NEW - Priority 3.2)
│
├── Export/
│   ├── PDFGenerator.swift            (NEW - Priority 4.1)
│   └── PDFTemplates.swift            (NEW - Priority 4.2)
│
├── Managers/
│   ├── NotesManager.swift            (NEW - Priority 2.1)
│   └── HolidayManager.swift          (NEW - Priority 3.1)
│
└── Core/
    ├── WeekCalculator.swift          (existing)
    └── DesignSystem.swift            (existing)
```

---

## Dependencies

### New Frameworks Required
- **PDFKit** (built-in) - For PDF generation
- **UniformTypeIdentifiers** (built-in) - For file type handling

### No External Dependencies
- All features implemented using iOS SDK
- No third-party libraries required

---

## Risks & Mitigation

### Risk: PDF Generation Performance
**Mitigation**: Generate PDFs on background thread, show progress indicator

### Risk: Holiday Calculation Complexity
**Mitigation**: Use well-tested algorithms, add comprehensive unit tests

### Risk: Notes Data Loss
**Mitigation**: Implement backup/restore, use reliable persistence (FileManager)

### Risk: UI Complexity in Landscape
**Mitigation**: Prototype layouts first, test on real iPads early

---

## Future Enhancements (Beyond Current Scope)

- iCloud sync for notes
- Share notes with other users
- Recurring notes templates
- Week goals and habit tracking
- Calendar integration (iOS Calendar events)
- Reminders integration
- Widgets showing notes/holidays
- Watch app with week notes
- Siri shortcuts for adding notes
- Machine learning for note suggestions

---

## Version Targeting

**Current Version**: 1.0 (Calendar + Countdowns)
**Target Version**: 2.0 (Notes + Holidays + Export)

**Release Plan**:
- v1.1 - Landscape layout + Notes (Phase 1)
- v1.5 - International holidays (Phase 2)
- v2.0 - PDF Export (Phase 3)

---

## Questions for Clarification

1. Should notes support rich text (bold, italic, lists)?
2. Maximum note length?
3. Should holidays be downloaded or bundled in app?
4. PDF export: Single week per page or multiple weeks?
5. Should notes be searchable?
6. Need to support note attachments (photos)?

---

**Last Updated**: 2025-11-27
**Status**: Ready for development
**Owner**: Nils Johansson
**AI Assistants**: Claude & Gemini compatible format
