# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

**Onsen Planner** is an iOS 18+ app displaying ISO 8601 week numbers with semantic color coding. Built with SwiftUI, SwiftData, and WidgetKit.

- **Project folder:** `Vecka` (legacy name)
- **App Store name:** Onsen Planner
- **Design System:** 情報デザイン (Jōhō Dezain) - Japanese Information Design

---

## ⚠️ MANDATORY: Read Before Working

**You MUST read the relevant documentation file BEFORE making changes:**

| Task | Action |
|------|--------|
| **Any UI/View changes** | READ `.claude/design-system.md` FIRST |
| **Architecture/Model changes** | READ `.claude/architecture.md` FIRST |
| **Adding new components** | READ `.claude/COMPONENT_GLOSSARY.md` FIRST |
| **Symbol/icon decisions** | READ `.claude/japanese-symbol-language.md` FIRST |

**Do not skip this step.** The design system is strict and violations are bugs.

---

## Build Commands

| Command | Purpose |
|---------|---------|
| `./build.sh build` | Debug build |
| `./build.sh test` | Run tests |
| `./build.sh clean` | Clean artifacts |

---

## Critical Rules (ALWAYS FOLLOW)

### 1. Design System Compliance

You are the **情報デザイン Guardian**. Design violations are bugs.

```swift
// ✅ ALWAYS use JohoColors, never raw Color
.foregroundStyle(JohoColors.black)
.background(JohoColors.white)

// ✅ ALWAYS use squircle corners
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

// ✅ ALWAYS add borders
.overlay(RoundedRectangle(...).stroke(JohoColors.black, lineWidth: 1.5))

// ✅ ALWAYS use .design(.rounded)
.font(.system(size: 16, weight: .medium, design: .rounded))
```

### 2. Forbidden Patterns (Auto-Reject)

```swift
// ❌ NEVER use these
.background(.ultraThinMaterial)  // No glass/blur
LinearGradient(...)              // No gradients
Color.blue                       // No raw colors
.cornerRadius(12)                // No non-continuous
.padding(.top, 40)               // Max 8pt top padding
Text("\(year)")                  // Use String(year)
```

### 3. Color Semantics (6-Color Simplified Palette)

| Color | Japanese | Meaning |
|-------|----------|---------|
| Yellow `#FFE566` | 今 (ima) | NOW - today, notes |
| Cyan `#A5F3FC` | 予定 (yotei) | SCHEDULED - events, trips |
| Pink `#FECDD3` | 祝 (iwai) | CELEBRATION - holidays, birthdays |
| Green `#BBF7D0` | 金 (kane) | MONEY - expenses |
| Purple `#E9D5FF` | 人 (hito) | PEOPLE - contacts |
| Red `#E53935` | 警告 | ALERT - warnings (system only) |

**Deprecated:** Orange (→ use Cyan), Cream (→ use Yellow)

### 4. Border Widths

| Element | Width |
|---------|-------|
| Cells | 1pt |
| Rows | 1.5pt |
| Buttons | 2pt |
| Selected | 2.5pt |
| Containers | 3pt |

### 5. Touch Targets

- Minimum **44×44pt** for all interactive elements
- Minimum **12pt** spacing between buttons

---

## Build Commands

```bash
# Quick commands
./build.sh build         # Debug build
./build.sh build-release # Release build
./build.sh test          # Run tests
./build.sh clean         # Clean artifacts

# Xcode direct
xcodebuild build -project Vecka.xcodeproj -scheme Vecka \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

---

## File Structure

```
Vecka/
├── Core/                    # Week calculation
├── Models/                  # SwiftData models
├── Views/                   # SwiftUI views
├── Services/                # External APIs
├── Intents/                 # Siri Shortcuts
├── JohoDesignSystem.swift   # Design components
└── Localization.swift       # i18n
```

---

## Supported Holiday Regions (16 Countries)

Users can select up to **2 regions** simultaneously.

| Code | Country | Calendar Type |
|------|---------|---------------|
| **Nordic** |||
| SE | Sweden | Gregorian + Easter |
| NO | Norway | Gregorian + Easter |
| DK | Denmark | Gregorian + Easter |
| FI | Finland | Gregorian + Easter |
| IS | Iceland | Gregorian + Easter |
| **Europe** |||
| DE | Germany | Gregorian + Easter |
| GB | United Kingdom | Gregorian + Easter |
| FR | France | Gregorian + Easter |
| IT | Italy | Gregorian + Easter |
| NL | Netherlands | Gregorian + Easter |
| **Asia** |||
| JP | Japan | Gregorian + Astronomical |
| CN | China | Gregorian + Lunar |
| HK | Hong Kong | Gregorian + Lunar + Easter |
| TH | Thailand | Gregorian + Lunar (Buddhist) |
| VN | Vietnam | Gregorian + Lunar |
| **Americas** |||
| US | United States | Gregorian |

Holiday rules are defined in `HolidayManager.seedSwedishRules()`.
Do NOT reference regions not in this list.

---

## Swipe Gestures

| Direction | Action | Color |
|-----------|--------|-------|
| → Right | Edit | Cyan |
| ← Left | Delete | Red |

System holidays (🔒) have no swipe actions.

---

## Design Audit

```bash
# Find violations
grep -rn "ultraThinMaterial" --include="*.swift"
grep -rn "\.cornerRadius(" --include="*.swift"
grep -rn "Color\.blue" --include="*.swift"
```

---

## Compliance Checklist

Before committing UI code:
- [ ] Every container has a black border
- [ ] Colors match semantic meaning
- [ ] No glass/blur effects
- [ ] All corners use `style: .continuous`
- [ ] Typography uses `.design(.rounded)`
- [ ] Max 8pt top padding
- [ ] Icons use correct weight (16pt .medium for lists)

---

## Documentation Files (in `.claude/`)

| File | Contains | Read when |
|------|----------|-----------|
| `design-system.md` | Full 情報デザイン spec, colors, borders, patterns | ANY UI work |
| `architecture.md` | Manager pattern, SwiftData models, data flow | Model/service changes |
| `COMPONENT_GLOSSARY.md` | Existing UI components and their usage | Adding/modifying views |
| `japanese-symbol-language.md` | マルバツ symbols, priority markers, icons | Icon/symbol choices |
| `WORKING_WITH_CLAUDE.md` | Collaboration patterns for this project | Reference |

Also see: `JohoDesignSystem.swift` (code), `TODO_VECKA_FEATURES.md` (roadmap)
