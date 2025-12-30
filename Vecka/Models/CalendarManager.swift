//
//  CalendarManager.swift
//  Vecka
//
//  Manages Calendar Rules: Seeding -> SwiftData -> WeekCalculator Configuration
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class CalendarManager {
    static let shared = CalendarManager()

    private(set) var activeRule: CalendarRule?
    
    private init() {}
    
    /// Initialize: Seed Rules if empty, then configure WeekCalculator
    func initialize(context: ModelContext) {
        seedDefaultRules(context: context)
        configureCalculator(context: context)
    }
    
    /// Configure WeekCalculator with the active rule
    private func configureCalculator(context: ModelContext) {
        do {
            // Fetch active rule
            let descriptor = FetchDescriptor<CalendarRule>(predicate: #Predicate<CalendarRule> { $0.isActive == true })
            let rules = try context.fetch(descriptor)

            if let activeRule = rules.first {
                self.activeRule = activeRule
                WeekCalculator.shared.configure(with: activeRule)
            } else {
                Log.w("No active calendar rule found. Using defaults.")
            }
        } catch {
            Log.w("Failed to fetch calendar rules: \(error.localizedDescription)")
        }
    }
    
    /// Seed the Database with Default Rules (SE/ISO8601)
    private func seedDefaultRules(context: ModelContext) {
        do {
            let existing = try context.fetch(FetchDescriptor<CalendarRule>())
            var byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
            var didChange = false

            let seDefault = CalendarRule(
                regionCode: "SE",
                identifier: "gregorian",
                firstWeekday: 2, // Monday
                minimumDaysInFirstWeek: 4, // ISO 8601
                localeIdentifier: "sv_SE",
                secondaryCalendarIdentifier: nil,
                isActive: existing.contains(where: { $0.isActive }) ? false : true
            )

            let usDefault = CalendarRule(
                regionCode: "US",
                identifier: "gregorian",
                firstWeekday: 1, // Sunday
                minimumDaysInFirstWeek: 1,
                localeIdentifier: "en_US",
                secondaryCalendarIdentifier: nil,
                isActive: false
            )

            let vnDefault = CalendarRule(
                regionCode: "VN",
                identifier: "gregorian",
                firstWeekday: 2, // Monday
                minimumDaysInFirstWeek: 4,
                localeIdentifier: "vi_VN",
                secondaryCalendarIdentifier: "chinese",
                isActive: false
            )

            func insertIfMissing(_ rule: CalendarRule) {
                guard byId[rule.id] == nil else { return }
                context.insert(rule)
                byId[rule.id] = rule
                didChange = true
            }

            insertIfMissing(seDefault)
            insertIfMissing(usDefault)
            insertIfMissing(vnDefault)

            if let seRule = byId["SE"], seRule.secondaryCalendarIdentifier == "chinese" {
                seRule.secondaryCalendarIdentifier = nil
                didChange = true
            }

            if let vnRule = byId["VN"], vnRule.secondaryCalendarIdentifier == nil {
                vnRule.secondaryCalendarIdentifier = "chinese"
                didChange = true
            }

            if didChange {
                try context.save()
                Log.i("Seeded/updated calendar rules.")
            }
        } catch {
            Log.w("Failed to seed calendar rules: \(error.localizedDescription)")
        }
    }
}
