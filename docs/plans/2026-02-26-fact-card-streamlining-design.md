# Fact Card Streamlining Design

## Goal

Fix truncated country names on fact grid tiles, add category context to detail sheet and share card, and carry category data through the RandomFact model.

## Problems Solved

1. "UNITED KINGDOM" and "UNITED STATES" truncate in the 3-column grid
2. Detail sheet title shows generic "FACT" instead of country name
3. No category (FOOD, TRADITION, NATURE) shown anywhere in detail/share views
4. Share card recipients can't see what country or category a fact belongs to

## Changes

### 1. RandomFact model — add category field

Add `category: String?` to `RandomFact` struct. Add `displayCategory` computed property mapping raw strings to readable labels. `RandomFactProvider` populates category from `QuirkyFact.category` or `"calendar"` for calendar facts.

### 2. Fix display names

In `RandomFact.displaySource`:
- "United Kingdom" -> "Britain"
- "United States" -> "USA"

### 3. Detail sheet — country title + category pill

- `JohoSheetHeader` title: `fact.displaySource.uppercased()` (was "FACT")
- Add `JohoPill(.colored(fact.color))` showing category between header and content card

### 4. Share card — country + category footer

Footer left: country name. Footer right: category name. Replaces "RANDOM FACTS" / source.

## Files

- `Vecka/Services/RandomFactProvider.swift` — pass category through RandomFact
- `Vecka/Views/LandingPageView.swift` — detail sheet, deep link category, displaySource fix
- `Vecka/Views/ShareableFact.swift` — share card footer
