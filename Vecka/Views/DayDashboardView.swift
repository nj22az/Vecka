//
//  DayDashboardView.swift
//  Vecka
//
//  Inline "dashboard" beneath the month grid - Japanese Packaging Design
//  Updated to work with unified Memo model
//

import SwiftUI
import SwiftData

struct DayDashboardView: View {
    struct HolidayInfo: Identifiable, Equatable {
        let id: String
        let name: String
        let isBankHoliday: Bool
        let symbolName: String?
        let regionCode: String?  // ISO country code (SE, JP, US, etc.)
        let ruleID: String?      // HolidayRule.id for persistent editing

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
        !holidays.isEmpty || !memos.isEmpty || !birthdays.isEmpty
    }

    @State private var isExpanded = false
    @State private var showSummarySheet = false
    @State private var selectedMemo: Memo? = nil  // For single memo detail view
    @State private var selectedHoliday: HolidayInfo? = nil  // For single holiday detail view
    @State private var selectedBirthday: BirthdayInfo? = nil  // For single birthday detail view

    @Environment(\.locale) private var locale
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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

    /// Data model for shareable summary
    private var summaryData: DaySummaryData {
        DaySummaryData(
            date: date,
            holidays: holidays,
            birthdays: birthdays,
            memos: memos,
            secondaryDateText: secondaryDateText
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            dayBento
        }
        .sheet(isPresented: $showSummarySheet) {
            DaySummarySheetView(
                data: summaryData,
                onDismiss: { showSummarySheet = false },
                onOpenMemos: onOpenMemos
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedMemo) { memo in
            SingleMemoDetailSheet(memo: memo, date: date)
        }
        .sheet(item: $selectedHoliday) { holiday in
            SingleHolidayDetailSheet(holiday: holiday, date: date)
        }
        .sheet(item: $selectedBirthday) { birthday in
            SingleBirthdayDetailSheet(birthday: birthday, date: date)
        }
    }

    // MARK: - Combined Day Bento (情報デザイン: Clean vertical layout)

    private var dayBento: some View {
        VStack(spacing: 0) {
            // Header row: Date + Add button
            HStack(spacing: 0) {
                // Date compartment
                VStack(alignment: .leading, spacing: 2) {
                    // Day number + weekday
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(isToday ? JohoColors.todayOrange : colors.primary)

                        Text(weekdayName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }

                    // Month + week + secondary text
                    HStack(spacing: 6) {
                        Text(monthName.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)

                        Text("•")
                            .foregroundStyle(colors.secondary.opacity(0.5))

                        Text(Localization.weekDisplayText(Calendar.iso8601.component(.weekOfYear, from: date)))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)

                        if let secondary = secondaryDateText, !secondary.isEmpty {
                            Text("•")
                                .foregroundStyle(colors.secondary.opacity(0.5))
                            Text(secondary)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.secondary)
                        }
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)

                Spacer()

                // Share button - opens full day summary sheet
                Button {
                    showSummarySheet = true
                    HapticManager.selection()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(colors.primary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .frame(minHeight: 60)

            // Horizontal divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Content: memo cards are individually tappable
            if !hasAnyContent {
                emptyStateContent
                    .padding(JohoDimensions.spacingMD)
            } else {
                contentCardGrid
                    .padding(JohoDimensions.spacingSM)
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = locale
        return formatter.string(from: date)
    }


    // MARK: - Content Card Grid (情報デザイン: Quirky facts style tiles)

    private var contentCardGrid: some View {
        let items = buildCardItems()
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: JohoDimensions.spacingSM) {
            ForEach(items) { item in
                summaryCardTile(item)
            }
        }
    }

    // MARK: - Card Item Model

    private enum CardItemType {
        case holiday(HolidayInfo)
        case memo(Memo)
        case birthday(BirthdayInfo)
    }

    private struct CardItem: Identifiable {
        let id: String
        let icon: String
        let color: Color
        let title: String
        let badge: String?
        let itemType: CardItemType
    }

    private func buildCardItems() -> [CardItem] {
        var items: [CardItem] = []

        // Holidays (max 2) - tappable
        for holiday in holidays.prefix(2) {
            items.append(CardItem(
                id: "h-\(holiday.id)",
                icon: holiday.isBankHoliday ? "star.fill" : "calendar",
                color: holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance),
                title: holiday.name,
                badge: holiday.isBankHoliday ? "HOLIDAY" : nil,
                itemType: .holiday(holiday)
            ))
        }

        // Birthdays (from Contacts) - 情報デザイン: Pink celebration color
        let birthdaySlots = max(0, 4 - items.count)
        for birthday in birthdays.prefix(birthdaySlots) {
            let ageText = birthday.age.map { "Turns \($0)" }
            items.append(CardItem(
                id: "b-\(birthday.id)",
                icon: "birthday.cake.fill",
                color: JohoColors.pink,
                title: birthday.name,
                badge: ageText,
                itemType: .birthday(birthday)
            ))
        }

        // Memos (fill remaining up to 6 total) - tappable
        let remainingSlots = max(0, 6 - items.count)
        for memo in memos.prefix(remainingSlots) {
            items.append(CardItem(
                id: "m-\(memo.id)",
                icon: memoIcon(for: memo),
                color: memoColor(for: memo),
                title: memo.preview,
                badge: memo.amount.map { String(format: "%.0f", $0) },
                itemType: .memo(memo)
            ))
        }

        return items
    }

    // MARK: - Summary Card Tile (情報デザイン: Quirky facts style)

    @ViewBuilder
    private func summaryCardTile(_ item: CardItem) -> some View {
        let tileContent = VStack(spacing: 0) {
            // TOP: Icon zone with colored background
            ZStack {
                // Icon with subtle shadow for contrast on light backgrounds
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.15))
                    .offset(x: 0.5, y: 0.5)

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(item.color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(item.color.opacity(0.3))

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // BOTTOM: Text zone
            VStack(spacing: 1) {
                Text(item.title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                if let badge = item.badge {
                    Text(badge)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(item.color.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(colors.border, lineWidth: 1.5)
        )

        // All items are tappable - opens appropriate detail view
        Button {
            HapticManager.selection()
            switch item.itemType {
            case .memo(let memo):
                selectedMemo = memo
            case .holiday(let holiday):
                selectedHoliday = holiday
            case .birthday(let birthday):
                selectedBirthday = birthday
            }
        } label: {
            tileContent
        }
        .buttonStyle(.plain)
    }

    private func memoIcon(for memo: Memo) -> String {
        // Birthday memos (linked to contact or has birthday symbol)
        if memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill" {
            return "gift.fill"
        }
        if memo.hasMoney { return currencyIcon(for: memo.currency ?? baseCurrency) }
        if memo.hasPlace { return "airplane" }
        return "note.text"
    }

    private func memoColor(for memo: Memo) -> Color {
        // 情報デザイン: Semantic color system
        // Person/birthday memos use purple (PEOPLE)
        if memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill" || memo.hasPerson {
            return JohoColors.purple  // Purple (人) - PEOPLE
        }
        // Money memos use green (MONEY)
        if memo.hasMoney { return JohoColors.green }  // Green (金) - MONEY
        // Place/trip memos use cyan (SCHEDULED)
        if memo.hasPlace { return JohoColors.cyan }  // Cyan (予定) - SCHEDULED
        // Default memos use yellow (NOW)
        return JohoColors.yellow  // Yellow - NOW (notes, today, memos)
    }

    /// Get SF Symbol for currency code
    private func currencyIcon(for currency: String) -> String {
        switch currency.uppercased() {
        case "USD": return "dollarsign.circle.fill"
        case "EUR": return "eurosign.circle.fill"
        case "GBP": return "sterlingsign.circle.fill"
        case "JPY": return "yensign.circle.fill"
        case "CNY", "RMB": return "yensign.circle.fill"
        case "KRW": return "wonsign.circle.fill"
        case "INR": return "indianrupeesign.circle.fill"
        case "RUB": return "rublesign.circle.fill"
        case "BRL": return "brazilianrealsign.circle.fill"
        case "THB": return "bahtsign.circle.fill"
        case "TRY": return "turkishlirasign.circle.fill"
        case "SEK", "NOK", "DKK", "ISK": return "swedishkronasign.circle.fill"
        case "CHF": return "francsign.circle.fill"
        case "PLN": return "polishzlotysign.circle.fill"
        case "MXN", "ARS", "CLP", "COP": return "pesosign.circle.fill"
        default: return "banknote.fill"
        }
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
            case .holidays: return JohoColors.pink      // Holidays = pink (CELEBRATION)
            case .birthdays: return JohoColors.pink     // Birthdays = pink (CELEBRATION)
            case .notes: return JohoColors.yellow       // Notes = yellow (NOW)
            case .expenses: return JohoColors.green     // Expenses = green (MONEY)
            case .trips: return JohoColors.cyan         // Trips = cyan (SCHEDULED)
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
                .foregroundStyle(colors.primary)
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
                .foregroundStyle(colors.primary)
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
                    .foregroundStyle(colors.primary)
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
                    .foregroundStyle(colors.primary)
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
                    .foregroundStyle(colors.primary)
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

// MARK: - Single Memo Detail Sheet (情報デザイン: Quirky Fact style - matches RandomFactDetailSheet)

struct SingleMemoDetailSheet: View {
    let memo: Memo
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    // Share customization state (temporary, not persisted)
    @State private var showIconPicker = false
    @State private var customIcon: String? = nil
    @State private var personalNote: String = ""
    @State private var showShareOptions = false

    // Permanent icon editing state
    @State private var showPermanentIconPicker = false
    @State private var permanentIconSelection: String = ""

    private var memoIcon: String {
        if memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill" { return "gift.fill" }
        if memo.hasMoney { return currencyIcon(for: memo.currency ?? baseCurrency) }
        if memo.hasPlace { return "airplane" }
        return "note.text"
    }

    /// Get SF Symbol for currency code
    private func currencyIcon(for currency: String) -> String {
        switch currency.uppercased() {
        case "USD": return "dollarsign.circle.fill"
        case "EUR": return "eurosign.circle.fill"
        case "GBP": return "sterlingsign.circle.fill"
        case "JPY": return "yensign.circle.fill"
        case "CNY", "RMB": return "yensign.circle.fill"
        case "KRW": return "wonsign.circle.fill"
        case "INR": return "indianrupeesign.circle.fill"
        case "RUB": return "rublesign.circle.fill"
        case "BRL": return "brazilianrealsign.circle.fill"
        case "THB": return "bahtsign.circle.fill"
        case "TRY": return "turkishlirasign.circle.fill"
        case "SEK", "NOK", "DKK", "ISK": return "swedishkronasign.circle.fill"
        case "CHF": return "francsign.circle.fill"
        case "PLN": return "polishzlotysign.circle.fill"
        case "MXN", "ARS", "CLP", "COP": return "pesosign.circle.fill"
        default: return "banknote.fill"
        }
    }

    private var memoColor: Color {
        // 情報デザイン: Semantic color system
        if memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill" || memo.hasPerson {
            return JohoColors.purple  // Purple (人) - PEOPLE
        }
        if memo.hasMoney { return JohoColors.green }  // Green (金) - MONEY
        if memo.hasPlace { return JohoColors.cyan }  // Cyan (予定) - SCHEDULED
        return JohoColors.yellow  // Yellow - NOW (notes, today, memos)
    }

    private var categoryLabel: String {
        if memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill" { return "BIRTHDAY" }
        if memo.hasMoney { return "EXPENSE" }
        if memo.hasPlace { return "TRIP" }
        return "MEMO"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: memo.date)
    }

    /// Full date stamp for shareable: YYYYMMDD · W{n}
    private var fullDateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let weekNumber = Calendar.iso8601.component(.weekOfYear, from: date)
        return "\(formatter.string(from: date)) · W\(weekNumber)"
    }

    /// The icon to display (custom or default)
    private var displayIcon: String {
        customIcon ?? memoIcon
    }

    var body: some View {
        VStack(spacing: 0) {
            // DARK HEADER (outside card) - matches RandomFactDetailSheet
            HStack {
                Text(categoryLabel)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primaryInverted)

                Spacer()

                // Share button
                if #available(iOS 16.0, *) {
                    SingleMemoShareButton(
                        memo: memo,
                        date: date,
                        customIcon: customIcon,
                        personalNote: personalNote.isEmpty ? nil : personalNote
                    )
                }

                // Close button
                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(colors.surface)
                            .frame(width: 28, height: 28)
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(colors.surfaceInverted)

            // CARD CONTENT - single VStack with background/clip/overlay on same view
            VStack(spacing: 0) {
                // Large icon zone (情報デザイン: Hero display)
                VStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: displayIcon)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(memoColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(memoColor.opacity(0.2))

                // Thick divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // Title (date)
                Text(formattedDate)
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

                // Memo text (情報デザイン: Full content)
                Text(memo.text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, JohoDimensions.spacingMD)

                // Footer: category + time
                HStack {
                    Text(categoryLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    Text(formattedTime)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.4))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.top, JohoDimensions.spacingSM)
                .padding(.bottom, JohoDimensions.spacingMD)

                // ITEM ICON - persistent editing
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1)

                itemIconSection

                // SHARE OPTIONS - collapsible section
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1)

                // Share options toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showShareOptions.toggle()
                    }
                } label: {
                    HStack {
                        Text("SHARE OPTIONS")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                            .tracking(0.5)

                        Spacer()

                        Image(systemName: showShareOptions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(colors.primary.opacity(0.4))
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingSM)
                }
                .buttonStyle(.plain)

                if showShareOptions {
                    VStack(spacing: JohoDimensions.spacingSM) {
                        // Icon picker row
                        Button {
                            showIconPicker = true
                        } label: {
                            HStack {
                                Text("ICON")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.5))

                                Spacer()

                                Image(systemName: displayIcon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(memoColor)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(colors.primary.opacity(0.3))
                            }
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                        }
                        .buttonStyle(.plain)

                        // Personal note field
                        HStack {
                            Text("NOTE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.5))

                            TextField("Add personal note...", text: $personalNote)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                        }
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM)

                        // Date stamp preview
                        HStack {
                            Text("DATE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.5))

                            Spacer()

                            Text(fullDateStamp)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(colors.primary.opacity(0.7))
                        }
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM)
                    }
                    .background(colors.surface.opacity(0.5))
                }
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
        .background(memoColor.opacity(0.3))
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(JohoDimensions.radiusLarge)
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showIconPicker) {
            JohoSFSymbolPickerSheet(
                selectedSymbol: Binding(
                    get: { customIcon ?? memoIcon },
                    set: { customIcon = $0 }
                ),
                accentColor: memoColor,
                lightBackground: memoColor.opacity(0.2),
                onDone: {}
            )
        }
        .sheet(isPresented: $showPermanentIconPicker) {
            JohoSFSymbolPickerSheet(
                selectedSymbol: $permanentIconSelection,
                accentColor: CategoryColorSettings.shared.color(for: .memo),
                lightBackground: CategoryColorSettings.shared.color(for: .memo).opacity(0.2),
                onDone: {
                    savePermanentMemoIcon(permanentIconSelection)
                }
            )
        }
        .onAppear {
            permanentIconSelection = memo.symbolName ?? memoIcon
        }
    }

    // MARK: - Save Permanent Memo Icon

    private func savePermanentMemoIcon(_ iconName: String) {
        memo.symbolName = iconName == memoIcon ? nil : iconName
        try? modelContext.save()
        HapticManager.notification(.success)
    }

    // MARK: - Item Icon Section

    private var itemIconSection: some View {
        VStack(spacing: 0) {
            Button {
                showPermanentIconPicker = true
            } label: {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(CategoryColorSettings.shared.color(for: .memo))
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        Text("ITEM ICON")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: memo.symbolName ?? memoIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(CategoryColorSettings.shared.color(for: .memo))

                        if memo.symbolName != nil {
                            Text("CUSTOM")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(colors.primary.opacity(0.3))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingMD)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Single Memo Share Button

@available(iOS 16.0, *)
struct SingleMemoShareButton: View {
    let memo: Memo
    let date: Date
    var customIcon: String? = nil
    var personalNote: String? = nil

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var snapshot: SingleMemoSnapshot {
        SingleMemoSnapshot(
            memo: memo,
            date: date,
            size: CGSize(width: 340, height: 0),
            customIcon: customIcon,
            personalNote: personalNote
        )
    }

    var body: some View {
        ShareLink(
            item: snapshot,
            preview: SharePreview(
                memo.preview,
                image: Image(systemName: customIcon ?? "note.text")
            )
        ) {
            ZStack {
                Circle()
                    .fill(colors.surface)
                    .frame(width: 28, height: 28)
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Single Memo Snapshot (Transferable)

@available(iOS 16.0, *)
struct SingleMemoSnapshot: Transferable, @unchecked Sendable {
    let memo: Memo
    let date: Date
    let size: CGSize
    var customIcon: String? = nil
    var personalNote: String? = nil

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { snapshot in
            await snapshot.renderToPNG()
        }
    }

    @MainActor
    func renderToPNG() -> Data {
        let renderer = ImageRenderer(content: shareableView())
        renderer.scale = 3.0
        renderer.isOpaque = false

        guard let uiImage = renderer.uiImage else {
            return Data()
        }

        return uiImage.pngData() ?? Data()
    }

    @MainActor
    func shareableView() -> some View {
        ShareableMemoCard(
            memo: memo,
            date: date,
            customIcon: customIcon,
            personalNote: personalNote
        )
        .frame(width: size.width)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Shareable Memo Card (情報デザイン: Exact Quirky Facts style)

struct ShareableMemoCard: View {
    let memo: Memo
    let date: Date
    var isShareable: Bool = false
    var customIcon: String? = nil
    var personalNote: String? = nil

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let cornerRadius: CGFloat = 16

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    private var defaultMemoIcon: String {
        if memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill" { return "gift.fill" }
        if memo.hasMoney { return currencyIcon(for: memo.currency ?? baseCurrency) }
        if memo.hasPlace { return "airplane" }
        return "note.text"
    }

    /// The icon to display (custom or default)
    private var displayIcon: String {
        customIcon ?? defaultMemoIcon
    }

    /// Get SF Symbol for currency code
    private func currencyIcon(for currency: String) -> String {
        switch currency.uppercased() {
        case "USD": return "dollarsign.circle.fill"
        case "EUR": return "eurosign.circle.fill"
        case "GBP": return "sterlingsign.circle.fill"
        case "JPY": return "yensign.circle.fill"
        case "CNY", "RMB": return "yensign.circle.fill"
        case "KRW": return "wonsign.circle.fill"
        case "INR": return "indianrupeesign.circle.fill"
        case "RUB": return "rublesign.circle.fill"
        case "BRL": return "brazilianrealsign.circle.fill"
        case "THB": return "bahtsign.circle.fill"
        case "TRY": return "turkishlirasign.circle.fill"
        case "SEK", "NOK", "DKK", "ISK": return "swedishkronasign.circle.fill"
        case "CHF": return "francsign.circle.fill"
        case "PLN": return "polishzlotysign.circle.fill"
        case "MXN", "ARS", "CLP", "COP": return "pesosign.circle.fill"
        default: return "banknote.fill"
        }
    }

    private var memoColor: Color {
        // 情報デザイン: Semantic color system
        if memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill" || memo.hasPerson {
            return JohoColors.purple  // Purple (人) - PEOPLE
        }
        if memo.hasMoney { return JohoColors.green }  // Green (金) - MONEY
        if memo.hasPlace { return JohoColors.cyan }  // Cyan (予定) - SCHEDULED
        return JohoColors.yellow  // Yellow - NOW (notes, today, memos)
    }

    private var categoryLabel: String {
        if memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill" { return "BIRTHDAY" }
        if memo.hasMoney { return "EXPENSE" }
        if memo.hasPlace { return "TRIP" }
        return "MEMO"
    }

    /// Full date stamp: YYYYMMDD · W{n}
    private var fullDateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let weekNumber = Calendar.iso8601.component(.weekOfYear, from: date)
        return "\(formatter.string(from: date)) · W\(weekNumber)"
    }

    var body: some View {
        ZStack {
            // Layer 1: Solid background
            cardShape.fill(colors.surface)

            // Layer 2: Content
            VStack(spacing: 0) {
                // HEADER: Branding + icon
                HStack(spacing: 0) {
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                        Text("ONSEN PLANNER")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(.leading, JohoDimensions.spacingMD)

                    Spacer()

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // Icon (customizable)
                    Image(systemName: displayIcon)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(memoColor)
                        .frame(width: 48)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 40)
                .background(memoColor.opacity(0.5))

                // Divider
                Rectangle().fill(colors.border).frame(height: 2)

                // DATE STAMP row
                HStack {
                    Text(fullDateStamp)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(colors.primary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(colors.surface)

                // Divider
                Rectangle().fill(colors.border).frame(height: 1)

                // MAIN CONTENT: Large icon + text
                HStack(alignment: .top, spacing: 0) {
                    // LEFT: Large icon (customizable)
                    VStack {
                        Spacer()
                        Image(systemName: displayIcon)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(memoColor)
                        Spacer()
                    }
                    .frame(width: 100)
                    .frame(minHeight: 120)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)

                    // RIGHT: Text content
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        Text(titleText)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)

                        Text(memo.text)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                            .lineLimit(isShareable ? nil : 3)
                            .multilineTextAlignment(.leading)

                        // Personal note (if provided)
                        if let note = personalNote, !note.isEmpty {
                            Rectangle()
                                .fill(colors.border.opacity(0.3))
                                .frame(height: 1)
                                .padding(.vertical, 4)

                            Text(note)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.5))
                                .italic()
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120)
                .background(memoColor.opacity(0.15))

                // Divider
                Rectangle().fill(colors.border).frame(height: 2)

                // FOOTER
                HStack {
                    Text(categoryLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    Text("ONSEN PLANNER")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.3))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(height: 32)
            }
            .clipShape(cardShape)

            // Layer 3: Border
            cardShape.strokeBorder(colors.border, lineWidth: 3)
        }
    }

    private var titleText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Single Holiday Detail Sheet (情報デザイン: Quirky Fact style - matches RandomFactDetailSheet)

struct SingleHolidayDetailSheet: View {
    let holiday: DayDashboardView.HolidayInfo
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Share customization state (temporary, not persisted)
    @State private var showIconPicker = false
    @State private var customIcon: String? = nil
    @State private var personalNote: String = ""
    @State private var showShareOptions = false

    // Permanent icon editing state
    @State private var showPermanentIconPicker = false
    @State private var permanentIconSelection: String = ""

    private var categoryLabel: String {
        holiday.isBankHoliday ? "HOLIDAY" : "OBSERVANCE"
    }

    private var defaultHolidayIcon: String {
        holiday.symbolName ?? (holiday.isBankHoliday ? "star.fill" : "calendar")
    }

    /// The icon to display (custom or default)
    private var displayIcon: String {
        customIcon ?? defaultHolidayIcon
    }

    private var holidayColor: Color {
        holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    /// Full date stamp for shareable: YYYYMMDD · W{n}
    private var fullDateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let weekNumber = Calendar.iso8601.component(.weekOfYear, from: date)
        return "\(formatter.string(from: date)) · W\(weekNumber)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // DARK HEADER (outside card) - matches RandomFactDetailSheet
            HStack {
                Text(categoryLabel)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primaryInverted)

                Spacer()

                // Share button
                if #available(iOS 16.0, *) {
                    SingleHolidayShareButton(
                        holiday: holiday,
                        date: date,
                        customIcon: customIcon,
                        personalNote: personalNote.isEmpty ? nil : personalNote
                    )
                }

                // Close button
                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(colors.surface)
                            .frame(width: 28, height: 28)
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(colors.surfaceInverted)

            // CARD CONTENT - single VStack with background/clip/overlay on same view
            VStack(spacing: 0) {
                // Large icon zone (情報デザイン: Hero display)
                VStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: displayIcon)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(holidayColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(holidayColor.opacity(0.2))

                // Thick divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // Title (date)
                Text(formattedDate)
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

                // Holiday name (情報デザイン: Full content)
                Text(holiday.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, JohoDimensions.spacingMD)

                // Footer: category + region code
                HStack {
                    Text(categoryLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    if let code = holiday.regionCode {
                        Text(code.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.4))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.top, JohoDimensions.spacingSM)
                .padding(.bottom, JohoDimensions.spacingMD)

                // ITEM ICON - persistent editing
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1)

                holidayItemIconSection

                // SHARE OPTIONS - collapsible section
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1)

                // Share options toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showShareOptions.toggle()
                    }
                } label: {
                    HStack {
                        Text("SHARE OPTIONS")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                            .tracking(0.5)

                        Spacer()

                        Image(systemName: showShareOptions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(colors.primary.opacity(0.4))
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingSM)
                }
                .buttonStyle(.plain)

                if showShareOptions {
                    VStack(spacing: JohoDimensions.spacingSM) {
                        // Icon picker row
                        Button {
                            showIconPicker = true
                        } label: {
                            HStack {
                                Text("ICON")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.5))

                                Spacer()

                                Image(systemName: displayIcon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(holidayColor)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(colors.primary.opacity(0.3))
                            }
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                        }
                        .buttonStyle(.plain)

                        // Personal note field
                        HStack {
                            Text("NOTE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.5))

                            TextField("Add personal note...", text: $personalNote)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                        }
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM)

                        // Date stamp preview
                        HStack {
                            Text("DATE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.5))

                            Spacer()

                            Text(fullDateStamp)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(colors.primary.opacity(0.7))
                        }
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM)
                    }
                    .background(colors.surface.opacity(0.5))
                }
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
        .background(holidayColor.opacity(0.3))
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(JohoDimensions.radiusLarge)
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showIconPicker) {
            JohoSFSymbolPickerSheet(
                selectedSymbol: Binding(
                    get: { customIcon ?? defaultHolidayIcon },
                    set: { customIcon = $0 }
                ),
                accentColor: holidayColor,
                lightBackground: holidayColor.opacity(0.2),
                onDone: {}
            )
        }
        .sheet(isPresented: $showPermanentIconPicker) {
            JohoSFSymbolPickerSheet(
                selectedSymbol: $permanentIconSelection,
                accentColor: dynamicHolidayColor,
                lightBackground: dynamicHolidayColor.opacity(0.2),
                onDone: {
                    savePermanentHolidayIcon(permanentIconSelection)
                }
            )
        }
        .onAppear {
            permanentIconSelection = holiday.symbolName ?? defaultHolidayIcon
        }
    }

    // MARK: - Dynamic Holiday Color (from CategoryColorSettings)

    private var dynamicHolidayColor: Color {
        let category: DisplayCategory = holiday.isBankHoliday ? .holiday : .observance
        return CategoryColorSettings.shared.color(for: category)
    }

    // MARK: - Holiday Item Icon Section

    private var holidayItemIconSection: some View {
        let category: DisplayCategory = holiday.isBankHoliday ? .holiday : .observance

        return VStack(spacing: 0) {
            Button {
                showPermanentIconPicker = true
            } label: {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(CategoryColorSettings.shared.color(for: category))
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        Text("ITEM ICON")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: holiday.symbolName ?? defaultHolidayIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(CategoryColorSettings.shared.color(for: category))

                        if holiday.symbolName != nil {
                            Text("CUSTOM")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(colors.primary.opacity(0.3))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingMD)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Save Permanent Holiday Icon

    private func savePermanentHolidayIcon(_ iconName: String) {
        // Find and update HolidayRule by holiday ID
        guard let targetID = holiday.ruleID else { return }

        let descriptor = FetchDescriptor<HolidayRule>(predicate: #Predicate { rule in
            rule.id == targetID
        })
        if let rules = try? modelContext.fetch(descriptor), let rule = rules.first {
            rule.symbolName = iconName == defaultHolidayIcon ? nil : iconName
            rule.userModifiedAt = Date()
            try? modelContext.save()
            // Refresh holiday cache
            HolidayManager.shared.calculateAndCacheHolidays(context: modelContext, focusYear: Calendar.current.component(.year, from: date))
            HapticManager.notification(.success)
        }
    }
}

// MARK: - Single Birthday Detail Sheet (情報デザイン: Pink celebration style)

struct SingleBirthdayDetailSheet: View {
    let birthday: DayDashboardView.BirthdayInfo
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // DARK HEADER
            HStack {
                Text("BIRTHDAY")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primaryInverted)

                Spacer()

                // Close button
                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(colors.surface)
                            .frame(width: 28, height: 28)
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(colors.surfaceInverted)

            // CARD CONTENT
            VStack(spacing: 0) {
                // Large icon zone (情報デザイン: Hero display)
                VStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.pink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(JohoColors.pink.opacity(0.2))

                // Thick divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // Title (date)
                Text(formattedDate)
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

                // Birthday name
                Text(birthday.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, JohoDimensions.spacingMD)

                // Age if known
                if let age = birthday.age, age > 0 {
                    Text("Turns \(age)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .padding(.top, JohoDimensions.spacingSM)
                }

                Spacer().frame(height: JohoDimensions.spacingLG)
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
        .background(JohoColors.pink.opacity(0.3))
        .presentationDetents([.medium])
        .presentationCornerRadius(JohoDimensions.radiusLarge)
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Single Holiday Share Button

@available(iOS 16.0, *)
struct SingleHolidayShareButton: View {
    let holiday: DayDashboardView.HolidayInfo
    let date: Date
    var customIcon: String? = nil
    var personalNote: String? = nil

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var snapshot: SingleHolidaySnapshot {
        SingleHolidaySnapshot(
            holiday: holiday,
            date: date,
            size: CGSize(width: 340, height: 0),
            customIcon: customIcon,
            personalNote: personalNote
        )
    }

    var body: some View {
        ShareLink(
            item: snapshot,
            preview: SharePreview(
                holiday.name,
                image: Image(systemName: customIcon ?? "star.fill")
            )
        ) {
            ZStack {
                Circle()
                    .fill(colors.surface)
                    .frame(width: 28, height: 28)
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Single Holiday Snapshot (Transferable)

@available(iOS 16.0, *)
struct SingleHolidaySnapshot: Transferable {
    let holiday: DayDashboardView.HolidayInfo
    let date: Date
    let size: CGSize
    var customIcon: String? = nil
    var personalNote: String? = nil

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { snapshot in
            await snapshot.renderToPNG()
        }
    }

    @MainActor
    func renderToPNG() -> Data {
        let renderer = ImageRenderer(content: shareableView())
        renderer.scale = 3.0
        renderer.isOpaque = false

        guard let uiImage = renderer.uiImage else {
            return Data()
        }

        return uiImage.pngData() ?? Data()
    }

    @MainActor
    func shareableView() -> some View {
        ShareableHolidayCard(
            holiday: holiday,
            date: date,
            customIcon: customIcon,
            personalNote: personalNote
        )
        .frame(width: size.width)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Shareable Holiday Card (情報デザイン: Exact Quirky Facts style)

struct ShareableHolidayCard: View {
    let holiday: DayDashboardView.HolidayInfo
    let date: Date
    var isShareable: Bool = false
    var customIcon: String? = nil
    var personalNote: String? = nil

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let cornerRadius: CGFloat = 16

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var defaultHolidayIcon: String {
        holiday.symbolName ?? (holiday.isBankHoliday ? "star.fill" : "calendar")
    }

    /// The icon to display (custom or default)
    private var displayIcon: String {
        customIcon ?? defaultHolidayIcon
    }

    private var holidayColor: Color {
        holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance)
    }

    private var categoryLabel: String {
        holiday.isBankHoliday ? "HOLIDAY" : "OBSERVANCE"
    }

    /// Full date stamp: YYYYMMDD · W{n}
    private var fullDateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let weekNumber = Calendar.iso8601.component(.weekOfYear, from: date)
        return "\(formatter.string(from: date)) · W\(weekNumber)"
    }

    var body: some View {
        ZStack {
            // Layer 1: Solid background
            cardShape.fill(colors.surface)

            // Layer 2: Content
            VStack(spacing: 0) {
                // HEADER: Branding + icon
                HStack(spacing: 0) {
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                        Text("ONSEN PLANNER")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(.leading, JohoDimensions.spacingMD)

                    Spacer()

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // Icon (customizable)
                    Image(systemName: displayIcon)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(holidayColor)
                        .frame(width: 48)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 40)
                .background(holidayColor.opacity(0.5))

                // Divider
                Rectangle().fill(colors.border).frame(height: 2)

                // DATE STAMP row
                HStack {
                    Text(fullDateStamp)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(colors.primary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(colors.surface)

                // Divider
                Rectangle().fill(colors.border).frame(height: 1)

                // MAIN CONTENT: Large icon + text
                HStack(alignment: .top, spacing: 0) {
                    // LEFT: Large icon (customizable)
                    VStack {
                        Spacer()
                        Image(systemName: displayIcon)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(holidayColor)
                        Spacer()
                    }
                    .frame(width: 100)
                    .frame(minHeight: 120)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)

                    // RIGHT: Text content
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        Text(titleText)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)

                        Text(holiday.name)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                            .lineLimit(isShareable ? nil : 3)
                            .multilineTextAlignment(.leading)

                        // Personal note (if provided)
                        if let note = personalNote, !note.isEmpty {
                            Rectangle()
                                .fill(colors.border.opacity(0.3))
                                .frame(height: 1)
                                .padding(.vertical, 4)

                            Text(note)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.5))
                                .italic()
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120)
                .background(holidayColor.opacity(0.15))

                // Divider
                Rectangle().fill(colors.border).frame(height: 2)

                // FOOTER
                HStack {
                    HStack(spacing: 4) {
                        Text(categoryLabel)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))
                            .tracking(1)

                        if let code = holiday.regionCode {
                            Text("·")
                                .foregroundStyle(colors.primary.opacity(0.3))
                            Text(code.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }
                    }

                    Spacer()

                    Text("ONSEN PLANNER")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.3))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(height: 32)
            }
            .clipShape(cardShape)

            // Layer 3: Border
            cardShape.strokeBorder(colors.border, lineWidth: 3)
        }
    }

    private var titleText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
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
            DayDashboardView.HolidayInfo(id: "1", name: "Midsummer Eve", isBankHoliday: true, symbolName: "sun.max.fill", regionCode: "SE", ruleID: "SE-midsummer"),
            DayDashboardView.HolidayInfo(id: "2", name: "元日", isBankHoliday: true, symbolName: nil, regionCode: "JP", ruleID: "JP-newyear")
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
