# Chapter 6: Typography

> "Rounded letters. Heavy weights. No whispers."

---

Typography in Joho Dezain serves one purpose: instant legibility. Every choice—font family, weight, size, spacing—optimizes for reading speed and clarity.

---

## The Rounded Font Mandate

Joho Dezain uses rounded fonts exclusively. On Apple platforms, this means SF Pro Rounded.

Why rounded? Three reasons:

**1. Friendliness without weakness.**
Rounded letterforms feel approachable without sacrificing authority. Sharp corners can feel cold or aggressive. Rounded corners feel warm while maintaining professional clarity.

**2. Consistency with squircle geometry.**
The interface uses continuous corners everywhere. Rounded typography extends this visual language to text. Sharp-cornered letters in a squircle interface create subtle dissonance.

**3. Reduced visual noise.**
Sharp serifs and pointed terminals create complexity. Rounded terminals simplify letterforms, reducing the cognitive processing required to read.

```
SHARP TYPOGRAPHY:
The quick brown fox jumps over the lazy dog.
(Sharp terminals, angular joints)

ROUNDED TYPOGRAPHY:
The quick brown fox jumps over the lazy dog.
(Soft terminals, smooth joints)
```

In code:

```swift
// ✅ CORRECT - Rounded design
.font(.system(size: 16, weight: .medium, design: .rounded))

// ❌ WRONG - Default design (not rounded)
.font(.system(size: 16, weight: .medium))
.font(.body)
```

Every text element must include `.design(.rounded)`. No exceptions.

---

## The Type Scale

Joho Dezain uses a fixed type scale with seven levels:

| Name | Size | Weight | Usage |
|------|------|--------|-------|
| displayLarge | 48pt | .heavy | Hero numbers, week displays |
| displayMedium | 32pt | .bold | Section titles, page headers |
| headline | 18pt | .bold | Card titles, row headers |
| body | 16pt | .medium | Primary content, descriptions |
| bodySmall | 14pt | .medium | Secondary content, metadata |
| label | 12pt | .bold | Pills, badges, tags |
| labelSmall | 10pt | .bold | Timestamps, fine print |

### displayLarge (48pt, Heavy)

The largest text in the system. Reserved for hero moments—the primary number or word that defines a screen.

```
┌─────────────────────────────────────────┐
│                                         │
│              ▄▄▄▄   ▄▄▄▄                │
│             █    █ █    █               │
│             █    █  ████                │
│             █    █ █    █               │
│              ████   ████                │
│                                         │
│              WEEK 42                    │
│                                         │
└─────────────────────────────────────────┘
Hero number: 48pt heavy
```

Use sparingly. One displayLarge per screen maximum.

### displayMedium (32pt, Bold)

Section titles and page headers. Establishes major divisions in content.

```
┌─────────────────────────────────────────┐
│                                         │
│   SPECIAL DAYS                          │  ← 32pt bold
│                                         │
│   ┌─────────────────────────────────┐   │
│   │  Christmas Day                  │   │
│   └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### headline (18pt, Bold)

Card titles and row headers. The primary text of individual content items.

```
┌─────────────────────────────────────────┐
│                                         │
│   Team Standup Meeting                  │  ← 18pt bold
│   9:00 AM - Conference Room A           │  ← 14pt medium
│                                         │
└─────────────────────────────────────────┘
```

### body (16pt, Medium)

Primary content text. The default for any paragraph or description.

```
This is body text at 16pt medium weight.
It's used for descriptions, explanations,
and any content that users need to read
in full. Comfortable for extended reading.
```

### bodySmall (14pt, Medium)

Secondary content. Metadata, supporting information, less critical details.

```
┌─────────────────────────────────────────┐
│   Meeting with Client                   │  ← headline
│   Tomorrow at 2:00 PM                   │  ← bodySmall
│   Added 3 days ago                      │  ← bodySmall
└─────────────────────────────────────────┘
```

### label (12pt, Bold, UPPERCASE)

Pills, badges, and categorical tags. Always uppercase.

```
┌─────────────────────────────────────────┐
│   ┌────────┐  ┌────────┐  ┌────────┐   │
│   │ WORK   │  │ URGENT │  │ 2024   │   │
│   └────────┘  └────────┘  └────────┘   │
│                                         │
│   Labels: 12pt bold UPPERCASE          │
└─────────────────────────────────────────┘
```

### labelSmall (10pt, Bold)

Timestamps and fine print. The smallest readable text.

```
┌─────────────────────────────────────────┐
│   Document Title                        │
│   Last modified: Jan 8, 2026 at 11:30   │  ← 10pt bold
└─────────────────────────────────────────┘
```

Never go smaller than 10pt. Anything smaller fails accessibility.

---

## Weight Rules

Joho Dezain never uses light font weights.

| Weight | Allowed? | Usage |
|--------|----------|-------|
| .ultraLight | ❌ No | Never |
| .thin | ❌ No | Never |
| .light | ❌ No | Never |
| .regular | ⚠️ Rarely | Only if medium unavailable |
| .medium | ✅ Yes | Default for body text |
| .semibold | ✅ Yes | Emphasis within body |
| .bold | ✅ Yes | Headlines, labels |
| .heavy | ✅ Yes | Hero displays |
| .black | ✅ Yes | Maximum impact |

Light weights reduce contrast and legibility. They whisper when Joho Dezain should speak clearly.

```swift
// ✅ CORRECT
.font(.system(size: 16, weight: .medium, design: .rounded))
.font(.system(size: 18, weight: .bold, design: .rounded))

// ❌ WRONG
.font(.system(size: 16, weight: .light, design: .rounded))
.font(.system(size: 16, weight: .thin, design: .rounded))
```

---

## Labels Are Uppercase

All labels, badges, and pills use uppercase text. This is non-negotiable.

```
✅ CORRECT:
┌────────┐  ┌────────┐  ┌────────┐
│ EVENT  │  │ TODAY  │  │ 2026   │
└────────┘  └────────┘  └────────┘

❌ WRONG:
┌────────┐  ┌────────┐  ┌────────┐
│ Event  │  │ Today  │  │ 2026   │
└────────┘  └────────┘  └────────┘
```

Why uppercase?

1. **Increased legibility at small sizes.** Uppercase letters have more consistent height, making them easier to read at 12pt and below.

2. **Visual distinction.** Uppercase labels stand apart from body text, reinforcing their categorical nature.

3. **Symmetry.** Uppercase letters align more predictably in fixed-width containers.

In code:

```swift
Text("EVENT")
    .font(.system(size: 12, weight: .bold, design: .rounded))
    .textCase(.uppercase)  // Or just write "EVENT" directly
```

---

## Numeric Typography

Numbers require special attention in Joho Dezain.

### Monospaced Digits

When displaying numbers in columns or sequences, use monospaced digits:

```swift
Text("42")
    .font(.system(size: 48, weight: .heavy, design: .rounded))
    .monospacedDigit()
```

Monospaced digits ensure alignment:

```
WITH MONOSPACED DIGITS:
  Week 1
  Week 2
  Week 10
  Week 42
  (Numbers align perfectly)

WITHOUT MONOSPACED DIGITS:
  Week 1
  Week 2
  Week 10
  Week 42
  (Numbers shift based on character width)
```

### Year Formatting

Never use string interpolation with years:

```swift
// ❌ WRONG - May add locale formatting
Text("\(year)")

// ✅ CORRECT - Guaranteed clean output
Text(String(year))
```

String interpolation can add commas (2,026) or other locale-specific formatting. `String(year)` outputs exactly what you expect: 2026.

### Price Formatting

Format prices consistently:

```swift
// Currency with proper formatting
Text(price, format: .currency(code: "USD"))
    .font(.system(size: 16, weight: .medium, design: .rounded))
    .monospacedDigit()
```

---

## Text Color

Text color follows simple rules:

| Context | Color |
|---------|-------|
| On white/light backgrounds | Black (#000000) |
| On dark backgrounds | White (#FFFFFF) |
| On semantic color backgrounds | Black (usually) |
| Secondary/muted text | Black at 60% opacity |

```swift
// Primary text
.foregroundStyle(JohoColors.black)

// Secondary text
.foregroundStyle(JohoColors.black.opacity(0.6))

// Text on dark background
.foregroundStyle(JohoColors.white)
```

Never use gray as a text color. Use black with reduced opacity instead. This maintains color consistency while reducing visual weight.

---

## Line Height and Spacing

Default system line height works well with SF Pro Rounded. Avoid custom line spacing unless absolutely necessary.

For multi-line body text:

```swift
Text(longString)
    .font(.system(size: 16, weight: .medium, design: .rounded))
    .lineSpacing(4)  // Slight increase for readability
```

For labels and short text, use default spacing.

---

## Implementing the Type Scale

Define your type scale as reusable styles:

```swift
extension Font {
    static let johoDisplayLarge = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let johoDisplayMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    static let johoHeadline = Font.system(size: 18, weight: .bold, design: .rounded)
    static let johoBody = Font.system(size: 16, weight: .medium, design: .rounded)
    static let johoBodySmall = Font.system(size: 14, weight: .medium, design: .rounded)
    static let johoLabel = Font.system(size: 12, weight: .bold, design: .rounded)
    static let johoLabelSmall = Font.system(size: 10, weight: .bold, design: .rounded)
}

// Usage
Text("Week 42")
    .font(.johoDisplayLarge)
    .monospacedDigit()

Text("HOLIDAY")
    .font(.johoLabel)
    .textCase(.uppercase)
```

---

## Common Typography Mistakes

**Missing .design(.rounded):**
```swift
// ❌ WRONG
.font(.system(size: 16, weight: .medium))

// ✅ CORRECT
.font(.system(size: 16, weight: .medium, design: .rounded))
```

**Using light weights:**
```swift
// ❌ WRONG
.font(.system(size: 16, weight: .light, design: .rounded))

// ✅ CORRECT
.font(.system(size: 16, weight: .medium, design: .rounded))
```

**Lowercase labels:**
```swift
// ❌ WRONG
Text("event")
    .font(.johoLabel)

// ✅ CORRECT
Text("EVENT")
    .font(.johoLabel)
```

**Gray text instead of opacity:**
```swift
// ❌ WRONG
.foregroundStyle(Color.gray)

// ✅ CORRECT
.foregroundStyle(JohoColors.black.opacity(0.6))
```

**Non-monospaced numbers in columns:**
```swift
// ❌ WRONG - Numbers misalign
Text("\(number)")

// ✅ CORRECT - Numbers align
Text(String(number))
    .monospacedDigit()
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           Joho Dezain TYPOGRAPHY REFERENCE               │
│                                                         │
│   displayLarge   48pt  heavy   Hero numbers            │
│   displayMedium  32pt  bold    Section titles          │
│   headline       18pt  bold    Card titles             │
│   body           16pt  medium  Content                 │
│   bodySmall      14pt  medium  Secondary               │
│   label          12pt  bold    PILLS (UPPERCASE)       │
│   labelSmall     10pt  bold    Timestamps              │
│                                                         │
│   RULES:                                               │
│   • Always use .design(.rounded)                       │
│   • Never use weights below .medium                    │
│   • Labels are always UPPERCASE                        │
│   • Use .monospacedDigit() for numbers                 │
│   • Use String(year) not "\(year)"                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 7 — Spacing & Layout*
