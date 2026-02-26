# Fact Card Streamlining Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix truncated country names, add category to RandomFact model, show country + category in detail sheet and share card.

**Architecture:** Add `category` field to the `RandomFact` display model. Fix two long display names. Update detail sheet header and add category pill. Update share card footer labels.

**Tech Stack:** SwiftUI, SwiftData, JohoComponents (JohoPill, JohoSheetHeader)

---

### Task 1: Add category to RandomFact model + fix display names

**Files:**
- Modify: `Vecka/Services/RandomFactProvider.swift:15-45` (RandomFact struct)
- Modify: `Vecka/Services/RandomFactProvider.swift:121-208` (all RandomFact construction sites)

**Step 1: Add category field to RandomFact**

In `RandomFactProvider.swift`, add `category` to the struct (line ~15):

```swift
struct RandomFact: Identifiable, Equatable {
    let id: String
    let text: String
    let icon: String?
    let color: Color
    let explanation: String
    let source: String?
    let category: String?  // NEW: "tradition", "food", "invention", "nature", "history", "quirky", "calendar"

    static func == (lhs: RandomFact, rhs: RandomFact) -> Bool {
        lhs.id == rhs.id
    }

    /// Human-readable category name for display
    var displayCategory: String {
        guard let category = category else { return "Fact" }
        switch category {
        case "tradition": return "Tradition"
        case "food": return "Food"
        case "invention": return "Invention"
        case "nature": return "Nature"
        case "history": return "History"
        case "quirky": return "Fun Fact"
        case "calendar": return "Calendar"
        default: return category.capitalized
        }
    }
```

**Step 2: Fix truncating display names**

In `displaySource` (line ~28), change two cases:

```swift
case "US": return "USA"
case "UK": return "Britain"
case "GB": return "Britain"
```

**Step 3: Pass category through all RandomFact construction sites**

There are 4 production sites in `RandomFactProvider.swift`:

1. **Fallback fact** (line ~121): Add `category: nil`
2. **Region fact** (line ~137): Add `category: fact.category`
3. **Easter egg** (line ~167): Add `category: "quirky"`
4. **Calendar fact** (line ~201): Add `category: "calendar"`

**Step 4: Build and verify**

Run: `./build.sh build`
Expected: Compiler errors in LandingPageView.swift (deep link) and ShareableFact.swift (previews) because they construct RandomFact without the new `category` parameter.

### Task 2: Fix remaining call sites

**Files:**
- Modify: `Vecka/Views/LandingPageView.swift:503` (deep link RandomFact construction)
- Modify: `Vecka/Views/ShareableFact.swift:143,156` (preview RandomFact constructions)

**Step 1: Fix deep link construction in LandingPageView**

At line ~503, add category to the RandomFact init:

```swift
let fact = RandomFact(
    id: quirkyFact.id,
    text: quirkyFact.text,
    icon: iconFor(category: quirkyFact.factCategory),
    color: colorFor(category: quirkyFact.factCategory),
    explanation: quirkyFact.explanation.isEmpty ? quirkyFact.text : quirkyFact.explanation,
    source: quirkyFact.region,
    category: quirkyFact.category  // NEW
)
```

**Step 2: Fix preview constructions in ShareableFact**

At lines ~143 and ~156, add `category: "food"` to both preview RandomFact inits.

**Step 3: Build and verify**

Run: `./build.sh build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Vecka/Services/RandomFactProvider.swift Vecka/Views/LandingPageView.swift Vecka/Views/ShareableFact.swift
git commit -m "feat(facts): Add category to RandomFact model, fix truncating display names"
```

### Task 3: Update detail sheet — country title + category pill

**Files:**
- Modify: `Vecka/Views/LandingPageView.swift:1240-1308` (RandomFactDetailSheet)

**Step 1: Change sheet title from "FACT" to country name**

In `RandomFactDetailSheet.body` (line ~1250), change:

```swift
// BEFORE:
JohoSheetHeader(
    title: "FACT",
    shareButton: FactShareButton(fact: fact),
    onClose: { dismiss() }
)

// AFTER:
JohoSheetHeader(
    title: fact.displaySource.uppercased(),
    shareButton: FactShareButton(fact: fact),
    onClose: { dismiss() }
)
```

**Step 2: Add category pill between header and content card**

After the `JohoSheetHeader` closing paren (line ~1254) and before the main content card `VStack`, add:

```swift
// Category pill
HStack {
    JohoPill(text: fact.displayCategory.uppercased(), style: .colored(fact.color), size: .small)
    Spacer()
}
.padding(.horizontal, JohoDimensions.spacingMD)
.padding(.top, JohoDimensions.spacingSM)
```

**Step 3: Build and verify**

Run: `./build.sh build`
Expected: BUILD SUCCEEDED

**Step 4: Install and verify on simulator**

Launch on iPhone 17 Pro simulator. Navigate to landing page. Tap a fact tile. Verify:
- Sheet title shows country name (e.g., "SWEDEN") not "FACT"
- Category pill appears below header (e.g., "FOOD" in colored pill)

### Task 4: Update share card footer

**Files:**
- Modify: `Vecka/Views/ShareableFact.swift:49-105` (ShareableFactCard.body)

**Step 1: Change footer labels**

In `ShareableFactCard.body` (line ~50), change the `ShareableCardShell` init:

```swift
// BEFORE:
ShareableCardShell(
    headerIcon: fact.icon ?? "lightbulb.fill",
    headerIconColor: fact.color,
    headerAccentColor: fact.color,
    footerLeftLabel: "RANDOM FACTS",
    footerRightLabel: fact.displaySource.uppercased()
)

// AFTER:
ShareableCardShell(
    headerIcon: fact.icon ?? "lightbulb.fill",
    headerIconColor: fact.color,
    headerAccentColor: fact.color,
    footerLeftLabel: fact.displaySource.uppercased(),
    footerRightLabel: fact.displayCategory.uppercased()
)
```

**Step 2: Build and verify**

Run: `./build.sh build`
Expected: BUILD SUCCEEDED

**Step 3: Commit all UI changes**

```bash
git add Vecka/Views/LandingPageView.swift Vecka/Views/ShareableFact.swift
git commit -m "feat(facts): Show country title + category pill in detail sheet and share card"
```

### Task 5: Visual verification on simulator

**Step 1: Full verification**

Launch app on simulator. Verify:
- Grid tiles: All country names fit without truncation (especially "BRITAIN" and "USA")
- Tap a fact: Detail sheet shows country as title, category pill below
- Share button: Share card shows country left, category right in footer
- Refresh facts (tap reload): New facts load with correct country/category

**Step 2: Commit design doc**

```bash
git add docs/plans/2026-02-26-fact-card-streamlining-design.md docs/plans/2026-02-26-fact-card-streamlining.md
git commit -m "docs: Add fact card streamlining design and implementation plan"
```
