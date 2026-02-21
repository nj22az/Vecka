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
        return DateFormatterCache.weekdayFull.string(from: date).uppercased()
    }

    var monthName: String {
        return DateFormatterCache.monthName.string(from: date)
    }

    var yearString: String {
        let components = Calendar.current.dateComponents([.year], from: date)
        return String(components.year ?? 0)
    }

    var weekNumber: Int {
        Calendar.iso8601.component(.weekOfYear, from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var hasContent: Bool {
        !holidays.isEmpty || !memos.isEmpty || !birthdays.isEmpty
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
        CardSnapshotRenderer.renderToPNG(
            ShareableDaySummaryCard(data: data, isShareable: true),
            size: size
        )
    }
}

// MARK: - Shareable Day Summary Card View

struct ShareableDaySummaryCard: View {
    let data: DaySummaryData
    var isShareable: Bool = false

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let cornerRadius: CGFloat = JohoDimensions.radiusLarge

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
                                .font(JohoFont.bodySmallBold)
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
                ShareableCardDivider()

                // ═══════════════════════════════════════════════════════════════
                // CONTENT: Items list
                // ═══════════════════════════════════════════════════════════════
                if data.hasContent {
                    VStack(spacing: 0) {
                        // Holidays
                        ForEach(data.holidays.prefix(isShareable ? 10 : 3)) { holiday in
                            DaySummaryRow(
                                icon: holiday.isBankHoliday ? IconCatalog.holiday : IconCatalog.calendar,
                                iconColor: holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance),
                                title: holiday.name,
                                badge: holiday.isBankHoliday ? "HOLIDAY" : "OBSERVANCE",
                                badgeColor: holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance),
                                subtitle: holiday.regionCode?.uppercased(),
                                lineLimit: isShareable ? nil : 1,
                                horizontalPadding: JohoDimensions.spacingMD
                            )

                            if holiday.id != data.holidays.prefix(isShareable ? 10 : 3).last?.id ||
                               !data.birthdays.isEmpty || !data.memos.isEmpty {
                                Rectangle()
                                    .fill(colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, JohoDimensions.spacingMD)
                            }
                        }

                        // Birthdays
                        ForEach(data.birthdays.prefix(isShareable ? 6 : 3)) { birthday in
                            DaySummaryRow(
                                icon: "gift.fill",
                                iconColor: JohoColors.purple,
                                title: birthday.name,
                                badge: birthday.age != nil ? "\(birthday.age!)" : "BIRTHDAY",
                                badgeColor: JohoColors.purple,
                                subtitle: nil,
                                lineLimit: isShareable ? nil : 1,
                                horizontalPadding: JohoDimensions.spacingMD
                            )

                            if birthday.id != data.birthdays.prefix(isShareable ? 6 : 3).last?.id ||
                               !data.memos.isEmpty {
                                Rectangle()
                                    .fill(colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, JohoDimensions.spacingMD)
                            }
                        }

                        // Memos
                        ForEach(data.memos.prefix(isShareable ? 8 : 4)) { memo in
                            DayMemoRow(
                                memo: memo,
                                lineLimit: isShareable ? nil : 1,
                                horizontalPadding: JohoDimensions.spacingMD
                            )

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
                        Image(systemName: IconCatalog.checkmarkCircle)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(colors.secondary.opacity(0.5))

                        Text("No events scheduled")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, JohoDimensions.spacingLG)
                }

                // Divider
                ShareableCardDivider()

                // ═══════════════════════════════════════════════════════════════
                // FOOTER: Branding
                // ═══════════════════════════════════════════════════════════════
                ShareableCardFooter(leftLabel: "DAY SUMMARY", rightLabel: "ONSEN PLANNER")
            }
            .clipShape(cardShape)

            // Layer 3: Border
            cardShape
                .strokeBorder(colors.border, lineWidth: 3)
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
                        Image(systemName: IconCatalog.xmark)
                            .font(JohoFont.headerTag)
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
                        .font(JohoFont.label)
                        .foregroundStyle(colors.primary)

                    // Week number badge
                    HStack(spacing: 6) {
                        Text("W\(data.weekNumber)")
                            .font(JohoFont.headerTag)
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
                ShareableCardDivider()

                // ═══════════════════════════════════════════════════════════════
                // CONTENT: Items list (unified inset system)
                // ═══════════════════════════════════════════════════════════════
                if data.hasContent {
                    VStack(spacing: 0) {
                        // Holidays
                        ForEach(data.holidays.prefix(3)) { holiday in
                            DaySummaryRow(
                                icon: holiday.isBankHoliday ? IconCatalog.holiday : IconCatalog.calendar,
                                iconColor: holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance),
                                title: holiday.name,
                                badge: holiday.isBankHoliday ? "HOLIDAY" : "OBSERVANCE",
                                badgeColor: holiday.isBankHoliday ? CategoryColorSettings.shared.color(for: .holiday) : CategoryColorSettings.shared.color(for: .observance),
                                subtitle: holiday.regionCode?.uppercased(),
                                lineLimit: 1,
                                horizontalPadding: contentInset
                            )

                            if holiday.id != data.holidays.prefix(3).last?.id ||
                               !data.birthdays.isEmpty || !data.memos.isEmpty {
                                Rectangle()
                                    .fill(colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, contentInset)
                            }
                        }

                        // Birthdays
                        ForEach(data.birthdays.prefix(3)) { birthday in
                            DaySummaryRow(
                                icon: "gift.fill",
                                iconColor: JohoColors.purple,
                                title: birthday.name,
                                badge: birthday.age != nil ? "\(birthday.age!)" : "BIRTHDAY",
                                badgeColor: JohoColors.purple,
                                subtitle: nil,
                                lineLimit: 1,
                                horizontalPadding: contentInset
                            )

                            if birthday.id != data.birthdays.prefix(3).last?.id ||
                               !data.memos.isEmpty {
                                Rectangle()
                                    .fill(colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, contentInset)
                            }
                        }

                        // Memos
                        ForEach(data.memos.prefix(4)) { memo in
                            DayMemoRow(
                                memo: memo,
                                lineLimit: 1,
                                horizontalPadding: contentInset
                            )

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
                        Image(systemName: IconCatalog.checkmarkCircle)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(colors.secondary.opacity(0.5))

                        Text("No events scheduled")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, JohoDimensions.spacingLG)
                }

                // Divider
                ShareableCardDivider()

                // ═══════════════════════════════════════════════════════════════
                // FOOTER: Branding (same baseline margin as Fact body text)
                // ═══════════════════════════════════════════════════════════════
                ShareableCardFooter(leftLabel: "DAY SUMMARY", rightLabel: "ONSEN PLANNER")
            }
            .background(colors.surface)
            .johoBordered(borderWidth: JohoDimensions.borderThick)
            .padding(contentInset)

            Spacer()
        }
        .background(summaryBackgroundColor.opacity(0.3))
        .presentationDetents([.medium])
        .presentationCornerRadius(JohoDimensions.radiusLarge)
        .presentationDragIndicator(.hidden)
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
                image: Image(systemName: IconCatalog.calendar)
            )
        ) {
            JohoShareCircleButton()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared Row Components

private struct DaySummaryRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let badge: String?
    let badgeColor: Color
    let subtitle: String?
    let lineLimit: Int?
    let horizontalPadding: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))

            // Title + subtitle
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(lineLimit)

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
                    .font(JohoFont.labelBold)
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, JohoDimensions.spacingSM)
    }
}

private struct DayMemoRow: View {
    let memo: Memo
    let lineLimit: Int?
    let horizontalPadding: CGFloat
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        // Detect birthday memos (linked to contact or has birthday symbol)
        let isBirthday = memo.hasLinkedContact || memo.symbolName == IconCatalog.birthday
        let icon = isBirthday ? "gift.fill" : (memo.hasMoney ? IconCatalog.currencyIcon(for: memo.currency ?? baseCurrency) : (memo.hasPlace ? IconCatalog.trip : IconCatalog.memo))
        // 情報デザイン: Semantic color system
        let iconColor: Color = {
            if memo.hasLinkedContact || memo.symbolName == IconCatalog.birthday || memo.hasPerson {
                return JohoColors.purple  // Purple (人) - PEOPLE
            }
            if memo.hasMoney { return JohoColors.green }  // Green (金) - MONEY
            if memo.hasPlace { return JohoColors.cyan }  // Cyan (予定) - SCHEDULED
            return JohoColors.yellow  // Yellow - NOW (notes, today, memos)
        }()

        return HStack(spacing: JohoDimensions.spacingSM) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))

            // Content
            VStack(alignment: .leading, spacing: 1) {
                Text(memo.preview)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(lineLimit)

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
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.green)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, JohoDimensions.spacingSM)
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
            DayDashboardView.HolidayInfo(id: "1", name: "Midsummer Eve", isBankHoliday: true, symbolName: "sun.max.fill", regionCode: "SE", ruleID: "SE-midsummer", notes: nil)
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
