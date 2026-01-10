# 情報デザイン Violations - Detailed Fix List

## Category 1: RAW SYSTEM COLORS (19 violations)

### File: HolidayChangeLogView.swift

**Lines 181-188** (actionColor computed property)
```swift
// ❌ CURRENT
private var actionColor: Color {
    switch entry.action {
    case .created: return Color.green
    case .modified: return Color.orange
    case .deleted: return Color.red
    case .enabled: return Color.green
    case .disabled: return Color.gray
    case .reset: return Color.blue
    case .migrated: return Color.purple
    case .defaultsLoaded: return Color.cyan
    }
}

// ✅ FIX
private var actionColor: Color {
    switch entry.action {
    case .created: return JohoColors.green
    case .modified: return JohoColors.orange
    case .deleted: return JohoColors.red
    case .enabled: return JohoColors.green
    case .disabled: return JohoColors.black.opacity(0.4)
    case .reset: return Color(hex: "4338CA")  // Calendar accent
    case .migrated: return JohoColors.purple
    case .defaultsLoaded: return JohoColors.cyan
    }
}
```

**Lines 340-347** (duplicate - same fix as above)

---

### File: HolidayDatabaseExplorer.swift

**Line 928**
```swift
// ❌ CURRENT
.foregroundStyle(Color.blue)

// ✅ FIX
.foregroundStyle(PageHeaderColor.calendar.accent)
```

---

## Category 2: MISSING .design(.rounded) - TOP 30 FILES

### Quick Fix Pattern
Search: `\.font\(\.system\(size: (\d+), weight: (\.\w+)\)\)`
Replace: `.font(.system(size: $1, weight: $2, design: .rounded))`

### File-by-File List

#### ContactListView.swift (44 violations)
- Line 241: `.font(.system(size: 20, weight: .bold))`
- Line 274: `.font(.system(size: 14, weight: .bold))`
- Line 320: `.font(.system(size: 16, weight: .bold))`
- Line 340: `.font(.system(size: 16, weight: .bold))`
- Line 358: `.font(.system(size: 16, weight: .bold))`
- Line 391: `.font(.system(size: 10, weight: .bold))`
- Line 402: `.font(.system(size: 10, weight: .bold))`
- Line 432: `.font(.system(size: 40, weight: .bold))`
- Line 461: `.font(.system(size: 18, weight: .bold))`
- Line 481: `.font(.system(size: 14, weight: .bold))`
- Line 593: `.font(.system(size: 10, weight: .bold))`
- Line 624: `.font(.system(size: 10, weight: .bold))`
- Line 684: `.font(.system(size: 11, weight: .bold))`
- Line 716: `.font(.system(size: 14, weight: .black))`
- Line 845: `.font(.system(size: 12, weight: .bold))`
- Line 952-963: Multiple 10pt bold instances
- Line 975: `.font(.system(size: 12, weight: .bold))`
- Line 1085: `.font(.system(size: decorationBadgeSize * 0.5, weight: .bold))`
- Line 1156: `.font(.system(size: 14, weight: .bold))`
- Line 1173: `.font(.system(size: 9, weight: .bold))`
- Lines 1241-1431: Multiple violations

**Action:** Add `, design: .rounded` to all 44 instances

---

#### ContactDetailView.swift (30+ violations)
Similar pattern - add `, design: .rounded` to all `.font(.system())` calls

---

#### SpecialDaysListView.swift (40+ violations)
**Note:** Some use `design: .monospaced` which is intentional for data display
- Lines with `.monospaced` - KEEP AS IS
- All others - add `, design: .rounded`

---

#### DashboardView.swift (5 violations)
- Line 391: `.font(.system(size: 24, weight: .medium))`

---

#### OnsenRobotMascot.swift (4 violations)
- Line 93: `.font(.system(size: antennaSize, weight: .medium))`
- Line 185: `.font(.system(size: handSize, weight: .bold))`
- Line 349: `.font(.system(size: 20, weight: .bold))`

---

## Category 3: EXCESSIVE TOP PADDING (17 violations)

| File | Line | Current | Fix |
|------|------|---------|-----|
| DayDetailSheet.swift | 34 | `spacingMD` (12pt) | `spacingSM` (8pt) |
| CountdownListView.swift | 107 | `spacingLG` (16pt) | `spacingSM` (8pt) |
| SimplePDFExportView.swift | 55 | `spacingLG` (16pt) | `spacingSM` (8pt) |
| ContactDetailView.swift | 1702 | `spacingMD` (12pt) | `spacingSM` (8pt) |
| ContactDetailView.swift | 2485 | `spacingMD` (12pt) | `spacingSM` (8pt) |
| HolidayDatabaseExplorer.swift | 916 | `spacingMD` (12pt) | `spacingSM` (8pt) |
| NotesListView.swift | 94 | `spacingXL` (20pt) | `spacingSM` (8pt) |
| ContactPickerSheet.swift | 212 | `spacingLG` (16pt) | `spacingSM` (8pt) |
| WeekDetailPanel.swift | 33 | `spacingLG` (16pt) | `spacingSM` (8pt) |
| JohoEditorSheets.swift | 114 | `spacingLG` (16pt) | `spacingSM` (8pt) |
| TripListView.swift | 104 | `spacingXL` (20pt) | `spacingSM` (8pt) |
| OnboardingView.swift | 153 | `spacingMD` (12pt) | `spacingSM` (8pt) |
| IconStripSidebar.swift | 54 | `spacingMD` (12pt) | `spacingSM` (8pt) |
| SpecialDaysListView.swift | 1042 | `spacingXL` (20pt) | `spacingSM` (8pt) |
| SpecialDaysListView.swift | 2044 | `spacingXL` (20pt) | `spacingSM` (8pt) |
| ExpenseListView.swift | 219 | `spacingMD` (12pt) | `spacingSM` (8pt) |
| AppSidebar.swift | 90 | `spacingMD` (12pt) | `spacingSM` (8pt) |

### Bulk Fix Command
```bash
# Find all instances (review before replacing)
grep -rn "\.padding(\.top, JohoDimensions\.spacingMD)" Vecka/Views/
grep -rn "\.padding(\.top, JohoDimensions\.spacingLG)" Vecka/Views/
grep -rn "\.padding(\.top, JohoDimensions\.spacingXL)" Vecka/Views/
```

**Manual Review Needed:** Some may require parent container adjustments instead of simple replacement.

---

## VALIDATION CHECKLIST

After fixes, verify:

```bash
cd /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka

# Should return 0
echo "Raw colors:"
grep -rn "Color\.blue\|Color\.red\|Color\.green" Vecka/Views/ --include="*.swift" | grep -v "JohoColors" | grep -v "//" | wc -l

# Should return 0 (excluding .monospaced intentional cases)
echo "Missing .rounded:"
grep -rn "\.font(\.system" Vecka/Views/ --include="*.swift" | grep -v "design: .rounded" | grep -v "design: .monospaced" | grep -v "//" | wc -l

# Should return 0
echo "Excessive top padding:"
grep -rn "\.padding(\.top," Vecka/Views/ --include="*.swift" | grep -E "spacingXL|spacingLG|spacingMD" | grep -v "//" | wc -l
```

---

## ESTIMATED FIX TIME

| Priority | Task | Time | Difficulty |
|----------|------|------|------------|
| P1 | Raw colors (19 instances) | 15 min | Easy |
| P2 | Missing .rounded (200+ instances) | 60-90 min | Mechanical |
| P3 | Excessive padding (17 instances) | 30-45 min | Medium |

**Total:** 2-3 hours for systematic fixes
