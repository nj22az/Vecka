# Chapter 7: Spacing & Layout

> "Every gap has a purpose. No pixel is accidental."

---

Spacing in Joho Dezain follows a strict system. Every measurement derives from a 4pt base unit. Every gap communicates something about the relationship between elements.

---

## The 4pt Grid

All spacing in Joho Dezain is divisible by 4:

```
4pt   = xs (extra small)
8pt   = sm (small)
12pt  = md (medium)
16pt  = lg (large)
20pt  = xl (extra large)
24pt  = 2xl
32pt  = 3xl
```

Why 4pt? Because it scales cleanly across device resolutions and creates consistent rhythm. A 4pt base means your spacing is always 4, 8, 12, 16, 20, 24, 32... never 5, 7, 13, 19.

```swift
struct JohoSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}
```

---

## Spacing Tokens

Joho Dezain uses four primary spacing tokens:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Cell gaps, tight grouping |
| sm | 8pt | Row gaps, element spacing |
| md | 12pt | Container padding, section gaps |
| lg | 16pt | Screen margins, major divisions |

### xs (4pt) — Tight Grouping

Use xs for elements that belong together as a single unit:

```
┌─────────────────────────────────────────┐
│   ●←4pt→Label                           │
│   ↑                                     │
│   Icon and label: 4pt gap               │
└─────────────────────────────────────────┘
```

```swift
HStack(spacing: JohoSpacing.xs) {
    Circle().frame(width: 8, height: 8)
    Text("Label")
}
```

### sm (8pt) — Element Spacing

Use sm for spacing between related elements:

```
┌─────────────────────────────────────────┐
│   Item 1                                │
│   ←──────── 8pt ────────→               │
│   Item 2                                │
│   ←──────── 8pt ────────→               │
│   Item 3                                │
└─────────────────────────────────────────┘
```

```swift
VStack(spacing: JohoSpacing.sm) {
    ItemRow()
    ItemRow()
    ItemRow()
}
```

### md (12pt) — Container Padding

Use md for internal padding of containers:

```
┌─────────────────────────────────────────┐
│ ↑                                       │
│ 12pt                                    │
│ ←12pt  Content goes here          12pt→ │
│                                         │
│ 12pt                                    │
│ ↓                                       │
└─────────────────────────────────────────┘
```

```swift
VStack {
    // content
}
.padding(JohoSpacing.md)
```

### lg (16pt) — Screen Margins

Use lg for screen-level margins:

```
┌─ Screen Edge ─────────────────────────────────────┐
│                                                   │
│  ←16pt→ ┌─────────────────────────────┐ ←16pt→   │
│         │                             │           │
│         │     Content Container       │           │
│         │                             │           │
│         └─────────────────────────────┘           │
│                                                   │
└───────────────────────────────────────────────────┘
```

```swift
ScrollView {
    VStack {
        // content
    }
    .padding(.horizontal, JohoSpacing.lg)
}
```

---

## The 8pt Maximum Top Padding Rule

This rule is critical and frequently violated: **No more than 8pt of padding at the top of a content area.**

```
❌ WRONG - 40pt top padding:
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                                         │
│   Content finally starts here           │
│                                         │
└─────────────────────────────────────────┘
Wasted space. User must scroll past nothing.

✅ CORRECT - 8pt top padding:
┌─────────────────────────────────────────┐
│   Content starts immediately            │
│                                         │
│   More content here                     │
│                                         │
└─────────────────────────────────────────┘
Efficient. User sees content immediately.
```

Top padding is the most expensive real estate in your interface. Users' eyes start at the top. Every pixel of empty space delays content.

```swift
// ❌ WRONG
.padding(.top, 40)
.padding(.top, 32)
.padding(.top, 20)

// ✅ CORRECT
.padding(.top, JohoSpacing.sm)  // 8pt
.padding(.top, 4)
.padding(.top, 0)
```

---

## Touch Target Minimums

Every interactive element must have a minimum touch target of 44×44pt.

```
┌─────────────────────────────────────────┐
│                                         │
│      ┌─────────────────┐                │
│      │                 │                │
│      │   Small Icon    │ ← Visual: 20pt │
│      │                 │                │
│      └─────────────────┘                │
│   ┌─────────────────────────┐           │
│   │                         │           │
│   │    Touch Target         │ ← Hit: 44pt│
│   │                         │           │
│   └─────────────────────────┘           │
│                                         │
└─────────────────────────────────────────┘
```

A small icon can be 20pt visually, but its tappable area must extend to at least 44pt:

```swift
Button(action: { }) {
    Image(systemName: "plus")
        .font(.system(size: 16))
}
.frame(minWidth: 44, minHeight: 44)  // Touch target
```

### Spacing Between Touch Targets

Maintain at least 12pt between adjacent touch targets to prevent accidental taps:

```
┌─────────────────────────────────────────┐
│                                         │
│   [Button A]  ←12pt→  [Button B]        │
│                                         │
└─────────────────────────────────────────┘
```

```swift
HStack(spacing: JohoSpacing.md) {  // 12pt
    Button("Cancel") { }
    Button("Save") { }
}
```

---

## Layout Patterns

### Full-Width Container

Content that spans the full width with standard margins:

```
┌─ Screen ─────────────────────────────────┐
│ ←16pt→ ┌────────────────────────┐ ←16pt→ │
│        │                        │        │
│        │   Full-width content   │        │
│        │                        │        │
│        └────────────────────────┘        │
└──────────────────────────────────────────┘
```

```swift
VStack {
    ContentContainer()
}
.padding(.horizontal, JohoSpacing.lg)
```

### Card Stack

Cards stacked vertically with consistent spacing:

```
┌─────────────────────────────────────────┐
│  ┌───────────────────────────────────┐  │
│  │  Card 1                           │  │
│  └───────────────────────────────────┘  │
│  ←────────────── 8pt ──────────────→    │
│  ┌───────────────────────────────────┐  │
│  │  Card 2                           │  │
│  └───────────────────────────────────┘  │
│  ←────────────── 8pt ──────────────→    │
│  ┌───────────────────────────────────┐  │
│  │  Card 3                           │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

```swift
VStack(spacing: JohoSpacing.sm) {
    Card1()
    Card2()
    Card3()
}
.padding(JohoSpacing.lg)
```

### Bento Layout

The signature Joho Dezain layout—compartmentalized content:

```
┌─────────────────────────────────────────────────────────┐
│ ┌─────────┬──────────────────────────┬────────────────┐ │
│ │         │                          │                │ │
│ │  Zone A │        Zone B            │    Zone C      │ │
│ │  (fixed)│       (flexible)         │    (fixed)     │ │
│ │         │                          │                │ │
│ └─────────┴──────────────────────────┴────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

```swift
HStack(spacing: 0) {
    // Zone A - Fixed width
    VStack { }
        .frame(width: 44)
        .border(JohoColors.black, width: 1.5)

    // Zone B - Flexible
    VStack { }
        .frame(maxWidth: .infinity)
        .border(JohoColors.black, width: 1.5)

    // Zone C - Fixed width
    VStack { }
        .frame(width: 80)
        .border(JohoColors.black, width: 1.5)
}
```

### Grid Layout

For calendar-style grids:

```
┌───┬───┬───┬───┬───┬───┬───┐
│ M │ T │ W │ T │ F │ S │ S │
├───┼───┼───┼───┼───┼───┼───┤
│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │
├───┼───┼───┼───┼───┼───┼───┤
│ 8 │ 9 │10 │11 │12 │13 │14 │
└───┴───┴───┴───┴───┴───┴───┘
Cell gaps: 4pt (xs)
```

```swift
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: JohoSpacing.xs), count: 7), spacing: JohoSpacing.xs) {
    ForEach(days) { day in
        DayCell(day: day)
    }
}
```

---

## Safe Area Handling

Respect safe areas but don't add excessive padding:

```swift
// ✅ CORRECT - Content respects safe area naturally
ScrollView {
    VStack {
        // content
    }
    .padding(.horizontal, JohoSpacing.lg)
}

// ❌ WRONG - Double safe area padding
ScrollView {
    VStack {
        // content
    }
    .padding()
    .padding(.top, 44)  // Redundant with safe area
}
```

For elements that should extend to edges (like a header background), ignore safe area selectively:

```swift
VStack {
    HeaderBackground()
        .ignoresSafeArea(edges: .top)

    Content()
}
```

---

## Responsive Spacing

On larger screens (iPad), spacing can increase proportionally:

```swift
struct AdaptiveSpacing {
    @Environment(\.horizontalSizeClass) var sizeClass

    var containerPadding: CGFloat {
        sizeClass == .regular ? JohoSpacing.xl : JohoSpacing.lg
    }

    var itemSpacing: CGFloat {
        sizeClass == .regular ? JohoSpacing.md : JohoSpacing.sm
    }
}
```

However, don't over-complicate. The base spacing tokens work well across most contexts.

---

## Common Spacing Mistakes

**Inconsistent gaps:**
```swift
// ❌ WRONG - Mixed arbitrary values
VStack(spacing: 10) { }
VStack(spacing: 15) { }
VStack(spacing: 7) { }

// ✅ CORRECT - Consistent token values
VStack(spacing: JohoSpacing.sm) { }  // 8pt
VStack(spacing: JohoSpacing.md) { }  // 12pt
```

**Excessive top padding:**
```swift
// ❌ WRONG
.padding(.top, 32)

// ✅ CORRECT
.padding(.top, JohoSpacing.sm)  // 8pt max
```

**Tiny touch targets:**
```swift
// ❌ WRONG - Too small to tap
Button { } label: {
    Image(systemName: "plus")
}
.frame(width: 24, height: 24)

// ✅ CORRECT - Proper touch target
Button { } label: {
    Image(systemName: "plus")
}
.frame(minWidth: 44, minHeight: 44)
```

**Buttons too close:**
```swift
// ❌ WRONG - Buttons touching
HStack(spacing: 4) {
    Button("A") { }
    Button("B") { }
}

// ✅ CORRECT - Adequate separation
HStack(spacing: JohoSpacing.md) {  // 12pt
    Button("A") { }
    Button("B") { }
}
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           Joho Dezain SPACING REFERENCE                  │
│                                                         │
│   xs   4pt   Cell gaps, tight grouping                 │
│   sm   8pt   Row gaps, element spacing                 │
│   md  12pt   Container padding, sections               │
│   lg  16pt   Screen margins                            │
│                                                         │
│   RULES:                                               │
│   • All spacing divisible by 4                         │
│   • Maximum 8pt top padding                            │
│   • Minimum 44×44pt touch targets                      │
│   • Minimum 12pt between buttons                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 8 — Japanese Symbol Language*
