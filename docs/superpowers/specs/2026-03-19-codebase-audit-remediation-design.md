# Codebase Audit Remediation — Design Spec

**Date:** 2026-03-19
**Scope:** Fix all 400+ issues found in structural audit across 7 categories
**Strategy:** One branch per category, merged sequentially, build-tested between each

## Phase Order (safest → riskiest)

### Phase 1: Dead Code Removal
Remove 5 unused `@State` variables and 6 unused `ViewUtilities` functions.
Files: ExpenseListView, ContactListView, ModernCalendarView, SpecialDaysListView, ViewUtilities.

### Phase 2: Naming Standardization
- Rename 14 `get*` methods to Swift-idiomatic names (drop `get` prefix)
- Rename 16 vague variables (`result`, `data`, `dict`, `item`, `idx`)
- Add descriptive names to Easter algorithm variables in HolidayEngine + WidgetHolidayEngine
- Standardize: all SwiftUI views end with `View` suffix

### Phase 3: Hardcoded Value Extraction
- Replace ~50 hardcoded SF Symbol strings with `IconCatalog` constants (add new constants as needed)
- Replace hardcoded `Color(hex:)` in Views with `JohoColors` references (PDF renderer, ConfigurationManager weekday colors, SpecialDayTypes)
- Extract country flag colors from JohoComponents into a `CountryFlagTheme` structure
- Extract `Task.sleep` durations into named constants

### Phase 4: Folder Restructure (Option A — domain-aligned)
Create:
- `Vecka/DesignSystem/` — move 7 Joho*.swift files from root
- `Vecka/Views/Calendar/` — 6 files
- `Vecka/Views/Entries/` — 9 files (memos, expenses, trips, countdowns)
- `Vecka/Views/Contacts/` — 3 files
- `Vecka/Views/Holidays/` — 6 files
- `Vecka/Views/Landing/` — 2 files
- `Vecka/Views/Sharing/` — 6 files
- `Vecka/Views/Settings/` — 3 files
- `Vecka/Views/Common/` — 9 files
Move `CountdownModels.swift` → `Models/`, `HolidayManager.swift` → `Services/`
Update all Xcode project references.

### Phase 5: Worst File Split (SpecialDaysListView.swift → 5 files)
- `SpecialDaysGridView.swift` — Month grid overview
- `SpecialDaysMonthDetail.swift` — Single month expanded view
- `SpecialDayCard.swift` — Individual day card component
- `SpecialDayEditor.swift` — Edit/create/delete logic
- `SpecialDaysDataProvider.swift` — Query management + caching (ObservableObject)
Keep `SpecialDaysListView.swift` as the coordinator that composes these.

### Phase 6: Scalability Fixes
- Add `FetchDescriptor` predicates to unfiltered `@Query` statements
- Cache expensive computed properties in `@State` (memoColors, filter chains)
- Replace `try?` with `do/catch` + logging in data operations
- Add thumbnail generation for contact photos on import

### Phase 7: Documentation
- Write `README.md` covering: what the app does, how to run, folder structure, design system overview

## Decisions Made
- **Branch strategy:** One branch per phase, build-tested before merge
- **Folder structure:** Option A (8 domain-aligned View subfolders)
- **Entries grouping:** Memos + Notes + Expenses + Trips + Countdowns in one folder (all Memo model variants)
- **No shortcuts:** Full restructure, every file in the right place
