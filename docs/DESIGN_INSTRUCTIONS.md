# Onsen Planner Website - Design Instructions

## CRITICAL: What I Got Wrong

The promotional website was built with a **bright cream background** (`#FFFBF5`).
This is **WRONG**. The actual app uses:

- **Dark canvas** (`#1A1A2E` or pure black `#000000`)
- **White cards** floating on the dark background
- The dark background is **barely visible** - just thin edges around cards

---

## The Correct 情報デザイン Visual System

### Color Palette

#### Canvas/Background (DARK - not bright!)
| Option | Hex | Usage |
|--------|-----|-------|
| **True Black** | `#000000` | AMOLED optimized (default) |
| **Dark Navy** | `#1A1A2E` | Warm dark alternative |
| **Near Black** | `#0A0A0F` | Subtle warmth |

#### Card/Surface Colors
| Element | Hex | Notes |
|---------|-----|-------|
| **Card Surface** | `#FFFFFF` | Pure white - ALL content cards |
| **Primary Text** | `#000000` | Pure black on white |
| **All Borders** | `#000000` | Every element has black border |

#### Semantic Colors (for zones within cards)
| Color | Hex | Meaning |
|-------|-----|---------|
| Yellow | `#FFE566` | NOW / Today / Present |
| Cyan | `#A5F3FC` | Events / Calendar / Scheduled |
| Pink | `#FECDD3` | Holidays / Celebrations |
| Orange | `#FED7AA` | Trips / Movement |
| Green | `#BBF7D0` | Expenses / Money |
| Purple | `#E9D5FF` | Contacts / People |
| Red | `#E53935` | Alerts / Warnings |
| Cream | `#FEF3C7` | Personal Notes (NOT background!) |

---

## Bento Layout System

### Core Principle
```
┌─────────────────────────────────────────┐
│ DARK CANVAS (barely visible - 8px max)  │
│  ┌─────────────────────────────────────┐│
│  │ WHITE CARD with BLACK BORDER        ││
│  │                                     ││
│  │  [Colored Zone] │ Content           ││
│  │  (semantic bg)  │ (black text)      ││
│  │                 │                   ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### Bento Card Structure
```
┌────────────────────────────────────────┐
│ HEADER ROW                             │  ← 8-12px padding
├────────────────────────────────────────┤  ← 1.5px black divider
│ CONTENT AREA                           │  ← 12px padding
└────────────────────────────────────────┘
     ↑ 2-3px black border, 12px radius
```

### Grid Layout (Star Page Style)
```
┌─────────┬─────────┬─────────┐
│  TILE   │  TILE   │  TILE   │
│ (color) │ (color) │ (color) │
├─────────┼─────────┼─────────┤
│  TILE   │  TILE   │  TILE   │
│ (color) │ (color) │ (color) │
└─────────┴─────────┴─────────┘
   8px gaps, 3-column grid
```

---

## Border Specifications

| Element | Border Width | Notes |
|---------|--------------|-------|
| Day cells | 1px | Smallest elements |
| List rows | 1.5px | Standard rows |
| Buttons | 2px | Interactive elements |
| Cards | 2px | Content containers |
| Selected/Today | 2.5-3px | Emphasis |
| Page containers | 3px | Major sections |

**RULE: Every visible element has a black border. No exceptions.**

---

## Typography

- **Font**: System rounded (SF Pro Rounded / Nunito for web)
- **Weights**: Medium minimum, Bold/Black for headers
- **Color**: Pure black `#000000` on white surfaces
- **UPPERCASE**: Labels, badges, section headers

---

## What NOT To Do

| Forbidden | Why |
|-----------|-----|
| Gradients | 情報デザイン uses solid colors only |
| Blur/Glass effects | No `.backdrop-filter` |
| Gray borders | Borders are always BLACK |
| Cream/bright backgrounds | Canvas is DARK |
| Shadows with blur | Use solid offset shadows only |
| Rounded corners without continuous | Use `border-radius` with large values |
| Text on dark backgrounds | Text goes in WHITE cards |
| Missing borders | Every element needs a border |

---

## Correct Website Structure

```html
<body style="background: #000000;">  <!-- DARK canvas -->

  <div class="page" style="max-width: 420px; padding: 8px;">

    <!-- Card floats on dark background -->
    <div class="card" style="
      background: #FFFFFF;
      border: 2px solid #000000;
      border-radius: 12px;
    ">
      <!-- Content with black text -->
    </div>

  </div>

</body>
```

---

## Bento Tile Styling

**IMPORTANT: App's starStyleGlanceTile has NO borders - just colored backgrounds!**

```css
/* Correct - matching app's LandingPageView.swift */
.bento-tile {
  background: var(--semantic-color);  /* Yellow, Cyan, Pink, etc. */
  border-radius: 12px;
  /* NO border - tiles are borderless colored surfaces */
  /* NO box-shadow */
}

.bento-tile-icon {
  width: 32px;
  height: 32px;
  color: #000000;  /* Black icons on colored background */
}

.bento-tile-label {
  font-size: 10px;
  font-weight: 900;
  color: #000000;
  text-transform: uppercase;
}
```

**Note:** Borders are used on CARDS (containers), not individual bento tiles.

---

## Screenshot Display

Screenshots should be displayed in white cards with black borders:

```css
.screenshot-card {
  background: #FFFFFF;
  border: 2px solid #000000;
  border-radius: 12px;
  padding: 8px;
  box-shadow: 4px 4px 0 0 #000000;
}

.screenshot-card img {
  border-radius: 8px;
  border: 1px solid #000000;
}
```

---

## Reference: App Screenshots Analysis

The app shows:
1. **Dark background** barely visible around white cards
2. **Bento grid** of colored tiles (3 columns)
3. **White containers** with thick black borders
4. **Colored zones** for semantic meaning
5. **Type indicator circles** (colored dots with black borders)

---

## Implementation Checklist

- [ ] Canvas/body background is DARK (#000000 or #1A1A2E)
- [ ] All content in WHITE cards (#FFFFFF)
- [ ] Every element has BLACK border (#000000)
- [ ] No gradients anywhere
- [ ] No blur/glass effects
- [ ] Borders are solid black (not gray, not colored)
- [ ] Typography is rounded design
- [ ] Semantic colors used correctly
- [ ] Bento compartmentalization with dividers
- [ ] Maximum 8px top padding (dark barely visible)
- [ ] Solid offset shadows only (no blur radius)
