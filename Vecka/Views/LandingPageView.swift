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
    @Environment(NavigationManager.self) private var navigationManager: NavigationManager?

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// 情報デザイン: Adaptive layout for iPad (regular) vs iPhone (compact)
    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    // Personalized title (情報デザイン: User can customize their landing page)
    @AppStorage("customLandingTitle") private var customLandingTitle = ""

    // Unified Memo query - filter by type in computed properties
    @Query(sort: \Memo.date, order: .reverse) private var allMemos: [Memo]
    @Query private var contacts: [Contact]
    @Query(sort: \WorldClock.sortOrder) private var worldClocks: [WorldClock]

    /// Filtered notes from Memo
    private var allNotes: [Memo] {
        allMemos.filter { $0.type == .note }
    }

    /// Filtered expenses from Memo
    private var allExpenses: [Memo] {
        allMemos.filter { $0.type == .expense }
    }

    /// Filtered trips from Memo
    private var allTrips: [Memo] {
        allMemos.filter { $0.type == .trip }
    }

    /// Filtered countdown events from Memo
    private var countdownMemos: [Memo] {
        allMemos.filter { $0.type == .countdown }
    }

    private var holidayManager = HolidayManager.shared

    // UI State for sheets
    @State private var showTripsSheet = false
    @State private var showExpensesSheet = false

    // Random stat state (情報デザイン: Rotating insights)

    // Quirky facts for GLANCE (情報デザイン: Database-driven facts only)
    @State private var factProvider: RandomFactProvider?
    @State private var randomFacts: [RandomFact] = []
    @State private var selectedRandomFact: RandomFact?  // Tap-to-expand detail sheet

    // Discovery Grid state (情報デザイン: Random events from database)

    // Navigation to Calendar with specific date

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
                // 情報デザイン: Fixed header + scrollable content
                VStack(spacing: 0) {
                    pageHeader
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.top, JohoDimensions.spacingSM)
                        .padding(.bottom, JohoDimensions.spacingMD)

                    ScrollView {
                        VStack(spacing: JohoDimensions.spacingMD) {
                            if displayClocks.isNotEmpty {
                                worldClocksCard
                            }

                            agendaCard
                            randomFactsCard
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.bottom, JohoDimensions.spacingXL)
                    }
                }
            } else {
                // iPhone/iPad mini: Fixed header + scrollable content
                VStack(spacing: 0) {
                    pageHeader
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, JohoDimensions.spacingSM)
                        .padding(.top, JohoDimensions.spacingSM)
                        .padding(.bottom, JohoDimensions.spacingMD)

                    ScrollView {
                        VStack(spacing: JohoDimensions.spacingMD) {
                            if displayClocks.isNotEmpty {
                                worldClocksCard
                            }

                            agendaCard
                            randomFactsCard
                        }
                        .padding(.horizontal, JohoDimensions.spacingSM)
                        .padding(.bottom, JohoDimensions.spacingXL)
                    }
                }
            }
        }
        .johoBackground()
        .onAppear {
            // Initialize fact provider if needed
            if factProvider == nil {
                factProvider = RandomFactProvider(context: modelContext, selectedRegions: ["NORDIC", "VN", "UK"])
            }
            // 情報デザイン: Always refresh facts when landing page appears (tab switch, back navigation)
            loadRandomFacts()
            // Check for deep link fact to show
            checkForDeepLinkFact()
        }
        .onChange(of: navigationManager?.factIdToShow) { _, newFactId in
            if newFactId != nil {
                checkForDeepLinkFact()
            }
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
        .sheet(item: $selectedRandomFact) { fact in
            RandomFactDetailSheet(fact: fact)
        }
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
                .foregroundStyle(colors.primaryInverted)
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

    // MARK: - RANDOM FACTS Card (情報デザイン: Quirky Facts Grid)

    private var randomFactsCard: some View {
        VStack(spacing: 0) {
            // Header with display icon (情報デザイン: Black contour icon)
            HStack {
                ZStack {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.cyan)
                }
                .frame(width: 24, height: 24)
                .background(JohoColors.cyan.opacity(0.15))
                .clipShape(Squircle(cornerRadius: 6))
                .overlay(
                    Squircle(cornerRadius: 6)
                        .stroke(colors.border, lineWidth: 1)
                )

                Text("RANDOM FACTS")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                // Tap to refresh facts (情報デザイン: Visual stays small, tap area expanded)
                Button {
                    HapticManager.impact(.light)
                    loadRandomFacts()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
                .buttonStyle(.plain)
                .padding(JohoDimensions.spacingSM)  // Expand tap area without visual change
                .contentShape(Rectangle())
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // 3x2 Grid of quirky facts (情報デザイン: Month card style, tap to expand)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: JohoDimensions.spacingSM) {
                ForEach(randomFacts) { fact in
                    Button {
                        HapticManager.selection()
                        selectedRandomFact = fact
                    } label: {
                        randomFactTile(fact)
                    }
                    .buttonStyle(.plain)
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

    /// Load 6 quirky facts from database (情報デザイン: Simple, database-driven)
    private func loadRandomFacts() {
        guard let provider = factProvider else { return }
        provider.reset()
        randomFacts = (0..<6).map { _ in provider.nextFact() }
    }

    /// Check for and show a fact from widget deep link
    private func checkForDeepLinkFact() {
        guard let factId = navigationManager?.factIdToShow else { return }

        // Look up fact from database
        let descriptor = FetchDescriptor<QuirkyFact>(
            predicate: #Predicate { $0.id == factId }
        )

        if let quirkyFact = try? modelContext.fetch(descriptor).first {
            // Convert to RandomFact display model
            let fact = RandomFact(
                id: quirkyFact.id,
                text: quirkyFact.text,
                icon: iconFor(category: quirkyFact.factCategory),
                color: colorFor(category: quirkyFact.factCategory),
                explanation: quirkyFact.explanation.isEmpty ? quirkyFact.text : quirkyFact.explanation,
                source: quirkyFact.region
            )
            selectedRandomFact = fact
        }

        // Clear the deep link after handling
        navigationManager?.factIdToShow = nil
    }

    /// Icon for fact category (matches RandomFactProvider)
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

    /// Color for fact category (matches RandomFactProvider)
    private func colorFor(category: QuirkyFact.Category) -> Color {
        switch category {
        case .tradition: return JohoColors.purple
        case .food: return Color(hex: "F97316")
        case .invention: return JohoColors.yellow
        case .nature: return JohoColors.green
        case .history: return Color(hex: "78350F")
        case .quirky: return JohoColors.cyan
        }
    }

    /// Month card style fact tile (情報デザイン: Star page style - strong colors)
    private func randomFactTile(_ fact: RandomFact) -> some View {
        VStack(spacing: 0) {
            // TOP: Icon zone (情報デザイン: Strong color like Star page month icons)
            VStack {
                Image(systemName: fact.icon ?? "star.fill")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(fact.color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(fact.color.opacity(0.2))

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // BOTTOM: Text zone
            Text(fact.text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: 1.5)
        )
    }

    // MARK: - Row Helpers

    private func todayItemRowView(_ item: TodayItem, size: JohoCardSize) -> some View {
        let isCompact = size == .compact

        return HStack(spacing: isCompact ? 6 : JohoDimensions.spacingSM) {
            // Type indicator
            Circle()
                .fill(item.color)
                .frame(width: size.dotSize, height: size.dotSize)
                .overlay(Circle().stroke(colors.border, lineWidth: 1))

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

    private func todayItemRow(_ item: TodayItem) -> some View {
        todayItemRowView(item, size: .regular)
    }

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

    // MARK: - AGENDA Card (情報デザイン: Unified Today/Upcoming/Recent)

    /// Agenda mode determines what content to show
    private enum AgendaMode {
        case today      // Has items today
        case upcoming   // Nothing today, show next 7 days
        case recent     // Nothing upcoming, show what happened recently

        var icon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .upcoming: return "arrow.right.circle.fill"
            case .recent: return "clock.arrow.circlepath"
            }
        }

        var title: String {
            switch self {
            case .today: return "TODAY"
            case .upcoming: return "UPCOMING"
            case .recent: return "RECENT"
            }
        }

        var accentColor: Color {
            switch self {
            case .today: return JohoColors.yellow
            case .upcoming: return JohoColors.cyan
            case .recent: return JohoColors.purple
            }
        }

        var emptyMessage: String {
            switch self {
            case .today: return "Nothing scheduled"
            case .upcoming: return "Nothing in the next 7 days"
            case .recent: return "No recent activity"
            }
        }
    }

    /// Determine which agenda mode to show
    private var agendaMode: AgendaMode {
        if !todayItems.isEmpty {
            return .today
        } else if !upcomingItemsExcludingToday.isEmpty {
            return .upcoming
        } else {
            return .recent
        }
    }

    /// Upcoming items excluding today (for when today is empty)
    private var upcomingItemsExcludingToday: [UpcomingItem] {
        upcomingItems.filter { !$0.isToday }
    }

    /// Recent items from yesterday and before (last 7 days)
    private var recentItems: [TodayItem] {
        let calendar = Calendar.iso8601
        var items: [TodayItem] = []

        // Look back 7 days
        for dayOffset in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: todayStart) else { continue }

            // Holidays
            if let holidays = holidayManager.holidayCache[date] {
                for holiday in holidays {
                    let color = holiday.isBankHoliday ? JohoColors.red : JohoColors.cyan
                    let badge = holiday.isBankHoliday ? "HOL" : "OBS"
                    items.append(TodayItem(
                        title: holiday.displayTitle,
                        subtitle: formatRelativeDate(date),
                        icon: holiday.isBankHoliday ? "star.fill" : "sparkles",
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
                    items.append(TodayItem(
                        title: "\(name)'s Birthday",
                        subtitle: formatRelativeDate(date),
                        icon: "birthday.cake.fill",
                        color: CategoryColorSettings.shared.color(for: .memo),
                        typeBadge: "BDY"
                    ))
                }
            }

            // Notes
            for note in allNotes {
                let noteDate = calendar.startOfDay(for: note.date)
                if noteDate == date {
                    let preview = String(note.text.prefix(30))
                    items.append(TodayItem(
                        title: preview + (note.text.count > 30 ? "..." : ""),
                        subtitle: formatRelativeDate(date),
                        icon: "note.text",
                        color: JohoColors.yellow,
                        typeBadge: "NTE"
                    ))
                }
            }
        }

        return items
    }

    /// Format relative date (Yesterday, 2 days ago, etc.)
    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.iso8601
        let daysDiff = calendar.dateComponents([.day], from: date, to: todayStart).day ?? 0

        if daysDiff == 1 {
            return "Yesterday"
        } else if daysDiff < 7 {
            return "\(daysDiff) days ago"
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    /// Unified agenda card - shows Today, Upcoming, or Recent based on content
    private var agendaCard: some View {
        let mode = agendaMode

        return VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(mode.accentColor)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(colors.border, lineWidth: 1))

                Text(mode.title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                // Item count
                let count = agendaItemCount(for: mode)
                if count > 0 {
                    Text("\(count)")
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

            // Content based on mode
            switch mode {
            case .today:
                todayContent

            case .upcoming:
                upcomingContent

            case .recent:
                recentContent
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    /// Item count for agenda mode
    private func agendaItemCount(for mode: AgendaMode) -> Int {
        switch mode {
        case .today: return todayItems.count
        case .upcoming: return upcomingItemsExcludingToday.count
        case .recent: return recentItems.count
        }
    }

    /// Today content for agenda card
    private var todayContent: some View {
        Group {
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
    }

    /// Upcoming content for agenda card
    private var upcomingContent: some View {
        Group {
            let items = upcomingItemsExcludingToday
            if items.isEmpty {
                Text("Nothing in the next 7 days")
                    .font(JohoFont.body)
                    .foregroundStyle(colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(JohoDimensions.spacingMD)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Rectangle()
                                .fill(colors.border.opacity(0.2))
                                .frame(height: 1)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                        }
                        upcomingItemRow(item)
                    }

                    if items.count > 5 {
                        Rectangle()
                            .fill(colors.border.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)

                        Text("+\(items.count - 5) more")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(colors.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, JohoDimensions.spacingSM)
                    }
                }
            }
        }
    }

    /// Recent content for agenda card
    private var recentContent: some View {
        Group {
            let items = recentItems
            if items.isEmpty {
                VStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(colors.secondary.opacity(0.4))

                    Text("All caught up!")
                        .font(JohoFont.body)
                        .foregroundStyle(colors.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(JohoDimensions.spacingMD)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Rectangle()
                                .fill(colors.border.opacity(0.2))
                                .frame(height: 1)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                        }
                        recentItemRow(item)
                    }
                }
            }
        }
    }

    /// Recent item row (similar to today but with subtitle for date)
    private func recentItemRow(_ item: TodayItem) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Type indicator
            Circle()
                .fill(item.color)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(colors.border, lineWidth: 1))

            // Icon
            Image(systemName: item.icon)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(item.color)
                .frame(width: 16)

            // Title + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }

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
                    let color = holiday.isBankHoliday ? JohoColors.red : JohoColors.cyan
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
                        color: CategoryColorSettings.shared.color(for: .memo),
                        typeBadge: "BDY"
                    ))
                }
            }

            // Countdown events
            for event in countdownMemos {
                let eventDate = calendar.startOfDay(for: event.date)
                if eventDate == date {
                    items.append(UpcomingItem(
                        date: date,
                        dayName: dayName,
                        dayNumber: dayNumber,
                        isToday: isToday,
                        title: event.text,
                        color: JohoColors.cyan,
                        typeBadge: "EVT"
                    ))
                }
            }

            // Trips starting
            for trip in allTrips {
                let tripStart = calendar.startOfDay(for: trip.date)
                if tripStart == date {
                    items.append(UpcomingItem(
                        date: date,
                        dayName: dayName,
                        dayNumber: dayNumber,
                        isToday: isToday,
                        title: trip.text,
                        color: SpecialDayType.trip.accentColor,
                        typeBadge: "TRP"
                    ))
                }
            }
        }

        return items.sorted { $0.date < $1.date }
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
                let color = holiday.isBankHoliday ? JohoColors.red : JohoColors.cyan
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
                    color: CategoryColorSettings.shared.color(for: .memo),
                    typeBadge: "BDY"
                ))
            }
        }

        // 3. Countdown events today
        for event in countdownMemos {
            let eventDate = calendar.startOfDay(for: event.date)
            if eventDate == todayStart {
                items.append(TodayItem(
                    title: event.text,
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
                let preview = String(note.text.prefix(30))
                items.append(TodayItem(
                    title: preview + (note.text.count > 30 ? "..." : ""),
                    subtitle: nil,
                    icon: "note.text",
                    color: JohoColors.yellow,
                    typeBadge: "NTE"
                ))
            }
        }

        // 5. Active trips
        for trip in allTrips {
            guard let endDate = trip.tripEndDate else { continue }
            let tripStart = calendar.startOfDay(for: trip.date)
            let tripEnd = calendar.startOfDay(for: endDate)

            if todayStart >= tripStart && todayStart <= tripEnd {
                items.append(TodayItem(
                    title: trip.text,
                    subtitle: nil,
                    icon: "airplane",
                    color: JohoColors.cyan,
                    typeBadge: "TRP"
                ))
            }
        }

        // 6. Expenses today
        for expense in allExpenses {
            let expenseDate = calendar.startOfDay(for: expense.date)
            if expenseDate == todayStart {
                items.append(TodayItem(
                    title: expense.text,
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

// MARK: - Random Fact Detail Sheet (情報デザイン: Tap-to-expand detail view)

/// Detail sheet shown when tapping a GLANCE fact tile
/// 情報デザイン: Larger view with full explanation
struct RandomFactDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    let fact: RandomFact

    var body: some View {
        VStack(spacing: 0) {
            JohoSheetHeader(
                title: "FACT",
                shareButton: FactShareButton(fact: fact),
                onClose: { dismiss() }
            )

            // Main content card
            VStack(spacing: 0) {
                // Large icon zone (情報デザイン: Hero display like Star page)
                VStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: fact.icon ?? "star.fill")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(fact.color)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(fact.color.opacity(0.2))

                // Thick divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // Text zone with headline
                Text(fact.text)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.top, JohoDimensions.spacingMD)

                // Thin divider
                Rectangle()
                    .fill(colors.border.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingSM)

                // Explanation text (情報デザイン: Full context for understanding)
                Text(fact.explanation)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.bottom, JohoDimensions.spacingLG)
            }
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
            )
            .padding(JohoDimensions.spacingMD)

            Spacer()
        }
        .background(fact.color.opacity(0.3))
        .presentationDetents([.medium])
        .presentationCornerRadius(JohoDimensions.radiusLarge)
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Preview

#Preview("Onsen Landing") {
    LandingPageView()
}

