//
//  MediumWidgetView.swift
//  VeckaWidget
//
//  Medium Widget: Two-compartment bento
//  Left: Compact date box (day, date, month, week)
//  Right: Smart content — today's special > upcoming within 7 days > fact
//

import SwiftUI
import WidgetKit

struct VeckaMediumWidgetView: View {
    let entry: VeckaWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Calendar

    private var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }

    // MARK: - Month Theme

    private var monthTheme: WidgetMonthTheme {
        let month = calendar.component(.month, from: entry.date)
        return WidgetMonthTheme.theme(for: month)
    }

    // MARK: - Date Properties

    private var dayOfMonth: Int {
        calendar.component(.day, from: entry.date)
    }

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var weekdayFull: String {
        entry.date.formatted(.dateTime.weekday(.wide).locale(.autoupdatingCurrent)).uppercased()
    }

    private var yearString: String {
        entry.date.formatted(.dateTime.year().locale(.autoupdatingCurrent))
    }

    private var lunarDateString: String {
        let chineseCalendar = Calendar(identifier: .chinese)
        let lunarMonth = chineseCalendar.component(.month, from: entry.date)
        let lunarDay = chineseCalendar.component(.day, from: entry.date)
        return "\(lunarMonth)/\(lunarDay)"
    }

    // MARK: - Smart Content

    private enum ContentMode {
        case todaySpecial(name: String, symbol: String, notes: String?)
        case upcoming(name: String, symbol: String, date: Date, daysAway: Int)
        case fact(WidgetFacts.Fact)
    }

    private var contentMode: ContentMode {
        // 1. Today's special
        if let holiday = entry.todaysHolidays.first {
            return .todaySpecial(
                name: holiday.displayName,
                symbol: holiday.isBankHoliday ? "star.fill" : "sparkles",
                notes: holiday.notes
            )
        }
        if let birthday = entry.todaysBirthdays.first {
            return .todaySpecial(
                name: birthday.displayName,
                symbol: "gift.fill",
                notes: nil
            )
        }

        // 2. Next upcoming event within 7 days
        let today = calendar.startOfDay(for: entry.date)
        guard let oneWeekOut = calendar.date(byAdding: .day, value: 7, to: today) else {
            return .fact(WidgetFacts.randomFact(for: entry.date))
        }

        var nextEvents: [(name: String, symbol: String, date: Date)] = []

        for holiday in entry.upcomingHolidays where holiday.date > today && holiday.date <= oneWeekOut {
            nextEvents.append((holiday.displayName, holiday.isBankHoliday ? "star.fill" : "sparkles", holiday.date))
        }

        for (date, birthdays) in entry.weekBirthdays where date > today && date <= oneWeekOut {
            for birthday in birthdays {
                nextEvents.append((birthday.displayName, "gift.fill", date))
            }
        }

        nextEvents.sort { $0.date < $1.date }

        if let next = nextEvents.first {
            let daysAway = calendar.dateComponents([.day], from: today, to: next.date).day ?? 0
            return .upcoming(name: next.name, symbol: next.symbol, date: next.date, daysAway: daysAway)
        }

        // 3. Quirky or calendar fact
        return .fact(WidgetFacts.randomFact(for: entry.date))
    }

    private var widgetURLString: String {
        switch contentMode {
        case .todaySpecial: return "vecka://today"
        case .upcoming: return "vecka://today"
        case .fact(let f): return "vecka://facts/\(f.id)"
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.height / 155

            HStack(spacing: 0) {
                // Left: star card column
                dateColumn(scale: scale)
                    .frame(width: geo.size.width * 0.42)

                // Right: smart content
                contentColumn(scale: scale)
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: widgetURLString))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content(for: colorScheme)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Show Lunar Setting (synced from main app)

    private var showLunarCalendar: Bool {
        UserDefaults(suiteName: "group.Johansson.Vecka")?.bool(forKey: "showLunarCalendar") ?? false
    }

    // MARK: - Date Column (Star Card with date info in white zone)

    private func dateColumn(scale: CGFloat) -> some View {
        let borderColor = JohoWidget.Colors.border(for: colorScheme)
        let cardRadius: CGFloat = 8 * scale
        let secondaryColor = JohoWidget.Colors.textSecondary(for: colorScheme)

        return VStack(spacing: 0) {
            // Star card fills the left column
            VStack(spacing: 0) {
                // TOP: Colored icon zone
                VStack {
                    Image(systemName: monthTheme.icon)
                        .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(monthTheme.accentColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 38 * scale)
                .background(monthTheme.lightBackground)

                // Divider
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1)

                // BOTTOM: White zone — all date info
                VStack(spacing: 2 * scale) {
                    // Month · Year
                    HStack(spacing: 3 * scale) {
                        Text(monthShort)
                            .font(.system(size: 8 * scale, weight: .black, design: .rounded))
                            .tracking(0.5)
                        Text("\u{00B7}")
                            .font(.system(size: 8 * scale, weight: .bold, design: .rounded))
                        Text(yearString)
                            .font(.system(size: 8 * scale, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(secondaryColor)

                    // Big date number
                    Text("\(dayOfMonth)")
                        .font(.system(size: 36 * scale, weight: .black, design: .rounded))
                        .foregroundStyle(borderColor)
                        .padding(.vertical, -2 * scale)

                    // Weekday
                    Text(weekdayFull)
                        .font(.system(size: 8 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryColor)
                        .tracking(0.5)

                    // Week number + lunar
                    HStack(spacing: 4 * scale) {
                        Text("W\(entry.weekNumber)")
                            .font(.system(size: 9 * scale, weight: .black, design: .rounded))
                            .foregroundStyle(secondaryColor)

                        if showLunarCalendar {
                            HStack(spacing: 1 * scale) {
                                Image(systemName: JohoWidget.Symbols.moonFill)
                                    .font(.system(size: 5 * scale))
                                Text(lunarDateString)
                                    .font(.system(size: 7 * scale, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(secondaryColor.opacity(0.6))
                        }
                    }
                    .padding(.top, 1 * scale)
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(JohoWidget.Colors.content(for: colorScheme))
            }
            .background(JohoWidget.Colors.content(for: colorScheme))
            .clipShape(WidgetSquircle(cornerRadius: cardRadius))
            .overlay(
                WidgetSquircle(cornerRadius: cardRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .padding(5 * scale)
        }
    }

    // MARK: - Content Column

    @ViewBuilder
    private func contentColumn(scale: CGFloat) -> some View {
        switch contentMode {
        case .todaySpecial(let name, let symbol, let notes):
            todayContent(name: name, symbol: symbol, notes: notes, scale: scale)
        case .upcoming(let name, let symbol, let date, let daysAway):
            upcomingContent(name: name, symbol: symbol, date: date, daysAway: daysAway, scale: scale)
        case .fact(let fact):
            factContent(fact: fact, scale: scale)
        }
    }

    // MARK: - Today Content

    private func todayContent(name: String, symbol: String, notes: String?, scale: CGFloat) -> some View {
        let accentColor = monthTheme.accentColor
        let textColor = JohoWidget.Colors.text(for: colorScheme)
        let secondaryColor = JohoWidget.Colors.textSecondary(for: colorScheme)

        return VStack(alignment: .leading, spacing: 0) {
            // Header — accent colored
            Text("TODAY")
                .font(.system(size: 9 * scale, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)
                .tracking(1)

            Spacer(minLength: 6 * scale)

            // Name with icon — prominent
            HStack(spacing: 6 * scale) {
                Image(systemName: symbol)
                    .font(.system(size: 20 * scale, weight: .bold))
                    .foregroundStyle(textColor)

                Text(name)
                    .font(.system(size: 15 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }

            if let notes {
                Text(notes)
                    .font(.system(size: 10 * scale, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(3)
                    .padding(.top, 4 * scale)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10 * scale)
        .padding(.top, 6 * scale)
        .padding(.bottom, 8 * scale)
    }

    // MARK: - Upcoming Content

    private func upcomingContent(name: String, symbol: String, date: Date, daysAway: Int, scale: CGFloat) -> some View {
        let accentColor = monthTheme.accentColor
        let textColor = JohoWidget.Colors.text(for: colorScheme)
        let secondaryColor = JohoWidget.Colors.textSecondary(for: colorScheme)

        return VStack(alignment: .leading, spacing: 0) {
            // Header — accent colored
            Text("NEXT UP")
                .font(.system(size: 9 * scale, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)
                .tracking(1)

            Spacer(minLength: 6 * scale)

            // Name with icon — prominent
            HStack(spacing: 6 * scale) {
                Image(systemName: symbol)
                    .font(.system(size: 20 * scale, weight: .bold))
                    .foregroundStyle(textColor)

                Text(name)
                    .font(.system(size: 15 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            // Date info at bottom
            HStack {
                Text("in \(daysAway) day\(daysAway == 1 ? "" : "s")")
                    .font(.system(size: 10 * scale, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryColor)

                Spacer()

                Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().locale(.autoupdatingCurrent)).uppercased())
                    .font(.system(size: 9 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(secondaryColor)
            }
        }
        .padding(.horizontal, 10 * scale)
        .padding(.top, 6 * scale)
        .padding(.bottom, 8 * scale)
    }

    // MARK: - Fact Content

    private func factContent(fact: WidgetFacts.Fact, scale: CGFloat) -> some View {
        let accentColor = monthTheme.accentColor
        let textColor = JohoWidget.Colors.text(for: colorScheme)
        let secondaryColor = JohoWidget.Colors.textSecondary(for: colorScheme)

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("DID YOU KNOW")
                .font(.system(size: 9 * scale, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)
                .tracking(1)

            Spacer(minLength: 6 * scale)

            HStack(spacing: 6 * scale) {
                Image(systemName: fact.symbol)
                    .font(.system(size: 20 * scale, weight: .bold))
                    .foregroundStyle(textColor)

                Text(fact.text)
                    .font(.system(size: 12 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)

            // Country pill — right-aligned
            if let region = fact.region {
                HStack {
                    Spacer()
                    Text(region)
                        .font(.system(size: 8 * scale, weight: .black, design: .rounded))
                        .foregroundStyle(secondaryColor)
                        .tracking(0.5)
                        .padding(.horizontal, 5 * scale)
                        .padding(.vertical, 2 * scale)
                        .background(JohoWidget.Colors.border(for: colorScheme).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 3 * scale, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                                .stroke(JohoWidget.Colors.border(for: colorScheme).opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 10 * scale)
        .padding(.top, 6 * scale)
        .padding(.bottom, 8 * scale)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = "Week \(entry.weekNumber)"
        switch contentMode {
        case .todaySpecial(let name, _, _):
            label += ", Today: \(name)"
        case .upcoming(let name, _, _, let days):
            label += ", Next up: \(name) in \(days) days"
        case .fact(let fact):
            label += ", \(fact.text)"
        }
        return label
    }
}
