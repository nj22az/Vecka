# Month Detail Category Cards — Bento Redesign

**Date:** 2026-03-19
**Scope:** Restyle the 3 category cards on the Star page month detail view
**File:** `Vecka/Views/Holidays/SpecialDaysMonthDetail.swift`

## Problem

The category cards (Holidays, Observances, Memos) on the month detail view use a "big color block + small label" pattern that doesn't match the two-compartment bento card pattern used everywhere else in the app. They look disconnected, waste vertical space, and leave the bottom 60% of the screen empty.

## Design

### Card Structure (matches DataCard pattern from DashboardView)

```
┌─[sticker] HOLIDAYS─────────5─┐  ← tinted banner header
├───────────────────────────────┤  ← 1.5pt border divider
│  Jan 1    New Year's Day      │
│  Jan 6    Epiphany            │
│  May 1    Labour Day          │
│  +2 more                      │  ← if count > 3
└───────────────────────────────┘
```

**Header row:**
- `JohoSticker(content: .icon(displayIcon), color: categoryColor, size: 28)` — left
- Uppercase bold label: `.font(JohoFont.headerTag)`, `.tracking(1)` — after sticker
- Count pill right-aligned: "\(count)" in `JohoFont.labelBold`
- Background: `categoryColor.opacity(0.15)` (tinted banner)

**Divider:** `Rectangle().fill(colors.border).frame(height: 1.5)`

**Content area:**
- Up to 3 preview rows from the category's day cards
- Each row: short date (e.g., "May 1") left-aligned + item name right of date
- Font: `JohoFont.bodySmall` for date, `JohoFont.body` for name
- If more than 3 items: "+N more" row in `colors.secondary`
- Padding: `spacingMD` all sides

**Outer container:**
- `radiusMedium` corner radius (`.continuous`)
- `borderMedium` stroke width (1.5pt) in `colors.border`
- `colors.surface` background

### Layout

- Full-width vertical stack (not 3-column grid)
- `VStack(spacing: spacingSM)` with `.padding(.horizontal, spacingLG)`
- Cards render top to bottom: Holidays, Observances, Memos (in that order, skipping empty)

### Empty Categories

Hidden entirely. Only render cards for categories where count > 0.

### Interaction

Tap anywhere on card → sets `selectedCategory` (existing behavior unchanged).

## Decisions

- Preview rows use the first 3 items from `filteredDayCards(category)`, taking the first row from each day card's items
- Date format: `DateFormatterCache.monthDay` for preview dates (e.g., "May 1")
- No animation changes — existing `easeInOut(duration: 0.2)` kept
- No logic changes — only `categoryCardsGrid` and `categoryCard()` view builders replaced
