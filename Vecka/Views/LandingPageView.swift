//
//  LandingPageView.swift
//  Vecka
//
//  情報デザイン: ONSEN (温泉) - Home Dashboard
//
//  Design principles:
//  - Follows Star Page golden standard layout
//  - Bento compartmentalization with wall dividers
//  - Mascot as small sprite companion (not hero)
//  - Max 8pt top padding (dark BG barely visible)
//  - Black text on white backgrounds ALWAYS
//

import SwiftUI
import SwiftData

struct LandingPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Personalized title (情報デザイン: User can customize their landing page)
    @AppStorage("customLandingTitle") private var customLandingTitle = ""

    // Data queries
    @Query(sort: \DailyNote.date, order: .reverse) private var allNotes: [DailyNote]
    @Query(sort: \ExpenseItem.date, order: .reverse) private var allExpenses: [ExpenseItem]
    @Query private var allTrips: [TravelTrip]
    @Query private var contacts: [Contact]
    @Query private var countdownEvents: [CountdownEvent]
    @Query(sort: \WorldClock.sortOrder) private var worldClocks: [WorldClock]

    private var holidayManager = HolidayManager.shared

    // MARK: - Computed Properties

    private var today: Date { Date() }
    private var todayStart: Date { Calendar.iso8601.startOfDay(for: today) }

    private var weekNumber: Int {
        Calendar.iso8601.component(.weekOfYear, from: today)
    }

    private var year: Int {
        Calendar.iso8601.component(.year, from: today)
    }

    private var weekdayFull: String {
        today.formatted(.dateTime.weekday(.wide))
    }

    private var monthName: String {
        today.formatted(.dateTime.month(.abbreviated))
    }

    /// Personalized landing page title (情報デザイン: User customization)
    private var displayTitle: String {
        customLandingTitle.isEmpty ? "ONSEN" : customLandingTitle.uppercased()
    }

    /// Limit world clocks to max 3
    private var displayClocks: [WorldClock] {
        Array(worldClocks.prefix(3))
    }

    /// Today's items for summary
    private var todayItems: [TodayItem] {
        getTodayItems()
    }

    // MARK: - GLANCE Data (情報デザイン: Contextual information)

    /// Current month theme from Star page
    private var currentMonthTheme: MonthTheme {
        let month = Calendar.current.component(.month, from: today)
        return MonthTheme.theme(for: month)
    }

    /// Special days count for current month
    private var specialDaysThisMonth: (holidays: Int, notes: Int) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from: today)

        // Count holidays this month
        var holidayCount = 0
        for (date, holidays) in holidayManager.holidayCache {
            if calendar.component(.month, from: date) == month &&
               calendar.component(.year, from: date) == year {
                holidayCount += holidays.count
            }
        }

        // Count notes/events this month
        let noteCount = allNotes.filter { note in
            calendar.component(.month, from: note.date) == month &&
            calendar.component(.year, from: note.date) == year
        }.count

        return (holidayCount, noteCount)
    }

    /// Next upcoming birthday from contacts
    private var nextBirthday: (name: String, daysUntil: Int)? {
        let calendar = Calendar.current

        var closestBirthday: (name: String, daysUntil: Int)?

        for contact in contacts {
            guard let birthday = contact.birthday else { continue }
            let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)

            // Create this year's birthday
            var thisYearBirthday = DateComponents()
            thisYearBirthday.year = calendar.component(.year, from: today)
            thisYearBirthday.month = birthdayComponents.month
            thisYearBirthday.day = birthdayComponents.day

            guard let birthdayDate = calendar.date(from: thisYearBirthday) else { continue }

            var daysUntil = calendar.dateComponents([.day], from: today, to: birthdayDate).day ?? 0

            // If birthday passed this year, calculate for next year
            if daysUntil < 0 {
                thisYearBirthday.year = calendar.component(.year, from: today) + 1
                if let nextYearBirthday = calendar.date(from: thisYearBirthday) {
                    daysUntil = calendar.dateComponents([.day], from: today, to: nextYearBirthday).day ?? 365
                }
            }

            let firstName = contact.givenName.isEmpty ? contact.familyName : contact.givenName

            if closestBirthday == nil || daysUntil < closestBirthday!.daysUntil {
                closestBirthday = (firstName, daysUntil)
            }
        }

        return closestBirthday
    }

    /// Database health status
    private var databaseHealth: (isHealthy: Bool, slotsRemaining: Int) {
        let totalEntries = allNotes.count + allExpenses.count + allTrips.count + contacts.count + countdownEvents.count
        let maxSlots = 5000
        let remaining = maxSlots - totalEntries
        return (remaining > 100, remaining)
    }

    // MARK: - Body (Star Page Pattern)

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingMD) {
                // PAGE HEADER: Two-row card matching Calendar structure
                pageHeader

                // WORLD CLOCKS: Hotel style (if configured)
                if !displayClocks.isEmpty {
                    worldClocksCard
                }

                // TODAY: What's happening
                todayCard

                // GLANCE: Contextual information dashboard (情報デザイン)
                glanceCard
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.top, JohoDimensions.spacingSM)
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .scrollContentBackground(.hidden)
        .johoBackground()
    }

    // MARK: - Page Header (Two-Row: Icon+Title | Week+Date - Matches Calendar)

    private var pageHeader: some View {
        let dayNumber = Calendar.iso8601.component(.day, from: today)
        let weekday = today.formatted(.dateTime.weekday(.abbreviated)).uppercased()

        return VStack(spacing: 0) {
            // ROW 1: Icon + Title | WALL | Mascot
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Icon + Title
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Icon zone with Landing accent color (Warm Amber)
                    Image(systemName: "house.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(PageHeaderColor.landing.accent)
                        .frame(width: 40, height: 40)
                        .background(PageHeaderColor.landing.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: 1.5)
                        )

                    Text(displayTitle)
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL
                Rectangle()
                    .fill(colors.border)
                    .frame(width: 1.5)

                // RIGHT COMPARTMENT: Animated mascot (情報デザイン)
                // Happy default with random ♨️ onsen transformation, tap to return
                JohoMascot(
                    mood: mascotMood,
                    size: 44,
                    borderWidth: 1.5,
                    showBob: true,
                    showBlink: true,
                    autoOnsen: true  // Randomly transforms to ♨️, tap to return
                )
                .padding(JohoDimensions.spacingSM)
            }
            .frame(minHeight: 56)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // ROW 2: Date info + Week badge (matches Calendar's Today row)
            HStack(spacing: JohoDimensions.spacingSM) {
                // Day number + weekday
                HStack(spacing: JohoDimensions.spacingXS) {
                    Text("\(dayNumber)")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(colors.primary)

                    Text(weekday)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.secondary)

                    Text("•")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(0.4))

                    Text(monthName)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.secondary)
                }

                Spacer()

                // Week badge (matches Calendar) - inverted for contrast
                Text("W\(weekNumber)")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colors.surfaceInverted)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }

    /// Mascot mood - happy default, with occasional ♨️ onsen transformation
    private var mascotMood: MascotMood {
        .happy  // Default happy, blushing face - autoOnsen handles ♨️ transformation
    }

    // MARK: - World Clocks Card (Hotel Style)

    private var worldClocksCard: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)

                Text("WORLD")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                Text("\(displayClocks.count)")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(colors.secondary)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Clocks row
            HStack(spacing: 0) {
                ForEach(Array(displayClocks.enumerated()), id: \.element.id) { index, clock in
                    if index > 0 {
                        // Vertical wall between clocks
                        Rectangle()
                            .fill(colors.border)
                            .frame(width: 1)
                    }

                    worldClockCell(clock)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    /// Individual clock cell (bento compartment) - 情報デザイン: Analog clock with region colors
    private func worldClockCell(_ clock: WorldClock) -> some View {
        let theme = TimezoneTheme.theme(for: clock.timezoneIdentifier)

        return VStack(spacing: 4) {
            // Country code pill (情報デザイン: Region-colored like MonthTheme)
            Text(clock.countryCode)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(theme.accentColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(colors.border, lineWidth: 0.5))

            // Full city name (情報デザイン: Clear identification)
            Text(clock.cityName)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(colors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Analog clock (情報デザイン: Clean station clock style)
            if let tz = clock.timezone {
                AnalogClockView(
                    timezone: tz,
                    size: 52,
                    accentColor: theme.accentColor
                )
            }

            // Digital time (small, below analog clock)
            Text(clock.formattedTime)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)

            // Day/Night + offset (情報デザイン: Sun=yellow, Moon=purple)
            HStack(spacing: 3) {
                Image(systemName: clock.isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(clock.isDaytime ? Color(hex: "F39C12") : Color(hex: "6C5CE7"))

                Text(clock.offsetFromLocal)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingXS)
    }

    // MARK: - Timezone Theme (情報デザイン: Regional colors like MonthTheme)

    /// 情報デザイン: Timezone themes with regional colors (like Star page MonthTheme)
    struct TimezoneTheme {
        let region: String
        let accentColor: Color
        let lightBackground: Color

        /// Regional color themes - warm/cool based on geography
        static let themes: [String: TimezoneTheme] = [
            // Asia/Pacific - Warm tones (coral, orange, red)
            "Asia": TimezoneTheme(region: "Asia", accentColor: Color(hex: "E17055"), lightBackground: Color(hex: "FDECE8")),
            "Pacific": TimezoneTheme(region: "Pacific", accentColor: Color(hex: "00CEC9"), lightBackground: Color(hex: "E8FFFE")),
            "Australia": TimezoneTheme(region: "Australia", accentColor: Color(hex: "D35400"), lightBackground: Color(hex: "FDEEE5")),

            // Europe - Cool tones (blue, purple)
            "Europe": TimezoneTheme(region: "Europe", accentColor: Color(hex: "4A90D9"), lightBackground: Color(hex: "E8F4FD")),
            "Atlantic": TimezoneTheme(region: "Atlantic", accentColor: Color(hex: "6C5CE7"), lightBackground: Color(hex: "EFECFD")),

            // Americas - Green/teal tones
            "America": TimezoneTheme(region: "America", accentColor: Color(hex: "00B894"), lightBackground: Color(hex: "E8FDF6")),

            // Africa/Middle East - Warm gold
            "Africa": TimezoneTheme(region: "Africa", accentColor: Color(hex: "FDCB6E"), lightBackground: Color(hex: "FFF9E8")),

            // Default
            "default": TimezoneTheme(region: "default", accentColor: Color(hex: "636E72"), lightBackground: Color(hex: "F0F2F3"))
        ]

        /// Get theme for timezone identifier (e.g., "Asia/Tokyo" → Asia theme)
        static func theme(for timezoneId: String) -> TimezoneTheme {
            // Extract region from timezone ID (e.g., "Asia/Tokyo" → "Asia")
            let region = timezoneId.split(separator: "/").first.map(String.init) ?? "default"
            return themes[region] ?? themes["default"]!
        }
    }

    // MARK: - Today Card

    private var todayCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(JohoColors.yellow)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(colors.border, lineWidth: 1))

                Text("TODAY")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                if !todayItems.isEmpty {
                    Text("\(todayItems.count)")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(colors.secondary)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Content
            if todayItems.isEmpty {
                Text("Nothing scheduled")
                    .font(JohoFont.body)
                    .foregroundStyle(colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(JohoDimensions.spacingMD)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todayItems.prefix(5).enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Rectangle()
                                .fill(colors.border.opacity(0.2))
                                .frame(height: 1)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                        }

                        todayItemRow(item)
                    }

                    if todayItems.count > 5 {
                        Rectangle()
                            .fill(colors.border.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)

                        Text("+\(todayItems.count - 5) more")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(colors.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, JohoDimensions.spacingSM)
                    }
                }
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    /// Today item row
    private func todayItemRow(_ item: TodayItem) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Type indicator
            Circle()
                .fill(item.color)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(colors.border, lineWidth: 0.5))

            // Icon
            Image(systemName: item.icon)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(item.color)
                .frame(width: 16)

            // Title
            Text(item.title)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary)
                .lineLimit(1)

            Spacer()

            // Type badge
            Text(item.typeBadge)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(item.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(item.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    // MARK: - GLANCE Card (情報デザイン: Star Page Style Dashboard)

    private var glanceCard: some View {
        VStack(spacing: 0) {
            // Header with ※ kome-jirushi (reference/attention mark)
            HStack {
                Text("※")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(colors.primary)

                Text("GLANCE")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // 2x2 Grid - Star Page Style (情報デザイン: Centered icons, light backgrounds)
            HStack(spacing: JohoDimensions.spacingSM) {
                VStack(spacing: JohoDimensions.spacingSM) {
                    // CALENDAR: Week progress
                    starStyleGlanceTile(
                        target: .calendar,
                        icon: "calendar",
                        label: "W\(weekNumber)",
                        indicator: todayItems.isEmpty ? nil : "●\(todayItems.count)"
                    )

                    // CONTACTS: Count + birthday
                    starStyleGlanceTile(
                        target: .contacts,
                        icon: "person.2.fill",
                        label: "\(contacts.count)",
                        indicator: nextBirthdayIndicator
                    )
                }

                VStack(spacing: JohoDimensions.spacingSM) {
                    // STAR: Month theme
                    starStyleGlanceTile(
                        target: .specialDays,
                        icon: currentMonthTheme.icon,
                        label: currentMonthTheme.name.prefix(3).uppercased(),
                        indicator: specialDaysIndicator,
                        customIconColor: currentMonthTheme.accentColor,
                        customBackground: currentMonthTheme.lightBackground
                    )

                    // SETTINGS: Health
                    starStyleGlanceTile(
                        target: .settings,
                        icon: "gearshape.fill",
                        label: databaseHealth.isHealthy ? "○" : "△",
                        indicator: nil
                    )
                }
            }
            .padding(JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    /// Special days indicator using maru-batsu symbols (●/○)
    private var specialDaysIndicator: String? {
        let (holidays, notes) = specialDaysThisMonth
        if holidays == 0 && notes == 0 { return nil }
        var parts: [String] = []
        if holidays > 0 { parts.append("●\(holidays)") }
        if notes > 0 { parts.append("○\(notes)") }
        return parts.joined(separator: " ")
    }

    /// Next birthday indicator (情報デザイン: ★ symbol)
    private var nextBirthdayIndicator: String? {
        guard let birthday = nextBirthday, birthday.daysUntil <= 14 else { return nil }
        if birthday.daysUntil == 0 {
            return "★ today"
        } else {
            return "★ \(birthday.daysUntil)d"
        }
    }

    /// Star Page Style GLANCE tile - matches month card design EXACTLY
    /// 情報デザイン: NO visible borders, just pastel background with subtle squircle
    private func starStyleGlanceTile(
        target: SidebarSelection,
        icon: String,
        label: String,
        indicator: String?,
        customIconColor: Color? = nil,
        customBackground: Color? = nil
    ) -> some View {
        // Get colors from PageHeaderColor
        let pageColor: PageHeaderColor = {
            switch target {
            case .landing: return .landing
            case .calendar: return .calendar
            case .contacts: return .contacts
            case .specialDays: return .specialDays
            case .settings: return .settings
            }
        }()

        let iconColor = customIconColor ?? pageColor.accent
        let bgColor = customBackground ?? pageColor.lightBackground

        return Button {
            HapticManager.impact(.light)
            NotificationCenter.default.post(name: .navigateToPage, object: target)
        } label: {
            VStack(spacing: 6) {
                // Large centered icon (Star page style - 32pt)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(iconColor)

                // Centered label (BLACK, bold, uppercase)
                Text(label)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                // Count indicator orbs (Star page style - small)
                if let indicator = indicator {
                    Text(indicator)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                } else {
                    Text("—")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(JohoColors.black.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            // NO BORDER - Star page has no visible borders on cards
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(target.label): \(label)")
    }

    // MARK: - TodayItem Model

    private struct TodayItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String?
        let icon: String
        let color: Color
        let typeBadge: String
    }

    // MARK: - Get Today's Items

    private func getTodayItems() -> [TodayItem] {
        let calendar = Calendar.iso8601
        var items: [TodayItem] = []

        // 1. Holidays today
        if let holidays = holidayManager.holidayCache[todayStart] {
            for holiday in holidays {
                let color = holiday.isRedDay ? JohoColors.red : JohoColors.orange
                let badge = holiday.isRedDay ? "HOL" : "OBS"
                items.append(TodayItem(
                    title: holiday.displayTitle,
                    subtitle: nil,
                    icon: holiday.isRedDay ? "star.fill" : "sparkles",
                    color: color,
                    typeBadge: badge
                ))
            }
        }

        // 2. Birthdays today
        let currentMonth = calendar.component(.month, from: todayStart)
        let currentDay = calendar.component(.day, from: todayStart)

        for contact in contacts {
            guard let birthday = contact.birthday else { continue }
            let bMonth = calendar.component(.month, from: birthday)
            let bDay = calendar.component(.day, from: birthday)

            if bMonth == currentMonth && bDay == currentDay {
                let name = contact.displayName.isEmpty ? "Someone" : contact.displayName
                items.append(TodayItem(
                    title: "\(name)'s Birthday",
                    subtitle: nil,
                    icon: "birthday.cake.fill",
                    color: JohoColors.pink,
                    typeBadge: "BDY"
                ))
            }
        }

        // 3. Countdown events today
        for event in countdownEvents {
            let eventDate = calendar.startOfDay(for: event.targetDate)
            if eventDate == todayStart {
                items.append(TodayItem(
                    title: event.title,
                    subtitle: nil,
                    icon: "calendar.badge.clock",
                    color: JohoColors.eventPurple,
                    typeBadge: "EVT"
                ))
            }
        }

        // 4. Notes today
        for note in allNotes {
            let noteDate = calendar.startOfDay(for: note.date)
            if noteDate == todayStart {
                let preview = String(note.content.prefix(30))
                items.append(TodayItem(
                    title: preview + (note.content.count > 30 ? "..." : ""),
                    subtitle: nil,
                    icon: "note.text",
                    color: JohoColors.yellow,
                    typeBadge: "NTE"
                ))
            }
        }

        // 5. Active trips
        for trip in allTrips {
            let tripStart = calendar.startOfDay(for: trip.startDate)
            let tripEnd = calendar.startOfDay(for: trip.endDate)

            if todayStart >= tripStart && todayStart <= tripEnd {
                items.append(TodayItem(
                    title: trip.tripName,
                    subtitle: nil,
                    icon: "airplane",
                    color: JohoColors.orange,
                    typeBadge: "TRP"
                ))
            }
        }

        // 6. Expenses today
        for expense in allExpenses {
            let expenseDate = calendar.startOfDay(for: expense.date)
            if expenseDate == todayStart {
                items.append(TodayItem(
                    title: expense.itemDescription,
                    subtitle: nil,
                    icon: "dollarsign.circle.fill",
                    color: JohoColors.green,
                    typeBadge: "EXP"
                ))
            }
        }

        return items
    }
}

// MARK: - Navigation Notification

extension Notification.Name {
    static let navigateToPage = Notification.Name("navigateToPage")
}

// MARK: - Preview

#Preview("Onsen Landing") {
    LandingPageView()
}
