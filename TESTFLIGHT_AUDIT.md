# Vecka App – TestFlight Audit and Action Plan

This document summarizes a TestFlight-style audit of the Vecka app and widget, the fixes applied in this pass, and the remaining items to reach a polished beta.

## Summary
- Picker UI simplified: single selection, cleaner sections, swipe actions for secondary operations.
- Favorites and custom events are fully manageable (add/remove, delete customs).
- Countdown banner now computes relative to the selected day/week and avoids number/label mismatch.
- Calendar usage standardized toward `Calendar.iso8601` for reliable week math.
- Fixed compile/runtime issues spotted during audit.

---

## Changes Implemented

- Gesture and UIKit correctness
  - Replaced non-existent `value.velocity` with `predictedEndTranslation`.
    - File: `Vecka/WeekCalendarStrip.swift:270`
  - Added `import UIKit` where UIKit types are used.
    - Files: `Vecka/ContentView.swift:1`, `Vecka/VeckaApp.swift:1`

- Countdown consistency
  - Banner calculates days relative to `selectedDate` and shows absolute number with a clear subtitle (“TODAY/TOMORROW/PASSED”).
    - File: `Vecka/ContentView.swift:480`

- ISO-8601 standardization
  - Color-of-day and weekday computations use `Calendar.iso8601` to match ISO week logic used across the app.
    - Files: `Vecka/DesignSystem.swift:44`, `Vecka/WeekCalendarStrip.swift:156`, `Vecka/WeekCalendarStrip.swift:246`, `Vecka/VeckaApp.swift:63`, `Vecka/VeckaApp.swift:73`

- Favorites and custom events
  - Favorites: star button on rows; swipe-to-remove in favorites section.
  - Custom events: swipe-to-delete; also prunes from favorites and falls back selection if deleted.
    - File: `Vecka/CountdownComponents.swift`
  - Limited to max 4 favorites and 2 custom events; safe persistence in `UserDefaults`.
  - Custom dialog includes a Lucid icon picker; icon saved with the event and shown in UI.

- Settings favorites grid
  - Avoids decoding `UserDefaults` in view builders; caches selected custom in state.
    - File: `Vecka/SettingsView.swift`

---

## Issues Discovered (Beta-Test View) and Status

1) Countdown number vs label mismatch (PASSED vs 0)
- Status: Fixed. Banner shows absolute day count; subtitle communicates direction (“PASSED”/“TOMORROW”).
- Area: `Vecka/ContentView.swift`.

2) Inconsistent Calendar usage (ISO vs current)
- Status: Partially fixed. Switched key locations to ISO. Review remaining `Calendar.current` usages for consistency where ISO rules matter (week math, weekday coloring).
- Areas to re-check: `CountdownCard.daysUntilCountdown` (OK to keep current), any other `Calendar.current` if week semantics matter.

3) Favorites management unobvious / incomplete
- Status: Fixed. Star buttons on rows; swipe to remove favorites; swipe to delete customs; collapsible sections to reduce clutter.
- Area: `Vecka/CountdownComponents.swift`.

4) Custom events deletion
- Status: Fixed. Swipe-to-delete in Custom Events; removes from favorites; safe fallback if current selection deleted.

5) Localization gaps
- Status: Pending. New strings to add to `Localizable.strings` in all languages:
  - "Favorites %d/4", "Predefined", "Custom Events", "Create Custom…", "Favorite", "Unfavorite", "Delete", "Remove", "Manage Events…", empty-state hints.

6) Accessibility announcements
- Status: Pending polish. Favoriting/unfavoriting should announce state change via VoiceOver (accessibilityValue). Rows have labels; add value updates for star toggles.

7) Widget calendar authorization
- Status: Acceptable with note. Widget shows no events if the app has not been granted Calendar access. Add onboarding tip in app Settings explaining this.

8) Orientation
- Status: Intentional. iPhone portrait-only; iPad supports landscape. Verify this matches product goals.

9) Midnight updates in foreground
- Status: Pending nice-to-have. Add a midnight timer to refresh the countdown banner without user interaction.

---

## Action Plan (Next Changes)

1) Calendar consistency sweep
- Replace any ISO-relevant `Calendar.current` with `Calendar.iso8601` where week semantics matter.
- Verify weekday-color mapping is as desired under ISO weekday numbers.

2) Localization
- Add the new UI strings in all `*.lproj/Localizable.strings`.
- Quick pass to avoid English-only strings.

3) Accessibility polish
- Add `accessibilityValue` for favorite state on rows and announce on toggle.
- Confirm Dynamic Type layout for the picker and banner (XL/XXL).

4) UX tweaks (optional but recommended)
- Selected summary row at top of the picker for clarity.
- Edit/Reorder favorites (drag-and-drop) if needed.
- Banner midnight timer.

---

## Manual Test Checklist

- Picker
  - Expand/Collapse sections; add/remove favorites; delete a custom; create a custom; select any event; Save/Cancel behaviors.
- Settings
  - Favorites grid shows up to 4; selection updates banner after closing.
- Banner
  - Switch days/weeks; countdown updates; test events that are in the past, today, and future.
- Widget
  - With calendar access vs without; timeline refresh at midnight.
- Accessibility
  - VoiceOver navigation of picker and banner; Increase Contrast; Dynamic Type XL/XXL.
- Localization
  - Swedish, English, others: spot-check strings and date formats.

---

## Notes
- Persistence
  - Keys: `favoriteCountdowns`, `customCountdowns`, `selectedCountdownType`, `selectedCustomCountdown`.
- Limits
  - Favorites: 4 max (oldest trimmed). Custom events: 2 max (oldest trimmed).

---

## Appendices
- Lucid icon set for customs uses SF Symbols: `sparkles`, `tree.fill`, `sun.max.fill`, `heart.fill`, `moon.stars.fill`, `leaf.fill`, `gift.fill`, `calendar`, `party.popper`, `star.fill`.

