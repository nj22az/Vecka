# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WeekGrid is an iOS app displaying ISO 8601 week numbers with semantic color coding. Built with SwiftUI, SwiftData, and WidgetKit, it features Swedish holiday integration, custom countdowns, and comprehensive Siri Shortcuts support. The app targets iOS 18.0+ and follows **情報デザイン (Jōhō Dezain)** - Japanese Information Design inspired by pharmaceutical packaging.

**Project folder name**: `Vecka` (legacy, kept for backwards compatibility)
**App name**: `WeekGrid`

---

## 🎨 DESIGN SYSTEM: 情報デザイン (Jōhō Dezain)

### You Are The Design Guardian

When working on ANY UI code in this project, you are the **情報デザイン Guardian**. You enforce the design system strictly. Design violations are bugs that must be fixed.

### Core Philosophy

> "Every visual element must serve a clear informational purpose. Nothing is decorative - everything communicates."

Inspired by Japanese OTC medicine packaging (Muhi, Rohto, Salonpas):
- **Compartmentalized layouts** like a bento box
- **Thick black borders** on everything
- **High contrast** (pure black and white)
- **Purposeful color** (every color has semantic meaning)
- **Squircle geometry** (continuous corner curves)

### ⚠️ CRITICAL: Readability Rules (HIGHEST PRIORITY)

**情報デザイン = BLACK text on WHITE backgrounds. ALWAYS.**

Japanese OTC packaging is designed to be read quickly by anyone - elderly, rushed shoppers, poor lighting. This means:

| Rule | Correct | WRONG |
|------|---------|-------|
| **Text color** | Black `#000000` | ~~White/gray on dark~~ |
| **Content background** | White `#FFFFFF` | ~~Dark backgrounds~~ |
| **Subtitle opacity** | Minimum 0.6 | ~~Below 0.5 (invisible)~~ |
| **Page titles** | Inside white container | ~~Floating on dark~~ |
| **Section headers** | Black text, visible | ~~Faint gray~~ |

**The Dark Background Rule:**
- `#1A1A2E` is the CANVAS only (outermost layer)
- It should be BARELY visible - just thin edges around white containers
- If you see more than 8pt of dark background anywhere, something is wrong
- ALL content areas must have white backgrounds

```swift
// ✅ CORRECT - Content in white container, title INSIDE
ScrollView {
    VStack {
        Text("Page Title")
            .foregroundStyle(JohoColors.black)  // BLACK text
        // ... rest of content
    }
    .padding()
    .background(JohoColors.white)  // WHITE background
    .clipShape(Squircle(cornerRadius: 16))
    .overlay(Squircle(...).stroke(JohoColors.black, lineWidth: 3))
}
.johoBackground()  // Dark canvas BEHIND everything

// ❌ WRONG - Title floating on dark background
ScrollView {
    Text("Page Title")
        .foregroundStyle(.white)  // NO! Unreadable
    VStack { ... }
        .background(JohoColors.white)
}
```

**Minimum Touch Targets & Spacing:**
- All interactive elements: **44pt × 44pt** minimum
- Spacing between buttons: **minimum 12pt**
- Never stack interactive elements closer than 8pt

### Legend Pills (情報デザイン Readability)

Legend pills and status indicators MUST use **white backgrounds** with colored borders/text:

```swift
// ✅ CORRECT - White pill, colored border and text (readable)
HStack(spacing: 4) {
    Circle().fill(accentColor).frame(width: 6, height: 6)
    Text("LABEL").foregroundStyle(accentColor)
}
.padding(.horizontal, 8)
.padding(.vertical, 4)
.background(JohoColors.white)
.clipShape(Capsule())
.overlay(Capsule().stroke(accentColor, lineWidth: 1.5))

// ❌ WRONG - Inverted (symbol becomes unclear on colored background)
.background(accentColor)
.foregroundStyle(.white)
```

**Why?** Inverted pills obscure the indicator symbol (●, ○, ◆). The symbol's meaning is lost when white-on-color.

### Status Pills (TODAY, HOL, Type Codes)

**Status pills WITHOUT indicator symbols** use the inverted pattern:
- **Background**: Semantic accent color (yellow for TODAY, red for HOL, etc.)
- **Text**: White
- **Border**: Black (1.5pt)

```swift
// ✅ CORRECT - Status pills use .coloredInverted()
JohoPill(text: "TODAY", style: .coloredInverted(JohoColors.yellow), size: .small)
JohoPill(text: "HOL", style: .coloredInverted(item.type.accentColor), size: .small)

// ❌ WRONG - Status pills should NOT use .colored() (hard to read)
JohoPill(text: "TODAY", style: .colored(JohoColors.yellow), size: .small)
```

| Pill Type | Style | Background | Text | Border |
|-----------|-------|------------|------|--------|
| **TODAY** | `.coloredInverted(JohoColors.yellow)` | Yellow | **Black** | Black |
| **HOL** | `.coloredInverted(red)` | Red | White | Black |
| **OBS** | `.coloredInverted(orange)` | Orange | White | Black |
| **EVT** | `.coloredInverted(purple)` | Purple | White | Black |
| **BDY** | `.coloredInverted(pink)` | Pink | White | Black |

**Rule:** If the pill has NO indicator symbol (●, ○), use `.coloredInverted()` for high visibility.

### Country Color Pills (Not Emoji Flags)

Emoji flags are NOT 情報デザイン compliant. Use text-based national color pills instead:

| Country | Background | Text | Border | Code |
|---------|------------|------|--------|------|
| **SE** (Sweden) | Dark blue `#004B87` | Yellow `#FECC00` | Black | SWE |
| **US** (USA) | Navy `#3C3B6E` | White `#FFFFFF` | Black | USA |
| **VN** (Vietnam) | Red `#DA251D` | Yellow `#FFCD00` | Black | VN |

**All country pills use black borders** for 情報デザイン uniformity.

```swift
// CountryPill: 情報デザイン compliant country indicator with text
Text(scheme.code)  // "SWE", "USA", "VN"
    .font(.system(size: 8, weight: .black, design: .rounded))
    .foregroundStyle(scheme.textColor)
    .padding(.horizontal, 6)
    .padding(.vertical, 3)
    .background(scheme.backgroundColor)
    .clipShape(Capsule())
    .overlay(Capsule().stroke(scheme.borderColor, lineWidth: 1.5))
```

### Color Semantics (MEMORIZE THIS)

Colors are NEVER decorative. Each has ONE meaning:

| Color | Hex | Semantic Meaning | Usage |
|-------|-----|------------------|-------|
| **Yellow** | `#FFE566` | NOW / Present | Today, current highlight, attention |
| **Cyan** | `#A5F3FC` | Scheduled Time | Events, appointments, calendar items |
| **Pink** | `#FECDD3` | Special Day | Holidays, birthdays, celebrations |
| **Orange** | `#FED7AA` | Movement | Trips, travel, locations |
| **Green** | `#BBF7D0` | Money | Expenses, financial, transactions |
| **Purple** | `#E9D5FF` | People | Contacts, relationships |
| **Red** | `#E53935` | Alert | Warnings, Sundays, errors |
| **Cream** | `#FEF3C7` | Personal | Notes, user annotations |
| **Black** | `#000000` | Definition | Borders, text, authority |
| **White** | `#FFFFFF` | Content | Container backgrounds |
| **Dark BG** | `#1A1A2E` | Canvas | App background ONLY (never containers) |

### Sidebar Icon Colors (iPad IconStripSidebar)

Each sidebar icon has its own semantic accent color. When selected, the icon and indicator bar use this color:

| Selection | Hex | Color Name | Icon |
|-----------|-----|------------|------|
| **Summary** | `#FFD700` | Gold | `square.grid.2x2` |
| **Workspace** | `#00B4D8` | Cyan | `rectangle.3.group` |
| **Calendar** | `#E53E3E` | Red | `calendar` |
| **Notes** | `#4A5568` | Gray | `doc.text` |
| **Contacts** | `#718096` | Slate | `person.2` |
| **Expenses** | `#38A169` | Green | `dollarsign.circle` |
| **Trips** | `#3182CE` | Blue | `airplane` |
| **Countdowns** | `#ED8936` | Orange | `timer` |
| **Special Days** | `#FFD700` | Gold | `star.fill` |
| **Settings** | `#718096` | Slate | `gearshape` |

**Implementation:** See `SidebarSelection.accentColor` in `AppSidebar.swift`. The `IconStripButton` in `IconStripSidebar.swift` uses `item.accentColor` for both the selection bar and the icon color when selected.

### Border Specifications

**Every element MUST have a border. No exceptions.**

| Element Type | Border Width |
|--------------|--------------|
| Day cells | 1pt |
| List rows | 1.5pt |
| Buttons | 2pt |
| Today/Selected | 2.5pt |
| Containers | 3pt |

Border color is ALWAYS `#000000` (pure black).

### Color-Coded Type Indicator Circles (PILLAR)

**This is a CORE pillar of 情報デザイン. ALL indicator circles MUST follow this specification CONSISTENTLY across the entire app.**

Type indicator circles show what kind of content exists for a day/item. They ALWAYS have:
1. **Filled center** with the type's ACCENT COLOR (never white!)
2. **BLACK border** (1-1.5pt stroke)
3. **Consistent sizing** based on context

| Type | Color | Hex | 3-Letter Code |
|------|-------|-----|---------------|
| **Holiday** | Red | `#E53E3E` | HOL |
| **Observance** | Orange | `#ED8936` | OBS |
| **Event** | Purple | `#805AD5` | EVT |
| **Birthday** | Pink | `#D53F8C` | BDY |
| **Note** | Yellow | `#ECC94B` | NTE |
| **Trip** | Blue | `#3182CE` | TRP |
| **Expense** | Green | `#38A169` | EXP |

**Circle Sizes by Context:**

| Context | Size | Border Width |
|---------|------|--------------|
| Calendar grid day | 7pt | 1pt |
| Collapsed row indicator | 8pt | 1pt |
| Month card stats | 8pt | 1pt |
| Expanded section items | 10pt | 1.5pt |
| Legend popover | 12pt | 1.5pt |

**CRITICAL: Bento box backgrounds use LIGHT TINTS so colored circles remain visible!**

The `SectionZone` backgrounds use light versions:
- `.holidays` → `JohoColors.redLight` (#FECACA) - light red
- `.birthdays` → `JohoColors.pinkLight` (#FED7E2) - light pink
- Other zones → 30% opacity of accent color

```swift
// ✅ CORRECT - Circles ALWAYS use type's accent color
Circle()
    .fill(type.accentColor)  // RED for holidays, PINK for birthdays, etc.
    .frame(width: 10, height: 10)
    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))

// ✅ CORRECT - Bento boxes use LIGHT tints
SectionZone.holidays.background  // Returns JohoColors.redLight (not solid red)

// ❌ WRONG - No border (looks unfinished, loses definition)
Circle()
    .fill(accentColor)
    .frame(width: 8, height: 8)

// ❌ WRONG - White circles (loses type color meaning!)
Circle()
    .fill(JohoColors.white)  // NO! Circles show type via color
    .frame(width: 10, height: 10)
```

**Database-Driven Type Codes:**
Use `SpecialDayType.code` property for 3-letter codes (HOL, OBS, EVT, BDY, NTE, TRP, EXP).
```swift
// ✅ CORRECT - Use type.code for pills
JohoPill(text: item.type.code, style: .colored(item.type.accentColor), size: .small)

// ❌ WRONG - Hardcoded strings
JohoPill(text: "Red Day", ...)  // NO! Use item.type.code
```

**Files implementing this system:**
- `SpecialDaysListView.swift` - Type codes, indicators, sections
- `CalendarGridView.swift` - Day cell indicators (7pt)
- `JohoDesignSystem.swift` - Colors, SectionZone backgrounds

### Star Page Bento Design (SpecialDaysListView)

The Star Page (☆) displays all special days using **compartmentalized bento rows** with colored backgrounds. NO white boxes inside colored sections - the section color IS the row background.

**The 7 Special Day Types:**

| Type | Code | Accent Color | Hex | Section Background | Light Tint |
|------|------|--------------|-----|-------------------|------------|
| **Holiday** | HOL | Red | `#E53E3E` | `JohoColors.redLight` | `#FECACA` |
| **Observance** | OBS | Orange | `#ED8936` | Orange 20% | `rgba(237,137,54,0.2)` |
| **Event** | EVT | Purple | `#805AD5` | Purple 20% | `rgba(128,90,213,0.2)` |
| **Birthday** | BDY | Pink | `#D53F8C` | `JohoColors.pinkLight` | `#FED7E2` |
| **Note** | NTE | Yellow | `#ECC94B` | Yellow 30% | `rgba(236,201,75,0.3)` |
| **Trip** | TRP | Blue | `#3182CE` | Blue 20% | `rgba(49,130,206,0.2)` |
| **Expense** | EXP | Green | `#38A169` | Green 30% | `rgba(56,161,105,0.3)` |

**Bento Row Structure (3 compartments with walls):**

```
┌─────┬──────────────────────────────┬─────────────────┐
│ ●🔒 │ Title Text                   │ SWE │ HOL │
├─────┼──────────────────────────────┼─────────────────┤
│LEFT │ CENTER                       │ RIGHT           │
│28pt │ flexible                     │ 80pt            │
└─────┴──────────────────────────────┴─────────────────┘
  │         │                              │
  │         │                              └── Country + Type pills
  │         └── Item title (black text)
  └── Type indicator circle + lock (if system)
```

**Compartment Walls (vertical dividers):**
- 1.5pt black vertical lines between compartments
- Creates visual separation like OTC medicine packaging
- Ensures alignment across all rows

```swift
// ✅ CORRECT - Bento row with colored background and compartment walls
HStack(spacing: 0) {
    // LEFT COMPARTMENT (28pt)
    HStack(spacing: 4) {
        typeIndicatorDot(for: item.type)  // Filled circle
        if !canEdit {
            Image(systemName: "lock.fill")
                .font(.system(size: 8))
                .foregroundStyle(JohoColors.black.opacity(0.4))
        }
    }
    .frame(width: 28)

    // WALL (divider)
    Rectangle()
        .fill(JohoColors.black)
        .frame(width: 1.5)

    // CENTER COMPARTMENT (flexible)
    Text(item.title)
        .font(JohoFont.bodySmall)
        .foregroundStyle(JohoColors.black)
        .padding(.horizontal, 8)

    Spacer()

    // WALL (divider)
    Rectangle()
        .fill(JohoColors.black)
        .frame(width: 1.5)

    // RIGHT COMPARTMENT (80pt)
    HStack(spacing: 4) {
        CountryPill(region: item.region)
        JohoPill(text: item.type.code, style: .coloredInverted(...))
    }
    .frame(width: 80)
}
.padding(.vertical, 8)
.background(zone.background)  // Section color IS the row background
.clipShape(Squircle(cornerRadius: 8))
.overlay(Squircle(...).stroke(JohoColors.black, lineWidth: 1.5))

// ❌ WRONG - White box inside colored section
.background(JohoColors.white)  // NO! Use zone.background
```

**Swipe Actions for Data Management:**

| Direction | Action | Color | Availability |
|-----------|--------|-------|--------------|
| ← Swipe LEFT | Delete | Red `#E53935` | User-created entries only |
| → Swipe RIGHT | Edit | Cyan `#A5F3FC` | User-created entries only |

System holidays (lock icon) have NO swipe actions - they are read-only.

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: canEdit) {
    if canEdit {
        Button(role: .destructive) { deleteRow(item) } label: {
            Label("DELETE", systemImage: "trash")
        }
    }
}
.swipeActions(edge: .leading, allowsFullSwipe: false) {
    if canEdit {
        Button { openEditor(item) } label: {
            Label("EDIT", systemImage: "pencil")
        }
        .tint(JohoColors.cyan)
    }
}
```

**Section Box Structure:**

```
┌─────────────────────────────────────────────────────┐
│ [HOLIDAYS] ★                                        │ ← Header (black pill + icon)
├─────────────────────────────────────────────────────┤
│ ┌─────┬───────────────────────────┬───────────────┐ │
│ │ ●   │ New Year's Day            │ SWE │ HOL │   │ │ ← Bento row
│ └─────┴───────────────────────────┴───────────────┘ │
│ ┌─────┬───────────────────────────┬───────────────┐ │
│ │ ●🔒 │ Christmas Day             │ USA │ HOL │   │ │ ← System (locked)
│ └─────┴───────────────────────────┴───────────────┘ │
└─────────────────────────────────────────────────────┘
  └── Light red background (#FECACA)
```

**Expandable Detail (tap row to expand):**

When a row is tapped, it expands to show additional details:
- Notes/description
- Date information
- Edit/Delete action buttons (for user entries)

### Typography

Font: **SF Pro Rounded** (`.design(.rounded)`)

| Scale | Size | Weight | Usage |
|-------|------|--------|-------|
| displayLarge | 48pt | heavy | Hero numbers |
| displayMedium | 32pt | bold | Section titles |
| headline | 18pt | bold | Card titles |
| body | 16pt | medium | Content |
| bodySmall | 14pt | medium | Secondary |
| label | 12pt | bold | Pills, badges (UPPERCASE) |
| labelSmall | 10pt | bold | Timestamps |

**Rules:**
- NEVER use weights below `.medium`
- ALWAYS include `.design(.rounded)`
- Labels and pills are ALWAYS UPPERCASE

### Spacing Grid

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Cell gaps |
| sm | 8pt | Row gaps |
| md | 12pt | Container padding |
| lg | 16pt | Screen margins |

**Critical:** Maximum 8pt top padding on any screen (no dead space!)

### Corner Radius (Squircle)

All corners MUST use continuous curvature:

```swift
// ✅ CORRECT
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

// ❌ WRONG
.cornerRadius(12)
```

| Element | Radius |
|---------|--------|
| Day cells | 8pt |
| Buttons | 8pt |
| Pills | 6pt |
| Cards | 12pt |
| Containers | 16pt |

### ❌ FORBIDDEN PATTERNS (Auto-Reject)

**NEVER use these. Flag and fix immediately:**

```swift
// ❌ GLASS/BLUR - FORBIDDEN
.background(.ultraThinMaterial)
.background(.thinMaterial)
.background(.regularMaterial)
.background(.bar)

// ❌ GRADIENTS - FORBIDDEN
LinearGradient(...)
RadialGradient(...)

// ❌ SHADOWS AS PRIMARY DESIGN - FORBIDDEN
.shadow(radius: 10)

// ❌ RAW SYSTEM COLORS - Use JohoColors instead
Color.blue
Color.red
Color.green

// ❌ MISSING BORDERS - Every background needs a border
.background(Color.white)  // Missing .overlay(...stroke())

// ❌ EXCESSIVE TOP PADDING
.padding(.top, 40)  // Max is 8pt

// ❌ NON-CONTINUOUS CORNERS
.cornerRadius(12)  // Must use style: .continuous

// ❌ LOCALE-FORMATTED YEARS - Years must NEVER have spaces
Text("\(year)")  // BAD: "1 990" with locale thousand separator
Text(String(year))  // GOOD: "1990" always
```

### ✅ Correct Component Patterns

**Container:**
```swift
VStack {
    content
}
.padding(12)
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(Color.black, lineWidth: 3)
)
```

**Pill/Badge:**
```swift
Text("LABEL")
    .font(.system(size: 12, weight: .bold, design: .rounded))
    .foregroundStyle(Color.white)
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(Color.black)
    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
```

**List Row:**
```swift
HStack(spacing: 12) {
    // Colored icon zone (color = semantic meaning)
    Image(systemName: "calendar")
        .frame(width: 40, height: 40)
        .background(Color(hex: "A5F3FC")) // Cyan = events
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.black, lineWidth: 1.5)
        )

    VStack(alignment: .leading) {
        Text("Title").font(.system(size: 16, weight: .medium, design: .rounded))
        Text("Subtitle").font(.system(size: 12, weight: .medium, design: .rounded))
    }
    Spacer()
    Image(systemName: "chevron.right")
}
.padding(12)
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(Color.black, lineWidth: 1.5)
)
```

**Compartmentalized Flipcard (Bento Style):**

情報デザイン flipcards should be **compartmentalized like a bento box** - distinct zones separated by dividers:

```swift
HStack(spacing: 0) {
    // LEFT COMPARTMENT: Icon zone (visual anchor)
    VStack {
        Image(systemName: "snowflake")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(accentColor)
    }
    .frame(width: 44)
    .frame(maxHeight: .infinity)
    .background(lightBackground)  // Tinted background

    // Vertical divider (essential for compartmentalization)
    Rectangle()
        .fill(Color.black)
        .frame(width: 1.5)

    // RIGHT COMPARTMENT: Data zone
    VStack(alignment: .leading, spacing: 4) {
        Text("TITLE")
            .font(.system(size: 11, weight: .black))

        // Stats with visual indicators
        HStack(spacing: 6) {
            // Indicator + count
        }
    }
    .padding(.horizontal, 8)
    .frame(maxWidth: .infinity, alignment: .leading)
}
.frame(height: 52)
.background(Color.white)
.clipShape(Squircle(cornerRadius: 8))
.overlay(Squircle(...).stroke(Color.black, lineWidth: 2))
```

**Key Principles:**
- Icon ALWAYS in left compartment with tinted background
- Black vertical divider between compartments
- Data/stats in right compartment, left-aligned
- Fixed height for consistent grid appearance

**Editor Sheet Header Pattern (情報デザイン):**

ALL editor sheets MUST use the consistent header pattern from Star Page month detail view:

```
┌─────────────────────────────────────────────────────────────┐
│ [◀] [Icon] TITLE TEXT                              [Save]  │
│            Subtitle text                                    │
└─────────────────────────────────────────────────────────────┘
```

**Header Components:**

| Component | Size | Specifications |
|-----------|------|----------------|
| Back button | 44×44pt | `chevron.left`, white background, thin border (1pt) |
| Icon zone | 52×52pt | Type icon (24pt bold), light tint background, medium border (2pt) |
| Title | Headline font | UPPERCASE, black text |
| Subtitle | Caption font | 0.7 opacity black text |
| Save button | Auto | Accent color when valid, white when invalid |

**Type Icons (from SpecialDayType.defaultIcon):**

| Type | Code | Icon | Accent Color | Light Background |
|------|------|------|--------------|------------------|
| Holiday | HOL | `star.fill` | `#E53E3E` (Red) | Red 20% opacity |
| Observance | OBS | `sparkles` | `#ED8936` (Orange) | Orange 20% opacity |
| Event | EVT | `calendar.badge.clock` | `#805AD5` (Purple) | Purple 20% opacity |
| Birthday | BDY | `birthday.cake.fill` | `#D53F8C` (Pink) | Pink 20% opacity |
| Note | NTE | `note.text` | `#ECC94B` (Yellow) | Yellow 20% opacity |
| Trip | TRP | `airplane` | `#3182CE` (Blue) | Blue 20% opacity |
| Expense | EXP | `dollarsign.circle.fill` | `#38A169` (Green) | Green 20% opacity |

**Standard Header Implementation:**

```swift
// Use JohoEditorHeader for all editor sheets
JohoEditorHeader(
    icon: type.defaultIcon,           // SF Symbol from SpecialDayType
    accentColor: type.accentColor,    // Semantic color
    title: "NEW HOLIDAY",             // UPPERCASE
    subtitle: "Set date & details",   // Descriptive text
    canSave: !name.isEmpty,           // Validation state
    onBack: { dismiss() },
    onSave: { saveAndDismiss() }
)
```

**Full Header Code Pattern:**

```swift
HStack(alignment: .center, spacing: JohoDimensions.spacingMD) {
    // Back button (44×44)
    Button { dismiss() } label: {
        Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(JohoColors.black)
            .frame(width: 44, height: 44)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(Squircle(...).stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin))
    }

    // Icon zone (52×52) - uses type.lightBackground for proper contrast
    Image(systemName: type.defaultIcon)
        .font(.system(size: 24, weight: .bold))
        .foregroundStyle(type.accentColor)
        .frame(width: 52, height: 52)
        .background(type.lightBackground)  // NOT opacity - explicit light tint
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(Squircle(...).stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium))

    // Title area
    VStack(alignment: .leading, spacing: 2) {
        Text("NEW HOLIDAY")
            .font(JohoFont.headline)
            .foregroundStyle(JohoColors.black)
        Text("Set date & details")
            .font(JohoFont.caption)
            .foregroundStyle(JohoColors.black.opacity(0.7))
    }

    Spacer()

    // Save button
    Button { onSave() } label: {
        Text("Save")
            .font(JohoFont.body.bold())
            .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(canSave ? type.accentColor : JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(Squircle(...).stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium))
    }
    .disabled(!canSave)
}
.padding(JohoDimensions.spacingLG)  // 16pt all sides
.background(JohoColors.white)  // WHITE background
.clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
.overlay(Squircle(...).stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick))  // 3pt border
```

**Editor Content Card:**

Below the header, the scrollable content card contains form fields:

```swift
ScrollView {
    VStack(spacing: JohoDimensions.spacingLG) {
        // Form fields with JohoPill labels
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            JohoPill(text: "FIELD NAME", style: .whiteOnBlack, size: .small)
            TextField("placeholder", text: $value)
                .font(JohoFont.body)
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(Squircle(...).stroke(JohoColors.black, lineWidth: 1.5))
        }

        // Toggle fields use johoToggle pattern
        HStack {
            JohoPill(text: "OPTION", style: .whiteOnBlack, size: .small)
            Spacer()
            johoToggle(isOn: $optionEnabled, accentColor: type.accentColor)
        }
    }
    .padding(JohoDimensions.spacingLG)
    .background(JohoColors.white)
    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
    .overlay(Squircle(...).stroke(JohoColors.black, lineWidth: 3))
}

**Editor Requirements:**
- Header OUTSIDE scrollable content (fixed at top)
- VStack spacing: `JohoDimensions.spacingMD` (12pt gap between header and content)
- Back button: 44×44pt minimum touch target
- Icon zone: Uses type's `defaultIcon`, `accentColor`, and `lightBackground`
- Save button: Accent color background when valid, white when invalid
- All form fields: White background + black border + JohoPill label
- Toggles: Custom 情報デザイン toggle (not iOS default)
- Year numbers: Use `String(year)` never `"\(year)"` to avoid locale spacing

### JohoIconPicker (情報デザイン Icon Selector)

Standard icon picker for selecting SF Symbols in entry editors. Defined in `CountdownViews.swift`.

**Categories:**
- MARU-BATSU: マルバツ記号 (circle, xmark, triangle, square, diamond)
- EVENTS: Celebration icons (star, sparkles, gift, birthday, party, balloon, heart, bell)
- NATURE: Natural elements (leaf, camera.macro, sun, moon, snowflake, cloud, flame, drop)
- PEOPLE: Person icons
- TIME: Calendar and clock icons

**Selected State Styling (matches header icon zone):**
- Icon: Accent color (`SpecialDayType.event.accentColor`)
- Background: Light background (`SpecialDayType.event.lightBackground`)
- Border: Black, 2pt

**Unselected State:**
- Icon: Black
- Background: White
- Border: Black, 1pt

```swift
// ✅ CORRECT - Selected icon uses accent on light (NOT inverted)
Image(systemName: symbol)
    .foregroundStyle(selectedSymbol == symbol ? SpecialDayType.event.accentColor : JohoColors.black)
    .background(selectedSymbol == symbol ? SpecialDayType.event.lightBackground : JohoColors.white)
    .overlay(Squircle(...).stroke(JohoColors.black, lineWidth: selected ? 2 : 1))

// ❌ WRONG - Inverted (white on purple)
.foregroundStyle(selectedSymbol == symbol ? JohoColors.white : JohoColors.black)
.background(selectedSymbol == symbol ? SpecialDayType.event.accentColor : JohoColors.white)
```

**Key Principle:** Icon picker selected state MUST match the header icon zone pattern - accent color icon on light background, not inverted.

### Visual Indicators (Filled vs Outlined)

Use filled/outlined shapes to distinguish categories visually:

| Indicator | Style | Meaning | Example Usage |
|-----------|-------|---------|---------------|
| ● Filled circle | `Circle().fill(color)` | Primary/Important | Holidays, required items |
| ○ Outlined circle | `Circle().stroke(color, lineWidth: 1.5)` | Secondary/Optional | Observances, optional items |
| ■ Filled square | `Rectangle().fill(color)` | Active/Selected | Current state |
| □ Outlined square | `Rectangle().stroke(color)` | Inactive/Available | Available options |

```swift
// Legend example (always include for clarity)
HStack(spacing: 16) {
    HStack(spacing: 4) {
        Circle().fill(Color.red).frame(width: 10, height: 10)
        Text("HOLIDAYS").font(.system(size: 10, weight: .bold)).foregroundStyle(.red)
    }
    HStack(spacing: 4) {
        Circle().stroke(Color.orange, lineWidth: 1.5).frame(width: 10, height: 10)
        Text("OBSERVANCES").font(.system(size: 10, weight: .bold)).foregroundStyle(.orange)
    }
}
```

**Rule:** When using filled/outlined indicators, ALWAYS include a legend above the content.

### Priority Symbols (Hierarchy Markers)

Japanese OTC uses visual priority markers. Use these to indicate importance:

| Symbol | Meaning | Usage |
|--------|---------|-------|
| **◎** | Primary | Most important item, top priority |
| **○** | Secondary | Standard items |
| **△** | Tertiary | Low priority, optional |
| **✕** | Excluded | Not applicable, don't use |

```swift
// Priority badge example
Text("◎")
    .font(.system(size: 14, weight: .bold))
    .foregroundStyle(Color.black)
```

### Day Card Canvas Rules (Month Detail View)

Special Days pages use a **3-column grid** of day cards. When the same date has multiple holidays/events, the card **expands vertically** to fit all content while maintaining grid alignment.

**Grid Layout:**
```
┌─────────┬─────────┬─────────┐
│ Jan 1   │ Jan 6   │ Jan 13  │  ← Standard 1x1 cards
│ SWE VN  │ SWE     │         │
│ NewYear │ Epiph.  │ Birthday│
│ Tet...  │         │         │  ← Jan 1 expands for 2 holidays
├─────────┼─────────┼─────────┤
│ ...     │ ...     │ ...     │
└─────────┴─────────┴─────────┘
```

**Day Card Sizing Rules:**

| Items on Date | Card Size | Height |
|---------------|-----------|--------|
| 1 item | Standard | 110pt |
| 2 items | Expanded | 130pt |
| 3+ items | Expanded | 110 + (n-1) × 20pt |

**Day Card Structure (情報デザイン Bento):**

```swift
// Standard card (single item)
VStack(spacing: 0) {
    // TOP (colored): Icon + country pill
    HStack {
        Image(systemName: icon).padding(.leading, 8)
        Spacer()
        CountryPill(region: region).padding(.trailing, 8)
    }
    .frame(height: 48)
    .background(accentColor.opacity(0.15))

    Rectangle().fill(JohoColors.black).frame(height: 1.5)  // Divider

    // BOTTOM (white): Date + holiday name
    VStack {
        Text("\(day)").font(.system(size: 18, weight: .black))
        Text(title).font(.system(size: 9, weight: .bold))
        TypeIndicator(type: type)  // ● or ○
    }
}

// Expanded card (multiple items on same date)
VStack(spacing: 0) {
    // TOP (colored): Date is the visual anchor
    Text("\(day)")
        .font(.system(size: 28, weight: .black))
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(primaryType.accentColor.opacity(0.15))

    Rectangle().fill(JohoColors.black).frame(height: 1.5)

    // BOTTOM (white): List all holidays with flags
    VStack(spacing: 6) {
        ForEach(items) { item in
            HStack {
                TypeIndicator(type: item.type)  // ●/○/◆/🎂
                Text(item.title)
                Spacer()
                CountryPill(region: item.region)  // Flag on right
            }
        }
    }
    .padding(8)
}
```

**Same-Day Holiday Rules:**

1. **Group by date**: All items falling on the same day combine into one card
2. **English first**: System language determines primary display (English names)
3. **Country pills inline**: Each holiday shows its country pill next to the name
4. **Type indicators**: Use ● (holiday), ○ (observance), ◆ (event), 🎂 (birthday)
5. **Vertical expansion**: Cards grow taller, never wider (maintains grid)

**Canvas Boundaries:**

- Month page uses 3-column `LazyVGrid`
- Horizontal padding: `JohoDimensions.spacingLG` (16pt)
- Inter-card spacing: `JohoDimensions.spacingSM` (8pt)
- Cards fill available width equally (no spanning columns)

### マルバツ記号 (Maru-Batsu Symbols)

These are the core Japanese information symbols (also used by PlayStation). They are fundamental to 情報デザイン:

| Symbol | Name | SF Symbol | Meaning |
|--------|------|-----------|---------|
| ○ | Maru | `circle.fill` | Correct, yes, good, approved |
| × | Batsu | `xmark` | Wrong, no, rejected, cancel |
| △ | Sankaku | `triangle.fill` | Caution, maybe, partial, warning |
| □ | Shikaku | `square.fill` | Neutral, info, menu, options |
| ◇ | Hishigata | `diamond.fill` | Special, important, highlight |

**Usage in app:**
- Icon picker organized with マルバツ symbols at the top
- Use these for status indicators, approval states, warnings
- Prefer filled variants for better visibility

### Color Placement Rule (CRITICAL)

**Colors go ONLY in icon zones, NEVER in full headers/rows.**

```swift
// ✅ CORRECT - Color in icon zone only
HStack {
    Image(systemName: "star")
        .frame(width: 40, height: 40)
        .background(SectionZone.holidays.background)  // Pink HERE
    Text("Holiday Name")
}
.background(JohoColors.white)  // White background

// ❌ WRONG - Full row is colored
HStack {
    Image(systemName: "star")
    Text("Holiday Name")
}
.background(SectionZone.holidays.background)  // NO! Too much pink
```

### Attention/Warning Tiers

Beyond basic Red=Alert, use tiered warning levels:

| Level | Japanese | Color Treatment | Usage |
|-------|----------|-----------------|-------|
| Info | 情報 | Cyan border | Helpful tips |
| Caution | 注意 | Yellow background | User should know |
| Warning | 警告 | Red background | Action required |
| Danger | 危険 | Black + Red stripe | Critical/destructive |

### Icon Specifications

**SF Symbol Standards:**

| Context | Weight | Size | Style |
|---------|--------|------|-------|
| Navigation | `.medium` | 20pt | Outline |
| List icons | `.medium` | 16pt | Filled |
| Buttons | `.semibold` | 18pt | Filled |
| Badges | `.bold` | 12pt | Filled |
| Hero display | `.bold` | 32pt | Filled |

```swift
// ✅ CORRECT - Consistent icon styling
Image(systemName: "calendar")
    .font(.system(size: 16, weight: .medium))
    .symbolRenderingMode(.hierarchical)
```

### Swipe Row Pattern

Standard swipe interactions for list rows:

| Direction | Action | Color | Icon |
|-----------|--------|-------|------|
| ← Left | Delete (destructive) | Red `#E53935` | `trash` |
| → Right | Edit/Configure | Cyan `#A5F3FC` | `pencil` |

```swift
// Swipe action zones
private struct JohoSwipeableRow: View {
    @State private var offset: CGFloat = 0
    let swipeThreshold: CGFloat = 80

    var body: some View {
        ZStack {
            // Left zone (delete) - revealed on left swipe
            HStack {
                Spacer()
                Image(systemName: "trash")
                    .foregroundStyle(.white)
                    .frame(width: 60)
            }
            .background(Color(hex: "E53935"))

            // Right zone (edit) - revealed on right swipe
            HStack {
                Image(systemName: "pencil")
                    .foregroundStyle(.black)
                    .frame(width: 60)
                Spacer()
            }
            .background(Color(hex: "A5F3FC"))

            // Main content
            rowContent
                .offset(x: offset)
                .gesture(swipeGesture)
        }
    }
}
```

### Expandable Section Pattern

For collapsible content groups:

```swift
private struct JohoExpandableSection<Content: View>: View {
    let title: String
    let color: Color  // Semantic color for section
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    Text(title.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.black)
                .padding(12)
                .background(color)
            }

            // Content (expandable)
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black, lineWidth: 2)
        )
    }
}
```

### Empty/Loading/Error States

**Empty State:**
```swift
VStack(spacing: 12) {
    Image(systemName: "tray")
        .font(.system(size: 32, weight: .medium))
        .foregroundStyle(.black.opacity(0.4))
    Text("NO ITEMS")
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundStyle(.black.opacity(0.6))
}
.frame(maxWidth: .infinity)
.padding(24)
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(Color.black.opacity(0.3), lineWidth: 1.5)
)
```

**Loading State:**
```swift
// Pulsing border animation
.overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(Color.black, lineWidth: 2)
        .opacity(isPulsing ? 0.3 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(), value: isPulsing)
)
```

**Error State:**
```swift
HStack(spacing: 12) {
    Image(systemName: "xmark.circle.fill")
        .foregroundStyle(Color(hex: "E53935"))
    Text("Error message here")
        .font(.system(size: 14, weight: .medium, design: .rounded))
}
.padding(12)
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(Color(hex: "E53935"), lineWidth: 2)
)
```

### Information Density Guidelines

Japanese OTC succeeds by maximizing clarity, not quantity:

| Principle | Rule |
|-----------|------|
| **One Glance** | Each card conveys ONE primary message |
| **3-Item Max** | Maximum 3 info items per card |
| **7±2 Rule** | 5-9 items visible without scrolling |
| **Icon + Label** | Every data point has icon AND text |
| **Hierarchy** | Primary info 2x size of secondary |

```
┌─────────────────────────────┐
│ ◎ PRIMARY INFO (large)     │  ← Immediately visible
│   ○ Secondary detail       │  ← Supports primary
│   ○ Secondary detail       │  ← Supports primary
│   △ Tertiary (tap for more)│  ← Optional, discoverable
└─────────────────────────────┘
```

### Diagonal Corner Banner (Optional)

For "NEW" or promotional callouts:

```swift
// 45° corner ribbon
Text("NEW")
    .font(.system(size: 10, weight: .bold, design: .rounded))
    .foregroundStyle(.white)
    .padding(.horizontal, 20)
    .padding(.vertical, 4)
    .background(Color(hex: "E53935"))
    .rotationEffect(.degrees(-45))
    .offset(x: -20, y: 10)
```

### Animation Guidelines

情報デザイン uses **minimal, functional** animation:

| Animation | Duration | Curve | Usage |
|-----------|----------|-------|-------|
| Expand/Collapse | 0.2s | easeInOut | Section toggles |
| Swipe snap | 0.15s | spring | Row gestures |
| Selection | 0.1s | easeOut | Tap feedback |
| Page transition | 0.25s | easeInOut | Navigation |

**FORBIDDEN Animations:**
- Bouncy/playful springs
- Rotation effects (except corner banners)
- Scale animations > 1.05x
- Continuous looping (except loading)

---

### Design Audit Commands

```bash
# Find forbidden glass/blur materials
grep -rn "ultraThinMaterial\|thinMaterial\|regularMaterial" --include="*.swift"

# Find non-continuous corners
grep -rn "\.cornerRadius(" --include="*.swift"

# Find raw system colors
grep -rn "Color\.blue\|Color\.red\|Color\.green" --include="*.swift"

# Find gradients
grep -rn "LinearGradient\|RadialGradient" --include="*.swift"

# Find excessive top padding
grep -rn "\.padding(.top," --include="*.swift"

# Find forbidden bouncy animations
grep -rn "\.spring(response.*bounce" --include="*.swift"

# Find scale animations (check if > 1.05)
grep -rn "\.scaleEffect(" --include="*.swift"

# Find missing .design(.rounded) on fonts
grep -rn "\.font(.system" --include="*.swift" | grep -v "design:"

# Verify icon weights are correct
grep -rn "Image(systemName:" --include="*.swift" -A 2
```

### Design Files

- `JohoDesignSystem.swift` - Core design system components and colors
- `joho-design-system.json` - Complete specification reference

---

## Build Commands

### Quick Start
```bash
# Build the app (Debug)
./build.sh build

# Build for release
./build.sh build-release

# Run tests
./build.sh test

# Clean build artifacts
./build.sh clean

# Validate project structure
./build.sh validate
```

### Xcode Commands
```bash
# Build for simulator
xcodebuild build -project Vecka.xcodeproj -scheme Vecka \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Run tests
xcodebuild test -project Vecka.xcodeproj -scheme Vecka \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# List available simulators
xcrun simctl list devices available
```

### Widget-Specific Build
```bash
# Test widget extension build
./build.sh widget-test

# Or directly with xcodebuild (target is VeckaWidgetExtension)
xcodebuild build -project Vecka.xcodeproj -scheme Vecka \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Architecture Overview

### Multi-Target Structure
- **Vecka**: Main app target (iOS 18.0+)
- **VeckaWidgetExtension**: Widget extension target with small/medium/large variants
- **VeckaTests**: Unit test suite
- **VeckaUITests**: UI automation tests

**Note**: Code sharing between app and widget happens through direct file inclusion in both targets. When adding new files that should be accessible from widgets, ensure the file is added to both the Vecka and VeckaWidgetExtension targets in Xcode's Target Membership settings.

### Core Architecture Pattern: Manager + Model + View

The app uses a sophisticated manager-based architecture with SwiftData persistence:

**1. Core Calculator Layer** (`Vecka/Core/`)
- `WeekCalculator`: Thread-safe ISO 8601 week calculation with caching

**2. Model Layer** (`Vecka/Models/`)
- SwiftData models: `HolidayRule`, `CalendarRule`, `CountdownEvent`, `DailyNote`
- Pure Swift structs: `Holiday`, `CalendarModels`

**3. Manager Layer** (Singleton Pattern)
- `HolidayManager`: Holiday calculation and caching
- `CalendarManager`: Calendar rule management
- `CountdownManager`: Countdown event management

**4. Engine Layer** (`Vecka/Models/HolidayEngine.swift`)
- Easter calculations, floating weekday finder, lunar calendar conversion

**5. View Layer** (`Vecka/Views/`)
- **ModernCalendarView**: Main calendar UI with 情報デザイン styling
- **AppSidebar**: Left sidebar for iPad NavigationSplitView
- **PhoneLibraryView**: Library/favorites view for iPhone TabView
- Modular components: `CalendarGridView`, `DayDashboardView`, `WeekDetailPanel`, etc.

**6. Services Layer** (`Vecka/Services/`)
- Weather, Travel & Expenses, PDF Export, Currency

### Data Flow Pattern
```
User Action → View
           ↓
     Manager.shared (cache check)
           ↓
     SwiftData Query / Engine Calculation
           ↓
     Cache Update → View Update
```

---

## Key Technical Details

### ISO 8601 Calendar Configuration
```swift
var calendar = Calendar(identifier: .gregorian)
calendar.firstWeekday = 2        // Monday
calendar.minimumDaysInFirstWeek = 4  // ISO 8601 standard
calendar.locale = Locale(identifier: "sv_SE")
```

### Holiday Calculation System
Five types: Fixed, Easter-relative, Floating, Nth weekday, Lunar

**Supported Regions (database-seeded):**
| Code | Country | Flag | Bank Holidays | Observances |
|------|---------|------|---------------|-------------|
| SE | Sweden | 🇸🇪 | 12 | 8 |
| US | United States | 🇺🇸 | 11 | 5 |
| VN | Vietnam | 🇻🇳 | 6 | 1 (lunar) |

Maximum 2 regions can be selected simultaneously (enforced by `HolidayRegionSelection`).

To add more holidays: add `HolidayRule` entries in `HolidayManager.seedDefaultRules()`.

Do NOT reference regions that are not in this list. Flags are generated from region codes using Unicode Regional Indicator symbols.

### Siri Shortcuts Integration (`Vecka/Intents/`)
- `CurrentWeekIntent`: "What week is it?"
- `WeekOverviewIntent`: "Show week overview"
- `WeekForDateIntent`: Get week for specific date

### Widget Deep Linking
- `vecka://today`: Navigate to current week
- `vecka://week/{weekNumber}/{year}`: Navigate to specific week
- `vecka://calendar`: Navigate to calendar view

---

## Important Conventions

### File Organization
- Core logic in `Vecka/Core/`
- Data models in `Vecka/Models/`
- Reusable views in `Vecka/Views/`
- Design system in `Vecka/JohoDesignSystem.swift`
- App Intents in `Vecka/Intents/`

### Localization
- Primary: Swedish (sv_SE)
- Secondary: English, Japanese, Korean, German, Vietnamese, Thai, Chinese
- Use `Localization` struct for all user-facing strings

### SwiftData Models
```swift
.modelContainer(for: [
    DailyNote.self,
    HolidayRule.self,
    CalendarRule.self,
    CountdownEvent.self,
    ExpenseCategory.self,
    ExpenseTemplate.self,
    ExpenseItem.self,
    TravelTrip.self,
    MileageEntry.self,
    ExchangeRate.self,
    SavedLocation.self
])
```

### 情報デザイン Compliance Checklist

Before committing any UI code:
- [ ] Every container has a black border
- [ ] Colors match semantic meaning (not random)
- [ ] No glass/blur effects anywhere
- [ ] All corners are squircle (continuous)
- [ ] Typography uses SF Rounded with `.design(.rounded)`
- [ ] No dead space at top of screens (max 8pt)
- [ ] Dark background only on ScrollView/main container
- [ ] All interactive elements have borders
- [ ] Swipe rows: right=edit (cyan), left=delete (red)
- [ ] Icons use correct weight for context (16pt medium for lists)
- [ ] Animations are functional, not playful (max 0.25s)
- [ ] Info density: max 3 items per card
- [ ] Priority symbols used for importance (◎○△)

---

## Common Development Tasks

### Adding a New View

1. Create file in `Vecka/Views/`
2. Import `JohoDesignSystem` components
3. Use `JohoColors` for all colors
4. Ensure all containers have borders
5. Use `.design(.rounded)` for all fonts
6. Test in both light and dark mode

### Adding a New Holiday
```swift
let holiday = HolidayRule(
    id: "unique-id",
    name: "Holiday Name",
    localizedName: ["en": "English", "sv": "Svenska"],
    type: .fixed,
    month: 12, day: 25,
    regionCode: "SE"
)
context.insert(holiday)
```

### Working with Expenses
- Use **Green** (`#BBF7D0`) for expense-related UI
- Icon zone background matches semantic meaning
- All amounts in bordered containers

### Working with Trips
- Use **Orange** (`#FED7AA`) for trip-related UI
- Airplane icon with orange background

---

## Build Configuration

### Bundle Identifiers
- Main App: `Johansson.Vecka`
- Widget: `Johansson.Vecka.VeckaWidget`
- **App Store Name**: WeekGrid

### Deployment Targets
- Main App: iOS 18.0+
- Widget: iOS 18.0+
- Swift Version: Swift 6.0

---

## Widget Implementation

### Widget Architecture
- **Provider**: Timeline provider with EventKit integration
- **Views**: `SmallWidgetView`, `MediumWidgetView`, `LargeWidgetView`
- **Theme**: 情報デザイン styling (borders, semantic colors)

### Widget Sizes
- **Small**: Week number with semantic color
- **Medium**: Week number + date range + countdown
- **Large**: Full 7-day calendar with events

---

## Debugging Tips

### Week Calculation Issues
- Verify `Calendar.iso8601` configuration
- Check cache invalidation in `WeekCalculator`

### Design System Issues
- Run audit commands to find violations
- Check `JohoDesignSystem.swift` for correct component usage
- Verify colors match semantic meaning

### Widget Not Updating
- Verify timeline provider midnight calculation
- Check widget URL scheme handling

---

## Project Documentation

### Active Documentation
- `CLAUDE.md`: Project instructions and design system (this file)
- `joho-design-system.json`: Complete 情報デザイン specification
- `TODO_VECKA_FEATURES.md`: Feature roadmap
- `REMAINING_ISSUES.md`: Deferred issues

---

## Quick Reference: 情報デザイン

```
┌─────────────────────────────────────────────┐
│         情報デザイン QUICK REFERENCE         │
├─────────────────────────────────────────────┤
│ COLORS (semantic only):                     │
│   Yellow #FFE566 = Today/Now                │
│   Cyan   #A5F3FC = Events                   │
│   Pink   #FECDD3 = Holidays                 │
│   Orange #FED7AA = Trips                    │
│   Green  #BBF7D0 = Expenses                 │
│   Purple #E9D5FF = Contacts                 │
│   Red    #E53935 = Warnings/Sunday          │
│   Cream  #FEF3C7 = Notes                    │
├─────────────────────────────────────────────┤
│ PRIORITY SYMBOLS:                           │
│   ◎ = Primary (most important)              │
│   ○ = Secondary (standard)                  │
│   △ = Tertiary (optional)                   │
│   ✕ = Excluded (don't use)                  │
├─────────────────────────────────────────────┤
│ マルバツ記号 (MARU-BATSU):                    │
│   ○ circle.fill = Yes/Correct              │
│   × xmark = No/Wrong                        │
│   △ triangle.fill = Caution/Maybe          │
│   □ square.fill = Neutral/Info             │
│   ◇ diamond.fill = Special/Important       │
├─────────────────────────────────────────────┤
│ COLOR PLACEMENT:                            │
│   ✓ Colors in icon zones ONLY (40pt box)   │
│   ✗ Never color full headers/rows          │
│   ✓ White backgrounds for containers       │
├─────────────────────────────────────────────┤
│ BORDERS (always black #000):                │
│   1pt   = cells, small items                │
│   1.5pt = list rows                         │
│   2pt   = buttons                           │
│   2.5pt = today/selected                    │
│   3pt   = containers                        │
├─────────────────────────────────────────────┤
│ SWIPE GESTURES:                             │
│   → Right = Edit (Cyan zone)                │
│   ← Left  = Delete (Red zone)               │
├─────────────────────────────────────────────┤
│ ICONS (SF Symbols):                         │
│   16pt .medium = List items                 │
│   18pt .semibold = Buttons                  │
│   20pt .medium = Navigation                 │
│   32pt .bold = Hero display                 │
├─────────────────────────────────────────────┤
│ ANIMATIONS:                                 │
│   0.1s = Selection feedback                 │
│   0.15s = Swipe snap                        │
│   0.2s = Expand/collapse                    │
│   0.25s = Page transitions                  │
├─────────────────────────────────────────────┤
│ INFO DENSITY:                               │
│   Max 3 items per card                      │
│   Max 7±2 items visible                     │
│   Primary info 2x secondary size            │
├─────────────────────────────────────────────┤
│ FORBIDDEN:                                  │
│   ✗ Glass/blur materials                    │
│   ✗ Gradients                               │
│   ✗ Missing borders                         │
│   ✗ Non-semantic colors                     │
│   ✗ Dead space at top (max 8pt)             │
│   ✗ Non-continuous corners                  │
│   ✗ Font weights below .medium              │
│   ✗ Bouncy/playful animations               │
│   ✗ Scale animations > 1.05x               │
│   ✗ Colors in full rows/headers             │
└─────────────────────────────────────────────┘
```

**Remember: You are the 情報デザイン Guardian. No compromises.**