//
//  DayDashboardView.swift
//  Vecka
//
//  Inline "dashboard" beneath the month grid - Japanese Packaging Design
//  Updated to work with unified Memo model
//

import SwiftUI

// MARK: - Event Text Color Setting

/// 情報デザイン: Classic Japanese planner text colors
enum EventTextColor: String, CaseIterable {
    case black = "black"
    case red = "red"
    case blue = "blue"

    var color: Color {
        switch self {
        case .black: return Color.black
        case .red: return Color(hex: "D32F2F")  // Deep red
        case .blue: return Color(hex: "1976D2")  // Deep blue
        }
    }

    var darkModeColor: Color {
        switch self {
        case .black: return Color.white
        case .red: return Color(hex: "EF5350")  // Lighter red for dark mode
        case .blue: return Color(hex: "42A5F5")  // Lighter blue for dark mode
        }
    }

    var displayName: String {
        switch self {
        case .black: return "Black"
        case .red: return "Red"
        case .blue: return "Blue"
        }
    }
}

struct DayDashboardView: View {
    struct HolidayInfo: Identifiable, Equatable {
        let id: String
        let name: String
        let isBankHoliday: Bool
        let symbolName: String?
        let regionCode: String?  // ISO country code (SE, JP, US, etc.)

        /// 情報デザイン: Flag emoji from region code
        var flag: String? {
            guard let code = regionCode?.uppercased(), code.count == 2 else { return nil }
            let base: UInt32 = 127397
            var emoji = ""
            for scalar in code.unicodeScalars {
                if let flagScalar = UnicodeScalar(base + scalar.value) {
                    emoji.append(Character(flagScalar))
                }
            }
            return emoji.isEmpty ? nil : emoji
        }
    }

    struct BirthdayInfo: Identifiable, Equatable {
        let id: String
        let name: String
        let age: Int?  // nil if birth year unknown
    }

    let date: Date
    let memos: [Memo]
    let holidays: [HolidayInfo]
    let birthdays: [BirthdayInfo]  // 情報デザイン: Contact birthdays
    let secondaryDateText: String?
    let onOpenMemos: (_ date: Date) -> Void
    var onAddEntry: (() -> Void)? = nil  // 情報デザイン: Opens add entry menu

    /// 情報デザイン: Check if day has any content
    private var hasAnyContent: Bool {
        !holidays.isEmpty || !birthdays.isEmpty || !memos.isEmpty
    }

    @State private var isExpanded = false

    @Environment(\.locale) private var locale
    @Environment(\.johoColorMode) private var colorMode
    @AppStorage("eventTextColor") private var eventTextColorRaw = "black"

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// 情報デザイン: Event text color respecting dark mode
    private var eventTextColor: Color {
        let setting = EventTextColor(rawValue: eventTextColorRaw) ?? .black
        return colorMode == .dark ? setting.darkModeColor : setting.color
    }

    /// 情報デザイン: Border color for dark mode (white borders)
    private var eventBorderColor: Color {
        colorMode == .dark ? Color.white : Color.black
    }

    private let previewLimit = 3

    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    // Computed memo categories
    private var noteMemos: [Memo] {
        memos.filter { !$0.hasMoney && !$0.hasPlace }
    }

    private var expenseMemos: [Memo] {
        memos.filter { $0.hasMoney }
    }

    private var tripMemos: [Memo] {
        memos.filter { $0.hasPlace && !$0.hasMoney }
    }

    private var visibleMemos: [Memo] {
        isExpanded ? noteMemos : Array(noteMemos.prefix(previewLimit))
    }

    private var showExpandToggle: Bool {
        noteMemos.count > previewLimit
    }

    // MARK: - Joho Design System Body
    // 情報デザイン: Single Bento containing header + content grid

    var body: some View {
        VStack(spacing: 0) {
            // Single combined Bento
            dayBento
        }
    }

    // MARK: - Combined Day Bento (情報デザイン: Grid compartments like RANDOM FACTS)

    private var dayBento: some View {
        VStack(spacing: 0) {
            // Top row: Date header cell + Add button
            HStack(spacing: JohoDimensions.spacingSM) {
                // Date compartment (squircle cell)
                dateCell

                Spacer()

                // Add button
                if let onAddEntry {
                    Button(action: onAddEntry) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(colors.primary)
                    }
                    .frame(width: 40, height: 40)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: 10))
                    .overlay(
                        Squircle(cornerRadius: 10)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
                    .buttonStyle(.plain)
                }
            }
            .padding(JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1)

            // Content grid: empty state OR item cells
            if !hasAnyContent {
                emptyStateContent
                    .padding(JohoDimensions.spacingSM)
            } else {
                contentCellGrid
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

    // MARK: - Date Cell (情報デザイン: Header compartment)

    private var dateCell: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formattedDate)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)

            Text(subtitleText ?? "")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(colors.secondary)
        }
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.vertical, 6)
        .background(
            Calendar.current.isDateInToday(date) ? JohoColors.yellow.opacity(0.3) : Color.clear
        )
        .clipShape(Squircle(cornerRadius: 8))
    }

    // MARK: - Content Cell Grid (情報デザイン: 2-column grid of compartments)

    private var contentCellGrid: some View {
        let allItems = buildGridItems()
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: JohoDimensions.spacingSM) {
            ForEach(allItems) { item in
                gridCell(item: item)
            }
        }
    }

    // MARK: - Grid Item Model

    private struct DayGridItem: Identifiable {
        let id: String
        let title: String
        let subtitle: String?
        let flag: String?        // Country code or category
        let badge: String?       // HOLIDAY/OBSERVANCE, amount, etc.
        let zone: BentoZone
        let action: (() -> Void)?
    }

    private func buildGridItems() -> [DayGridItem] {
        var items: [DayGridItem] = []

        // Holidays
        for holiday in holidays.prefix(4) {
            items.append(DayGridItem(
                id: "h-\(holiday.id)",
                title: holiday.name,
                subtitle: nil,
                flag: holiday.regionCode?.uppercased(),
                badge: holiday.isBankHoliday ? "HOLIDAY" : "OBSERVANCE",
                zone: .holidays,
                action: nil
            ))
        }

        // Birthdays
        for birthday in birthdays.prefix(2) {
            let ageText = birthday.age.map { "TURNS \($0)" }
            items.append(DayGridItem(
                id: "b-\(birthday.id)",
                title: birthday.name,
                subtitle: ageText,
                flag: nil,
                badge: nil,
                zone: .birthdays,
                action: nil
            ))
        }

        // Expenses
        for memo in expenseMemos.prefix(2) {
            let amountText = memo.amount.map { String(format: "%.0f", $0) }
            items.append(DayGridItem(
                id: "e-\(memo.id)",
                title: memo.preview,
                subtitle: nil,
                flag: memo.currency ?? baseCurrency,
                badge: amountText,
                zone: .expenses,
                action: { onOpenMemos(date) }
            ))
        }

        // Trips
        for memo in tripMemos.prefix(2) {
            items.append(DayGridItem(
                id: "t-\(memo.id)",
                title: memo.place ?? memo.preview,
                subtitle: memo.place != nil ? memo.preview : nil,
                flag: nil,
                badge: nil,
                zone: .trips,
                action: { onOpenMemos(date) }
            ))
        }

        // Notes
        for memo in noteMemos.prefix(2) {
            items.append(DayGridItem(
                id: "n-\(memo.id)",
                title: memo.preview,
                subtitle: nil,
                flag: memo.priority.symbol,
                badge: nil,
                zone: .notes,
                action: { onOpenMemos(date) }
            ))
        }

        return items
    }

    // MARK: - Grid Cell (情報デザイン: Colored compartment with flag/badge)

    private func gridCell(item: DayGridItem) -> some View {
        Button {
            item.action?()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // Top row: flag + badge
                HStack {
                    if let flag = item.flag {
                        Text(flag)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .stroke(colors.border.opacity(0.5), lineWidth: 0.5)
                            )
                    }

                    Spacer()

                    if let badge = item.badge {
                        Text(badge)
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(item.zone == .holidays ? colors.surfaceInverted : item.zone.accentColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(item.zone == .holidays && item.badge == "HOLIDAY" ? JohoColors.red : colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                }

                Spacer()

                // Title
                Text(item.title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Subtitle
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 9, weight: .regular, design: .rounded))
                        .foregroundStyle(colors.secondary)
                        .lineLimit(1)
                }
            }
            .padding(JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
            .background(item.zone.accentColor.opacity(colorMode == .dark ? 0.2 : 0.3))
            .clipShape(Squircle(cornerRadius: 10))
            .overlay(
                Squircle(cornerRadius: 10)
                    .stroke(colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }


    // MARK: - Empty State Content (情報デザイン: Inside combined Bento)

    private var emptyStateContent: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            Text(Localization.noSpecialDays)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoDimensions.spacingMD)
    }

    // MARK: - Day Header Row (情報デザイン: Inside combined Bento)

    private var dayHeaderRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                // Date badge
                Text(headerBadge)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.surfaceInverted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                // Main date
                Text(formattedDate)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)

                // Subtitle (week + secondary)
                if let subtitle = subtitleText, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }

            Spacer()

            // Add button
            if let onAddEntry {
                Button(action: onAddEntry) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(colors.primary)
                        .frame(width: 44, height: 44)
                        .background(colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(colors.border, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var headerBadge: String {
        Calendar.current.isDateInToday(date) ? "TODAY" : weekdayName
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
        return formatter.string(from: date).uppercased()
    }

    private var subtitleText: String? {
        let week = Localization.weekDisplayText(Calendar.iso8601.component(.weekOfYear, from: date))
        let secondary = (secondaryDateText ?? "").trimmingCharacters(in: .whitespaces)
        if secondary.isEmpty { return week }
        return "\(week) • \(secondary)"
    }

    // MARK: - Bento Section

    enum BentoZone {
        case holidays
        case birthdays
        case notes
        case expenses
        case trips

        var accentColor: Color {
            switch self {
            case .holidays: return JohoColors.pink
            case .birthdays: return JohoColors.pink
            case .notes: return JohoColors.yellow
            case .expenses: return JohoColors.green
            case .trips: return JohoColors.cyan
            }
        }
    }

    // 情報デザイン: Flat section - just label + content (no nested box/border/divider)
    private func bentoSection<Content: View>(
        title: String,
        icon: String,
        zone: BentoZone,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // Section label with colored dot
            HStack(spacing: 6) {
                Circle()
                    .fill(zone.accentColor)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(colors.secondary)
            }

            // Content rows
            VStack(alignment: .leading, spacing: 2) {
                content()
            }
        }
    }

    // MARK: - Row Views

    private func bentoHolidayRow(holiday: HolidayInfo) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Country code badge (情報デザイン: Minimal text, not emoji flags)
            if let code = holiday.regionCode?.uppercased() {
                Text(code)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                    .frame(width: 22)
            }

            // Holiday name
            Text(holiday.name)
                .font(JohoFont.bodySmall)
                .foregroundStyle(eventTextColor)
                .lineLimit(1)

            // Holiday type badge
            Text(holiday.isBankHoliday ? "HOLIDAY" : "OBSERVANCE")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(colors.surfaceInverted)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(holiday.isBankHoliday ? JohoColors.red : JohoColors.cyan)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func bentoBirthdayRow(birthday: BirthdayInfo) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Text(birthday.name)
                .font(JohoFont.bodySmall)
                .foregroundStyle(eventTextColor)
                .lineLimit(1)

            if let age = birthday.age, age > 0 {
                Text("TURNS \(age)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func bentoExpenseRow(memo: Memo) -> some View {
        Button {
            onOpenMemos(date)
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Description
                Text(memo.preview)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(eventTextColor)
                    .lineLimit(1)

                Spacer()

                // Amount
                if let amount = memo.amount {
                    Text(String(format: "%.0f %@", amount, memo.currency ?? baseCurrency))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.green)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    private func bentoTripRow(memo: Memo) -> some View {
        Button {
            onOpenMemos(date)
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Place
                Text(memo.place ?? memo.preview)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(eventTextColor)
                    .lineLimit(1)

                Spacer()

                // Note preview
                if memo.place != nil && !memo.text.isEmpty {
                    Text(memo.preview)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(colors.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    private func bentoNoteRow(memo: Memo) -> some View {
        Button {
            onOpenMemos(date)
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Priority symbol
                Text(memo.priority.symbol)
                    .font(.system(size: 12))

                // Color indicator
                Circle()
                    .fill(Color(hex: memo.colorHex))
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(colors.border, lineWidth: 0.5))

                // Text
                Text(memo.preview)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(eventTextColor)
                    .lineLimit(isExpanded ? 3 : 1)

                Spacer()

                // Person indicator
                if memo.hasPerson {
                    Circle()
                        .fill(JohoColors.purple)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let memo1 = Memo(text: "Buy groceries for dinner", date: Date())
    let memo2 = Memo(text: "Lunch meeting", date: Date())
    memo2.amount = 145
    memo2.currency = "SEK"
    let memo3 = Memo(text: "Team sync", date: Date())
    memo3.place = "Office"

    return DayDashboardView(
        date: Date(),
        memos: [memo1, memo2, memo3],
        holidays: [
            DayDashboardView.HolidayInfo(id: "1", name: "Midsummer Eve", isBankHoliday: true, symbolName: "sun.max.fill", regionCode: "SE"),
            DayDashboardView.HolidayInfo(id: "2", name: "元日", isBankHoliday: true, symbolName: nil, regionCode: "JP")
        ],
        birthdays: [
            DayDashboardView.BirthdayInfo(id: "1", name: "Anna", age: 30)
        ],
        secondaryDateText: nil,
        onOpenMemos: { _ in }
    )
    .modelContainer(for: Memo.self, inMemory: true)
    .padding()
}
