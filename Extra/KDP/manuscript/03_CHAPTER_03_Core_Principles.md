# Chapter 3: Core Principles

> "The seven rules. Memorize them. Apply them. Never break them."

---

This chapter defines the non-negotiable rules of Joho Dezain. These aren't guidelines or suggestions. They're laws. Every principle in this book derives from these seven rules.

---

## Principle 1: Everything Has a Border

The first rule is the most important. It's also the most frequently violated by designers coming from other traditions.

**Every container has a visible border.**

Not most containers. Not important containers. Every container.

```
┌─────────────────────────────────────────┐
│                                         │
│    This element has a border.           │
│    It is a discrete unit.               │
│    Your eye knows where it begins       │
│    and ends.                            │
│                                         │
└─────────────────────────────────────────┘
```

Without borders:

```

    This element has no border.
    It floats in space.
    Your eye must calculate its
    boundaries. That takes effort.

```

See the difference? The bordered element is instantly parseable. The borderless element requires your brain to construct invisible boundaries.

### Border Weights

Not all borders are equal. Joho Dezain uses a specific hierarchy:

| Element Type | Border Width | Example |
|--------------|--------------|---------|
| Cells, small elements | 1pt | Calendar day cells |
| List rows, sections | 1.5pt | Table rows |
| Buttons, interactive | 2pt | Action buttons |
| Selected, focused | 2.5pt | Active states |
| Containers, cards | 3pt | Main content areas |

This hierarchy communicates importance. A 3pt border says "this is a major container." A 1pt border says "this is a small element within a container."

### Border Color

Border color is always black (#000000). No gray. No colored borders. Black.

Why? Because black borders work on any background. They're visible on white. They're visible on colors. They create consistent visual rhythm regardless of content.

The only exception: white borders on dark backgrounds, maintaining the same weight hierarchy.

### Common Mistakes

**Missing borders entirely.** If you can't see where an element ends, it needs a border.

**Inconsistent weights.** If buttons sometimes have 2pt borders and sometimes have 1pt borders, your visual language is broken.

**Colored borders.** Unless you're indicating state (selected, error), stick to black.

**Borders that disappear.** A border that matches its background isn't a border—it's decoration.

---

## Principle 2: Color Is Semantic

In Joho Dezain, colors have meanings. They're not decorative choices. They're vocabulary.

The core palette:

| Color | Hex Code | Meaning | Usage |
|-------|----------|---------|-------|
| Yellow | #FFE566 | NOW / Present | Today, current item, attention |
| Cyan | #A5F3FC | Scheduled Time | Events, appointments, calendar |
| Pink | #FECDD3 | Special Day | Holidays, birthdays, celebrations |
| Orange | #FED7AA | Movement | Trips, travel, locations |
| Green | #BBF7D0 | Money | Expenses, financial items |
| Purple | #E9D5FF | People | Contacts, relationships |
| Red | #E53935 | Alert | Warnings, errors, Sundays |
| Black | #000000 | Definition | Borders, primary text |
| White | #FFFFFF | Content | Backgrounds, containers |

### The One-Meaning Rule

Each color has exactly one meaning. No exceptions.

If yellow means "now," yellow can't also mean "warning." If green means "money," green can't also mean "success."

This seems restrictive, and it is. That's the point. When colors are ambiguous, users can't learn them. When colors are consistent, users read them without thinking.

### How Users Learn Color Language

The first time a user sees yellow highlighting today's date, they notice: "yellow means today."

The second time, they confirm: "yes, yellow means today."

The third time, they stop noticing. Yellow is now unconsciously associated with the present moment. They scan for yellow without thinking.

This is the power of semantic color. Users develop fluency. Your interface becomes faster to read with each use.

But the moment yellow appears for a different reason, fluency breaks. "Wait, does yellow mean today or does it mean... something else?" The user must now actively interpret every yellow element. Speed is lost.

### Using Color

Color goes on backgrounds of containers that represent that concept.

- A today indicator? Yellow background.
- An event item? Cyan background.
- A holiday entry? Pink background.
- A trip card? Orange background.
- An expense row? Green background.
- A contact cell? Purple background.
- A warning banner? Red background.

The color fills the container. Text on top is black (or white if contrast requires).

### Not Using Color

Don't use color for:

- Decoration ("This section needs visual interest")
- Branding ("Our brand color is blue")
- Differentiation without meaning ("Let's make these items different colors")
- Emphasis without semantic meaning ("This is important, make it red")

If the color doesn't mean something, don't use it. Use black and white.

---

## Principle 3: Black Text on White Backgrounds

This rule seems almost insultingly basic. But it's violated constantly.

**Content areas have white backgrounds. Text is black.**

Not gray text. Not light text on dark backgrounds. Black text on white backgrounds.

```
┌─────────────────────────────────────────┐
│                                         │
│   This text is black (#000000)          │
│   This background is white (#FFFFFF)    │
│   Maximum contrast. Maximum legibility. │
│                                         │
└─────────────────────────────────────────┘
```

### The Dark Background Rule

"But my app has a dark theme," you say.

Fine. The dark background is your canvas—the outermost layer. But your content containers are still white (or very light). Text is still black (or very dark).

The dark background should be barely visible. Just thin edges showing between white containers. If you can see more than 8pt of dark background anywhere inside your content area, something is wrong.

```
Dark Background Canvas
┌────────────────────────────────────────────────────────┐
│                                                        │
│   ┌────────────────────────────────────────────────┐   │
│   │                                                │   │
│   │   White container with black text.             │   │
│   │                                                │   │
│   │   The dark background is just a thin          │   │
│   │   edge around this container.                  │   │
│   │                                                │   │
│   └────────────────────────────────────────────────┘   │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### Why High Contrast?

- **Accessibility.** Low contrast fails users with visual impairments.
- **Environmental robustness.** Screens in sunlight, dim rooms, various angles—high contrast works everywhere.
- **Cognitive ease.** Your brain processes high contrast faster.
- **Aging.** Users' vision degrades. High contrast ages well.

"But low contrast looks sophisticated," you say.

Sophistication that reduces usability isn't sophisticated. It's ego.

---

## Principle 4: Continuous Corners (Squircle)

All corners must use continuous curvature.

```swift
// ✅ CORRECT - Continuous corners
RoundedRectangle(cornerRadius: 12, style: .continuous)

// ❌ WRONG - Standard corners
RoundedRectangle(cornerRadius: 12)
.cornerRadius(12)  // This is also wrong
```

The difference is subtle but important. A standard rounded rectangle has a mathematical discontinuity where the curve meets the straight edge. A continuous corner (squircle) transitions smoothly.

### Corner Radius Values

| Element | Radius |
|---------|--------|
| Day cells | 8pt |
| Buttons | 8pt |
| Pills, badges | 6pt |
| Cards | 12pt |
| Containers | 16pt |

Larger elements get larger radii. Small elements get smaller radii. The proportion feels natural.

### Never Use .cornerRadius()

In SwiftUI, the `.cornerRadius()` modifier uses standard (non-continuous) corners. Always use `RoundedRectangle(cornerRadius:style:)` with `.continuous` instead.

---

## Principle 5: Compartmentalized Layouts

Information is grouped into visible containers. Related items share a container. Unrelated items get separate containers.

The bento box layout:

```
┌─────────────────────────────────────────────────────────┐
│ ┌─────────┬─────────────────────────────┬─────────────┐ │
│ │  Icon   │  Title and Description      │  Actions    │ │
│ │  Zone   │  Zone                       │  Zone       │ │
│ └─────────┴─────────────────────────────┴─────────────┘ │
└─────────────────────────────────────────────────────────┘
```

Each zone has:
- A defined purpose
- A visible boundary (even if just a divider line)
- Consistent sizing

### Nesting Containers

Containers can nest, but follow the border hierarchy:

```
Outer container (3pt border)
┌─────────────────────────────────────────────────────┐
│                                                     │
│   Section (1.5pt border)                           │
│   ┌───────────────────────────────────────────┐    │
│   │                                           │    │
│   │   Item (1pt border)                       │    │
│   │   ┌───────────────────────────────────┐   │    │
│   │   │  Content                          │   │    │
│   │   └───────────────────────────────────┘   │    │
│   │                                           │    │
│   └───────────────────────────────────────────┘    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Outer containers have thicker borders. Inner elements have thinner borders. This creates visual hierarchy without relying on size or position alone.

---

## Principle 6: Rounded Typography

All text uses rounded fonts. In iOS, this means SF Pro Rounded (via `.design(.rounded)`).

```swift
// ✅ CORRECT
.font(.system(size: 16, weight: .medium, design: .rounded))

// ❌ WRONG
.font(.system(size: 16, weight: .medium))  // Missing .rounded
.font(.body)  // System default, not rounded
```

### The Typography Scale

| Name | Size | Weight | Usage |
|------|------|--------|-------|
| displayLarge | 48pt | heavy | Hero numbers |
| displayMedium | 32pt | bold | Section titles |
| headline | 18pt | bold | Card titles |
| body | 16pt | medium | Content |
| bodySmall | 14pt | medium | Secondary content |
| label | 12pt | bold | Pills, badges (UPPERCASE) |
| labelSmall | 10pt | bold | Timestamps |

### Weight Rules

Never use font weights below `.medium`. Light and ultralight weights reduce legibility and contradict the bold aesthetic of Joho Dezain.

### Labels Are Uppercase

Pills, badges, and small labels are always UPPERCASE. This increases legibility at small sizes and creates visual distinction from body text.

---

## Principle 7: Maximum 8pt Top Padding

This rule seems oddly specific. It is. And it's critical.

The top of your content area should have no more than 8pt of padding before the first element.

Why? Because excessive top padding wastes the most valuable screen real estate. Users' eyes start at the top. Make them scroll past empty space and you've already lost them.

```
❌ WRONG - 40pt top padding
┌────────────────────────────────────────┐
│                                        │
│                                        │
│                                        │
│   Finally, content starts here         │
│                                        │
└────────────────────────────────────────┘

✅ CORRECT - 8pt top padding
┌────────────────────────────────────────┐
│   Content starts immediately           │
│                                        │
│   More content below                   │
│                                        │
└────────────────────────────────────────┘
```

---

## The Forbidden Patterns

The following are never acceptable in Joho Dezain:

### Glass/Blur Effects
```swift
// ❌ FORBIDDEN
.background(.ultraThinMaterial)
.background(.thinMaterial)
```
Glass effects reduce contrast and add visual noise. They're decoration, not communication.

### Gradients
```swift
// ❌ FORBIDDEN
LinearGradient(...)
RadialGradient(...)
```
Gradients are decorative. They don't communicate meaning.

### Raw System Colors
```swift
// ❌ FORBIDDEN
Color.blue
Color.red
Color.green
```
System colors have no semantic meaning in your design language. Use your defined palette.

### Missing Borders
```swift
// ❌ FORBIDDEN
.background(Color.white)  // Where's the border?
```
Every colored background needs a border.

### Non-Continuous Corners
```swift
// ❌ FORBIDDEN
.cornerRadius(12)
```
Always use `RoundedRectangle(cornerRadius:style:.continuous)`.

### Bouncy Animations
```swift
// ❌ FORBIDDEN
.spring(response: 0.5, dampingFraction: 0.5)
```
Animations should be quick and functional, not playful.

---

## Summary Card

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           Joho Dezain CORE PRINCIPLES                    │
│                                                         │
│   1. Everything has a border                           │
│   2. Color is semantic                                 │
│   3. Black text on white backgrounds                   │
│   4. Continuous corners (squircle)                     │
│   5. Compartmentalized layouts                         │
│   6. Rounded typography                                │
│   7. Maximum 8pt top padding                           │
│                                                         │
│   FORBIDDEN: Glass, gradients, raw colors,             │
│   missing borders, .cornerRadius()                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

These principles are non-negotiable. Every chapter that follows builds on them. Every component implements them. Every line of code respects them.

---

*Next: Chapter 4 — Color Semantics*
