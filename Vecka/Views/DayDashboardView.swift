//
//  DayDashboardView.swift
//  Vecka
//
//  Inline "dashboard" beneath the month grid - Japanese Packaging Design
//

import SwiftUI

struct DayDashboardView: View {
    struct HolidayInfo: Identifiable, Equatable {
        let id: String
        let name: String
        let isRedDay: Bool
        let symbolName: String?
    }

    let date: Date
    let notes: [DailyNote]
    let pinnedNotes: [DailyNote]
    let holidays: [HolidayInfo]
    let expenses: [ExpenseItem]
    let trips: [TravelTrip]
    let secondaryDateText: String?
    let onOpenNotes: (_ date: Date) -> Void
    let onOpenExpenses: ((_ date: Date) -> Void)?

    @State private var isExpanded = false
    @State private var isPinnedExpanded = false

    @Environment(\.locale) private var locale

    private let previewLimit = 3
    private let pinnedPreviewLimit = 2

    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    private var referenceDay: Date {
        Calendar.current.startOfDay(for: date)
    }

    private var pinnedCountdownNotes: [DailyNote] {
        let referenceDay = self.referenceDay

        return pinnedNotes
            .filter { $0.pinnedToDashboard == true }
            .filter { $0.day > referenceDay }
            .sorted(by: { lhs, rhs in
                if lhs.day != rhs.day { return lhs.day < rhs.day }
                let lhsTime = lhs.scheduledAt ?? lhs.date
                let rhsTime = rhs.scheduledAt ?? rhs.date
                return lhsTime < rhsTime
            })
    }

    private var visiblePinnedNotes: [DailyNote] {
        isPinnedExpanded ? pinnedCountdownNotes : Array(pinnedCountdownNotes.prefix(pinnedPreviewLimit))
    }

    private var showPinnedExpandToggle: Bool {
        pinnedCountdownNotes.count > pinnedPreviewLimit
    }

    private var hasExpandableContent: Bool {
        if notes.count > previewLimit {
            return true
        }
        return notes.contains { note in
            let trimmed = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.count > 140 || trimmed.contains("\n")
        }
    }

    private var visibleNotes: [DailyNote] {
        isExpanded ? notes : Array(notes.prefix(previewLimit))
    }

    private var showExpandToggle: Bool {
        hasExpandableContent
    }

    private var expandTitle: String {
        if notes.count > previewLimit {
            return isExpanded ? Localization.showLess : Localization.showAll
        }
        return isExpanded ? Localization.less : Localization.more
    }

    // MARK: - Joho Design System Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                // HEADER - Simplified to avoid redundancy
                // Only shows TODAY badge (if today) or weekday, plus formatted date
                JohoPageHeader(
                    title: formattedDate,
                    badge: headerBadge,
                    subtitle: Calendar.current.isDateInToday(date) ? weekdayName : nil
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

                // HOLIDAYS SECTION
                if !holidays.isEmpty {
                    JohoSectionBox(title: "HOLIDAYS", zone: .holidays, icon: "star.fill") {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            ForEach(holidays.prefix(2)) { holiday in
                                HStack(spacing: JohoDimensions.spacingSM) {
                                    Image(systemName: holiday.symbolName ?? (holiday.isRedDay ? "flag.fill" : "flag"))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(JohoColors.black)

                                    Text(holiday.name)
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)

                                    Spacer(minLength: 0)

                                    if holiday.isRedDay {
                                        JohoPill(text: "RED DAY", style: .whiteOnBlack, size: .small)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(holiday.name)\(holiday.isRedDay ? ", public holiday" : "")")
                            }

                            if holidays.count > 2 {
                                Text(String.localizedStringWithFormat(
                                    NSLocalizedString("holiday.more_count", value: "+%d more", comment: "Additional holidays count"),
                                    holidays.count - 2
                                ))
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // NOTES SECTION
                if !notes.isEmpty {
                    JohoSectionBox(title: "NOTES", zone: .notes, icon: "note.text") {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            HStack {
                                if showExpandToggle {
                                    Button(expandTitle) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                            isExpanded.toggle()
                                        }
                                    }
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black)
                                    .accessibilityLabel(expandTitle)
                                }
                            }

                            ForEach(visibleNotes) { note in
                                Button(action: { onOpenNotes(date) }) {
                                    NotePreviewRow(note: note, expanded: isExpanded)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(noteAccessibilityLabel(note))
                                .accessibilityHint("Double tap to edit")
                            }

                            if !isExpanded, notes.count > previewLimit {
                                Text(String.localizedStringWithFormat(
                                    NSLocalizedString("note.more_count", value: "+%d more", comment: "Additional notes count"),
                                    notes.count - previewLimit
                                ))
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // EXPENSES SECTION
                if !expenses.isEmpty {
                    Button {
                        onOpenExpenses?(date)
                    } label: {
                        JohoSectionBox(title: "EXPENSES", zone: .expenses, icon: "yensign.circle") {
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                                HStack {
                                    Text("Total")
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)

                                    Spacer(minLength: 0)

                                    Text(totalExpenseAmount, format: .currency(code: baseCurrency))
                                        .font(JohoFont.monoMedium)
                                        .foregroundStyle(JohoColors.black)
                                }

                                ForEach(expenses) { expense in
                                    ExpenseDayRow(expense: expense)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .accessibilityLabel("\(expenses.count) expenses, total \(totalExpenseAmount.formatted(.currency(code: baseCurrency)))")
                    .accessibilityHint("Double tap to view expenses")
                }

                // TRIPS SECTION
                if !trips.isEmpty {
                    JohoSectionBox(title: "TRIPS", zone: .trips, icon: "airplane.departure") {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            ForEach(trips) { trip in
                                TripDayRow(trip: trip)
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .accessibilityLabel("\(trips.count) active trips")
                }

                // PINNED COUNTDOWNS SECTION
                if !pinnedCountdownNotes.isEmpty {
                    JohoSectionBox(title: "PINNED", zone: .calendar, icon: "pin.fill") {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            if showPinnedExpandToggle {
                                Button(isPinnedExpanded ? Localization.showLess : Localization.showAll) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                        isPinnedExpanded.toggle()
                                    }
                                }
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black)
                            }

                            ForEach(visiblePinnedNotes) { note in
                                Button(action: { onOpenNotes(note.day) }) {
                                    PinnedCountdownRow(note: note, daysRemaining: daysUntil(note.day))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(pinnedNoteAccessibilityLabel(note))
                                .accessibilityHint("Double tap to view")
                            }

                            if !isPinnedExpanded, pinnedCountdownNotes.count > pinnedPreviewLimit {
                                Text(String.localizedStringWithFormat(
                                    NSLocalizedString("pinned.more_count", value: "+%d more", comment: "Additional pinned notes count"),
                                    pinnedCountdownNotes.count - pinnedPreviewLimit
                                ))
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }
            }
            .padding(.vertical, JohoDimensions.spacingLG)
        }
        .johoBackground()
    }

    // MARK: - Header Helpers

    private var headerBadge: String {
        if Calendar.current.isDateInToday(date) {
            return "TODAY"
        }
        return weekdayName
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = locale
        return formatter.string(from: date)
    }

    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = locale
        return formatter.string(from: date)
    }

    private var subtitleText: String {
        let week = Localization.weekDisplayText(Calendar.iso8601.component(.weekOfYear, from: date))
        let trimmedSecondary = (secondaryDateText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSecondary.isEmpty else { return week }
        return "\(week) • \(trimmedSecondary)"
    }

    private var dateHeadline: String {
        let formatted = date.formatted(date: .complete, time: .omitted)
        let language = locale.language.languageCode?.identifier
        if language == "sv" {
            return formatted.capitalized(with: locale)
        }
        return formatted
    }

    private func daysUntil(_ targetDay: Date) -> Int {
        ViewUtilities.daysUntil(from: referenceDay, to: targetDay)
    }

    private var totalExpenseAmount: Double {
        expenses.reduce(0) { $0 + ($1.convertedAmount ?? $1.amount) }
    }

    private func noteAccessibilityLabel(_ note: DailyNote) -> String {
        let content = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = content.components(separatedBy: .newlines).first ?? content
        let truncated = firstLine.count > 50 ? String(firstLine.prefix(50)) + "..." : firstLine
        let time = (note.scheduledAt ?? note.date).formatted(date: .omitted, time: .shortened)
        return "\(truncated), at \(time)"
    }

    private func pinnedNoteAccessibilityLabel(_ note: DailyNote) -> String {
        let content = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = content.components(separatedBy: .newlines).first ?? content
        let truncated = firstLine.count > 40 ? String(firstLine.prefix(40)) + "..." : firstLine
        let days = daysUntil(note.day)
        let daysText = days == 1 ? "1 day left" : "\(days) days left"
        return "\(truncated), \(daysText)"
    }
}

// MARK: - Expense Day Row (Joho Design)

private struct ExpenseDayRow: View {
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    let expense: ExpenseItem

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Category icon
            if let category = expense.category {
                Image(systemName: category.iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: "creditcard")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 28, height: 28)
            }

            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.itemDescription)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                if let merchant = expense.merchantName {
                    Text(merchant)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount, format: .currency(code: expense.currency))
                    .font(JohoFont.monoMedium)
                    .foregroundStyle(JohoColors.black)

                if let converted = expense.convertedAmount, expense.currency != baseCurrency {
                    Text(converted, format: .currency(code: baseCurrency))
                        .font(JohoFont.monoSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }
        }
        .padding(JohoDimensions.spacingSM)
        .background(JohoColors.white.opacity(0.4))
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
        )
    }
}

private struct NotePreviewRow: View {
    let note: DailyNote
    let expanded: Bool

    var body: some View {
        // Check if this is a birthday note
        let birthdayInfo = PersonnummerParser.extractBirthdayInfo(from: note.content)
        let (title, subtitle): (String, String?) = if let info = birthdayInfo {
            ("🎂 \(info.localizedDescription)", nil)
        } else {
            titleAndSubtitle(from: note.content)
        }
        let timeSource = note.scheduledAt ?? note.date

        VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
            HStack(spacing: JohoDimensions.spacingSM) {
                Text(timeSource.formatted(date: .omitted, time: .shortened))
                    .font(JohoFont.monoSmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))

                Spacer(minLength: 0)

                if note.pinnedToDashboard == true {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                }

                if let color = note.color {
                    Circle()
                        .fill(colorForName(color))
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                }
            }

            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: note.symbolName ?? NoteSymbolCatalog.defaultSymbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.black)

                Text(title)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
                    .lineLimit(expanded ? 8 : 2)
            }
        }
        .padding(JohoDimensions.spacingSM)
        .background(JohoColors.white.opacity(0.4))
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
        )
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "red": return JohoColors.pink
        case "blue": return JohoColors.cyan
        case "green": return JohoColors.green
        case "orange": return JohoColors.orange
        case "purple": return Color(hex: "B19CD9")
        case "yellow": return JohoColors.yellow
        default: return JohoColors.cyan
        }
    }

    private func titleAndSubtitle(from raw: String) -> (String, String?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", nil) }

        if let newlineIndex = trimmed.firstIndex(where: \.isNewline) {
            let firstLine = String(trimmed[..<newlineIndex])
            let remainder = String(trimmed[trimmed.index(after: newlineIndex)...])
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return (firstLine, remainder.isEmpty ? nil : remainder)
        }

        let maxTitleLength = 80
        guard trimmed.count > maxTitleLength else {
            return (trimmed, nil)
        }

        let hardSplitIndex = trimmed.index(trimmed.startIndex, offsetBy: maxTitleLength)
        let prefix = trimmed[..<hardSplitIndex]
        let wordBoundaryIndex = prefix.lastIndex(where: { $0.isWhitespace })

        let splitIndex: String.Index
        if let wordBoundaryIndex, trimmed.distance(from: trimmed.startIndex, to: wordBoundaryIndex) >= 40 {
            splitIndex = wordBoundaryIndex
        } else {
            splitIndex = hardSplitIndex
        }

        let title = String(trimmed[..<splitIndex]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let subtitle = String(trimmed[splitIndex...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return (title, subtitle.isEmpty ? nil : subtitle)
    }
}

#Preview {
    DayDashboardView(
        date: Date(),
        notes: [],
        pinnedNotes: [],
        holidays: [.init(id: "preview", name: "Holiday", isRedDay: true, symbolName: "flag.fill")],
        expenses: [],
        trips: [],
        secondaryDateText: "Lunar 1/1",
        onOpenNotes: { _ in },
        onOpenExpenses: { _ in }
    )
}

private struct PinnedCountdownRow: View {
    let note: DailyNote
    let daysRemaining: Int

    var body: some View {
        let (title, subtitle) = titleAndSubtitle(from: note.content)
        let scheduleText = scheduleLine(for: note)
        let badgeText = countdownBadgeText(days: daysRemaining)

        HStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: note.symbolName ?? NoteSymbolCatalog.defaultSymbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(JohoColors.black)
                .frame(width: 32, alignment: .center)

            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                Text(title)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                Text([scheduleText, subtitle].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            JohoPill(text: badgeText, style: .whiteOnBlack, size: .small)
        }
        .padding(JohoDimensions.spacingSM)
        .background(JohoColors.white.opacity(0.4))
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
        )
    }

    private func scheduleLine(for note: DailyNote) -> String {
        let dayText = note.day.formatted(date: .abbreviated, time: .omitted)
        if let scheduledAt = note.scheduledAt {
            let timeText = scheduledAt.formatted(date: .omitted, time: .shortened)
            return "\(dayText) • \(timeText)"
        }
        return dayText
    }

    private func countdownBadgeText(days: Int) -> String {
        if days <= 0 { return Localization.today }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 1
        return formatter.string(from: TimeInterval(days) * 86_400) ?? "\(days)"
    }

    private func titleAndSubtitle(from raw: String) -> (String, String?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", nil) }

        if let newlineIndex = trimmed.firstIndex(where: \.isNewline) {
            let firstLine = String(trimmed[..<newlineIndex])
            let remainder = String(trimmed[trimmed.index(after: newlineIndex)...])
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return (firstLine, remainder.isEmpty ? nil : remainder)
        }

        let maxTitleLength = 80
        guard trimmed.count > maxTitleLength else {
            return (trimmed, nil)
        }

        let hardSplitIndex = trimmed.index(trimmed.startIndex, offsetBy: maxTitleLength)
        let prefix = trimmed[..<hardSplitIndex]
        let wordBoundaryIndex = prefix.lastIndex(where: { $0.isWhitespace })

        let splitIndex: String.Index
        if let wordBoundaryIndex, trimmed.distance(from: trimmed.startIndex, to: wordBoundaryIndex) >= 40 {
            splitIndex = wordBoundaryIndex
        } else {
            splitIndex = hardSplitIndex
        }

        let title = String(trimmed[..<splitIndex]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let subtitle = String(trimmed[splitIndex...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return (title, subtitle.isEmpty ? nil : subtitle)
    }
}

// MARK: - Trip Day Row (Joho Design)

private struct TripDayRow: View {
    let trip: TravelTrip

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Trip icon
            JohoIconBadge(icon: "airplane.departure", zone: .trips, size: 36)

            // Trip info
            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                Text(trip.tripName)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)

                HStack(spacing: 4) {
                    Text(trip.destination)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))

                    Text("•")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))

                    Text("\(trip.duration) days")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                }
            }

            Spacer()

            // Date range badge
            VStack(alignment: .trailing, spacing: 2) {
                Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(JohoFont.monoSmall)
                    .foregroundStyle(JohoColors.black)

                Text("→")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))

                Text(trip.endDate.formatted(date: .abbreviated, time: .omitted))
                    .font(JohoFont.monoSmall)
                    .foregroundStyle(JohoColors.black)
            }
        }
        .padding(JohoDimensions.spacingSM)
        .background(JohoColors.white.opacity(0.4))
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
        )
    }
}
