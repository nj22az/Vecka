# 情報デザイン Compliance Rules System

> Automated rules and audit tools for enforcing Japanese Information Design principles.

---

## Quick Compliance Check

Run this one-liner to check for common violations:

```bash
cd /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka && \
grep -rn "ultraThinMaterial\|thinMaterial\|\.cornerRadius(" --include="*.swift" Vecka/ | head -20
```

---

## Rule Categories

### 1. COLOR RULES

| Rule ID | Description | Severity |
|---------|-------------|----------|
| COL-001 | Never use raw system colors (`Color.blue`, `Color.red`) | ERROR |
| COL-002 | Always use `JohoColors.black/white` for text | ERROR |
| COL-003 | Semantic colors must match their meaning | WARNING |
| COL-004 | Text opacity minimum 0.6 for readability | WARNING |

**Audit Command:**
```bash
# Find raw system colors
grep -rn "Color\.blue\|Color\.red\|Color\.green\|Color\.orange\|Color\.purple\|Color\.yellow\|Color\.gray" --include="*.swift" Vecka/
```

**Allowed Exceptions:**
- Inside `JohoColors` enum definitions
- Inside `CountryColorScheme` for flag colors

---

### 2. BORDER RULES

| Rule ID | Description | Severity |
|---------|-------------|----------|
| BRD-001 | Every container MUST have a black border | ERROR |
| BRD-002 | Day cells: 1pt border | WARNING |
| BRD-003 | List rows: 1.5pt border | WARNING |
| BRD-004 | Buttons: 2pt border | WARNING |
| BRD-005 | Containers: 3pt border | WARNING |

**Audit Command:**
```bash
# Find backgrounds without borders (requires manual review)
grep -rn "\.background(JohoColors\." --include="*.swift" Vecka/ | grep -v "overlay\|stroke"
```

---

### 3. CORNER RADIUS RULES

| Rule ID | Description | Severity |
|---------|-------------|----------|
| RAD-001 | Never use `.cornerRadius()` modifier | ERROR |
| RAD-002 | Always use `Squircle` or `RoundedRectangle(..., style: .continuous)` | ERROR |

**Audit Command:**
```bash
# Find non-continuous corners
grep -rn "\.cornerRadius(" --include="*.swift" Vecka/
```

**Correct Pattern:**
```swift
// CORRECT
.clipShape(Squircle(cornerRadius: 12))
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

// WRONG
.cornerRadius(12)
```

---

### 4. VISUAL EFFECT RULES

| Rule ID | Description | Severity |
|---------|-------------|----------|
| VFX-001 | Never use glass/blur materials | ERROR |
| VFX-002 | Never use gradients | ERROR |
| VFX-003 | Avoid drop shadows | WARNING |

**Audit Command:**
```bash
# Find forbidden visual effects
grep -rn "ultraThinMaterial\|thinMaterial\|\.blur\|LinearGradient\|RadialGradient\|\.shadow" --include="*.swift" Vecka/
```

---

### 5. SPACING RULES

| Rule ID | Description | Severity |
|---------|-------------|----------|
| SPC-001 | Maximum 8pt top padding on screens | ERROR |
| SPC-002 | Use JohoDimensions tokens for spacing | WARNING |

**Audit Command:**
```bash
# Find excessive top padding
grep -rn "\.padding(\.top," --include="*.swift" Vecka/ | grep -v "spacingSM\|spacingXS\|8\|4"
```

---

### 6. TYPOGRAPHY RULES

| Rule ID | Description | Severity |
|---------|-------------|----------|
| TYP-001 | Always use `.design(.rounded)` with fonts | WARNING |
| TYP-002 | Minimum font weight is `.medium` | WARNING |
| TYP-003 | Labels and pills MUST be UPPERCASE | WARNING |
| TYP-004 | Use JohoFont tokens for consistency | WARNING |

**Audit Command:**
```bash
# Find fonts without rounded design
grep -rn "Font\.system(size:" --include="*.swift" Vecka/ | grep -v "design: .rounded"
```

---

### 7. LOCALIZATION RULES

| Rule ID | Description | Severity |
|---------|-------------|----------|
| LOC-001 | Never use `"\(year)"` - use `String(year)` | ERROR |
| LOC-002 | Use `Text(verbatim:)` for numbers | WARNING |

**Audit Command:**
```bash
# Find locale-formatted numbers in strings
grep -rn 'Text("\\(' --include="*.swift" Vecka/
```

---

### 8. ANIMATION RULES

| Rule ID | Description | Severity |
|---------|-------------|----------|
| ANI-001 | No bouncy springs (dampingFraction < 0.7) | WARNING |
| ANI-002 | Max animation duration 0.3s | WARNING |

**Audit Command:**
```bash
# Find bouncy animations
grep -rn "dampingFraction: 0\.[0-6]" --include="*.swift" Vecka/
```

---

## Full Audit Script

Save this as `audit_joho.sh` in the project root:

```bash
#!/bin/bash

# 情報デザイン Compliance Audit Script
# Run: ./audit_joho.sh

PROJECT_DIR="/Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka"
VIOLATIONS=0

echo "====================================="
echo "情報デザイン COMPLIANCE AUDIT"
echo "====================================="
echo ""

# Function to check and report
check_rule() {
    local rule_id="$1"
    local description="$2"
    local pattern="$3"
    local severity="$4"

    local count=$(grep -rn "$pattern" --include="*.swift" "$PROJECT_DIR" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$count" -gt 0 ]; then
        echo "[$severity] $rule_id: $description"
        echo "   Found: $count occurrence(s)"
        grep -rn "$pattern" --include="*.swift" "$PROJECT_DIR" 2>/dev/null | head -5
        echo ""
        VIOLATIONS=$((VIOLATIONS + count))
    fi
}

# Run checks
check_rule "COL-001" "Raw system colors" "Color\.blue\|Color\.red\|Color\.purple" "ERROR"
check_rule "RAD-001" "Non-continuous corners" "\.cornerRadius(" "ERROR"
check_rule "VFX-001" "Glass/blur materials" "ultraThinMaterial\|thinMaterial" "ERROR"
check_rule "VFX-002" "Gradients" "LinearGradient\|RadialGradient" "ERROR"
check_rule "SPC-001" "Excessive top padding" "\.padding(\.top, [1-9][0-9]" "ERROR"
check_rule "TYP-001" "Font without rounded design" 'Font\.system(size: [0-9]' "WARNING"

echo "====================================="
if [ "$VIOLATIONS" -eq 0 ]; then
    echo "RESULT: PASS - No violations found"
else
    echo "RESULT: $VIOLATIONS potential violation(s) found"
    echo "Review each finding - some may be false positives"
fi
echo "====================================="
```

---

## Semantic Color Reference

| Purpose | Color | Hex | JohoColors |
|---------|-------|-----|------------|
| **NOW/Present** | Yellow | `#FFE566` | `.yellow` |
| **Events/Scheduled** | Cyan | `#A5F3FC` | `.cyan` |
| **Holidays** | Pink | `#FECDD3` | `.pink` |
| **Trips/Movement** | Orange | `#FED7AA` | `.orange` |
| **Money/Expenses** | Green | `#BBF7D0` | `.green` |
| **People/Contacts** | Purple | `#E9D5FF` | `.purple` |
| **Alerts/Warnings** | Red | `#E53935` | `.red` |
| **Notes/Personal** | Cream | `#FEF3C7` | `.cream` |
| **Text/Borders** | Black | `#000000` | `.black` |
| **Container BG** | White | `#FFFFFF` | `.white` |

---

## Border Width Reference

| Element | Width | JohoDimensions |
|---------|-------|----------------|
| Day cells | 1pt | `.borderThin` |
| List rows | 1.5pt | - |
| Buttons | 2pt | `.borderMedium` |
| Today/Selected | 2.5pt | - |
| Containers | 3pt | `.borderThick` |

---

## Component Checklist

When creating a new component, verify:

- [ ] Uses `Squircle` or continuous corners
- [ ] Has black border with correct width
- [ ] Uses JohoColors (not raw colors)
- [ ] Uses JohoFont tokens
- [ ] Text is black on white background
- [ ] Opacity minimum 0.6 for secondary text
- [ ] No glass/blur/gradients
- [ ] Minimum 44x44pt touch targets
- [ ] Animation duration <= 0.3s

---

## Quick Fix Patterns

### Fix .cornerRadius()
```swift
// Before
.cornerRadius(12)

// After
.clipShape(Squircle(cornerRadius: 12))
```

### Fix raw colors
```swift
// Before
.foregroundStyle(Color.blue)

// After
.foregroundStyle(JohoColors.cyan)  // or appropriate semantic color
```

### Fix missing border
```swift
// Before
.background(JohoColors.white)

// After
.background(JohoColors.white)
.clipShape(Squircle(cornerRadius: 12))
.overlay(Squircle(cornerRadius: 12).stroke(JohoColors.black, lineWidth: 2))
```

### Fix year formatting
```swift
// Before
Text("\(year)")

// After
Text(verbatim: String(year))
```

---

## Integration with Claude Code

When reviewing code, Claude should:

1. **Before any UI change:** Run `grep -rn ".cornerRadius(" --include="*.swift" Vecka/`
2. **After edits:** Verify no new violations introduced
3. **In code reviews:** Check against this ruleset

---

## Violation Tracking

| Date | File | Rule | Status |
|------|------|------|--------|
| 2026-01-05 | - | - | Initial audit needed |

---

*Last Updated: 2026-01-05*
*Guardian: Claude Code*
