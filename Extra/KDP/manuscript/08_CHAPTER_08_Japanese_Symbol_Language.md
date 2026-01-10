# Chapter 8: Japanese Symbol Language

> "The shapes ARE the language."

---

Japan has developed the world's most sophisticated system of visual communication symbols. In Joho Dezain, we inherit this tradition—using shapes and symbols that communicate meaning independent of language.

---

## The Maru-Batsu System

At the foundation of Japanese visual language is Maru-Batsu (○×)—a system of shapes with universal meanings.

| Symbol | Name | Meaning |
|--------|------|---------|
| ◎ | Nijū-maru (double circle) | Excellent, best, highly recommended |
| ○ | Maru (circle) | Good, yes, correct, positive |
| △ | Sankaku (triangle) | Caution, partial, maybe |
| □ | Shikaku (square) | Note, reference, neutral information |
| × | Batsu (cross) | No, wrong, failed, negative |
| ー | Bō (bar) | Not applicable, none |

This system predates PlayStation—but PlayStation's controller buttons (○×△□) are directly derived from it. In Japan, ○ confirms and × cancels. (Western games inverted this, causing decades of confusion.)

### Why Maru-Batsu Works

On Japanese tests, correct answers are marked ○. Wrong answers are marked ×. Every Japanese person learns this in elementary school.

This creates a population-wide visual vocabulary. No explanation needed. ○ means yes. × means no. The shapes communicate across languages, ages, and contexts.

Joho Dezain leverages this literacy. When you use ○ for positive states and × for negative states, you're speaking a language your users already know.

---

## Filled vs. Outlined Symbols

Filled and outlined versions communicate intensity:

| Filled | Outlined | Meaning Difference |
|--------|----------|-------------------|
| ● Kuro-maru | ○ Shiro-maru | Strong yes vs. Standard yes |
| ▲ Kuro-sankaku | △ Shiro-sankaku | Strong warning vs. Mild caution |
| ■ Kuro-shikaku | □ Shiro-shikaku | Active/Selected vs. Inactive |
| ◆ Kuro-hishi | ◇ Shiro-hishi | Important vs. Notable |

Use filled symbols for emphasis, outlined for standard states:

```
Content present:  ●  (filled = has content)
Content optional: ○  (outlined = available)
Selected item:    ■  (filled = active)
Available item:   □  (outlined = inactive)
```

---

## Reference Marks

Japanese documents use specific marks for notes and references:

| Symbol | Name | Usage |
|--------|------|-------|
| ※ | Kome-jirushi | Important note (THE most common reference mark) |
| ★ | Kuro-boshi | Important highlight |
| ☆ | Shiro-boshi | Standard highlight |
| † | Dagger | Footnote |
| ‡ | Double dagger | Secondary footnote |
| § | Section | Section reference |

The ※ symbol (kome-jirushi, "rice mark") is ubiquitous in Japanese text. It signals "pay attention to this note." If you see only one Japanese reference mark in your life, it will be ※.

---

## Calendar Symbols

Japanese calendars use specific markers for special days:

| Symbol | Meaning | Romaji |
|--------|---------|--------|
| Shuku | National holiday | Shukujitsu |
| Kyu | Rest day, closed | Yasumi |
| Furi | Substitute holiday | Furikae kyujitsu |
| ● | Day has content | - |
| ◎ | Important date | - |

### Day Color Conventions

In Japanese calendars, Sundays are red. This convention comes from the traditional association of Sunday (*nichiyobi*) with the sun, which is red in Japanese iconography.

| Day | Traditional Color |
|-----|------------------|
| Sunday | Red |
| Saturday | Blue (often) |
| Weekdays | Black |

Joho Dezain follows this: Sundays use red text or red indicators.

---

## Why No Emoji

Emoji are forbidden in Joho Dezain. This seems restrictive—emoji are expressive and universal. But they violate core principles:

**1. Emoji are colorful.**
Emoji have fixed colors that can't be controlled. They break the semantic color system.

**2. Emoji render differently across platforms.**
The same emoji looks different on iOS, Android, Windows, and web. Inconsistent rendering breaks visual harmony.

**3. Emoji are decorative.**
Emoji express emotion. Joho Dezain communicates information. These are different goals.

**4. Emoji have variable sizing.**
Emoji don't align consistently with text. They create visual noise.

Instead of emoji, use SF Symbols (on Apple platforms) or equivalent monochrome icon systems:

| Concept | ❌ Emoji | ✅ SF Symbol |
|---------|----------|-------------|
| Warning | ⚠️ | `exclamationmark.triangle` |
| Star | ⭐ | `star.fill` |
| Heart | ❤️ | `heart.fill` |
| Location | 📍 | `mappin` |
| Fire | 🔥 | `flame` |
| Check | ✅ | `checkmark` |

SF Symbols are monochrome, scalable, and visually consistent. They communicate without decoration.

---

## SF Symbol Mapping

Here's how to map common concepts to SF Symbols:

### Maru-Batsu Equivalents

| Concept | SF Symbol | Unicode |
|---------|-----------|---------|
| Yes/Positive | `circle` / `circle.fill` | ○ ● |
| Excellent | `circle.circle` | ◎ |
| No/Cancel | `xmark` | × |
| Caution | `triangle` / `triangle.fill` | △ ▲ |
| Info/Neutral | `square` / `square.fill` | □ ■ |
| Special | `diamond` / `diamond.fill` | ◇ ◆ |

### Status Symbols

| Concept | SF Symbol |
|---------|-----------|
| Check/Complete | `checkmark` |
| Warning | `exclamationmark.triangle` |
| Error | `xmark.circle` |
| Info | `info.circle` |
| Prohibited | `nosign` |
| Important | `star.fill` |

### Navigation Symbols

| Concept | SF Symbol |
|---------|-----------|
| Forward | `chevron.right` |
| Back | `chevron.left` |
| Expand | `chevron.down` |
| Collapse | `chevron.up` |
| More | `ellipsis` |

### Content Type Symbols

| Type | SF Symbol |
|------|-----------|
| Calendar | `calendar` |
| Event | `clock` |
| Note | `doc.text` |
| Contact | `person` |
| Location | `mappin` |
| Money | `dollarsign.circle` |

---

## Icon Specifications

Icons in Joho Dezain follow specific size and weight rules:

| Context | Weight | Size |
|---------|--------|------|
| Navigation | .medium | 20pt |
| List icons | .medium | 16pt |
| Buttons | .semibold | 18pt |
| Badges | .bold | 12pt |
| Hero display | .bold | 32pt |

Never use thin or ultralight icon weights. Icons should be clearly visible and match the bold aesthetic of Joho Dezain.

```swift
// Navigation icon
Image(systemName: "chevron.right")
    .font(.system(size: 20, weight: .medium))

// List icon
Image(systemName: "calendar")
    .font(.system(size: 16, weight: .medium))

// Button icon
Image(systemName: "plus")
    .font(.system(size: 18, weight: .semibold))
```

---

## Type Indicator Circles

In Joho Dezain, small colored circles indicate content type. These are used in calendars and lists to show what kind of items exist:

| Type | Color | Code |
|------|-------|------|
| Holiday | Red #E53E3E | HOL |
| Observance | Orange #ED8936 | OBS |
| Event | Purple #805AD5 | EVT |
| Birthday | Pink #D53F8C | BDY |
| Note | Yellow #ECC94B | NTE |
| Trip | Blue #3182CE | TRP |
| Expense | Green #38A169 | EXP |

**Critical:** Indicator circles always have black borders.

```swift
Circle()
    .fill(typeColor)
    .frame(width: 10, height: 10)
    .overlay(
        Circle()
            .stroke(JohoColors.black, lineWidth: 1.5)
    )
```

Circle sizes vary by context:

| Context | Size | Border |
|---------|------|--------|
| Calendar grid | 7pt | 1pt |
| Collapsed row | 8pt | 1pt |
| Expanded items | 10pt | 1.5pt |
| Legend | 12pt | 1.5pt |

---

## Implementing Symbols

### Basic Symbol View

```swift
struct JohoSymbol: View {
    let symbol: String
    var size: CGFloat = 16
    var weight: Font.Weight = .medium

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(JohoColors.black)
    }
}

// Usage
JohoSymbol(symbol: "checkmark", size: 18, weight: .bold)
```

### Indicator Circle View

```swift
struct JohoIndicator: View {
    let color: Color
    var size: CGFloat = 10
    var borderWidth: CGFloat = 1.5

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}

// Usage
JohoIndicator(color: JohoColors.cyan, size: 10)  // Event indicator
JohoIndicator(color: JohoColors.pink, size: 10)  // Holiday indicator
```

---

## Symbol Combinations

Symbols can combine to create compound meanings:

```
Status + Type:
●✓  = Completed event (filled circle + check)
○⚠  = Available with warning
■★  = Selected and important

Hierarchy:
◎ → ○ → △ → ×
Best → Good → Caution → Bad
```

In implementation:

```swift
HStack(spacing: JohoSpacing.xs) {
    JohoIndicator(color: JohoColors.cyan)
    JohoSymbol(symbol: "checkmark", size: 12, weight: .bold)
}
// Shows: completed event
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           Joho Dezain SYMBOL REFERENCE                   │
│                                                         │
│   MARU-BATSU:                                          │
│   ◎ Excellent  ○ Good  △ Caution  □ Info  × No        │
│                                                         │
│   FILLED VS OUTLINED:                                  │
│   ● Strong yes    ○ Standard yes                       │
│   ▲ Strong warn   △ Mild caution                       │
│   ■ Active        □ Inactive                           │
│                                                         │
│   REFERENCE:                                           │
│   ※ Note  ★ Important  ☆ Highlight                    │
│                                                         │
│   CALENDAR:                                            │
│   Shuku=Holiday  Kyu=Rest  Furi=Substitute             │
│   Sundays = Red text                                   │
│                                                         │
│   FORBIDDEN: All emoji                                 │
│   USE INSTEAD: SF Symbols (monochrome)                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 9 — Containers & Cards*
