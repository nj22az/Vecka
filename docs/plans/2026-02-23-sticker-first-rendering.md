# Sticker-First Rendering Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace all bare `Image(systemName:)` content icon zones with `JohoSticker` rendering so every category/type icon looks like a bold sticker badge (colored background + white icon).

**Architecture:** Enhance `JohoSticker` with size presets and squircle default, then update 3 design system components internally, then convert 13 view files one at a time with build verification after each.

**Tech Stack:** SwiftUI, JohoDesignSystem (JohoSticker, JohoIconBadge, JohoEditorHeader, JohoEmptyState)

---

## Task 1: Enhance JohoSticker — Default Shape and Size Presets

**Files:**
- Modify: `Vecka/JohoComponents.swift` (JohoSticker struct, ~line 781)

**Step 1: Change default shape from `.circle` to `.squircle`**

In `JohoSticker`, change line ~805:
```swift
// OLD:
var shape: StickerShape = .circle

// NEW:
var shape: StickerShape = .squircle
```

**Step 2: Add thin border for small sizes**

In `JohoSticker`, update `resolvedBorderWidth` (~line 813):
```swift
// OLD:
private var resolvedBorderWidth: CGFloat {
    borderWidth ?? (size >= 80 ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
}

// NEW:
private var resolvedBorderWidth: CGFloat {
    borderWidth ?? (size >= 80 ? JohoDimensions.borderThick :
                    size < 32 ? JohoDimensions.borderThin :
                    JohoDimensions.borderMedium)
}
```

**Step 3: Add size preset factory methods**

After the `stickerShape` property (before the closing `}` of JohoSticker), add:
```swift
// MARK: - Size Presets

/// 24pt — bento card headers, compact inline icons
static func mini(icon: String, color: Color, shape: StickerShape = .squircle) -> JohoSticker {
    JohoSticker(content: .icon(icon), color: color, shape: shape, size: 24)
}

/// 32pt — compact list rows, tile icons
static func small(icon: String, color: Color, shape: StickerShape = .squircle) -> JohoSticker {
    JohoSticker(content: .icon(icon), color: color, shape: shape, size: 32)
}

/// 48pt — prominent card icons, fact tiles, shareable card headers
static func regular(icon: String, color: Color, shape: StickerShape = .squircle) -> JohoSticker {
    JohoSticker(content: .icon(icon), color: color, shape: shape, size: 48)
}

/// 80pt — hero displays, empty states
static func large(icon: String, color: Color, shape: StickerShape = .squircle) -> JohoSticker {
    JohoSticker(content: .icon(icon), color: color, shape: shape, size: 80)
}
```

**Step 4: Build**

Run: `./build.sh build`
Expected: Clean build, no errors.

**Step 5: Commit**

```bash
git add Vecka/JohoComponents.swift
git commit -m "feat(sticker): Add size presets and squircle default to JohoSticker"
```

---

## Task 2: Update JohoIconBadge to Use JohoSticker Internally

**Files:**
- Modify: `Vecka/JohoComponents.swift` (JohoIconBadge struct, ~line 758)

**Step 6: Replace JohoIconBadge body with JohoSticker**

```swift
// OLD (lines 767-774):
var body: some View {
    Image(systemName: icon)
        .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
        .foregroundStyle(zone.textColor(for: colorMode))
        .frame(width: size, height: size)
        .background(zone.background(for: colorMode))
        .johoBordered(cornerRadius: size * 0.25, borderWidth: JohoDimensions.borderThin, borderColor: colors.border)
}

// NEW:
var body: some View {
    JohoSticker(
        content: .icon(icon),
        color: zone.background(for: colorMode),
        size: size,
        borderWidth: JohoDimensions.borderThin
    )
}
```

**Step 7: Build**

Run: `./build.sh build`
Expected: Clean build. JohoIconBadge callers (JohoToggleRow, etc.) unchanged.

**Step 8: Commit**

```bash
git add Vecka/JohoComponents.swift
git commit -m "refactor(sticker): JohoIconBadge now renders through JohoSticker"
```

---

## Task 3: Update JohoEditorHeader to Use JohoSticker

**Files:**
- Modify: `Vecka/JohoComponents.swift` (JohoEditorHeader struct, ~line 622)

**Step 9: Replace editor header icon zone with JohoSticker**

```swift
// OLD (lines 649-654):
// Icon zone (52×52pt) - matches January 2026 pattern
Image(systemName: icon)
    .font(JohoFont.displaySmall)
    .foregroundStyle(accentColor)
    .frame(width: 52, height: 52)
    .background(lightBackground)
    .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)

// NEW:
// Icon zone (52×52pt) - sticker-first rendering
JohoSticker(content: .icon(icon), color: accentColor, size: 52)
```

**Step 10: Build**

Run: `./build.sh build`
Expected: Clean build. All editor sheets (Add Event, Add Trip, etc.) now show sticker icons.

**Step 11: Commit**

```bash
git add Vecka/JohoComponents.swift
git commit -m "refactor(sticker): JohoEditorHeader icon zone uses JohoSticker"
```

---

## Task 4: Update JohoEmptyState to Use JohoSticker

**Files:**
- Modify: `Vecka/JohoComponents.swift` (JohoEmptyState struct, ~line 1299)

**Step 12: Replace empty state icon zone with JohoSticker.large**

```swift
// OLD (lines 1311-1316):
Image(systemName: icon)
    .font(.system(size: 48, weight: .bold, design: .rounded))
    .foregroundStyle(zone.textColor(for: colorMode))
    .frame(width: 80, height: 80)
    .background(zone.background(for: colorMode))
    .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)

// NEW:
JohoSticker.large(icon: icon, color: zone.background(for: colorMode))
```

**Step 13: Build**

Run: `./build.sh build`
Expected: Clean build. All empty states now render through JohoSticker.

**Step 14: Commit**

```bash
git add Vecka/JohoComponents.swift
git commit -m "refactor(sticker): JohoEmptyState icon zone uses JohoSticker.large"
```

---

## Task 5: SettingsView — Page Header + Personalization Icons

**Files:**
- Modify: `Vecka/SettingsView.swift` (lines ~154 and ~725)

**Step 15: Replace settings page header icon zone**

```swift
// OLD (lines 153-163):
// Icon zone with Settings accent color (Slate Blue)
Image(systemName: IconCatalog.settings)
    .font(JohoFont.title)
    .foregroundStyle(PageHeaderColor.settings.accent)
    .frame(width: 40, height: 40)
    .background(PageHeaderColor.settings.lightBackground)
    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
    .overlay(
        Squircle(cornerRadius: JohoDimensions.radiusSmall)
            .stroke(colors.border, lineWidth: 1.5)
    )

// NEW:
// Icon zone with Settings accent color (Slate Blue)
JohoSticker(content: .icon(IconCatalog.settings), color: PageHeaderColor.settings.accent, size: 40)
```

**Step 16: Replace personalization section icon zone**

```swift
// OLD (lines 724-734):
// Icon zone
Image(systemName: IconCatalog.textFormat)
    .font(JohoFont.title)
    .foregroundStyle(PageHeaderColor.landing.accent)
    .johoTouchTarget()
    .background(PageHeaderColor.landing.lightBackground)
    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
    .overlay(
        Squircle(cornerRadius: JohoDimensions.radiusSmall)
            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
    )

// NEW:
// Icon zone
JohoSticker(content: .icon(IconCatalog.textFormat), color: PageHeaderColor.landing.accent, size: 40)
```

**Step 17: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 18: Commit**

```bash
git add Vecka/SettingsView.swift
git commit -m "refactor(sticker): SettingsView icon zones use JohoSticker"
```

---

## Task 6: ContactListView — Page Header Icon

**Files:**
- Modify: `Vecka/Views/ContactListView.swift` (~line 168)

**Step 19: Replace contacts page header icon zone**

```swift
// OLD (lines 167-173):
// Icon zone with Contacts accent color (Warm Brown)
Image(systemName: IconCatalog.people)
    .font(JohoFont.title)
    .foregroundStyle(PageHeaderColor.contacts.accent)
    .frame(width: 40, height: 40)
    .background(PageHeaderColor.contacts.lightBackground)
    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)

// NEW:
// Icon zone with Contacts accent color (Warm Brown)
JohoSticker(content: .icon(IconCatalog.people), color: PageHeaderColor.contacts.accent, size: 40)
```

**Step 20: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 21: Commit**

```bash
git add Vecka/Views/ContactListView.swift
git commit -m "refactor(sticker): ContactListView header icon uses JohoSticker"
```

---

## Task 7: ModernCalendarView — Page Header Icon

**Files:**
- Modify: `Vecka/Views/ModernCalendarView.swift` (~line 820)

**Step 22: Replace calendar page header icon zone**

```swift
// OLD (lines 819-825):
// 情報デザイン: Purple calendar icon (app identity)
Image(systemName: IconCatalog.calendar)
    .font(JohoFont.title)
    .foregroundStyle(PageHeaderColor.calendar.accent)
    .frame(width: 40, height: 40)
    .background(PageHeaderColor.calendar.lightBackground)
    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)

// NEW:
// 情報デザイン: Purple calendar icon sticker (app identity)
JohoSticker(content: .icon(IconCatalog.calendar), color: PageHeaderColor.calendar.accent, size: 40)
```

**Step 23: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 24: Commit**

```bash
git add Vecka/Views/ModernCalendarView.swift
git commit -m "refactor(sticker): ModernCalendarView header icon uses JohoSticker"
```

---

## Task 8: DashboardView — Page Header + DataCard Icons

**Files:**
- Modify: `Vecka/Views/DashboardView.swift` (~lines 83 and 690)

**Step 25: Replace data page header icon zone**

```swift
// OLD (lines 82-88):
// Icon zone with Tools accent color (Teal)
Image(systemName: IconCatalog.chartBar)
    .font(JohoFont.title)
    .foregroundStyle(PageHeaderColor.tools.accent)
    .frame(width: 40, height: 40)
    .background(PageHeaderColor.tools.lightBackground)
    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)

// NEW:
// Icon zone with Tools accent color (Teal)
JohoSticker(content: .icon(IconCatalog.chartBar), color: PageHeaderColor.tools.accent, size: 40)
```

**Step 26: Replace DataCard header icon zone**

```swift
// OLD (lines 689-695):
// Icon zone - uses SectionZone background for proper semantic color
Image(systemName: icon)
    .font(JohoFont.bodySmallBold)
    .foregroundStyle(zone.textColor(for: colorMode))
    .frame(width: 28, height: 28)
    .background(zone.background(for: colorMode))
    .johoBordered(cornerRadius: JohoDimensions.radiusChip, borderWidth: 1)

// NEW:
// Icon zone - JohoSticker for sticker-first rendering
JohoSticker(content: .icon(icon), color: zone.background(for: colorMode), size: 28)
```

**Step 27: Build**

Run: `./build.sh build`
Expected: Clean build. Verify DataCard still compiles (it uses `zone.background(for: colorMode)` — correct API).

**Step 28: Commit**

```bash
git add Vecka/Views/DashboardView.swift
git commit -m "refactor(sticker): DashboardView icon zones use JohoSticker"
```

---

## Task 9: LandingPageView — Page Header + Fact Tile Icons

**Files:**
- Modify: `Vecka/Views/LandingPageView.swift` (~lines 210 and 551)

**Step 29: Replace landing page header icon zone**

```swift
// OLD (lines 209-215):
// Icon zone with Landing accent color (Warm Amber)
Image(systemName: IconCatalog.home)
    .font(JohoFont.title)
    .foregroundStyle(PageHeaderColor.landing.accent)
    .frame(width: 40, height: 40)
    .background(PageHeaderColor.landing.lightBackground)
    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)

// NEW:
// Icon zone with Landing accent color (Warm Amber)
JohoSticker(content: .icon(IconCatalog.home), color: PageHeaderColor.landing.accent, size: 40)
```

**Step 30: Replace random fact tile icon zone**

```swift
// OLD (lines 549-557):
// TOP: Icon zone (情報デザイン: Strong color like Star page month icons)
VStack {
    Image(systemName: fact.icon ?? IconCatalog.holiday)
        .font(JohoFont.displaySmall)
        .foregroundStyle(fact.color.readableForeground)
}
.frame(maxWidth: .infinity)
.frame(height: 48)
.background(fact.color.opacity(JohoDimensions.opacityMild))

// NEW:
// TOP: Icon zone (情報デザイン: Sticker-first rendering)
JohoSticker.small(icon: fact.icon ?? IconCatalog.holiday, color: fact.color)
    .frame(maxWidth: .infinity)
    .frame(height: 48)
```

**Step 31: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 32: Commit**

```bash
git add Vecka/Views/LandingPageView.swift
git commit -m "refactor(sticker): LandingPageView icon zones use JohoSticker"
```

---

## Task 10: ShareableCard — Bento Compartment Icon

**Files:**
- Modify: `Vecka/Views/ShareableCard.swift` (~line 158)

**Step 33: Replace shareable card header right icon**

```swift
// OLD (lines 157-162):
// RIGHT: Icon
Image(systemName: icon)
    .font(JohoFont.headline)
    .foregroundStyle(iconColor)
    .frame(width: 48)
    .frame(maxHeight: .infinity)

// NEW:
// RIGHT: Icon sticker
JohoSticker.small(icon: icon, color: iconColor)
    .frame(width: 48)
    .frame(maxHeight: .infinity)
```

**Step 34: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 35: Commit**

```bash
git add Vecka/Views/ShareableCard.swift
git commit -m "refactor(sticker): ShareableCard header icon uses JohoSticker"
```

---

## Task 11: DayDetailSheet — Bento Decoration Icon

**Files:**
- Modify: `Vecka/Views/DayDetailSheet.swift` (~line 271)

**Step 36: Replace day detail decoration icon**

```swift
// OLD (lines 270-276):
// RIGHT: Decoration icon with colored background
Image(systemName: icon)
    .font(JohoFont.headlineSmall)
    .foregroundStyle(colors.primaryInverted)
    .frame(width: 28, height: 28)
    .background(color)
    .johoBordered(cornerRadius: 7, borderWidth: 1.5)

// NEW:
// RIGHT: Decoration icon sticker
JohoSticker(content: .icon(icon), color: color, size: 28)
```

Note: Keep the `.frame(width: 52).frame(maxHeight: .infinity).background(colors.surface)` modifiers that follow on subsequent lines — they control the compartment sizing, not the icon.

**Step 37: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 38: Commit**

```bash
git add Vecka/Views/DayDetailSheet.swift
git commit -m "refactor(sticker): DayDetailSheet decoration icon uses JohoSticker"
```

---

## Task 12: CountdownListView — Header + 3 Bento Compartment Icons

**Files:**
- Modify: `Vecka/Views/CountdownListView.swift` (~lines 72, 148, 326, 434)

**Step 39: Replace events page header icon (line ~72)**

```swift
// OLD (lines 71-77):
// Icon zone (52×52pt) - matches Star Page month detail pattern
Image(systemName: IconCatalog.event)
    .font(JohoFont.displaySmall)
    .foregroundStyle(colors.primary)
    .johoTouchTarget(52)
    .background(JohoColors.purple.opacity(JohoDimensions.opacityMedium))
    .johoBordered()

// NEW:
// Icon zone (52×52pt) - sticker-first rendering
JohoSticker(content: .icon(IconCatalog.event), color: JohoColors.purple, size: 52)
```

**Step 40: Build and verify**

Run: `./build.sh build`
Expected: Clean build.

**Step 41: Replace next-up hero card right compartment icon (line ~148)**

```swift
// OLD (lines 147-152):
// RIGHT: Event icon compartment (uses actual event icon)
Image(systemName: event.icon)
    .font(JohoFont.headlineSmall)
    .foregroundStyle(colors.primary)
    .frame(width: 40)
    .frame(maxHeight: .infinity)

// NEW:
// RIGHT: Event icon compartment (sticker-first)
JohoSticker.mini(icon: event.icon, color: JohoColors.purple)
    .frame(width: 40)
    .frame(maxHeight: .infinity)
```

**Step 42: Build and verify**

Run: `./build.sh build`
Expected: Clean build.

**Step 43: Replace section header right compartment icon (line ~326)**

```swift
// OLD (lines 325-330):
// RIGHT: Icon compartment
Image(systemName: icon)
    .font(JohoFont.headlineSmall)
    .foregroundStyle(colors.primary)
    .frame(width: 40)
    .frame(maxHeight: .infinity)

// NEW:
// RIGHT: Icon compartment sticker
JohoSticker.mini(icon: icon, color: JohoColors.purple)
    .frame(width: 40)
    .frame(maxHeight: .infinity)
```

**Step 44: Build and verify**

Run: `./build.sh build`
Expected: Clean build.

**Step 45: Replace event row decoration icon (line ~434)**

```swift
// OLD (lines 433-443):
// RIGHT COMPARTMENT: Decoration icon (fixed 48pt, centered)
// 情報デザイン: Decoration icon ALWAYS shown (user decision)
HStack(spacing: 4) {
    Image(systemName: icon ?? IconCatalog.event)
        .font(JohoFont.bodySmallBold)
        .foregroundStyle(JohoColors.cyan)
        .frame(width: 24, height: 24)
        .background(JohoColors.cyan.opacity(JohoDimensions.opacityLight))
        .johoBordered(cornerRadius: JohoDimensions.radiusChip, borderWidth: 1)
}
.frame(width: 48, alignment: .center)
.frame(maxHeight: .infinity)

// NEW:
// RIGHT COMPARTMENT: Decoration icon sticker
// 情報デザイン: Decoration icon ALWAYS shown (user decision)
JohoSticker.mini(icon: icon ?? IconCatalog.event, color: JohoColors.cyan)
    .frame(width: 48, alignment: .center)
    .frame(maxHeight: .infinity)
```

**Step 46: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 47: Commit**

```bash
git add Vecka/Views/CountdownListView.swift
git commit -m "refactor(sticker): CountdownListView icon zones use JohoSticker"
```

---

## Task 13: CountdownViews — Countdown Card Icon

**Files:**
- Modify: `Vecka/Views/CountdownViews.swift` (~lines 51-75)

**Step 48: Replace countdown card icon and remove helper properties**

Replace the `countdownIcon` computed property and delete `iconBackgroundColor` and `iconForegroundColor`:

```swift
// OLD (lines 51-75):
private var countdownIcon: some View {
    ZStack {
        Circle()
            .fill(iconBackgroundColor)
            .frame(width: 50, height: 50)

        Image(systemName: iconName)
            .font(.system(size: 24, weight: .medium, design: .rounded))
            .foregroundStyle(iconForegroundColor)
    }
}

private var iconBackgroundColor: Color {
    if isSelected {
        return JohoColors.cyan.opacity(JohoDimensions.opacityMild)
    }

    return colors.primary.opacity(JohoDimensions.opacityHeavy).opacity(JohoDimensions.opacitySubtle)
}

private var iconForegroundColor: Color {
    if isSelected {
        return JohoColors.cyan
    }
    // (continues...)

// NEW:
private var countdownIcon: some View {
    JohoSticker(
        content: .icon(iconName),
        color: isSelected ? JohoColors.cyan : colors.primary.opacity(0.3),
        shape: .circle,
        size: 48
    )
}
```

Delete the `iconBackgroundColor` and `iconForegroundColor` computed properties entirely.

**Step 49: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 50: Commit**

```bash
git add Vecka/Views/CountdownViews.swift
git commit -m "refactor(sticker): CountdownCard icon uses JohoSticker"
```

---

## Task 14: DayDashboardView — Summary Card Tiles

**Files:**
- Modify: `Vecka/Views/DayDashboardView.swift` (~line 302)

**Step 51: Replace summary card tile icon zone**

```swift
// OLD (lines 303-317):
// TOP: Icon zone with colored background
ZStack {
    // Icon with subtle shadow for contrast on light backgrounds
    Image(systemName: item.icon)
        .font(.system(size: 18, weight: .black, design: .rounded))
        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityLight))
        .offset(x: 0.5, y: 0.5)

    Image(systemName: item.icon)
        .font(.system(size: 18, weight: .black, design: .rounded))
        .foregroundStyle(item.color)
}
.frame(maxWidth: .infinity)
.frame(height: 36)
.background(item.color.opacity(JohoDimensions.opacityMedium))

// NEW:
// TOP: Icon zone with sticker
JohoSticker.small(icon: item.icon, color: item.color)
    .frame(maxWidth: .infinity)
    .frame(height: 36)
```

**Step 52: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 53: Commit**

```bash
git add Vecka/Views/DayDashboardView.swift
git commit -m "refactor(sticker): DayDashboardView summary tiles use JohoSticker"
```

---

## Task 15: SpecialDaysListView — Page Header Icons

**Files:**
- Modify: `Vecka/Views/SpecialDaysListView.swift` (~lines 617-633)

**Step 54: Replace star page header icon (month detail view)**

```swift
// OLD (lines 617-626):
if let month = selectedMonth, let theme = theme {
    let headerIcon = customIcon(for: month) ?? theme.icon
    let headerIconColor: Color = customIconColor(for: month).map { Color(hex: $0) } ?? theme.accentColor

    Image(systemName: headerIcon)
        .font(.system(size: 20, weight: .bold, design: .rounded))
        .foregroundStyle(headerIconColor)
        .johoTouchTarget()
        .background(theme.lightBackground)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall)

// NEW:
if let month = selectedMonth, let theme = theme {
    let headerIcon = customIcon(for: month) ?? theme.icon
    let headerIconColor: Color = customIconColor(for: month).map { Color(hex: $0) } ?? theme.accentColor

    JohoSticker(content: .icon(headerIcon), color: headerIconColor, size: 40)
```

**Step 55: Replace star page header icon (main view)**

```swift
// OLD (lines 627-633):
} else {
    Image(systemName: IconCatalog.holiday)
        .font(.system(size: 20, weight: .bold, design: .rounded))
        .foregroundStyle(PageHeaderColor.specialDays.accent)
        .johoTouchTarget()
        .background(PageHeaderColor.specialDays.lightBackground)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall)
}

// NEW:
} else {
    JohoSticker(content: .icon(IconCatalog.holiday), color: PageHeaderColor.specialDays.accent, size: 40)
}
```

**Step 56: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 57: Commit**

```bash
git add Vecka/Views/SpecialDaysListView.swift
git commit -m "refactor(sticker): SpecialDaysListView page header icons use JohoSticker"
```

---

## Task 16: SpecialDaysListView — Month Flip Card Icons

**Files:**
- Modify: `Vecka/Views/SpecialDaysListView.swift` (~line 1165)

**Step 58: Replace month flip card icon zone**

```swift
// OLD (lines 1163-1172):
// TOP: Icon zone (情報デザイン: Strong accent color on light tint background)
// Fixed height ensures banner dividers align across all cards
VStack {
    Image(systemName: displayIcon)
        .font(JohoFont.displaySmall)
        .foregroundStyle(displayIconColor)
}
.frame(maxWidth: .infinity)
.frame(height: 64)  // Fixed height for aligned banners
.background(displayColor)

// NEW:
// TOP: Icon zone (情報デザイン: Sticker-first rendering)
// Fixed height ensures banner dividers align across all cards
JohoSticker.small(icon: displayIcon, color: displayIconColor)
    .frame(maxWidth: .infinity)
    .frame(height: 64)  // Fixed height for aligned banners
    .background(displayColor)
```

**Step 59: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 60: Commit**

```bash
git add Vecka/Views/SpecialDaysListView.swift
git commit -m "refactor(sticker): SpecialDaysListView month flip card icons use JohoSticker"
```

---

## Task 17: SpecialDaysListView — Category Card Icons

**Files:**
- Modify: `Vecka/Views/SpecialDaysListView.swift` (~line 1336)

**Step 61: Replace category card icon zone**

```swift
// OLD (lines 1334-1343):
// TOP: Icon zone (情報デザイン: Category color background)
// Fixed height ensures banner dividers align across all cards
VStack {
    Image(systemName: displayIcon)
        .font(JohoFont.displaySmall)
        .foregroundStyle(colors.primary)
}
.frame(maxWidth: .infinity)
.frame(height: 64)  // Fixed height for aligned banners
.background(categoryColor)

// NEW:
// TOP: Icon zone (情報デザイン: Sticker-first rendering)
// Fixed height ensures banner dividers align across all cards
JohoSticker.small(icon: displayIcon, color: categoryColor)
    .frame(maxWidth: .infinity)
    .frame(height: 64)  // Fixed height for aligned banners
    .background(categoryColor)
```

**Step 62: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 63: Commit**

```bash
git add Vecka/Views/SpecialDaysListView.swift
git commit -m "refactor(sticker): SpecialDaysListView category card icons use JohoSticker"
```

---

## Task 18: SpecialDaysListView — Section Header Right Icons (specialDaySection)

**Files:**
- Modify: `Vecka/Views/SpecialDaysListView.swift` (~line 1719)

**Step 64: Replace specialDaySection header right icon**

```swift
// OLD (lines 1718-1723):
// RIGHT: Icon compartment
Image(systemName: icon)
    .font(JohoFont.headlineSmall)
    .foregroundStyle(colors.primary)
    .frame(width: 40)
    .frame(maxHeight: .infinity)

// NEW:
// RIGHT: Icon compartment sticker
JohoSticker.mini(icon: icon, color: zone.background(for: colorMode))
    .frame(width: 40)
    .frame(maxHeight: .infinity)
```

**Step 65: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 66: Commit**

```bash
git add Vecka/Views/SpecialDaysListView.swift
git commit -m "refactor(sticker): SpecialDaysListView specialDaySection header uses JohoSticker"
```

---

## Task 19: SpecialDaysListView — Section Header Right Icons (consolidatedHolidaySection)

**Files:**
- Modify: `Vecka/Views/SpecialDaysListView.swift` (~line 1779)

**Step 67: Replace consolidatedHolidaySection header right icon**

```swift
// OLD (lines 1778-1783):
// RIGHT: Icon compartment
Image(systemName: icon)
    .font(JohoFont.headlineSmall)
    .foregroundStyle(colors.primary)
    .frame(width: 40)
    .frame(maxHeight: .infinity)

// NEW:
// RIGHT: Icon compartment sticker
JohoSticker.mini(icon: icon, color: zone.background(for: colorMode))
    .frame(width: 40)
    .frame(maxHeight: .infinity)
```

**Step 68: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 69: Commit**

```bash
git add Vecka/Views/SpecialDaysListView.swift
git commit -m "refactor(sticker): SpecialDaysListView consolidatedHolidaySection header uses JohoSticker"
```

---

## Task 20: SpecialDaysListView — Day Card Header Icons

**Files:**
- Modify: `Vecka/Views/SpecialDaysListView.swift` (~lines 2100 and 2207)

**Step 70: Replace collapsed day card header icon**

```swift
// OLD (lines 2099-2102):
// LEFT: Icon + Date grouped
HStack(spacing: 6) {
    Image(systemName: icon)
        .font(JohoFont.bodySmallBold)
        .foregroundStyle(iconColor)

// NEW:
// LEFT: Icon sticker + Date grouped
HStack(spacing: 6) {
    JohoSticker.mini(icon: icon, color: iconColor)
```

**Step 71: Replace expanded day card header icon**

```swift
// OLD (lines 2206-2209):
HStack(spacing: 6) {
    Image(systemName: icon)
        .font(JohoFont.bodySmallBold)
        .foregroundStyle(iconColor)

// NEW:
HStack(spacing: 6) {
    JohoSticker.mini(icon: icon, color: iconColor)
```

**Step 72: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 73: Commit**

```bash
git add Vecka/Views/SpecialDaysListView.swift
git commit -m "refactor(sticker): SpecialDaysListView day card header icons use JohoSticker"
```

---

## Task 21: ContactDetailView — Bento Badge Header Icons

**Files:**
- Modify: `Vecka/Views/ContactDetailView.swift` (~line 906)

**Step 74: Locate the `bentoBadge` or section header helper**

Read the file around line 895-920 to confirm the exact function signature and parameters. This is a reusable helper that renders bento card headers with icon zones.

**Step 75: Replace bento badge header icon zone**

```swift
// OLD (lines 905-911):
// Header banner — 情報デザイン: Colored banner with icon zone
HStack(spacing: JohoDimensions.spacingSM) {
    Image(systemName: icon)
        .font(JohoFont.bodySmallBold)
        .foregroundStyle(iconColor)
        .frame(width: 28, height: 28)
        .background(iconColor.opacity(0.35))
        .johoBordered(cornerRadius: JohoDimensions.radiusChip, borderWidth: 1)

// NEW:
// Header banner — 情報デザイン: Sticker-first icon zone
HStack(spacing: JohoDimensions.spacingSM) {
    JohoSticker(content: .icon(icon), color: iconColor, size: 28)
```

**Step 76: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 77: Commit**

```bash
git add Vecka/Views/ContactDetailView.swift
git commit -m "refactor(sticker): ContactDetailView bento badge headers use JohoSticker"
```

---

## Task 22: ContactDetailView — Birthday Section Icon

**Files:**
- Modify: `Vecka/Views/ContactDetailView.swift` (~line 711)

**Step 78: Replace birthday section standalone icon**

```swift
// OLD (lines 711-713):
Image(systemName: IconCatalog.birthday)
    .font(JohoFont.displaySmall)
    .foregroundStyle(SpecialDayType.birthday.accentColor)

// NEW:
JohoSticker.regular(icon: IconCatalog.birthday, color: SpecialDayType.birthday.accentColor)
```

**Step 79: Build**

Run: `./build.sh build`
Expected: Clean build.

**Step 80: Commit**

```bash
git add Vecka/Views/ContactDetailView.swift
git commit -m "refactor(sticker): ContactDetailView birthday icon uses JohoSticker"
```

---

## Task 23: Final Build Verification

**Step 81: Clean build**

Run: `./build.sh clean && ./build.sh build`
Expected: Clean build with zero errors and zero warnings related to JohoSticker.

**Step 82: Grep for remaining bare icon zones in view files**

Run a search to verify no content icon zones were missed:
```bash
grep -n 'Image(systemName:' Vecka/Views/*.swift Vecka/SettingsView.swift | grep -v '// SKIP\|chevron\|xmark\|plus\|trash\|pencil\|checkmark\|share\|download'
```

Review each remaining hit and confirm it's an action button, inline indicator, or inside a design system component.

**Step 83: Commit the plan document update**

```bash
git add docs/plans/
git commit -m "docs: Add sticker-first rendering design and implementation plan"
```

---

## Task 24: Run on Simulator and Visual Check

**Step 84: Build and run on simulator**

Use Xcode or `mcp__XcodeBuildMCP__build_run_sim` to launch the app.

**Step 85: Check Landing Page**

Navigate to Landing Page. Verify the home icon in the page header is a sticker (colored bg, white icon). Check the random fact tiles show sticker icons.

**Step 86: Check Calendar Page**

Navigate to Calendar. Verify the calendar icon in the header is a sticker.

**Step 87: Check Star Page (Special Days)**

Navigate to Star Page. Verify:
- Page header icon is a sticker
- Month flip card icons show sticker badges
- Category card icons show sticker badges
- Section header right-side icons are mini stickers
- Day card header icons are mini stickers

**Step 88: Check Events Page**

Navigate to Events. Verify:
- Page header icon (52pt purple sticker)
- Next-up hero card right compartment icon
- Section header right compartment icons
- Event row decoration icons (cyan mini stickers)

**Step 89: Check Dashboard**

Navigate to Dashboard. Verify:
- Page header icon (tools/teal sticker)
- All DataCard header icons (28pt stickers matching zone colors)

**Step 90: Check Day Dashboard**

Tap a day. Verify summary card tiles show sticker icons at the top of each tile.

**Step 91: Check Day Detail Sheet**

Tap an item in day view. Verify decoration icon in bento compartment is a sticker.

**Step 92: Check Countdown Card**

Open countdown picker. Verify countdown type cards show circular sticker icons.

**Step 93: Check Settings**

Navigate to Settings. Verify:
- Settings page header icon (slate blue sticker)
- Personalization section icon (amber sticker)

**Step 94: Check Contacts**

Navigate to Contacts. Verify:
- Contacts page header icon (warm brown sticker)

**Step 95: Check Contact Detail**

Open a contact. Verify:
- Birthday section icon is a 48pt sticker
- Bento card header icons are 28pt stickers

**Step 96: Check Shareable Card**

Long-press and share an item. Verify the shareable card header right icon is a sticker.

**Step 97: Check Editor Sheets**

Add a new event/trip. Verify the editor header shows a 52pt sticker icon (from JohoEditorHeader update).

**Step 98: Check Empty States**

Clear filters to find an empty list. Verify empty state icons are 80pt stickers (from JohoEmptyState update).

---

## Task 25: Update Memory and Close

**Step 99: Update MEMORY.md**

Update the "Sticker-First Rendering (planned)" entry to "(completed)":
```markdown
### Sticker-First Rendering (completed)
Every content icon renders through `JohoSticker`. Size presets: .mini(24pt), .small(32pt), .regular(48pt), .large(80pt). Default shape is squircle. Design system components (JohoIconBadge, JohoEditorHeader, JohoEmptyState) also render through JohoSticker internally.
```

**Step 100: Final verification summary**

Create a summary of:
- Total files changed
- Total icon zones converted
- Any remaining bare `Image(systemName:)` instances (should only be action buttons, inline indicators, and form elements)

---

## Reference: Files Changed Summary

| Task | File | Zones | Type |
|------|------|-------|------|
| 1 | JohoComponents.swift (JohoSticker) | 0 | Enhancement |
| 2 | JohoComponents.swift (JohoIconBadge) | 1 | Component |
| 3 | JohoComponents.swift (JohoEditorHeader) | 1 | Component |
| 4 | JohoComponents.swift (JohoEmptyState) | 1 | Component |
| 5 | SettingsView.swift | 2 | Page headers |
| 6 | ContactListView.swift | 1 | Page header |
| 7 | ModernCalendarView.swift | 1 | Page header |
| 8 | DashboardView.swift | 2 | Header + DataCard |
| 9 | LandingPageView.swift | 2 | Header + fact tile |
| 10 | ShareableCard.swift | 1 | Bento compartment |
| 11 | DayDetailSheet.swift | 1 | Bento compartment |
| 12 | CountdownListView.swift | 4 | Header + 3 bento |
| 13 | CountdownViews.swift | 1 | Card icon |
| 14 | DayDashboardView.swift | 1 | Summary tiles |
| 15-20 | SpecialDaysListView.swift | 8 | Headers + cards |
| 21-22 | ContactDetailView.swift | 2 | Bento + birthday |
| **Total** | **13 files** | **~30 zones** | |
