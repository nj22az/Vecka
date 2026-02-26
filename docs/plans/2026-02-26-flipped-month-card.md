# Flipped Month Card Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Flip the Star page month card layout so month name is in the upper colored compartment and JohoSticker + message + dots are in the lower white compartment.

**Architecture:** Modify `monthFlipcard` in SpecialDaysListView.swift. Upper compartment becomes text-on-color (48pt). Lower compartment becomes sticker+message+dots-on-white (56pt) with HStack layout.

**Tech Stack:** SwiftUI, JohoSticker, JohoFont, MonthTheme, CategoryColorSettings

---

### Task 1: Flip the upper compartment to month name text

**Files:**
- Modify: `Vecka/Views/SpecialDaysListView.swift:1153-1159`

**Step 1: Replace the sticker icon zone with month name text**

In `monthFlipcard(for:)`, replace the TOP section (lines ~1153-1159):

```swift
// BEFORE:
// TOP: Icon zone
JohoSticker.small(icon: displayIcon, color: displayIconColor)
    .frame(maxWidth: .infinity)
    .frame(height: 64)
    .background(displayColor)

// AFTER:
// TOP: Month name on seasonal color
Text(theme.name.uppercased())
    .font(JohoFont.pillLabel)
    .foregroundStyle(colors.primary)
    .frame(maxWidth: .infinity)
    .frame(height: 48)
    .background(displayColor)
```

**Step 2: Build and verify**

Run: `./build.sh build`
Expected: BUILD SUCCEEDED

### Task 2: Flip the lower compartment to sticker + message + dots

**Files:**
- Modify: `Vecka/Views/SpecialDaysListView.swift:1166-1217`

**Step 1: Replace the bottom section with HStack layout**

Replace the BOTTOM section (lines ~1166-1217) with:

```swift
// BOTTOM: Sticker + message + dots
HStack(spacing: JohoDimensions.spacingSM) {
    // Leading: Sticker
    JohoSticker.small(icon: displayIcon, color: displayIconColor)

    // Center: Custom message
    if let message {
        Text(message)
            .font(.system(size: 9, weight: .medium, design: .rounded))
            .foregroundStyle(colors.primary.opacity(0.6))
            .lineLimit(1)
    }

    Spacer(minLength: 0)
}
.padding(.horizontal, JohoDimensions.spacingSM)
.frame(maxWidth: .infinity)
.frame(height: 56)
.background(colors.surface)
.overlay(alignment: .bottomTrailing) {
    // Category dot indicators
    if hasItems {
        VStack(spacing: 3) {
            if counts.holidays > 0 {
                Circle()
                    .fill(CategoryColorSettings.shared.color(for: .holiday))
                    .frame(width: 7, height: 7)
                    .overlay(Circle().stroke(colors.border, lineWidth: 1))
            }
            if counts.observances > 0 {
                Circle()
                    .fill(CategoryColorSettings.shared.color(for: .observance))
                    .frame(width: 7, height: 7)
                    .overlay(Circle().stroke(colors.border, lineWidth: 1))
            }
            if (counts.birthdays + counts.memos) > 0 {
                Circle()
                    .fill(CategoryColorSettings.shared.color(for: .memo))
                    .frame(width: 7, height: 7)
                    .overlay(Circle().stroke(colors.border, lineWidth: 1))
            }
        }
        .padding(.trailing, 6)
        .padding(.bottom, 6)
    }
}
```

**Step 2: Build and verify**

Run: `./build.sh build`
Expected: BUILD SUCCEEDED

### Task 3: Visual verification on simulator

**Step 1: Run on simulator**

Launch on iPhone simulator and navigate to the Star page. Verify:
- Upper compartment shows month name text on seasonal colored background
- Lower compartment shows JohoSticker on the left, custom message in center (if set), dots on the right
- All 12 month cards align properly in the grid
- Tapping a month still opens the detail view
- Squircle borders and black borders are intact

**Step 2: Commit**

```bash
git add Vecka/Views/SpecialDaysListView.swift
git commit -m "feat(star-page): Flip month card layout - name on top, sticker below"
```
