# 情報デザイン (Jōhō Dezain) Bookmaking Style Guide

> Japanese Information Design principles for LLM-assisted book creation

---

## Philosophy

情報デザイン (Jōhō Dezain) translates to "Information Design" in Japanese. It embodies the clarity, warmth, and playfulness of Nintendo-era interface design combined with Line messenger's approachability and Tomodachi Life's charm.

**Core Principle:** Information should be clear, friendly, and never intimidating. Every element serves a purpose. Nothing is decorative without function.

---

## Color Palette

### Primary Colors (Strict)

| Color | Hex | Usage |
|-------|-----|-------|
| **Black** | `#000000` | Text, borders, primary elements |
| **White** | `#FFFFFF` | Backgrounds, cards, containers |

### Semantic Accent Colors

| Color | Hex | Meaning | Book Usage |
|-------|-----|---------|------------|
| **Yellow** | `#FFE566` | Today/Now/Current | Current chapter marker, "you are here" indicators |
| **Cyan** | `#A5F3FC` | Events/Activities | Event listings, activity sections |
| **Pink** | `#FECDD3` | Holidays/Celebrations | Special dates, celebration pages |
| **Orange** | `#FED7AA` | Trips/Travel | Journey sections, travel logs |
| **Green** | `#BBF7D0` | Money/Expenses | Financial sections, cost tables |
| **Purple** | `#E9D5FF` | Contacts/People | Character pages, contact lists |
| **Red** | `#E53935` | Warnings/Important | Critical notices, important warnings |

### Color Rules

1. **Never use gradients** - Flat colors only
2. **Never use blur/glass effects** - Solid backgrounds only
3. **Never use raw system colors** - Only the defined palette
4. **Semantic meaning is mandatory** - Colors must match their purpose

---

## Typography

### Font Family

**Primary:** Rounded sans-serif (similar to SF Rounded, Nunito, or Varela Round)

### Type Scale

| Element | Size | Weight | Usage |
|---------|------|--------|-------|
| **Title** | 24-32pt | Bold | Chapter titles, major headings |
| **Heading** | 18-20pt | Semibold | Section headings |
| **Body** | 14-16pt | Regular | Main content |
| **Caption** | 11-12pt | Regular | Footnotes, annotations |
| **Label** | 10-11pt | Bold | Category tags, small labels |

### Typography Rules

1. **Always use `.design(.rounded)`** - No sharp serifs
2. **Maximum 3 levels of hierarchy** per page
3. **Generous line height** (1.4-1.6x font size)
4. **Left-aligned text** (never justified)

---

## Borders & Containers

### Border Widths

| Element | Width | Usage |
|---------|-------|-------|
| **Light** | 1pt | Table cells, subtle dividers |
| **Medium** | 1.5pt | Cards, rows, standard containers |
| **Standard** | 2pt | Buttons, interactive elements |
| **Selected** | 2.5pt | Active/selected items |
| **Heavy** | 3pt | Main containers, page frames |

### Corner Radius

**All corners must use continuous (squircle) curves**, never circular arcs.

| Element | Radius |
|---------|--------|
| Small pills/tags | 4-6pt |
| Cards/buttons | 8-12pt |
| Large containers | 16-20pt |
| Full-page frames | 24pt |

### Container Rules

1. **Every container has a visible border** - No borderless floating elements
2. **Borders are always black** - Unless indicating selection state
3. **White backgrounds inside containers** - Content areas are always white
4. **Consistent padding** - 8pt, 12pt, 16pt, or 24pt increments

---

## Spacing System

### Spacing Scale (8pt Base Grid)

| Token | Value | Usage |
|-------|-------|-------|
| `spacing-xs` | 4pt | Tight inline spacing |
| `spacing-sm` | 8pt | Component internal padding |
| `spacing-md` | 12pt | Standard gaps |
| `spacing-lg` | 16pt | Section spacing |
| `spacing-xl` | 24pt | Major divisions |
| `spacing-xxl` | 32pt | Page margins |

### Spacing Rules

1. **Maximum 8pt top padding** in any scrollable content
2. **Consistent vertical rhythm** - Use the 8pt grid
3. **Generous whitespace** - Let content breathe
4. **No orphaned elements** - Group related items

---

## Icons & Symbols

### Approved Symbols (マルバツ System)

| Symbol | Meaning | Usage |
|--------|---------|-------|
| `○` (Maru) | Correct, available, positive | Checkmarks, availability |
| `×` (Batsu) | Incorrect, unavailable, negative | Crosses, errors |
| `△` (Sankaku) | Warning, caution, partial | Warnings, incomplete |
| `※` (Kome) | Note, reference, important | Footnotes, annotations |
| `★` (Hoshi) | Favorite, special, featured | Highlights, favorites |
| `●` (Kuro Maru) | Active, current, selected | Current state indicators |

### Icon Rules

1. **NO EMOJI** - Never use emoji in any context
2. **Text symbols preferred** - Use ○ × △ ※ ★ ● over SF Symbols when possible
3. **Monochrome icons** - Icons match text color
4. **Consistent weight** - Medium weight (not too thin, not too heavy)
5. **16pt standard size** - For inline icons with text

---

## Layout Patterns

### Bento Grid (重箱 Jūbako)

The signature layout inspired by Japanese bento boxes:

```
┌─────────────┬─────────────┬─────────────┐
│             │             │             │
│   Cell 1    │   Cell 2    │   Cell 3    │
│             │             │             │
├─────────────┼─────────────┼─────────────┤
│             │             │             │
│   Cell 4    │   Cell 5    │   Cell 6    │
│             │             │             │
└─────────────┴─────────────┴─────────────┘
```

- Equal-sized cells with consistent borders
- Each cell is self-contained
- Black borders between all cells
- Can span multiple columns/rows

### Card Layout

```
┌────────────────────────────────────────┐
│ ┌────────────────────────────────────┐ │
│ │  HEADER                            │ │
│ └────────────────────────────────────┘ │
│                                        │
│  Content area with generous padding    │
│                                        │
│ ┌──────────┐  ┌──────────┐            │
│ │  Action  │  │  Action  │            │
│ └──────────┘  └──────────┘            │
└────────────────────────────────────────┘
```

### List Layout

```
┌────────────────────────────────────────┐
│ ○  Item text                        → │
├────────────────────────────────────────┤
│ ○  Item text                        → │
├────────────────────────────────────────┤
│ ○  Item text                        → │
└────────────────────────────────────────┘
```

- 1pt dividers between rows
- Icon on left, chevron on right
- Full-width tappable area

---

## Page Structure

### Chapter Opening

```
┌────────────────────────────────────────┐
│                                        │
│                                        │
│           CHAPTER NUMBER               │
│           (large, centered)            │
│                                        │
│           Chapter Title                │
│           (semibold, centered)         │
│                                        │
│                                        │
│  ────────────────────────────────────  │
│                                        │
│           Brief intro text             │
│                                        │
└────────────────────────────────────────┘
```

### Content Page

```
┌────────────────────────────────────────┐
│  Section Header                   ★ 3  │
│  subtitle text                         │
├────────────────────────────────────────┤
│                                        │
│  Body content with rounded typography  │
│  and generous line spacing.            │
│                                        │
│  ┌─────────────────────────────────┐   │
│  │  Callout box with 1.5pt border  │   │
│  │  and light accent background    │   │
│  └─────────────────────────────────┘   │
│                                        │
└────────────────────────────────────────┘
```

---

## Interactive Elements (For Digital Books)

### Buttons

```
┌──────────────────┐    ┌──────────────────┐
│   Primary        │    │   Secondary      │
│   (black fill)   │    │   (white fill)   │
└──────────────────┘    └──────────────────┘
     2pt border              2pt border
     white text              black text
```

### Pills/Tags

```
┌─────────┐  ┌─────────┐  ┌─────────┐
│  TAG 1  │  │  TAG 2  │  │  TAG 3  │
└─────────┘  └─────────┘  └─────────┘
   6pt radius, 1.5pt border, semantic colors
```

---

## What to AVOID

### Strictly Forbidden

1. **Emojis** - Never use emoji anywhere
2. **Gradients** - No color gradients of any kind
3. **Blur/Glass effects** - No frosted glass or blur
4. **Drop shadows** - No shadows (use borders instead)
5. **Circular corners** - Use continuous (squircle) only
6. **Thin hairline fonts** - Minimum regular weight
7. **Justified text** - Left-align only
8. **Decorative elements** - Everything must have purpose

### Common Mistakes

- Using colors without semantic meaning
- Mixing border weights inconsistently
- Forgetting borders on containers
- Using sharp corners instead of squircles
- Adding decorative icons that don't convey information

---

## Checklist for 情報デザイン Compliance

Before finalizing any page:

- [ ] All containers have black borders
- [ ] Colors match their semantic meaning
- [ ] No emojis, gradients, or blur effects
- [ ] All corners use continuous (squircle) style
- [ ] Typography uses rounded design
- [ ] Spacing follows 8pt grid
- [ ] Maximum 8pt top padding
- [ ] Icons use correct weight (medium)
- [ ] No decorative-only elements
- [ ] Clear visual hierarchy (max 3 levels)

---

## Quick Reference JSON

```json
{
  "design_system": "情報デザイン",
  "colors": {
    "primary": {
      "black": "#000000",
      "white": "#FFFFFF"
    },
    "semantic": {
      "today": "#FFE566",
      "events": "#A5F3FC",
      "holidays": "#FECDD3",
      "trips": "#FED7AA",
      "money": "#BBF7D0",
      "people": "#E9D5FF",
      "warning": "#E53935"
    }
  },
  "typography": {
    "family": "rounded-sans-serif",
    "sizes": {
      "title": "24-32pt",
      "heading": "18-20pt",
      "body": "14-16pt",
      "caption": "11-12pt",
      "label": "10-11pt"
    }
  },
  "borders": {
    "light": "1pt",
    "medium": "1.5pt",
    "standard": "2pt",
    "selected": "2.5pt",
    "heavy": "3pt"
  },
  "radius": {
    "style": "continuous-squircle",
    "small": "4-6pt",
    "medium": "8-12pt",
    "large": "16-20pt"
  },
  "spacing": {
    "base": "8pt",
    "scale": ["4pt", "8pt", "12pt", "16pt", "24pt", "32pt"]
  },
  "symbols": ["○", "×", "△", "※", "★", "●"],
  "forbidden": ["emoji", "gradients", "blur", "shadows", "circular-corners", "justified-text"]
}
```

---

*This guide enables any LLM to apply 情報デザイン principles to book design, maintaining the warm, clear, and purposeful aesthetic of Japanese information design.*
