# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

**WeekGrid** is an iOS 18+ app displaying ISO 8601 week numbers with semantic color coding. Built with SwiftUI, SwiftData, and WidgetKit.

- **Project folder:** `Vecka` (legacy name)
- **App Store name:** WeekGrid
- **Design System:** 情報デザイン (Jōhō Dezain) - Japanese Information Design

---

## Quick Reference

| Task | Reference |
|------|-----------|
| **UI work** | See `.claude/design-system.md` |
| **Architecture** | See `.claude/architecture.md` |
| **Build** | `./build.sh build` |
| **Test** | `./build.sh test` |
| **Clean** | `./build.sh clean` |

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

### 3. Color Semantics

| Color | Meaning |
|-------|---------|
| Yellow `#FFE566` | Today/Now |
| Cyan `#A5F3FC` | Events |
| Pink `#FECDD3` | Holidays |
| Orange `#FED7AA` | Trips |
| Green `#BBF7D0` | Expenses |
| Purple `#E9D5FF` | Contacts |
| Red `#E53935` | Warnings |

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

## Supported Holiday Regions

| Code | Country | Max 2 selectable |
|------|---------|------------------|
| SE | Sweden | ✓ |
| US | United States | ✓ |
| VN | Vietnam | ✓ |

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

## Additional Documentation

- `.claude/design-system.md` - Complete 情報デザイン specification
- `.claude/architecture.md` - Code patterns and technical details
- `JohoDesignSystem.swift` - Design system components
- `TODO_VECKA_FEATURES.md` - Feature roadmap
