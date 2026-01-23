# CLAUDE.md

## Project Overview

**Onsen Planner** — iOS 18+ week number app with semantic color coding.
Built with SwiftUI, SwiftData, WidgetKit.

- **Folder:** `Vecka` (legacy name)
- **Design:** 情報デザイン (Jōhō Dezain)

---

## ⚠️ MANDATORY: Read Before Working

| Task | Read First |
|------|------------|
| UI/View changes | `.claude/design-system.md` |
| Layout/Forms | `.claude/layout-rules.md` |
| Models/Architecture | `.claude/architecture.md` |
| Components | `.claude/COMPONENT_GLOSSARY.md` |
| Icons/Symbols | `.claude/japanese-symbol-language.md` |

**Violations are bugs. No exceptions.**

---

## Build Commands

```bash
./build.sh build    # Debug build
./build.sh test     # Run tests
./build.sh clean    # Clean
```

---

## 情報デザイン Rules (Summary)

### Colors (6-Color Palette)

| Color | Hex | Meaning |
|-------|-----|---------|
| Yellow | `#FFE566` | NOW - notes, today |
| Cyan | `#A5F3FC` | SCHEDULED - events, trips |
| Pink | `#FECDD3` | CELEBRATION - holidays |
| Green | `#BBF7D0` | MONEY - expenses |
| Purple | `#E9D5FF` | PEOPLE - contacts |
| Red | `#E53935` | ALERT - system only |

### Required Patterns

```swift
// Colors: JohoColors only
.foregroundStyle(JohoColors.black)

// Corners: squircle only
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

// Borders: always present
.overlay(RoundedRectangle(...).stroke(JohoColors.black, lineWidth: 1.5))

// Typography: rounded only
.font(.system(size: 16, weight: .medium, design: .rounded))

// Animation: easeInOut only
withAnimation(.easeInOut(duration: 0.2)) { ... }
```

### Forbidden (Auto-Reject)

```swift
.background(.ultraThinMaterial)  // NO glass
LinearGradient(...)              // NO gradients
Color.blue                       // NO raw colors
.cornerRadius(12)                // NO non-continuous
ScrollView { Form... }           // NO scroll in forms
.spring(...)                     // NO bouncy animations
```

### Border Widths

| Element | Width |
|---------|-------|
| Cells | 1pt |
| Rows | 1.5pt |
| Buttons | 2pt |
| Selected | 2.5pt |
| Containers | 3pt |

### Touch Targets

- **44×44pt minimum** for all interactive elements
- **12pt spacing** between buttons

---

## Layout Rules (Critical)

**NO VERTICAL SCROLLING** in forms, editors, or sheets.

Use instead:
- Collapsible sections (expand/collapse)
- Progressive disclosure
- Push content down when expanding

See `.claude/layout-rules.md` for full specification.

---

## File Structure

```
Vecka/
├── Core/                    # Week calculation
├── Models/                  # SwiftData models
├── Views/                   # SwiftUI views
├── Services/                # External APIs
├── JohoDesignSystem.swift   # Design components
```

---

## Checklist

Before committing UI:
- [ ] Black borders on all containers
- [ ] Colors match semantic meaning
- [ ] No glass/blur/gradients
- [ ] Squircle corners (`.continuous`)
- [ ] Rounded typography
- [ ] No vertical scroll in forms
- [ ] 44pt touch targets
