# JDS-MAN-SFW-001 — Joho Design System Manual

**Doc No:** JDS-MAN-SFW-001
**Rev:** C
**Status:** CURRENT
**Date:** 2026-05-29
**Author:** Nils Johansson

---

## 1. Overview

The **Joho Design System** (情報デザイン / *Jōhō Dezain*) is the visual language of Onsen Planner. It draws from classic Japanese OTC medicine packaging — Muhi, Rohto, Sato — and codifies that look into SwiftUI tokens, components, and modifiers.

Three rules guide every decision:

1. **One color, one meaning.** Six semantic colors. Each represents exactly one concept.
2. **Bold, thick, rounded.** Heavy borders, continuous (squircle) corners, rounded font design.
3. **No glass, no gradients.** Opaque surfaces only. Color does the work, not blur.

Implementation lives across these files:

| File | Role |
|---|---|
| `Vecka/JohoFoundations.swift` | `JohoColors`, `JohoScheme`, `SystemUIAccent`, `JohoColorMode`, hex helpers |
| `Vecka/JohoTokens.swift` | `JohoFont`, `JohoDimensions`, `SectionZone`, `JohoCardSize`, `Squircle`, `HalfCircle` |
| `Vecka/JohoSymbols.swift` | `IconCatalog`, `JohoSymbols` (Japanese symbol vocabulary), photo/icon picker components |
| `Vecka/JohoComponents.swift` | Reusable UI components (containers, pills, cards, day cells, etc.) |
| `Vecka/JohoViewModifiers.swift` | `.johoBackground()`, `.johoBordered()`, `.johoBento()`, `.johoNavigation()`, etc. |
| `Vecka/Models/JohoTheme.swift` | `JohoThemePreset` — JSON-driven theme overrides |
| `Vecka/JohoSettings.swift` | `JohoThemeCache`, category color/icon overrides |

---

## 2. Color tokens

### 2.1 The six-color semantic palette

Source: `Vecka/JohoFoundations.swift:112` (`enum JohoColors`).

| Token | Hex | Japanese | Meaning |
|---|---|---|---|
| `JohoColors.yellow` | `#FFE566` | 今 (*ima*) | **NOW** — today, current moment, personal notes |
| `JohoColors.cyan` | `#A5F3FC` | 予定 (*yotei*) | **SCHEDULED** — events, trips, appointments, countdowns |
| `JohoColors.pink` | `#FECDD3` | 祝 (*iwai*) | **CELEBRATION** — holidays, birthdays, special days |
| `JohoColors.green` | `#4ADE80` | 金 (*kane*) | **MONEY** — expenses, financial items |
| `JohoColors.purple` | `#E9D5FF` | 人 (*hito*) | **PEOPLE** — contacts, relationships |
| `JohoColors.red` | `#E53935` | 警告 | **ALERT** — warnings, errors (system only) |

### 2.2 Foreground (dark) variants

For dark text/icons on white surfaces, paired with the base color used as a background tint.

| Token | Hex |
|---|---|
| `yellowDark` | `#B8860B` |
| `cyanDark` | `#0891B2` |
| `pinkDark` | `#BE123C` |
| `greenDark` | `#15803D` |
| `purpleDark` | `#7C3AED` |

### 2.3 Background (light) tints

For bento-box backgrounds and section tints.

| Token | Hex |
|---|---|
| `yellowLight` | `#FEF3C7` |
| `cyanLight` | `#CFFAFE` |
| `pinkLight` | `#FED7E2` |
| `greenLight` | `#D1FAE5` |
| `purpleLight` | `#F3E8FF` |
| `redLight` | `#FECACA` |

### 2.4 Utility tokens

| Token | Hex | Use |
|---|---|---|
| `black` | `#000000` | Text, borders |
| `white` | `#FFFFFF` | Surfaces |
| `todayOrange` | `#FF9500` | Today highlight on calendar — distinct from yellow memos |
| `tripBlue` | `#3182CE` | TRP indicator on calendar |

### 2.5 Adaptive scheme (`JohoScheme`)

`JohoScheme.colors(for: colorMode)` (defined at `Vecka/JohoFoundations.swift:320`) returns the canvas/surface/text colors for the active `JohoColorMode` (`.light` or `.dark`).

| Slot | Light mode | Dark mode |
|---|---|---|
| `primary` | `#000000` | `#F0F0F0` |
| `secondary` | `primary × opacityStrong` | `primary × opacityHeavy` |
| `surface` | `#FFFFFF` | `#1C1C1E` |
| `border` | `#000000` | `#48484A` |
| `canvas` | `#FFFFFF` | `#000000` (true black, AMOLED) |
| `surfaceInverted` | `#000000` | `#F0F0F0` |
| `primaryInverted` | `#FFFFFF` | `#1C1C1E` |
| `inputBackground` | `#F5F5F5` | `#2C2C2E` |

If a `JohoThemePreset` is active and declares structural overrides, those are applied on top of the base scheme.

### 2.6 Page header accents (`PageHeaderColor`)

These are **identity** colors for top-level pages — not semantic content colors. Source: `Vecka/JohoFoundations.swift:173`.

| Case | Accent | Page |
|---|---|---|
| `landing` | `#F59E0B` (warm amber) | Onsen landing / home |
| `calendar` | `#4338CA` (deep indigo) | Calendar |
| `specialDays` | `#D97706` (rich amber) | Special days / holidays |
| `tools` | `#0D9488` (teal) | Tools |
| `contacts` | `#7C3AED` (vivid purple) | Contacts |
| `settings` | `#475569` (slate blue) | Settings |

### 2.7 System UI accent (`SystemUIAccent`)

User-selectable global accent. Source: `Vecka/JohoFoundations.swift:220`.

| Case | Hex | Japanese | Theme |
|---|---|---|---|
| `black` | `#000000` | 権威 | Pure authority |
| `slate` | `#475569` | 穏やか | Soft professional |
| `indigo` | `#4338CA` | 時 | Deep calm (time/structure) |
| `navy` | `#1E3A5F` | 深み | Warm neutral, depth |
| `blue` | `#3B82F6` | 案内 | Wayfinding |

---

## 3. Typography (`JohoFont`)

Source: `Vecka/JohoTokens.swift:103`. All fonts use `design: .rounded` unless noted.

| Token | Size | Weight | Use |
|---|---|---|---|
| `displayLarge` | 48 | heavy | Big numbers, hero titles |
| `displayMedium` | 32 | bold | Section displays |
| `displaySmall` | 24 | bold | Day numbers |
| `title` | 20 | bold | Page titles |
| `headline` | 18 | bold | Section headers |
| `headlineSmall` | 16 | bold | Card headers |
| `subheadline` | 15 | semibold | Sub-section headers |
| `body` | 16 | medium | Body copy |
| `bodySmall` | 14 | medium | Body copy (small) |
| `bodySmallBold` | 14 | bold | Emphasized small text |
| `tag` | 11 | bold | Tags |
| `headerTag` | 11 | black | Strong header tags |
| `pillLabel` | 10 | black | Pill / badge labels |
| `label` | 12 | bold | Labels (pills) |
| `labelSmall` | 10 | heavy | Small labels |
| `labelBold` | 10 | bold | Bold small labels |
| `button` | 15 | semibold | Buttons |
| `caption` | 12 | medium | Captions (never below `.medium` weight) |
| `monoLarge` | 24 | bold | Monospaced numbers (large) |
| `monoMedium` | 16 | semibold | Monospaced numbers (medium) |
| `monoSmall` | 14 | medium | Monospaced numbers (small) |

**Rule:** never use weights below `.medium`. Thin and light weights are forbidden.

---

## 4. Dimensions (`JohoDimensions`)

Source: `Vecka/JohoTokens.swift:146`.

### 4.1 Corner radii (squircle)

| Token | pt | Use |
|---|---|---|
| `radiusXS` | 4 | Tiny chips |
| `radiusChip` | 6 | Chips |
| `radiusSmall` | 8 | Small cards |
| `radiusCard` | 10 | Standard cards |
| `radiusMedium` | 12 | Medium containers |
| `radiusLarge` | 16 | Large containers |
| `radiusXL` | 20 | Sheets |
| `radiusXXL` | 24 | App-icon style |

All corners use `.continuous` (squircle), never `.circular`. The `Squircle` shape in `Vecka/JohoTokens.swift:215` is the canonical implementation.

### 4.2 Border widths

| Token | pt | Use |
|---|---|---|
| `borderThin` | 1.0 | Day cells |
| `borderMedium` | 2.0 | Buttons |
| `borderThick` | 3.0 | Containers |

### 4.3 Spacing

| Token | pt |
|---|---|
| `spacingXS` | 4 |
| `spacingSM` | 8 |
| `spacingMD` | 12 |
| `spacingLG` | 16 |
| `spacingXL` | 20 |

### 4.4 Opacity

| Token | Value |
|---|---|
| `opacityFaint` | 0.05 |
| `opacitySubtle` | 0.10 |
| `opacityLight` | 0.15 |
| `opacityMild` | 0.20 |
| `opacityMedium` | 0.30 |
| `opacityModerate` | 0.40 |
| `opacityHeavy` | 0.50 |
| `opacityStrong` | 0.60 |
| `opacityBold` | 0.70 |
| `opacityDense` | 0.80 |

---

## 5. Section zones (`SectionZone`)

Source: `Vecka/JohoTokens.swift:15`. Maps content categories to the six-color palette. Each zone exposes a `background(for: mode)` and `textColor(for: mode)` to drive section coloring.

| Zone | Color | Concept |
|---|---|---|
| `.notes` | yellow | NOW |
| `.memos`, `.expenses` | green | MONEY / user memos |
| `.calendar`, `.trips`, `.events`, `.countdowns`, `.observances` | cyan | SCHEDULED |
| `.holidays`, `.birthdays` | pink | CELEBRATION |
| `.contacts` | purple | PEOPLE |
| `.warning` | redLight | ALERT (system only) |

---

## 6. Icon Catalog (`IconCatalog`)

Source: `Vecka/JohoSymbols.swift:9`. **All SF Symbol references in views must go through `IconCatalog.*`** — no hardcoded `Image(systemName: "…")` strings.

### 6.1 Three-tier resolution

When a view needs an icon, it resolves in order:

1. **User override** — a `symbolName` field on the model (selected by the user via `JohoIconPicker` / `JohoSymbolPickerSheet`).
2. **Category setting** — `CategoryIconSettings.icon(for:)` (theme-defined per category).
3. **Catalog default** — `IconCatalog.*` constant.

### 6.2 Key constants

| Constant | SF Symbol | Use |
|---|---|---|
| `.memo` | `note.text` | Notes, memos |
| `.person` | `person.fill` | Single person |
| `.people` | `person.2.fill` | Groups |
| `.contacts` | `person.2` | Contacts page nav |
| `.calendar` | `calendar` | Calendar nav |
| `.calendarBadgePlus` | `calendar.badge.plus` | Add event |
| `.event` | `calendar.badge.clock` | Events, countdowns |
| `.clock` / `.clockOutline` | `clock.fill` / `clock` | Time |
| `.home` | `house.fill` | Landing |
| `.star` | `star.fill` | Special days / holidays default |
| `.holiday` | `star.fill` | Bank holidays |
| `.observance` | `sparkles` | Observances |
| `.birthday` | `birthday.cake.fill` | Birthdays |
| `.trip` | `airplane` | Trips |
| `.settings` | `gearshape` | Settings (outline style) |
| `.search` | `magnifyingglass` | Search |
| `.share` | `square.and.arrow.up` | Share |
| `.warning` | `exclamationmark.triangle.fill` | Warnings |
| `.expense` | locale-aware | Money (computed) |

Full set: ~134 constants covering navigation, actions, communication, location, media, documents, alerts, decorative, settings, and type defaults. See `Vecka/JohoSymbols.swift:9-189` for the complete list.

### 6.3 Currency icons

Locale-aware. Two overloads in `Vecka/JohoSymbols.swift:150` and `:170`.

```swift
IconCatalog.currencyIcon(for: Locale.current)   // resolves via Locale.currency.identifier
IconCatalog.currencyIcon(for: "SEK")            // resolves by ISO code
```

Supported codes: USD, EUR, GBP, JPY, CNY/RMB, KRW, INR, RUB, BRL, THB, TRY, SEK/NOK/DKK/ISK (all share the Swedish krona glyph), CHF, PLN. Anything else falls back to `dollarsign.circle.fill`.

`IconCatalog.expense` is a computed shortcut to the current locale's currency icon.

---

## 7. Components (`JohoComponents.swift` + others)

All components live in `Vecka/JohoComponents.swift` unless noted.

### 7.1 Containers & layout

| Component | Purpose |
|---|---|
| `JohoContainer` | Bordered squircle wrapper; optional zone coloring |
| `JohoCard` | Content container with configurable size (`JohoCardSize`) |
| `JohoSectionBox` | Section wrapper with header + body |
| `JohoFormSection` | Form section wrapper with title |
| `JohoFormField` | Single labeled form input row |
| `JohoDivider` | Themed divider line |
| `FlowLayout` | Wrapping flow layout for chips/tags |

### 7.2 Badges, pills, indicators

| Component | Purpose |
|---|---|
| `JohoPill` | Capsule badge (black-on-white, white-on-black, colored, muted variants) |
| `JohoIconBadge` | Colored icon container with border |
| `JohoIndicatorCircle` | Small circular indicator dot |
| `JohoWeekBadge` | Week-number indicator |

### 7.3 Calendar primitives

| Component | Purpose |
|---|---|
| `JohoDayCell` | Calendar day cell with semantic coloring and indicators |

### 7.4 List & data presentation

| Component | Purpose |
|---|---|
| `JohoListRow` | Table row: icon + label + value |
| `JohoMetricRow` | Metric row variant |
| `JohoStatBox` | Single metric display (number + label) |

### 7.5 Headers

| Component | Purpose |
|---|---|
| `JohoPageHeader` | Top-of-page header (icon + title + secondary content) |
| `JohoEditorHeader` | Editor sheet header |
| `JohoSheetHeader` | Generic sheet header with optional share button |

### 7.6 Inputs

| Component | Purpose |
|---|---|
| `JohoSearchField` | Themed search input |
| `JohoToggle`, `JohoToggleRow` | Themed toggle and toggle-with-label row |

### 7.7 Buttons

| Component | Purpose |
|---|---|
| `JohoIconButton` | Icon button (icon + optional label) |
| `JohoContactActionButton` | Quick-action button for contacts (call / message / map) |

### 7.8 Avatars & media

| Component | Purpose |
|---|---|
| `JohoSticker` | Universal avatar/badge (circle or squircle; photo / initials / icon; optional badge overlay) |
| `JohoPhotoPicker`, `JohoPhotoContainer` | Photo picker and display (in `Vecka/JohoSymbols.swift`) |
| `JohoContactAvatarRow` | Row variant for contact lists (in `Vecka/JohoSymbols.swift`) |

### 7.9 State & empty views

| Component | Purpose |
|---|---|
| `JohoEmptyState` | Empty-state placeholder with icon + message |

### 7.10 Pickers

| Component | Purpose |
|---|---|
| `JohoSymbolPickerSheet` | Full SF Symbol picker with search and categories (in `Vecka/JohoSymbols.swift`) |
| `JohoIconPicker` view modifier | Triggered via `.johoIconPicker(isPresented:selection:accentColor:)` |

### 7.11 Country / locale

| Component | Purpose |
|---|---|
| `CountryColorScheme` | Color scheme keyed to country code |
| `CountryPill` | Country-coded pill |

### 7.12 Shapes

| Shape | File | Purpose |
|---|---|---|
| `Squircle` | `Vecka/JohoTokens.swift:215` | Continuous-corner rounded rect (the canonical Joho corner) |
| `HalfCircle` | `Vecka/JohoTokens.swift:240` | Half-circle for split-color buttons |
| `AnyInsettableShape` | `Vecka/JohoComponents.swift:898` | Type-erased insettable shape |

---

## 8. View modifiers (`JohoViewModifiers.swift`)

All accessed via `View` extension methods. Source: `Vecka/JohoViewModifiers.swift:211` for the main set; `.johoIconPicker(…)` lives in `Vecka/JohoSettings.swift:316` (defined there because it depends on settings-layer types).

| Modifier | Purpose |
|---|---|
| `.johoBackground()` | App-level canvas background; adapts to `JohoColorMode` so the status bar stays legible |
| `.johoNavigation(title:)` | Opaque navigation bar with title (no glass) |
| `.johoListStyle()` | List styling: plain, hidden content background, themed canvas |
| `.johoBordered(cornerRadius:borderWidth:borderColor:)` | Squircle clip + stroke |
| `.johoBento(...)` | White surface card with black border (the "bento box" look) |
| `.johoAccentedBento(color:...)` | Colored-tint bento card with black border |
| `.johoSectionHeader(...)` | Section header styling |
| `.johoInteractiveCell(isSelected:isHighlighted:cornerRadius:)` | Cell with pressed/selected states |
| `.johoIconBadge(color:size:)` | Icon badge styling |
| `.johoPillStyle(backgroundColor:foregroundColor:borderColor:)` | Pill/tag styling |
| `.johoTouchTarget(_:)` | Minimum 44×44 pt touch target (Apple HIG) |
| `.johoIconPicker(isPresented:selection:accentColor:)` | Presents the SF Symbol picker sheet (`JohoSettings.swift`) |

---

## 9. Theme system

### 9.1 Color mode

`JohoColorMode` is a two-case enum (`Vecka/JohoFoundations.swift:278`):

- `.light` — classic 情報デザイン, black on white.
- `.dark` — 夜間モード (night mode), white on true black (AMOLED).

The active mode is stored in `@AppStorage("johoColorMode")` and propagated via `.johoColorMode(_:)` (an environment-key modifier). `JohoScheme.colors(for:)` reads it to return the right canvas/surface/text triad.

The app also forces `.preferredColorScheme` to match, so iOS chrome (status bar tint, system sheets) follows the user's choice rather than the system setting.

### 9.2 Theme presets (`JohoThemePreset`)

Source: `Vecka/Models/JohoTheme.swift`. A `JohoThemePreset` is a `Codable` struct describing:

- Per-category background and foreground colors (holiday, observance, memo, …) for both light and dark modes.
- Per-category icon name overrides.
- Optional **structural overrides** — border hex and surface hex — applied on top of `JohoScheme` when `hasStructuralOverrides` is true.
- A `systemAccent` field (`SystemUIAccent`).

Presets are loaded from JSON. The currently active preset is cached in `JohoThemeCache` (`Vecka/JohoSettings.swift`); switching themes is a single setter call that triggers re-render across the app.

### 9.3 Category overrides

`CategoryColorSettings` and `CategoryIconSettings` (in `Vecka/JohoSettings.swift`) hold per-category overrides outside any active preset — the user's own picks via the in-app settings UI. They sit between the catalog default and the user-level model override in the three-tier resolution.

---

## 10. House rules

These are non-negotiable. Code review and the design system itself reject deviations.

- **Always** use `IconCatalog.*` for SF Symbols. No `Image(systemName: "literal-string")` in views.
- **Always** use `JohoColors.*` (or `JohoScheme` slots) for colors. No raw `Color(red:green:blue:)` or asset-catalog colors.
- **Always** use `.continuous` corners. No `.circular`.
- **Always** use `design: .rounded` for fonts (mono variants excepted).
- **Always** use black borders on containers (or the theme's border override).
- **Never** use gradients or glass/blur materials. Color does the work.
- **Never** drop typography weight below `.medium`.
- **Never** hide the status bar or render opaque content behind it without using `JohoScheme.canvas` (so the system icons stay legible — see Rev A entry in the changelog).

### 10.1 Automated enforcement

`scripts/lint-design-system.sh` (run via `./build.sh lint`, and as part of `./build.sh test`) enforces the mechanizable rules against `Vecka/` and `VeckaWidget/`:

| Rule | Linter id | Mode |
|---|---|---|
| SF Symbols via IconCatalog | `symbols` | strict |
| No `Color(hex:)` outside `JohoFoundations` | `colorhex` | ratchet |
| No raw SwiftUI colors | `colorraw` | ratchet |
| `.continuous` corners only | `corners` | strict |
| `.rounded`/`.monospaced` fonts only | `fonts` | ratchet |
| No gradients | `gradient` | strict |
| No glass/blur materials | `glass` | strict |
| Weight ≥ `.medium` | `weights` | strict |

**Strict** rules fail on any violation. **Ratchet** rules track existing debt per file in `scripts/lint-allowlist.txt`; counts may only decrease, so no new violation can be introduced in a tracked file. `#Preview` blocks and comments are stripped before scanning.

The two remaining house rules are not statically checkable and rely on review: **black borders on containers** (border presence/color is context-dependent) and **status-bar legibility** (a runtime/layout property).

---

## 11. Extension points

| Need | Where |
|---|---|
| Add a semantic color | Extend `JohoColors` in `JohoFoundations.swift`. Update §2 of this manual. |
| Add a typography size | Extend `JohoFont` in `JohoTokens.swift`. Update §3 of this manual. |
| Add an icon constant | Extend `IconCatalog` in `JohoSymbols.swift`. Update §6.2 of this manual. |
| Add a reusable component | Add to `JohoComponents.swift`. Update §7. |
| Add a view modifier | Add to `JohoViewModifiers.swift`. Update §8. |
| Add a theme preset | Add JSON loaded by `JohoThemeCache`. No code change required if the schema fits. |

Any addition without a corresponding update to this manual is a documentation defect.

---

## 12. References

- Internal: `Vecka/JohoFoundations.swift`, `Vecka/JohoTokens.swift`, `Vecka/JohoSymbols.swift`, `Vecka/JohoComponents.swift`, `Vecka/JohoViewModifiers.swift`, `Vecka/JohoSettings.swift`, `Vecka/Models/JohoTheme.swift`
- Project card: [`JDS-PRJ-SFW-002_onsen-planner.md`](JDS-PRJ-SFW-002_onsen-planner.md)
- Parent register: [`nj22az/JDS_Documentation`](https://github.com/nj22az/JDS_Documentation)
- Japanese symbol vocabulary reference: `Vecka/JohoSymbols.swift:196` (`enum JohoSymbols`)
