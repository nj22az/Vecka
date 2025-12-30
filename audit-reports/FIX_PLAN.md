# WeekGrid Fix Plan - Prioritized Action Items

**Date**: 2025-12-30
**Based on**: Master Audit Report (6-agent analysis)
**Total Estimated Effort**: 25-30 hours

---

## Priority Levels

| Priority | Definition | Timeline |
|----------|------------|----------|
| P0 | Critical - Before TestFlight | This week |
| P1 | High - Before App Store | Next 2 weeks |
| P2 | Medium - Post-launch polish | 1 month |
| P3 | Low - Nice to have | Backlog |

---

## P0 - Critical (Before TestFlight)

### 1. Reduce Force Unwraps (204 → <20)
**Effort**: 4-6 hours
**Risk**: App crashes in production

**Focus Areas:**
| File | Count | Action |
|------|-------|--------|
| Widget Provider.swift | 4 | Guard let + fallback UI |
| HolidayManager.swift | 16 | Optional chaining |
| DayDashboardView.swift | 19 | Safe unwrap patterns |
| ExpenseEntryView.swift | 10 | Optional binding |

**Example Fix:**
```swift
// Before (line 47)
let date = calendar.date(from: components)!

// After
guard let date = calendar.date(from: components) else {
    Log.w("Failed to create date from components")
    return Date()
}
```

### 2. Expand Accessibility (32 → 100+ annotations)
**Effort**: 4-6 hours
**Risk**: App Store rejection, poor accessibility experience

**Priority Files:**
1. **ModernCalendarView.swift** - Add 15+ labels
2. **DayDashboardView.swift** - Add 20+ labels
3. **Widget views** - Add 10+ labels
4. **AppSidebar.swift** - Add hints to icons

**Example:**
```swift
// Add to day cells
.accessibilityLabel("\(day.formatted(.dateTime.day().weekday())) \(holiday?.name ?? "")")
.accessibilityHint("Double tap to view details")
.accessibilityAddTraits(isToday ? .isSelected : [])
```

### 3. Widget Permission Feedback
**Effort**: 30-45 minutes
**Risk**: Users confused why events missing

**Implementation:**
```swift
// In Provider.swift
if eventStore.authorizationStatus(for: .event) != .authorized {
    entry.calendarAccessDenied = true
}

// In Widget view
if entry.calendarAccessDenied {
    Text("Calendar access needed")
        .font(.caption)
}
```

---

## P1 - High Priority (Before App Store)

### 4. Typography Token Migration
**Effort**: 2-3 hours
**Location**: 45 occurrences across 16 files

**Steps:**
1. Find all `.font(.system(size:))` usages
2. Map to Typography constants
3. Replace with `Typography.*`

**Mapping Table:**
| Current | Replace With |
|---------|--------------|
| `.font(.system(size: 11))` | `Typography.caption` |
| `.font(.system(size: 13))` | `Typography.captionLarge` |
| `.font(.system(size: 15))` | `Typography.body` |
| `.font(.system(size: 17))` | `Typography.bodyLarge` |
| `.font(.system(size: 20))` | `Typography.headline` |
| `.font(.largeTitle)` | `Typography.title` |

### 5. Spacing Token Migration
**Effort**: 2-3 hours
**Location**: ~500 hardcoded padding values

**Steps:**
1. Replace `.padding(.horizontal, 16)` → `.padding(.horizontal, Spacing.medium)`
2. Replace `.padding(.vertical, 8)` → `.padding(.vertical, Spacing.small)`
3. Document any intentional non-standard values

**Mapping Table:**
| Current | Replace With |
|---------|--------------|
| `padding(4)` | `Spacing.tiny` |
| `padding(8)` | `Spacing.small` |
| `padding(12)` | `Spacing.compact` |
| `padding(16)` | `Spacing.medium` |
| `padding(24)` | `Spacing.large` |
| `padding(32)` | `Spacing.xl` |

### 6. GlassCard Component Adoption
**Effort**: 4-6 hours
**Benefit**: Consistent iOS 26 Liquid Glass across app

**Files to Update:**
- OverviewDashboardView.swift (8 occurrences)
- DayDashboardView.swift (3 occurrences)
- WeekDetailPanel.swift (2 occurrences)

**Example:**
```swift
// Before
VStack {
    content
}
.background(.ultraThinMaterial)
.cornerRadius(16)

// After
GlassCard(elevation: .medium) {
    content
}
```

### 7. Consolidate Color Systems
**Effort**: 2 hours
**Risk**: Maintenance burden with dual systems

**Steps:**
1. Audit SlateColors vs AppColors usage
2. Create unified `DesignColors` namespace
3. Migrate views to single system

### 8. P0 Critical Tests (36 tests)
**Effort**: 2 weeks (can parallel with other work)

**Test Files to Create:**
| File | Tests | Focus |
|------|-------|-------|
| ManagerCachingTests.swift | 12 | Holiday/Countdown/Calendar managers |
| SwiftDataPersistenceTests.swift | 14 | CRUD, migrations, cascade |
| InputValidationTests.swift | 10 | Boundaries, edge cases |

---

## P2 - Medium Priority (Post-Launch Polish)

### 9. Widget Color Deduplication
**Effort**: 2 hours

Extract shared colors to file included in both targets:
```swift
// SharedColors.swift (in both targets)
struct PlanetaryColors {
    static let monday = Color(hex: "#C0C0C0")
    // ...
}
```

### 10. Fix IconStripSidebar Touch Target
**Effort**: 15 minutes
**Issue**: 32x32pt icons below 44pt minimum

```swift
// Line 112: Increase from 32 to 40pt
.frame(width: 40, height: 40)
.contentShape(Rectangle())
```

### 11. Localize Remaining Strings
**Effort**: 1-2 hours
**Files**: CountdownBanner.swift, SettingsView.swift

Add to Localizable.strings:
```
"settings.title" = "Settings";
"countdown.days_until" = "%d days until";
// etc.
```

### 12. Standardize to 8pt Grid
**Effort**: 2 hours
**Issue**: ~25% of padding values are non-8pt

**Non-standard values to fix:**
- PhoneLibraryView.swift:82 - 14pt → 16pt
- ExpenseListView.swift:437 - 6pt → 8pt
- DayDashboardView.swift:412 - 6pt → 8pt
- DayDashboardView.swift:111, 194 - 10pt → 8pt or 12pt

### 13. Animation Constants Centralization
**Effort**: 1 hour

Add to DesignSystem.swift:
```swift
extension Animation {
    static let smoothNavigation = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let standardTransition = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let quickFeedback = Animation.spring(response: 0.2, dampingFraction: 0.9)
}
```

---

## P3 - Low Priority (Backlog)

### 14. P1 Integration Tests (30 tests)
**Effort**: 2 weeks

- Week Calculation Integration (8)
- Holiday Accuracy Tests (12)
- Service Integration Tests (10)

### 15. P2 Polish Tests (20 tests)
**Effort**: 1 week

- UI Accessibility Tests (8)
- Performance Benchmarks (6)
- Snapshot Tests (6)

### 16. Equatable Conformance for Heavy Views
**Files**: CalendarGridView, DayDashboardView, WeekDetailPanel
**Benefit**: Reduced unnecessary redraws

### 17. @Observable Migration
**Current**: 8 ObservableObject classes
**Target**: Migrate to @Observable macro for Swift 6

---

## Quick Wins (Do First)

These can be done in 15 minutes or less:

| Task | Time | Impact |
|------|------|--------|
| Settings title localization | 5 min | Polish |
| IconStripSidebar touch target | 5 min | HIG |
| Consolidate 3 duplicate color helpers | 15 min | Clean |

---

## Implementation Order

### Week 1: TestFlight Ready
- [ ] P0.1 Force unwraps in Widget Provider (1 hour)
- [ ] P0.1 Force unwraps in HolidayManager (2 hours)
- [ ] P0.2 Accessibility in calendar views (3 hours)
- [ ] P0.3 Widget permission feedback (45 min)
- [ ] Quick wins (30 min)

### Week 2: Polish
- [ ] P0.1 Remaining force unwraps (2 hours)
- [ ] P0.2 Widget accessibility (2 hours)
- [ ] P1.4 Typography migration (3 hours)
- [ ] P1.5 Spacing migration (3 hours)

### Week 3-4: Tests & Cleanup
- [ ] P1.8 Start P0 critical tests
- [ ] P1.6 GlassCard adoption
- [ ] P1.7 Color consolidation
- [ ] P2 items as time permits

---

## Metrics to Track

| Metric | Current | Target | Date |
|--------|---------|--------|------|
| Force unwraps | 204 | <20 | Week 1 |
| Accessibility annotations | 44 | 100+ | Week 1 |
| Typography token adoption | 0% | 100% | Week 2 |
| Spacing token adoption | <1% | 80%+ | Week 2 |
| Test coverage | 15% | 40%+ | Week 4 |

---

## Success Criteria

**TestFlight Ready:**
- [ ] Force unwraps < 20
- [ ] Accessibility annotations > 100
- [ ] Widget shows permission feedback
- [ ] Build: 0 errors, 0 warnings

**App Store Ready:**
- [ ] All Typography tokens used
- [ ] Spacing tokens at 80%+ adoption
- [ ] GlassCard used consistently
- [ ] P0 critical tests passing
- [ ] No critical bugs in manager caching

---

*Generated from 6-agent audit findings*
