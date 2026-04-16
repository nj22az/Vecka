# Design Systems: Joho vs JDS

Quick-reference disambiguation for contributors. Two similarly-named systems
touch this project. They solve **different problems** and must not be
confused or merged.

## Joho Design System

**Scope**: SwiftUI UI for the Onsen Planner iOS app (and its widgets).
**Lives in**: `Vecka/JohoFoundations.swift`, `Vecka/JohoTokens.swift`,
`Vecka/JohoComponents.swift`, `Vecka/JohoSymbols.swift`,
`Vecka/JohoViewModifiers.swift`, `Vecka/JohoCalendarWidgets.swift`,
`Vecka/JohoSettings.swift`, `Vecka/Models/JohoTheme.swift`.
**Prefix**: `Joho*` (types), `.joho*` (view modifiers).
**Philosophy**: 情報デザイン (jōhō dezain) — Japanese information-design
aesthetic with 6 semantic colors (yellow/cyan/pink/green/purple/red),
thick black borders, `.continuous` squircles, and `.rounded` SF fonts.

**Authoritative reference**: `CLAUDE.md` at the repo root.

## JDS (Johansson Documentation System)

**Scope**: An **external** engineering documentation governance system
owned by Nils Johansson. Lives at
[github.com/nj22az/JDS_Documentation](https://github.com/nj22az/JDS_Documentation).
**Target medium**: Markdown → PDF, for reports/procedures/manuals.
**NOT** a UI design system. Has no SwiftUI, no iOS, no on-screen components.
**Relevance here**: Purely philosophical. A few of its print-design
principles (three-level reading, 6pt vertical rhythm, five-zone page
architecture, redundant encoding, max 3 colors per page) are a good fit
for the app's **PDF export pipeline** — and only that.

## How they relate in this repo

| Context | Governed by |
|---|---|
| Anything the user sees on screen in the iOS app | Joho Design System |
| Anything the user sees on screen in the widget | Joho Design System |
| Anything inside a generated PDF export | `JohoPDFStyle` (print-scoped, inspired by JDS) |
| Document numbering, revision control, audit workflows | Not applicable — out of scope for this app |

`JohoPDFStyle` (`Vecka/Services/JohoPDFStyle.swift`) is the bridge.
It reuses `JohoColors` semantically so that "yellow means today" is
consistent between the UI and its exported PDFs, but enforces print-only
typography, spacing, and page architecture that would be inappropriate
on screen.

## Rules for contributors

1. **Never** import print tokens (`JohoPDFStyle.*`) into on-screen views.
2. **Never** import UI tokens (`JohoFont`, `JohoCornerRadius`,
   `JohoSpacing`, etc.) into PDF page views if a `JohoPDFStyle` equivalent
   exists — prefer the print-scoped value.
3. **Never** rename anything in the app to `JDS*`. That namespace belongs
   to the external documentation system and collisions would be confusing.
4. **Never** copy JDS colors (Navy `#1B3A5C`, Steel Blue, Forest Green
   `#3D8B6E`, etc.) into `JohoColors`. The app's 6-color semantic palette
   is fixed.
5. **Do** feel free to borrow JDS's *mental models* when reviewing PDF
   output: Does this page pass the Glance test (0.5s)? The Scan test (5s)?
   Is every color carrying meaning, with text/icon backup?

## Quick naming cheat sheet

```
JohoColors.yellow                → app UI only
JohoFont.displayLarge            → app UI only
JohoPDFStyle.Color.now           → PDF exports only (yellow in PDF context)
JohoPDFStyle.Font.h1             → PDF exports only
JohoPDFStyle.Page.marginRecommended → PDF exports only
JohoPDFReadingLevel              → documentation hint, no runtime effect
```

If in doubt: is the code rendering pixels to a screen, or ink to a page?
Screen → `Joho*`. Page → `JohoPDF*`.
