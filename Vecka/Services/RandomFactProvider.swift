//
//  RandomFactProvider.swift
//  Vecka
//
//  情報デザイン: Database-driven fact provider for RANDOM FACTS tiles
//  Minimal code, queries SwiftData
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Random Fact (Display Model)

struct RandomFact: Identifiable, Equatable {
    let id: String
    let text: String
    let icon: String?
    let color: Color
    let explanation: String  // Detailed explanation for tap-to-expand
    let source: String?  // Country or source name (e.g., "Sweden", "Vietnam", "Calendar")

    static func == (lhs: RandomFact, rhs: RandomFact) -> Bool {
        lhs.id == rhs.id
    }

    /// Human-readable source name for display
    var displaySource: String {
        guard let source = source else { return "Random Fact" }
        switch source {
        case "SE": return "Sweden"
        case "VN": return "Vietnam"
        case "US": return "United States"
        case "UK": return "United Kingdom"
        case "GB": return "United Kingdom"
        case "NO": return "Norway"
        case "DK": return "Denmark"
        case "FI": return "Finland"
        case "NORDIC": return "Nordic"
        case "XX": return "Fun Fact"
        case "Calendar": return "Calendar"
        default: return source
        }
    }
}

// MARK: - Random Fact Provider

@MainActor
final class RandomFactProvider: ObservableObject {

    private let context: ModelContext
    private let selectedRegions: [String]
    private let today: Date
    private var usedFactIDs: Set<String> = []
    private let easterEggChance: Double = 0  // 情報デザイン: Disabled - facts must be understandable at a glance

    init(context: ModelContext, selectedRegions: [String] = ["NORDIC", "VN", "UK"], date: Date = Date()) {
        self.context = context
        // 情報デザイン: Expand NORDIC to individual country codes for database queries
        self.selectedRegions = Self.expandRegions(selectedRegions)
        self.today = date
    }

    /// Expands unified regions (like NORDIC) to their component countries
    private static func expandRegions(_ regions: [String]) -> [String] {
        var result: [String] = []
        for region in regions {
            if region == "NORDIC" {
                result.append(contentsOf: HolidayRegionSelection.nordicCountries)
            } else {
                result.append(region)
            }
        }
        return result
    }

    // MARK: - Public API

    func nextFact() -> RandomFact {
        // Small chance for easter egg
        if Double.random(in: 0...1) < easterEggChance,
           let egg = randomEasterEgg() {
            return egg
        }

        // 情報デザイン: 20% chance for calendar fact, 80% database facts for variety
        // This ensures interesting region facts dominate while still showing relevant date info
        if Double.random(in: 0...1) < 0.2,
           let calendarFact = randomCalendarFact() {
            return calendarFact
        }

        // Primarily show database facts for maximum variety
        return randomRegionFact()
    }

    func reset() {
        usedFactIDs.removeAll()
    }

    // MARK: - Database Queries

    private func randomRegionFact() -> RandomFact {
        // Query facts for selected regions
        let regions = selectedRegions
        let descriptor = FetchDescriptor<QuirkyFact>(
            predicate: #Predicate { regions.contains($0.region) }
        )

        let facts = (try? context.fetch(descriptor)) ?? []
        let available = facts.filter { !usedFactIDs.contains($0.id) }
        let pool = available.isEmpty ? facts : available

        guard !pool.isEmpty else {
            return RandomFact(
                id: "fallback",
                text: "Week numbers matter.",
                icon: "calendar",
                color: JohoColors.cyan,
                explanation: "ISO 8601 week numbers are the international standard for numbering weeks. This app helps you track weeks the Swedish way.",
                source: "Calendar"
            )
        }

        // True random selection for maximum variety
        let fact = pool.randomElement()!

        usedFactIDs.insert(fact.id)

        return RandomFact(
            id: fact.id,
            text: fact.text,
            icon: iconFor(category: fact.factCategory),
            color: colorFor(category: fact.factCategory),
            explanation: fact.explanation.isEmpty ? fact.text : fact.explanation,
            source: fact.region
        )
    }

    private func randomEasterEgg() -> RandomFact? {
        let descriptor = FetchDescriptor<QuirkyFact>(
            predicate: #Predicate { $0.region == "XX" }
        )

        let eggs = (try? context.fetch(descriptor)) ?? []
        let available = eggs.filter { !usedFactIDs.contains($0.id) }
        guard !available.isEmpty else { return nil }

        let day = Calendar.current.component(.day, from: today)
        let egg = available[day % available.count]

        usedFactIDs.insert(egg.id)

        return RandomFact(
            id: egg.id,
            text: egg.text,
            icon: "sparkles",
            color: JohoColors.yellow,
            explanation: egg.explanation.isEmpty ? egg.text : egg.explanation,
            source: "XX"
        )
    }

    // MARK: - Calendar Facts (情報デザイン: Database-driven calendar information)

    private func randomCalendarFact() -> RandomFact? {
        // Query all calendar facts from database
        let descriptor = FetchDescriptor<CalendarFact>()
        let allFacts = (try? context.fetch(descriptor)) ?? []

        // Filter to applicable facts for today
        let applicableFacts = allFacts.filter { $0.isApplicable(for: today) }

        // Filter out already-used facts
        let available = applicableFacts.filter { !usedFactIDs.contains($0.id) }
        guard !available.isEmpty else { return nil }

        // 情報デザイン: True random selection for variety
        let picked = available.randomElement()!
        usedFactIDs.insert(picked.id)

        return RandomFact(
            id: picked.id,
            text: picked.renderText(for: today),
            icon: picked.icon,
            color: picked.color,
            explanation: picked.explanation,
            source: "Calendar"
        )
    }

    // MARK: - Helpers (情報デザイン: Strong colors like Star page)

    private func iconFor(category: QuirkyFact.Category) -> String {
        switch category {
        case .tradition: return "person.2.fill"
        case .food: return "fork.knife"
        case .invention: return "lightbulb.fill"
        case .nature: return "leaf.fill"
        case .history: return "book.fill"
        case .quirky: return "star.fill"
        }
    }

    /// 情報デザイン: Use semantic colors by CATEGORY (not region flags)
    /// Strong colors like Star page month icons
    private func colorFor(category: QuirkyFact.Category) -> Color {
        switch category {
        case .tradition: return JohoColors.purple    // People zone
        case .food: return JohoColors.yellow         // NOW - cultural experience
        case .invention: return JohoColors.yellow    // Ideas/bright
        case .nature: return JohoColors.green        // Nature zone
        case .history: return JohoColors.pink        // CELEBRATION - heritage
        case .quirky: return JohoColors.cyan         // General info
        }
    }
}
