//
//  GlanceFactProvider.swift
//  Vecka
//
//  情報デザイン: Database-driven fact provider for GLANCE tiles
//  Minimal code, queries SwiftData
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Glance Fact (Display Model)

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

    private let context: ModelContext
    private let selectedRegions: [String]
    private let today: Date
    private var usedFactIDs: Set<String> = []
    private let easterEggChance: Double = 0.05

    init(context: ModelContext, selectedRegions: [String] = ["SE", "VN", "UK"], date: Date = Date()) {
        self.context = context
        self.selectedRegions = selectedRegions
        self.today = date
    }

    // MARK: - Public API

    func nextFact() -> GlanceFact {
        // Small chance for easter egg
        if Double.random(in: 0...1) < easterEggChance,
           let egg = randomEasterEgg() {
            return egg
        }

        // Try calendar fact first
        if let calendarFact = randomCalendarFact() {
            return calendarFact
        }

        // Fall back to region facts from database
        return randomRegionFact()
    }

    func reset() {
        usedFactIDs.removeAll()
    }

    // MARK: - Database Queries

    private func randomRegionFact() -> GlanceFact {
        // Query facts for selected regions
        let regions = selectedRegions
        let descriptor = FetchDescriptor<QuirkyFact>(
            predicate: #Predicate { regions.contains($0.region) }
        )

        let facts = (try? context.fetch(descriptor)) ?? []
        let available = facts.filter { !usedFactIDs.contains($0.id) }
        let pool = available.isEmpty ? facts : available

        guard !pool.isEmpty else {
            return GlanceFact(id: "fallback", text: "Week numbers matter.", icon: "sparkles", color: JohoColors.cyan)
        }

        // Seed based on date for daily consistency
        let day = Calendar.current.component(.day, from: today)
        let index = (day + usedFactIDs.count * 1000) % pool.count
        let fact = pool[index]

        usedFactIDs.insert(fact.id)

        return GlanceFact(
            id: fact.id,
            text: fact.text,
            icon: iconFor(category: fact.factCategory),
            color: colorFor(region: fact.region)
        )
    }

    private func randomEasterEgg() -> GlanceFact? {
        let descriptor = FetchDescriptor<QuirkyFact>(
            predicate: #Predicate { $0.region == "XX" }
        )

        let eggs = (try? context.fetch(descriptor)) ?? []
        let available = eggs.filter { !usedFactIDs.contains($0.id) }
        guard !available.isEmpty else { return nil }

        let day = Calendar.current.component(.day, from: today)
        let egg = available[day % available.count]

        usedFactIDs.insert(egg.id)

        return GlanceFact(id: egg.id, text: egg.text, icon: "sparkles", color: JohoColors.yellow)
    }

    // MARK: - Calendar Facts

    private func randomCalendarFact() -> GlanceFact? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        let day = calendar.component(.day, from: today)
        let month = calendar.component(.month, from: today)
        let weekOfYear = calendar.component(.weekOfYear, from: today)

        var facts: [(id: String, text: String, icon: String)] = []

        // Days until Friday
        let daysUntilFriday = (6 - weekday + 7) % 7
        if daysUntilFriday > 0 && daysUntilFriday < 5 {
            facts.append(("cal_friday", "\(daysUntilFriday) day\(daysUntilFriday == 1 ? "" : "s") until Friday", "party.popper"))
        }

        facts.append(("cal_week", "Week \(weekOfYear) of 52", "calendar"))

        if let range = calendar.range(of: .day, in: .month, for: today) {
            let daysLeft = range.count - day
            if daysLeft > 0 && daysLeft <= 10 {
                facts.append(("cal_month_end", "\(daysLeft) days left this month", "calendar.badge.clock"))
            }
            let progress = Int((Double(day) / Double(range.count)) * 100)
            facts.append(("cal_progress", "\(progress)% through the month", "chart.pie"))
        }

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        facts.append(("cal_year", "\(Int(Double(dayOfYear) / 365.0 * 100))% through the year", "chart.bar"))

        if weekday == 1 { facts.append(("cal_sunday", "Sunday: rest day", "bed.double")) }
        else if weekday == 6 { facts.append(("cal_friday_is", "It's Friday!", "star")) }
        else if weekday == 7 { facts.append(("cal_saturday", "Saturday vibes", "sun.max")) }

        switch month {
        case 1: facts.append(("cal_jan", "New year, new week numbers", "sparkles"))
        case 6: facts.append(("cal_jun", "Midsommar approaches", "sun.max"))
        case 12: facts.append(("cal_dec", "December: cozy season", "snowflake"))
        default: break
        }

        let available = facts.filter { !usedFactIDs.contains($0.id) }
        guard !available.isEmpty else { return nil }

        let seed = day + month * 100 + weekOfYear * 10000
        let picked = available[seed % available.count]
        usedFactIDs.insert(picked.id)

        return GlanceFact(id: picked.id, text: picked.text, icon: picked.icon, color: JohoColors.cyan)
    }

    // MARK: - Helpers

    private func iconFor(category: QuirkyFact.Category) -> String {
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
        case "SE": return Color(hex: "006AA7")
        case "VN": return Color(hex: "DA251D")
        case "UK": return Color(hex: "012169")
        case "US": return Color(hex: "3C3B6E")
        default: return JohoColors.cyan
        }
    }
}
