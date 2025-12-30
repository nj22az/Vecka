//
//  HolidayManager.swift
//  Vecka
//
//  Manages Holiday data: Seeding from logic -> SwiftData -> In-Memory Cache
//

import Foundation
import SwiftData
import SwiftUI

struct HolidayCacheItem: Identifiable, Hashable, Sendable {
    let id: String
    let region: String
    let name: String
    let titleOverride: String?
    let isRedDay: Bool
    let symbolName: String?
}

extension HolidayCacheItem {
    var displayTitle: String {
        let trimmedOverride = (titleOverride ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedOverride.isEmpty { return trimmedOverride }
        guard name.hasPrefix("holiday.") else { return name }
        return NSLocalizedString(name, comment: "Holiday Name")
    }

    var isCustom: Bool {
        name.hasPrefix("custom.")
    }
}

@MainActor
@Observable
class HolidayManager {
    static let shared = HolidayManager()

    // Thread-safe cache for holiday data: [Date: [HolidayCacheItem]]
    // Dictionary reads are atomic; writes happen on MainActor only
    // @ObservationIgnored because cross-actor access is needed
    @ObservationIgnored
    nonisolated(unsafe) private var _holidayCache: [Date: [HolidayCacheItem]] = [:]

    /// Access to the holiday cache (thread-safe for reads, MainActor-only for writes)
    nonisolated var holidayCache: [Date: [HolidayCacheItem]] {
        _holidayCache
    }

    /// MainActor-isolated setter for the cache
    private func setHolidayCache(_ newValue: [Date: [HolidayCacheItem]]) {
        _holidayCache = newValue
    }

    // Holiday engine for date calculations
    private let engine = HolidayEngine()

    private var lastFocusYear: Int?

    private init() {}

    /// Initialize: Seed DB if empty, update existing rules, load to cache
    func initialize(context: ModelContext) {
        seedSwedishRules(context: context)
        calculateAndCacheHolidays(context: context)
    }

    /// Calculate holidays for a 5-year window (Current Year +/- 2).
    /// If `focusYear` is provided, also caches a 5-year window around that year.
    func calculateAndCacheHolidays(context: ModelContext, focusYear: Int? = nil) {
        if let focusYear {
            lastFocusYear = focusYear
        }
        let effectiveFocusYear = focusYear ?? lastFocusYear

        // Check Settings
        let showHolidays = (UserDefaults.standard.object(forKey: "showHolidays") as? Bool) ?? true
        let selectedRegions = HolidayRegionSelection(rawValue: UserDefaults.standard.string(forKey: "holidayRegions") ?? "")
        var regions = selectedRegions.regions
        if regions.isEmpty {
            let legacy = UserDefaults.standard.string(forKey: "holidayRegion") ?? "SE"
            regions = HolidayRegionSelection.normalized([legacy], maxCount: 2)
        }
        
        if !showHolidays {
            setHolidayCache([:])
            Log.d("Holidays disabled in settings. Cache cleared.")
            return
        }

        do {
            // Fetch all rules
            let descriptor = FetchDescriptor<HolidayRule>()
            let allRules = try context.fetch(descriptor)

            // Filter by selected regions.
            // Empty region is treated as "All Regions" (user-defined or global rules).
            let rules = allRules.filter { $0.region.isEmpty || regions.contains($0.region) }

            let span = ConfigurationManager.shared.getInt("holiday_cache_span", context: context, default: 2)
            let currentYear = Calendar.current.component(.year, from: Date())
            var yearsToCache = Set((currentYear - span)...(currentYear + span))
            if let effectiveFocusYear {
                yearsToCache.formUnion((effectiveFocusYear - span)...(effectiveFocusYear + span))
            }
            let years = yearsToCache.sorted()

            var newCache: [Date: [HolidayCacheItem]] = [:]

            for year in years {
                for rule in rules {
                    if let date = engine.calculateDate(for: rule, year: year) {
                        let normalized = Calendar.current.startOfDay(for: date)
                        let symbolName = normalizedSymbolName(for: rule, context: context)
                        let item = HolidayCacheItem(
                            id: rule.id,
                            region: rule.region,
                            name: rule.name,
                            titleOverride: rule.titleOverride,
                            isRedDay: rule.isRedDay,
                            symbolName: symbolName
                        )
                        newCache[normalized, default: []].append(item)
                    }
                }
            }

            var sortedCache: [Date: [HolidayCacheItem]] = [:]
            sortedCache.reserveCapacity(newCache.count)
            for (day, items) in newCache {
                sortedCache[day] = items.sorted(by: { sortHolidays(lhs: $0, rhs: $1) })
            }

            setHolidayCache(sortedCache)
            Log.i("Engine calculated \(newCache.count) holiday dates for regions \(regions.joined(separator: ", ")).")
        } catch {
            Log.w("Failed to fetch holiday rules: \(error.localizedDescription)")
        }
    }

    private func sortHolidays(lhs: HolidayCacheItem, rhs: HolidayCacheItem) -> Bool {
        if lhs.isRedDay != rhs.isRedDay { return lhs.isRedDay && !rhs.isRedDay }
        let left = lhs.displayTitle
        let right = rhs.displayTitle
        return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
    }

    private func normalizedSymbolName(for rule: HolidayRule, context: ModelContext) -> String? {
        let trimmed = (rule.symbolName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }

        // Use shared icon logic
        if let icon = HolidayManager.holidayIcon(for: rule.name) {
            return icon
        }

        // Fallback: flag.fill for red days, star for others
        return rule.isRedDay ? "flag.fill" : "star"
    }

    /// Shared holiday icon logic used by Widgets and App
    static func holidayIcon(for holidayId: String?) -> String? {
        guard let id = holidayId?.lowercased() else { return nil }

        // Christmas related
        if id.contains("christmas") || id.contains("jul") {
            return "gift.fill"
        }
        // New Year
        if id.contains("new-year") || id.contains("nyar") || id.contains("nyår") {
            return "sparkles"
        }
        // Easter related
        if id.contains("easter") || id.contains("påsk") || id.contains("pask") {
            return "sun.max.fill"
        }
        // Midsummer
        if id.contains("midsommar") || id.contains("midsummer") {
            return "leaf.fill"
        }
        // National day
        if id.contains("national") || id.contains("sverige") {
            return "flag.fill"
        }
        // Valentine's
        if id.contains("valentin") || id.contains("hjärtan") {
            return "heart.fill"
        }
        // All Saints
        if id.contains("saints") || id.contains("helgon") {
            return "candle.fill"
        }
        // Epiphany
        if id.contains("epiphany") || id.contains("tretton") {
            return "star.circle.fill"
        }
        // Ascension
        if id.contains("ascension") || id.contains("himmelsfärd") {
            return "cloud.sun.fill"
        }
        // Pentecost
        if id.contains("pentecost") || id.contains("pingst") {
            return "flame.fill"
        }
        // Mother's/Father's day
        if id.contains("mother") || id.contains("mors") || id.contains("father") || id.contains("fars") {
            return "heart.circle.fill"
        }
        // Walpurgis
        if id.contains("walpurgis") || id.contains("valborg") {
            return "flame"
        }
        // May Day / Labor Day
        if id.contains("labor") || id.contains("första maj") || id.contains("may-day") {
            return "figure.walk"
        }

        return nil
    }
    
    /// Seed the Database with Swedish Holiday Rules (The "DNA")
    private func seedSwedishRules(context: ModelContext) {
        Log.d("Seeding holiday rules (non-destructive)...")

        migrateLegacySwedishRuleNames(context: context)

        let rules: [HolidayRule] = [
            // --- RÖDA DAGAR (Red Days - Official Public Holidays) ---
            HolidayRule(name: "holiday.nyarsdagen", isRedDay: true, type: .fixed, month: 1, day: 1),
            HolidayRule(name: "holiday.trettondedag_jul", isRedDay: true, type: .fixed, month: 1, day: 6),
            HolidayRule(name: "holiday.forsta_maj", isRedDay: true, type: .fixed, month: 5, day: 1),
            HolidayRule(name: "holiday.sveriges_nationaldag", isRedDay: true, type: .fixed, month: 6, day: 6),
            HolidayRule(name: "holiday.juldagen", isRedDay: true, type: .fixed, month: 12, day: 25),
            HolidayRule(name: "holiday.annandag_jul", isRedDay: true, type: .fixed, month: 12, day: 26),

            // --- HELGDAGAR (Holidays - NOT Red Days) ---
            HolidayRule(name: "holiday.nyarsafton", isRedDay: false, type: .fixed, month: 12, day: 31),
            HolidayRule(name: "holiday.julafton", isRedDay: false, type: .fixed, month: 12, day: 24),

            // --- Observances (Not Red Days) ---
            HolidayRule(name: "holiday.alla_hjartans_dag", isRedDay: false, type: .fixed, month: 2, day: 14),
            HolidayRule(name: "holiday.internationella_kvinnodagen", isRedDay: false, type: .fixed, month: 3, day: 8),
            
            // --- Easter Relative ---
            HolidayRule(name: "holiday.langfredagen", isRedDay: true, type: .easterRelative, daysOffset: -2),
            HolidayRule(name: "holiday.paskdagen", isRedDay: true, type: .easterRelative, daysOffset: 0),
            HolidayRule(name: "holiday.annandag_pask", isRedDay: true, type: .easterRelative, daysOffset: 1),
            HolidayRule(name: "holiday.kristi_himmelsfardsdag", isRedDay: true, type: .easterRelative, daysOffset: 39),
            HolidayRule(name: "holiday.pingstdagen", isRedDay: true, type: .easterRelative, daysOffset: 49),
            
            // --- RÖRLIGA RÖDA DAGAR (Floating Red Days) ---
            // Midsommardagen: Saturday between June 20–26 (RED DAY)
            HolidayRule(name: "holiday.midsommardagen", isRedDay: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26),

            // Midsommarafton: Friday before Midsommardagen (HOLIDAY but NOT RED)
            HolidayRule(name: "holiday.midsommarafton", isRedDay: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25),

            // Alla helgons dag: Saturday between Oct 31 – Nov 6 (RED DAY)
            HolidayRule(name: "holiday.alla_helgons_dag", isRedDay: true, type: .nthWeekday, month: 11, weekday: 7, ordinal: 1),

            // --- Observances (Not Red Days) ---
            // Mother's Day: Last Sunday in May
            HolidayRule(name: "holiday.mors_dag", isRedDay: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: -1),
            
            // Father's Day: Second Sunday in November
            HolidayRule(name: "holiday.fars_dag", isRedDay: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2),
            
            // --- Astronomical Events (Observances) ---
            HolidayRule(name: "holiday.virdagjamning", isRedDay: false, type: .astronomical, month: 3),
            HolidayRule(name: "holiday.sommarsolstand", isRedDay: false, type: .astronomical, month: 6),
            HolidayRule(name: "holiday.hostdagjamning", isRedDay: false, type: .astronomical, month: 9),
            HolidayRule(name: "holiday.vintersolstand", isRedDay: false, type: .astronomical, month: 12),
            
            // --- US Holidays (Seeded for "US" region) ---
            HolidayRule(name: "New Year's Day", region: "US", isRedDay: true, type: .fixed, month: 1, day: 1),
            HolidayRule(name: "Independence Day", region: "US", isRedDay: true, type: .fixed, month: 7, day: 4),
            HolidayRule(name: "Christmas Day", region: "US", isRedDay: true, type: .fixed, month: 12, day: 25),
            HolidayRule(name: "Thanksgiving Day", region: "US", isRedDay: true, type: .nthWeekday, month: 11, weekday: 5, ordinal: 4), // 4th Thursday
            
            // --- Vietnamese Holidays (Seeded for "VN" region) ---
            // Lunar
            HolidayRule(name: "Tết Nguyên Đán", region: "VN", isRedDay: true, type: .lunar, month: 1, day: 1), // Lunar New Year
            HolidayRule(name: "Giỗ Tổ Hùng Vương", region: "VN", isRedDay: true, type: .lunar, month: 3, day: 10), // Hung Kings
            
            // Fixed
            HolidayRule(name: "Ngày Thống nhất", region: "VN", isRedDay: true, type: .fixed, month: 4, day: 30), // Reunification
            HolidayRule(name: "Quốc tế Lao động", region: "VN", isRedDay: true, type: .fixed, month: 5, day: 1), // Labor Day
            HolidayRule(name: "Quốc khánh", region: "VN", isRedDay: true, type: .fixed, month: 9, day: 2) // National Day
        ]

        do {
            let existing = try context.fetch(FetchDescriptor<HolidayRule>())
            let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
            var insertedCount = 0
            var updatedCount = 0

            for rule in rules {
                if let existingRule = existingById[rule.id] {
                    guard existingRule.userModifiedAt == nil else { continue }

                    var didChange = false

                    if existingRule.isRedDay != rule.isRedDay {
                        existingRule.isRedDay = rule.isRedDay
                        didChange = true
                    }
                    if existingRule.type != rule.type {
                        existingRule.type = rule.type
                        didChange = true
                    }
                    if existingRule.month != rule.month {
                        existingRule.month = rule.month
                        didChange = true
                    }
                    if existingRule.day != rule.day {
                        existingRule.day = rule.day
                        didChange = true
                    }
                    if existingRule.daysOffset != rule.daysOffset {
                        existingRule.daysOffset = rule.daysOffset
                        didChange = true
                    }
                    if existingRule.weekday != rule.weekday {
                        existingRule.weekday = rule.weekday
                        didChange = true
                    }
                    if existingRule.ordinal != rule.ordinal {
                        existingRule.ordinal = rule.ordinal
                        didChange = true
                    }
                    if existingRule.dayRangeStart != rule.dayRangeStart {
                        existingRule.dayRangeStart = rule.dayRangeStart
                        didChange = true
                    }
                    if existingRule.dayRangeEnd != rule.dayRangeEnd {
                        existingRule.dayRangeEnd = rule.dayRangeEnd
                        didChange = true
                    }

                    if didChange {
                        updatedCount += 1
                    }
                } else {
                    context.insert(rule)
                    insertedCount += 1
                }
            }

            if insertedCount > 0 || updatedCount > 0 {
                try context.save()
                Log.i("Seeded \(insertedCount) holiday rules (updated: \(updatedCount)).")
            } else {
                Log.d("No holiday rules needed seeding.")
            }
        } catch {
            Log.w("Failed to seed holiday rules: \(error.localizedDescription)")
        }
    }

    private func migrateLegacySwedishRuleNames(context: ModelContext) {
        let mapping: [String: String] = [
            "Nyårsdagen": "holiday.nyarsdagen",
            "Trettondedag jul": "holiday.trettondedag_jul",
            "Första maj": "holiday.forsta_maj",
            "Sveriges nationaldag": "holiday.sveriges_nationaldag",
            "Juldagen": "holiday.juldagen",
            "Annandag jul": "holiday.annandag_jul",
            "Nyårsafton": "holiday.nyarsafton",
            "Julafton": "holiday.julafton",
            "Alla hjärtans dag": "holiday.alla_hjartans_dag",
            "Internationella kvinnodagen": "holiday.internationella_kvinnodagen",
            "Långfredagen": "holiday.langfredagen",
            "Påskdagen": "holiday.paskdagen",
            "Annandag påsk": "holiday.annandag_pask",
            "Kristi himmelsfärdsdag": "holiday.kristi_himmelsfardsdag",
            "Pingstdagen": "holiday.pingstdagen",
            "Midsommardagen": "holiday.midsommardagen",
            "Midsommarafton": "holiday.midsommarafton",
            "Alla helgons dag": "holiday.alla_helgons_dag",
            "Mors dag": "holiday.mors_dag",
            "Fars dag": "holiday.fars_dag",
            "Vårdagjämningen": "holiday.virdagjamning",
            "Sommarsolståndet": "holiday.sommarsolstand",
            "Höstdagjämningen": "holiday.hostdagjamning",
            "Vintersolståndet": "holiday.vintersolstand"
        ]

        do {
            let descriptor = FetchDescriptor<HolidayRule>(predicate: #Predicate<HolidayRule> { $0.region == "SE" })
            let rules = try context.fetch(descriptor)
            let byId = Dictionary(uniqueKeysWithValues: rules.map { ($0.id, $0) })

            for rule in rules {
                guard let newKey = mapping[rule.name] else { continue }
                let newId = "SE-\(newKey)"

                if let existing = byId[newId], existing !== rule {
                    if (existing.titleOverride ?? "").isEmpty, let titleOverride = rule.titleOverride, !titleOverride.isEmpty {
                        existing.titleOverride = titleOverride
                    }
                    if (existing.symbolName ?? "").isEmpty, let symbolName = rule.symbolName, !symbolName.isEmpty {
                        existing.symbolName = symbolName
                    }
                    if existing.userModifiedAt == nil, let modifiedAt = rule.userModifiedAt {
                        existing.userModifiedAt = modifiedAt
                    }

                    context.delete(rule)
                } else {
                    rule.name = newKey
                    rule.id = newId
                }
            }

            try context.save()
        } catch {
            Log.w("Failed to migrate legacy Swedish holiday names: \(error.localizedDescription)")
        }
    }
}
