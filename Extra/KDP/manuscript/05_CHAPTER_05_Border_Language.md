# Chapter 5: Border Language

> "A border is not decoration. A border is definition."

---

Borders are the most distinctive feature of Joho Dezain. Where other design systems treat borders as optional styling, Joho Dezain treats them as grammatical—as essential to meaning as words in a sentence.

---

## Why Every Element Needs a Border

Consider two UI elements. One has a border. One doesn't.

```
WITH BORDER:
┌─────────────────────────────────────────┐
│                                         │
│   This card has a defined boundary.     │
│   Your eye knows instantly where it     │
│   begins and ends.                      │
│                                         │
└─────────────────────────────────────────┘

WITHOUT BORDER:

   This card floats in space.
   Your eye must construct imaginary
   boundaries based on content edges.


```

The bordered element is a *thing*. It exists as a discrete unit. The borderless element is content that happens to be grouped—but grouping must be inferred.

This inference takes cognitive effort. Not much—milliseconds—but those milliseconds accumulate. In an interface with dozens of elements, borderless design creates a constant low-level processing burden.

Bordered design eliminates this burden. Every element announces itself: "I am a thing. Here are my edges. This is my territory."

---

## The Border Hierarchy

Not all borders are equal. Joho Dezain uses five specific border weights, each communicating something different:

| Weight | Use Case | Signal |
|--------|----------|--------|
| 1pt | Cells, small elements | "I am a unit within a larger structure" |
| 1.5pt | Rows, sections | "I am a grouping mechanism" |
| 2pt | Buttons, interactive elements | "I respond to touch" |
| 2.5pt | Selected, focused states | "I am currently active" |
| 3pt | Containers, cards | "I am a major content area" |

This hierarchy is absolute. A container never has a 1pt border. A cell never has a 3pt border. The weight tells the user what kind of element they're looking at before they read any content.

---

## 1pt Borders: The Atoms

1pt borders define the smallest meaningful units—the atoms of your interface.

**Calendar day cells:**
```
┌───┬───┬───┬───┬───┬───┬───┐
│ M │ T │ W │ T │ F │ S │ S │
├───┼───┼───┼───┼───┼───┼───┤
│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │
├───┼───┼───┼───┼───┼───┼───┤
│ 8 │ 9 │10 │11 │12 │13 │14 │
└───┴───┴───┴───┴───┴───┴───┘
Each cell: 1pt border
```

**Type indicator dots:**
```
● ○ ◆ ◇
Each circle/shape: 1pt border (even on fills)
```

**Table cells:**
```
┌──────────┬──────────┬──────────┐
│  Cell A  │  Cell B  │  Cell C  │
└──────────┴──────────┴──────────┘
Internal cell dividers: 1pt
```

The 1pt border says: "I am one piece of a larger puzzle."

---

## 1.5pt Borders: The Molecules

1.5pt borders group atoms into meaningful collections—the molecules of your interface.

**List rows:**
```
┌───────────────────────────────────────────────────────┐
│  ☀ Morning workout                              9:00  │
├───────────────────────────────────────────────────────┤
│  📞 Call with Sarah                            10:30  │
├───────────────────────────────────────────────────────┤
│  ✏️ Review documents                            14:00  │
└───────────────────────────────────────────────────────┘
Row separators: 1.5pt
```

**Section dividers:**
```
┌───────────────────────────────────────────────────────┐
│  UPCOMING                                             │
│  ─────────────────────────────────────────────────── │
│  Item 1                                               │
│  Item 2                                               │
│  ─────────────────────────────────────────────────── │
│  COMPLETED                                            │
│  ─────────────────────────────────────────────────── │
│  Item 3                                               │
└───────────────────────────────────────────────────────┘
Section dividers: 1.5pt
```

**Bento compartment walls:**
```
┌─────┬──────────────────────────┬─────────────────────┐
│ ●   │  Event Title             │  [Badge]  [Icon]    │
│     │  Description             │                     │
└─────┴──────────────────────────┴─────────────────────┘
Internal vertical walls: 1.5pt
```

The 1.5pt border says: "I organize things into groups."

---

## 2pt Borders: Interactive Elements

2pt borders signal interactivity—elements that respond to touch.

**Buttons:**
```
┌─────────────────┐   ┌─────────────────┐
│     Cancel      │   │      Save       │
└─────────────────┘   └─────────────────┘
Button borders: 2pt
```

**Input fields:**
```
┌─────────────────────────────────────────┐
│  Enter your name...                     │
└─────────────────────────────────────────┘
Input border: 2pt
```

**Toggles:**
```
┌────────────────────────┐
│  ●○                    │  OFF
└────────────────────────┘
Toggle track border: 2pt
```

The 2pt border says: "Touch me. I do something."

Users learn this quickly. They scan for 2pt borders when looking for actions. The heavier weight catches the eye, inviting interaction.

---

## 2.5pt Borders: Active States

2.5pt borders indicate selection or focus—elements currently receiving attention.

**Selected calendar day:**
```
┌───┬───┬───┬───┬───────┬───┬───┐
│ M │ T │ W │ T │▐▐ F ▐▐│ S │ S │
├───┼───┼───┼───┼───────┼───┼───┤
Normal cells: 1pt
Selected cell: 2.5pt (bold)
```

**Focused input:**
```
Normal state (2pt):
┌─────────────────────────────────────────┐
│                                         │
└─────────────────────────────────────────┘

Focused state (2.5pt):
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
│                                         │
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

**Selected list item:**
```
┌───────────────────────────────────────────────────────┐
│  Item 1                                               │
┝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┥
│  Item 2  (SELECTED)                                   │
┝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┥
│  Item 3                                               │
└───────────────────────────────────────────────────────┘
Selected row: 2.5pt
```

The 2.5pt border says: "I am the active element. Your attention is here."

---

## 3pt Borders: Containers

3pt borders define major content areas—the containers that hold everything else.

**Main content card:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
│                                                       │
│   This is a major content container.                  │
│                                                       │
│   It holds rows (1.5pt), cells (1pt),                │
│   and buttons (2pt).                                  │
│                                                       │
│   The 3pt border establishes it as                    │
│   the top level of hierarchy.                         │
│                                                       │
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
Container border: 3pt
```

**Modal dialogs:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
│                                               │
│   Are you sure you want to delete?            │
│                                               │
│       ┌─────────┐   ┌─────────┐              │
│       │ Cancel  │   │ Delete  │              │
│       └─────────┘   └─────────┘              │
│                                               │
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
Dialog container: 3pt
Buttons inside: 2pt
```

The 3pt border says: "I am a major element. Everything inside me is subordinate."

---

## Nested Borders

When containers nest, border weights create visual hierarchy:

```
Outer container (3pt)
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
│                                                       │
│   Section (1.5pt)                                     │
│   ┌───────────────────────────────────────────────┐   │
│   │                                               │   │
│   │   Row (1.5pt)                                 │   │
│   │   ┌───────────────────────────────────────┐   │   │
│   │   │  Cell  │  Cell  │  Cell  │  Cell      │   │   │
│   │   └───────────────────────────────────────┘   │   │
│   │   1pt internal borders                        │   │
│   │                                               │   │
│   └───────────────────────────────────────────────┘   │
│                                                       │
│   Button area                                         │
│   ┌────────────┐   ┌────────────┐                    │
│   │   Cancel   │   │    Save    │                    │
│   └────────────┘   └────────────┘                    │
│   2pt button borders                                  │
│                                                       │
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

The rule: **outer containers have heavier borders than inner elements.**

This creates a clear hierarchy. Your eye follows the weight gradient: 3pt defines the overall container, 1.5pt organizes internal structure, 1pt delineates individual units.

---

## Border Color

In Joho Dezain, borders are black. Always.

```swift
// ✅ CORRECT
.stroke(JohoColors.black, lineWidth: 1.5)

// ❌ WRONG
.stroke(Color.gray, lineWidth: 1.5)
.stroke(JohoColors.cyan, lineWidth: 1.5)
.stroke(someColor.opacity(0.5), lineWidth: 1.5)
```

Exceptions are rare:
- White borders on dark backgrounds (inverted contexts)
- No other exceptions

Colored borders violate the semantic color principle. If a border is cyan, does that mean the element is event-related? Confusion results.

Gray borders reduce contrast. They become invisible at certain sizes or on certain backgrounds.

Transparent borders aren't borders at all.

Black borders work universally. They're visible on white backgrounds, on colored backgrounds, at any size. They create consistent visual rhythm.

---

## Implementing Borders

In SwiftUI, borders are applied via overlay:

```swift
// Container with 3pt border
VStack {
    // content
}
.padding(12)
.background(JohoColors.white)
.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(JohoColors.black, lineWidth: 3)
)

// Row with 1.5pt border
HStack {
    // content
}
.padding(8)
.background(JohoColors.white)
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(JohoColors.black, lineWidth: 1.5)
)

// Button with 2pt border
Button(action: {}) {
    Text("Action")
}
.padding(.horizontal, 16)
.padding(.vertical, 8)
.background(JohoColors.white)
.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(JohoColors.black, lineWidth: 2)
)
```

---

## Common Border Mistakes

**Missing borders entirely:**
```swift
// ❌ WRONG - no border
.background(JohoColors.cyan)

// ✅ CORRECT - with border
.background(JohoColors.cyan)
.clipShape(...)
.overlay(...stroke(JohoColors.black, lineWidth: 1.5))
```

**Wrong weight for element type:**
```swift
// ❌ WRONG - 3pt on a button
.stroke(JohoColors.black, lineWidth: 3)

// ✅ CORRECT - 2pt on a button
.stroke(JohoColors.black, lineWidth: 2)
```

**Colored borders:**
```swift
// ❌ WRONG - semantic color as border
.stroke(JohoColors.cyan, lineWidth: 1.5)

// ✅ CORRECT - black border, semantic background
.background(JohoColors.cyan)
.overlay(...stroke(JohoColors.black, lineWidth: 1.5))
```

**Disappearing borders:**
```swift
// ❌ WRONG - gray on white is barely visible
.stroke(Color.gray.opacity(0.3), lineWidth: 1)

// ✅ CORRECT - black is always visible
.stroke(JohoColors.black, lineWidth: 1)
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           Joho Dezain BORDER REFERENCE                   │
│                                                         │
│   1pt    ─────  Cells, small elements, indicators      │
│   1.5pt  ━━━━━  Rows, sections, compartment walls      │
│   2pt    ▬▬▬▬▬  Buttons, inputs, interactive           │
│   2.5pt  ▰▰▰▰▰  Selected, focused states               │
│   3pt    █████  Containers, cards, dialogs             │
│                                                         │
│   COLOR: Always black (#000000)                        │
│   EXCEPTION: White on dark backgrounds                 │
│                                                         │
│   Rule: Every visible element has a border.            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 6 — Typography*
