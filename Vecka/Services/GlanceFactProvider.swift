//
//  GlanceFactProvider.swift
//  Vecka
//
//  Smart fact provider for GLANCE tiles
//  Priority: User Data → Calendar → Region Facts → Easter Eggs
//  情報デザイン: No duplicates, region-aware, daily rotation
//

import Foundation
import SwiftUI

// MARK: - Glance Fact

/// A fact ready for display in a GLANCE tile
struct GlanceFact: Identifiable, Equatable {
    let id: String
    let text: String
    let icon: String?
    let color: Color

    static func == (lhs: GlanceFact, rhs: GlanceFact) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Glance Fact Provider

@MainActor
final class GlanceFactProvider: ObservableObject {

    // MARK: - Properties

    /// User's selected holiday regions (priority order)
    private let selectedRegions: [String]

    /// Today's date for seeding randomness
    private let today: Date

    /// Track used facts to prevent duplicates
    private var usedFactIDs: Set<String> = []

    /// Easter egg probability (5%)
    private let easterEggChance: Double = 0.05

    // MARK: - Init

    init(selectedRegions: [String] = ["SE", "VN", "UK"], date: Date = Date()) {
        self.selectedRegions = selectedRegions
        self.today = date
    }

    // MARK: - Public API

    /// Get a unique fact for a GLANCE tile
    /// Each call returns a different fact (no duplicates in same view)
    func nextFact() -> GlanceFact {
        // Small chance for easter egg
        if Double.random(in: 0...1) < easterEggChance {
            if let egg = randomEasterEgg() {
                return egg
            }
        }

        // Try calendar fact first (contextual)
        if let calendarFact = randomCalendarFact() {
            return calendarFact
        }

        // Fall back to region facts
        return randomRegionFact()
    }

    /// Get multiple unique facts (for filling a GLANCE bento)
    func facts(count: Int) -> [GlanceFact] {
        usedFactIDs.removeAll()
        var result: [GlanceFact] = []

        for _ in 0..<count {
            result.append(nextFact())
        }

        return result
    }

    /// Reset used facts (call when view reloads)
    func reset() {
        usedFactIDs.removeAll()
    }

    // MARK: - Calendar Facts

    private func randomCalendarFact() -> GlanceFact? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        let day = calendar.component(.day, from: today)
        let month = calendar.component(.month, from: today)
        let weekOfYear = calendar.component(.weekOfYear, from: today)

        // Build pool of calendar facts
        var calendarFacts: [(id: String, text: String, icon: String)] = []

        // Days until weekend
        let daysUntilFriday = (6 - weekday + 7) % 7
        if daysUntilFriday > 0 && daysUntilFriday < 5 {
            calendarFacts.append((
                id: "cal_friday",
                text: "\(daysUntilFriday) day\(daysUntilFriday == 1 ? "" : "s") until Friday",
                icon: "party.popper"
            ))
        }

        // Week number
        calendarFacts.append((
            id: "cal_week",
            text: "Week \(weekOfYear) of 52",
            icon: "calendar"
        ))

        // Days until end of month
        if let range = calendar.range(of: .day, in: .month, for: today) {
            let daysLeft = range.count - day
            if daysLeft > 0 && daysLeft <= 10 {
                calendarFacts.append((
                    id: "cal_month_end",
                    text: "\(daysLeft) days left this month",
                    icon: "calendar.badge.clock"
                ))
            }
        }

        // Month progress
        if let range = calendar.range(of: .day, in: .month, for: today) {
            let progress = Int((Double(day) / Double(range.count)) * 100)
            calendarFacts.append((
                id: "cal_progress",
                text: "\(progress)% through the month",
                icon: "chart.pie"
            ))
        }

        // Year progress
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        let yearProgress = Int((Double(dayOfYear) / 365.0) * 100)
        calendarFacts.append((
            id: "cal_year",
            text: "\(yearProgress)% through the year",
            icon: "chart.bar"
        ))

        // Special day messages
        if weekday == 1 { // Sunday
            calendarFacts.append((id: "cal_sunday", text: "Sunday: rest day", icon: "bed.double"))
        } else if weekday == 6 { // Friday
            calendarFacts.append((id: "cal_friday_is", text: "It's Friday!", icon: "star"))
        } else if weekday == 7 { // Saturday
            calendarFacts.append((id: "cal_saturday", text: "Saturday vibes", icon: "sun.max"))
        }

        // Month-specific
        switch month {
        case 1: calendarFacts.append((id: "cal_jan", text: "New year, new week numbers", icon: "sparkles"))
        case 6: calendarFacts.append((id: "cal_jun", text: "Midsommar approaches", icon: "sun.max"))
        case 12: calendarFacts.append((id: "cal_dec", text: "December: cozy season", icon: "snowflake"))
        default: break
        }

        // Filter out already used
        let available = calendarFacts.filter { !usedFactIDs.contains($0.id) }
        guard !available.isEmpty else { return nil }

        // Pick one based on today's date (consistent within day)
        let seed = day + month * 100 + weekOfYear * 10000
        let index = seed % available.count
        let picked = available[index]

        usedFactIDs.insert(picked.id)

        return GlanceFact(
            id: picked.id,
            text: picked.text,
            icon: picked.icon,
            color: JohoColors.cyan
        )
    }

    // MARK: - Region Facts

    private func randomRegionFact() -> GlanceFact {
        // Get facts from selected regions
        let regionFacts = QuirkyFactsDB.facts(for: selectedRegions)

        // Filter out already used
        let available = regionFacts.filter { !usedFactIDs.contains($0.id) }

        // If all used, reset and pick any
        let pool = available.isEmpty ? regionFacts : available

        // Seed random based on date for daily consistency
        let calendar = Calendar.current
        let day = calendar.component(.day, from: today)
        let seed = day + usedFactIDs.count * 1000

        let index = seed % max(pool.count, 1)
        let fact = pool.indices.contains(index) ? pool[index] : pool[0]

        usedFactIDs.insert(fact.id)

        return GlanceFact(
            id: fact.id,
            text: fact.text,
            icon: iconFor(category: fact.category),
            color: colorFor(region: fact.region)
        )
    }

    // MARK: - Easter Eggs

    private func randomEasterEgg() -> GlanceFact? {
        let eggs = QuirkyFactsDB.easterEggs
        let available = eggs.filter { !usedFactIDs.contains($0.id) }
        guard !available.isEmpty else { return nil }

        let calendar = Calendar.current
        let day = calendar.component(.day, from: today)
        let index = day % available.count
        let egg = available[index]

        usedFactIDs.insert(egg.id)

        return GlanceFact(
            id: egg.id,
            text: egg.text,
            icon: "sparkles",
            color: JohoColors.yellow
        )
    }

    // MARK: - Helpers

    private func iconFor(category: QuirkyFact.FactCategory) -> String {
        switch category {
        case .tradition: return "person.2"
        case .food: return "fork.knife"
        case .invention: return "lightbulb"
        case .nature: return "leaf"
        case .history: return "book"
        case .quirky: return "sparkles"
        }
    }

    private func colorFor(region: String) -> Color {
        switch region.uppercased() {
        case "SE": return Color(hex: "006AA7") // Swedish blue
        case "VN": return Color(hex: "DA251D") // Vietnamese red
        case "UK": return Color(hex: "012169") // British blue
        case "US": return Color(hex: "3C3B6E") // American blue
        default: return JohoColors.cyan
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension GlanceFactProvider {
    static var preview: GlanceFactProvider {
        GlanceFactProvider(selectedRegions: ["SE", "VN", "UK"])
    }
}
#endif
