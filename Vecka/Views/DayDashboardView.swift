//
//  DayDashboardView.swift
//  Vecka
//
//  Inline "dashboard" beneath the month grid (Apple Calendar-like).
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                // Week status (date now shown in header above calendar)
                Text(subtitleText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                if notes.count > 0 {
                    Text("\(notes.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.extraSmall)
                        .background(.secondary.opacity(0.10), in: Capsule())
                }
            }

            if !holidays.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(holidays.prefix(2)) { holiday in
                        HStack(spacing: 10) {
                            Image(systemName: holiday.symbolName ?? (holiday.isRedDay ? "flag.fill" : "flag"))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(holiday.isRedDay ? .red : AppColors.accentBlue)

                            Text(holiday.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Spacer(minLength: 0)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(holiday.name)\(holiday.isRedDay ? ", public holiday" : "")")
                    }

                    if holidays.count > 2 {
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("holiday.more_count", value: "+%d more", comment: "Additional holidays count"),
                            holidays.count - 2
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if !notes.isEmpty {
                    Divider()
                }
            }

            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(Localization.notesForDay)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer(minLength: 0)

                        if showExpandToggle {
                            Button(expandTitle) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    isExpanded.toggle()
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.plain)
                            .foregroundStyle(AppColors.accentBlue)
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            if !expenses.isEmpty {
                if !notes.isEmpty || !holidays.isEmpty {
                    Divider()
                }

                Button {
                    onOpenExpenses?(date)
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Expenses")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Spacer(minLength: 0)

                            Text(totalExpenseAmount, format: .currency(code: baseCurrency))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.green)
                        }

                        ForEach(expenses) { expense in
                            ExpenseDayRow(expense: expense)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(expenses.count) expenses, total \(totalExpenseAmount.formatted(.currency(code: baseCurrency)))")
                .accessibilityHint("Double tap to view expenses")
            }

            // Trips Section
            if !trips.isEmpty {
                if !notes.isEmpty || !holidays.isEmpty || !expenses.isEmpty {
                    Divider()
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "airplane.departure")
                            .font(.subheadline)
                            .foregroundStyle(.blue)

                        Text("Trips")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("\(trips.count) active trips")

                    ForEach(trips) { trip in
                        TripDayRow(trip: trip)
                    }
                }
            }

            if !pinnedCountdownNotes.isEmpty {
                if !notes.isEmpty || !holidays.isEmpty || !expenses.isEmpty || !trips.isEmpty {
                    Divider()
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(Localization.pinnedHeader)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer(minLength: 0)

                        if showPinnedExpandToggle {
                            Button(isPinnedExpanded ? Localization.showLess : Localization.showAll) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    isPinnedExpanded.toggle()
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.plain)
                            .foregroundStyle(AppColors.accentBlue)
                        }
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(Spacing.medium)
        .glassCard(cornerRadius: 16, material: .regularMaterial)
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

// MARK: - Expense Day Row

private struct ExpenseDayRow: View {
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    let expense: ExpenseItem

    var body: some View {
        HStack(spacing: 10) {
            // Category icon
            if let category = expense.category {
                Image(systemName: category.iconName)
                    .foregroundStyle(category.color)
                    .frame(width: 24, alignment: .center)
            } else {
                Image(systemName: "creditcard")
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .center)
            }

            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.itemDescription)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let merchant = expense.merchantName {
                    Text(merchant)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount, format: .currency(code: expense.currency))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                if let converted = expense.convertedAmount, expense.currency != baseCurrency {
                    Text(converted, format: .currency(code: baseCurrency))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.small)
        .padding(.horizontal, Spacing.small)
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(timeSource.formatted(date: .omitted, time: .shortened))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer(minLength: 0)

                if note.pinnedToDashboard == true {
                    Image(systemName: "pin.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if let color = note.color {
                    Circle()
                        .fill(colorForName(color))
                        .frame(width: 8, height: 8)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: note.symbolName ?? NoteSymbolCatalog.defaultSymbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(expanded ? 8 : 2)
            }
        }
        .padding(.vertical, Spacing.small)
        .padding(.horizontal, Spacing.small)
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default: return AppColors.accentBlue
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
    .padding()
    .background(AppColors.background)
}

private struct PinnedCountdownRow: View {
    let note: DailyNote
    let daysRemaining: Int

    var body: some View {
        let (title, subtitle) = titleAndSubtitle(from: note.content)
        let scheduleText = scheduleLine(for: note)
        let badgeText = countdownBadgeText(days: daysRemaining)

        HStack(spacing: 12) {
            Image(systemName: note.symbolName ?? NoteSymbolCatalog.defaultSymbol)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppColors.accentBlue)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text([scheduleText, subtitle].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Text(badgeText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.small)
                .background(.secondary.opacity(0.10), in: Capsule())
                .monospacedDigit()
        }
        .padding(.vertical, Spacing.small)
        .padding(.horizontal, Spacing.small)
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

// MARK: - Trip Day Row

private struct TripDayRow: View {
    let trip: TravelTrip

    var body: some View {
        HStack(spacing: 10) {
            // Trip icon with color
            Image(systemName: "airplane.departure")
                .font(.body)
                .foregroundStyle(trip.tripType.color)
                .frame(width: 24, height: 24)
                .background(trip.tripType.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            // Trip info
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.tripName)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(trip.destination)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(trip.duration) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Date range
            VStack(alignment: .trailing, spacing: 2) {
                Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("to")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text(trip.endDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.extraSmall)
    }
}
