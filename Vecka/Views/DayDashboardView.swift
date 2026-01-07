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
        let isBankHoliday: Bool
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
    var onAddEntry: (() -> Void)? = nil  // 情報デザイン: Opens add entry menu

    /// 情報デザイン: Check if day has any content
    private var hasAnyContent: Bool {
        !holidays.isEmpty || !notes.isEmpty || !expenses.isEmpty || !trips.isEmpty
    }

    @State private var isExpanded = false
    @State private var isPinnedExpanded = false

    @Environment(\.locale) private var locale
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
        VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
            // HEADER with + button - 情報デザイン: Day title with add entry action
            dayHeader
                .padding(.horizontal, JohoDimensions.spacingLG)

            // EMPTY STATE - 情報デザイン: Show when no entries
            if !hasAnyContent {
                emptyStateView
                    .padding(.horizontal, JohoDimensions.spacingLG)
            }

            // HOLIDAYS SECTION (情報デザイン: Star Pages bento style)
            if !holidays.isEmpty {
                bentoSection(title: "HOLIDAYS", icon: "star.fill", zone: .holidays) {
                    ForEach(holidays.prefix(2)) { holiday in
                        bentoHolidayRow(holiday: holiday)
                    }

                    if holidays.count > 2 {
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("holiday.more_count", value: "+%d more", comment: "Additional holidays count"),
                            holidays.count - 2
                        ))
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                        .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
            }

            // NOTES SECTION (情報デザイン: Star Pages bento style)
            if !notes.isEmpty {
                bentoSection(title: "NOTES", icon: "note.text", zone: .notes) {
                    if showExpandToggle {
                        Button(expandTitle) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                isExpanded.toggle()
                            }
                        }
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .accessibilityLabel(expandTitle)
                    }

                    ForEach(visibleNotes) { note in
                        Button(action: { onOpenNotes(date) }) {
                            bentoNoteRow(note: note, expanded: isExpanded)
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
                        .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
            }

            // EXPENSES SECTION (情報デザイン: Star Pages bento style)
            if !expenses.isEmpty {
                Button {
                    onOpenExpenses?(date)
                } label: {
                    bentoSection(title: "EXPENSES", icon: "dollarsign.circle.fill", zone: .expenses) {
                        // Total row
                        bentoTotalRow(label: "Total", amount: totalExpenseAmount, currency: baseCurrency)

                        ForEach(expenses) { expense in
                            bentoExpenseRow(expense: expense)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, JohoDimensions.spacingLG)
                .accessibilityLabel("\(expenses.count) expenses, total \(totalExpenseAmount.formatted(.currency(code: baseCurrency)))")
                .accessibilityHint("Double tap to view expenses")
            }

            // TRIPS SECTION (情報デザイン: Star Pages bento style)
            if !trips.isEmpty {
                bentoSection(title: "TRIPS", icon: "airplane.departure", zone: .trips) {
                    ForEach(trips) { trip in
                        bentoTripRow(trip: trip)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .accessibilityLabel("\(trips.count) active trips")
            }

            // PINNED COUNTDOWNS SECTION (情報デザイン: Star Pages bento style)
            if !pinnedCountdownNotes.isEmpty {
                bentoSection(title: "PINNED", icon: "pin.fill", zone: .calendar) {
                    if showPinnedExpandToggle {
                        Button(isPinnedExpanded ? Localization.showLess : Localization.showAll) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                isPinnedExpanded.toggle()
                            }
                        }
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                    }

                    ForEach(visiblePinnedNotes) { note in
                        Button(action: { onOpenNotes(note.day) }) {
                            bentoPinnedRow(note: note, daysRemaining: daysUntil(note.day))
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
                        .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
            }
        }
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

    // MARK: - Day Header with + Button (情報デザイン)

    /// 情報デザイン: Compartmentalized header with visual separation
    /// Layout: [TODAY] │ Date │ [+ ADD]
    private var dayHeader: some View {
        HStack(spacing: 0) {
            // LEFT COMPARTMENT: TODAY/Weekday badge
            JohoPill(text: headerBadge, style: Calendar.current.isDateInToday(date) ? .coloredInverted(JohoColors.yellow) : .whiteOnBlack, size: .small)
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.vertical, JohoDimensions.spacingSM)

            // VERTICAL DIVIDER
            Rectangle()
                .fill(colors.border)
                .frame(width: JohoDimensions.borderMedium)
                .frame(maxHeight: .infinity)

            // CENTER COMPARTMENT: Formatted date
            Text(formattedDate)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)

            // VERTICAL DIVIDER (only if ADD button exists)
            if onAddEntry != nil {
                Rectangle()
                    .fill(colors.border)
                    .frame(width: JohoDimensions.borderMedium)
                    .frame(maxHeight: .infinity)
            }

            // RIGHT COMPARTMENT: + ADD Button
            if let onAddEntry {
                Button {
                    HapticManager.selection()
                    onAddEntry()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .black))
                        Text("ADD")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(0.5)
                    }
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(colors.surfaceInverted)
                    .clipShape(Squircle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.vertical, JohoDimensions.spacingSM)
            }
        }
        .frame(minHeight: 52)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }

    // MARK: - Empty State (情報デザイン)

    private var emptyStateView: some View {
        // Empty state background: slightly different from surface for visual distinction
        let emptyBg = colorMode == .dark ? Color(hex: "1A1A1A") : JohoColors.inputBackground

        return VStack(spacing: JohoDimensions.spacingMD) {
            // Icon
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(colors.primary.opacity(0.3))

            // Text
            Text("NO ENTRIES")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(colors.primary.opacity(0.4))

            // Hint
            Text("Tap + to add holidays, notes, events, or more")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoDimensions.spacingXL)
        .background(emptyBg)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Star Pages Bento Helpers (情報デザイン)

    /// 情報デザイン: Bento section box with vertical wall and icon compartment
    @ViewBuilder
    private func bentoSection<Content: View>(
        title: String,
        icon: String,
        zone: SectionZone,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // HEADER: Title pill | vertical wall | icon compartment
            HStack(spacing: 0) {
                JohoPill(text: title, style: .whiteOnBlack, size: .small)
                    .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                // Vertical wall
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // Icon compartment
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(zone.background.opacity(0.5))

            // Horizontal divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // CONTENT
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(.vertical, JohoDimensions.spacingXS)
        }
        .background(zone.background)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    /// 情報デザイン: Bento holiday row with compartments
    @ViewBuilder
    private func bentoHolidayRow(holiday: HolidayInfo) -> some View {
        HStack(spacing: 0) {
            // LEFT: Type indicator
            HStack(spacing: 3) {
                Circle()
                    .fill(SpecialDayType.holiday.accentColor)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))

                if holiday.isBankHoliday {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
            }
            .frame(width: 32, alignment: .center)
            .frame(maxHeight: .infinity)

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Icon + Name
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: holiday.symbolName ?? (holiday.isBankHoliday ? "flag.fill" : "flag"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black)

                Text(holiday.name)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(minHeight: 36)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(holiday.name)\(holiday.isBankHoliday ? ", public holiday" : "")")
    }

    /// 情報デザイン: Bento note row with compartments
    @ViewBuilder
    private func bentoNoteRow(note: DailyNote, expanded: Bool) -> some View {
        let (title, subtitle) = titleAndSubtitle(from: note.content)
        let timeSource = note.scheduledAt ?? note.date

        HStack(spacing: 0) {
            // LEFT: Type indicator + color
            HStack(spacing: 3) {
                if let colorName = note.color {
                    Circle()
                        .fill(colorForName(colorName))
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                } else {
                    Circle()
                        .fill(SpecialDayType.note.accentColor)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                }

                if note.pinnedToDashboard == true {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
            }
            .frame(width: 32, alignment: .center)
            .frame(maxHeight: .infinity)

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: note.symbolName ?? "note.text")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black)

                    Text(title)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(timeSource.formatted(date: .omitted, time: .shortened))
                        .font(JohoFont.monoSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                        .lineLimit(expanded ? 8 : 2)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.vertical, JohoDimensions.spacingXS)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 36)
        .contentShape(Rectangle())
    }

    /// 情報デザイン: Bento expense total row
    @ViewBuilder
    private func bentoTotalRow(label: String, amount: Double, currency: String) -> some View {
        HStack(spacing: 0) {
            // LEFT: Indicator
            Circle()
                .fill(SpecialDayType.expense.accentColor)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                .frame(width: 32, alignment: .center)
                .frame(maxHeight: .infinity)

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Label
            Text(label)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)
                .padding(.horizontal, JohoDimensions.spacingSM)

            Spacer()

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT: Amount
            Text(amount, format: .currency(code: currency))
                .font(JohoFont.monoMedium)
                .foregroundStyle(JohoColors.black)
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(maxHeight: .infinity)
        }
        .frame(minHeight: 36)
        .background(JohoColors.white.opacity(0.3))
    }

    /// 情報デザイン: Bento expense item row
    @ViewBuilder
    private func bentoExpenseRow(expense: ExpenseItem) -> some View {
        HStack(spacing: 0) {
            // LEFT: Category icon
            if let category = expense.category {
                Image(systemName: category.iconName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 32, alignment: .center)
                    .frame(maxHeight: .infinity)
            } else {
                Image(systemName: "creditcard")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 32, alignment: .center)
                    .frame(maxHeight: .infinity)
            }

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Description
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
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT: Amount
            Text(expense.amount, format: .currency(code: expense.currency))
                .font(JohoFont.monoSmall)
                .foregroundStyle(JohoColors.black)
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(maxHeight: .infinity)
        }
        .frame(minHeight: 36)
        .contentShape(Rectangle())
    }

    /// 情報デザイン: Bento trip row
    @ViewBuilder
    private func bentoTripRow(trip: TravelTrip) -> some View {
        HStack(spacing: 0) {
            // LEFT: Trip indicator
            Circle()
                .fill(SpecialDayType.trip.accentColor)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                .frame(width: 32, alignment: .center)
                .frame(maxHeight: .infinity)

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Trip info
            VStack(alignment: .leading, spacing: 2) {
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
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT: Date range
            VStack(alignment: .trailing, spacing: 2) {
                Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(JohoFont.monoSmall)
                    .foregroundStyle(JohoColors.black)

                Text("→ \(trip.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(JohoFont.monoSmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxHeight: .infinity)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    /// 情報デザイン: Bento pinned countdown row
    @ViewBuilder
    private func bentoPinnedRow(note: DailyNote, daysRemaining: Int) -> some View {
        let (title, _) = titleAndSubtitle(from: note.content)
        let badgeText = countdownBadgeText(days: daysRemaining)

        HStack(spacing: 0) {
            // LEFT: Pin indicator
            Image(systemName: "pin.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(JohoColors.black)
                .frame(width: 32, alignment: .center)
                .frame(maxHeight: .infinity)

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Content
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: note.symbolName ?? "note.text")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)

                    Text(note.day.formatted(date: .abbreviated, time: .omitted))
                        .font(JohoFont.monoSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer(minLength: 4)
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Vertical wall
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT: Countdown badge
            JohoPill(text: badgeText, style: .whiteOnBlack, size: .small)
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(maxHeight: .infinity)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
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
                Image(systemName: note.symbolName ?? "note.text")
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
        holidays: [.init(id: "preview", name: "Holiday", isBankHoliday: true, symbolName: "flag.fill")],
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
            Image(systemName: note.symbolName ?? "note.text")
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
