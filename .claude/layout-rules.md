# Layout Rules (情報デザイン)

> **Last Updated:** 2026-01-31

This document defines the layout principles for Onsen Planner.

---

## Core Principle: NO VERTICAL SCROLLING

**情報デザイン rejects vertical scrolling within forms and editors.**

Content must fit the screen through:
1. **Collapsible sections** - Expand/collapse to show/hide content
2. **Progressive disclosure** - Show essential fields first, more on demand
3. **Bento box layout** - Fixed compartments that resize, never scroll

```swift
// ✅ CORRECT: Collapsible section
DisclosureGroup("MONEY", isExpanded: $isExpanded) {
    moneyFields
}

// ❌ WRONG: ScrollView in forms
ScrollView {
    VStack { ... }
}
```

---

## Expansion Pattern (Like Contacts)

When a section expands:
1. **Push content down** - Items below move to accommodate
2. **No truncation** - Full content is visible
3. **No scroll** - Everything fits in viewport
4. **Animate smoothly** - Use `easeInOut(duration: 0.2)`

```swift
// Pattern: Expandable chip row
if isExpanded {
    VStack(spacing: 8) {
        ForEach(items) { item in
            FullItemRow(item: item)
        }
    }
    .transition(.opacity.combined(with: .move(edge: .top)))
}
```

---

## Sheet Presentations

Sheets must:
- Use `.presentationBackground(JohoColors.black)` - solid, no glass
- Use `.presentationDragIndicator(.hidden)` - no iOS chrome
- Contain single white card with all content
- Never scroll internally

---

## Allowed Scroll Contexts

Vertical scroll is ONLY allowed for:
1. **List views** - Contact list, calendar day entries
2. **Long content** - Notes body text (read mode only)
3. **Horizontal chips** - Feature selection row

**Never scroll in:**
- Form editors
- Modal sheets
- Entry creation/editing
- Settings screens

---

## Touch Targets

| Element | Minimum Size |
|---------|--------------|
| Buttons | 44×44pt |
| Chips | 44pt height |
| Row items | 44pt height |
| Icon buttons | 44×44pt |

Spacing between interactive elements: **12pt minimum**

---

## Padding Rules

| Location | Maximum |
|----------|---------|
| Top padding | 8pt |
| Side padding | 8-16pt |
| Bottom padding | 16pt |
| Between sections | 0pt (use dividers) |

---

## Dividers

Use 1.5pt black lines between sections:

```swift
private var dividerLine: some View {
    Rectangle()
        .fill(colors.border)
        .frame(height: 1.5)
}
```

---

## Animation

Only use `easeInOut`:

```swift
// ✅ CORRECT
withAnimation(.easeInOut(duration: 0.2)) { ... }

// ❌ WRONG - no bouncy springs
withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { ... }
```

---

## See Also

- `.claude/GOLDEN_STANDARD.md` — Authoritative design reference
- `.claude/design-system.md` — Visual specification
- `.claude/COMPONENT_GLOSSARY.md` — Component details
