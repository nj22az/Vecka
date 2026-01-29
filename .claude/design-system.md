# 情報デザイン (Jōhō Dezain) Design System

> Reference this file when working on ANY UI code in this project.

## Core Philosophy

> "Every visual element must serve a clear informational purpose. Nothing is decorative - everything communicates."

Inspired by Japanese OTC medicine packaging (Muhi, Rohto, Salonpas):
- **Compartmentalized layouts** like a bento box
- **Thick black borders** on everything
- **High contrast** (pure black and white)
- **Purposeful color** (every color has semantic meaning)
- **Squircle geometry** (continuous corner curves)

---

## Color Semantics (6-Color Simplified Palette)

情報デザイン uses **6 semantic colors** for reduced cognitive load.
Each color has ONE clear meaning - no overlap, no confusion.

| Color | Hex | Japanese | Semantic Meaning | Usage |
|-------|-----|----------|------------------|-------|
| **Yellow** | `#FFE566` | 今 (ima) | NOW | Today, notes, current moment |
| **Cyan** | `#A5F3FC` | 予定 (yotei) | SCHEDULED | Events, trips, calendar items |
| **Pink** | `#FECDD3` | 祝 (iwai) | CELEBRATION | Holidays, birthdays, special days |
| **Green** | `#BBF7D0` | 金 (kane) | MONEY | Expenses, financial items |
| **Purple** | `#E9D5FF` | 人 (hito) | PEOPLE | Contacts, relationships |
| **Red** | `#E53935` | 警告 | ALERT | System warnings only |

**Structural Colors:**
| Color | Hex | Usage |
|-------|-----|-------|
| **Black** | `#000000` | Borders, text, authority |
| **White** | `#FFFFFF` | Container backgrounds |

**Note:** Orange and Cream have been **deprecated**. Use Cyan for trips, Yellow for notes.

### App Background Options

| Option | Hex | Name | Description |
|--------|-----|------|-------------|
| **True Black** | `#000000` | Black (default) | Maximum AMOLED savings |
| **Dark Navy** | `#1A1A2E` | Navy | Warm dark (legacy) |
| **Near Black** | `#0A0A0F` | Soft | Slightly warmer |

---

## Readability Rules (HIGHEST PRIORITY)

**情報デザイン = BLACK text on WHITE backgrounds. ALWAYS.**

| Rule | Correct | WRONG |
|------|---------|-------|
| **Text color** | Black `#000000` | ~~White/gray on dark~~ |
| **Content background** | White `#FFFFFF` | ~~Dark backgrounds~~ |
| **Subtitle opacity** | Minimum 0.6 | ~~Below 0.5~~ |
| **Page titles** | Inside white container | ~~Floating on dark~~ |

**The Dark Background Rule:**
- Dark BG is the CANVAS only (outermost layer)
- Should be BARELY visible - just thin edges around white containers
- If you see more than 8pt of dark background anywhere, something is wrong

```swift
// ✅ CORRECT
ScrollView {
    VStack {
        Text("Page Title")
            .foregroundStyle(JohoColors.black)
    }
    .padding()
    .background(JohoColors.white)
    .clipShape(Squircle(cornerRadius: 16))
    .overlay(Squircle(...).stroke(JohoColors.black, lineWidth: 3))
}
.johoBackground()

// ❌ WRONG - Title floating on dark
ScrollView {
    Text("Page Title").foregroundStyle(.white)
    VStack { ... }.background(JohoColors.white)
}
```

---

## Border Specifications

**Every element MUST have a border. No exceptions.**

| Element Type | Border Width |
|--------------|--------------|
| Day cells | 1pt |
| List rows | 1.5pt |
| Buttons | 2pt |
| Today/Selected | 2.5pt |
| Containers | 3pt |

Border color is ALWAYS `#000000` (pure black).

---

## Typography

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

---

## Spacing Grid

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Cell gaps |
| sm | 8pt | Row gaps |
| md | 12pt | Container padding |
| lg | 16pt | Screen margins |

**Critical:** Maximum 8pt top padding on any screen!

---

## Corner Radius (Squircle)

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

---

## Type Indicator Circles (6-Color Mapping)

Type indicator circles show what kind of content exists. They ALWAYS have:
1. **Filled center** with the type's SEMANTIC COLOR
2. **BLACK border** (1-1.5pt stroke)
3. **Consistent sizing** based on context

| Type | Semantic | Color | Code |
|------|----------|-------|------|
| **Note** | NOW | Yellow `#FFE566` | NTE |
| **Trip** | SCHEDULED | Cyan `#A5F3FC` | TRP |
| **Event** | SCHEDULED | Cyan `#A5F3FC` | EVT |
| **Holiday** | CELEBRATION | Pink `#FECDD3` | HOL |
| **Birthday** | CELEBRATION | Pink `#FECDD3` | BDY |
| **Expense** | MONEY | Green `#BBF7D0` | EXP |
| **Contact** | PEOPLE | Purple `#E9D5FF` | CTN |

**Circle Sizes:**

| Context | Size | Border |
|---------|------|--------|
| Calendar grid | 7pt | 1pt |
| Collapsed row | 8pt | 1pt |
| Expanded items | 10pt | 1.5pt |
| Legend popover | 12pt | 1.5pt |

```swift
// ✅ CORRECT
Circle()
    .fill(type.accentColor)
    .frame(width: 10, height: 10)
    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))

// ❌ WRONG - No border
Circle().fill(accentColor).frame(width: 8, height: 8)
```

---

## Page Header Design

Each main page has its own header accent color:

| Page | Accent Hex | Icon | Meaning |
|------|------------|------|---------|
| **Calendar** | `#4338CA` | `calendar` | Time, structure |
| **Special Days** | `#D97706` | `star.fill` | Celebration |
| **Tools** | `#0D9488` | `wrench.and.screwdriver` | Productivity |
| **Contacts** | `#78350F` | `person.2` | Human connection |
| **Settings** | `#475569` | `gearshape` | Configuration |

**Header Structure:**
```
┌────────────────────────────────────────────────────────────────┐
│ ┌──────┬──────────────────────────────────────┬───────────────┐│
│ │ ICON │ TITLE                                │ CONTROLS      ││
│ │ 40pt │ PAGE NAME                            │   < 2026 >    ││
│ └──────┴──────────────────────────────────────┴───────────────┘│
└────────────────────────────────────────────────────────────────┘
```

---

## Bento Row Structure

Star Page uses compartmentalized bento rows:

```
┌─────┬──────────────────────────────┬─────────────────┐
│ ●🔒 │ Title Text                   │ SWE │ [⭐]      │
├─────┼──────────────────────────────┼─────────────────┤
│LEFT │ CENTER                       │ RIGHT           │
│28pt │ flexible                     │ 72pt            │
└─────┴──────────────────────────────┴─────────────────┘
```

- **LEFT**: Type indicator + lock (if system)
- **CENTER**: Item title (black text)
- **RIGHT**: Country pill + Decoration icon
- **Walls**: 1.5pt black vertical dividers

---

## Country Pills (Not Emoji Flags)

| Country | Background | Text | Code |
|---------|------------|------|------|
| **Sweden** | `#004B87` | `#FECC00` | SWE |
| **USA** | `#3C3B6E` | `#FFFFFF` | USA |
| **Vietnam** | `#DA251D` | `#FFCD00` | VN |

All country pills use black borders.

---

## Swipe Actions

| Direction | Action | Color | Icon |
|-----------|--------|-------|------|
| ← Left | Delete | Red `#E53935` | `trash` |
| → Right | Edit | Cyan `#A5F3FC` | `pencil` |

System items (lock icon) have NO swipe actions.

---

## Priority Symbols

| Symbol | Meaning | Usage |
|--------|---------|-------|
| **◎** | Primary | Most important |
| **○** | Secondary | Standard items |
| **△** | Tertiary | Optional |
| **✕** | Excluded | Don't use |

---

## マルバツ記号 (Maru-Batsu)

| Symbol | Name | SF Symbol | Meaning |
|--------|------|-----------|---------|
| ○ | Maru | `circle.fill` | Correct, yes |
| × | Batsu | `xmark` | Wrong, no |
| △ | Sankaku | `triangle.fill` | Caution |
| □ | Shikaku | `square.fill` | Neutral, info |
| ◇ | Hishigata | `diamond.fill` | Special |

---

## Icon Specifications

| Context | Weight | Size |
|---------|--------|------|
| Navigation | `.medium` | 20pt |
| List icons | `.medium` | 16pt |
| Buttons | `.semibold` | 18pt |
| Badges | `.bold` | 12pt |
| Hero display | `.bold` | 32pt |

---

## Animation Guidelines

| Animation | Duration | Curve |
|-----------|----------|-------|
| Expand/Collapse | 0.2s | easeInOut |
| Swipe snap | 0.15s | spring |
| Selection | 0.1s | easeOut |
| Page transition | 0.25s | easeInOut |

---

## ❌ FORBIDDEN PATTERNS

```swift
// ❌ GLASS/BLUR
.background(.ultraThinMaterial)
.background(.thinMaterial)

// ❌ GRADIENTS
LinearGradient(...)
RadialGradient(...)

// ❌ RAW SYSTEM COLORS
Color.blue  // Use JohoColors instead

// ❌ MISSING BORDERS
.background(Color.white)  // Missing stroke

// ❌ EXCESSIVE TOP PADDING
.padding(.top, 40)  // Max is 8pt

// ❌ NON-CONTINUOUS CORNERS
.cornerRadius(12)

// ❌ LOCALE-FORMATTED YEARS
Text("\(year)")  // Use String(year)

// ❌ BOUNCY ANIMATIONS
.spring(response: 0.5, dampingFraction: 0.5)

// ❌ iOS DatePicker
DatePicker("", selection: $date)  // NEVER use - use JohoCalendarPicker
```

---

## JohoCalendarPicker (情報デザイン Date Picker)

**MANDATORY: All date selection MUST use `JohoCalendarPicker`.** iOS DatePicker is forbidden.

### Features
- Week numbers column (W, 1-6) on left side
- Tap week number to select first day of that week
- Day headers (M T W T F S S)
- Black bordered cells (1pt)
- Yellow highlight for today
- Accent-colored DONE button (matches semantic zone)
- Floats as overlay over form content
- No black/gray background covering screen

### Usage Pattern

```swift
// State
@State private var showDatePicker = false
@State private var selectedDate = Date()

// Apply overlay modifier to container
VStack {
    // Form content...

    Button {
        withAnimation(.easeInOut(duration: 0.2)) {
            showDatePicker = true
        }
    } label: {
        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
    }
}
.johoCalendarPicker(
    isPresented: $showDatePicker,
    selectedDate: $selectedDate,
    accentColor: JohoColors.yellow  // Match semantic zone
)
```

### Accent Color by Zone

| Zone | Color | Example |
|------|-------|---------|
| NOW (memos) | `JohoColors.yellow` | Memo editor |
| CELEBRATION (holidays) | `JohoColors.pink` | Holiday editor |
| SCHEDULED (events) | `JohoColors.cyan` | Event editor |
| PEOPLE (contacts) | `JohoColors.purple` | Birthday editor |

### Visual Structure

```
┌─────────────────────────────────────────────────┐
│ [CANCEL]    SELECT DATE         [DONE]          │
├─────────────────────────────────────────────────┤
│    <        JANUARY 2026           >            │
├────┬────┬────┬────┬────┬────┬────┬────┤
│ W  │ M  │ T  │ W  │ T  │ F  │ S  │ S  │
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 1  │ 29 │ 30 │ 31 │  1 │  2 │  3 │  4 │
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 2  │  5 │  6 │  7 │  8 │  9 │ 10 │ 11 │
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 3  │ 12 │ 13 │ 14 │ 15 │ 16 │ 17 │ 18 │
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 4  │ 19 │ 20 │ 21 │ 22 │ 23 │ 24 │ 25 │
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 5  │ 26 │ 27 │ 28 │[29]│ 30 │ 31 │  1 │  ← [29] = today (yellow)
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 6  │  2 │  3 │  4 │  5 │  6 │  7 │  8 │
└────┴────┴────┴────┴────┴────┴────┴────┘
```

- Week column (W, 1-6): Black background, white text
- Today cell: Yellow background
- Other month days: 40% opacity
- All cells: 1pt black border

---

## Component Patterns

### Container
```swift
VStack { content }
.padding(12)
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(Color.black, lineWidth: 3)
)
```

### Pill/Badge
```swift
Text("LABEL")
    .font(.system(size: 12, weight: .bold, design: .rounded))
    .foregroundStyle(Color.white)
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(Color.black)
    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
```

### List Row
```swift
HStack(spacing: 12) {
    Image(systemName: "calendar")
        .frame(width: 40, height: 40)
        .background(Color(hex: "A5F3FC"))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(...).stroke(Color.black, lineWidth: 1.5))

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
.overlay(RoundedRectangle(...).stroke(Color.black, lineWidth: 1.5))
```

---

## Editor Sheet Header

```
┌─────────────────────────────────────────────────────────────┐
│ [◀] [Icon] TITLE TEXT                              [Save]  │
│            Subtitle text                                    │
└─────────────────────────────────────────────────────────────┘
```

| Component | Size | Notes |
|-----------|------|-------|
| Back button | 44×44pt | `chevron.left`, white bg |
| Icon zone | 52×52pt | Type icon, light tint bg |
| Title | Headline | UPPERCASE |
| Save button | Auto | Accent when valid |

Use `JohoEditorHeader` component.

---

## Design Audit Commands

```bash
# Find forbidden patterns
grep -rn "ultraThinMaterial\|thinMaterial" --include="*.swift"
grep -rn "\.cornerRadius(" --include="*.swift"
grep -rn "Color\.blue\|Color\.red" --include="*.swift"
grep -rn "LinearGradient\|RadialGradient" --include="*.swift"
grep -rn "\.padding(.top," --include="*.swift"
grep -rn "DatePicker(" --include="*.swift"  # Should return 0 results
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────┐
│         情報デザイン QUICK REFERENCE         │
├─────────────────────────────────────────────┤
│ 6-COLOR PALETTE (reduced cognitive load):   │
│   Yellow = NOW (today, notes)               │
│   Cyan   = SCHEDULED (events, trips)        │
│   Pink   = CELEBRATION (holidays, birthdays)│
│   Green  = MONEY (expenses)                 │
│   Purple = PEOPLE (contacts)                │
│   Red    = ALERT (system warnings only)     │
├─────────────────────────────────────────────┤
│ BORDERS: 1pt=cells, 1.5pt=rows,             │
│   2pt=buttons, 2.5pt=selected, 3pt=cards    │
├─────────────────────────────────────────────┤
│ SWIPE: →Right=Edit(Cyan), ←Left=Delete(Red) │
├─────────────────────────────────────────────┤
│ DATE PICKER: JohoCalendarPicker ONLY        │
│   .johoCalendarPicker(isPresented:          │
│     selectedDate:, accentColor:)            │
│   NEVER use iOS DatePicker                  │
├─────────────────────────────────────────────┤
│ FORBIDDEN: Glass, Gradients, Missing        │
│   borders, Raw colors, .cornerRadius()      │
│   Orange (use Cyan), Cream (use Yellow)     │
│   iOS DatePicker (use JohoCalendarPicker)   │
└─────────────────────────────────────────────┘
```

**Remember: You are the 情報デザイン Guardian.**
