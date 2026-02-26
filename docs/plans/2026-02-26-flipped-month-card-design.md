# Flipped Month Card Design

## Goal

Redesign the Star page month grid cards so the month name leads in the upper colored compartment and the JohoSticker icon moves to the lower white compartment alongside custom message text and category dots.

## Architecture

Modify the `monthFlipcard` function in `SpecialDaysListView.swift` to flip the two compartments. Upper becomes text-on-color (48pt), lower becomes sticker+message+dots-on-white (56pt). No new components needed — uses existing `JohoSticker.small` and the same customization model.

## Layout

```
+-------------------------+
| ### FEBRUARY ########## |  <- 48pt, seasonal color bg
|                         |    month name centered, pillLabel font
+-------------------------+  <- 1.5pt black divider
|                         |
| [S]  ski trip!    *     |  <- 56pt, white/surface bg
|                   *     |    sticker left, message center, dots right
|                   *     |
+-------------------------+
```

### Upper Compartment (48pt, seasonal color)
- Background: `theme.lightBackground` (seasonal — LOCKED, users cannot change)
- Content: Month name, uppercased, `JohoFont.pillLabel`, centered horizontally and vertically
- No sticker, no message — pure typography

### Divider
- `Rectangle().fill(colors.border).frame(height: 1.5)` — unchanged

### Lower Compartment (56pt, white)
- Background: `colors.surface`
- HStack layout:
  - **Leading**: `JohoSticker.small(icon: displayIcon, color: displayIconColor)` — 32pt squircle with black border
  - **Center**: Custom message text (`message ?? " "`) — 9pt medium rounded, muted opacity
  - **Trailing**: Vertical dot stack (holiday/observance/memo circles with black stroke)
- Padding: `spacingSM` horizontal for breathing room

### Customization (unchanged)
- Icon: user-customizable via `customIcon(for: month)`
- Icon color: user-customizable via `customIconColor(for: month)`, falls back to `theme.accentColor`
- Background color: LOCKED to `theme.lightBackground`
- Message: user-customizable via `customMessage(for: month)`

## What Changes vs What Stays

| Element | Before | After |
|---------|--------|-------|
| Upper content | JohoSticker icon (64pt) | Month name text (48pt) |
| Upper background | Seasonal color | Seasonal color (same) |
| Lower content | Month name + dots (48pt) | Sticker + message + dots (56pt) |
| Lower background | White | White (same) |
| Total height | 112pt + divider | 104pt + divider |
| Outer border | johoBordered squircle | Same |
| Tap gesture | selectedMonth = month | Same |
| Dot indicators | Vertical stack, bottom-right | Same position, same logic |

## File Scope

Single file: `Vecka/Views/SpecialDaysListView.swift`, function `monthFlipcard(for:)` (lines ~1132-1228).

No new files, no new components, no model changes.
