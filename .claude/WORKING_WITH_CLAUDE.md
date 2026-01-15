# Working with Claude on Onsen Planner

A practical guide for collaborating with Claude Code on this project.

---

## Documentation Map

```
Vecka/
├── CLAUDE.md                      # MAIN: Essential rules (always read)
│
├── .claude/
│   ├── WORKING_WITH_CLAUDE.md     # THIS FILE: How to work with Claude
│   ├── COMPONENT_GLOSSARY.md      # COMPONENTS: All pages, views, reusable parts
│   ├── design-system.md           # UI: Complete 情報デザイン specification
│   └── architecture.md            # CODE: Patterns, models, data flow
│
├── JohoDesignSystem.swift         # IMPLEMENTATION: Design system in code
│
└── Documentation/                 # PROJECT DOCS
    ├── TODO_VECKA_FEATURES.md     # Feature roadmap
    └── REMAINING_ISSUES.md        # Known issues
```

---

## Quick Reference: What to Tell Claude

| Task | What to Say |
|------|-------------|
| **UI work** | "Check `.claude/design-system.md` for the spec" |
| **Match Star Page** | "Use Star Page (`SpecialDaysListView.swift`) as the golden standard" |
| **Find a component** | "Check `.claude/COMPONENT_GLOSSARY.md` for [component]" |
| **Architecture question** | "See `.claude/architecture.md`" |
| **Find a pattern** | "Look at how Star Page does [X]" |
| **Ensure consistency** | "Make this match the Star Page bento pattern" |
| **Unify components** | "See unification priorities in COMPONENT_GLOSSARY.md" |

---

## The Golden Standard: Star Page

**Star Page** (`Vecka/Views/SpecialDaysListView.swift`) is the reference implementation for all UI in Onsen Planner.

### Why Star Page is the Standard

1. **Most refined** - Has gone through multiple design iterations
2. **Complete implementation** - Shows all 情報デザイン patterns
3. **All entry types** - Demonstrates holidays, events, birthdays, notes, trips, expenses
4. **Bento layout** - Compartmentalized rows with walls
5. **Proper headers** - Page header with icon zone + title + controls

### Key Patterns in Star Page

| Pattern | Location in File | Description |
|---------|------------------|-------------|
| **Page Header** | `pageHeader` view | Icon zone + title + year picker |
| **Section Box** | `SectionBox` | Colored sections with header pills |
| **Bento Row** | `itemRow(for:)` | 3-compartment layout with walls |
| **Type Indicators** | `typeIndicatorDot(for:)` | Colored circles with borders |
| **Country Pills** | `CountryPill` | National color text pills |
| **Swipe Actions** | `.swipeActions` | Edit (cyan) / Delete (red) |
| **Editor Sheet** | `EntryEditorSheet` | Consistent header + form pattern |

---

## How to Ask Claude for UI Work

### Making a View Match Star Page

```
"Rework [ViewName] to match Star Page's bento pattern:
- Check SpecialDaysListView.swift for the golden standard
- Use the same page header structure
- Apply compartmentalized rows with vertical walls
- Use JohoColors and proper borders
- Reference .claude/design-system.md for specs"
```

### Specific Pattern Requests

```
"Add a page header to [View] matching Star Page:
- 40pt icon zone with page accent color
- Vertical wall separator
- Title in JohoFont.headline
- Controls on the right"
```

```
"Convert this list to bento rows like Star Page:
- LEFT compartment: indicator circle (28pt)
- CENTER compartment: title text (flexible)
- RIGHT compartment: pills/icons (72pt)
- 1.5pt black walls between compartments"
```

### Before/After Comparison Request

```
"Compare [ViewName] to Star Page and list what needs to change:
1. What patterns are missing?
2. What violates 情報デザイン?
3. What should be refactored?"
```

---

## UI Consistency Checklist

When reworking a view to match Star Page, verify:

### Page Level
- [ ] Uses `johoBackground()` for dark canvas
- [ ] Content in white container with 3pt border
- [ ] Page header matches Star Page structure
- [ ] Max 8pt top padding

### Headers
- [ ] Icon zone: 40×40pt, accent color at 15% opacity
- [ ] Title: `JohoFont.headline`, black text
- [ ] Vertical wall: 1.5pt black separator
- [ ] Controls zone on right

### Rows/Items
- [ ] Bento compartments with walls
- [ ] Type indicator circles (filled, with border)
- [ ] Proper swipe actions (cyan edit, red delete)
- [ ] No white boxes inside colored sections

### Components
- [ ] All borders present (1-3pt based on element)
- [ ] Squircle corners (`style: .continuous`)
- [ ] SF Rounded font throughout
- [ ] Semantic colors only

---

## Views to Rework (Priority Order)

Based on similarity to Star Page functionality:

### Priority 1: Data Display Views
| View | Current State | Target |
|------|---------------|--------|
| `CountdownListView` | Partial | Match Star Page sections |
| `ContactsView` | Basic | Add bento rows |
| `ExpensesView` | Basic | Add bento rows |
| `TripsView` | Basic | Add bento rows |

### Priority 2: Calendar Views
| View | Current State | Target |
|------|---------------|--------|
| `ModernCalendarView` | Good | Verify header pattern |
| `CalendarGridView` | Good | Verify day cells |
| `DayDashboardView` | Partial | Match section pattern |

### Priority 3: Editor Sheets
| View | Current State | Target |
|------|---------------|--------|
| All entry editors | Mixed | Use `JohoEditorHeader` |

---

## Example: Reworking a View

### Step 1: Analyze Current State
```
"Read [ViewName].swift and compare to Star Page.
What patterns are different or missing?"
```

### Step 2: Plan Changes
```
"Create a plan to rework [ViewName] to match Star Page.
List specific changes needed for:
- Page header
- Section structure
- Row/item layout
- Components (pills, indicators, etc.)"
```

### Step 3: Implement
```
"Implement the changes to [ViewName].
Use Star Page as reference. Check .claude/design-system.md for specs.
Show me the key changes."
```

### Step 4: Verify
```
"Run the design audit commands on [ViewName].
Are there any 情報デザイン violations remaining?"
```

---

## Design Audit Commands

Run these to find violations:

```bash
# All forbidden patterns
grep -rn "ultraThinMaterial\|thinMaterial" Vecka/Views/ --include="*.swift"
grep -rn "\.cornerRadius(" Vecka/Views/ --include="*.swift"
grep -rn "Color\.blue\|Color\.red\|Color\.green" Vecka/Views/ --include="*.swift"
grep -rn "LinearGradient\|RadialGradient" Vecka/Views/ --include="*.swift"

# Check specific view
grep -n "cornerRadius\|Material\|Color\." Vecka/Views/[ViewName].swift
```

---

## Prompt Templates

### Full View Rework
```
Rework [ViewName].swift to match Star Page (SpecialDaysListView.swift):

1. First read both files and identify differences
2. Apply Star Page's bento pattern throughout
3. Use proper page header with icon zone
4. Implement compartmentalized rows with walls
5. Follow .claude/design-system.md specifications
6. Run audit commands when done

This view displays [describe content]. Keep the functionality
but update the visual structure to match Star Page exactly.
```

### Quick Fix
```
Fix [ViewName] to use 情報デザイン patterns:
- Replace any raw colors with JohoColors
- Add missing borders
- Use squircle corners
- Check against .claude/design-system.md
```

### Component Extraction
```
The pattern [describe pattern] appears in Star Page.
Extract it as a reusable component in JohoDesignSystem.swift
so other views can use the same implementation.
```

---

## Summary

1. **Star Page is THE golden standard** - Always reference `SpecialDaysListView.swift`
2. **Tell Claude explicitly** - "Use Star Page as reference"
3. **Check the spec** - Point to `.claude/design-system.md`
4. **Verify with audits** - Run grep commands after changes
5. **Rework systematically** - Follow the priority order above
