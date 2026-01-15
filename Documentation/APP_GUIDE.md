# Onsen Planner - Complete App Guide

> **Version:** 1.0
> **Platform:** iOS 18+
> **Design System:** 情報デザイン (Jōhō Dezain) - Japanese Information Design

---

## Table of Contents

1. [Overview](#overview)
2. [Design Philosophy](#design-philosophy)
3. [Main Screens](#main-screens)
   - [Landing Page (ONSEN)](#landing-page-onsen)
   - [Calendar](#calendar)
   - [Contacts](#contacts)
   - [Special Days](#special-days)
   - [Settings](#settings)
4. [Features](#features)
5. [Widgets](#widgets)
6. [Dark Mode](#dark-mode)
7. [Strengths](#strengths)
8. [Limitations](#limitations)
9. [Technical Architecture](#technical-architecture)

---

## Overview

**Onsen Planner** (internally codenamed "Vecka", Swedish for "week") is a professional iOS calendar application that emphasizes **ISO 8601 week numbers** with semantic color coding. The app follows a strict Japanese Information Design system (情報デザイン) that prioritizes clarity, consistency, and visual hierarchy.

### Key Value Proposition
- Professional week number display following ISO 8601 standard
- Multi-region holiday support (Sweden, Japan, US, Vietnam)
- Personal expense tracking with currency exchange
- Contact management with birthday/anniversary tracking
- Clean, paper-like visual design without distracting effects

---

## Design Philosophy

### 情報デザイン (Jōhō Dezain)

The app follows a strict Japanese Information Design system with these core principles:

| Principle | Implementation |
|-----------|----------------|
| **Clarity** | White backgrounds, black borders, high contrast |
| **Consistency** | Uniform border widths, squircle corners throughout |
| **Semantic Colors** | Each data type has a dedicated color |
| **No Distractions** | No gradients, no glass/blur effects, no animations |
| **Touch-First** | Minimum 44×44pt touch targets |

### Color Semantics

| Color | Hex Code | Meaning |
|-------|----------|---------|
| Yellow | `#FFE566` | Today/Current |
| Cyan | `#A5F3FC` | Calendar/Events |
| Pink | `#FECDD3` | Holidays |
| Orange | `#FED7AA` | Trips |
| Green | `#BBF7D0` | Expenses |
| Purple | `#E9D5FF` | Contacts |
| Brown | `#D4A574` | Notes |
| Red | `#E53935` | Warnings/Delete |

### Border System

| Element | Width |
|---------|-------|
| Cells | 1pt |
| Rows | 1.5pt |
| Buttons | 2pt |
| Selected items | 2.5pt |
| Containers | 3pt |

---

## Main Screens

### Landing Page (ONSEN)

The home screen of the app, providing a dashboard overview.

```
┌─────────────────────────────────────┐
│ 🏠 ONSEN                      [😊]  │  ← Header with mascot
├─────────────────────────────────────┤
│ 5 MON · Jan                    W2   │  ← Date strip
├─────────────────────────────────────┤
│ ● TODAY                             │
│ Nothing scheduled                   │  ← Today's summary
├─────────────────────────────────────┤
│ ❄ GLANCE                            │
│ ┌─────┐ ┌─────┐ ┌─────┐            │
│ │ 📅  │ │ ❄️  │ │ 💲  │            │
│ │ W2  │ │ JAN │ │  0  │            │  ← Quick access tiles
│ └─────┘ └─────┘ └─────┘            │
│ ┌─────┐ ┌─────┐ ┌─────┐            │
│ │ 👥  │ │ ✈️  │ │ ⚙️  │            │
│ │  6  │ │  0  │ │  O  │            │
│ └─────┘ └─────┘ └─────┘            │
└─────────────────────────────────────┘
```

**GLANCE Tiles:**
1. **W2** (Week) → Opens Calendar at current week
2. **JAN** (Month) → Shows observances count, opens Special Days
3. **$0** (Expenses) → Shows monthly total, opens Expenses sheet
4. **👥 6** (Contacts) → Shows count + upcoming birthdays, opens Contacts
5. **✈️ 0** (Trips) → Shows active trips, opens Trips sheet
6. **⚙️ O** (Settings) → Opens Settings page

**Mascot:** A small robot character (😊) with subtle animations:
- Gentle bobbing motion
- Eye blinking
- Mood changes based on app state

---

### Calendar

The main calendar view with ISO 8601 week numbers.

```
┌─────────────────────────────────────┐
│ 📅 CALENDAR           < January >   │
│                          2026       │
├─────────────────────────────────────┤
│ 5 MON                          W2   │
├─────────────────────────────────────┤
│ W   M   T   W   T   F   S   S      │
│     ░░  ░░  ░░  1   2   3   4      │  ← Previous month grayed
│ 1                                   │
│ 2  [5]  6   7   8   9   10  11     │  ← Today highlighted yellow
│ 3   12  13  14  15  16  17  18     │
│ 4   19 ●20  21  22  23  24  25     │  ← ● = has event
│ 5   26  27  28  29  30  31  ░░     │
├─────────────────────────────────────┤
│ [TODAY]    5 January      [+ ADD]   │
├─────────────────────────────────────┤
│           📋 NO ENTRIES             │
│   Tap + to add holidays, notes...   │
└─────────────────────────────────────┘
```

**Features:**
- ISO 8601 week numbers in left column (W1-W53)
- Yellow highlight for today
- Red dots indicate days with events/holidays
- Saturday/Sunday columns have pink background (holidays)
- Month navigation via arrows or swipe
- Quick jump to today via "TODAY" button
- Add entries via "+ ADD" button

**Entry Types:**
- Notes (brown)
- Holidays (pink)
- Events (cyan)
- Trips (orange)
- Expenses (green)

---

### Contacts

Contact management with quick actions.

```
┌─────────────────────────────────────┐
│ 👥 CONTACTS              [↗️] [📥]  │  ← Export/Import
├─────────────────────────────────────┤
│ ● 6 total  📞 6  🎂 4               │  ← Stats bar
├─────────────────────────────────────┤
│ 🔍 Search contacts                  │
├─────────────────────────────────────┤
│ ≡ INDEX >                           │
├─────────────────────────────────────┤
│ A ─────────────────────────────────│
│ (JA) John Appleseed    [●][✉️][📞] │
│                                     │
│ B ─────────────────────────────────│
│ (KB) Kate Bell         [●][✉️][📞] │
│      Creative Consulting            │
│                                     │
│ H ─────────────────────────────────│
│ (AH) Anna Haro         [●][✉️][📞] │
│ (DH) Daniel Higgins Jr.[●][✉️][📞] │
└─────────────────────────────────────┘
```

**Features:**
- Alphabetical grouping with section headers
- Quick action buttons: Message, Email, Call
- Color-coded dots indicate contact status
- Search functionality
- Birthday countdown (★ 14d = birthday in 14 days)
- Export to vCard
- Import from system contacts

**Contact Details Include:**
- Multiple phone numbers
- Multiple email addresses
- Physical addresses
- Birthdays and anniversaries
- Social profiles
- Custom notes

---

### Special Days

Year overview showing all holidays and observances by month.

```
┌─────────────────────────────────────┐
│ ⭐ SPECIAL DAYS           < 2026 >  │
├─────────────────────────────────────┤
│ ● 29  ○ 11  ○ 4                     │  ← Legend: holidays/observances
├─────────────────────────────────────┤
│ ┌───────┐ ┌───────┐ ┌───────┐      │
│ │  ❄️   │ │  💕   │ │  🌱   │      │
│ │JANUARY│ │FEBRUARY│ │ MARCH │      │
│ │ ●4 ○1 │ │ ●2 ○1 │ │ ●1 ○2 │      │
│ └───────┘ └───────┘ └───────┘      │
│ ┌───────┐ ┌───────┐ ┌───────┐      │
│ │  🌧️   │ │  🌷   │ │  ☀️   │      │
│ │ APRIL │ │  MAY  │ │ JUNE  │      │
│ │  ●4   │ │ ●6 ○1 │ │●2 ○2 ○2│      │
│ └───────┘ └───────┘ └───────┘      │
│           ...continues...           │
├─────────────────────────────────────┤
│ ≡ LEGEND >                     3    │
└─────────────────────────────────────┘
```

**Features:**
- Visual year overview with seasonal icons
- Count of holidays (●) and observances (○) per month
- Tap month to see detailed list
- Support for multiple holiday regions
- Custom holidays can be added
- System holidays marked with 🔒 (not editable)

**Holiday Types:**
- **Public Holidays** (red dot) - Official non-working days
- **Observances** (pink dot) - Notable days without time off
- **Birthdays** (purple dot) - From contacts
- **Custom** (blue dot) - User-defined special days

---

### Settings

App configuration and preferences.

```
┌─────────────────────────────────────┐
│ ⚙️ SETTINGS                   v1.0  │
│                               Onsen │
├─────────────────────────────────────┤
│ ○ 6 / 5 000                         │  ← Database entries
├─────────────────────────────────────┤
│ CALENDAR                            │
│ ┌─────────────────────────────────┐ │
│ │ ⭐ Show Holidays         [ON]  │ │
│ │ 🌍 Holiday Regions          > │ │
│ │    Sweden, Japan              │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ PREFERENCES                         │
│ ┌─────────────────────────────────┐ │
│ │ 💲 Base Currency            > │ │
│ │    SEK - Swedish Krona        │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ DISPLAY                             │
│ ┌─────────────────────────────────┐ │
│ │ Background Color               │ │
│ │ [BLACK ✓] [NAVY] [SOFT]       │ │
│ │                                │ │
│ │ Appearance                     │ │
│ │ [☀️ LIGHT] [🌙 DARK]          │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ PERSONALIZATION                     │
│ ┌─────────────────────────────────┐ │
│ │ Landing Page Title       [Edit]│ │
│ │ ONSEN (default)               │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ WORLD CLOCKS                        │
│ ┌─────────────────────────────────┐ │
│ │ + Add World Clock              │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Settings Sections:**

1. **Calendar**
   - Toggle holiday visibility
   - Select up to 2 holiday regions

2. **Preferences**
   - Base currency for expense calculations
   - Supports 150+ currencies

3. **Display**
   - Background color: Black (AMOLED), Navy, Soft gray
   - Appearance: Light/Dark mode

4. **Personalization**
   - Custom landing page title
   - Examples: "Nils Calendar", "My Planner", "Family Hub"

5. **World Clocks**
   - Add up to 3 world clocks
   - Displayed on landing page

---

## Features

### Expense Tracking

- **Add expenses** with categories (Food, Transport, Shopping, etc.)
- **Multi-currency support** with automatic exchange rates
- **Monthly summaries** with category breakdown
- **Trip-based expenses** for travel tracking
- **PDF export** for expense reports

### Trip Management

- Create trips with start/end dates
- Track trip-specific expenses
- Automatic currency detection based on destination
- Trip summary with total spending

### Notes

- Daily notes attached to calendar dates
- Rich text support
- Color coding options
- Quick access from calendar

### Holidays

- **Pre-loaded holidays** for Sweden, Japan, US, Vietnam
- **Custom holidays** with recurrence rules
- **Observances** (non-holiday notable days)
- **Birthday integration** from contacts

---

## Widgets

iOS Home Screen widgets in multiple sizes:

### Small Widget
```
┌─────────────┐
│ W2          │
│ 5 January   │
│ MON         │
└─────────────┘
```
Shows current week number and date.

### Medium Widget
```
┌─────────────────────────┐
│ W2  │ M  T  W  T  F  S S│
│     │ 5  6  7  8  9 1011│
│ JAN │       ↑           │
│     │    today          │
└─────────────────────────┘
```
Shows current week with day highlights.

### Large Widget
```
┌─────────────────────────┐
│    January 2026         │
│ W   M  T  W  T  F  S  S │
│ 1      1  2  3  4       │
│ 2  [5] 6  7  8  9 10 11 │
│ 3  12 13 14 15 16 17 18 │
│ 4  19 20 21 22 23 24 25 │
│ 5  26 27 28 29 30 31    │
└─────────────────────────┘
```
Full month calendar with week numbers.

**Widget Actions:**
- Tap widget → Opens app to Landing page (ONSEN)
- Deep linking to specific dates

---

## Dark Mode

The app supports a full dark mode following 情報デザイン principles:

### Light Mode
- White backgrounds (`#FFFFFF`)
- Black text and borders
- Semantic colors at full saturation

### Dark Mode
- True black background (`#000000`) - AMOLED friendly
- White text and borders
- Semantic colors muted for readability

**Dark Mode Color Mapping:**

| Zone | Light | Dark |
|------|-------|------|
| Calendar | `#A5F3FC` (Cyan) | `#164E63` (Dark Cyan) |
| Notes | `#FEF3C7` (Amber) | `#78350F` (Dark Amber) |
| Expenses | `#BBF7D0` (Green) | `#14532D` (Dark Green) |
| Trips | `#FED7AA` (Orange) | `#7C2D12` (Dark Orange) |
| Holidays | `#FECDD3` (Pink) | `#831843` (Dark Pink) |
| Contacts | `#E9D5FF` (Purple) | `#581C87` (Dark Purple) |

---

## Strengths

### 1. Clean, Professional Design
- Follows strict design system
- No visual clutter or distracting animations
- Paper-like aesthetic that's easy on the eyes

### 2. ISO 8601 Week Numbers
- Essential for European/business users
- Week numbers prominently displayed
- Consistent with international standards

### 3. Multi-Region Holiday Support
- Pre-configured for Sweden, Japan, US, Vietnam
- Support for multiple regions simultaneously
- Custom holiday creation

### 4. Integrated Expense Tracking
- Built into calendar for contextual tracking
- Multi-currency with exchange rates
- Trip-based expense grouping

### 5. Privacy-First
- All data stored locally via SwiftData
- Optional iCloud sync
- No third-party analytics

### 6. Battery Efficient
- True black AMOLED mode
- No background processes
- Minimal animations

### 7. Accessibility
- Minimum 44pt touch targets
- High contrast design
- VoiceOver compatible

---

## Limitations

### 1. Region Support
- Holiday data limited to 4 regions (SE, JP, US, VN)
- Cannot add additional country holiday packs
- Custom holidays required for other regions

### 2. Calendar Integration
- Does not sync with system Calendar app
- Events must be entered manually
- No CalDAV/Exchange support

### 3. Expense Features
- Exchange rates may not be real-time
- No receipt scanning/OCR
- Limited reporting options

### 4. Contacts
- Separate from system Contacts
- Requires manual import
- No two-way sync

### 5. Widgets
- No interactive widgets (iOS limitation)
- Widget refresh depends on system
- Limited customization options

### 6. Platform
- iOS only (no macOS, watchOS, iPad optimization)
- Requires iOS 18+
- iPhone portrait mode only

### 7. Localization
- UI in English and Swedish only
- Holiday names may not be localized

---

## Technical Architecture

### Frameworks Used
- **SwiftUI** - User interface
- **SwiftData** - Local persistence
- **WidgetKit** - Home screen widgets
- **CloudKit** - iCloud sync (optional)

### Data Models
```
├── DailyNote
├── HolidayRule
├── CalendarRule
├── CountdownEvent
├── ExpenseCategory
├── ExpenseItem
├── TravelTrip
├── Contact (+ related)
├── SavedLocation
└── WorldClock
```

### Design System
- `JohoDesignSystem.swift` - Core components
- `JohoColors` - Color palette
- `JohoScheme` - Dynamic light/dark colors
- `SectionZone` - Semantic section styling

### File Structure
```
Vecka/
├── Core/           # Week calculations
├── Models/         # SwiftData models
├── Views/          # SwiftUI views
├── Services/       # External APIs
├── Intents/        # Siri Shortcuts
└── Localization/   # i18n strings
```

---

## Summary

Onsen Planner is a focused, well-designed calendar application that excels at:
- **Week number visibility** - Core feature done right
- **Visual clarity** - 情報デザイン design system
- **Personal organization** - Calendar, expenses, contacts in one app

It's best suited for users who:
- Need ISO 8601 week numbers
- Prefer clean, professional interfaces
- Want an all-in-one personal organizer
- Value privacy and local data storage

The app intentionally avoids:
- Complex integrations
- Flashy animations
- Cloud dependencies
- Feature bloat

This makes it a reliable, focused tool for personal planning rather than a full-featured productivity suite.

---

*Documentation generated: January 2026*
*© 2025 The Office of Nils Johansson*
