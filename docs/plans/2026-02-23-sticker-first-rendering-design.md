# Sticker-First Rendering Design

**Date**: 2026-02-23
**Status**: Approved

## Goal

Replace all bare `Image(systemName:)` content icon zones with `JohoSticker` rendering. Every category/type icon in the app should look like a bold sticker badge: colored background + white icon.

## Previous Attempt

Commit `ffb14ff` attempted this in one shot across 13 files. It was reverted (`db31aee`) due to:
1. Compilation error: `zone.background` missing `for: colorMode` parameter
2. Visual mismatch: JohoSticker uses inverted (white) icons but many zones used accent-colored icons on light backgrounds
3. Layout conflicts with `.frame(maxWidth: .infinity)` stretching
4. Too many files in one commit

## Design Decisions

- **Full sticker style**: All icon zones convert to colored-bg + white-icon (no tinted mode)
- **Size presets**: `.mini(24pt)`, `.small(32pt)`, `.regular(48pt)`, `.large(80pt)` factory methods
- **Default shape**: Squircle (changed from circle)
- **Incremental commits**: One file per commit, build verification after each

## Scope

### CONVERT (25-30 zones across 14 view files + 3 components)

**Design System Components** (update internally):
- JohoIconBadge — bare Image -> JohoSticker
- JohoEditorHeader — 52pt icon zone -> JohoSticker
- JohoEmptyState — 80pt icon zone -> JohoSticker.large

**View Files** (in order of complexity):
1. SettingsView — 2 page header icon zones
2. ContactListView — 1 page header icon zone
3. PhoneLibraryView — 1 page header icon zone
4. ModernCalendarView — 1 page header icon zone
5. DashboardView — 2 zones (page header + DataCard)
6. LandingPageView — 2 zones (page header + fact tile)
7. ShareableCard — 1 bento compartment
8. DayDetailSheet — 1 bento compartment
9. CountdownListView — 4 zones (header + 3 bento compartments)
10. CountdownViews — 1 countdown card icon
11. DayDashboardView — 2-3 zones (summary tiles + shareable card)
12. SpecialDaysListView — ~8 zones (headers, month tiles, day cards)
13. ContactDetailView — 3-4 zones (bento headers, hero icons)
14. TripListView — 1 editor header icon zone

### SKIP (not converted)
- Inline chevrons, action buttons, status indicators (~150 instances)
- Widget code
- JohoListRow, JohoFormSection, JohoSearchField internals
- Preview code
