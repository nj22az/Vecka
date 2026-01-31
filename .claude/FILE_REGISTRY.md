# File Registry

> **Last Updated:** 2026-01-31
> **Complete inventory of all Swift files in Onsen Planner**

---

## Summary

| Category | Count |
|----------|-------|
| **App Swift Files** | 100 |
| **Widget Swift Files** | 12 |
| **Total** | 112 |

---

## Views (44 files)

### Main Pages

| File | Purpose | Feature |
|------|---------|---------|
| `LandingPageView.swift` | Today dashboard | Landing |
| `ModernCalendarView.swift` | Calendar page | Calendar |
| `SpecialDaysListView.swift` | Star page (golden standard) | Special Days |
| `DashboardView.swift` | Tools/workspace page | Tools |
| `ContactListView.swift` | Contact list | Contacts |
| `SettingsView.swift` | Settings page | Settings |

### Notes & Memos

| File | Purpose |
|------|---------|
| `NotesListView.swift` | Notes list view |
| `DailyNotesView.swift` | Daily notes view |
| `MemoEditorView.swift` | Memo editor sheet |

### Events & Countdowns

| File | Purpose |
|------|---------|
| `CountdownListView.swift` | Countdown list |
| `CountdownViews.swift` | Countdown components |
| `EventTaskViews.swift` | Event task views |

### Trips & Expenses

| File | Purpose |
|------|---------|
| `TripListView.swift` | Trip list and editor |
| `ExpenseListView.swift` | Expense list |
| `ExpenseEntryView.swift` | Expense entry editor |

### Contacts

| File | Purpose |
|------|---------|
| `ContactListView.swift` | Contact list |
| `ContactDetailView.swift` | Contact detail view |
| `ContactPickerSheet.swift` | Contact picker |
| `ContactExportSheet.swift` | Contact export sheet |
| `ContactImagePicker.swift` | Contact image picker |
| `DuplicateReviewSheet.swift` | Duplicate contact review |

### Calendar

| File | Purpose |
|------|---------|
| `CalendarGridView.swift` | Month grid display |
| `DayDetailSheet.swift` | Day detail modal |
| `DayDashboardView.swift` | Day overview |
| `SpecialDayDetailSheet.swift` | Special day detail |

### Navigation

| File | Purpose |
|------|---------|
| `SwipeNavigationContainer.swift` | Main navigation container |
| `IconStripSidebar.swift` | iPad left edge sidebar |
| `IconStripDock.swift` | iPad compact dock |
| `PhoneLibraryView.swift` | iPhone library tab |
| `AppSidebar.swift` | Navigation enum + legacy grid |
| `ContentView.swift` | Root content view |

### Editors & Sheets

| File | Purpose |
|------|---------|
| `JohoEditorSheets.swift` | Joho-styled editor sheets |
| `UnifiedEntryCreator.swift` | Multi-type entry creator |
| `SimplePDFExportView.swift` | PDF export view |

### Onboarding & Settings

| File | Purpose |
|------|---------|
| `OnboardingView.swift` | First-run onboarding |
| `RegionSelectionView.swift` | Region picker |
| `RegionQuickPicker.swift` | Quick region picker |
| `EditLandingTitleView.swift` | Landing title editor |
| `HolidayChangeLogView.swift` | Holiday changelog |
| `HolidayDatabaseExplorer.swift` | Holiday database viewer |
| `DeveloperSettings.swift` | Developer settings |

### World Clock

| File | Purpose |
|------|---------|
| `AddWorldClockView.swift` | Add world clock |
| `AnalogClockView.swift` | Analog clock display |

### Shareables & Mascots

| File | Purpose |
|------|---------|
| `ShareableContact.swift` | Shareable contact card |
| `ShareableFact.swift` | Shareable fact card |
| `ShareableCountdown.swift` | Shareable countdown |
| `ShareableDaySummary.swift` | Shareable day summary |
| `QRCodeView.swift` | QR code generator |
| `KaomojiMascot.swift` | Kaomoji mascot |
| `OnsenRobotMascot.swift` | Onsen robot mascot |
| `GeometricMascotView.swift` | Geometric mascot |

### Utilities

| File | Purpose |
|------|---------|
| `SOSGestureModifier.swift` | SOS gesture handling |

---

## Models (11 SwiftData + Supporting)

### SwiftData Models

| File | Models | Purpose |
|------|--------|---------|
| `Memo.swift` | `DailyNote` | Personal memos |
| `HolidayRule.swift` | `HolidayRule` | Holiday definitions |
| `CalendarRule.swift` | `CalendarRule` | Calendar rules |
| `CountdownModels.swift` | `CountdownEvent` | Countdown events |
| `ContactModels.swift` | 8 models | Contact data |
| `SpecialDayTypes.swift` | Entry type enums | Type definitions |
| `EntryType.swift` | `EntryType` | Entry type enum |

### Pure Swift Models

| File | Purpose |
|------|---------|
| `CalendarModels.swift` | Calendar data structures |
| `ConfigurationModels.swift` | App configuration |
| `WorldClock.swift` | World clock data |
| `WorldCityDatabase.swift` | City timezone database |
| `CalendarFact.swift` | Calendar facts |
| `QuirkyFacts.swift` | Quirky calendar facts |
| `HolidaySymbolCatalog.swift` | Holiday symbol mappings |
| `HolidayChangeLog.swift` | Holiday change tracking |
| `DuplicateSuggestion.swift` | Duplicate detection |

---

## Services (11 files)

| File | Purpose |
|------|---------|
| `ContactsManager.swift` | Contact management |
| `ContactExportService.swift` | Contact export (PDF, VCF) |
| `DuplicateContactManager.swift` | Duplicate detection |
| `ConfigurationManager.swift` | App configuration |
| `LunarCalendarService.swift` | Lunar calendar conversion |
| `SimplePDFRenderer.swift` | PDF export service |
| `PDFRenderer.swift` | Detailed PDF rendering |
| `PDFExportModels.swift` | PDF export data models |
| `CSVExportService.swift` | CSV export |
| `EntryTypeDetector.swift` | Entry type detection |
| `RandomFactProvider.swift` | Random fact generation |
| `WorldClockSync.swift` | World clock sync |

---

## Core (4 files)

| File | Purpose |
|------|---------|
| `WeekCalculator.swift` | ISO 8601 week calculation |
| `PersonnummerParser.swift` | Swedish ID parsing |
| `HolidayRegionSelection.swift` | Region selection logic |
| `AppInitializer.swift` | App initialization |

---

## Managers (2 files in Models/)

| File | Purpose |
|------|---------|
| `HolidayManager.swift` | Holiday calculation |
| `CalendarManager.swift` | Calendar rule management |
| `HolidayEngine.swift` | Holiday calculation engine |

---

## Design System (3 files)

| File | LOC | Purpose |
|------|-----|---------|
| `JohoDesignSystem.swift` | ~4000 | All Joho* components |
| `JohoSymbols.swift` | - | Symbol definitions |
| `Haptics.swift` | - | Haptic feedback |

---

## Intents (4 files)

| File | Purpose |
|------|---------|
| `CurrentWeekIntent.swift` | "What week is it?" |
| `WeekForDateIntent.swift` | Week for specific date |
| `WeekOverviewIntent.swift` | Week overview |
| `AppShortcuts.swift` | Shortcut definitions |

---

## Utilities

| File | Purpose |
|------|---------|
| `Localization.swift` | i18n strings |
| `ViewUtilities.swift` | View helpers |
| `Log.swift` | Logging utilities |
| `CountdownBanner.swift` | Countdown banner |
| `WeekPickerSheet.swift` | Week picker |
| `MonthPickerSheet.swift` | Month picker |
| `VeckaApp.swift` | App entry point |

---

## Widget Files (12)

### Core Widget

| File | Purpose |
|------|---------|
| `VeckaWidget.swift` | Widget entry point |
| `Provider.swift` | Timeline provider |
| `Theme.swift` | Widget theme |
| `WidgetHolidayEngine.swift` | Widget holiday calc |
| `WidgetRandomFact.swift` | Random fact for widget |
| `SharedWorldClock.swift` | Shared world clock data |

### Widget Views

| File | Purpose |
|------|---------|
| `SmallWidgetView.swift` | Small widget (week #) |
| `MediumWidgetView.swift` | Medium widget (+ calendar row) |
| `LargeWidgetView.swift` | Large widget (full calendar) |
| `WorldClockWidgetView.swift` | World clock widget |

### Widget Components

| File | Purpose |
|------|---------|
| `DayCell.swift` | Day cell component |
| `BackgroundPattern.swift` | Background patterns |

---

## Directory Structure

```
Vecka/
├── Core/                    # 4 files - Week calculation
├── Models/                  # 15 files - SwiftData + managers
├── Views/                   # 44 files - SwiftUI views
├── Services/                # 11 files - External integrations
├── Intents/                 # 4 files - Siri Shortcuts
├── JohoDesignSystem.swift   # Design system (~4000 LOC)
├── JohoSymbols.swift        # Symbol definitions
├── Haptics.swift            # Haptic feedback
├── Localization.swift       # i18n
├── VeckaApp.swift           # Entry point
└── ...utilities

VeckaWidget/
├── Views/                   # 4 widget views
├── Components/              # 2 shared components
├── VeckaWidget.swift        # Entry point
├── Provider.swift           # Timeline provider
├── Theme.swift              # Widget theme
└── ...supporting files
```

---

## See Also

- `.claude/GOLDEN_STANDARD.md` — Authoritative design reference
- `.claude/COMPONENT_GLOSSARY.md` — Component details
- `.claude/architecture.md` — Technical structure
