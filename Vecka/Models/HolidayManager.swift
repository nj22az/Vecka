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
    let localName: String?   // Native language name (e.g., "Julafton" for Christmas Eve)
    let isUserCreated: Bool  // True if userModifiedAt != nil
}

extension HolidayCacheItem {
    var displayTitle: String {
        let trimmedOverride = (titleOverride ?? "").trimmed
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

    /// Thread-safe static access to holiday cache (avoids MainActor isolation)
    /// Use this from non-isolated contexts like CalendarDay computed properties
    nonisolated static var cache: [Date: [HolidayCacheItem]] {
        cacheStorage.cache
    }

    /// Thread-safe instance access to the holiday cache (legacy, prefer static cache)
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
            dayRangeEnd: Int? = nil,
            titleOverride: String? = nil,
            localName: String? = nil,
            notes: String? = nil
        ) -> HolidayRule {
            HolidayRule(
                name: name,
                region: region,
                isBankHoliday: isBankHoliday,
                titleOverride: titleOverride,
                notes: notes,
                localName: localName,
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
                systemRule(name: "holiday.nyarsdagen", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nyårsdagen", notes: "The first day of the year. Celebrated with fireworks and festivities at midnight."),
                systemRule(name: "holiday.trettondedag_jul", isBankHoliday: true, type: .fixed, month: 1, day: 6, titleOverride: "Epiphany", localName: "Trettondedag jul", notes: "Marks the end of the Christmas season. Traditionally when the Three Wise Men visited the infant Jesus."),
                systemRule(name: "holiday.forsta_maj", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "May Day", localName: "Första maj", notes: "International Workers' Day. Marked by political rallies and demonstrations across Sweden."),
                systemRule(name: "holiday.sveriges_nationaldag", isBankHoliday: true, type: .fixed, month: 6, day: 6, titleOverride: "National Day of Sweden", localName: "Sveriges nationaldag", notes: "Commemorates the election of King Gustav Vasa in 1523. Celebrated with flag ceremonies and citizenship events."),
                systemRule(name: "holiday.juldagen", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Juldagen", notes: "The main Christmas celebration. Swedish traditions include the julbord feast and watching Donald Duck on TV."),
                systemRule(name: "holiday.annandag_jul", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Annandag jul", notes: "The day after Christmas. A relaxed day for visiting family and friends."),
                systemRule(name: "holiday.nyarsafton", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Nyårsafton", notes: "The last day of the year. Celebrated with fireworks, champagne toasts, and watching the clock strike midnight."),
                systemRule(name: "holiday.julafton", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Julafton", notes: "The main day of Christmas celebration in Sweden. Families gather for julbord, gift-giving, and watching Kalle Anka (Donald Duck)."),
                systemRule(name: "holiday.alla_hjartans_dag", isBankHoliday: false, type: .fixed, month: 2, day: 14, titleOverride: "Valentine's Day", localName: "Alla hjärtans dag", notes: "A day to celebrate romantic love. Couples exchange gifts, flowers, and cards."),
                systemRule(name: "holiday.internationella_kvinnodagen", isBankHoliday: false, type: .fixed, month: 3, day: 8, titleOverride: "International Women's Day", localName: "Internationella kvinnodagen", notes: "A global day celebrating women's achievements and advocating for gender equality."),
                systemRule(name: "holiday.langfredagen", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Långfredagen", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day of reflection in the Christian calendar."),
                systemRule(name: "holiday.paskdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Påskdagen", notes: "Celebrates the resurrection of Jesus Christ. Swedish traditions include Easter eggs and påskkärringar (Easter witches)."),
                systemRule(name: "holiday.annandag_pask", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Annandag påsk", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
                systemRule(name: "holiday.kristi_himmelsfardsdag", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Kristi himmelsfärdsdag", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter. Often used as a long weekend."),
                systemRule(name: "holiday.pingstdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Pingstdagen", notes: "Celebrates the descent of the Holy Spirit. Falls 49 days after Easter and marks the beginning of summer."),
                systemRule(name: "holiday.midsommardagen", isBankHoliday: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26, titleOverride: "Midsummer Day", localName: "Midsommardagen", notes: "One of Sweden's most beloved holidays. Celebrated with maypole dancing, flower wreaths, and herring feasts."),
                systemRule(name: "holiday.midsommarafton", isBankHoliday: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25, titleOverride: "Midsummer Eve", localName: "Midsommarafton", notes: "The main celebration day of Midsummer. Swedes raise the maypole, dance, and feast on pickled herring and strawberries."),
                systemRule(name: "holiday.alla_helgons_dag", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 7, ordinal: 1, titleOverride: "All Saints' Day", localName: "Alla helgons dag", notes: "A day to honor the deceased. Swedes visit cemeteries and light candles on the graves of loved ones."),
                systemRule(name: "holiday.mors_dag", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: -1, titleOverride: "Mother's Day", localName: "Mors dag", notes: "A day to honor mothers and motherhood. Celebrated with flowers, gifts, and family gatherings."),
                systemRule(name: "holiday.fars_dag", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2, titleOverride: "Father's Day", localName: "Fars dag", notes: "A day to honor fathers and fatherhood. Celebrated with gifts and quality family time."),
                systemRule(name: "holiday.virdagjamning", isBankHoliday: false, type: .astronomical, month: 3, titleOverride: "Vernal Equinox", localName: "Vårdagjämning", notes: "The spring equinox when day and night are equal length. Marks the astronomical start of spring."),
                systemRule(name: "holiday.sommarsolstand", isBankHoliday: false, type: .astronomical, month: 6, titleOverride: "Summer Solstice", localName: "Sommarsolstånd", notes: "The longest day of the year. In northern Sweden, the sun barely sets during this period."),
                systemRule(name: "holiday.hostdagjamning", isBankHoliday: false, type: .astronomical, month: 9, titleOverride: "Autumnal Equinox", localName: "Höstdagjämning", notes: "The autumn equinox when day and night are equal length. Marks the astronomical start of autumn."),
                systemRule(name: "holiday.vintersolstand", isBankHoliday: false, type: .astronomical, month: 12, titleOverride: "Winter Solstice", localName: "Vintersolstånd", notes: "The shortest day of the year. In northern Sweden, the sun barely rises during this period.")
            ]
        case "US":
            return [
                systemRule(name: "New Year's Day", isBankHoliday: true, type: .fixed, month: 1, day: 1, notes: "The first day of the year. Celebrated with parties, fireworks, and the ball drop in Times Square."),
                systemRule(name: "Martin Luther King Jr. Day", isBankHoliday: true, type: .nthWeekday, month: 1, weekday: 2, ordinal: 3, notes: "Honors the civil rights leader Dr. Martin Luther King Jr. A day of community service and reflection on equality."),
                systemRule(name: "Presidents' Day", isBankHoliday: true, type: .nthWeekday, month: 2, weekday: 2, ordinal: 3, notes: "Honors all U.S. presidents, originally celebrating George Washington's birthday."),
                systemRule(name: "Memorial Day", isBankHoliday: true, type: .nthWeekday, month: 5, weekday: 2, ordinal: -1, notes: "Honors military personnel who died in service. Marks the unofficial start of summer with barbecues and parades."),
                systemRule(name: "Juneteenth", isBankHoliday: true, type: .fixed, month: 6, day: 19, notes: "Commemorates the end of slavery in the United States on June 19, 1865."),
                systemRule(name: "Independence Day", isBankHoliday: true, type: .fixed, month: 7, day: 4, notes: "Celebrates the Declaration of Independence in 1776. Marked by fireworks, barbecues, and patriotic ceremonies."),
                systemRule(name: "Labor Day", isBankHoliday: true, type: .nthWeekday, month: 9, weekday: 2, ordinal: 1, notes: "Honors the American labor movement. Marks the unofficial end of summer."),
                systemRule(name: "Columbus Day", isBankHoliday: true, type: .nthWeekday, month: 10, weekday: 2, ordinal: 2, notes: "Commemorates Christopher Columbus's arrival in the Americas in 1492. Increasingly observed as Indigenous Peoples' Day."),
                systemRule(name: "Veterans Day", isBankHoliday: true, type: .fixed, month: 11, day: 11, notes: "Honors all who have served in the U.S. Armed Forces. Marked by ceremonies, parades, and moments of silence."),
                systemRule(name: "Thanksgiving Day", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 5, ordinal: 4, notes: "A day of giving thanks with family. Celebrated with a large turkey dinner, parades, and football."),
                systemRule(name: "Christmas Day", isBankHoliday: true, type: .fixed, month: 12, day: 25, notes: "Celebrates the birth of Jesus Christ. Marked by gift-giving, decorating trees, and family gatherings."),
                systemRule(name: "Valentine's Day", isBankHoliday: false, type: .fixed, month: 2, day: 14, notes: "A day to celebrate romantic love. Couples exchange cards, chocolates, and flowers."),
                systemRule(name: "St. Patrick's Day", isBankHoliday: false, type: .fixed, month: 3, day: 17, notes: "Celebrates Irish culture and heritage. Known for wearing green, parades, and festive gatherings."),
                systemRule(name: "Mother's Day", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2, notes: "A day to honor mothers and motherhood. Celebrated with flowers, cards, and family meals."),
                systemRule(name: "Father's Day", isBankHoliday: false, type: .nthWeekday, month: 6, weekday: 1, ordinal: 3, notes: "A day to honor fathers and fatherhood. Celebrated with gifts and quality family time."),
                systemRule(name: "Halloween", isBankHoliday: false, type: .fixed, month: 10, day: 31, notes: "An evening of costumes, trick-or-treating, and spooky decorations. Rooted in ancient Celtic harvest festivals.")
            ]
        case "VN":
            return [
                // Public Holidays
                systemRule(name: "Tết Dương lịch", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Tết Dương lịch", notes: "The first day of the Gregorian calendar year. A one-day public holiday in Vietnam."),
                systemRule(name: "Tết Nguyên Đán", isBankHoliday: true, type: .lunar, month: 1, day: 1, titleOverride: "Lunar New Year (Tết)", localName: "Tết Nguyên Đán", notes: "Vietnam's most important holiday. Families reunite, visit temples, and exchange lì xì (lucky money) in red envelopes."),
                systemRule(name: "Giỗ Tổ Hùng Vương", isBankHoliday: true, type: .lunar, month: 3, day: 10, titleOverride: "Hùng Kings' Temple Festival", localName: "Giỗ Tổ Hùng Vương", notes: "Honours the legendary Hùng Kings, founders of the first Vietnamese state."),
                systemRule(name: "Ngày Thống nhất", isBankHoliday: true, type: .fixed, month: 4, day: 30, titleOverride: "Reunification Day", localName: "Ngày Thống nhất", notes: "Marks the fall of Saigon in 1975 and reunification of North and South Vietnam."),
                systemRule(name: "Quốc tế Lao động", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "International Labour Day", localName: "Quốc tế Lao động", notes: "International Workers' Day. Combined with Reunification Day for a long holiday weekend."),
                systemRule(name: "Quốc khánh", isBankHoliday: true, type: .fixed, month: 9, day: 2, titleOverride: "National Day", localName: "Quốc khánh", notes: "Celebrates Vietnamese independence declared by Hồ Chí Minh in 1945."),
                // Observances
                systemRule(name: "Tết Trung Thu", isBankHoliday: false, type: .lunar, month: 8, day: 15, titleOverride: "Mid-Autumn Festival", localName: "Tết Trung Thu", notes: "A children's festival with lantern processions, lion dances, and mooncakes under the full autumn moon."),
                systemRule(name: "Ngày Quốc tế Phụ nữ", isBankHoliday: false, type: .fixed, month: 3, day: 8, titleOverride: "International Women's Day", localName: "Ngày Quốc tế Phụ nữ", notes: "A major celebration in Vietnam. Women receive flowers, gifts, and special attention from family and colleagues."),
                systemRule(name: "Ngày Phụ nữ Việt Nam", isBankHoliday: false, type: .fixed, month: 10, day: 20, titleOverride: "Vietnamese Women's Day", localName: "Ngày Phụ nữ Việt Nam", notes: "Celebrates Vietnamese women's contributions. Commemorates the founding of the Vietnam Women's Union in 1930."),
                systemRule(name: "Ngày Nhà giáo Việt Nam", isBankHoliday: false, type: .fixed, month: 11, day: 20, titleOverride: "Vietnamese Teachers' Day", localName: "Ngày Nhà giáo Việt Nam", notes: "Honouring teachers is deeply important in Vietnamese culture. Students give flowers and gifts to their teachers."),
                systemRule(name: "Tết Đoan Ngọ", isBankHoliday: false, type: .lunar, month: 5, day: 5, titleOverride: "Mid-Year Festival", localName: "Tết Đoan Ngọ", notes: "A festival to eliminate parasites and disease. Vietnamese eat fermented sticky rice and seasonal fruits at dawn."),
                systemRule(name: "Lễ Vu Lan", isBankHoliday: false, type: .lunar, month: 7, day: 15, titleOverride: "Vu Lan Festival", localName: "Lễ Vu Lan", notes: "A Buddhist festival honouring parents and ancestors. Those with living mothers wear red roses; without, white roses."),
                systemRule(name: "Ngày Valentine", isBankHoliday: false, type: .fixed, month: 2, day: 14, titleOverride: "Valentine's Day", localName: "Ngày Valentine", notes: "A popular celebration of romantic love among young Vietnamese. Couples exchange flowers and gifts.")
            ]
        case "NO":
            return [
                // Bank Holidays
                systemRule(name: "Nyttårsdag", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nyttårsdag", notes: "The first day of the year. Norwegians celebrate with fireworks and festive gatherings."),
                systemRule(name: "Skjærtorsdag", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Skjærtorsdag", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
                systemRule(name: "Langfredag", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Langfredag", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day often spent in quiet reflection."),
                systemRule(name: "Første påskedag", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Første påskedag", notes: "Celebrates the resurrection of Jesus Christ. Norwegians enjoy Easter eggs, skiing trips, and crime novels."),
                systemRule(name: "Andre påskedag", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Andre påskedag", notes: "The day after Easter Sunday. The final day of the traditional Norwegian Easter holiday week."),
                systemRule(name: "Arbeidernes dag", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "Labour Day", localName: "Arbeidernes dag", notes: "International Workers' Day. Marked by political rallies and parades across Norway."),
                systemRule(name: "Grunnlovsdagen", isBankHoliday: true, type: .fixed, month: 5, day: 17, titleOverride: "Constitution Day", localName: "Grunnlovsdagen", notes: "Norway's national day celebrating the 1814 constitution. Famous for children's parades, bunads, and ice cream."),
                systemRule(name: "Kristi himmelfartsdag", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Kristi himmelfartsdag", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
                systemRule(name: "Første pinsedag", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Første pinsedag", notes: "Celebrates the descent of the Holy Spirit. Falls 49 days after Easter."),
                systemRule(name: "Andre pinsedag", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Andre pinsedag", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
                systemRule(name: "Første juledag", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Første juledag", notes: "The main Christmas celebration. Norwegian traditions include ribbe (pork ribs) and walking around the Christmas tree."),
                systemRule(name: "Andre juledag", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Andre juledag", notes: "The day after Christmas. A relaxed day for visiting family and friends."),
                // Observances
                systemRule(name: "Julaften", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Julaften", notes: "The main day of Christmas celebration in Norway. Families gather for dinner, gifts, and walking around the tree."),
                systemRule(name: "Nyttårsaften", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Nyttårsaften", notes: "The last day of the year. Celebrated with fireworks, champagne, and watching the clock strike midnight."),
                systemRule(name: "Morsdag", isBankHoliday: false, type: .nthWeekday, month: 2, weekday: 1, ordinal: 2, titleOverride: "Mother's Day", localName: "Morsdag", notes: "A day to honour mothers. Celebrated with flowers, breakfast in bed, and family time."),
                systemRule(name: "Farsdag", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2, titleOverride: "Father's Day", localName: "Farsdag", notes: "A day to honour fathers. Celebrated with gifts and quality family time.")
            ]
        case "DK":
            return [
                // Bank Holidays
                systemRule(name: "Nytårsdag", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nytårsdag", notes: "The first day of the year. Danes celebrate with the Queen's New Year speech and fireworks."),
                systemRule(name: "Skærtorsdag", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Skærtorsdag", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
                systemRule(name: "Langfredag", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Langfredag", notes: "Commemorates the crucifixion of Jesus Christ. A quiet day with special church services."),
                systemRule(name: "Påskedag", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Påskedag", notes: "Celebrates the resurrection of Jesus Christ. Danish traditions include Easter letters and painted eggs."),
                systemRule(name: "2. Påskedag", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "2. Påskedag", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
                systemRule(name: "Kristi himmelfartsdag", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Kristi himmelfartsdag", notes: "Commemorates the ascension of Jesus into heaven. Often enjoyed as a long weekend."),
                systemRule(name: "Pinsedag", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Pinsedag", notes: "Celebrates the descent of the Holy Spirit, 49 days after Easter."),
                systemRule(name: "2. Pinsedag", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "2. Pinsedag", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
                systemRule(name: "Grundlovsdag", isBankHoliday: true, type: .fixed, month: 6, day: 5, titleOverride: "Constitution Day", localName: "Grundlovsdag", notes: "Celebrates the signing of the Danish constitution in 1849. Marked by political speeches and outdoor events."),
                systemRule(name: "Juledag", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Juledag", notes: "The main Christmas celebration. Danish traditions include risalamande (rice pudding) and dancing around the tree."),
                systemRule(name: "2. Juledag", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "2. Juledag", notes: "The day after Christmas. A relaxed day for visiting family and friends."),
                // Observances
                systemRule(name: "Juleaftensdag", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Juleaftensdag", notes: "The main day of Christmas celebration in Denmark. Families gather for duck or goose dinner and dance around the tree."),
                systemRule(name: "Nytårsaften", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Nytårsaften", notes: "The last day of the year. Danes watch the Queen's speech, jump off chairs at midnight, and set off fireworks."),
                systemRule(name: "Mors dag", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2, titleOverride: "Mother's Day", localName: "Mors dag", notes: "A day to honour mothers. Celebrated with flowers, gifts, and family gatherings."),
                systemRule(name: "Valdemarsdag", isBankHoliday: false, type: .fixed, month: 6, day: 15, titleOverride: "Valdemar's Day", localName: "Valdemarsdag", notes: "Celebrates the Danish flag (Dannebrog), said to have fallen from the sky during battle in 1219.")
            ]
        case "FI":
            return [
                // Bank Holidays
                systemRule(name: "Uudenvuodenpäivä", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Uudenvuodenpäivä", notes: "The first day of the year. Finns celebrate with fireworks and the tradition of casting tin for fortune-telling."),
                systemRule(name: "Loppiainen", isBankHoliday: true, type: .fixed, month: 1, day: 6, titleOverride: "Epiphany", localName: "Loppiainen", notes: "Marks the visit of the Three Wise Men. The end of the Finnish Christmas season."),
                systemRule(name: "Pitkäperjantai", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Pitkäperjantai", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day with quiet reflection."),
                systemRule(name: "Pääsiäispäivä", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Pääsiäispäivä", notes: "Celebrates the resurrection of Jesus Christ. Finnish children dress as Easter witches with willow branches."),
                systemRule(name: "2. pääsiäispäivä", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "2. pääsiäispäivä", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
                systemRule(name: "Vappu", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "May Day", localName: "Vappu", notes: "Finland's carnival-like spring celebration. Students wear white caps and everyone enjoys sima (mead) and tippaleipä."),
                systemRule(name: "Helatorstai", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Helatorstai", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
                systemRule(name: "Helluntaipäivä", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Helluntaipäivä", notes: "Celebrates the descent of the Holy Spirit. Falls 49 days after Easter."),
                systemRule(name: "Juhannuspäivä", isBankHoliday: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26, titleOverride: "Midsummer Day", localName: "Juhannuspäivä", notes: "One of Finland's most important holidays. Celebrated at summer cottages with bonfires, sauna, and the midnight sun."),
                systemRule(name: "Pyhäinpäivä", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 7, ordinal: 1, titleOverride: "All Saints' Day", localName: "Pyhäinpäivä", notes: "A day to honour the deceased. Finns visit cemeteries and light candles on graves."),
                systemRule(name: "Itsenäisyyspäivä", isBankHoliday: true, type: .fixed, month: 12, day: 6, titleOverride: "Independence Day", localName: "Itsenäisyyspäivä", notes: "Celebrates Finland's independence from Russia in 1917. Marked by candles in windows and the Presidential Ball."),
                systemRule(name: "Joulupäivä", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Joulupäivä", notes: "The main Christmas celebration. Finnish traditions include Christmas sauna and visiting Santa Claus in Rovaniemi."),
                systemRule(name: "Tapaninpäivä", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "St. Stephen's Day", localName: "Tapaninpäivä", notes: "The day after Christmas, named after Saint Stephen. A day for visiting friends and outdoor activities."),
                // Observances
                systemRule(name: "Jouluaatto", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Jouluaatto", notes: "The main day of Christmas celebration in Finland. Families enjoy Christmas sauna, ham dinner, and gift-giving."),
                systemRule(name: "Uudenvuodenaatto", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Uudenvuodenaatto", notes: "The last day of the year. Finns celebrate with fireworks and the tradition of molten tin fortune-telling."),
                systemRule(name: "Juhannusaatto", isBankHoliday: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25, titleOverride: "Midsummer Eve", localName: "Juhannusaatto", notes: "The eve of Midsummer. Finns head to summer cottages for bonfires, sauna, and swimming."),
                systemRule(name: "Äitienpäivä", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2, titleOverride: "Mother's Day", localName: "Äitienpäivä", notes: "A day to honour mothers. Celebrated with flowers, especially a white rose, and family meals."),
                systemRule(name: "Isänpäivä", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2, titleOverride: "Father's Day", localName: "Isänpäivä", notes: "A day to honour fathers. Celebrated with gifts and quality family time.")
            ]
        case "IS":
            return [
                // Bank Holidays
                systemRule(name: "Nýársdagur", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nýársdagur", notes: "The first day of the year. Icelanders celebrate with bonfires, fireworks, and community gatherings."),
                systemRule(name: "Skírdagur", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Skírdagur", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
                systemRule(name: "Föstudagurinn langi", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Föstudagurinn langi", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day of quiet reflection."),
                systemRule(name: "Páskadagur", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Páskadagur", notes: "Celebrates the resurrection of Jesus Christ. Icelanders exchange chocolate eggs with proverbs inside."),
                systemRule(name: "Annar í páskum", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Annar í páskum", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
                systemRule(name: "Sumardagurinn fyrsti", isBankHoliday: true, type: .floating, month: 4, weekday: 5, dayRangeStart: 19, dayRangeEnd: 25, titleOverride: "First Day of Summer", localName: "Sumardagurinn fyrsti", notes: "Celebrates the arrival of summer in the old Icelandic calendar. A uniquely Icelandic holiday."),
                systemRule(name: "Verkalýðsdagurinn", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "Labour Day", localName: "Verkalýðsdagurinn", notes: "International Workers' Day. Marked by union rallies and celebrations across Iceland."),
                systemRule(name: "Uppstigningardagur", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Uppstigningardagur", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
                systemRule(name: "Hvítasunnudagur", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Hvítasunnudagur", notes: "Celebrates the descent of the Holy Spirit, 49 days after Easter."),
                systemRule(name: "Annar í hvítasunnu", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Annar í hvítasunnu", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
                systemRule(name: "Þjóðhátíðardagur", isBankHoliday: true, type: .fixed, month: 6, day: 17, titleOverride: "Icelandic National Day", localName: "Þjóðhátíðardagur", notes: "Celebrates Iceland's independence from Denmark in 1944. Marked by parades, music, and the Lady of the Mountain."),
                systemRule(name: "Verslunarmannahelgi", isBankHoliday: true, type: .nthWeekday, month: 8, weekday: 2, ordinal: 1, titleOverride: "Commerce Day", localName: "Verslunarmannahelgi", notes: "A long weekend holiday. Icelanders celebrate with outdoor festivals and camping."),
                systemRule(name: "Jóladagur", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Jóladagur", notes: "The main Christmas celebration. Icelandic traditions include the 13 Yule Lads who visit children before Christmas."),
                systemRule(name: "Annar í jólum", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Annar í jólum", notes: "The day after Christmas. A relaxed day for visiting family and friends."),
                // Observances
                systemRule(name: "Aðfangadagur", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Aðfangadagur", notes: "The main day of Christmas celebration in Iceland. Gifts are exchanged at 6 PM and families enjoy smoked lamb."),
                systemRule(name: "Gamlársdagur", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Gamlársdagur", notes: "The last day of the year. Iceland's spectacular fireworks display is funded by the national rescue service."),
                systemRule(name: "Dagur íslenskrar tungu", isBankHoliday: false, type: .fixed, month: 11, day: 16, titleOverride: "Icelandic Language Day", localName: "Dagur íslenskrar tungu", notes: "Celebrates the Icelandic language on the birthday of poet Jónas Hallgrímsson."),
                systemRule(name: "Mæðradagurinn", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2, titleOverride: "Mother's Day", localName: "Mæðradagurinn", notes: "A day to honour mothers. Celebrated with flowers, gifts, and family gatherings."),
                systemRule(name: "Feðradagurinn", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2, titleOverride: "Father's Day", localName: "Feðradagurinn", notes: "A day to honour fathers. Celebrated with gifts and quality family time.")
            ]
        case "GL":
            return [
                // Bank Holidays - Greenland (Kalaallit Nunaat)
                systemRule(name: "Ukiortaaq", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Ukiortaaq", notes: "The first day of the year. Greenlanders celebrate with fireworks and community gatherings."),
                systemRule(name: "Sisamanngorneq Illernartoq", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Sisamanngorneq Illernartoq", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
                systemRule(name: "Tallimanngorneq Illernartoq", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Tallimanngorneq Illernartoq", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day of quiet reflection."),
                systemRule(name: "Poorskip ullua", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Poorskip ullua", notes: "Celebrates the resurrection of Jesus Christ. Families gather for traditional meals."),
                systemRule(name: "Poorskip aappaa", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Poorskip aappaa", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
                systemRule(name: "Qilalugaq", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Qilalugaq", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
                systemRule(name: "Pinikkoq", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Pinikkoq", notes: "Celebrates the descent of the Holy Spirit, 49 days after Easter."),
                systemRule(name: "Pinikkoq aappaa", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Pinikkoq aappaa", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
                systemRule(name: "Ullortuneq", isBankHoliday: true, type: .fixed, month: 6, day: 21, titleOverride: "National Day", localName: "Ullortuneq", notes: "Greenland's national day on the summer solstice. Celebrated with traditional Inuit music, food, and cultural events."),
                systemRule(name: "Juulli ullua", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Juulli ullua", notes: "The main Christmas celebration. Greenlandic traditions blend Danish customs with Inuit culture."),
                systemRule(name: "Juulli aappaa", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Juulli aappaa", notes: "The day after Christmas. A relaxed day for visiting family and community feasts."),
                // Observances
                systemRule(name: "Juulli siullia", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Juulli siullia", notes: "The main day of Christmas celebration in Greenland. Families gather for traditional meals and gift-giving."),
                systemRule(name: "Ukiortaami siullia", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Ukiortaami siullia", notes: "The last day of the year. Celebrated with fireworks visible across the arctic landscape.")
            ]
        case "FO":
            return [
                // Bank Holidays - Faroe Islands (Føroyar)
                systemRule(name: "Nýggjársdagur", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nýggjársdagur", notes: "The first day of the year. Faroese celebrate with fireworks and festive gatherings."),
                systemRule(name: "Skírhósdagur", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Skírhósdagur", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
                systemRule(name: "Langifríggjadagur", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Langifríggjadagur", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day of quiet reflection."),
                systemRule(name: "Páskadagur", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Páskadagur", notes: "Celebrates the resurrection of Jesus Christ. Faroese traditions include Easter eggs and family meals."),
                systemRule(name: "Annar páskadagur", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Annar páskadagur", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
                systemRule(name: "Flaggdagur", isBankHoliday: false, type: .fixed, month: 4, day: 25, titleOverride: "Flag Day", localName: "Flaggdagur", notes: "Celebrates the Faroese flag (Merkið), first used during World War II."),
                systemRule(name: "Kristi himmalsferðardagur", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Kristi himmalsferðardagur", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
                systemRule(name: "Hvítasunnudagur", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Hvítasunnudagur", notes: "Celebrates the descent of the Holy Spirit, 49 days after Easter."),
                systemRule(name: "Annar hvítasunnudagur", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Annar hvítasunnudagur", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
                systemRule(name: "Ólavsøkuaftan", isBankHoliday: false, type: .fixed, month: 7, day: 28, titleOverride: "St. Olav's Eve", localName: "Ólavsøkuaftan", notes: "The eve of the Faroese national holiday. Opening ceremonies and cultural events begin in Tórshavn."),
                systemRule(name: "Ólavsøkudagur", isBankHoliday: true, type: .fixed, month: 7, day: 29, titleOverride: "St. Olav's Day", localName: "Ólavsøkudagur", notes: "The Faroese national holiday. Celebrated with rowing races, chain dancing, and the opening of Parliament."),
                systemRule(name: "Jólafturansaftan", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Jólafturansaftan", notes: "The main day of Christmas celebration in the Faroe Islands. Families gather for traditional dinner and gift-giving."),
                systemRule(name: "Jóladagur", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Jóladagur", notes: "The main Christmas celebration. Faroese traditions include festive meals and family gatherings."),
                systemRule(name: "Annar jóladagur", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Annar jóladagur", notes: "The day after Christmas. A relaxed day for visiting family and friends."),
                systemRule(name: "Nýggjársaftan", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Nýggjársaftan", notes: "The last day of the year. Celebrated with fireworks and festive gatherings across the islands.")
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
        // 情報デザイン: Use expandedRegions to handle NORDIC → [SE, NO, DK, FI]
        var regions = selectedRegions.expandedRegions
        if regions.isEmpty {
            let legacy = UserDefaults.standard.string(forKey: "holidayRegion") ?? "NORDIC"
            let legacySelection = HolidayRegionSelection(regions: [legacy])
            regions = legacySelection.expandedRegions
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
                            localName: rule.localName,
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
        let trimmed = (rule.symbolName ?? "").trimmed
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
            dayRangeEnd: Int? = nil,
            titleOverride: String? = nil,
            localName: String? = nil,
            notes: String? = nil
        ) -> HolidayRule {
            HolidayRule(
                name: name,
                region: region,
                isBankHoliday: isBankHoliday,
                titleOverride: titleOverride,
                notes: notes,
                localName: localName,
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
            systemRule(name: "holiday.nyarsdagen", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nyårsdagen", notes: "The first day of the year. Celebrated with fireworks and festivities at midnight."),
            systemRule(name: "holiday.trettondedag_jul", isBankHoliday: true, type: .fixed, month: 1, day: 6, titleOverride: "Epiphany", localName: "Trettondedag jul", notes: "Marks the end of the Christmas season. Traditionally when the Three Wise Men visited the infant Jesus."),
            systemRule(name: "holiday.forsta_maj", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "May Day", localName: "Första maj", notes: "International Workers' Day. Marked by political rallies and demonstrations across Sweden."),
            systemRule(name: "holiday.sveriges_nationaldag", isBankHoliday: true, type: .fixed, month: 6, day: 6, titleOverride: "National Day of Sweden", localName: "Sveriges nationaldag", notes: "Commemorates the election of King Gustav Vasa in 1523. Celebrated with flag ceremonies and citizenship events."),
            systemRule(name: "holiday.juldagen", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Juldagen", notes: "The main Christmas celebration. Swedish traditions include the julbord feast and watching Donald Duck on TV."),
            systemRule(name: "holiday.annandag_jul", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Annandag jul", notes: "The day after Christmas. A relaxed day for visiting family and friends."),

            // --- HELGDAGAR (Holidays - NOT Red Days) ---
            systemRule(name: "holiday.nyarsafton", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Nyårsafton", notes: "The last day of the year. Celebrated with fireworks, champagne toasts, and watching the clock strike midnight."),
            systemRule(name: "holiday.julafton", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Julafton", notes: "The main day of Christmas celebration in Sweden. Families gather for julbord, gift-giving, and watching Kalle Anka (Donald Duck)."),

            // --- Observances (Not Red Days) ---
            systemRule(name: "holiday.alla_hjartans_dag", isBankHoliday: false, type: .fixed, month: 2, day: 14, titleOverride: "Valentine's Day", localName: "Alla hjärtans dag", notes: "A day to celebrate romantic love. Couples exchange gifts, flowers, and cards."),
            systemRule(name: "holiday.internationella_kvinnodagen", isBankHoliday: false, type: .fixed, month: 3, day: 8, titleOverride: "International Women's Day", localName: "Internationella kvinnodagen", notes: "A global day celebrating women's achievements and advocating for gender equality."),

            // --- Easter Relative ---
            systemRule(name: "holiday.langfredagen", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Långfredagen", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day of reflection in the Christian calendar."),
            systemRule(name: "holiday.paskdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Påskdagen", notes: "Celebrates the resurrection of Jesus Christ. Swedish traditions include Easter eggs and påskkärringar (Easter witches)."),
            systemRule(name: "holiday.annandag_pask", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Annandag påsk", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
            systemRule(name: "holiday.kristi_himmelsfardsdag", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Kristi himmelsfärdsdag", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter. Often used as a long weekend."),
            systemRule(name: "holiday.pingstdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Pingstdagen", notes: "Celebrates the descent of the Holy Spirit. Falls 49 days after Easter and marks the beginning of summer."),

            // --- RÖRLIGA RÖDA DAGAR (Floating Red Days) ---
            systemRule(name: "holiday.midsommardagen", isBankHoliday: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26, titleOverride: "Midsummer Day", localName: "Midsommardagen", notes: "One of Sweden's most beloved holidays. Celebrated with maypole dancing, flower wreaths, and herring feasts."),
            systemRule(name: "holiday.midsommarafton", isBankHoliday: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25, titleOverride: "Midsummer Eve", localName: "Midsommarafton", notes: "The main celebration day of Midsummer. Swedes raise the maypole, dance, and feast on pickled herring and strawberries."),
            systemRule(name: "holiday.alla_helgons_dag", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 7, ordinal: 1, titleOverride: "All Saints' Day", localName: "Alla helgons dag", notes: "A day to honor the deceased. Swedes visit cemeteries and light candles on the graves of loved ones."),

            // --- Observances (Not Red Days) ---
            systemRule(name: "holiday.mors_dag", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: -1, titleOverride: "Mother's Day", localName: "Mors dag", notes: "A day to honor mothers and motherhood. Celebrated with flowers, gifts, and family gatherings."),
            systemRule(name: "holiday.fars_dag", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2, titleOverride: "Father's Day", localName: "Fars dag", notes: "A day to honor fathers and fatherhood. Celebrated with gifts and quality family time."),

            // --- Astronomical Events (Observances) ---
            systemRule(name: "holiday.virdagjamning", isBankHoliday: false, type: .astronomical, month: 3, titleOverride: "Vernal Equinox", localName: "Vårdagjämning", notes: "The spring equinox when day and night are equal length. Marks the astronomical start of spring."),
            systemRule(name: "holiday.sommarsolstand", isBankHoliday: false, type: .astronomical, month: 6, titleOverride: "Summer Solstice", localName: "Sommarsolstånd", notes: "The longest day of the year. In northern Sweden, the sun barely sets during this period."),
            systemRule(name: "holiday.hostdagjamning", isBankHoliday: false, type: .astronomical, month: 9, titleOverride: "Autumnal Equinox", localName: "Höstdagjämning", notes: "The autumn equinox when day and night are equal length. Marks the astronomical start of autumn."),
            systemRule(name: "holiday.vintersolstand", isBankHoliday: false, type: .astronomical, month: 12, titleOverride: "Winter Solstice", localName: "Vintersolstånd", notes: "The shortest day of the year. In northern Sweden, the sun barely rises during this period."),

            // --- US Federal Holidays (11 total) ---
            systemRule(name: "New Year's Day", region: "US", isBankHoliday: true, type: .fixed, month: 1, day: 1, notes: "The first day of the year. Celebrated with parties, fireworks, and the ball drop in Times Square."),
            systemRule(name: "Martin Luther King Jr. Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 1, weekday: 2, ordinal: 3, notes: "Honors the civil rights leader Dr. Martin Luther King Jr. A day of community service and reflection on equality."),
            systemRule(name: "Presidents' Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 2, weekday: 2, ordinal: 3, notes: "Honors all U.S. presidents, originally celebrating George Washington's birthday. Often marked by sales and patriotic events."),
            systemRule(name: "Memorial Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 5, weekday: 2, ordinal: -1, notes: "Honors military personnel who died in service. Marks the unofficial start of summer with barbecues and parades."),
            systemRule(name: "Juneteenth", region: "US", isBankHoliday: true, type: .fixed, month: 6, day: 19, notes: "Commemorates the end of slavery in the United States on June 19, 1865. Celebrated with community gatherings and cultural events."),
            systemRule(name: "Independence Day", region: "US", isBankHoliday: true, type: .fixed, month: 7, day: 4, notes: "Celebrates the Declaration of Independence in 1776. Marked by fireworks, barbecues, and patriotic ceremonies."),
            systemRule(name: "Labor Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 9, weekday: 2, ordinal: 1, notes: "Honors the American labor movement. Marks the unofficial end of summer with barbecues and parades."),
            systemRule(name: "Columbus Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 10, weekday: 2, ordinal: 2, notes: "Commemorates Christopher Columbus's arrival in the Americas in 1492. Increasingly observed as Indigenous Peoples' Day."),
            systemRule(name: "Veterans Day", region: "US", isBankHoliday: true, type: .fixed, month: 11, day: 11, notes: "Honors all who have served in the U.S. Armed Forces. Marked by ceremonies, parades, and moments of silence."),
            systemRule(name: "Thanksgiving Day", region: "US", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 5, ordinal: 4, notes: "A day of giving thanks with family. Celebrated with a large turkey dinner, parades, and football."),
            systemRule(name: "Christmas Day", region: "US", isBankHoliday: true, type: .fixed, month: 12, day: 25, notes: "Celebrates the birth of Jesus Christ. Marked by gift-giving, decorating trees, and family gatherings."),

            // --- US Observances ---
            systemRule(name: "Valentine's Day", region: "US", isBankHoliday: false, type: .fixed, month: 2, day: 14, notes: "A day to celebrate romantic love. Couples exchange cards, chocolates, and flowers."),
            systemRule(name: "St. Patrick's Day", region: "US", isBankHoliday: false, type: .fixed, month: 3, day: 17, notes: "Celebrates Irish culture and heritage. Known for wearing green, parades, and festive gatherings."),
            systemRule(name: "Mother's Day", region: "US", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2, notes: "A day to honor mothers and motherhood. Celebrated with flowers, cards, and family meals."),
            systemRule(name: "Father's Day", region: "US", isBankHoliday: false, type: .nthWeekday, month: 6, weekday: 1, ordinal: 3, notes: "A day to honor fathers and fatherhood. Celebrated with gifts and quality family time."),
            systemRule(name: "Halloween", region: "US", isBankHoliday: false, type: .fixed, month: 10, day: 31, notes: "An evening of costumes, trick-or-treating, and spooky decorations. Rooted in ancient Celtic harvest festivals."),

            // --- Vietnamese Public Holidays ---
            systemRule(name: "Tết Dương lịch", region: "VN", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Tết Dương lịch", notes: "The first day of the Gregorian calendar year. A one-day public holiday in Vietnam."),
            systemRule(name: "Tết Nguyên Đán", region: "VN", isBankHoliday: true, type: .lunar, month: 1, day: 1, titleOverride: "Lunar New Year (Tết)", localName: "Tết Nguyên Đán", notes: "Vietnam's most important holiday. Families reunite, visit temples, and exchange lì xì (lucky money) in red envelopes."),
            systemRule(name: "Giỗ Tổ Hùng Vương", region: "VN", isBankHoliday: true, type: .lunar, month: 3, day: 10, titleOverride: "Hùng Kings' Temple Festival", localName: "Giỗ Tổ Hùng Vương", notes: "Honours the legendary Hùng Kings, founders of the first Vietnamese state. Pilgrimages to the temple on Nghĩa Lĩnh mountain."),
            systemRule(name: "Ngày Thống nhất", region: "VN", isBankHoliday: true, type: .fixed, month: 4, day: 30, titleOverride: "Reunification Day", localName: "Ngày Thống nhất", notes: "Marks the fall of Saigon in 1975 and reunification of North and South Vietnam."),
            systemRule(name: "Quốc tế Lao động", region: "VN", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "International Labour Day", localName: "Quốc tế Lao động", notes: "International Workers' Day. Combined with Reunification Day for a long holiday weekend."),
            systemRule(name: "Quốc khánh", region: "VN", isBankHoliday: true, type: .fixed, month: 9, day: 2, titleOverride: "National Day", localName: "Quốc khánh", notes: "Celebrates Vietnamese independence declared by Hồ Chí Minh in 1945. Marked by fireworks and patriotic events."),

            // --- Vietnamese Observances ---
            systemRule(name: "Tết Trung Thu", region: "VN", isBankHoliday: false, type: .lunar, month: 8, day: 15, titleOverride: "Mid-Autumn Festival", localName: "Tết Trung Thu", notes: "A children's festival with lantern processions, lion dances, and mooncakes under the full autumn moon."),
            systemRule(name: "Ngày Quốc tế Phụ nữ", region: "VN", isBankHoliday: false, type: .fixed, month: 3, day: 8, titleOverride: "International Women's Day", localName: "Ngày Quốc tế Phụ nữ", notes: "A major celebration in Vietnam. Women receive flowers, gifts, and special attention from family and colleagues."),
            systemRule(name: "Ngày Phụ nữ Việt Nam", region: "VN", isBankHoliday: false, type: .fixed, month: 10, day: 20, titleOverride: "Vietnamese Women's Day", localName: "Ngày Phụ nữ Việt Nam", notes: "Celebrates Vietnamese women's contributions. Commemorates the founding of the Vietnam Women's Union in 1930."),
            systemRule(name: "Ngày Nhà giáo Việt Nam", region: "VN", isBankHoliday: false, type: .fixed, month: 11, day: 20, titleOverride: "Vietnamese Teachers' Day", localName: "Ngày Nhà giáo Việt Nam", notes: "Honouring teachers is deeply important in Vietnamese culture. Students give flowers and gifts to their teachers."),
            systemRule(name: "Tết Đoan Ngọ", region: "VN", isBankHoliday: false, type: .lunar, month: 5, day: 5, titleOverride: "Mid-Year Festival", localName: "Tết Đoan Ngọ", notes: "A festival to eliminate parasites and disease. Vietnamese eat fermented sticky rice and seasonal fruits at dawn."),
            systemRule(name: "Lễ Vu Lan", region: "VN", isBankHoliday: false, type: .lunar, month: 7, day: 15, titleOverride: "Vu Lan Festival", localName: "Lễ Vu Lan", notes: "A Buddhist festival honouring parents and ancestors. Those with living mothers wear red roses; without, white roses."),
            systemRule(name: "Ngày Valentine", region: "VN", isBankHoliday: false, type: .fixed, month: 2, day: 14, titleOverride: "Valentine's Day", localName: "Ngày Valentine", notes: "A popular celebration of romantic love among young Vietnamese. Couples exchange flowers and gifts."),

            // ===============================================================
            // GERMANY (DE) - Public Holidays (nationwide)
            // ===============================================================
            systemRule(name: "Neujahrstag", region: "DE", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Neujahrstag", notes: "The first day of the year. Germans celebrate with fireworks, Bleigießen (lead pouring), and Sekt (sparkling wine)."),
            systemRule(name: "Karfreitag", region: "DE", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Karfreitag", notes: "Commemorates the crucifixion of Jesus Christ. One of the quietest holidays in Germany with strict public event restrictions."),
            systemRule(name: "Ostermontag", region: "DE", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Ostermontag", notes: "The day after Easter Sunday. Families enjoy Easter egg hunts and spring walks."),
            systemRule(name: "Tag der Arbeit", region: "DE", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "Labour Day", localName: "Tag der Arbeit", notes: "International Workers' Day. Marked by trade union rallies and also the traditional Tanz in den Mai celebrations."),
            systemRule(name: "Christi Himmelfahrt", region: "DE", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Christi Himmelfahrt", notes: "Commemorates the ascension of Jesus. Also celebrated as Father's Day (Vatertag) with group excursions and wagon tours."),
            systemRule(name: "Pfingstmontag", region: "DE", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Pfingstmontag", notes: "The day after Whit Sunday. A public holiday extending the Pentecost long weekend."),
            systemRule(name: "Tag der Deutschen Einheit", region: "DE", isBankHoliday: true, type: .fixed, month: 10, day: 3, titleOverride: "German Unity Day", localName: "Tag der Deutschen Einheit", notes: "Celebrates German reunification in 1990. The national day with official ceremonies and public festivals."),
            systemRule(name: "Weihnachtstag", region: "DE", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Weihnachtstag", notes: "The first day of Christmas. German traditions include Christstollen, decorated trees, and family gatherings."),
            systemRule(name: "Zweiter Weihnachtstag", region: "DE", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Zweiter Weihnachtstag", notes: "The second day of Christmas. A relaxed day for visiting extended family and friends."),

            // ===============================================================
            // UNITED KINGDOM (GB) - Bank Holidays (England & Wales)
            // ===============================================================
            systemRule(name: "New Year's Day", region: "GB", isBankHoliday: true, type: .fixed, month: 1, day: 1, notes: "The first day of the year. Celebrated with Hogmanay traditions in Scotland and fireworks over the Thames in London."),
            systemRule(name: "Good Friday", region: "GB", isBankHoliday: true, type: .easterRelative, daysOffset: -2, notes: "Commemorates the crucifixion of Jesus Christ. Traditionally marked by eating hot cross buns."),
            systemRule(name: "Easter Monday", region: "GB", isBankHoliday: true, type: .easterRelative, daysOffset: 1, notes: "The day after Easter Sunday. A bank holiday often spent with family, egg hunts, and spring activities."),
            systemRule(name: "Early May Bank Holiday", region: "GB", isBankHoliday: true, type: .nthWeekday, month: 5, weekday: 2, ordinal: 1, notes: "The first May bank holiday. Celebrates the arrival of spring with village fetes and Morris dancing."),
            systemRule(name: "Spring Bank Holiday", region: "GB", isBankHoliday: true, type: .nthWeekday, month: 5, weekday: 2, ordinal: -1, notes: "The late May bank holiday. A long weekend enjoyed with outdoor activities and travel."),
            systemRule(name: "Summer Bank Holiday", region: "GB", isBankHoliday: true, type: .nthWeekday, month: 8, weekday: 2, ordinal: -1, notes: "The last bank holiday of summer. Often the busiest travel weekend of the year in England and Wales."),
            systemRule(name: "Christmas Day", region: "GB", isBankHoliday: true, type: .fixed, month: 12, day: 25, notes: "Celebrates the birth of Jesus Christ. British traditions include Christmas crackers, the King's speech, and Christmas pudding."),
            systemRule(name: "Boxing Day", region: "GB", isBankHoliday: true, type: .fixed, month: 12, day: 26, notes: "The day after Christmas. Traditionally a day for giving to the less fortunate, now known for sales and sporting events."),

            // ===============================================================
            // FRANCE (FR) - Jours fériés
            // ===============================================================
            systemRule(name: "Jour de l'An", region: "FR", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Jour de l'An", notes: "The first day of the year. The French celebrate with réveillon dinners, champagne, and fireworks."),
            systemRule(name: "Lundi de Pâques", region: "FR", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Lundi de Pâques", notes: "The day after Easter Sunday. French children search for chocolate eggs said to be dropped by flying bells."),
            systemRule(name: "Fête du Travail", region: "FR", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "Labour Day", localName: "Fête du Travail", notes: "International Workers' Day. The French give lily of the valley (muguet) as a symbol of good luck."),
            systemRule(name: "Victoire 1945", region: "FR", isBankHoliday: true, type: .fixed, month: 5, day: 8, titleOverride: "Victory in Europe Day", localName: "Victoire 1945", notes: "Commemorates the Allied victory in World War II on May 8, 1945. Marked by ceremonies at war memorials."),
            systemRule(name: "Ascension", region: "FR", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Ascension", notes: "Commemorates the ascension of Jesus into heaven. Often combined with a bridge day for a long weekend."),
            systemRule(name: "Lundi de Pentecôte", region: "FR", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Lundi de Pentecôte", notes: "The day after Whit Sunday. Since 2004, some work this day as the Journée de Solidarité for elderly care funding."),
            systemRule(name: "Fête Nationale", region: "FR", isBankHoliday: true, type: .fixed, month: 7, day: 14, titleOverride: "Bastille Day", localName: "Fête Nationale", notes: "France's national day commemorating the storming of the Bastille in 1789. Celebrated with military parades, fireworks, and balls."),
            systemRule(name: "Assomption", region: "FR", isBankHoliday: true, type: .fixed, month: 8, day: 15, titleOverride: "Assumption of Mary", localName: "Assomption", notes: "Celebrates the assumption of the Virgin Mary into heaven. Religious processions and the peak of summer holidays."),
            systemRule(name: "Toussaint", region: "FR", isBankHoliday: true, type: .fixed, month: 11, day: 1, titleOverride: "All Saints' Day", localName: "Toussaint", notes: "Honors all saints and departed souls. The French visit cemeteries and place chrysanthemums on graves."),
            systemRule(name: "Armistice", region: "FR", isBankHoliday: true, type: .fixed, month: 11, day: 11, titleOverride: "Armistice Day", localName: "Armistice", notes: "Commemorates the end of World War I on November 11, 1918. Marked by ceremonies at the Arc de Triomphe."),
            systemRule(name: "Noël", region: "FR", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Noël", notes: "Celebrates the birth of Jesus Christ. French traditions include a réveillon feast with bûche de Noël (Yule log cake)."),

            // ===============================================================
            // ITALY (IT) - Giorni festivi
            // ===============================================================
            systemRule(name: "Capodanno", region: "IT", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Capodanno", notes: "The first day of the year. Italians celebrate with fireworks, lentils for good luck, and wearing red underwear."),
            systemRule(name: "Epifania", region: "IT", isBankHoliday: true, type: .fixed, month: 1, day: 6, titleOverride: "Epiphany", localName: "Epifania", notes: "Celebrates the visit of the Three Wise Men. Italian children receive gifts from La Befana, a gift-giving witch."),
            systemRule(name: "Lunedì dell'Angelo", region: "IT", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Lunedì dell'Angelo", notes: "Also called Pasquetta ('Little Easter'). Italians traditionally enjoy outdoor picnics with family and friends."),
            systemRule(name: "Festa della Liberazione", region: "IT", isBankHoliday: true, type: .fixed, month: 4, day: 25, titleOverride: "Liberation Day", localName: "Festa della Liberazione", notes: "Commemorates the liberation of Italy from Nazi occupation in 1945. Marked by parades and patriotic ceremonies."),
            systemRule(name: "Festa del Lavoro", region: "IT", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "Labour Day", localName: "Festa del Lavoro", notes: "International Workers' Day. Celebrated with a famous free concert in Rome's Piazza San Giovanni."),
            systemRule(name: "Festa della Repubblica", region: "IT", isBankHoliday: true, type: .fixed, month: 6, day: 2, titleOverride: "Republic Day", localName: "Festa della Repubblica", notes: "Italy's national day celebrating the 1946 referendum that established the Republic. Marked by a military parade in Rome."),
            systemRule(name: "Ferragosto", region: "IT", isBankHoliday: true, type: .fixed, month: 8, day: 15, titleOverride: "Assumption of Mary", localName: "Ferragosto", notes: "Celebrates the Assumption of Mary and marks the peak of Italian summer holidays. Cities empty as everyone heads to the coast."),
            systemRule(name: "Tutti i Santi", region: "IT", isBankHoliday: true, type: .fixed, month: 11, day: 1, titleOverride: "All Saints' Day", localName: "Tutti i Santi", notes: "Honors all saints. Italians visit cemeteries and place flowers on the graves of loved ones."),
            systemRule(name: "Immacolata Concezione", region: "IT", isBankHoliday: true, type: .fixed, month: 12, day: 8, titleOverride: "Immaculate Conception", localName: "Immacolata Concezione", notes: "Celebrates the Immaculate Conception of the Virgin Mary. Marks the traditional start of the Christmas season in Italy."),
            systemRule(name: "Natale", region: "IT", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Natale", notes: "Celebrates the birth of Jesus Christ. Italian traditions include presepe (nativity scenes) and a festive family feast."),
            systemRule(name: "Santo Stefano", region: "IT", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "St. Stephen's Day", localName: "Santo Stefano", notes: "Honours Saint Stephen, the first Christian martyr. A day for visiting family and enjoying leftover Christmas food."),

            // ===============================================================
            // NETHERLANDS (NL) - Nationale feestdagen
            // ===============================================================
            systemRule(name: "Nieuwjaarsdag", region: "NL", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nieuwjaarsdag", notes: "The first day of the year. The Dutch celebrate with oliebollen (deep-fried dumplings) and fireworks."),
            systemRule(name: "Tweede Paasdag", region: "NL", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Tweede Paasdag", notes: "The second day of Easter. A public holiday for family visits and spring outings."),
            systemRule(name: "Koningsdag", region: "NL", isBankHoliday: true, type: .fixed, month: 4, day: 27, titleOverride: "King's Day", localName: "Koningsdag", notes: "Celebrates King Willem-Alexander's birthday. The entire country turns orange with street markets, music, and boat parties."),
            systemRule(name: "Bevrijdingsdag", region: "NL", isBankHoliday: true, type: .fixed, month: 5, day: 5, titleOverride: "Liberation Day", localName: "Bevrijdingsdag", notes: "Commemorates the liberation of the Netherlands from Nazi occupation in 1945. Celebrated with festivals and free concerts."),
            systemRule(name: "Hemelvaartsdag", region: "NL", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Hemelvaartsdag", notes: "Commemorates the ascension of Jesus into heaven. A popular day for outdoor activities and short trips."),
            systemRule(name: "Tweede Pinksterdag", region: "NL", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Tweede Pinksterdag", notes: "The second day of Pentecost. A public holiday extending the Whitsun long weekend."),
            systemRule(name: "Eerste Kerstdag", region: "NL", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Eerste Kerstdag", notes: "The first day of Christmas. Dutch traditions include a festive family dinner and church services."),
            systemRule(name: "Tweede Kerstdag", region: "NL", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Tweede Kerstdag", notes: "The second day of Christmas. A relaxed day for visiting extended family and friends."),

            // ===============================================================
            // JAPAN (JP) - 国民の祝日 (National Holidays)
            // ===============================================================
            systemRule(name: "元日", region: "JP", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "元日", notes: "The most important holiday in Japan. Families visit shrines, eat osechi-ryōri, and send nengajō (New Year cards)."),
            systemRule(name: "成人の日", region: "JP", isBankHoliday: true, type: .nthWeekday, month: 1, weekday: 2, ordinal: 2, titleOverride: "Coming of Age Day", localName: "成人の日", notes: "Celebrates young people turning 20. New adults attend ceremonies in furisode kimono and hakama."),
            systemRule(name: "建国記念の日", region: "JP", isBankHoliday: true, type: .fixed, month: 2, day: 11, titleOverride: "National Foundation Day", localName: "建国記念の日", notes: "Commemorates the mythical founding of Japan by Emperor Jimmu in 660 BC."),
            systemRule(name: "天皇誕生日", region: "JP", isBankHoliday: true, type: .fixed, month: 2, day: 23, titleOverride: "Emperor's Birthday", localName: "天皇誕生日", notes: "Celebrates the birthday of Emperor Naruhito. The Imperial Palace grounds open to the public for the occasion."),
            systemRule(name: "春分の日", region: "JP", isBankHoliday: true, type: .astronomical, month: 3, titleOverride: "Vernal Equinox Day", localName: "春分の日", notes: "Marks the spring equinox. A day for visiting family graves and appreciating the awakening of nature."),
            systemRule(name: "昭和の日", region: "JP", isBankHoliday: true, type: .fixed, month: 4, day: 29, titleOverride: "Shōwa Day", localName: "昭和の日", notes: "Honors Emperor Shōwa (Hirohito) and reflects on the turbulent Shōwa era. The start of Golden Week."),
            systemRule(name: "憲法記念日", region: "JP", isBankHoliday: true, type: .fixed, month: 5, day: 3, titleOverride: "Constitution Memorial Day", localName: "憲法記念日", notes: "Commemorates the enactment of Japan's post-war constitution in 1947. Part of Golden Week."),
            systemRule(name: "みどりの日", region: "JP", isBankHoliday: true, type: .fixed, month: 5, day: 4, titleOverride: "Greenery Day", localName: "みどりの日", notes: "A day to commune with nature and appreciate its blessings. Part of Golden Week."),
            systemRule(name: "こどもの日", region: "JP", isBankHoliday: true, type: .fixed, month: 5, day: 5, titleOverride: "Children's Day", localName: "こどもの日", notes: "Celebrates children's happiness. Families fly koinobori (carp streamers) and display samurai helmets. The last day of Golden Week."),
            systemRule(name: "海の日", region: "JP", isBankHoliday: true, type: .nthWeekday, month: 7, weekday: 2, ordinal: 3, titleOverride: "Marine Day", localName: "海の日", notes: "Gives thanks for the blessings of the ocean. A day for beach outings and marine activities."),
            systemRule(name: "山の日", region: "JP", isBankHoliday: true, type: .fixed, month: 8, day: 11, titleOverride: "Mountain Day", localName: "山の日", notes: "Provides an opportunity to appreciate mountains. Established in 2016 to encourage mountain activities."),
            systemRule(name: "敬老の日", region: "JP", isBankHoliday: true, type: .nthWeekday, month: 9, weekday: 2, ordinal: 3, titleOverride: "Respect for the Aged Day", localName: "敬老の日", notes: "Honors elderly citizens and celebrates long life. Families visit grandparents with gifts."),
            systemRule(name: "秋分の日", region: "JP", isBankHoliday: true, type: .astronomical, month: 9, titleOverride: "Autumnal Equinox Day", localName: "秋分の日", notes: "Marks the autumn equinox. A day for visiting family graves during the Buddhist Higan period."),
            systemRule(name: "スポーツの日", region: "JP", isBankHoliday: true, type: .nthWeekday, month: 10, weekday: 2, ordinal: 2, titleOverride: "Sports Day", localName: "スポーツの日", notes: "Promotes sports and an active lifestyle. Originally commemorated the 1964 Tokyo Olympics opening ceremony."),
            systemRule(name: "文化の日", region: "JP", isBankHoliday: true, type: .fixed, month: 11, day: 3, titleOverride: "Culture Day", localName: "文化の日", notes: "Promotes culture, the arts, and academic achievement. Museums offer free admission and awards are given."),
            systemRule(name: "勤労感謝の日", region: "JP", isBankHoliday: true, type: .fixed, month: 11, day: 23, titleOverride: "Labour Thanksgiving Day", localName: "勤労感謝の日", notes: "Celebrates labour and gives thanks for production. Rooted in an ancient harvest festival tradition."),
            // Japanese Observances (年中行事)
            systemRule(name: "節分", region: "JP", isBankHoliday: false, type: .fixed, month: 2, day: 3, titleOverride: "Setsubun", localName: "節分", notes: "The day before spring begins. People throw roasted soybeans to drive out evil spirits, shouting 'Oni wa soto!'"),
            systemRule(name: "バレンタインデー", region: "JP", isBankHoliday: false, type: .fixed, month: 2, day: 14, titleOverride: "Valentine's Day", localName: "バレンタインデー", notes: "In Japan, women give chocolate to men. Giri-choco (obligation chocolate) goes to colleagues, honmei-choco to loved ones."),
            systemRule(name: "ひな祭り", region: "JP", isBankHoliday: false, type: .fixed, month: 3, day: 3, titleOverride: "Hinamatsuri", localName: "ひな祭り", notes: "Girls' Day or Doll Festival. Families display ornate hina dolls and serve chirashizushi and hina-arare rice crackers."),
            systemRule(name: "ホワイトデー", region: "JP", isBankHoliday: false, type: .fixed, month: 3, day: 14, titleOverride: "White Day", localName: "ホワイトデー", notes: "Men return Valentine's gifts to women with white-themed presents. Unique to Japan and parts of East Asia."),
            systemRule(name: "七夕", region: "JP", isBankHoliday: false, type: .fixed, month: 7, day: 7, titleOverride: "Tanabata", localName: "七夕", notes: "The Star Festival celebrating the meeting of deities Orihime and Hikoboshi. People write wishes on paper strips tied to bamboo."),
            systemRule(name: "お盆", region: "JP", isBankHoliday: false, type: .fixed, month: 8, day: 15, titleOverride: "Obon", localName: "お盆", notes: "A Buddhist festival honouring ancestral spirits. Families return to their hometowns, visit graves, and perform bon odori dances."),
            systemRule(name: "七五三", region: "JP", isBankHoliday: false, type: .fixed, month: 11, day: 15, titleOverride: "Shichi-Go-San", localName: "七五三", notes: "A rite of passage for children ages 3, 5, and 7. Families visit shrines in traditional kimono and buy chitose-ame candy."),
            systemRule(name: "大晦日", region: "JP", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "大晦日", notes: "The last day of the year. Families eat toshikoshi soba (year-crossing noodles) and temple bells ring 108 times at midnight."),

            // ===============================================================
            // HONG KONG (HK) - Public Holidays
            // ===============================================================
            systemRule(name: "New Year's Day", region: "HK", isBankHoliday: true, type: .fixed, month: 1, day: 1, notes: "The first day of the Gregorian calendar year. Celebrated with countdown events along Victoria Harbour."),
            systemRule(name: "Lunar New Year", region: "HK", isBankHoliday: true, type: .lunar, month: 1, day: 1, notes: "The most important Chinese festival. Celebrated with red envelopes, lion dances, and fireworks over the harbour."),
            systemRule(name: "Ching Ming Festival", region: "HK", isBankHoliday: true, type: .fixed, month: 4, day: 4, notes: "A day to honour ancestors by visiting and cleaning their graves. Families offer food, incense, and paper offerings."),
            systemRule(name: "Good Friday", region: "HK", isBankHoliday: true, type: .easterRelative, daysOffset: -2, notes: "Commemorates the crucifixion of Jesus Christ. A public holiday reflecting Hong Kong's colonial heritage."),
            systemRule(name: "Easter Monday", region: "HK", isBankHoliday: true, type: .easterRelative, daysOffset: 1, notes: "The Monday after Easter. A public holiday enjoyed as part of a long weekend."),
            systemRule(name: "Labour Day", region: "HK", isBankHoliday: true, type: .fixed, month: 5, day: 1, notes: "International Workers' Day. A public holiday celebrating the contributions of workers."),
            systemRule(name: "Buddha's Birthday", region: "HK", isBankHoliday: true, type: .lunar, month: 4, day: 8, notes: "Celebrates the birth of Siddhartha Gautama. Temples hold bathing ceremonies and vegetarian feasts."),
            systemRule(name: "Tuen Ng Festival", region: "HK", isBankHoliday: true, type: .lunar, month: 5, day: 5, notes: "The Dragon Boat Festival. Celebrated with dragon boat races and eating zongzi (sticky rice dumplings)."),
            systemRule(name: "HKSAR Establishment Day", region: "HK", isBankHoliday: true, type: .fixed, month: 7, day: 1, notes: "Marks the establishment of the Hong Kong Special Administrative Region in 1997 after handover from Britain."),
            systemRule(name: "Mid-Autumn Festival", region: "HK", isBankHoliday: true, type: .lunar, month: 8, day: 15, notes: "A harvest festival celebrated under the full moon. Families share mooncakes and display colourful lanterns."),
            systemRule(name: "National Day", region: "HK", isBankHoliday: true, type: .fixed, month: 10, day: 1, notes: "Celebrates the founding of the People's Republic of China in 1949. Marked by fireworks and flag-raising ceremonies."),
            systemRule(name: "Chung Yeung Festival", region: "HK", isBankHoliday: true, type: .lunar, month: 9, day: 9, notes: "The Double Ninth Festival. Tradition calls for hiking to high places and visiting ancestors' graves."),
            systemRule(name: "Christmas Day", region: "HK", isBankHoliday: true, type: .fixed, month: 12, day: 25, notes: "Celebrates the birth of Jesus Christ. Hong Kong's spectacular light displays make it a festive shopping season."),
            systemRule(name: "Boxing Day", region: "HK", isBankHoliday: true, type: .fixed, month: 12, day: 26, notes: "The day after Christmas. A public holiday enjoyed for shopping sales and family time."),

            // ===============================================================
            // CHINA (CN) - 法定节假日 (Public Holidays)
            // ===============================================================
            systemRule(name: "元旦", region: "CN", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "元旦", notes: "The first day of the Gregorian calendar year. A one-day public holiday in China."),
            systemRule(name: "春节", region: "CN", isBankHoliday: true, type: .lunar, month: 1, day: 1, titleOverride: "Chinese New Year", localName: "春节", notes: "The most important Chinese festival. Celebrated with family reunions, red envelopes, fireworks, and dragon dances for 15 days."),
            systemRule(name: "清明节", region: "CN", isBankHoliday: true, type: .fixed, month: 4, day: 4, titleOverride: "Qingming Festival", localName: "清明节", notes: "Tomb-Sweeping Day for honouring ancestors. Families clean graves, make offerings, and enjoy spring outings."),
            systemRule(name: "劳动节", region: "CN", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "Labour Day", localName: "劳动节", notes: "International Workers' Day. A major travel holiday with a five-day Golden Week break."),
            systemRule(name: "端午节", region: "CN", isBankHoliday: true, type: .lunar, month: 5, day: 5, titleOverride: "Dragon Boat Festival", localName: "端午节", notes: "Commemorates the poet Qu Yuan. Celebrated with dragon boat races and eating zongzi (sticky rice dumplings)."),
            systemRule(name: "中秋节", region: "CN", isBankHoliday: true, type: .lunar, month: 8, day: 15, titleOverride: "Mid-Autumn Festival", localName: "中秋节", notes: "A harvest festival for family reunion under the full moon. Families share mooncakes and admire the moon."),
            systemRule(name: "国庆节", region: "CN", isBankHoliday: true, type: .fixed, month: 10, day: 1, titleOverride: "National Day", localName: "国庆节", notes: "Celebrates the founding of the People's Republic of China in 1949. A seven-day Golden Week holiday."),

            // ===============================================================
            // THAILAND (TH) - วันหยุดราชการ (Public Holidays)
            // ===============================================================
            systemRule(name: "วันขึ้นปีใหม่", region: "TH", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "วันขึ้นปีใหม่", notes: "The first day of the year. Thais celebrate with temple visits, merit-making, and countdown events."),
            systemRule(name: "วันมาฆบูชา", region: "TH", isBankHoliday: true, type: .lunar, month: 3, day: 15, titleOverride: "Makha Bucha Day", localName: "วันมาฆบูชา", notes: "Commemorates when 1,250 disciples spontaneously gathered to hear the Buddha preach. Marked by candlelit temple processions."),
            systemRule(name: "วันจักรี", region: "TH", isBankHoliday: true, type: .fixed, month: 4, day: 6, titleOverride: "Chakri Memorial Day", localName: "วันจักรี", notes: "Commemorates the founding of the Chakri Dynasty by King Rama I in 1782."),
            systemRule(name: "วันสงกรานต์", region: "TH", isBankHoliday: true, type: .fixed, month: 4, day: 13, titleOverride: "Songkran", localName: "วันสงกรานต์", notes: "Thai New Year and the world's largest water festival. Celebrated with water fights, temple visits, and family reunions."),
            systemRule(name: "วันแรงงาน", region: "TH", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "National Labour Day", localName: "วันแรงงาน", notes: "International Workers' Day. A public holiday for private sector workers."),
            systemRule(name: "วันฉัตรมงคล", region: "TH", isBankHoliday: true, type: .fixed, month: 5, day: 4, titleOverride: "Coronation Day", localName: "วันฉัตรมงคล", notes: "Commemorates the coronation of King Maha Vajiralongkorn (Rama X) on May 4, 2019."),
            systemRule(name: "วันวิสาขบูชา", region: "TH", isBankHoliday: true, type: .lunar, month: 4, day: 15, titleOverride: "Visakha Bucha Day", localName: "วันวิสาขบูชา", notes: "The most sacred Buddhist holiday marking the Buddha's birth, enlightenment, and death. Candlelit temple processions."),
            systemRule(name: "วันเฉลิมพระชนมพรรษา", region: "TH", isBankHoliday: true, type: .fixed, month: 6, day: 3, titleOverride: "Queen Suthida's Birthday", localName: "วันเฉลิมพระชนมพรรษา", notes: "Celebrates the birthday of Queen Suthida. Buildings are decorated and merit-making ceremonies are held."),
            systemRule(name: "วันอาสาฬหบูชา", region: "TH", isBankHoliday: true, type: .lunar, month: 6, day: 15, titleOverride: "Asalha Bucha Day", localName: "วันอาสาฬหบูชา", notes: "Commemorates the Buddha's first sermon. Marked by candlelit processions around temples."),
            systemRule(name: "วันเข้าพรรษา", region: "TH", isBankHoliday: true, type: .lunar, month: 6, day: 16, titleOverride: "Buddhist Lent Day", localName: "วันเข้าพรรษา", notes: "Marks the beginning of Buddhist Lent when monks retreat to temples for three months during the rainy season."),
            systemRule(name: "วันเฉลิมพระชนมพรรษา ร.10", region: "TH", isBankHoliday: true, type: .fixed, month: 7, day: 28, titleOverride: "King's Birthday", localName: "วันเฉลิมพระชนมพรรษา ร.10", notes: "Celebrates the birthday of King Maha Vajiralongkorn (Rama X). Buildings are decorated in yellow."),
            systemRule(name: "วันแม่แห่งชาติ", region: "TH", isBankHoliday: true, type: .fixed, month: 8, day: 12, titleOverride: "Mother's Day", localName: "วันแม่แห่งชาติ", notes: "Celebrates the birthday of Queen Sirikit, the Queen Mother. Children give jasmine garlands to their mothers."),
            systemRule(name: "วันคล้ายวันสวรรคต ร.9", region: "TH", isBankHoliday: true, type: .fixed, month: 10, day: 13, titleOverride: "King Bhumibol Memorial Day", localName: "วันคล้ายวันสวรรคต ร.9", notes: "Marks the passing of the beloved King Bhumibol Adulyadej (Rama IX) in 2016. A day of national mourning."),
            systemRule(name: "วันปิยมหาราช", region: "TH", isBankHoliday: true, type: .fixed, month: 10, day: 23, titleOverride: "Chulalongkorn Day", localName: "วันปิยมหาราช", notes: "Honours King Chulalongkorn (Rama V) who modernized Thailand and abolished slavery. Wreaths are laid at his statue."),
            systemRule(name: "วันพ่อแห่งชาติ", region: "TH", isBankHoliday: true, type: .fixed, month: 12, day: 5, titleOverride: "Father's Day", localName: "วันพ่อแห่งชาติ", notes: "Celebrates the birthday of the late King Bhumibol Adulyadej. Children give canna flowers to their fathers."),
            systemRule(name: "วันรัฐธรรมนูญ", region: "TH", isBankHoliday: true, type: .fixed, month: 12, day: 10, titleOverride: "Constitution Day", localName: "วันรัฐธรรมนูญ", notes: "Commemorates the first permanent constitution granted by King Prajadhipok in 1932."),
            systemRule(name: "วันสิ้นปี", region: "TH", isBankHoliday: true, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "วันสิ้นปี", notes: "The last day of the year. Celebrated with countdown events, temple visits, and fireworks."),

            // ===============================================================
            // NORWAY (NO) - Offentlige helligdager (Public Holidays)
            // ===============================================================
            // Bank Holidays (Røde dager)
            systemRule(name: "Nyttårsdag", region: "NO", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nyttårsdag", notes: "The first day of the year. Norwegians celebrate with fireworks and festive gatherings."),
            systemRule(name: "Skjærtorsdag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Skjærtorsdag", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
            systemRule(name: "Langfredag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Langfredag", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day often spent in quiet reflection."),
            systemRule(name: "Første påskedag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Første påskedag", notes: "Celebrates the resurrection of Jesus Christ. Norwegians enjoy Easter eggs, skiing trips, and crime novels."),
            systemRule(name: "Andre påskedag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Andre påskedag", notes: "The day after Easter Sunday. The final day of the traditional Norwegian Easter holiday week."),
            systemRule(name: "Arbeidernes dag", region: "NO", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "Labour Day", localName: "Arbeidernes dag", notes: "International Workers' Day. Marked by political rallies and parades across Norway."),
            systemRule(name: "Grunnlovsdagen", region: "NO", isBankHoliday: true, type: .fixed, month: 5, day: 17, titleOverride: "Constitution Day", localName: "Grunnlovsdagen", notes: "Norway's national day celebrating the 1814 constitution. Famous for children's parades, bunads, and ice cream."),
            systemRule(name: "Kristi himmelfartsdag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Kristi himmelfartsdag", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
            systemRule(name: "Første pinsedag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Første pinsedag", notes: "Celebrates the descent of the Holy Spirit. Falls 49 days after Easter."),
            systemRule(name: "Andre pinsedag", region: "NO", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Andre pinsedag", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
            systemRule(name: "Første juledag", region: "NO", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Første juledag", notes: "The main Christmas celebration. Norwegian traditions include ribbe (pork ribs) and walking around the Christmas tree."),
            systemRule(name: "Andre juledag", region: "NO", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Andre juledag", notes: "The day after Christmas. A relaxed day for visiting family and friends."),
            // Observances
            systemRule(name: "Julaften", region: "NO", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Julaften", notes: "The main day of Christmas celebration in Norway. Families gather for dinner, gifts, and walking around the tree."),
            systemRule(name: "Nyttårsaften", region: "NO", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Nyttårsaften", notes: "The last day of the year. Celebrated with fireworks, champagne, and watching the clock strike midnight."),
            systemRule(name: "Morsdag", region: "NO", isBankHoliday: false, type: .nthWeekday, month: 2, weekday: 1, ordinal: 2, titleOverride: "Mother's Day", localName: "Morsdag", notes: "A day to honour mothers. Celebrated with flowers, breakfast in bed, and family time."),
            systemRule(name: "Farsdag", region: "NO", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2, titleOverride: "Father's Day", localName: "Farsdag", notes: "A day to honour fathers. Celebrated with gifts and quality family time."),

            // ===============================================================
            // DENMARK (DK) - Helligdage (Public Holidays)
            // ===============================================================
            // Bank Holidays
            systemRule(name: "Nytårsdag", region: "DK", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nytårsdag", notes: "The first day of the year. Danes celebrate with the Queen's New Year speech and fireworks."),
            systemRule(name: "Skærtorsdag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Skærtorsdag", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
            systemRule(name: "Langfredag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Langfredag", notes: "Commemorates the crucifixion of Jesus Christ. A quiet day with special church services."),
            systemRule(name: "Påskedag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Påskedag", notes: "Celebrates the resurrection of Jesus Christ. Danish traditions include Easter letters and painted eggs."),
            systemRule(name: "2. Påskedag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "2. Påskedag", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
            systemRule(name: "Kristi himmelfartsdag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Kristi himmelfartsdag", notes: "Commemorates the ascension of Jesus into heaven. Often enjoyed as a long weekend."),
            systemRule(name: "Pinsedag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Pinsedag", notes: "Celebrates the descent of the Holy Spirit, 49 days after Easter."),
            systemRule(name: "2. Pinsedag", region: "DK", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "2. Pinsedag", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
            systemRule(name: "Grundlovsdag", region: "DK", isBankHoliday: true, type: .fixed, month: 6, day: 5, titleOverride: "Constitution Day", localName: "Grundlovsdag", notes: "Celebrates the signing of the Danish constitution in 1849. Marked by political speeches and outdoor events."),
            systemRule(name: "Juledag", region: "DK", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Juledag", notes: "The main Christmas celebration. Danish traditions include risalamande (rice pudding) and dancing around the tree."),
            systemRule(name: "2. Juledag", region: "DK", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "2. Juledag", notes: "The day after Christmas. A relaxed day for visiting family and friends."),
            // Observances
            systemRule(name: "Juleaftensdag", region: "DK", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Juleaftensdag", notes: "The main day of Christmas celebration in Denmark. Families gather for duck or goose dinner and dance around the tree."),
            systemRule(name: "Nytårsaften", region: "DK", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Nytårsaften", notes: "The last day of the year. Danes watch the Queen's speech, jump off chairs at midnight, and set off fireworks."),
            systemRule(name: "Mors dag", region: "DK", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2, titleOverride: "Mother's Day", localName: "Mors dag", notes: "A day to honour mothers. Celebrated with flowers, gifts, and family gatherings."),
            systemRule(name: "Valdemarsdag", region: "DK", isBankHoliday: false, type: .fixed, month: 6, day: 15, titleOverride: "Valdemar's Day", localName: "Valdemarsdag", notes: "Celebrates the Danish flag (Dannebrog), said to have fallen from the sky during battle in 1219."),

            // ===============================================================
            // FINLAND (FI) - Juhlapyhät (Public Holidays)
            // ===============================================================
            // Bank Holidays
            systemRule(name: "Uudenvuodenpäivä", region: "FI", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Uudenvuodenpäivä", notes: "The first day of the year. Finns celebrate with fireworks and the tradition of casting tin for fortune-telling."),
            systemRule(name: "Loppiainen", region: "FI", isBankHoliday: true, type: .fixed, month: 1, day: 6, titleOverride: "Epiphany", localName: "Loppiainen", notes: "Marks the visit of the Three Wise Men to the infant Jesus. The end of the Finnish Christmas season."),
            systemRule(name: "Pitkäperjantai", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Pitkäperjantai", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day with quiet reflection."),
            systemRule(name: "Pääsiäispäivä", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Pääsiäispäivä", notes: "Celebrates the resurrection of Jesus Christ. Finnish children dress as Easter witches and go door-to-door with willow branches."),
            systemRule(name: "2. pääsiäispäivä", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "2. pääsiäispäivä", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
            systemRule(name: "Vappu", region: "FI", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "May Day", localName: "Vappu", notes: "Finland's carnival-like spring celebration. Students wear white caps, and everyone enjoys sima (mead) and tippaleipä (funnel cake)."),
            systemRule(name: "Helatorstai", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Helatorstai", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
            systemRule(name: "Helluntaipäivä", region: "FI", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Helluntaipäivä", notes: "Celebrates the descent of the Holy Spirit. Falls 49 days after Easter."),
            systemRule(name: "Juhannuspäivä", region: "FI", isBankHoliday: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26, titleOverride: "Midsummer Day", localName: "Juhannuspäivä", notes: "One of Finland's most important holidays. Celebrated at summer cottages with bonfires, sauna, and the midnight sun."),
            systemRule(name: "Pyhäinpäivä", region: "FI", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 7, ordinal: 1, titleOverride: "All Saints' Day", localName: "Pyhäinpäivä", notes: "A day to honour the deceased. Finns visit cemeteries and light candles on graves, creating a beautiful sea of light."),
            systemRule(name: "Itsenäisyyspäivä", region: "FI", isBankHoliday: true, type: .fixed, month: 12, day: 6, titleOverride: "Independence Day", localName: "Itsenäisyyspäivä", notes: "Celebrates Finland's independence from Russia in 1917. Marked by candles in windows and the Presidential Independence Day Ball."),
            systemRule(name: "Joulupäivä", region: "FI", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Joulupäivä", notes: "The main Christmas celebration. Finnish traditions include Christmas sauna and visiting Santa Claus in Rovaniemi."),
            systemRule(name: "Tapaninpäivä", region: "FI", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "St. Stephen's Day", localName: "Tapaninpäivä", notes: "The day after Christmas, named after Saint Stephen. A day for visiting friends and outdoor activities."),
            // Observances
            systemRule(name: "Jouluaatto", region: "FI", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Jouluaatto", notes: "The main day of Christmas celebration in Finland. Families enjoy Christmas sauna, ham dinner, and gift-giving."),
            systemRule(name: "Uudenvuodenaatto", region: "FI", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Uudenvuodenaatto", notes: "The last day of the year. Finns celebrate with fireworks and the tradition of molten tin fortune-telling."),
            systemRule(name: "Juhannusaatto", region: "FI", isBankHoliday: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25, titleOverride: "Midsummer Eve", localName: "Juhannusaatto", notes: "The eve of Midsummer. Finns head to summer cottages for bonfires, sauna, and swimming."),
            systemRule(name: "Äitienpäivä", region: "FI", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2, titleOverride: "Mother's Day", localName: "Äitienpäivä", notes: "A day to honour mothers. Celebrated with flowers, especially a white rose, and family meals."),
            systemRule(name: "Isänpäivä", region: "FI", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2, titleOverride: "Father's Day", localName: "Isänpäivä", notes: "A day to honour fathers. Celebrated with gifts and quality family time."),

            // ===============================================================
            // ICELAND (IS) - Almennir frídagar (Public Holidays)
            // ===============================================================
            // Bank Holidays
            systemRule(name: "Nýársdagur", region: "IS", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nýársdagur", notes: "The first day of the year. Icelanders celebrate with bonfires, fireworks, and community gatherings."),
            systemRule(name: "Skírdagur", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Skírdagur", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
            systemRule(name: "Föstudagurinn langi", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Föstudagurinn langi", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day of quiet reflection."),
            systemRule(name: "Páskadagur", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Páskadagur", notes: "Celebrates the resurrection of Jesus Christ. Icelanders exchange chocolate eggs with proverbs inside."),
            systemRule(name: "Annar í páskum", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Annar í páskum", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
            systemRule(name: "Sumardagurinn fyrsti", region: "IS", isBankHoliday: true, type: .floating, month: 4, weekday: 5, dayRangeStart: 19, dayRangeEnd: 25, titleOverride: "First Day of Summer", localName: "Sumardagurinn fyrsti", notes: "Celebrates the arrival of summer in the old Icelandic calendar. A uniquely Icelandic holiday with parades and festivities."),
            systemRule(name: "Verkalýðsdagurinn", region: "IS", isBankHoliday: true, type: .fixed, month: 5, day: 1, titleOverride: "Labour Day", localName: "Verkalýðsdagurinn", notes: "International Workers' Day. Marked by union rallies and celebrations across Iceland."),
            systemRule(name: "Uppstigningardagur", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Uppstigningardagur", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
            systemRule(name: "Hvítasunnudagur", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Hvítasunnudagur", notes: "Celebrates the descent of the Holy Spirit, 49 days after Easter."),
            systemRule(name: "Annar í hvítasunnu", region: "IS", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Annar í hvítasunnu", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
            systemRule(name: "Þjóðhátíðardagur", region: "IS", isBankHoliday: true, type: .fixed, month: 6, day: 17, titleOverride: "Icelandic National Day", localName: "Þjóðhátíðardagur", notes: "Celebrates Iceland's independence from Denmark in 1944. Marked by parades, music, and the Lady of the Mountain."),
            systemRule(name: "Verslunarmannahelgi", region: "IS", isBankHoliday: true, type: .nthWeekday, month: 8, weekday: 2, ordinal: 1, titleOverride: "Commerce Day", localName: "Verslunarmannahelgi", notes: "A long weekend holiday. Icelanders celebrate with outdoor festivals, camping, and the famous Þjóðhátíð festival in Vestmannaeyjar."),
            systemRule(name: "Jóladagur", region: "IS", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Jóladagur", notes: "The main Christmas celebration. Icelandic traditions include the 13 Yule Lads who visit children in the days before Christmas."),
            systemRule(name: "Annar í jólum", region: "IS", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Annar í jólum", notes: "The day after Christmas. A relaxed day for visiting family and friends."),
            // Observances
            systemRule(name: "Aðfangadagur", region: "IS", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Aðfangadagur", notes: "The main day of Christmas celebration in Iceland. Gifts are exchanged at 6 PM and families enjoy smoked lamb."),
            systemRule(name: "Gamlársdagur", region: "IS", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Gamlársdagur", notes: "The last day of the year. Iceland's spectacular fireworks display is funded by the national rescue service."),
            systemRule(name: "Dagur íslenskrar tungu", region: "IS", isBankHoliday: false, type: .fixed, month: 11, day: 16, titleOverride: "Icelandic Language Day", localName: "Dagur íslenskrar tungu", notes: "Celebrates the Icelandic language on the birthday of poet Jónas Hallgrímsson. Events promote language preservation."),
            systemRule(name: "Mæðradagurinn", region: "IS", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: 2, titleOverride: "Mother's Day", localName: "Mæðradagurinn", notes: "A day to honour mothers. Celebrated with flowers, gifts, and family gatherings."),
            systemRule(name: "Feðradagurinn", region: "IS", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2, titleOverride: "Father's Day", localName: "Feðradagurinn", notes: "A day to honour fathers. Celebrated with gifts and quality family time."),

            // ===============================================================
            // GREENLAND (GL) - Kalaallit Nunaat (Public Holidays)
            // ===============================================================
            // Bank Holidays
            systemRule(name: "Ukiortaaq", region: "GL", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Ukiortaaq", notes: "The first day of the year. Greenlanders celebrate with fireworks and community gatherings."),
            systemRule(name: "Sisamanngorneq Illernartoq", region: "GL", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Sisamanngorneq Illernartoq", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
            systemRule(name: "Tallimanngorneq Illernartoq", region: "GL", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Tallimanngorneq Illernartoq", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day of quiet reflection."),
            systemRule(name: "Poorskip ullua", region: "GL", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Poorskip ullua", notes: "Celebrates the resurrection of Jesus Christ. Families gather for traditional meals."),
            systemRule(name: "Poorskip aappaa", region: "GL", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Poorskip aappaa", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
            systemRule(name: "Qilalugaq", region: "GL", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Qilalugaq", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
            systemRule(name: "Pinikkoq", region: "GL", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Pinikkoq", notes: "Celebrates the descent of the Holy Spirit, 49 days after Easter."),
            systemRule(name: "Pinikkoq aappaa", region: "GL", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Pinikkoq aappaa", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
            systemRule(name: "Ullortuneq", region: "GL", isBankHoliday: true, type: .fixed, month: 6, day: 21, titleOverride: "National Day", localName: "Ullortuneq", notes: "Greenland's national day on the summer solstice. Celebrated with traditional Inuit music, food, and cultural events."),
            systemRule(name: "Juulli ullua", region: "GL", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Juulli ullua", notes: "The main Christmas celebration. Greenlandic traditions blend Danish customs with Inuit culture."),
            systemRule(name: "Juulli aappaa", region: "GL", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Juulli aappaa", notes: "The day after Christmas. A relaxed day for visiting family and community feasts."),
            // Observances
            systemRule(name: "Juulli siullia", region: "GL", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Juulli siullia", notes: "The main day of Christmas celebration in Greenland. Families gather for traditional meals and gift-giving."),
            systemRule(name: "Ukiortaami siullia", region: "GL", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Ukiortaami siullia", notes: "The last day of the year. Celebrated with fireworks visible across the arctic landscape."),

            // ===============================================================
            // FAROE ISLANDS (FO) - Føroyar (Public Holidays)
            // ===============================================================
            // Bank Holidays
            systemRule(name: "Nýggjársdagur", region: "FO", isBankHoliday: true, type: .fixed, month: 1, day: 1, titleOverride: "New Year's Day", localName: "Nýggjársdagur", notes: "The first day of the year. Faroese celebrate with fireworks and festive gatherings."),
            systemRule(name: "Skírhósdagur", region: "FO", isBankHoliday: true, type: .easterRelative, daysOffset: -3, titleOverride: "Maundy Thursday", localName: "Skírhósdagur", notes: "The Thursday before Easter. Commemorates the Last Supper of Jesus with his disciples."),
            systemRule(name: "Langifríggjadagur", region: "FO", isBankHoliday: true, type: .easterRelative, daysOffset: -2, titleOverride: "Good Friday", localName: "Langifríggjadagur", notes: "Commemorates the crucifixion of Jesus Christ. A solemn day of quiet reflection."),
            systemRule(name: "Páskadagur", region: "FO", isBankHoliday: true, type: .easterRelative, daysOffset: 0, titleOverride: "Easter Sunday", localName: "Páskadagur", notes: "Celebrates the resurrection of Jesus Christ. Faroese traditions include Easter eggs and family meals."),
            systemRule(name: "Annar páskadagur", region: "FO", isBankHoliday: true, type: .easterRelative, daysOffset: 1, titleOverride: "Easter Monday", localName: "Annar páskadagur", notes: "The day after Easter Sunday. A public holiday for rest and family gatherings."),
            systemRule(name: "Flaggdagur", region: "FO", isBankHoliday: false, type: .fixed, month: 4, day: 25, titleOverride: "Flag Day", localName: "Flaggdagur", notes: "Celebrates the Faroese flag (Merkið). The flag was first used during World War II when the islands were under British protection."),
            systemRule(name: "Kristi himmalsferðardagur", region: "FO", isBankHoliday: true, type: .easterRelative, daysOffset: 39, titleOverride: "Ascension Day", localName: "Kristi himmalsferðardagur", notes: "Commemorates the ascension of Jesus into heaven, 40 days after Easter."),
            systemRule(name: "Hvítasunnudagur", region: "FO", isBankHoliday: true, type: .easterRelative, daysOffset: 49, titleOverride: "Whit Sunday", localName: "Hvítasunnudagur", notes: "Celebrates the descent of the Holy Spirit, 49 days after Easter."),
            systemRule(name: "Annar hvítasunnudagur", region: "FO", isBankHoliday: true, type: .easterRelative, daysOffset: 50, titleOverride: "Whit Monday", localName: "Annar hvítasunnudagur", notes: "The day after Whit Sunday. A public holiday extending the Pentecost weekend."),
            systemRule(name: "Ólavsøkuaftan", region: "FO", isBankHoliday: false, type: .fixed, month: 7, day: 28, titleOverride: "St. Olav's Eve", localName: "Ólavsøkuaftan", notes: "The eve of the Faroese national holiday. Opening ceremonies and cultural events begin in Tórshavn."),
            systemRule(name: "Ólavsøkudagur", region: "FO", isBankHoliday: true, type: .fixed, month: 7, day: 29, titleOverride: "St. Olav's Day", localName: "Ólavsøkudagur", notes: "The Faroese national holiday. Celebrated with rowing races, chain dancing, and the opening of the Faroese Parliament."),
            systemRule(name: "Jólafturansaftan", region: "FO", isBankHoliday: false, type: .fixed, month: 12, day: 24, titleOverride: "Christmas Eve", localName: "Jólafturansaftan", notes: "The main day of Christmas celebration in the Faroe Islands. Families gather for traditional dinner and gift-giving."),
            systemRule(name: "Jóladagur", region: "FO", isBankHoliday: true, type: .fixed, month: 12, day: 25, titleOverride: "Christmas Day", localName: "Jóladagur", notes: "The main Christmas celebration. Faroese traditions include festive meals and family gatherings."),
            systemRule(name: "Annar jóladagur", region: "FO", isBankHoliday: true, type: .fixed, month: 12, day: 26, titleOverride: "Second Day of Christmas", localName: "Annar jóladagur", notes: "The day after Christmas. A relaxed day for visiting family and friends."),
            systemRule(name: "Nýggjársaftan", region: "FO", isBankHoliday: false, type: .fixed, month: 12, day: 31, titleOverride: "New Year's Eve", localName: "Nýggjársaftan", notes: "The last day of the year. Celebrated with fireworks and festive gatherings across the islands.")
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
                    if existingRule.localName != rule.localName {
                        existingRule.localName = rule.localName
                        didChange = true
                    }
                    if existingRule.notes != rule.notes {
                        existingRule.notes = rule.notes
                        didChange = true
                    }
                    if existingRule.titleOverride != rule.titleOverride {
                        existingRule.titleOverride = rule.titleOverride
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
