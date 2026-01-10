# Chapter 18: Design Audit Checklist

> "Ship nothing that violates the system."

---

Every Joho Dezain interface should pass a comprehensive audit before release. This chapter provides the checklist, the tools to find violations, and the standards for compliance.

---

## The Complete Audit Checklist

### Borders

- [ ] **Every container has a border**
  - No borderless cards or sections
  - Containers: 3pt
  - Cards: 1.5pt
  - Buttons: 2pt
  - Selected states: 2.5pt
  - Grid cells: 1pt

- [ ] **All borders are black (#000000)**
  - No gray borders
  - No colored borders (except state indication)
  - No gradients on borders

### Colors

- [ ] **Only semantic palette colors used**
  - Yellow: Today/Now
  - Cyan: Events
  - Pink: Holidays
  - Orange: Trips
  - Green: Expenses
  - Purple: Contacts
  - Red: Warnings/Sunday
  - Black/White: Structure

- [ ] **No system colors**
  - No Color.blue
  - No Color.accentColor
  - No Color.primary
  - Use JohoColors exclusively

- [ ] **No emoji**
  - Replace all emoji with SF Symbols
  - Icons are monochrome

### Corners

- [ ] **All corners use .continuous style**
  - `.clipShape(RoundedRectangle(cornerRadius: X, style: .continuous))`
  - Never `.cornerRadius(X)`
  - Never `.clipShape(Circle())` for non-circular elements

- [ ] **Consistent radii within hierarchy**
  - Containers: 16pt
  - Cards: 12pt
  - Buttons: 8pt
  - Pills/badges: 6pt

### Typography

- [ ] **All fonts use .design(.rounded)**
  - `.font(.system(size: X, weight: Y, design: .rounded))`
  - Never plain `.font(.system(size: X))`
  - Never `.font(.body)` etc.

- [ ] **No light or thin weights**
  - Minimum weight: .medium
  - Headlines: .bold
  - Hero: .heavy

- [ ] **Labels are uppercase**
  - All pills, badges, section headers
  - `.textCase(.uppercase)` or direct "UPPERCASE"

- [ ] **Numbers use monospacedDigit()**
  - Week numbers
  - Dates
  - Prices
  - Any columnar data

### Spacing

- [ ] **All spacing on 4pt grid**
  - 4, 8, 12, 16, 20, 24, 32...
  - Never 5, 7, 10, 15...
  - Use JohoSpacing constants

- [ ] **Maximum 8pt top padding**
  - `.padding(.top, 8)` maximum
  - Never 16, 20, 32, 40...
  - Content starts immediately

- [ ] **Minimum 12pt between buttons**
  - Adjacent tap targets well-separated
  - Use JohoSpacing.md (12pt)

### Touch Targets

- [ ] **Minimum 44×44pt for all interactive elements**
  - `.frame(minWidth: 44, minHeight: 44)`
  - Small icons can be 16-20pt visually
  - Touch area must extend to 44pt

### Effects

- [ ] **No glass/blur effects**
  - No .ultraThinMaterial
  - No .blur()
  - No .opacity() for blur simulation

- [ ] **No shadows**
  - No .shadow()
  - Depth comes from borders only

- [ ] **No gradients**
  - No LinearGradient
  - No RadialGradient
  - Flat colors only

### Interaction

- [ ] **Swipe actions follow pattern**
  - Right swipe → Edit (Cyan)
  - Left swipe → Delete (Red)
  - System items (🔒) have no swipe

- [ ] **Selection uses 2.5pt border + yellow.opacity(0.3)**
  - Clear visual feedback
  - Consistent across all selectable items

---

## Audit Commands

Run these commands in your project directory to find violations:

### Find missing .rounded

```bash
grep -rn "\.font(\.system(" --include="*.swift" | \
  grep -v "design: .rounded"
```

### Find raw colors

```bash
grep -rn "Color\.blue\|Color\.red\|Color\.accentColor" --include="*.swift"
```

### Find non-continuous corners

```bash
grep -rn "\.cornerRadius(" --include="*.swift"
```

### Find glass effects

```bash
grep -rn "ultraThinMaterial\|\.blur(" --include="*.swift"
```

### Find shadows

```bash
grep -rn "\.shadow(" --include="*.swift"
```

### Find gradients

```bash
grep -rn "LinearGradient\|RadialGradient" --include="*.swift"
```

### Find excessive top padding

```bash
grep -rn "\.padding(\.top," --include="*.swift" | \
  grep -v "\.top, 4\|\.top, 8"
```

### Find emoji in code

```bash
grep -rP "[\x{1F300}-\x{1F9FF}]" --include="*.swift"
```

---

## Automated Audit Script

Save this as `audit-joho.sh`:

```bash
#!/bin/bash

echo "🔍 Joho Dezain Design Audit"
echo "=========================="
echo ""

# Colors
echo "📌 Checking for raw colors..."
RAW_COLORS=$(grep -rn "Color\.blue\|Color\.red\|Color\.accentColor\|Color\.primary" --include="*.swift" 2>/dev/null | wc -l)
if [ "$RAW_COLORS" -gt 0 ]; then
    echo "❌ Found $RAW_COLORS raw color references"
    grep -rn "Color\.blue\|Color\.red\|Color\.accentColor\|Color\.primary" --include="*.swift"
else
    echo "✅ No raw colors found"
fi
echo ""

# Rounded fonts
echo "📌 Checking for non-rounded fonts..."
NON_ROUNDED=$(grep -rn "\.font(\.system(" --include="*.swift" 2>/dev/null | grep -v "design: .rounded" | wc -l)
if [ "$NON_ROUNDED" -gt 0 ]; then
    echo "❌ Found $NON_ROUNDED fonts without .rounded"
else
    echo "✅ All fonts use .rounded"
fi
echo ""

# Corners
echo "📌 Checking for non-continuous corners..."
BAD_CORNERS=$(grep -rn "\.cornerRadius(" --include="*.swift" 2>/dev/null | wc -l)
if [ "$BAD_CORNERS" -gt 0 ]; then
    echo "❌ Found $BAD_CORNERS uses of .cornerRadius()"
else
    echo "✅ All corners use .continuous style"
fi
echo ""

# Effects
echo "📌 Checking for forbidden effects..."
EFFECTS=$(grep -rn "ultraThinMaterial\|\.blur(\|\.shadow(\|LinearGradient\|RadialGradient" --include="*.swift" 2>/dev/null | wc -l)
if [ "$EFFECTS" -gt 0 ]; then
    echo "❌ Found $EFFECTS forbidden effects"
else
    echo "✅ No glass, blur, shadow, or gradient effects"
fi
echo ""

echo "Audit complete."
```

Run with:
```bash
chmod +x audit-joho.sh
./audit-joho.sh
```

---

## Pre-Commit Hook

Add this to `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Joho Dezain pre-commit hook
VIOLATIONS=0

# Check for raw colors
if grep -rn "Color\.blue\|Color\.accentColor" --include="*.swift" > /dev/null 2>&1; then
    echo "❌ Commit blocked: Raw colors found (use JohoColors)"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check for non-rounded fonts
if grep -rn "\.font(\.system(" --include="*.swift" 2>/dev/null | grep -v "design: .rounded" > /dev/null; then
    echo "❌ Commit blocked: Fonts without .rounded found"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check for .cornerRadius
if grep -rn "\.cornerRadius(" --include="*.swift" > /dev/null 2>&1; then
    echo "❌ Commit blocked: Use RoundedRectangle(style: .continuous)"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check for forbidden effects
if grep -rn "ultraThinMaterial\|\.shadow(" --include="*.swift" > /dev/null 2>&1; then
    echo "❌ Commit blocked: Forbidden effects found"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

if [ "$VIOLATIONS" -gt 0 ]; then
    echo ""
    echo "Run ./audit-joho.sh for details"
    exit 1
fi

echo "✅ Joho Dezain compliance check passed"
exit 0
```

---

## Code Review Standards

When reviewing Joho Dezain code, verify:

### Level 1: Structural (Must Pass)

1. Every container has a black border
2. All corners use `.continuous` style
3. No forbidden effects (blur, shadow, gradient)
4. No raw Color values

### Level 2: Typography (Must Pass)

1. All fonts use `.design(.rounded)`
2. No weights below `.medium`
3. Labels are uppercase
4. Numbers use `.monospacedDigit()`

### Level 3: Spacing (Must Pass)

1. All values on 4pt grid
2. Top padding ≤ 8pt
3. Touch targets ≥ 44pt
4. Button spacing ≥ 12pt

### Level 4: Semantics (Should Pass)

1. Colors match content meaning
2. Border weights match hierarchy
3. Swipe actions follow convention
4. Selection states consistent

---

## Common Violation Patterns

### "It looks fine without borders"

**No.** Borders are not optional. If you think something looks cleaner without a border, you're designing for a different system.

### "I used a slightly different blue"

**No.** Use the semantic color that matches the content type. If there's no matching color, the content type doesn't belong in this interface.

### "The top padding felt cramped"

**No.** Content starts at the top. Users expect information immediately. Every pixel of top padding delays content.

### "I made the font lighter for hierarchy"

**No.** Use size and position for hierarchy, not weight. The minimum weight is `.medium`.

### "I added a subtle shadow for depth"

**No.** Borders create depth. Shadows create visual noise. Remove all shadows.

---

## Appendix A: Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│              Joho Dezain QUICK REFERENCE                    │
│                                                             │
│   BORDERS:                                                 │
│   Containers  3pt    Cards      1.5pt                      │
│   Buttons     2pt    Selected   2.5pt                      │
│   Cells       1pt                                          │
│                                                             │
│   COLORS:                                                  │
│   Yellow  #FFE566  Today     Cyan    #A5F3FC  Events       │
│   Pink    #FECDD3  Holidays  Orange  #FED7AA  Trips        │
│   Green   #BBF7D0  Money     Purple  #E9D5FF  People       │
│   Red     #E53935  Warning   Black/White: Structure        │
│                                                             │
│   TYPOGRAPHY:                                              │
│   displayLarge   48pt  heavy   displayMedium  32pt  bold   │
│   headline       18pt  bold    body           16pt  medium │
│   bodySmall      14pt  medium  label          12pt  bold   │
│   labelSmall     10pt  bold    ALL: .design(.rounded)      │
│                                                             │
│   SPACING:                                                 │
│   xs  4pt   sm  8pt   md  12pt  lg  16pt                  │
│   xl 20pt  xxl 24pt  xxxl 32pt                            │
│                                                             │
│   RULES:                                                   │
│   • Max 8pt top padding                                    │
│   • Min 44×44pt touch targets                              │
│   • Min 12pt between buttons                               │
│   • Always .continuous corners                             │
│   • Never shadow/blur/gradient                             │
│   • Never emoji                                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Appendix B: Border Width Decision Tree

```
Is it interactive (button, toggle, input)?
├── YES → 2pt border
│         Is it selected/focused?
│         └── YES → 2.5pt border
└── NO → Is it a major container (screen-level)?
         ├── YES → 3pt border
         └── NO → Is it a card or row?
                  ├── YES → 1.5pt border
                  └── NO → Is it a grid cell?
                           ├── YES → 1pt border
                           └── NO → 1.5pt border (default)
```

---

## Appendix C: Color Decision Tree

```
What type of content is this?

Time/State related (today, now, current)?
└── Yellow #FFE566

Events, meetings, appointments?
└── Cyan #A5F3FC

Holidays, special days, observances?
└── Pink #FECDD3

Travel, trips, vacation?
└── Orange #FED7AA

Money, expenses, financial?
└── Green #BBF7D0

People, contacts, birthdays?
└── Purple #E9D5FF

Warning, danger, error, Sunday?
└── Red #E53935

Structure, text, borders?
└── Black #000000 or White #FFFFFF

None of the above?
└── Don't add color. Use black/white.
```

---

## Conclusion

Joho Dezain is not about aesthetics—it's about communication. Every border, every color, every pixel serves the goal of making information instantly comprehensible.

The rules are strict because consistency is clarity. When every interface follows the same patterns, users don't have to learn each screen. They recognize the language.

Ship nothing that violates the system. Run the audit. Fix the violations. Then ship with confidence.

Your interfaces will be clear, consistent, and instantly understandable—like the best Japanese train station signage, the clearest emergency instructions, the most functional everyday objects.

That's Joho Dezain.

---

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                       THE END                               │
│                        (END)                                │
│                                                             │
│                    Joho Dezain                              │
│              Information Design for iOS                     │
│                                                             │
│                                                             │
│        "Clear information serves all people."              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

