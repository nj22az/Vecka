# CLAUDE.md

> **Last Updated:** 2026-01-31

## Project Overview

**Onsen Planner** — iOS 18+ week number app with semantic color coding.
Built with SwiftUI, SwiftData, WidgetKit.

- **Folder:** `Vecka` (legacy name)
- **Design:** 情報デザイン (Jōhō Dezain)
- **Files:** 112 Swift (100 app + 12 widget)

---

## Documentation Map

| Document | Purpose |
|----------|---------|
| **`.claude/GOLDEN_STANDARD.md`** | Single source of truth (colors, components, patterns) |
| **`.claude/FILE_REGISTRY.md`** | Complete file inventory |
| **`.claude/design-system.md`** | Visual specification |
| **`.claude/architecture.md`** | Technical structure |
| **`.claude/layout-rules.md`** | Interaction rules |
| **`.claude/COMPONENT_GLOSSARY.md`** | Component details |
| **`.claude/widgets.md`** | Widget implementation |
| **`.claude/japanese-symbol-language.md`** | Symbol guide |
| **`.claude/NEW_APP_GUIDE.md`** | Building new apps |

---

## Build Commands

```bash
./build.sh build    # Debug build
./build.sh test     # Run tests
./build.sh clean    # Clean
```

---

## Quick Reference

### 6-Color Semantic Palette

| Color | Hex | Meaning |
|-------|-----|---------|
| Yellow | `#FFE566` | NOW - notes, today |
| Cyan | `#A5F3FC` | SCHEDULED - events, trips |
| Pink | `#FECDD3` | CELEBRATION - holidays |
| Green | `#4ADE80` | MONEY - expenses |
| Purple | `#E9D5FF` | PEOPLE - contacts |
| Red | `#E53935` | ALERT - system only |

### Category Colors (Star Page)

| Category | Color |
|----------|-------|
| Holidays | `JohoColors.pink` |
| Observances | `JohoColors.cyan` |
| Memos | `JohoColors.yellow` |

### Border Widths

| Element | Width |
|---------|-------|
| Cells | 1pt |
| Rows | 1.5pt |
| Buttons | 2pt |
| Selected | 2.5pt |
| Containers | 3pt |

---

## Golden Rules

```swift
// ✅ ALWAYS
.foregroundStyle(JohoColors.black)
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(RoundedRectangle(...).stroke(JohoColors.black, lineWidth: 1.5))
.font(.system(size: 16, weight: .medium, design: .rounded))
withAnimation(.easeInOut(duration: 0.2)) { ... }
.johoCalendarPicker(isPresented:selectedDate:accentColor:)

// ❌ NEVER
.background(.ultraThinMaterial)   // NO glass
LinearGradient(...)               // NO gradients
Color.blue                        // NO raw colors
.cornerRadius(12)                 // NO non-continuous
ScrollView { Form... }            // NO scroll in forms
.spring(...)                      // NO bouncy animations
DatePicker(...)                   // NO iOS DatePicker
```

---

## UI Checklist

Before committing:
- [ ] Black borders on all containers
- [ ] Semantic colors only (`JohoColors.*`)
- [ ] Squircle corners (`.continuous`)
- [ ] Rounded typography (`.design(.rounded)`)
- [ ] 44pt touch targets
- [ ] No scroll in forms/editors
- [ ] `JohoCalendarPicker` for dates

---

## File Structure

```
Vecka/
├── Core/                    # Week calculation (4 files)
├── Models/                  # SwiftData models (15 files)
├── Views/                   # SwiftUI views (44 files)
├── Services/                # External APIs (11 files)
├── JohoDesignSystem.swift   # Design components (~4000 LOC)
└── Intents/                 # Siri Shortcuts (4 files)

VeckaWidget/                 # Widget extension (12 files)
```

---

## See Also

For detailed documentation, see the `.claude/` directory:
- **GOLDEN_STANDARD.md** — Authoritative reference for all design decisions
- **FILE_REGISTRY.md** — Find any file quickly
- **NEW_APP_GUIDE.md** — Template for new 情報デザイン apps
