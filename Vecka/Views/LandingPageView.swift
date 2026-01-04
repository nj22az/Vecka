//
//  LandingPageView.swift
//  Vecka
//
//  情報デザイン: Today's Dashboard - summary + navigation hub
//  First page when app opens, shows today's info with quick navigation
//

import SwiftUI
import SwiftData

struct LandingPageView: View {
    @Environment(\.modelContext) private var modelContext

    // Data queries
    @Query(sort: \DailyNote.date, order: .reverse) private var allNotes: [DailyNote]
    @Query private var contacts: [Contact]
    @Query private var countdownEvents: [CountdownEvent]

    // Navigation callback (set by parent)
    var onNavigate: ((SidebarSelection) -> Void)?

    // Explicit init required due to @Query property wrappers
    init(onNavigate: ((SidebarSelection) -> Void)? = nil) {
        self.onNavigate = onNavigate
    }

    private var holidayManager = HolidayManager.shared

    // MARK: - Date Properties

    private var today: Date { Date() }

    private var weekNumber: Int {
        Calendar.iso8601.component(.weekOfYear, from: today)
    }

    private var dayNumber: Int {
        Calendar.iso8601.component(.day, from: today)
    }

    private var weekday: String {
        today.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    private var year: Int {
        Calendar.iso8601.component(.year, from: today)
    }

    private var fullDateString: String {
        today.formatted(.dateTime.month(.wide).day().year())
    }

    // MARK: - Data Properties

    private var todaysNotes: [DailyNote] {
        let day = Calendar.iso8601.startOfDay(for: today)
        return allNotes.filter { $0.day == day }
    }

    private var pinnedNotes: [DailyNote] {
        allNotes.filter { $0.pinnedToDashboard == true }
    }

    private var todaysEvents: [CountdownEvent] {
        let day = Calendar.iso8601.startOfDay(for: today)
        return countdownEvents.filter {
            Calendar.iso8601.startOfDay(for: $0.targetDate) == day
        }
    }

    private var upcomingBirthdays: [(contact: Contact, daysUntil: Int)] {
        let calendar = Calendar.iso8601

        let filtered: [(Contact, Int)] = contacts.compactMap { contact in
            guard let birthday = contact.birthday else { return nil }
            let bdayComponents = calendar.dateComponents([.month, .day], from: birthday)

            // Calculate days until next birthday
            var nextBirthday = calendar.date(from: DateComponents(
                year: year,
                month: bdayComponents.month,
                day: bdayComponents.day
            )) ?? birthday

            // If birthday already passed this year, use next year
            if nextBirthday < today {
                nextBirthday = calendar.date(from: DateComponents(
                    year: year + 1,
                    month: bdayComponents.month,
                    day: bdayComponents.day
                )) ?? birthday
            }

            let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0

            // Only include birthdays in next 30 days
            guard daysUntil <= 30 else { return nil }
            return (contact, daysUntil)
        }

        return filtered
            .sorted { $0.1 < $1.1 }
            .prefix(3)
            .map { (contact: $0.0, daysUntil: $0.1) }
    }

    private var todaysHolidays: [HolidayCacheItem] {
        let day = Calendar.iso8601.startOfDay(for: today)
        return holidayManager.holidayCache[day] ?? []
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingMD) {
                // Page header (情報デザイン bento style)
                landingPageHeader
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                // Summary cards grid (2x2)
                summaryCardsGrid
                    .padding(.horizontal, JohoDimensions.spacingLG)

                // Navigation cards (3x2)
                navigationCardsSection
                    .padding(.horizontal, JohoDimensions.spacingLG)

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.bottom, JohoDimensions.spacingLG)
        }
        .scrollBounceBehavior(.basedOnSize)
        .johoBackground()
    }

    // MARK: - Landing Page Header

    private var landingPageHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // LEFT: Icon + Title
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(PageHeaderColor.landing.accent)
                        .frame(width: 40, height: 40)
                        .background(PageHeaderColor.landing.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: 1.5)
                        )

                    Text("TODAY")
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)

                // RIGHT: Date info
                HStack(spacing: 4) {
                    Text("\(dayNumber)")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(JohoColors.black)
                    Text(weekday)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                }
                .frame(width: 80)
            }
            .frame(height: 56)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Week badge row
            HStack {
                Text("WEEK \(weekNumber)")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(JohoColors.black)
                    .clipShape(Capsule())

                Spacer()

                Text(fullDateString)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    // MARK: - Summary Cards Grid

    private var summaryCardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: JohoDimensions.spacingMD),
            GridItem(.flexible(), spacing: JohoDimensions.spacingMD)
        ], spacing: JohoDimensions.spacingMD) {
            // Week Number Card (yellow = NOW)
            weekNumberCard

            // Events/Holidays Today Card
            eventsTodayCard

            // Upcoming Birthdays Card
            birthdaysCard

            // Notes Card
            notesCard
        }
    }

    private var weekNumberCard: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            Text("\(weekNumber)")
                .font(JohoFont.displayLarge)
                .foregroundStyle(JohoColors.black)

            Text("WEEK OF \(String(year))")
                .font(JohoFont.labelSmall)
                .foregroundStyle(JohoColors.black.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(JohoColors.yellow.opacity(0.3))  // Yellow = NOW
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    private var eventsTodayCard: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            HStack {
                Text("TODAY")
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black)
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }

            if !todaysHolidays.isEmpty {
                ForEach(Array(todaysHolidays.prefix(2))) { holiday in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(holiday.isRedDay ? JohoColors.red : JohoColors.orange)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                        Text(holiday.displayTitle)
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)
                    }
                }
            } else if !todaysEvents.isEmpty {
                ForEach(todaysEvents.prefix(2), id: \.id) { event in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(JohoColors.cyan)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                        Text(event.title)
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("No events")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }

            Spacer()
        }
        .padding(JohoDimensions.spacingMD)
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    private var birthdaysCard: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            HStack {
                Text("BIRTHDAYS")
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black)
                Spacer()
                Image(systemName: "gift")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }

            if !upcomingBirthdays.isEmpty {
                ForEach(Array(upcomingBirthdays.prefix(2)), id: \.contact.id) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(JohoColors.pink)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                        Text(item.contact.displayName)
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)
                        Spacer()
                        if item.daysUntil == 0 {
                            Text("TODAY")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(JohoColors.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(JohoColors.pink)
                                .clipShape(Capsule())
                        } else {
                            Text("\(item.daysUntil)d")
                                .font(JohoFont.labelSmall)
                                .foregroundStyle(JohoColors.black.opacity(0.5))
                        }
                    }
                }
            } else {
                Text("None upcoming")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }

            Spacer()
        }
        .padding(JohoDimensions.spacingMD)
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            HStack {
                Text("NOTES")
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black)
                Spacer()
                Image(systemName: "note.text")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }

            if !todaysNotes.isEmpty || !pinnedNotes.isEmpty {
                if !todaysNotes.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(JohoColors.yellow)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                        Text("\(todaysNotes.count) today")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black)
                    }
                }
                if !pinnedNotes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                        Text("\(pinnedNotes.count) pinned")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black)
                    }
                }
            } else {
                Text("No notes")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }

            Spacer()
        }
        .padding(JohoDimensions.spacingMD)
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Navigation Cards Section

    private var navigationCardsSection: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            // Section header
            HStack {
                JohoPill(text: "NAVIGATE", style: .whiteOnBlack, size: .small)
                Spacer()
            }

            // Navigation grid (3x2)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: JohoDimensions.spacingMD),
                GridItem(.flexible(), spacing: JohoDimensions.spacingMD),
                GridItem(.flexible(), spacing: JohoDimensions.spacingMD)
            ], spacing: JohoDimensions.spacingMD) {
                navigationCard(for: .calendar)
                navigationCard(for: .tools)
                navigationCard(for: .contacts)
                navigationCard(for: .specialDays)
                navigationCard(for: .settings)
                mascotCard
            }
        }
    }

    private func navigationCard(for page: SidebarSelection) -> some View {
        Button {
            HapticManager.selection()
            onNavigate?(page)
        } label: {
            VStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: page.icon)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(page.accentColor)

                Text(page.label.uppercased())
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
            )
        }
        .buttonStyle(.plain)
    }

    private var mascotCard: some View {
        VStack(spacing: 4) {
            // Geometric mascot (情報デザイン compliant)
            GeometricMascotView(size: 50, showOuterBorder: false)

            Text("WEEKGRID")
                .font(JohoFont.labelSmall)
                .foregroundStyle(JohoColors.black)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - Preview

#Preview("Landing Page") {
    LandingPageView()
}
