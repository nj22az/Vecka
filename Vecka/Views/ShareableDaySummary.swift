//
//  ShareableDaySummary.swift
//  Vecka
//
//  情報デザイン: Shareable day summary cards using Transferable protocol
//  Renders day summaries as shareable PNG images (meme-style)
//

import SwiftUI
import UIKit
import CoreTransferable

// MARK: - Day Summary Data

/// Data model for a shareable day summary
struct DaySummaryData {
    let date: Date
    let holidays: [DayDashboardView.HolidayInfo]
    let birthdays: [DayDashboardView.BirthdayInfo]
    let memos: [Memo]
    let secondaryDateText: String?

    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).uppercased()
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }

    var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    var weekNumber: Int {
        Calendar.iso8601.component(.weekOfYear, from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var hasContent: Bool {
        // Birthdays are now memos with linkedContactID, so only check holidays and memos
        !holidays.isEmpty || !memos.isEmpty
    }
}

// MARK: - Shareable Day Summary Snapshot (Transferable)

@available(iOS 16.0, *)
struct ShareableDaySummarySnapshot: Transferable {
    let data: DaySummaryData
    let size: CGSize

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
        ShareableDaySummaryCard(data: data, isShareable: true)
            .frame(width: size.width)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Shareable Day Summary Card View

struct ShareableDaySummaryCard: View {
    let data: DaySummaryData
    var isShareable: Bool = false

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let cornerRadius: CGFloat = 16

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        ZStack {
            // Layer 1: Solid background
            cardShape
                .fill(colors.surface)

            // Layer 2: Content
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HEADER: Date display
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Day number + weekday
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(data.dayNumber)")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(data.isToday ? JohoColors.todayOrange : colors.primary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(data.weekdayName)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary)

                            Text("\(data.monthName.uppercased()) \(data.yearString)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.secondary)
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)

                    Spacer()

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)

                    // RIGHT: Week number
                    VStack(spacing: 2) {
                        Text("W\(data.weekNumber)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)

                        if data.isToday {
                            Text("TODAY")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.todayOrange)
                        }
                    }
                    .frame(width: 60)
                }
                .frame(height: 72)
                .background(data.isToday ? JohoColors.todayOrange.opacity(0.1) : colors.inputBackground)

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // CONTENT: Items list
                // ═══════════════════════════════════════════════════════════════
                if data.hasContent {
                    VStack(spacing: 0) {
                        // Holidays
                        ForEach(data.holidays.prefix(isShareable ? 10 : 3)) { holiday in
                            summaryRow(
                                icon: holiday.isBankHoliday ? "star.fill" : "calendar",
                                iconColor: holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance),
                                title: holiday.name,
                                badge: holiday.isBankHoliday ? "HOLIDAY" : "OBSERVANCE",
                                badgeColor: holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance),
                                subtitle: holiday.regionCode?.uppercased()
                            )

                            if holiday.id != data.holidays.prefix(isShareable ? 10 : 3).last?.id ||
                               !data.memos.isEmpty {
                                Rectangle()
                                    .fill(colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, JohoDimensions.spacingMD)
                            }
                        }

                        // Memos (includes birthday memos - those with linkedContactID or birthday symbol)
                        ForEach(data.memos.prefix(isShareable ? 8 : 4)) { memo in
                            memoSummaryRow(memo: memo)

                            if memo.id != data.memos.prefix(isShareable ? 8 : 4).last?.id {
                                Rectangle()
                                    .fill(colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, JohoDimensions.spacingMD)
                            }
                        }
                    }
                    .padding(.vertical, JohoDimensions.spacingSM)
                } else {
                    // Empty state
                    VStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(colors.secondary.opacity(0.5))

                        Text("No events scheduled")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, JohoDimensions.spacingLG)
                }

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // FOOTER: Branding
                // ═══════════════════════════════════════════════════════════════
                HStack {
                    Text("DAY SUMMARY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    Text("ONSEN PLANNER")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.4))
                        .tracking(0.5)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(height: 32)
            }
            .clipShape(cardShape)

            // Layer 3: Border
            cardShape
                .strokeBorder(colors.border, lineWidth: 3)
        }
    }

    // MARK: - Summary Row

    private func summaryRow(
        icon: String,
        iconColor: Color,
        title: String,
        badge: String?,
        badgeColor: Color,
        subtitle: String?
    ) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Title + subtitle
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(isShareable ? nil : 1)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }

            Spacer()

            // Badge
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    // MARK: - Memo Row

    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    private func memoSummaryRow(memo: Memo) -> some View {
        // Detect birthday memos (linked to contact or has birthday symbol)
        let isBirthday = memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill"
        let icon = isBirthday ? "gift.fill" : (memo.hasMoney ? currencyIcon(for: memo.currency ?? baseCurrency) : (memo.hasPlace ? "airplane" : "note.text"))
        // All memos use green, except trips which use cyan
        let iconColor = (memo.hasPlace && !memo.hasMoney) ? JohoColors.cyan : JohoColors.green

        return HStack(spacing: JohoDimensions.spacingSM) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Content
            VStack(alignment: .leading, spacing: 1) {
                Text(memo.preview)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(isShareable ? nil : 1)

                if let place = memo.place {
                    Text(place)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }

            Spacer()

            // Amount for expenses
            if let amount = memo.amount {
                Text(String(format: "%.0f %@", amount, memo.currency ?? baseCurrency))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.green)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
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
}

// MARK: - Day Summary Sheet View

struct DaySummarySheetView: View {
    let data: DaySummaryData
    let onDismiss: () -> Void
    let onOpenMemos: (Date) -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    // Single unified content inset for entire card (matches Fact card system)
    private let contentInset: CGFloat = JohoDimensions.spacingMD

    var body: some View {
        VStack(spacing: 0) {
            // DARK HEADER (matches Quirky Facts style exactly)
            HStack {
                Text("DAY SUMMARY")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(colors.primaryInverted)

                Spacer()

                // Share button
                if #available(iOS 16.0, *) {
                    DaySummaryShareButton(data: data)
                }

                // Close button
                Button {
                    onDismiss()
                } label: {
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
            .padding(.horizontal, contentInset)
            .padding(.vertical, contentInset)
            .background(colors.surfaceInverted)

            // Main content card (情報デザイン: Hero zone → Content pattern like Quirky Facts)
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HERO ZONE: Date display (centered, like Quirky Facts icon zone)
                // ═══════════════════════════════════════════════════════════════
                VStack(spacing: 4) {
                    // Large day number (hero element)
                    Text("\(data.dayNumber)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(data.isToday ? JohoColors.todayOrange : colors.primary)

                    // Weekday + Month/Year
                    Text("\(data.weekdayName) · \(data.monthName.uppercased()) \(data.yearString)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)

                    // Week number badge
                    HStack(spacing: 6) {
                        Text("W\(data.weekNumber)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(colors.secondary)

                        if data.isToday {
                            Text("TODAY")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(JohoColors.todayOrange)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, contentInset)
                .background(data.isToday ? JohoColors.todayOrange.opacity(0.1) : colors.inputBackground)

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // CONTENT: Items list (unified inset system)
                // ═══════════════════════════════════════════════════════════════
                if data.hasContent {
                    VStack(spacing: 0) {
                        // Holidays
                        ForEach(data.holidays.prefix(3)) { holiday in
                            sheetSummaryRow(
                                icon: holiday.isBankHoliday ? "star.fill" : "calendar",
                                iconColor: holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance),
                                title: holiday.name,
                                badge: holiday.isBankHoliday ? "HOLIDAY" : "OBSERVANCE",
                                badgeColor: holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance),
                                subtitle: holiday.regionCode?.uppercased()
                            )

                            if holiday.id != data.holidays.prefix(3).last?.id ||
                               !data.memos.isEmpty {
                                Rectangle()
                                    .fill(colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, contentInset)
                            }
                        }

                        // Memos
                        ForEach(data.memos.prefix(4)) { memo in
                            sheetMemoRow(memo: memo)

                            if memo.id != data.memos.prefix(4).last?.id {
                                Rectangle()
                                    .fill(colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, contentInset)
                            }
                        }
                    }
                    .padding(.vertical, contentInset)
                } else {
                    // Empty state
                    VStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(colors.secondary.opacity(0.5))

                        Text("No events scheduled")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, JohoDimensions.spacingLG)
                }

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // FOOTER: Branding (same baseline margin as Fact body text)
                // ═══════════════════════════════════════════════════════════════
                HStack {
                    Text("DAY SUMMARY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    Text("ONSEN PLANNER")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.4))
                        .tracking(0.5)
                }
                .padding(.horizontal, contentInset)
                .padding(.vertical, contentInset)
            }
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
            )
            .padding(contentInset)

            Spacer()
        }
        .background(summaryBackgroundColor.opacity(0.3))
        .presentationDetents([.medium])
        .presentationCornerRadius(JohoDimensions.radiusLarge)
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Sheet Row Helpers

    private func sheetSummaryRow(
        icon: String,
        iconColor: Color,
        title: String,
        badge: String?,
        badgeColor: Color,
        subtitle: String?
    ) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Title + subtitle
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }

            Spacer()

            // Badge
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, contentInset)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    private func sheetMemoRow(memo: Memo) -> some View {
        let isBirthday = memo.hasLinkedContact || memo.symbolName == "birthday.cake.fill"
        let icon = isBirthday ? "gift.fill" : (memo.hasMoney ? currencyIcon(for: memo.currency ?? baseCurrency) : (memo.hasPlace ? "airplane" : "note.text"))
        let iconColor = (memo.hasPlace && !memo.hasMoney) ? JohoColors.cyan : JohoColors.green

        return HStack(spacing: JohoDimensions.spacingSM) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Content
            VStack(alignment: .leading, spacing: 1) {
                Text(memo.preview)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                if let place = memo.place {
                    Text(place)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }

            Spacer()

            // Amount for expenses
            if let amount = memo.amount {
                Text(String(format: "%.0f %@", amount, memo.currency ?? baseCurrency))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.green)
            }
        }
        .padding(.horizontal, contentInset)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

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

    /// Background color based on primary content type
    private var summaryBackgroundColor: Color {
        if !data.holidays.isEmpty {
            // Has holidays - use pink (holiday color)
            return data.holidays.first?.isBankHoliday == true ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance)
        } else if !data.memos.isEmpty {
            // Has memos - use memo color
            return CategoryColorSettings.shared.color(for: .memo)
        }
        return colors.secondary
    }
}

// MARK: - Share Button

@available(iOS 16.0, *)
struct DaySummaryShareButton: View {
    let data: DaySummaryData
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var snapshot: ShareableDaySummarySnapshot {
        ShareableDaySummarySnapshot(
            data: data,
            size: CGSize(width: 340, height: 0)
        )
    }

    var body: some View {
        ShareLink(
            item: snapshot,
            preview: SharePreview(
                "Day Summary - \(data.monthName) \(data.dayNumber)",
                image: Image(systemName: "calendar")
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

// MARK: - Preview

#Preview("Shareable Day Summary") {
    let memo1 = Memo(text: "Team standup meeting", date: Date())
    let memo2 = Memo(text: "Lunch at restaurant", date: Date())
    memo2.amount = 245
    memo2.currency = "SEK"

    let data = DaySummaryData(
        date: Date(),
        holidays: [
            DayDashboardView.HolidayInfo(id: "1", name: "Midsummer Eve", isBankHoliday: true, symbolName: "sun.max.fill", regionCode: "SE", ruleID: "SE-midsummer")
        ],
        birthdays: [
            DayDashboardView.BirthdayInfo(id: "1", name: "Anna Larsson", age: 30)
        ],
        memos: [memo1, memo2],
        secondaryDateText: nil
    )

    return ScrollView {
        VStack(spacing: 20) {
            ShareableDaySummaryCard(data: data)
                .frame(width: 340)

            ShareableDaySummaryCard(data: data, isShareable: true)
                .frame(width: 340)
        }
        .padding()
    }
    .johoBackground()
}
