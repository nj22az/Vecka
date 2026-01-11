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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// 情報デザイン: Adaptive layout for iPad (regular) vs iPhone (compact)
    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

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

    // UI State for sheets
    @State private var showTripsSheet = false
    @State private var showExpensesSheet = false

    // Random stat state (情報デザイン: Rotating insights)
    @State private var randomStatIndex: Int = 0

    // Discovery Grid state (情報デザイン: Random events from database)
    @State private var discoveryItems: [DiscoveryItem] = []
    @State private var discoveryShuffleID = UUID()

    // Navigation to Calendar with specific date
    @State private var navigateToDate: Date?
    @State private var shouldNavigateToCalendar = false

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

    /// Limit world clocks to max 3, with 3 defaults if none configured
    private var displayClocks: [WorldClock] {
        if worldClocks.isEmpty {
            // 情報デザイン: Always show content, never empty states
            // Default clocks: Tokyo, London, New York
            return [
                WorldClock(cityName: "Tokyo", timezoneIdentifier: "Asia/Tokyo", sortOrder: 0),
                WorldClock(cityName: "London", timezoneIdentifier: "Europe/London", sortOrder: 1),
                WorldClock(cityName: "New York", timezoneIdentifier: "America/New_York", sortOrder: 2)
            ]
        }
        return Array(worldClocks.prefix(3))
    }

    /// Today's items for summary
    private var todayItems: [TodayItem] {
        getTodayItems()
    }

    // MARK: - Discovery Grid Data (情報デザイン: Random events from database)

    /// Discovery item for the grid - represents any event from the database
    struct DiscoveryItem: Identifiable {
        let id = UUID()
        let date: Date
        let title: String
        let type: DiscoveryType
        let subtitle: String?

        enum DiscoveryType {
            case holiday, birthday, trip, expense, note, event

            var icon: String {
                switch self {
                case .holiday: return "star.fill"
                case .birthday: return "gift.fill"
                case .trip: return "airplane"
                case .expense: return "dollarsign.circle.fill"
                case .note: return "note.text"
                case .event: return "calendar"
                }
            }

            var color: Color {
                switch self {
                case .holiday: return SpecialDayType.holiday.accentColor
                case .birthday: return SpecialDayType.birthday.accentColor
                case .trip: return SpecialDayType.trip.accentColor
                case .expense: return SpecialDayType.expense.accentColor
                case .note: return SpecialDayType.note.accentColor
                case .event: return SpecialDayType.event.accentColor
                }
            }

            var background: Color {
                switch self {
                case .holiday: return SpecialDayType.holiday.lightBackground
                case .birthday: return SpecialDayType.birthday.lightBackground
                case .trip: return SpecialDayType.trip.lightBackground
                case .expense: return SpecialDayType.expense.lightBackground
                case .note: return SpecialDayType.note.lightBackground
                case .event: return SpecialDayType.event.lightBackground
                }
            }

            var badge: String {
                switch self {
                case .holiday: return "HOL"
                case .birthday: return "BDY"
                case .trip: return "TRP"
                case .expense: return "EXP"
                case .note: return "NTE"
                case .event: return "EVT"
                }
            }
        }

        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }

        var yearString: String {
            String(Calendar.current.component(.year, from: date))
        }
    }

    /// Generate random discovery items from all database sources
    private func generateDiscoveryItems(count: Int = 12) -> [DiscoveryItem] {
        var items: [DiscoveryItem] = []

        // Add holidays from cache
        for (date, holidays) in holidayManager.holidayCache {
            for holiday in holidays {
                items.append(DiscoveryItem(
                    date: date,
                    title: holiday.displayTitle,
                    type: holiday.isBankHoliday ? .holiday : .event,
                    subtitle: holiday.region
                ))
            }
        }

        // Add birthdays from contacts
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: today)
        for contact in contacts {
            if let birthday = contact.birthday {
                // Create birthday for current year
                var components = calendar.dateComponents([.month, .day], from: birthday)
                components.year = currentYear
                if let thisYearBirthday = calendar.date(from: components) {
                    items.append(DiscoveryItem(
                        date: thisYearBirthday,
                        title: "\(contact.givenName)'s Birthday",
                        type: .birthday,
                        subtitle: contact.familyName
                    ))
                }
            }
        }

        // Add trips
        for trip in allTrips {
            items.append(DiscoveryItem(
                date: trip.startDate,
                title: trip.destination,
                type: .trip,
                subtitle: trip.purpose
            ))
        }

        // Add expenses
        for expense in allExpenses.prefix(50) {
            let amountStr = String(format: "%.0f %@", expense.amount, expense.currency)
            items.append(DiscoveryItem(
                date: expense.date,
                title: expense.itemDescription,
                type: .expense,
                subtitle: amountStr
            ))
        }

        // Add notes
        for note in allNotes.prefix(50) {
            if !note.content.isEmpty {
                items.append(DiscoveryItem(
                    date: note.date,
                    title: String(note.content.prefix(30)),
                    type: .note,
                    subtitle: nil
                ))
            }
        }

        // Add countdown events
        for event in countdownEvents {
            items.append(DiscoveryItem(
                date: event.targetDate,
                title: event.title,
                type: .event,
                subtitle: nil
            ))
        }

        // Shuffle and return requested count
        return Array(items.shuffled().prefix(count))
    }

    /// Refresh discovery items with new random selection
    private func shuffleDiscovery() {
        withAnimation(.easeInOut(duration: 0.3)) {
            discoveryItems = generateDiscoveryItems(count: 20)
            discoveryShuffleID = UUID()
        }
        HapticManager.selection()
    }

    // MARK: - GLANCE Data (情報デザイン: Contextual information)

    /// Current month theme from Star page
    private var currentMonthTheme: MonthTheme {
        let month = Calendar.current.component(.month, from: today)
        return MonthTheme.theme(for: month)
    }

    /// Special days count for current month (matches Star page format)
    /// Returns holidays (red●), observances (orange○), birthdays (pink○)
    private var specialDaysThisMonth: (holidays: Int, observances: Int, birthdays: Int) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from: today)

        // Count holidays and observances this month
        var holidayCount = 0
        var observanceCount = 0
        for (date, holidays) in holidayManager.holidayCache {
            if calendar.component(.month, from: date) == month &&
               calendar.component(.year, from: date) == year {
                for holiday in holidays {
                    if holiday.isBankHoliday {
                        holidayCount += 1
                    } else {
                        observanceCount += 1
                    }
                }
            }
        }

        // Count birthdays this month (from contacts)
        let birthdayCount = contacts.filter { contact in
            guard let birthday = contact.birthday else { return false }
            return calendar.component(.month, from: birthday) == month
        }.count

        return (holidayCount, observanceCount, birthdayCount)
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

    // MARK: - Random Stat (情報デザイン: Rotating insights, not settings)

    /// Model for random stat display
    private struct RandomStat {
        let icon: String
        let label: String
        let indicator: String?
        let iconColor: Color
        let bgColor: Color
    }

    /// Available random stats to show (情報デザイン: User-relevant data)
    private var availableRandomStats: [RandomStat] {
        var stats: [RandomStat] = []

        // 1. Year progress
        let calendar = Calendar.iso8601
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: today)?.count ?? 365
        let yearProgress = Int((Double(dayOfYear) / Double(daysInYear)) * 100)
        stats.append(RandomStat(
            icon: "chart.pie.fill",
            label: "\(yearProgress)%",
            indicator: "year",
            iconColor: JohoColors.green,
            bgColor: JohoColors.green.opacity(0.15)
        ))

        // 2. Week context (X of 52)
        let totalWeeks = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: today)?.count ?? 52
        stats.append(RandomStat(
            icon: "calendar.badge.clock",
            label: "W\(weekNumber)",
            indicator: "of \(totalWeeks)",
            iconColor: JohoColors.cyan,
            bgColor: JohoColors.cyan.opacity(0.15)
        ))

        // 3. Notes count (if any)
        if !allNotes.isEmpty {
            stats.append(RandomStat(
                icon: "note.text",
                label: "\(allNotes.count)",
                indicator: "notes",
                iconColor: JohoColors.yellow,
                bgColor: JohoColors.yellow.opacity(0.15)
            ))
        }

        // 4. Days until next holiday
        if let nextHoliday = getNextHoliday() {
            stats.append(RandomStat(
                icon: "star.fill",
                label: "\(nextHoliday.daysUntil)d",
                indicator: nextHoliday.name.prefix(8).lowercased(),
                iconColor: JohoColors.red,
                bgColor: JohoColors.pink.opacity(0.15)
            ))
        }

        // 5. Days left in month
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
        let daysLeftInMonth = calendar.dateComponents([.day], from: today, to: endOfMonth).day ?? 0
        stats.append(RandomStat(
            icon: "calendar",
            label: "\(daysLeftInMonth)",
            indicator: "days left",
            iconColor: currentMonthTheme.accentColor,
            bgColor: currentMonthTheme.lightBackground
        ))

        // 6. Countdown events (if any)
        if let nextEvent = countdownEvents.filter({ $0.targetDate > today }).min(by: { $0.targetDate < $1.targetDate }) {
            let daysUntil = calendar.dateComponents([.day], from: today, to: nextEvent.targetDate).day ?? 0
            stats.append(RandomStat(
                icon: "clock.fill",
                label: "\(daysUntil)d",
                indicator: nextEvent.title.prefix(8).lowercased(),
                iconColor: JohoColors.cyan,
                bgColor: JohoColors.purple.opacity(0.15)
            ))
        }

        return stats
    }

    /// Current random stat to display
    private var currentRandomStat: RandomStat {
        let stats = availableRandomStats
        guard !stats.isEmpty else {
            return RandomStat(
                icon: "sparkles",
                label: "—",
                indicator: nil,
                iconColor: JohoColors.black.opacity(0.5),
                bgColor: JohoColors.black.opacity(0.05)
            )
        }
        return stats[randomStatIndex % stats.count]
    }

    /// Get next upcoming holiday
    private func getNextHoliday() -> (name: String, daysUntil: Int)? {
        let calendar = Calendar.iso8601
        let todayStart = calendar.startOfDay(for: today)

        var closest: (name: String, daysUntil: Int)?

        for (date, holidays) in holidayManager.holidayCache {
            guard date > todayStart else { continue }
            let days = calendar.dateComponents([.day], from: todayStart, to: date).day ?? 0
            guard days > 0 && days <= 365 else { continue }

            for holiday in holidays where holiday.isBankHoliday {
                if closest == nil || days < closest!.daysUntil {
                    closest = (holiday.displayTitle, days)
                }
            }
        }

        return closest
    }

    // MARK: - Body (情報デザイン: Content fills screen, no scrolling on iPad)

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// 情報デザイン: iPad uses full screen bento grid, no scrolling
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        Group {
            if isRegularWidth {
                // iPad: Same layout as iPhone, scaled to fill screen
                // 情報デザイン: Identical components, just larger
                ScrollView {
                    VStack(spacing: JohoDimensions.spacingMD) {
                        pageHeader

                        if !displayClocks.isEmpty {
                            worldClocksCard
                        }

                        todayCard
                        glanceCard
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)
                    .padding(.bottom, JohoDimensions.spacingXL)
                }
            } else {
                // iPhone/iPad mini: Scrollable stacked layout
                ScrollView {
                    VStack(spacing: JohoDimensions.spacingMD) {
                        pageHeader

                        if !displayClocks.isEmpty {
                            worldClocksCard
                        }

                        todayCard
                        glanceCard
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .padding(.top, JohoDimensions.spacingSM)
                    .padding(.bottom, JohoDimensions.spacingXL)
                }
            }
        }
        .johoBackground()
        .onAppear {
            // Randomize stat on each appearance (情報デザイン: Fresh insights)
            randomStatIndex = Int.random(in: 0..<max(1, availableRandomStats.count))
        }
        .sheet(isPresented: $showTripsSheet) {
            NavigationStack {
                TripListView()
            }
        }
        .sheet(isPresented: $showExpensesSheet) {
            NavigationStack {
                ExpenseListView()
            }
        }
    }

    // MARK: - iPad Bento Grid (情報デザイン: Discovery-focused dashboard)

    /// 情報デザイン: iPad dashboard - GLANCE (top) → AGENDA (middle) → DISCOVER (bottom)
    /// Layout matches Star page bento styling with compartment walls
    @ViewBuilder
    private func iPadBentoGrid(in geometry: GeometryProxy) -> some View {
        let padding = JohoDimensions.spacingSM  // 8pt outer edge only

        // 情報デザイン: ONE BIG WHITE BENTO fills the screen
        let availableHeight = geometry.size.height - geometry.safeAreaInsets.bottom - (padding * 2)

        // Detect orientation from geometry (more reliable than size classes)
        let isLandscapeLayout = geometry.size.width > geometry.size.height

        // 情報デザイン: Information instrument layout
        // Primary axis: TODAY → THIS WEEK → GLANCE (contextual) → PROGRESS
        VStack(spacing: 0) {
            // HEADER COMPARTMENT
            iPadBentoHeader
                .frame(height: 64)

            // Horizontal wall below header
            Rectangle().fill(JohoColors.black).frame(height: 2)

            if isLandscapeLayout {
                // LANDSCAPE: TODAY (primary) | THIS WEEK (secondary)
                HStack(spacing: 0) {
                    // LEFT (55%): TODAY - Primary information anchor
                    iPadTodaySection
                        .frame(maxWidth: .infinity)

                    Rectangle().fill(JohoColors.black).frame(width: 2)

                    // RIGHT (45%): THIS WEEK - Secondary information
                    iPadThisWeekSection
                        .frame(width: geometry.size.width * 0.42)
                }
                .frame(maxHeight: .infinity)
            } else {
                // PORTRAIT: TODAY → THIS WEEK vertical stack
                VStack(spacing: 0) {
                    // TODAY - Primary anchor (takes more space)
                    iPadTodaySection
                        .frame(maxHeight: .infinity)

                    Rectangle().fill(JohoColors.black).frame(height: 2)

                    // THIS WEEK - Secondary
                    iPadThisWeekSection
                        .frame(maxHeight: .infinity)
                }
            }

            // Horizontal wall above glance
            Rectangle().fill(JohoColors.black).frame(height: 2)

            // GLANCE ROW: Contextual non-zero stats only
            iPadGlanceRow
                .frame(height: 44)

            // Horizontal wall above footer
            Rectangle().fill(JohoColors.black).frame(height: 2)

            // FOOTER COMPARTMENT: Progress bars
            iPadBentoFooter
                .frame(height: 70)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(Squircle(cornerRadius: JohoDimensions.radiusLarge).stroke(JohoColors.black, lineWidth: 3))
        .padding(padding)
        .frame(width: geometry.size.width, height: availableHeight + (padding * 2))
    }

    // MARK: - iPad TODAY Section (情報デザイン: Primary Information Anchor)

    /// TODAY section - The dominant information object
    /// Shows today's events or explicit "no events" state with next upcoming item
    private var iPadTodaySection: some View {
        VStack(spacing: 0) {
            // Header with date
            HStack(alignment: .center) {
                Circle().fill(JohoColors.yellow).frame(width: 12, height: 12)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                Text("TODAY")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1)

                Spacer()

                // Full date as anchor
                Text(today.formatted(.dateTime.day().month(.wide).year()))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Content: Today's items or explicit empty state
            if todayItems.isEmpty {
                // Explicit empty state with next upcoming
                VStack(spacing: JohoDimensions.spacingMD) {
                    Spacer()

                    // Clear state indicator
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(JohoColors.black.opacity(0.2))
                        Text("No events scheduled")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }

                    // Next upcoming item (if any)
                    if let nextItem = upcomingItems.first(where: { !$0.isToday }) {
                        HStack(spacing: JohoDimensions.spacingSM) {
                            Text("Next:")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.secondary)

                            Circle()
                                .fill(nextItem.color)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))

                            Text(nextItem.title)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(JohoColors.black)

                            Text("(\(nextItem.date.formatted(.dateTime.day().month(.abbreviated))))")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.secondary)
                        }
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM)
                        .background(JohoColors.yellow)
                        .clipShape(Squircle(cornerRadius: 8))
                        .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1))
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Today's items with bento rows
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(todayItems, id: \.id) { item in
                            todayItemBentoRow(item)
                            Rectangle().fill(JohoColors.black.opacity(0.2)).frame(height: 1)
                        }
                    }
                    .padding(.top, JohoDimensions.spacingXS)
                }
            }
        }
        .background(JohoColors.white)
    }

    /// Today item as bento row with compartments
    private func todayItemBentoRow(_ item: TodayItem) -> some View {
        HStack(spacing: 0) {
            // LEFT: Type indicator
            Circle()
                .fill(item.color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                .frame(width: 36)

            Rectangle().fill(JohoColors.black).frame(width: 1)
                .frame(maxHeight: .infinity)

            // CENTER: Title + subtitle if any
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle().fill(JohoColors.black).frame(width: 1)
                .frame(maxHeight: .infinity)

            // RIGHT: Badge
            Text(item.typeBadge)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.color)
                .clipShape(Capsule())
                .frame(width: 56)
        }
        .frame(height: 44)
    }

    // MARK: - iPad THIS WEEK Section (情報デザイン: Secondary Axis)

    /// THIS WEEK section - Secondary information showing upcoming 7 days
    private var iPadThisWeekSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle().fill(JohoColors.cyan).frame(width: 10, height: 10)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                Text("THIS WEEK")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)

                Spacer()

                Text("W\(weekNumber)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(JohoColors.black)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Content
            let weekItems = upcomingItems.filter { !$0.isToday }

            if weekItems.isEmpty {
                // Explicit empty state
                VStack(spacing: 8) {
                    Spacer()
                    Text("All clear through W\(weekNumber)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Week items
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(weekItems.prefix(10), id: \.id) { item in
                            weekItemRow(item)
                            Rectangle().fill(JohoColors.black.opacity(0.2)).frame(height: 1)
                        }
                    }
                    .padding(.top, JohoDimensions.spacingXS)
                }
            }
        }
        .background(JohoColors.white)
    }

    /// Week item row
    private func weekItemRow(_ item: UpcomingItem) -> some View {
        HStack(spacing: 0) {
            // LEFT: Day indicator
            VStack(spacing: 0) {
                Text(item.dayName)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                Text(String(item.dayNumber))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
            }
            .frame(width: 36)

            Rectangle().fill(JohoColors.black).frame(width: 1)
                .frame(maxHeight: .infinity)

            // CENTER: Type dot + Title
            HStack(spacing: JohoDimensions.spacingXS) {
                Circle()
                    .fill(item.color)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))

                Text(item.title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle().fill(JohoColors.black).frame(width: 1)
                .frame(maxHeight: .infinity)

            // RIGHT: Badge
            Text(item.typeBadge)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(item.color)
                .clipShape(Capsule())
                .frame(width: 48)
        }
        .frame(height: 40)
    }

    // MARK: - iPad Glance Row (情報デザイン: Contextual non-zero stats only)

    /// Compact glance row showing only non-zero stats with descriptions
    private var iPadGlanceRow: some View {
        HStack(spacing: 0) {
            // Header
            Image(systemName: "snowflake")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(JohoColors.cyan)
            Text("GLANCE")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.5)
                .padding(.leading, 4)

            Rectangle().fill(JohoColors.black).frame(width: 1)
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(maxHeight: .infinity)

            // Non-zero stats only, with context
            HStack(spacing: JohoDimensions.spacingMD) {
                // Holidays this month (with names if few)
                if specialDaysThisMonth.holidays > 0 {
                    glanceChip(
                        count: specialDaysThisMonth.holidays,
                        label: specialDaysThisMonth.holidays == 1 ? "holiday" : "holidays",
                        detail: "this month",
                        color: SpecialDayType.holiday.accentColor
                    )
                }

                // Contacts (only if non-zero)
                if contacts.count > 0 {
                    glanceChip(
                        count: contacts.count,
                        label: contacts.count == 1 ? "contact" : "contacts",
                        detail: nil,
                        color: PageHeaderColor.contacts.accent
                    )
                }

                // Expenses (only if non-zero)
                if allExpenses.count > 0 {
                    glanceChip(
                        count: allExpenses.count,
                        label: allExpenses.count == 1 ? "expense" : "expenses",
                        detail: nil,
                        color: SpecialDayType.expense.accentColor
                    )
                }

                // Trips (only if non-zero)
                if allTrips.count > 0 {
                    glanceChip(
                        count: allTrips.count,
                        label: allTrips.count == 1 ? "trip" : "trips",
                        detail: nil,
                        color: SpecialDayType.trip.accentColor
                    )
                }

                // If everything is zero, show a neutral message
                if specialDaysThisMonth.holidays == 0 && contacts.count == 0 && allExpenses.count == 0 && allTrips.count == 0 {
                    Text("No tracked items")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .background(JohoColors.white)
    }

    /// Glance chip with count and label
    private func glanceChip(count: Int, label: String, detail: String?, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .clipShape(Capsule())

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black)

            if let detail = detail {
                Text(detail)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(colors.secondary)
            }
        }
    }

    // MARK: - iPad Glance Section (情報デザイン: Large bento tiles)

    /// GLANCE section - 2x3 grid of large bento tiles with key stats
    private var iPadGlanceSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "snowflake")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.cyan)
                Text("GLANCE")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // 2x3 Grid of large bento tiles
            HStack(spacing: 0) {
                // Row 1
                largeBentoTile(icon: "calendar", label: "W\(weekNumber)", subtitle: "WEEK", color: PageHeaderColor.calendar.accent, bg: PageHeaderColor.calendar.lightBackground)

                Rectangle().fill(JohoColors.black).frame(width: 1.5)

                largeBentoTile(icon: currentMonthTheme.icon, label: String(currentMonthTheme.name.prefix(3)).uppercased(), subtitle: "MONTH", color: currentMonthTheme.accentColor, bg: currentMonthTheme.lightBackground)

                Rectangle().fill(JohoColors.black).frame(width: 1.5)

                largeBentoTile(icon: "person.2.fill", label: "\(contacts.count)", subtitle: "CONTACTS", color: PageHeaderColor.contacts.accent, bg: PageHeaderColor.contacts.lightBackground)
            }
            .frame(maxHeight: .infinity)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            HStack(spacing: 0) {
                // Row 2
                largeBentoTile(icon: "dollarsign.circle.fill", label: "\(allExpenses.count)", subtitle: "EXPENSES", color: SpecialDayType.expense.accentColor, bg: SpecialDayType.expense.lightBackground)

                Rectangle().fill(JohoColors.black).frame(width: 1.5)

                largeBentoTile(icon: "airplane", label: "\(allTrips.count)", subtitle: "TRIPS", color: SpecialDayType.trip.accentColor, bg: SpecialDayType.trip.lightBackground)

                Rectangle().fill(JohoColors.black).frame(width: 1.5)

                largeBentoTile(icon: "star.fill", label: "\(specialDaysThisMonth.holidays)", subtitle: "HOLIDAYS", color: SpecialDayType.holiday.accentColor, bg: SpecialDayType.holiday.lightBackground)
            }
            .frame(maxHeight: .infinity)
        }
        .background(JohoColors.white)
    }

    /// Large bento tile for GLANCE section
    private func largeBentoTile(icon: String, label: String, subtitle: String, color: Color, bg: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(bg)
                .clipShape(Squircle(cornerRadius: 10))
                .overlay(Squircle(cornerRadius: 10).stroke(JohoColors.black, lineWidth: 1.5))

            Text(label)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.black)

            Text(subtitle)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.white)
    }

    // MARK: - iPad Agenda Section (情報デザイン: Card styling)

    /// AGENDA section - Today's items + This Week in card format
    private var iPadAgendaSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle().fill(JohoColors.yellow).frame(width: 10, height: 10)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                Text("AGENDA")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)
                Spacer()
                if !todayItems.isEmpty || !upcomingItems.isEmpty {
                    Text("\(todayItems.count + upcomingItems.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            if todayItems.isEmpty && upcomingItems.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(colors.secondary.opacity(0.3))
                    Text("All clear")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                    Text("No events today or this week")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(colors.secondary.opacity(0.6))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // TODAY section
                        if !todayItems.isEmpty {
                            HStack {
                                Text("TODAY")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(JohoColors.yellow)
                                Spacer()
                            }
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.top, JohoDimensions.spacingSM)

                            ForEach(todayItems.prefix(5), id: \.id) { item in
                                agendaTodayCard(item)
                            }
                        }

                        // THIS WEEK section
                        if !upcomingItems.isEmpty {
                            HStack {
                                Text("THIS WEEK")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(JohoColors.cyan)
                                Spacer()
                            }
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.top, todayItems.isEmpty ? JohoDimensions.spacingSM : JohoDimensions.spacingMD)

                            ForEach(upcomingItems.prefix(6), id: \.id) { item in
                                agendaUpcomingCard(item)
                            }
                        }
                    }
                    .padding(.bottom, JohoDimensions.spacingSM)
                }
            }
        }
        .background(JohoColors.white)
    }

    /// Agenda card for TodayItem (情報デザイン: Bento compartments)
    private func agendaTodayCard(_ item: TodayItem) -> some View {
        HStack(spacing: 0) {
            // LEFT: Type indicator (32pt)
            Circle()
                .fill(item.color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                .frame(width: 32)

            // WALL
            Rectangle().fill(JohoColors.black).frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Title
            Text(item.title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .lineLimit(1)
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

            // WALL
            Rectangle().fill(JohoColors.black).frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT: Icon + Badge (64pt)
            HStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(item.color)
                    .frame(width: 22, height: 22)
                    .background(item.color.opacity(0.2))
                    .clipShape(Squircle(cornerRadius: 5))
                    .overlay(Squircle(cornerRadius: 5).stroke(JohoColors.black, lineWidth: 1))

                Text(item.typeBadge)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(item.color)
                    .clipShape(Capsule())
            }
            .frame(width: 64)
        }
        .frame(height: 40)
        .background(JohoColors.white)
        .overlay(
            Rectangle().fill(JohoColors.black.opacity(0.15)).frame(height: 1),
            alignment: .bottom
        )
        .padding(.horizontal, JohoDimensions.spacingXS)
    }

    /// Agenda card for UpcomingItem (情報デザイン: Bento compartments)
    private func agendaUpcomingCard(_ item: UpcomingItem) -> some View {
        HStack(spacing: 0) {
            // LEFT: Type indicator (32pt)
            Circle()
                .fill(item.color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                .frame(width: 32)

            // WALL
            Rectangle().fill(JohoColors.black).frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Title + Date
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)
                Text(item.date.formatted(.dateTime.weekday(.abbreviated).day()))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.secondary)
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, alignment: .leading)

            // WALL
            Rectangle().fill(JohoColors.black).frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT: Icon + Badge (64pt)
            HStack(spacing: 4) {
                Image(systemName: iconForBadge(item.typeBadge))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(item.color)
                    .frame(width: 22, height: 22)
                    .background(item.color.opacity(0.2))
                    .clipShape(Squircle(cornerRadius: 5))
                    .overlay(Squircle(cornerRadius: 5).stroke(JohoColors.black, lineWidth: 1))

                Text(item.typeBadge)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(item.color)
                    .clipShape(Capsule())
            }
            .frame(width: 64)
        }
        .frame(height: 40)
        .background(JohoColors.white)
        .overlay(
            Rectangle().fill(JohoColors.black.opacity(0.15)).frame(height: 1),
            alignment: .bottom
        )
        .padding(.horizontal, JohoDimensions.spacingXS)
    }

    /// Helper to get icon for type badge
    private func iconForBadge(_ badge: String) -> String {
        switch badge {
        case "HOL": return "star.fill"
        case "OBS": return "sparkles"
        case "BDY": return "birthday.cake.fill"
        case "EVT": return "calendar.badge.clock"
        case "NTE": return "note.text"
        case "TRP": return "airplane"
        case "EXP": return "dollarsign.circle.fill"
        default: return "circle.fill"
        }
    }

    // MARK: - iPad Discover Section (情報デザイン: Star page style bento rows)

    /// DISCOVER section - Random events in Star page bento row style
    private var iPadDiscoverSection: some View {
        VStack(spacing: 0) {
            // HEADER: DISCOVER + Year + Shuffle
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.yellow)
                Text("DISCOVER")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)

                Spacer()

                // Year badge
                Text(String(year))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                Spacer()

                Button(action: shuffleDiscovery) {
                    HStack(spacing: 4) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 10, weight: .bold))
                        Text("SHUFFLE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(JohoColors.black)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // CONTENT: Star page style bento rows - fills all space
            GeometryReader { geo in
                let rowCount = 8
                let dividerHeight: CGFloat = 1
                let totalDividers = CGFloat(rowCount - 1)
                let rowHeight = (geo.size.height - (totalDividers * dividerHeight)) / CGFloat(rowCount)

                HStack(spacing: 0) {
                    // LEFT COLUMN
                    VStack(spacing: 0) {
                        ForEach(0..<rowCount, id: \.self) { index in
                            if index > 0 {
                                Rectangle().fill(JohoColors.black).frame(height: dividerHeight)
                            }
                            if index < discoveryItems.count {
                                discoveryBentoRow(discoveryItems[index])
                                    .frame(height: rowHeight)
                            } else {
                                emptyDiscoveryBentoRow()
                                    .frame(height: rowHeight)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // VERTICAL WALL
                    Rectangle().fill(JohoColors.black).frame(width: 2)

                    // RIGHT COLUMN
                    VStack(spacing: 0) {
                        ForEach(0..<rowCount, id: \.self) { index in
                            if index > 0 {
                                Rectangle().fill(JohoColors.black).frame(height: dividerHeight)
                            }
                            let itemIndex = index + rowCount
                            if itemIndex < discoveryItems.count {
                                discoveryBentoRow(discoveryItems[itemIndex])
                                    .frame(height: rowHeight)
                            } else {
                                emptyDiscoveryBentoRow()
                                    .frame(height: rowHeight)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .id(discoveryShuffleID)
        }
        .background(JohoColors.white)
    }

    /// Star page style bento row for discovery items
    private func discoveryBentoRow(_ item: DiscoveryItem) -> some View {
        Button(action: {
            navigateToDate = item.date
            shouldNavigateToCalendar = true
            HapticManager.selection()
        }) {
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Type indicator (32pt, centered)
                Circle()
                    .fill(item.type.color)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                    .frame(width: 32)
                    .frame(maxHeight: .infinity)

                // WALL
                Rectangle().fill(JohoColors.black).frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // CENTER COMPARTMENT: Title + Date (flexible)
                HStack(spacing: JohoDimensions.spacingXS) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(item.formattedDate)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(colors.secondary)
                }
                .padding(.horizontal, 8)
                .frame(maxHeight: .infinity)

                // WALL
                Rectangle().fill(JohoColors.black).frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT COMPARTMENT: Icon + Badge (72pt)
                HStack(spacing: 4) {
                    Image(systemName: item.type.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(item.type.color)
                        .frame(width: 22, height: 22)
                        .background(item.type.background)
                        .clipShape(Squircle(cornerRadius: 5))
                        .overlay(Squircle(cornerRadius: 5).stroke(JohoColors.black, lineWidth: 1))

                    Text(item.type.badge)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(item.type.color)
                        .clipShape(Capsule())
                }
                .frame(width: 72, alignment: .center)
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(JohoColors.white)
        }
        .buttonStyle(.plain)
    }

    /// Empty bento row placeholder
    private func emptyDiscoveryBentoRow() -> some View {
        HStack(spacing: 0) {
            // LEFT COMPARTMENT
            Circle()
                .fill(JohoColors.black.opacity(0.1))
                .frame(width: 10, height: 10)
                .frame(width: 32)
                .frame(maxHeight: .infinity)

            Rectangle().fill(JohoColors.black).frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER
            Text("...")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(colors.secondary.opacity(0.3))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle().fill(JohoColors.black).frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT
            Color.clear.frame(width: 72)
                .frame(maxHeight: .infinity)
        }
        .background(JohoColors.white)
    }

    // MARK: - iPad Portrait Layout (情報デザイン: Vertical hierarchy)

    /// Portrait layout: GLANCE (top) → AGENDA (middle) → DISCOVER (bottom)
    private var iPadPortraitLayout: some View {
        VStack(spacing: 0) {
            // TOP: GLANCE section (fixed height)
            iPadGlanceSection
                .frame(height: 180)

            Rectangle().fill(JohoColors.black).frame(height: 2)

            // MIDDLE: Side-by-side Agenda + Discover preview
            HStack(spacing: 0) {
                // LEFT: Compact Agenda
                VStack(spacing: 0) {
                    HStack {
                        Circle().fill(JohoColors.yellow).frame(width: 8, height: 8)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                        Text("AGENDA")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1)
                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .padding(.vertical, JohoDimensions.spacingXS)

                    Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

                    if todayItems.isEmpty && upcomingItems.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(colors.secondary.opacity(0.3))
                            Text("All clear")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.secondary)
                            Spacer()
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(todayItems.prefix(3), id: \.id) { item in
                                    agendaTodayItemRow(item)
                                }
                                ForEach(upcomingItems.prefix(3), id: \.id) { item in
                                    agendaUpcomingItemRow(item)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle().fill(JohoColors.black).frame(width: 1.5)

                // RIGHT: Compact Discover
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(JohoColors.yellow)
                        Text("DISCOVER")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1)
                        Spacer()
                        Button(action: shuffleDiscovery) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(JohoColors.black)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .padding(.vertical, JohoDimensions.spacingXS)

                    Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

                    // Compact discover rows - anchored to top
                    VStack(spacing: 0) {
                        ForEach(discoveryItems.prefix(5), id: \.id) { item in
                            compactDiscoverRow(item)
                            if item.id != discoveryItems.prefix(5).last?.id {
                                Rectangle().fill(JohoColors.black.opacity(0.2)).frame(height: 1)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }

    /// Compact discover row for portrait
    private func compactDiscoverRow(_ item: DiscoveryItem) -> some View {
        Button(action: {
            navigateToDate = item.date
            shouldNavigateToCalendar = true
            HapticManager.selection()
        }) {
            HStack(spacing: JohoDimensions.spacingXS) {
                Circle()
                    .fill(item.type.color)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))

                Text(item.title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                Spacer()

                Text(item.type.badge)
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(item.type.color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    // MARK: - iPad Portrait Layout (情報デザイン: Vertical stack for portrait)

    /// Portrait-specific content: Calendar on top, Agenda + Glance below
    private var iPadPortraitContent: some View {
        VStack(spacing: 0) {
            // TOP: Calendar (compact, fills width, reasonable height)
            iPadCalendarColumn
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)

            // Horizontal divider
            Rectangle().fill(JohoColors.black).frame(height: 2)

            // BOTTOM: 2-column grid (Agenda + Glance side by side)
            HStack(spacing: 0) {
                // LEFT: Agenda section
                iPadPortraitAgenda
                    .frame(maxWidth: .infinity)

                // Vertical wall
                Rectangle().fill(JohoColors.black).frame(width: 1.5)

                // RIGHT: Glance section
                iPadPortraitGlance
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 200)
        }
    }

    /// Portrait Agenda section (compact version)
    private var iPadPortraitAgenda: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle().fill(JohoColors.yellow).frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                Text("AGENDA")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1)
                Spacer()
                if !todayItems.isEmpty || !upcomingItems.isEmpty {
                    Text("\(todayItems.count + upcomingItems.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.vertical, JohoDimensions.spacingXS)

            Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

            if todayItems.isEmpty && upcomingItems.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(colors.secondary.opacity(0.4))
                    Text("All clear")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if !todayItems.isEmpty {
                            HStack {
                                Text("TODAY")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(JohoColors.yellow)
                                Spacer()
                            }
                            .padding(.horizontal, JohoDimensions.spacingSM)
                            .padding(.top, 4)

                            ForEach(todayItems.prefix(4), id: \.id) { item in
                                agendaTodayItemRow(item)
                            }
                        }

                        if !upcomingItems.isEmpty {
                            HStack {
                                Text("THIS WEEK")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(JohoColors.cyan)
                                Spacer()
                            }
                            .padding(.horizontal, JohoDimensions.spacingSM)
                            .padding(.top, todayItems.isEmpty ? 4 : 8)

                            ForEach(upcomingItems.prefix(4), id: \.id) { item in
                                agendaUpcomingItemRow(item)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.white)
    }

    /// Portrait Glance section (vertical tile stack)
    private var iPadPortraitGlance: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "snowflake")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(JohoColors.cyan)
                Text("GLANCE")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.vertical, JohoDimensions.spacingXS)

            Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

            // Glance tiles in 2x3 grid for portrait
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                compactGlanceTile(icon: "calendar", label: "W\(weekNumber)", color: PageHeaderColor.calendar.accent, bg: PageHeaderColor.calendar.lightBackground)
                compactGlanceTile(icon: currentMonthTheme.icon, label: String(currentMonthTheme.name.prefix(3)).uppercased(), color: currentMonthTheme.accentColor, bg: currentMonthTheme.lightBackground)
                compactGlanceTile(icon: "dollarsign.circle.fill", label: "\(allExpenses.count)", color: SpecialDayType.expense.accentColor, bg: SpecialDayType.expense.lightBackground)
                compactGlanceTile(icon: "person.2.fill", label: "\(contacts.count)", color: PageHeaderColor.contacts.accent, bg: PageHeaderColor.contacts.lightBackground)
                compactGlanceTile(icon: "airplane", label: "\(allTrips.count)", color: SpecialDayType.trip.accentColor, bg: SpecialDayType.trip.lightBackground)
                compactGlanceTile(icon: "star.fill", label: "\(specialDaysThisMonth.holidays)", color: SpecialDayType.holiday.accentColor, bg: SpecialDayType.holiday.lightBackground)
            }
            .padding(JohoDimensions.spacingSM)
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.white)
    }

    // MARK: - iPad Discovery Grid (情報デザイン: Dense list rows like iPhone)

    /// Discovery Grid - 情報デザイン compliant with dense list rows
    /// Styled like iPhone todayCard but scaled for iPad
    private var iPadDiscoveryGrid: some View {
        VStack(spacing: 0) {
            // HEADER: DISCOVER + Year + Shuffle
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.yellow)
                Text("DISCOVER")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)

                Spacer()

                // Year prominently displayed
                Text(String(year))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                Spacer()

                Button(action: shuffleDiscovery) {
                    HStack(spacing: 4) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 11, weight: .bold))
                        Text("SHUFFLE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(JohoColors.black)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Thick wall
            Rectangle().fill(JohoColors.black).frame(height: 3)

            // CONTENT: Dense list rows in columns - FILLS ALL SPACE
            GeometryReader { geo in
                let rowCount = 10
                let dividerHeight: CGFloat = 1
                let totalDividers = CGFloat(rowCount - 1)
                let rowHeight = (geo.size.height - (totalDividers * dividerHeight)) / CGFloat(rowCount)

                HStack(spacing: 0) {
                    // LEFT COLUMN - First half of items
                    VStack(spacing: 0) {
                        ForEach(0..<rowCount, id: \.self) { index in
                            if index > 0 {
                                Rectangle().fill(JohoColors.black).frame(height: dividerHeight)
                            }
                            if index < discoveryItems.count {
                                discoveryListRow(discoveryItems[index])
                                    .frame(height: rowHeight)
                            } else {
                                emptyDiscoveryRow()
                                    .frame(height: rowHeight)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // VERTICAL WALL
                    Rectangle().fill(JohoColors.black).frame(width: 3)

                    // RIGHT COLUMN - Second half of items
                    VStack(spacing: 0) {
                        ForEach(0..<rowCount, id: \.self) { index in
                            if index > 0 {
                                Rectangle().fill(JohoColors.black).frame(height: dividerHeight)
                            }
                            let itemIndex = index + rowCount
                            if itemIndex < discoveryItems.count {
                                discoveryListRow(discoveryItems[itemIndex])
                                    .frame(height: rowHeight)
                            } else {
                                emptyDiscoveryRow()
                                    .frame(height: rowHeight)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .id(discoveryShuffleID)
        }
        .background(JohoColors.white)
    }

    /// Dense discovery list row - like iPhone todayItemRow
    private func discoveryListRow(_ item: DiscoveryItem) -> some View {
        Button(action: {
            navigateToDate = item.date
            shouldNavigateToCalendar = true
            HapticManager.selection()
        }) {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Type indicator dot
                Circle()
                    .fill(item.type.color)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))

                // Icon
                Image(systemName: item.type.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(item.type.color)
                    .frame(width: 28, height: 28)
                    .background(item.type.background)
                    .clipShape(Squircle(cornerRadius: 6))
                    .overlay(Squircle(cornerRadius: 6).stroke(JohoColors.black, lineWidth: 1))

                // Date + Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.formattedDate)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .lineLimit(1)
                }

                Spacer()

                // Year badge
                Text(item.yearString)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(JohoColors.cream)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(JohoColors.black, lineWidth: 0.5))

                // Type badge
                Text(item.type.badge)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.type.color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(JohoColors.white)
        }
        .buttonStyle(.plain)
    }

    /// Empty discovery row placeholder
    private func emptyDiscoveryRow() -> some View {
        HStack {
            Circle()
                .fill(colors.secondary.opacity(0.2))
                .frame(width: 10, height: 10)
            Rectangle()
                .fill(colors.secondary.opacity(0.1))
                .frame(height: 12)
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.cream.opacity(0.3))
    }

    /// Sidebar for landscape mode - Glance + Agenda
    private var iPadSidebar: some View {
        VStack(spacing: 0) {
            // GLANCE section
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "snowflake")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(JohoColors.cyan)
                    Text("GLANCE")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1)
                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.vertical, JohoDimensions.spacingXS)

                Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

                // Compact glance tiles
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    compactGlanceTile(icon: "calendar", label: "W\(weekNumber)", color: PageHeaderColor.calendar.accent, bg: PageHeaderColor.calendar.lightBackground)
                    compactGlanceTile(icon: currentMonthTheme.icon, label: String(currentMonthTheme.name.prefix(3)).uppercased(), color: currentMonthTheme.accentColor, bg: currentMonthTheme.lightBackground)
                    compactGlanceTile(icon: "dollarsign.circle.fill", label: "\(allExpenses.count)", color: SpecialDayType.expense.accentColor, bg: SpecialDayType.expense.lightBackground)
                    compactGlanceTile(icon: "person.2.fill", label: "\(contacts.count)", color: PageHeaderColor.contacts.accent, bg: PageHeaderColor.contacts.lightBackground)
                }
                .padding(JohoDimensions.spacingXS)
            }
            .frame(height: 110)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // AGENDA section
            VStack(spacing: 0) {
                HStack {
                    Circle().fill(JohoColors.yellow).frame(width: 8, height: 8)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                    Text("AGENDA")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1)
                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.vertical, JohoDimensions.spacingXS)

                Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

                if todayItems.isEmpty && upcomingItems.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(colors.secondary.opacity(0.4))
                        Text("All clear")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(todayItems.prefix(3), id: \.id) { item in
                                agendaTodayItemRow(item)
                            }
                            ForEach(upcomingItems.prefix(4), id: \.id) { item in
                                agendaUpcomingItemRow(item)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.white)
    }

    /// Portrait Discovery layout - stacked vertically
    private var iPadPortraitDiscovery: some View {
        VStack(spacing: 0) {
            // TOP: Discovery Grid (main focus)
            iPadDiscoveryGrid
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)

            // Horizontal divider
            Rectangle().fill(JohoColors.black).frame(height: 2)

            // BOTTOM: Glance + Agenda side by side
            HStack(spacing: 0) {
                // Compact Glance
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "snowflake")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(JohoColors.cyan)
                        Text("GLANCE")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1)
                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .padding(.vertical, JohoDimensions.spacingXS)

                    Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        compactGlanceTile(icon: "calendar", label: "W\(weekNumber)", color: PageHeaderColor.calendar.accent, bg: PageHeaderColor.calendar.lightBackground)
                        compactGlanceTile(icon: currentMonthTheme.icon, label: String(currentMonthTheme.name.prefix(3)).uppercased(), color: currentMonthTheme.accentColor, bg: currentMonthTheme.lightBackground)
                        compactGlanceTile(icon: "dollarsign.circle.fill", label: "\(allExpenses.count)", color: SpecialDayType.expense.accentColor, bg: SpecialDayType.expense.lightBackground)
                        compactGlanceTile(icon: "person.2.fill", label: "\(contacts.count)", color: PageHeaderColor.contacts.accent, bg: PageHeaderColor.contacts.lightBackground)
                        compactGlanceTile(icon: "airplane", label: "\(allTrips.count)", color: SpecialDayType.trip.accentColor, bg: SpecialDayType.trip.lightBackground)
                        compactGlanceTile(icon: "star.fill", label: "\(specialDaysThisMonth.holidays)", color: SpecialDayType.holiday.accentColor, bg: SpecialDayType.holiday.lightBackground)
                    }
                    .padding(JohoDimensions.spacingSM)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(JohoColors.white)

                Rectangle().fill(JohoColors.black).frame(width: 1.5)

                // Compact Agenda
                iPadPortraitAgenda
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 130)
        }
    }

    // MARK: - iPad Bento Header (with clocks in subtitle)

    private var iPadBentoHeader: some View {
        let dayNumber = Calendar.iso8601.component(.day, from: today)
        let weekday = today.formatted(.dateTime.weekday(.abbreviated)).uppercased()

        return HStack(spacing: 0) {
            // LEFT: Icon + Title + Date
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: "house.fill")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(PageHeaderColor.landing.accent)
                    .frame(width: 40, height: 40)
                    .background(PageHeaderColor.landing.lightBackground)
                    .clipShape(Squircle(cornerRadius: 8))
                    .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(displayTitle)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)

                        // Year badge (情報デザイン: Year prominently displayed)
                        Text(String(year))
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(JohoColors.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(PageHeaderColor.calendar.accent)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 4) {
                        Text(String(dayNumber))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text(weekday)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                }
            }

            Spacer()

            // CENTER: World clocks display (actual times, not count)
            HStack(spacing: JohoDimensions.spacingMD) {
                ForEach(displayClocks, id: \.id) { clock in
                    HStack(spacing: 4) {
                        Text(clock.countryCode)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(JohoColors.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(TimezoneTheme.theme(for: clock.timezoneIdentifier).accentColor)
                            .clipShape(Capsule())
                        Text(clock.formattedTime)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(JohoColors.black)
                    }
                }
            }

            Spacer()

            // VERTICAL WALL
            Rectangle().fill(JohoColors.black).frame(width: 1.5)
                .padding(.vertical, JohoDimensions.spacingXS)

            // RIGHT: Week badge + Mascot
            HStack(spacing: JohoDimensions.spacingSM) {
                Text("W\(weekNumber)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(JohoColors.black)
                    .clipShape(Capsule())

                JohoMascot(mood: mascotMood, size: 36, borderWidth: 1.5, showBob: true, showBlink: true, autoOnsen: false)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.white)
    }

    // MARK: - iPad Bento Column Components

    /// Left column: Week strip (vertical days)
    private var iPadWeekColumn: some View {
        VStack(spacing: 0) {
            ForEach(weekDays, id: \.date) { day in
                if day.dayOfWeek > 1 {
                    Rectangle().fill(JohoColors.black.opacity(0.2)).frame(height: 1)
                }
                HStack(spacing: 6) {
                    Text(day.name)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(day.isToday ? JohoColors.yellow : colors.secondary)
                        .frame(width: 24)
                    Text(String(day.number))
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(day.isToday ? JohoColors.black : colors.primary)
                        .frame(width: 32, height: 32)
                        .background(day.isToday ? JohoColors.yellow : Color.clear)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(day.isToday ? JohoColors.black : Color.clear, lineWidth: 1))
                    // Indicators
                    HStack(spacing: 2) {
                        ForEach(day.indicators.prefix(3), id: \.self) { color in
                            Circle().fill(color).frame(width: 5, height: 5)
                                .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.white)
    }

    /// Center column: Calendar
    private var iPadCalendarColumn: some View {
        VStack(spacing: 0) {
            // Month header
            HStack {
                Button { navigateEmbeddedCalendar(by: -1); HapticManager.selection() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 44, height: 44)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text(embeddedMonthName)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Text(String(embeddedCalendarYear))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(colors.secondary)
                }
                Spacer()
                Button { navigateEmbeddedCalendar(by: 1); HapticManager.selection() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)

            Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

            // 情報デザイン: Day headers with GRID LINES
            HStack(spacing: 0) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(d == "S" ? JohoColors.red : JohoColors.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .overlay(
                            Rectangle().stroke(JohoColors.black, lineWidth: 1)
                        )
                }
            }

            // 情報デザイン: Calendar grid with GRID LINES on each cell
            VStack(spacing: 0) {
                ForEach(embeddedCalendarWeeks, id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.self) { day in
                            embeddedDayCellWithGrid(day)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.white)
    }

    /// Right column: AGENDA (merged Today+Upcoming) + GLANCE
    /// 情報デザイン: Glance moved UP, combined agenda view
    private var iPadRightColumn: some View {
        VStack(spacing: 0) {
            // AGENDA section (merged Today + Upcoming)
            VStack(spacing: 0) {
                // Header
                HStack {
                    Circle().fill(JohoColors.yellow).frame(width: 8, height: 8)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                    Text("AGENDA")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1)
                    Spacer()
                    if !todayItems.isEmpty || !upcomingItems.isEmpty {
                        Text("\(todayItems.count + upcomingItems.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.vertical, JohoDimensions.spacingXS)

                Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

                if todayItems.isEmpty && upcomingItems.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(colors.secondary.opacity(0.4))
                        Text("All clear")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // TODAY sub-section
                            if !todayItems.isEmpty {
                                HStack {
                                    Text("TODAY")
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .foregroundStyle(JohoColors.yellow)
                                        .tracking(0.5)
                                    Spacer()
                                }
                                .padding(.horizontal, JohoDimensions.spacingSM)
                                .padding(.top, JohoDimensions.spacingXS)
                                .padding(.bottom, 2)

                                ForEach(todayItems, id: \.id) { item in
                                    agendaTodayItemRow(item)
                                }
                            }

                            // THIS WEEK sub-section
                            if !upcomingItems.isEmpty {
                                HStack {
                                    Text("THIS WEEK")
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .foregroundStyle(JohoColors.cyan)
                                        .tracking(0.5)
                                    Spacer()
                                }
                                .padding(.horizontal, JohoDimensions.spacingSM)
                                .padding(.top, todayItems.isEmpty ? JohoDimensions.spacingXS : JohoDimensions.spacingSM)
                                .padding(.bottom, 2)

                                ForEach(upcomingItems.prefix(5), id: \.id) { item in
                                    agendaUpcomingItemRow(item)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Horizontal divider
            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // GLANCE section (moved UP from footer)
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "snowflake")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(JohoColors.cyan)
                    Text("GLANCE")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1)
                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.vertical, JohoDimensions.spacingXS)

                Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

                // Glance tiles in grid
                HStack(spacing: 6) {
                    compactGlanceTile(icon: "calendar", label: "W\(weekNumber)", color: PageHeaderColor.calendar.accent, bg: PageHeaderColor.calendar.lightBackground)
                    compactGlanceTile(icon: currentMonthTheme.icon, label: String(currentMonthTheme.name.prefix(3)).uppercased(), color: currentMonthTheme.accentColor, bg: currentMonthTheme.lightBackground)
                    compactGlanceTile(icon: "dollarsign.circle.fill", label: "\(allExpenses.count)", color: SpecialDayType.expense.accentColor, bg: SpecialDayType.expense.lightBackground)
                    compactGlanceTile(icon: "person.2.fill", label: "\(contacts.count)", color: PageHeaderColor.contacts.accent, bg: PageHeaderColor.contacts.lightBackground)
                    compactGlanceTile(icon: "airplane", label: "\(allTrips.count)", color: SpecialDayType.trip.accentColor, bg: SpecialDayType.trip.lightBackground)
                }
                .padding(JohoDimensions.spacingSM)
            }
            .frame(height: 90)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.white)
    }

    /// Agenda item row for TodayItem
    private func agendaTodayItemRow(_ item: TodayItem) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.color)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))

            Text(item.title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
                .lineLimit(1)

            Spacer()

            Text(item.typeBadge)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(item.color)
                .clipShape(Capsule())
        }
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.vertical, 4)
    }

    /// Agenda item row for UpcomingItem
    private func agendaUpcomingItemRow(_ item: UpcomingItem) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.color)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))

            Text(item.title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
                .lineLimit(1)

            Spacer()

            Text(item.dayName)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            Text(item.typeBadge)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(item.color)
                .clipShape(Capsule())
        }
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.vertical, 4)
    }

    /// Footer: PROGRESS bars only (Glance moved to right column)
    /// 情報デザイン: Progress takes full width with larger, more prominent bars
    private var iPadBentoFooter: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(JohoColors.cyan)
                Text("PROGRESS")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1)
                Spacer()
                // Show percentage of year complete
                Text("\(Int(yearProgress * 100))% of \(String(Calendar.iso8601.component(.year, from: Date())))")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.secondary)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingXS)

            Rectangle().fill(JohoColors.black.opacity(0.3)).frame(height: 1)

            // Progress bars - larger and more prominent
            HStack(spacing: JohoDimensions.spacingLG) {
                progressBarLarge(label: "YEAR", progress: yearProgress, color: JohoColors.cyan.opacity(0.5))
                progressBarLarge(label: "MONTH", progress: monthProgress, color: JohoColors.cyan)
                progressBarLarge(label: "WEEK", progress: weekProgress, color: JohoColors.cyan.opacity(0.7))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoColors.white)
    }

    /// Large progress bar for footer (情報デザイン: More prominent)
    private func progressBarLarge(label: String, progress: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(colors.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(colors.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colors.secondary.opacity(0.2))
                        .overlay(Capsule().stroke(JohoColors.black, lineWidth: 0.5))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
    }

    private func progressBarRow(label: String, progress: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
                .frame(width: 40, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(colors.secondary.opacity(0.2))
                    Capsule().fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(colors.primary)
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: - Compact Glance Tile (Used by iPad layouts)

    private func compactGlanceTile(icon: String, label: String, color: Color, bg: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.black)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(JohoColors.black, lineWidth: 1))
    }

    /// 情報デザイン: Day cell with GRID LINES (1pt black border)
    /// Inspired by Refills and Class Timetable apps
    private func embeddedDayCellWithGrid(_ day: EmbeddedCalendarDay) -> some View {
        let calendar = Calendar.iso8601
        let isSunday = calendar.component(.weekday, from: day.date) == 1

        return VStack(spacing: 2) {
            // Day number with highlight for today
            Text(String(day.dayNumber))
                .font(.system(size: 14, weight: day.isToday ? .black : .medium, design: .rounded))
                .foregroundStyle(
                    day.isToday ? JohoColors.black :
                    isSunday && day.isCurrentMonth ? JohoColors.red :
                    day.isCurrentMonth ? colors.primary : colors.secondary.opacity(0.3)
                )
                .frame(width: 28, height: 28)
                .background(day.isToday ? JohoColors.yellow : Color.clear)
                .clipShape(Circle())
                .overlay(Circle().stroke(day.isToday ? JohoColors.black : Color.clear, lineWidth: 1.5))

            // Event indicators
            if !day.indicators.isEmpty && day.isCurrentMonth {
                HStack(spacing: 2) {
                    ForEach(Array(day.indicators.prefix(3).enumerated()), id: \.offset) { _, color in
                        Circle().fill(color).frame(width: 5, height: 5)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                    }
                }
                .frame(height: 6)
            } else {
                Spacer().frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(day.isCurrentMonth ? JohoColors.white : JohoColors.cream.opacity(0.3))
        .overlay(
            Rectangle().stroke(JohoColors.black, lineWidth: 1)
        )
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
                        .font(.system(size: 20, weight: .bold, design: .rounded))
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

                // RIGHT COMPARTMENT: Subtle mascot (情報デザイン)
                // Light animations: blinking, eye movement - no distracting transforms
                JohoMascot(
                    mood: mascotMood,
                    size: 44,
                    borderWidth: 1.5,
                    showBob: true,      // Gentle bobbing
                    showBlink: true,    // Eye blinks
                    autoOnsen: false    // No ♨️ transformation
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
                .overlay(Capsule().stroke(colors.border, lineWidth: JohoDimensions.borderThin))

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
            return themes[region] ?? TimezoneTheme(region: "default", accentColor: Color(hex: "636E72"), lightBackground: Color(hex: "F0F2F3"))
        }
    }

    // MARK: - Today Card (Unified: Regular + Compact)

    /// Backwards-compatible wrapper for regular size
    private var todayCard: some View {
        todayCardView(size: .regular)
    }

    /// Unified Today Card with adaptive sizing
    private func todayCardView(size: JohoCardSize) -> some View {
        let isCompact = size == .compact

        return VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(JohoColors.yellow)
                    .frame(width: size.dotSize + 2, height: size.dotSize + 2)
                    .overlay(Circle().stroke(isCompact ? JohoColors.black : colors.border, lineWidth: 1))

                Text("TODAY")
                    .font(.system(size: size.headerFontSize, weight: .black, design: .rounded))
                    .tracking(isCompact ? 1 : 1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                if !todayItems.isEmpty {
                    Text("\(todayItems.count)")
                        .font(.system(size: size.labelFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }
            .padding(.horizontal, size.headerPadding)
            .padding(.vertical, isCompact ? JohoDimensions.spacingXS : JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: isCompact ? 1 : 1.5)

            // Content
            if todayItems.isEmpty {
                if isCompact {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(colors.secondary.opacity(0.4))
                        Text("All clear")
                            .font(.system(size: size.labelFontSize, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, JohoDimensions.spacingMD)
                } else {
                    Text("Nothing scheduled")
                        .font(JohoFont.body)
                        .foregroundStyle(colors.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(size.contentPadding)
                }
            } else {
                let content = VStack(spacing: 0) {
                    ForEach(Array(todayItems.prefix(size.maxItems).enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Rectangle()
                                .fill(colors.border.opacity(0.2))
                                .frame(height: 1)
                                .padding(.horizontal, size.contentPadding)
                        }
                        todayItemRowView(item, size: size)
                    }

                    if !isCompact && todayItems.count > size.maxItems {
                        Rectangle()
                            .fill(colors.border.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, size.contentPadding)

                        Text("+\(todayItems.count - size.maxItems) more")
                            .font(.system(size: size.labelFontSize, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, JohoDimensions.spacingSM)
                    }
                }

                if isCompact {
                    ScrollView { content }
                } else {
                    content
                }
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: size.cornerRadius))
        .overlay(
            Squircle(cornerRadius: size.cornerRadius)
                .stroke(isCompact ? JohoColors.black : colors.border, lineWidth: size.borderWidth)
        )
    }

    /// Unified today item row
    private func todayItemRowView(_ item: TodayItem, size: JohoCardSize) -> some View {
        let isCompact = size == .compact

        return HStack(spacing: isCompact ? 6 : JohoDimensions.spacingSM) {
            // Type indicator
            Circle()
                .fill(item.color)
                .frame(width: size.dotSize, height: size.dotSize)
                .overlay(Circle().stroke(isCompact ? JohoColors.black : colors.border, lineWidth: 1))

            // Icon
            Image(systemName: item.icon)
                .font(.system(size: size.iconSize, weight: .medium, design: .rounded))
                .foregroundStyle(item.color)
                .frame(width: isCompact ? 12 : 16)

            // Title
            Text(item.title)
                .font(.system(size: size.bodyFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
                .lineLimit(1)

            Spacer()

            // Type badge
            Text(item.typeBadge)
                .font(.system(size: size.badgeFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(item.color)
                .padding(.horizontal, isCompact ? 4 : 6)
                .padding(.vertical, isCompact ? 1 : 2)
                .background(item.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.horizontal, size.contentPadding)
        .padding(.vertical, size.itemSpacing)
    }

    /// Backwards-compatible wrapper for old todayItemRow calls
    private func todayItemRow(_ item: TodayItem) -> some View {
        todayItemRowView(item, size: .regular)
    }

    // MARK: - GLANCE Card (情報デザイン: Star Page Style Dashboard)

    private var glanceCard: some View {
        VStack(spacing: 0) {
            // Header with sparkle icon (情報デザイン: proper SF Symbol)
            HStack {
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.cyan)

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

            // 3x2 Grid - Star Page Style (情報デザイン: Centered icons, light backgrounds)
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

                    // TRIPS: Travel (情報デザイン: Orange zone)
                    sheetGlanceTile(
                        icon: "airplane",
                        label: "\(allTrips.count)",
                        indicator: activeTripsIndicator,
                        iconColor: SpecialDayType.trip.accentColor,
                        bgColor: SpecialDayType.trip.lightBackground
                    ) {
                        showTripsSheet = true
                    }
                }

                VStack(spacing: JohoDimensions.spacingSM) {
                    // EXPENSES: Money (情報デザイン: Green zone)
                    sheetGlanceTile(
                        icon: "dollarsign.circle.fill",
                        label: "\(allExpenses.count)",
                        indicator: expensesIndicator,
                        iconColor: SpecialDayType.expense.accentColor,
                        bgColor: SpecialDayType.expense.lightBackground
                    ) {
                        showExpensesSheet = true
                    }

                    // RANDOM STAT: Rotating insights (情報デザイン: User data, not settings)
                    randomStatGlanceTile(stat: currentRandomStat)
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

    // MARK: - UPCOMING Card (情報デザイン: Next 7 days overview)

    private var upcomingCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.cyan)

                Text("UPCOMING")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                if !upcomingItems.isEmpty {
                    Text("\(upcomingItems.count)")
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
            if upcomingItems.isEmpty {
                Text("Nothing in the next 7 days")
                    .font(JohoFont.body)
                    .foregroundStyle(colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(JohoDimensions.spacingMD)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(upcomingItems.prefix(5).enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Rectangle()
                                .fill(colors.border.opacity(0.2))
                                .frame(height: 1)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                        }

                        upcomingItemRow(item)
                    }

                    if upcomingItems.count > 5 {
                        Rectangle()
                            .fill(colors.border.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)

                        Text("+\(upcomingItems.count - 5) more")
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

    /// Upcoming item row
    private func upcomingItemRow(_ item: UpcomingItem) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Date badge
            VStack(spacing: 0) {
                Text(item.dayName)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                Text("\(item.dayNumber)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(item.isToday ? JohoColors.yellow : colors.primary)
            }
            .frame(width: 36)
            .padding(.vertical, 4)
            .background(item.isToday ? JohoColors.yellow.opacity(0.15) : colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(item.isToday ? JohoColors.yellow : colors.border.opacity(0.3), lineWidth: 1)
            )

            // Type indicator
            Circle()
                .fill(item.color)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))

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

    /// UpcomingItem model
    private struct UpcomingItem: Identifiable {
        let id = UUID()
        let date: Date
        let dayName: String
        let dayNumber: Int
        let isToday: Bool
        let title: String
        let color: Color
        let typeBadge: String
    }

    /// Get upcoming items for next 7 days
    private var upcomingItems: [UpcomingItem] {
        let calendar = Calendar.iso8601
        var items: [UpcomingItem] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: todayStart) else { continue }
            let dayName = date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
            let dayNumber = calendar.component(.day, from: date)
            let isToday = dayOffset == 0

            // Holidays
            if let holidays = holidayManager.holidayCache[date] {
                for holiday in holidays {
                    let color = holiday.isBankHoliday ? JohoColors.red : JohoColors.orange
                    let badge = holiday.isBankHoliday ? "HOL" : "OBS"
                    items.append(UpcomingItem(
                        date: date,
                        dayName: dayName,
                        dayNumber: dayNumber,
                        isToday: isToday,
                        title: holiday.displayTitle,
                        color: color,
                        typeBadge: badge
                    ))
                }
            }

            // Birthdays
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            for contact in contacts {
                guard let birthday = contact.birthday else { continue }
                let bMonth = calendar.component(.month, from: birthday)
                let bDay = calendar.component(.day, from: birthday)
                if bMonth == month && bDay == day {
                    let name = contact.displayName.isEmpty ? "Someone" : contact.displayName
                    items.append(UpcomingItem(
                        date: date,
                        dayName: dayName,
                        dayNumber: dayNumber,
                        isToday: isToday,
                        title: "\(name)'s Birthday",
                        color: JohoColors.pink,
                        typeBadge: "BDY"
                    ))
                }
            }

            // Countdown events
            for event in countdownEvents {
                let eventDate = calendar.startOfDay(for: event.targetDate)
                if eventDate == date {
                    items.append(UpcomingItem(
                        date: date,
                        dayName: dayName,
                        dayNumber: dayNumber,
                        isToday: isToday,
                        title: event.title,
                        color: JohoColors.cyan,
                        typeBadge: "EVT"
                    ))
                }
            }

            // Trips starting
            for trip in allTrips {
                let tripStart = calendar.startOfDay(for: trip.startDate)
                if tripStart == date {
                    items.append(UpcomingItem(
                        date: date,
                        dayName: dayName,
                        dayNumber: dayNumber,
                        isToday: isToday,
                        title: trip.tripName,
                        color: SpecialDayType.trip.accentColor,
                        typeBadge: "TRP"
                    ))
                }
            }
        }

        return items.sorted { $0.date < $1.date }
    }

    // MARK: - WEEK Card (情報デザイン: Mini week grid with indicators)

    private var weekCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "calendar.day.timeline.left")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.cyan)

                Text("WEEK \(weekNumber)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                Text(String(year))
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(colors.secondary)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Week grid
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.date) { day in
                    if day.dayOfWeek > 1 {
                        Rectangle()
                            .fill(colors.border.opacity(0.3))
                            .frame(width: 1)
                    }

                    weekDayCell(day)
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

    /// Week day cell
    private func weekDayCell(_ day: WeekDay) -> some View {
        VStack(spacing: 4) {
            // Day name
            Text(day.name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(day.isToday ? JohoColors.yellow : colors.secondary)

            // Day number
            Text("\(day.number)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(day.isToday ? colors.primaryInverted : colors.primary)
                .frame(width: 32, height: 32)
                .background(day.isToday ? JohoColors.yellow : Color.clear)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(day.isToday ? JohoColors.black : Color.clear, lineWidth: 1.5)
                )

            // Indicators
            HStack(spacing: 2) {
                ForEach(day.indicators.prefix(3), id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }

    /// WeekDay model
    private struct WeekDay {
        let date: Date
        let name: String
        let number: Int
        let dayOfWeek: Int
        let isToday: Bool
        let indicators: [Color]
    }

    /// Get current week days (Mon-Sun ISO8601)
    private var weekDays: [WeekDay] {
        let calendar = Calendar.iso8601
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            let name = date.formatted(.dateTime.weekday(.narrow)).uppercased()
            let number = calendar.component(.day, from: date)
            let dayOfWeek = calendar.component(.weekday, from: date)
            let isToday = calendar.isDateInToday(date)

            // Collect indicators for this day
            var indicators: [Color] = []

            // Holidays
            if let holidays = holidayManager.holidayCache[dayStart] {
                for holiday in holidays {
                    indicators.append(holiday.isBankHoliday ? JohoColors.red : JohoColors.orange)
                }
            }

            // Birthdays
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            for contact in contacts {
                guard let birthday = contact.birthday else { continue }
                if calendar.component(.month, from: birthday) == month &&
                   calendar.component(.day, from: birthday) == day {
                    indicators.append(JohoColors.pink)
                }
            }

            // Countdown events
            for event in countdownEvents {
                if calendar.startOfDay(for: event.targetDate) == dayStart {
                    indicators.append(JohoColors.cyan)
                }
            }

            // Active trips
            for trip in allTrips {
                let tripStart = calendar.startOfDay(for: trip.startDate)
                let tripEnd = calendar.startOfDay(for: trip.endDate)
                if dayStart >= tripStart && dayStart <= tripEnd {
                    indicators.append(SpecialDayType.trip.accentColor)
                }
            }

            return WeekDay(
                date: date,
                name: name,
                number: number,
                dayOfWeek: dayOfWeek,
                isToday: isToday,
                indicators: indicators
            )
        }
    }

    // MARK: - PROGRESS Card (情報デザイン: Time progress visualization)

    private var progressCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.green)

                Text("PROGRESS")
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

            // Progress bars
            VStack(spacing: JohoDimensions.spacingSM) {
                progressRow(label: "YEAR", progress: yearProgress, color: JohoColors.green)
                progressRow(label: "MONTH", progress: monthProgress, color: currentMonthTheme.accentColor)
                progressRow(label: "WEEK", progress: weekProgress, color: JohoColors.cyan)
            }
            .padding(JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    /// Progress row with bar
    private func progressRow(label: String, progress: Double, color: Color) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
                .frame(width: 44, alignment: .leading)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(colors.border.opacity(0.2))

                    // Fill
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 12)

            // Percentage
            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 36, alignment: .trailing)
        }
    }

    /// Year progress (0.0 - 1.0)
    private var yearProgress: Double {
        let calendar = Calendar.iso8601
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: today)?.count ?? 365
        return Double(dayOfYear) / Double(daysInYear)
    }

    /// Month progress (0.0 - 1.0)
    private var monthProgress: Double {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: today)
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        return Double(dayOfMonth) / Double(daysInMonth)
    }

    /// Week progress (0.0 - 1.0)
    private var weekProgress: Double {
        let calendar = Calendar.iso8601
        let dayOfWeek = calendar.component(.weekday, from: today)
        // ISO8601: Monday = 2, Sunday = 1 (wrap to 7)
        let isoDayOfWeek = dayOfWeek == 1 ? 7 : dayOfWeek - 1
        return Double(isoDayOfWeek) / 7.0
    }

    /// Special days indicator matching Star page format (●red ○pink)
    private var specialDaysIndicator: String? {
        let (holidays, observances, birthdays) = specialDaysThisMonth
        if holidays == 0 && observances == 0 && birthdays == 0 { return nil }
        var parts: [String] = []
        if holidays > 0 { parts.append("●\(holidays)") }  // Red holidays
        if observances > 0 { parts.append("○\(observances)") }  // Orange observances
        if birthdays > 0 { parts.append("○\(birthdays)") }  // Pink birthdays
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

    /// Active trips indicator (情報デザイン: ✈ symbol)
    private var activeTripsIndicator: String? {
        let today = Calendar.iso8601.startOfDay(for: Date())
        let active = allTrips.filter { trip in
            let start = Calendar.iso8601.startOfDay(for: trip.startDate)
            let end = Calendar.iso8601.startOfDay(for: trip.endDate)
            return start <= today && today <= end
        }.count
        if active > 0 { return "✈ \(active)" }

        // Check for upcoming trips in next 7 days
        let upcoming = allTrips.filter { trip in
            let start = Calendar.iso8601.startOfDay(for: trip.startDate)
            let daysUntil = Calendar.iso8601.dateComponents([.day], from: today, to: start).day ?? 0
            return daysUntil > 0 && daysUntil <= 7
        }.count
        if upcoming > 0 { return "→ \(upcoming)" }
        return nil
    }

    /// Expenses indicator (情報デザイン: this month total)
    private var expensesIndicator: String? {
        let calendar = Calendar.iso8601
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let thisMonthExpenses = allExpenses.filter { $0.date >= startOfMonth }
        if thisMonthExpenses.isEmpty { return nil }
        let total = thisMonthExpenses.reduce(into: 0.0) { result, expense in
            result += expense.amount
        }
        return "¤\(Int(total))"
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
                    .font(.system(size: 32, weight: .bold, design: .rounded))
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
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            // 情報デザイン: Every element MUST have a border - 1pt for cells
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(target.label): \(label)")
    }

    /// Sheet-based GLANCE tile for Trips and Expenses (情報デザイン)
    /// Same visual style as starStyleGlanceTile but with custom action
    private func sheetGlanceTile(
        icon: String,
        label: String,
        indicator: String?,
        iconColor: Color,
        bgColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.impact(.light)
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(iconColor)

                Text(label)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                if let indicator = indicator {
                    Text(indicator)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                } else {
                    Text("—")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            // 情報デザイン: Every element MUST have a border - 1pt for cells
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
            )
        }
        .buttonStyle(.plain)
    }

    /// Display-only GLANCE tile for random stats (情報デザイン: Information, not navigation)
    /// Tappable to cycle through different stats
    private func randomStatGlanceTile(stat: RandomStat) -> some View {
        Button {
            HapticManager.impact(.light)
            // Cycle to next stat on tap
            withAnimation(.easeInOut(duration: 0.2)) {
                randomStatIndex = (randomStatIndex + 1) % max(1, availableRandomStats.count)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: stat.icon)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(stat.iconColor)

                Text(stat.label)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                if let indicator = stat.indicator {
                    Text(indicator)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                } else {
                    Text("—")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(stat.bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            // 情報デザイン: Every element MUST have a border - 1pt for cells
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Random stat: \(stat.label) \(stat.indicator ?? "")")
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
                let color = holiday.isBankHoliday ? JohoColors.red : JohoColors.orange
                let badge = holiday.isBankHoliday ? "HOL" : "OBS"
                items.append(TodayItem(
                    title: holiday.displayTitle,
                    subtitle: nil,
                    icon: holiday.isBankHoliday ? "star.fill" : "sparkles",
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
                    color: JohoColors.cyan,
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

    // MARK: - Embedded Calendar Card (情報デザイン: iPad Combined View)

    @State private var embeddedCalendarMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var embeddedCalendarYear: Int = Calendar.current.component(.year, from: Date())

    private var embeddedCalendarCard: some View {
        VStack(spacing: 0) {
            // Header with month navigation
            HStack {
                Button {
                    navigateEmbeddedCalendar(by: -1)
                    HapticManager.selection()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(embeddedMonthName)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                    Text(String(embeddedCalendarYear))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }

                Spacer()

                Button {
                    navigateEmbeddedCalendar(by: 1)
                    HapticManager.selection()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.vertical, JohoDimensions.spacingXS)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Day headers
            HStack(spacing: 0) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, JohoDimensions.spacingXS)

            // Divider
            Rectangle()
                .fill(colors.border.opacity(0.3))
                .frame(height: 1)

            // Calendar grid
            VStack(spacing: 2) {
                ForEach(embeddedCalendarWeeks, id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.self) { day in
                            embeddedDayCell(day)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.vertical, JohoDimensions.spacingSM)
            .padding(.horizontal, JohoDimensions.spacingXS)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Footer - tap to open full calendar
            Button {
                HapticManager.impact(.light)
                NotificationCenter.default.post(name: .navigateToPage, object: SidebarSelection.calendar)
            } label: {
                HStack {
                    Text("Open Full Calendar")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.secondary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, JohoDimensions.spacingSM)
            }
            .buttonStyle(.plain)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    /// Month name for embedded calendar
    private var embeddedMonthName: String {
        let dateComponents = DateComponents(year: embeddedCalendarYear, month: embeddedCalendarMonth, day: 1)
        guard let date = Calendar.current.date(from: dateComponents) else { return "" }
        return date.formatted(.dateTime.month(.wide)).uppercased()
    }

    /// Navigate embedded calendar by months
    private func navigateEmbeddedCalendar(by months: Int) {
        var newMonth = embeddedCalendarMonth + months
        var newYear = embeddedCalendarYear

        if newMonth > 12 {
            newMonth = 1
            newYear += 1
        } else if newMonth < 1 {
            newMonth = 12
            newYear -= 1
        }

        embeddedCalendarMonth = newMonth
        embeddedCalendarYear = newYear
    }

    /// Generate weeks for embedded calendar
    private var embeddedCalendarWeeks: [[EmbeddedCalendarDay]] {
        let calendar = Calendar.iso8601
        var weeks: [[EmbeddedCalendarDay]] = []

        // Get first day of month
        guard let firstOfMonth = calendar.date(from: DateComponents(year: embeddedCalendarYear, month: embeddedCalendarMonth, day: 1)),
              calendar.range(of: .day, in: .month, for: firstOfMonth) != nil else {
            return []
        }

        // Find the Monday of the week containing the 1st
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromMonday = (firstWeekday + 5) % 7  // Convert Sunday=1 to Monday-based

        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: firstOfMonth) else {
            return []
        }

        // Generate 6 weeks (covers all month layouts)
        var currentDate = weekStart
        for _ in 0..<6 {
            var week: [EmbeddedCalendarDay] = []
            for _ in 0..<7 {
                let dayNum = calendar.component(.day, from: currentDate)
                let monthNum = calendar.component(.month, from: currentDate)
                let isCurrentMonth = monthNum == embeddedCalendarMonth
                let isToday = calendar.isDateInToday(currentDate)
                let dayStart = calendar.startOfDay(for: currentDate)

                // Collect indicators
                var indicators: [Color] = []

                // Holidays
                if let holidays = holidayManager.holidayCache[dayStart] {
                    for holiday in holidays {
                        indicators.append(holiday.isBankHoliday ? JohoColors.red : JohoColors.orange)
                    }
                }

                // Birthdays
                let month = calendar.component(.month, from: currentDate)
                let day = calendar.component(.day, from: currentDate)
                for contact in contacts {
                    guard let birthday = contact.birthday else { continue }
                    if calendar.component(.month, from: birthday) == month &&
                       calendar.component(.day, from: birthday) == day {
                        indicators.append(JohoColors.pink)
                        break
                    }
                }

                // Events
                for event in countdownEvents {
                    if calendar.startOfDay(for: event.targetDate) == dayStart {
                        indicators.append(JohoColors.cyan)
                        break
                    }
                }

                // Notes
                for note in allNotes {
                    if calendar.startOfDay(for: note.date) == dayStart {
                        indicators.append(JohoColors.yellow)
                        break
                    }
                }

                week.append(EmbeddedCalendarDay(
                    date: currentDate,
                    dayNumber: dayNum,
                    isCurrentMonth: isCurrentMonth,
                    isToday: isToday,
                    indicators: Array(indicators.prefix(3))
                ))

                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            weeks.append(week)

            // Stop if we've passed the end of the month and completed the week
            let lastDayMonth = calendar.component(.month, from: week.last?.date ?? Date())
            if lastDayMonth > embeddedCalendarMonth || (lastDayMonth == 1 && embeddedCalendarMonth == 12) {
                break
            }
        }

        return weeks
    }

    /// Embedded calendar day model
    private struct EmbeddedCalendarDay: Hashable {
        let date: Date
        let dayNumber: Int
        let isCurrentMonth: Bool
        let isToday: Bool
        let indicators: [Color]

        func hash(into hasher: inout Hasher) {
            hasher.combine(date)
        }

        static func == (lhs: EmbeddedCalendarDay, rhs: EmbeddedCalendarDay) -> Bool {
            lhs.date == rhs.date
        }
    }

    /// Embedded calendar day cell
    private func embeddedDayCell(_ day: EmbeddedCalendarDay) -> some View {
        VStack(spacing: 2) {
            // Day number
            Text("\(day.dayNumber)")
                .font(.system(size: 14, weight: day.isToday ? .black : .medium, design: .rounded))
                .foregroundStyle(
                    day.isToday ? colors.primaryInverted :
                    day.isCurrentMonth ? colors.primary : colors.secondary.opacity(0.4)
                )
                .frame(width: 28, height: 28)
                .background(day.isToday ? JohoColors.yellow : Color.clear)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(day.isToday ? JohoColors.black : Color.clear, lineWidth: 1.5)
                )

            // Indicators
            if !day.indicators.isEmpty && day.isCurrentMonth {
                HStack(spacing: 2) {
                    ForEach(Array(day.indicators.enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            } else {
                Spacer()
                    .frame(height: 6)
            }
        }
        .frame(height: 40)
    }

    // MARK: - NOTES STREAM Card (情報デザイン: Recent notes with color/symbol indicators)

    /// Recent notes (last 5, sorted by date)
    private var recentNotes: [DailyNote] {
        Array(allNotes.prefix(5))
    }

    private var notesStreamCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.yellow)

                Text("NOTES")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                // Pinned count indicator
                let pinnedCount = allNotes.filter { $0.pinnedToDashboard == true }.count
                if pinnedCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(pinnedCount)")
                    }
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(JohoColors.red.opacity(0.1))
                    .clipShape(Capsule())
                }

                Text("\(allNotes.count)")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(colors.secondary)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Notes list
            VStack(spacing: 0) {
                ForEach(Array(recentNotes.enumerated()), id: \.element.id) { index, note in
                    if index > 0 {
                        Rectangle()
                            .fill(colors.border.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                    }

                    noteStreamRow(note)
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

    /// Note stream row
    private func noteStreamRow(_ note: DailyNote) -> some View {
        let noteColor = note.color.map { Color(hex: $0) } ?? JohoColors.yellow
        let isPinned = note.pinnedToDashboard == true

        return HStack(spacing: JohoDimensions.spacingSM) {
            // Color + Priority indicator
            VStack(spacing: 2) {
                Circle()
                    .fill(noteColor)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))

                // Priority marker (情報デザイン: マルバツ)
                if let priority = note.priority {
                    Text(priority == "high" ? "◎" : priority == "low" ? "△" : "")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(priority == "high" ? JohoColors.red : JohoColors.black.opacity(0.4))
                }
            }
            .frame(width: 16)

            // Symbol if any
            if let symbolName = note.symbolName {
                Image(systemName: symbolName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(noteColor)
                    .frame(width: 16)
            }

            // Content preview
            VStack(alignment: .leading, spacing: 2) {
                Text(note.content.prefix(50) + (note.content.count > 50 ? "..." : ""))
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                // Date
                Text(note.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.secondary)
            }

            Spacer()

            // Pinned indicator
            if isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(JohoColors.red)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    // MARK: - BIRTHDAY COUNTDOWN Card (情報デザイン: Next 3 birthdays)

    /// Upcoming birthdays (next 3)
    private var upcomingBirthdays: [(contact: Contact, daysUntil: Int)] {
        let calendar = Calendar.current
        var birthdays: [(Contact, Int)] = []

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

            birthdays.append((contact, daysUntil))
        }

        return birthdays.sorted { $0.1 < $1.1 }.prefix(3).map { ($0.0, $0.1) }
    }

    private var birthdayCountdownCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "birthday.cake.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.pink)

                Text("BIRTHDAYS")
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

            // Birthday list
            VStack(spacing: 0) {
                ForEach(Array(upcomingBirthdays.enumerated()), id: \.element.contact.id) { index, item in
                    if index > 0 {
                        Rectangle()
                            .fill(colors.border.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                    }

                    birthdayRow(contact: item.contact, daysUntil: item.daysUntil)
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

    /// Birthday row
    private func birthdayRow(contact: Contact, daysUntil: Int) -> some View {
        let firstName = contact.givenName.isEmpty ? contact.familyName : contact.givenName

        return HStack(spacing: JohoDimensions.spacingSM) {
            // Days countdown badge
            VStack(spacing: 0) {
                if daysUntil == 0 {
                    Text("TODAY")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.pink)
                } else {
                    Text("\(daysUntil)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(daysUntil <= 7 ? JohoColors.pink : colors.primary)
                    Text("days")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }
            .frame(width: 44)
            .padding(.vertical, 4)
            .background(daysUntil == 0 ? JohoColors.pink.opacity(0.2) : colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(daysUntil <= 7 ? JohoColors.pink : colors.border.opacity(0.3), lineWidth: 1)
            )

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(firstName)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                // Birthday date
                if let birthday = contact.birthday {
                    Text(birthday.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }

            Spacer()

            // Star for imminent birthdays
            if daysUntil <= 7 {
                Image(systemName: daysUntil == 0 ? "star.fill" : "star")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(JohoColors.pink)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    // MARK: - MONTHLY EXPENSE SUMMARY Card (情報デザイン: Spending overview)

    /// This month's expenses
    private var thisMonthExpenses: [ExpenseItem] {
        let calendar = Calendar.iso8601
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return []
        }
        return allExpenses.filter { $0.date >= startOfMonth }
    }

    /// Category breakdown for this month
    private var expenseCategoryBreakdown: [(category: String, icon: String, color: Color, total: Double)] {
        var breakdown: [String: (icon: String, color: Color, total: Double)] = [:]

        for expense in thisMonthExpenses {
            let categoryName = expense.category?.name ?? "Other"
            let icon = expense.category?.iconName ?? "creditcard.fill"
            let color = expense.category?.color ?? JohoColors.green

            if let existing = breakdown[categoryName] {
                breakdown[categoryName] = (existing.icon, existing.color, existing.total + expense.amount)
            } else {
                breakdown[categoryName] = (icon, color, expense.amount)
            }
        }

        return breakdown.map { ($0.key, $0.value.icon, $0.value.color, $0.value.total) }
            .sorted { $0.3 > $1.3 }
    }

    private var monthlyExpenseSummaryCard: some View {
        let total = thisMonthExpenses.reduce(0) { $0 + $1.amount }
        let primaryCurrency = thisMonthExpenses.first?.currency ?? "SEK"

        return VStack(spacing: 0) {
            // Header with total
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.green)

                Text("EXPENSES")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                Text(currentMonthTheme.name.prefix(3).uppercased())
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(colors.secondary)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Total amount
            VStack(spacing: 4) {
                Text(formatCurrency(total, currency: primaryCurrency))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary)

                Text("\(thisMonthExpenses.count) expenses")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.secondary)
            }
            .padding(.vertical, JohoDimensions.spacingMD)

            // Category breakdown
            if !expenseCategoryBreakdown.isEmpty {
                Rectangle()
                    .fill(colors.border.opacity(0.3))
                    .frame(height: 1)

                VStack(spacing: JohoDimensions.spacingXS) {
                    ForEach(expenseCategoryBreakdown.prefix(4), id: \.category) { item in
                        HStack(spacing: JohoDimensions.spacingSM) {
                            // Category icon
                            Image(systemName: item.icon)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(item.color)
                                .frame(width: 20)

                            // Category name
                            Text(item.category)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)

                            Spacer()

                            // Amount
                            Text(formatCurrency(item.total, currency: primaryCurrency))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary)

                            // Percentage
                            let percentage = Int((item.total / total) * 100)
                            Text("\(percentage)%")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.secondary)
                                .frame(width: 32, alignment: .trailing)
                        }
                    }
                }
                .padding(JohoDimensions.spacingSM)
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    /// Format currency amount
    private func formatCurrency(_ amount: Double, currency: String) -> String {
        let symbol = CurrencyDefinition.symbol(for: currency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
        return "\(symbol)\(formattedAmount)"
    }

    // MARK: - WEEK ACTIVITY STRIP Card (情報デザイン: Visual density dots)

    private var activityStripCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.cyan)

                Text("ACTIVITY")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                // Legend
                HStack(spacing: 8) {
                    legendDot(color: JohoColors.yellow, label: "N")
                    legendDot(color: JohoColors.green, label: "E")
                    legendDot(color: JohoColors.pink, label: "H")
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Activity strip
            HStack(spacing: 0) {
                ForEach(activityStripDays, id: \.date) { day in
                    if day.dayOfWeek > 1 {
                        Rectangle()
                            .fill(colors.border.opacity(0.2))
                            .frame(width: 1)
                    }

                    activityDayCell(day)
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

    /// Legend dot
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
        }
    }

    /// Activity strip day model
    private struct ActivityDay {
        let date: Date
        let dayOfWeek: Int
        let name: String
        let isToday: Bool
        let noteCount: Int
        let expenseCount: Int
        let holidayCount: Int
    }

    /// Get activity strip days for current week
    private var activityStripDays: [ActivityDay] {
        let calendar = Calendar.iso8601
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            let name = date.formatted(.dateTime.weekday(.narrow)).uppercased()
            let dayOfWeek = offset + 1  // 1-7 for Mon-Sun
            let isToday = calendar.isDateInToday(date)

            // Count notes
            let noteCount = allNotes.filter { calendar.startOfDay(for: $0.date) == dayStart }.count

            // Count expenses
            let expenseCount = allExpenses.filter { calendar.startOfDay(for: $0.date) == dayStart }.count

            // Count holidays/events
            var holidayCount = 0
            if let holidays = holidayManager.holidayCache[dayStart] {
                holidayCount = holidays.count
            }
            // Add birthday count
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            for contact in contacts {
                guard let birthday = contact.birthday else { continue }
                if calendar.component(.month, from: birthday) == month &&
                   calendar.component(.day, from: birthday) == day {
                    holidayCount += 1
                }
            }

            return ActivityDay(
                date: date,
                dayOfWeek: dayOfWeek,
                name: name,
                isToday: isToday,
                noteCount: noteCount,
                expenseCount: expenseCount,
                holidayCount: holidayCount
            )
        }
    }

    /// Activity day cell
    private func activityDayCell(_ day: ActivityDay) -> some View {
        VStack(spacing: 4) {
            // Day name
            Text(day.name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(day.isToday ? JohoColors.yellow : colors.secondary)

            // Activity dots stack (情報デザイン: Visual density)
            VStack(spacing: 2) {
                // Notes (yellow)
                HStack(spacing: 1) {
                    ForEach(0..<min(day.noteCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(JohoColors.yellow)
                            .frame(width: 5, height: 5)
                    }
                    if day.noteCount > 3 {
                        Text("+")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(JohoColors.yellow)
                    }
                }
                .frame(height: 6)

                // Expenses (green)
                HStack(spacing: 1) {
                    ForEach(0..<min(day.expenseCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(JohoColors.green)
                            .frame(width: 5, height: 5)
                    }
                    if day.expenseCount > 3 {
                        Text("+")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(JohoColors.green)
                    }
                }
                .frame(height: 6)

                // Holidays/Events (pink)
                HStack(spacing: 1) {
                    ForEach(0..<min(day.holidayCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(JohoColors.pink)
                            .frame(width: 5, height: 5)
                    }
                    if day.holidayCount > 3 {
                        Text("+")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(JohoColors.pink)
                    }
                }
                .frame(height: 6)
            }

            // Today indicator
            if day.isToday {
                Circle()
                    .fill(JohoColors.yellow)
                    .frame(width: 4, height: 4)
            } else {
                Spacer()
                    .frame(height: 4)
            }
        }
        .padding(.vertical, 4)
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
