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
    let isBankHoliday: Bool
    let symbolName: String?
    let iconColor: String?   // Hex color for icon background (e.g., "FFB5BA")
    let notes: String?
    let isUserCreated: Bool  // True if userModifiedAt != nil
}

extension HolidayCacheItem {
    var displayTitle: String {
        let trimmedOverride = (titleOverride ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedOverride.isEmpty { return trimmedOverride }
        guard name.hasPrefix("holiday.") else { return name }
        return NSLocalizedString(name, comment: "Holiday Name")
    }

    /// Returns true if this is a user-created observance that can be deleted
    var isCustom: Bool {
        isUserCreated || name.hasPrefix("custom.")
    }
}

/// Thread-safe storage for holiday cache, allowing cross-actor access
/// Uses NSLock for synchronization between main app and widget background threads
final class HolidayCacheStorage: @unchecked Sendable {
    private var _cache: [Date: [HolidayCacheItem]] = [:]
    private let lock = NSLock()

    var cache: [Date: [HolidayCacheItem]] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _cache
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _cache = newValue
        }
    }
}

@MainActor
@Observable
class HolidayManager {
    static let shared = HolidayManager()

    // Thread-safe cache storage using a dedicated actor-safe wrapper
    // Allows widget access from background threads without data races
    // HolidayCacheStorage is Sendable and uses NSLock internally for thread safety
    @ObservationIgnored
    nonisolated private static let cacheStorage = HolidayCacheStorage()

    /// Thread-safe access to the holiday cache
    nonisolated var holidayCache: [Date: [HolidayCacheItem]] {
        Self.cacheStorage.cache
    }

    /// MainActor-isolated setter for the cache with thread-safe write
    private func setHolidayCache(_ newValue: [Date: [HolidayCacheItem]]) {
        Self.cacheStorage.cache = newValue
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

    // MARK: - 情報デザイン: Load Defaults Feature

    /// Load default holiday rules for a specific region
    /// This will insert any missing default rules and log the action
    func loadDefaults(for region: String, context: ModelContext) {
        Log.i("Loading defaults for region: \(region)")

        // Get all default rules for this region from the seed data
        let defaultRules = getDefaultRulesForRegion(region)
        guard !defaultRules.isEmpty else {
            Log.w("No default rules found for region: \(region)")
            return
        }

        do {
            // Fetch existing rules for this region
            let descriptor = FetchDescriptor<HolidayRule>(
                predicate: #Predicate { $0.region == region }
            )
            let existingRules = try context.fetch(descriptor)
            let existingIds = Set(existingRules.map { $0.id })

            var insertedCount = 0

            for rule in defaultRules {
                if !existingIds.contains(rule.id) {
                    context.insert(rule)
                    insertedCount += 1
                }
            }

            if insertedCount > 0 {
                try context.save()
                Log.i("Loaded \(insertedCount) default rules for \(region)")

                // Log to changelog
                HolidayChangeLogService.shared.logDefaultsLoaded(
                    region: region,
                    rulesCount: insertedCount,
                    source: .user,
                    context: context
                )
            } else {
                Log.d("All default rules already exist for \(region)")
            }

            // Refresh cache
            calculateAndCacheHolidays(context: context)
        } catch {
            Log.w("Failed to load defaults for \(region): \(error.localizedDescription)")
        }
    }

    /// Reset a specific rule to its default values
    /// Returns true if reset was successful
    func resetRuleToDefault(_ rule: HolidayRule, context: ModelContext) -> Bool {
        guard rule.canResetToDefault,
              let originalJSON = rule.originalDefaultJSON,
              let data = originalJSON.data(using: .utf8),
              let snapshot = try? JSONDecoder().decode(HolidayRuleSnapshot.self, from: data) else {
            Log.w("Cannot reset rule \(rule.id) to default - no original data")
            return false
        }

        // Capture before state for changelog
        let beforeState = HolidayRuleSnapshot(from: rule)

        // Reset to default values
        rule.name = snapshot.name
        rule.isBankHoliday = snapshot.isBankHoliday
        rule.titleOverride = snapshot.titleOverride
        rule.symbolName = snapshot.symbolName
        rule.iconColor = snapshot.iconColor
        rule.month = snapshot.month
        rule.day = snapshot.day
        rule.daysOffset = snapshot.daysOffset
        rule.weekday = snapshot.weekday
        rule.ordinal = snapshot.ordinal
        rule.dayRangeStart = snapshot.dayRangeStart
        rule.dayRangeEnd = snapshot.dayRangeEnd
        rule.userModifiedAt = nil  // Clear modification flag
        rule.isEnabled = true

        do {
            try context.save()
            Log.i("Reset rule \(rule.id) to default")

            // Log to changelog
            HolidayChangeLogService.shared.logReset(
                rule: rule,
                beforeState: beforeState,
                source: .user,
                context: context
            )

            // Refresh cache
            calculateAndCacheHolidays(context: context)
            return true
        } catch {
            Log.w("Failed to reset rule: \(error.localizedDescription)")
            return false
        }
    }

    /// Get default rules for a specific region (used by loadDefaults)
    private func getDefaultRulesForRegion(_ region: String) -> [HolidayRule] {
        // Helper to create system default rules
        func systemRule(
            name: String,
            isBankHoliday: Bool,
            type: HolidayRuleType,
            month: Int? = nil,
            day: Int? = nil,
            daysOffset: Int? = nil,
            weekday: Int? = nil,
            ordinal: Int? = nil,
            dayRangeStart: Int? = nil,
            dayRangeEnd: Int? = nil
        ) -> HolidayRule {
            HolidayRule(
                name: name,
                region: region,
                isBankHoliday: isBankHoliday,
                type: type,
                month: month,
                day: day,
                daysOffset: daysOffset,
                weekday: weekday,
                ordinal: ordinal,
                dayRangeStart: dayRangeStart,
                dayRangeEnd: dayRangeEnd,
                isSystemDefault: true,
                isEnabled: true
            )
        }

        switch region {
        case "SE", "":
            return [
                systemRule(name: "holiday.nyarsdagen", isBankHoliday: true, type: .fixed, month: 1, day: 1),
                systemRule(name: "holiday.trettondedag_jul", isBankHoliday: true, type: .fixed, month: 1, day: 6),
                systemRule(name: "holiday.forsta_maj", isBankHoliday: true, type: .fixed, month: 5, day: 1),
                systemRule(name: "holiday.sveriges_nationaldag", isBankHoliday: true, type: .fixed, month: 6, day: 6),
                systemRule(name: "holiday.juldagen", isBankHoliday: true, type: .fixed, month: 12, day: 25),
                systemRule(name: "holiday.annandag_jul", isBankHoliday: true, type: .fixed, month: 12, day: 26),
                systemRule(name: "holiday.nyarsafton", isBankHoliday: false, type: .fixed, month: 12, day: 31),
                systemRule(name: "holiday.julafton", isBankHoliday: false, type: .fixed, month: 12, day: 24),
                systemRule(name: "holiday.alla_hjartans_dag", isBankHoliday: false, type: .fixed, month: 2, day: 14),
                systemRule(name: "holiday.internationella_kvinnodagen", isBankHoliday: false, type: .fixed, month: 3, day: 8),
                systemRule(name: "holiday.langfredagen", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
                systemRule(name: "holiday.paskdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
                systemRule(name: "holiday.annandag_pask", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
                systemRule(name: "holiday.kristi_himmelsfardsdag", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
                systemRule(name: "holiday.pingstdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 49),
                systemRule(name: "holiday.midsommardagen", isBankHoliday: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26),
                systemRule(name: "holiday.midsommarafton", isBankHoliday: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25),
                systemRule(name: "holiday.alla_helgons_dag", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 7, ordinal: 1),
                systemRule(name: "holiday.mors_dag", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: -1),
                systemRule(name: "holiday.fars_dag", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2),
                systemRule(name: "holiday.virdagjamning", isBankHoliday: false, type: .astronomical, month: 3),
                systemRule(name: "holiday.sommarsolstand", isBankHoliday: false, type: .astronomical, month: 6),
                systemRule(name: "holiday.hostdagjamning", isBankHoliday: false, type: .astronomical, month: 9),
                systemRule(name: "holiday.vintersolstand", isBankHoliday: false, type: .astronomical, month: 12)
            ]
        case "US":
            return [
                systemRule(name: "New Year's Day", isBankHoliday: true, type: .fixed, month: 1, day: 1),
                systemRule(name: "Martin Luther King Jr. Day", isBankHoliday: true, type: .nthWeekday, month: 1, weekday: 2, ordinal: 3),
                systemRule(name: "Presidents' Day", isBankHoliday: true, type: .nthWeekday, month: 2, weekday: 2, ordinal: 3),
                systemRule(name: "Memorial Day", isBankHoliday: true, type: .nthWeekday, month: 5, weekday: 2, ordinal: -1),
                systemRule(name: "Juneteenth", isBankHoliday: true, type: .fixed, month: 6, day: 19),
                systemRule(name: "Independence Day", isBankHoliday: true, type: .fixed, month: 7, day: 4),
                systemRule(name: "Labor Day", isBankHoliday: true, type: .nthWeekday, month: 9, weekday: 2, ordinal: 1),
                systemRule(name: "Columbus Day", isBankHoliday: true, type: .nthWeekday, month: 10, weekday: 2, ordinal: 2),
                systemRule(name: "Veterans Day", isBankHoliday: true, type: .fixed, month: 11, day: 11),
                systemRule(name: "Thanksgiving Day", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 5, ordinal: 4),
                systemRule(name: "Christmas Day", isBankHoliday: true, type: .fixed, month: 12, day: 25),
                systemRule(name: "Valentine's Day", isBankHoliday: false, type: .fixed, month: 2, day: 14),
                systemRule(name: "St. Patrick's Day", isBankHoliday: false, type: .fixed, month: 3, day: 17),
                systemRule(name: "Mother's Day", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2),
                systemRule(name: "Father's Day", isBankHoliday: false, type: .nthWeekday, month: 6, weekday: 1, ordinal: 3),
                systemRule(name: "Halloween", isBankHoliday: false, type: .fixed, month: 10, day: 31)
            ]
        case "VN":
            return [
                // Public Holidays
                systemRule(name: "Tết Dương lịch", isBankHoliday: true, type: .fixed, month: 1, day: 1),
                systemRule(name: "Tết Nguyên Đán", isBankHoliday: true, type: .lunar, month: 1, day: 1),
                systemRule(name: "Giỗ Tổ Hùng Vương", isBankHoliday: true, type: .lunar, month: 3, day: 10),
                systemRule(name: "Ngày Thống nhất", isBankHoliday: true, type: .fixed, month: 4, day: 30),
                systemRule(name: "Quốc tế Lao động", isBankHoliday: true, type: .fixed, month: 5, day: 1),
                systemRule(name: "Quốc khánh", isBankHoliday: true, type: .fixed, month: 9, day: 2),
                // Observances
                systemRule(name: "Tết Trung Thu", isBankHoliday: false, type: .lunar, month: 8, day: 15),
                systemRule(name: "Ngày Quốc tế Phụ nữ", isBankHoliday: false, type: .fixed, month: 3, day: 8),
                systemRule(name: "Ngày Phụ nữ Việt Nam", isBankHoliday: false, type: .fixed, month: 10, day: 20),
                systemRule(name: "Ngày Nhà giáo Việt Nam", isBankHoliday: false, type: .fixed, month: 11, day: 20),
                systemRule(name: "Tết Đoan Ngọ", isBankHoliday: false, type: .lunar, month: 5, day: 5),
                systemRule(name: "Lễ Vu Lan", isBankHoliday: false, type: .lunar, month: 7, day: 15),
                systemRule(name: "Ngày Valentine", isBankHoliday: false, type: .fixed, month: 2, day: 14)
            ]
        case "NO":
            return [
                // Bank Holidays
                systemRule(name: "Nyttårsdag", isBankHoliday: true, type: .fixed, month: 1, day: 1),
                systemRule(name: "Skjærtorsdag", isBankHoliday: true, type: .easterRelative, daysOffset: -3),
                systemRule(name: "Langfredag", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
                systemRule(name: "Første påskedag", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
                systemRule(name: "Andre påskedag", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
                systemRule(name: "Arbeidernes dag", isBankHoliday: true, type: .fixed, month: 5, day: 1),
                systemRule(name: "Grunnlovsdagen", isBankHoliday: true, type: .fixed, month: 5, day: 17),
                systemRule(name: "Kristi himmelfartsdag", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
                systemRule(name: "Første pinsedag", isBankHoliday: true, type: .easterRelative, daysOffset: 49),
                systemRule(name: "Andre pinsedag", isBankHoliday: true, type: .easterRelative, daysOffset: 50),
                systemRule(name: "Første juledag", isBankHoliday: true, type: .fixed, month: 12, day: 25),
                systemRule(name: "Andre juledag", isBankHoliday: true, type: .fixed, month: 12, day: 26),
                // Observances
                systemRule(name: "Julaften", isBankHoliday: false, type: .fixed, month: 12, day: 24),
                systemRule(name: "Nyttårsaften", isBankHoliday: false, type: .fixed, month: 12, day: 31),
                systemRule(name: "Morsdag", isBankHoliday: false, type: .nthWeekday, month: 2, weekday: 1, ordinal: 2),
                systemRule(name: "Farsdag", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2)
            ]
        case "DK":
            return [
                // Bank Holidays
                systemRule(name: "Nytårsdag", isBankHoliday: true, type: .fixed, month: 1, day: 1),
                systemRule(name: "Skærtorsdag", isBankHoliday: true, type: .easterRelative, daysOffset: -3),
                systemRule(name: "Langfredag", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
                systemRule(name: "Påskedag", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
                systemRule(name: "2. Påskedag", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
                systemRule(name: "Kristi himmelfartsdag", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
                systemRule(name: "Pinsedag", isBankHoliday: true, type: .easterRelative, daysOffset: 49),
                systemRule(name: "2. Pinsedag", isBankHoliday: true, type: .easterRelative, daysOffset: 50),
                systemRule(name: "Grundlovsdag", isBankHoliday: true, type: .fixed, month: 6, day: 5),
                systemRule(name: "Juledag", isBankHoliday: true, type: .fixed, month: 12, day: 25),
                systemRule(name: "2. Juledag", isBankHoliday: true, type: .fixed, month: 12, day: 26),
                // Observances
                systemRule(name: "Juleaftensdag", isBankHoliday: false, type: .fixed, month: 12, day: 24),
                systemRule(name: "Nytårsaften", isBankHoliday: false, type: .fixed, month: 12, day: 31),
                systemRule(name: "Mors dag", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2),
                systemRule(name: "Valdemarsdag", isBankHoliday: false, type: .fixed, month: 6, day: 15)
            ]
        case "FI":
            return [
                // Bank Holidays
                systemRule(name: "Uudenvuodenpäivä", isBankHoliday: true, type: .fixed, month: 1, day: 1),
                systemRule(name: "Loppiainen", isBankHoliday: true, type: .fixed, month: 1, day: 6),
                systemRule(name: "Pitkäperjantai", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
                systemRule(name: "Pääsiäispäivä", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
                systemRule(name: "2. pääsiäispäivä", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
                systemRule(name: "Vappu", isBankHoliday: true, type: .fixed, month: 5, day: 1),
                systemRule(name: "Helatorstai", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
                systemRule(name: "Helluntaipäivä", isBankHoliday: true, type: .easterRelative, daysOffset: 49),
                systemRule(name: "Juhannuspäivä", isBankHoliday: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26),
                systemRule(name: "Pyhäinpäivä", isBankHoliday: true, type: .floating, month: 11, weekday: 7, dayRangeStart: 31, dayRangeEnd: 6),
                systemRule(name: "Itsenäisyyspäivä", isBankHoliday: true, type: .fixed, month: 12, day: 6),
                systemRule(name: "Joulupäivä", isBankHoliday: true, type: .fixed, month: 12, day: 25),
                systemRule(name: "Tapaninpäivä", isBankHoliday: true, type: .fixed, month: 12, day: 26),
                // Observances
                systemRule(name: "Jouluaatto", isBankHoliday: false, type: .fixed, month: 12, day: 24),
                systemRule(name: "Uudenvuodenaatto", isBankHoliday: false, type: .fixed, month: 12, day: 31),
                systemRule(name: "Juhannusaatto", isBankHoliday: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25),
                systemRule(name: "Äitienpäivä", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2),
                systemRule(name: "Isänpäivä", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2)
            ]
        case "IS":
            return [
                // Bank Holidays
                systemRule(name: "Nýársdagur", isBankHoliday: true, type: .fixed, month: 1, day: 1),
                systemRule(name: "Skírdagur", isBankHoliday: true, type: .easterRelative, daysOffset: -3),
                systemRule(name: "Föstudagurinn langi", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
                systemRule(name: "Páskadagur", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
                systemRule(name: "Annar í páskum", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
                systemRule(name: "Sumardagurinn fyrsti", isBankHoliday: true, type: .floating, month: 4, weekday: 5, dayRangeStart: 19, dayRangeEnd: 25),
                systemRule(name: "Verkalýðsdagurinn", isBankHoliday: true, type: .fixed, month: 5, day: 1),
                systemRule(name: "Uppstigningardagur", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
                systemRule(name: "Hvítasunnudagur", isBankHoliday: true, type: .easterRelative, daysOffset: 49),
                systemRule(name: "Annar í hvítasunnu", isBankHoliday: true, type: .easterRelative, daysOffset: 50),
                systemRule(name: "Þjóðhátíðardagur", isBankHoliday: true, type: .fixed, month: 6, day: 17),
                systemRule(name: "Verslunarmannahelgi", isBankHoliday: true, type: .nthWeekday, month: 8, weekday: 2, ordinal: 1),
                systemRule(name: "Jóladagur", isBankHoliday: true, type: .fixed, month: 12, day: 25),
                systemRule(name: "Annar í jólum", isBankHoliday: true, type: .fixed, month: 12, day: 26),
                // Observances
                systemRule(name: "Aðfangadagur", isBankHoliday: false, type: .fixed, month: 12, day: 24),
                systemRule(name: "Gamlársdagur", isBankHoliday: false, type: .fixed, month: 12, day: 31),
                systemRule(name: "Dagur íslenskrar tungu", isBankHoliday: false, type: .fixed, month: 11, day: 16),
                systemRule(name: "Mæðradagurinn", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2),
                systemRule(name: "Feðradagurinn", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2)
            ]
        default:
            // For other regions, return empty - they will be seeded from the main seed function
            return []
        }
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
                            isBankHoliday: rule.isBankHoliday,
                            symbolName: symbolName,
                            iconColor: rule.iconColor,
                            notes: rule.notes,
                            isUserCreated: rule.userModifiedAt != nil
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
        if lhs.isBankHoliday != rhs.isBankHoliday { return lhs.isBankHoliday && !rhs.isBankHoliday }
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
        return rule.isBankHoliday ? "flag.fill" : "star"
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
    
    /// Seed the Database with Holiday Rules (The "DNA")
    /// All seeded rules are marked as system defaults with originalDefaultJSON for reset capability
    private func seedSwedishRules(context: ModelContext) {
        Log.d("Seeding holiday rules (non-destructive)...")

        migrateLegacySwedishRuleNames(context: context)

        // Helper to create system default rules
        func systemRule(
            name: String,
            region: String = "SE",
            isBankHoliday: Bool,
            type: HolidayRuleType,
            month: Int? = nil,
            day: Int? = nil,
            daysOffset: Int? = nil,
            weekday: Int? = nil,
            ordinal: Int? = nil,
            dayRangeStart: Int? = nil,
            dayRangeEnd: Int? = nil
        ) -> HolidayRule {
            HolidayRule(
                name: name,
                region: region,
                isBankHoliday: isBankHoliday,
                type: type,
                month: month,
                day: day,
                daysOffset: daysOffset,
                weekday: weekday,
                ordinal: ordinal,
                dayRangeStart: dayRangeStart,
                dayRangeEnd: dayRangeEnd,
                isSystemDefault: true,  // 情報デザイン: Mark as system default
                isEnabled: true
            )
        }

        let rules: [HolidayRule] = [
            // --- RÖDA DAGAR (Red Days - Official Public Holidays) ---
            systemRule(name: "holiday.nyarsdagen", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "holiday.trettondedag_jul", isBankHoliday: true, type: .fixed, month: 1, day: 6),
            systemRule(name: "holiday.forsta_maj", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "holiday.sveriges_nationaldag", isBankHoliday: true, type: .fixed, month: 6, day: 6),
            systemRule(name: "holiday.juldagen", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "holiday.annandag_jul", isBankHoliday: true, type: .fixed, month: 12, day: 26),

            // --- HELGDAGAR (Holidays - NOT Red Days) ---
            systemRule(name: "holiday.nyarsafton", isBankHoliday: false, type: .fixed, month: 12, day: 31),
            systemRule(name: "holiday.julafton", isBankHoliday: false, type: .fixed, month: 12, day: 24),

            // --- Observances (Not Red Days) ---
            systemRule(name: "holiday.alla_hjartans_dag", isBankHoliday: false, type: .fixed, month: 2, day: 14),
            systemRule(name: "holiday.internationella_kvinnodagen", isBankHoliday: false, type: .fixed, month: 3, day: 8),

            // --- Easter Relative ---
            systemRule(name: "holiday.langfredagen", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
            systemRule(name: "holiday.paskdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
            systemRule(name: "holiday.annandag_pask", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "holiday.kristi_himmelsfardsdag", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
            systemRule(name: "holiday.pingstdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 49),

            // --- RÖRLIGA RÖDA DAGAR (Floating Red Days) ---
            systemRule(name: "holiday.midsommardagen", isBankHoliday: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26),
            systemRule(name: "holiday.midsommarafton", isBankHoliday: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25),
            systemRule(name: "holiday.alla_helgons_dag", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 7, ordinal: 1),

            // --- Observances (Not Red Days) ---
            systemRule(name: "holiday.mors_dag", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: -1),
            systemRule(name: "holiday.fars_dag", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2),

            // --- Astronomical Events (Observances) ---
            systemRule(name: "holiday.virdagjamning", isBankHoliday: false, type: .astronomical, month: 3),
            systemRule(name: "holiday.sommarsolstand", isBankHoliday: false, type: .astronomical, month: 6),
            systemRule(name: "holiday.hostdagjamning", isBankHoliday: false, type: .astronomical, month: 9),
            systemRule(name: "holiday.vintersolstand", isBankHoliday: false, type: .astronomical, month: 12),

            // --- US Federal Holidays (11 total) ---
            systemRule(name: "New Year's Day", region: "US", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Martin Luther King Jr. Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 1, weekday: 2, ordinal: 3),
            systemRule(name: "Presidents' Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 2, weekday: 2, ordinal: 3),
            systemRule(name: "Memorial Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 5, weekday: 2, ordinal: -1),
            systemRule(name: "Juneteenth", region: "US", isBankHoliday: true, type: .fixed, month: 6, day: 19),
            systemRule(name: "Independence Day", region: "US", isBankHoliday: true, type: .fixed, month: 7, day: 4),
            systemRule(name: "Labor Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 9, weekday: 2, ordinal: 1),
            systemRule(name: "Columbus Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 10, weekday: 2, ordinal: 2),
            systemRule(name: "Veterans Day", region: "US", isBankHoliday: true, type: .fixed, month: 11, day: 11),
            systemRule(name: "Thanksgiving Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 5, ordinal: 4),
            systemRule(name: "Christmas Day", region: "US", isBankHoliday: true, type: .fixed, month: 12, day: 25),

            // --- US Observances ---
            systemRule(name: "Valentine's Day", region: "US", isBankHoliday: false, type: .fixed, month: 2, day: 14),
            systemRule(name: "St. Patrick's Day", region: "US", isBankHoliday: false, type: .fixed, month: 3, day: 17),
            systemRule(name: "Mother's Day", region: "US", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2),
            systemRule(name: "Father's Day", region: "US", isBankHoliday: false, type: .nthWeekday, month: 6, weekday: 1, ordinal: 3),
            systemRule(name: "Halloween", region: "US", isBankHoliday: false, type: .fixed, month: 10, day: 31),

            // --- Vietnamese Public Holidays ---
            systemRule(name: "Tết Dương lịch", region: "VN", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Tết Nguyên Đán", region: "VN", isBankHoliday: true, type: .lunar, month: 1, day: 1),
            systemRule(name: "Giỗ Tổ Hùng Vương", region: "VN", isBankHoliday: true, type: .lunar, month: 3, day: 10),
            systemRule(name: "Ngày Thống nhất", region: "VN", isBankHoliday: true, type: .fixed, month: 4, day: 30),
            systemRule(name: "Quốc tế Lao động", region: "VN", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "Quốc khánh", region: "VN", isBankHoliday: true, type: .fixed, month: 9, day: 2),

            // --- Vietnamese Observances ---
            systemRule(name: "Tết Trung Thu", region: "VN", isBankHoliday: false, type: .lunar, month: 8, day: 15),
            systemRule(name: "Ngày Quốc tế Phụ nữ", region: "VN", isBankHoliday: false, type: .fixed, month: 3, day: 8),
            systemRule(name: "Ngày Phụ nữ Việt Nam", region: "VN", isBankHoliday: false, type: .fixed, month: 10, day: 20),
            systemRule(name: "Ngày Nhà giáo Việt Nam", region: "VN", isBankHoliday: false, type: .fixed, month: 11, day: 20),
            systemRule(name: "Tết Đoan Ngọ", region: "VN", isBankHoliday: false, type: .lunar, month: 5, day: 5),
            systemRule(name: "Lễ Vu Lan", region: "VN", isBankHoliday: false, type: .lunar, month: 7, day: 15),
            systemRule(name: "Ngày Valentine", region: "VN", isBankHoliday: false, type: .fixed, month: 2, day: 14),

            // ===============================================================
            // GERMANY (DE) - Public Holidays (nationwide)
            // ===============================================================
            systemRule(name: "Neujahrstag", region: "DE", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Karfreitag", region: "DE", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
            systemRule(name: "Ostermontag", region: "DE", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Tag der Arbeit", region: "DE", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "Christi Himmelfahrt", region: "DE", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
            systemRule(name: "Pfingstmontag", region: "DE", isBankHoliday: true, type: .easterRelative, daysOffset: 50),
            systemRule(name: "Tag der Deutschen Einheit", region: "DE", isBankHoliday: true, type: .fixed, month: 10, day: 3),
            systemRule(name: "Weihnachtstag", region: "DE", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "Zweiter Weihnachtstag", region: "DE", isBankHoliday: true, type: .fixed, month: 12, day: 26),

            // ===============================================================
            // UNITED KINGDOM (GB) - Bank Holidays (England & Wales)
            // ===============================================================
            systemRule(name: "New Year's Day", region: "GB", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Good Friday", region: "GB", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
            systemRule(name: "Easter Monday", region: "GB", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Early May Bank Holiday", region: "GB", isBankHoliday: true, type: .nthWeekday, month: 5, weekday: 2, ordinal: 1),
            systemRule(name: "Spring Bank Holiday", region: "GB", isBankHoliday: true, type: .nthWeekday, month: 5, weekday: 2, ordinal: -1),
            systemRule(name: "Summer Bank Holiday", region: "GB", isBankHoliday: true, type: .nthWeekday, month: 8, weekday: 2, ordinal: -1),
            systemRule(name: "Christmas Day", region: "GB", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "Boxing Day", region: "GB", isBankHoliday: true, type: .fixed, month: 12, day: 26),

            // ===============================================================
            // FRANCE (FR) - Jours fériés
            // ===============================================================
            systemRule(name: "Jour de l'An", region: "FR", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Lundi de Pâques", region: "FR", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Fête du Travail", region: "FR", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "Victoire 1945", region: "FR", isBankHoliday: true, type: .fixed, month: 5, day: 8),
            systemRule(name: "Ascension", region: "FR", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
            systemRule(name: "Lundi de Pentecôte", region: "FR", isBankHoliday: true, type: .easterRelative, daysOffset: 50),
            systemRule(name: "Fête Nationale", region: "FR", isBankHoliday: true, type: .fixed, month: 7, day: 14),
            systemRule(name: "Assomption", region: "FR", isBankHoliday: true, type: .fixed, month: 8, day: 15),
            systemRule(name: "Toussaint", region: "FR", isBankHoliday: true, type: .fixed, month: 11, day: 1),
            systemRule(name: "Armistice", region: "FR", isBankHoliday: true, type: .fixed, month: 11, day: 11),
            systemRule(name: "Noël", region: "FR", isBankHoliday: true, type: .fixed, month: 12, day: 25),

            // ===============================================================
            // ITALY (IT) - Giorni festivi
            // ===============================================================
            systemRule(name: "Capodanno", region: "IT", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Epifania", region: "IT", isBankHoliday: true, type: .fixed, month: 1, day: 6),
            systemRule(name: "Lunedì dell'Angelo", region: "IT", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Festa della Liberazione", region: "IT", isBankHoliday: true, type: .fixed, month: 4, day: 25),
            systemRule(name: "Festa del Lavoro", region: "IT", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "Festa della Repubblica", region: "IT", isBankHoliday: true, type: .fixed, month: 6, day: 2),
            systemRule(name: "Ferragosto", region: "IT", isBankHoliday: true, type: .fixed, month: 8, day: 15),
            systemRule(name: "Tutti i Santi", region: "IT", isBankHoliday: true, type: .fixed, month: 11, day: 1),
            systemRule(name: "Immacolata Concezione", region: "IT", isBankHoliday: true, type: .fixed, month: 12, day: 8),
            systemRule(name: "Natale", region: "IT", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "Santo Stefano", region: "IT", isBankHoliday: true, type: .fixed, month: 12, day: 26),

            // ===============================================================
            // NETHERLANDS (NL) - Nationale feestdagen
            // ===============================================================
            systemRule(name: "Nieuwjaarsdag", region: "NL", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Tweede Paasdag", region: "NL", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Koningsdag", region: "NL", isBankHoliday: true, type: .fixed, month: 4, day: 27),
            systemRule(name: "Bevrijdingsdag", region: "NL", isBankHoliday: true, type: .fixed, month: 5, day: 5),
            systemRule(name: "Hemelvaartsdag", region: "NL", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
            systemRule(name: "Tweede Pinksterdag", region: "NL", isBankHoliday: true, type: .easterRelative, daysOffset: 50),
            systemRule(name: "Eerste Kerstdag", region: "NL", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "Tweede Kerstdag", region: "NL", isBankHoliday: true, type: .fixed, month: 12, day: 26),

            // ===============================================================
            // JAPAN (JP) - 国民の祝日 (National Holidays)
            // ===============================================================
            systemRule(name: "元日", region: "JP", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "成人の日", region: "JP", isBankHoliday: true, type: .nthWeekday, month: 1, weekday: 2, ordinal: 2),
            systemRule(name: "建国記念の日", region: "JP", isBankHoliday: true, type: .fixed, month: 2, day: 11),
            systemRule(name: "天皇誕生日", region: "JP", isBankHoliday: true, type: .fixed, month: 2, day: 23),
            systemRule(name: "春分の日", region: "JP", isBankHoliday: true, type: .astronomical, month: 3),
            systemRule(name: "昭和の日", region: "JP", isBankHoliday: true, type: .fixed, month: 4, day: 29),
            systemRule(name: "憲法記念日", region: "JP", isBankHoliday: true, type: .fixed, month: 5, day: 3),
            systemRule(name: "みどりの日", region: "JP", isBankHoliday: true, type: .fixed, month: 5, day: 4),
            systemRule(name: "こどもの日", region: "JP", isBankHoliday: true, type: .fixed, month: 5, day: 5),
            systemRule(name: "海の日", region: "JP", isBankHoliday: true, type: .nthWeekday, month: 7, weekday: 2, ordinal: 3),
            systemRule(name: "山の日", region: "JP", isBankHoliday: true, type: .fixed, month: 8, day: 11),
            systemRule(name: "敬老の日", region: "JP", isBankHoliday: true, type: .nthWeekday, month: 9, weekday: 2, ordinal: 3),
            systemRule(name: "秋分の日", region: "JP", isBankHoliday: true, type: .astronomical, month: 9),
            systemRule(name: "スポーツの日", region: "JP", isBankHoliday: true, type: .nthWeekday, month: 10, weekday: 2, ordinal: 2),
            systemRule(name: "文化の日", region: "JP", isBankHoliday: true, type: .fixed, month: 11, day: 3),
            systemRule(name: "勤労感謝の日", region: "JP", isBankHoliday: true, type: .fixed, month: 11, day: 23),
            // Japanese Observances (年中行事)
            systemRule(name: "節分", region: "JP", isBankHoliday: false, type: .fixed, month: 2, day: 3),
            systemRule(name: "バレンタインデー", region: "JP", isBankHoliday: false, type: .fixed, month: 2, day: 14),
            systemRule(name: "ひな祭り", region: "JP", isBankHoliday: false, type: .fixed, month: 3, day: 3),
            systemRule(name: "ホワイトデー", region: "JP", isBankHoliday: false, type: .fixed, month: 3, day: 14),
            systemRule(name: "七夕", region: "JP", isBankHoliday: false, type: .fixed, month: 7, day: 7),
            systemRule(name: "お盆", region: "JP", isBankHoliday: false, type: .fixed, month: 8, day: 15),
            systemRule(name: "七五三", region: "JP", isBankHoliday: false, type: .fixed, month: 11, day: 15),
            systemRule(name: "大晦日", region: "JP", isBankHoliday: false, type: .fixed, month: 12, day: 31),

            // ===============================================================
            // HONG KONG (HK) - Public Holidays
            // ===============================================================
            systemRule(name: "New Year's Day", region: "HK", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Lunar New Year", region: "HK", isBankHoliday: true, type: .lunar, month: 1, day: 1),
            systemRule(name: "Ching Ming Festival", region: "HK", isBankHoliday: true, type: .fixed, month: 4, day: 4),
            systemRule(name: "Good Friday", region: "HK", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
            systemRule(name: "Easter Monday", region: "HK", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Labour Day", region: "HK", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "Buddha's Birthday", region: "HK", isBankHoliday: true, type: .lunar, month: 4, day: 8),
            systemRule(name: "Tuen Ng Festival", region: "HK", isBankHoliday: true, type: .lunar, month: 5, day: 5),
            systemRule(name: "HKSAR Establishment Day", region: "HK", isBankHoliday: true, type: .fixed, month: 7, day: 1),
            systemRule(name: "Mid-Autumn Festival", region: "HK", isBankHoliday: true, type: .lunar, month: 8, day: 15),
            systemRule(name: "National Day", region: "HK", isBankHoliday: true, type: .fixed, month: 10, day: 1),
            systemRule(name: "Chung Yeung Festival", region: "HK", isBankHoliday: true, type: .lunar, month: 9, day: 9),
            systemRule(name: "Christmas Day", region: "HK", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "Boxing Day", region: "HK", isBankHoliday: true, type: .fixed, month: 12, day: 26),

            // ===============================================================
            // CHINA (CN) - 法定节假日 (Public Holidays)
            // ===============================================================
            systemRule(name: "元旦", region: "CN", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "春节", region: "CN", isBankHoliday: true, type: .lunar, month: 1, day: 1),
            systemRule(name: "清明节", region: "CN", isBankHoliday: true, type: .fixed, month: 4, day: 4),
            systemRule(name: "劳动节", region: "CN", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "端午节", region: "CN", isBankHoliday: true, type: .lunar, month: 5, day: 5),
            systemRule(name: "中秋节", region: "CN", isBankHoliday: true, type: .lunar, month: 8, day: 15),
            systemRule(name: "国庆节", region: "CN", isBankHoliday: true, type: .fixed, month: 10, day: 1),

            // ===============================================================
            // THAILAND (TH) - วันหยุดราชการ (Public Holidays)
            // ===============================================================
            systemRule(name: "วันขึ้นปีใหม่", region: "TH", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "วันมาฆบูชา", region: "TH", isBankHoliday: true, type: .lunar, month: 3, day: 15),
            systemRule(name: "วันจักรี", region: "TH", isBankHoliday: true, type: .fixed, month: 4, day: 6),
            systemRule(name: "วันสงกรานต์", region: "TH", isBankHoliday: true, type: .fixed, month: 4, day: 13),
            systemRule(name: "วันแรงงาน", region: "TH", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "วันฉัตรมงคล", region: "TH", isBankHoliday: true, type: .fixed, month: 5, day: 4),
            systemRule(name: "วันวิสาขบูชา", region: "TH", isBankHoliday: true, type: .lunar, month: 4, day: 15),
            systemRule(name: "วันเฉลิมพระชนมพรรษา", region: "TH", isBankHoliday: true, type: .fixed, month: 6, day: 3),
            systemRule(name: "วันอาสาฬหบูชา", region: "TH", isBankHoliday: true, type: .lunar, month: 6, day: 15),
            systemRule(name: "วันเข้าพรรษา", region: "TH", isBankHoliday: true, type: .lunar, month: 6, day: 16),
            systemRule(name: "วันเฉลิมพระชนมพรรษา ร.10", region: "TH", isBankHoliday: true, type: .fixed, month: 7, day: 28),
            systemRule(name: "วันแม่แห่งชาติ", region: "TH", isBankHoliday: true, type: .fixed, month: 8, day: 12),
            systemRule(name: "วันคล้ายวันสวรรคต ร.9", region: "TH", isBankHoliday: true, type: .fixed, month: 10, day: 13),
            systemRule(name: "วันปิยมหาราช", region: "TH", isBankHoliday: true, type: .fixed, month: 10, day: 23),
            systemRule(name: "วันพ่อแห่งชาติ", region: "TH", isBankHoliday: true, type: .fixed, month: 12, day: 5),
            systemRule(name: "วันรัฐธรรมนูญ", region: "TH", isBankHoliday: true, type: .fixed, month: 12, day: 10),
            systemRule(name: "วันสิ้นปี", region: "TH", isBankHoliday: true, type: .fixed, month: 12, day: 31),

            // ===============================================================
            // NORWAY (NO) - Offentlige helligdager (Public Holidays)
            // ===============================================================
            // Bank Holidays (Røde dager)
            systemRule(name: "Nyttårsdag", region: "NO", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Skjærtorsdag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: -3),
            systemRule(name: "Langfredag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
            systemRule(name: "Første påskedag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
            systemRule(name: "Andre påskedag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Arbeidernes dag", region: "NO", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "Grunnlovsdagen", region: "NO", isBankHoliday: true, type: .fixed, month: 5, day: 17),
            systemRule(name: "Kristi himmelfartsdag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
            systemRule(name: "Første pinsedag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 49),
            systemRule(name: "Andre pinsedag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 50),
            systemRule(name: "Første juledag", region: "NO", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "Andre juledag", region: "NO", isBankHoliday: true, type: .fixed, month: 12, day: 26),
            // Observances
            systemRule(name: "Julaften", region: "NO", isBankHoliday: false, type: .fixed, month: 12, day: 24),
            systemRule(name: "Nyttårsaften", region: "NO", isBankHoliday: false, type: .fixed, month: 12, day: 31),
            systemRule(name: "Morsdag", region: "NO", isBankHoliday: false, type: .nthWeekday, month: 2, weekday: 1, ordinal: 2),
            systemRule(name: "Farsdag", region: "NO", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2),

            // ===============================================================
            // DENMARK (DK) - Helligdage (Public Holidays)
            // ===============================================================
            // Bank Holidays
            systemRule(name: "Nytårsdag", region: "DK", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Skærtorsdag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: -3),
            systemRule(name: "Langfredag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
            systemRule(name: "Påskedag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
            systemRule(name: "2. Påskedag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Kristi himmelfartsdag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
            systemRule(name: "Pinsedag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 49),
            systemRule(name: "2. Pinsedag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 50),
            systemRule(name: "Grundlovsdag", region: "DK", isBankHoliday: true, type: .fixed, month: 6, day: 5),
            systemRule(name: "Juledag", region: "DK", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "2. Juledag", region: "DK", isBankHoliday: true, type: .fixed, month: 12, day: 26),
            // Observances
            systemRule(name: "Juleaftensdag", region: "DK", isBankHoliday: false, type: .fixed, month: 12, day: 24),
            systemRule(name: "Nytårsaften", region: "DK", isBankHoliday: false, type: .fixed, month: 12, day: 31),
            systemRule(name: "Mors dag", region: "DK", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2),
            systemRule(name: "Valdemarsdag", region: "DK", isBankHoliday: false, type: .fixed, month: 6, day: 15),

            // ===============================================================
            // FINLAND (FI) - Juhlapyhät (Public Holidays)
            // ===============================================================
            // Bank Holidays
            systemRule(name: "Uudenvuodenpäivä", region: "FI", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Loppiainen", region: "FI", isBankHoliday: true, type: .fixed, month: 1, day: 6),
            systemRule(name: "Pitkäperjantai", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
            systemRule(name: "Pääsiäispäivä", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
            systemRule(name: "2. pääsiäispäivä", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Vappu", region: "FI", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "Helatorstai", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
            systemRule(name: "Helluntaipäivä", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: 49),
            systemRule(name: "Juhannuspäivä", region: "FI", isBankHoliday: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26),
            systemRule(name: "Pyhäinpäivä", region: "FI", isBankHoliday: true, type: .floating, month: 11, weekday: 7, dayRangeStart: 31, dayRangeEnd: 6),
            systemRule(name: "Itsenäisyyspäivä", region: "FI", isBankHoliday: true, type: .fixed, month: 12, day: 6),
            systemRule(name: "Joulupäivä", region: "FI", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "Tapaninpäivä", region: "FI", isBankHoliday: true, type: .fixed, month: 12, day: 26),
            // Observances
            systemRule(name: "Jouluaatto", region: "FI", isBankHoliday: false, type: .fixed, month: 12, day: 24),
            systemRule(name: "Uudenvuodenaatto", region: "FI", isBankHoliday: false, type: .fixed, month: 12, day: 31),
            systemRule(name: "Juhannusaatto", region: "FI", isBankHoliday: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25),
            systemRule(name: "Äitienpäivä", region: "FI", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2),
            systemRule(name: "Isänpäivä", region: "FI", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2),

            // ===============================================================
            // ICELAND (IS) - Almennir frídagar (Public Holidays)
            // ===============================================================
            // Bank Holidays
            systemRule(name: "Nýársdagur", region: "IS", isBankHoliday: true, type: .fixed, month: 1, day: 1),
            systemRule(name: "Skírdagur", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: -3),
            systemRule(name: "Föstudagurinn langi", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
            systemRule(name: "Páskadagur", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
            systemRule(name: "Annar í páskum", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
            systemRule(name: "Sumardagurinn fyrsti", region: "IS", isBankHoliday: true, type: .floating, month: 4, weekday: 5, dayRangeStart: 19, dayRangeEnd: 25),
            systemRule(name: "Verkalýðsdagurinn", region: "IS", isBankHoliday: true, type: .fixed, month: 5, day: 1),
            systemRule(name: "Uppstigningardagur", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
            systemRule(name: "Hvítasunnudagur", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 49),
            systemRule(name: "Annar í hvítasunnu", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 50),
            systemRule(name: "Þjóðhátíðardagur", region: "IS", isBankHoliday: true, type: .fixed, month: 6, day: 17),
            systemRule(name: "Verslunarmannahelgi", region: "IS", isBankHoliday: true, type: .nthWeekday, month: 8, weekday: 2, ordinal: 1),
            systemRule(name: "Jóladagur", region: "IS", isBankHoliday: true, type: .fixed, month: 12, day: 25),
            systemRule(name: "Annar í jólum", region: "IS", isBankHoliday: true, type: .fixed, month: 12, day: 26),
            // Observances
            systemRule(name: "Aðfangadagur", region: "IS", isBankHoliday: false, type: .fixed, month: 12, day: 24),
            systemRule(name: "Gamlársdagur", region: "IS", isBankHoliday: false, type: .fixed, month: 12, day: 31),
            systemRule(name: "Dagur íslenskrar tungu", region: "IS", isBankHoliday: false, type: .fixed, month: 11, day: 16),
            systemRule(name: "Mæðradagurinn", region: "IS", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2),
            systemRule(name: "Feðradagurinn", region: "IS", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2)
        ]

        do {
            let existing = try context.fetch(FetchDescriptor<HolidayRule>())
            let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
            var insertedCount = 0
            var updatedCount = 0
            var insertedByRegion: [String: Int] = [:]

            for rule in rules {
                if let existingRule = existingById[rule.id] {
                    // Skip user-modified rules
                    guard existingRule.userModifiedAt == nil else { continue }

                    var didChange = false

                    // Update system default flag if not set
                    if !existingRule.isSystemDefault {
                        existingRule.isSystemDefault = true
                        existingRule.originalDefaultJSON = rule.toJSON()
                        didChange = true
                    }

                    if existingRule.isBankHoliday != rule.isBankHoliday {
                        existingRule.isBankHoliday = rule.isBankHoliday
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
                    let region = rule.region.isEmpty ? "SE" : rule.region
                    insertedByRegion[region, default: 0] += 1
                }
            }

            if insertedCount > 0 || updatedCount > 0 {
                try context.save()
                Log.i("Seeded \(insertedCount) holiday rules (updated: \(updatedCount)).")

                // 情報デザイン: Log seeding to changelog per region
                for (region, count) in insertedByRegion {
                    HolidayChangeLogService.shared.logDefaultsLoaded(
                        region: region,
                        rulesCount: count,
                        source: .system,
                        context: context
                    )
                }
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
