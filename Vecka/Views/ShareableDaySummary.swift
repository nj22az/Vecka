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
        ShareableCardShell(
            headerIcon: data.isToday ? "sun.max.fill" : IconCatalog.calendar,
            headerIconColor: data.isToday ? JohoColors.todayOrange : JohoColors.cyan,
            headerAccentColor: data.isToday ? JohoColors.todayOrange : JohoColors.cyan,
            footerLeftLabel: "DAY SUMMARY",
            footerRightLabel: "ONSEN PLANNER"
        ) {
            // 情報デザイン: 7-compartment packaging layout. JDS §12.
            ShareableCardDivider()

            VStack(spacing: JohoDimensions.spacingSM) {

                // 1. HOOK — the day itself as the loud headline
                PackagingHook(
                    "\(data.weekdayName) · \(data.monthName.uppercased()) \(data.dayNumber), \(data.yearString)",
                    subline: data.secondaryDateText
                )

                // 2. CLAIM PILL — week number, today badge, ISO note
                PackagingClaimPill(
                    "WEEK \(data.weekNumber)",
                    subtitle: data.isToday ? "Today · ISO 8601" : "ISO 8601",
                    tint: data.isToday ? JohoColors.yellow : JohoColors.cyan
                )

                // 3. INGREDIENTS — the day's events, with red allergen
                //    sub-box for bank holidays ("red days")
                if data.hasContent {
                    PackagingIngredientsBox(
                        entries: dayEntries,
                        allergens: redDayAllergen
                    )
                }

                // 4. NUTRITION — the day's stats
                PackagingNutritionTable(
                    title: "Day Stats (per 24h)",
                    rows: nutritionRows,
                    footnote: data.hasContent ? "Live counts" : "Empty day"
                )

                // 5. MANUFACTURER — source + best-before highlight
                PackagingManufacturerBlock(
                    maker: "Onsen Planner",
                    bestBefore: dateStamp,
                    storage: nil
                )

                // 6. CODE FOOTER — short id + URL stub
                PackagingCodeFooter(
                    identifier: "DAY-\(dateStamp)",
                    url: "vecka://day/\(dateStamp)"
                )
            }
            .padding(JohoDimensions.spacingSM)
            .background((data.isToday ? JohoColors.todayOrange : JohoColors.cyan).opacity(JohoDimensions.opacityLight))

            ShareableCardDivider()
        }
    }

    // MARK: - Packaging Data Builders

    private var dateStamp: String {
        DateFormatterCache.compactDate.string(from: data.date)  // yyyyMMdd
    }

    /// Holidays + birthdays + memos collapsed into a single bulleted spec.
    /// Holidays first (most weighty), then birthdays, then memos.
    private var dayEntries: [PackagingIngredientsBox.Entry] {
        var out: [PackagingIngredientsBox.Entry] = []
        let holidayLimit = isShareable ? 10 : 3
        let birthdayLimit = isShareable ? 6 : 3
        let memoLimit = isShareable ? 8 : 4

        for h in data.holidays.prefix(holidayLimit) {
            let label = h.isBankHoliday ? "HOLIDAY" : "OBS"
            let region = h.regionCode.map { " · \($0.uppercased())" } ?? ""
            out.append(.init(label: label, value: "\(h.name)\(region)"))
        }
        for b in data.birthdays.prefix(birthdayLimit) {
            let age = b.age.map { " · turns \($0)" } ?? ""
            out.append(.init(label: "BDAY", value: "\(b.name)\(age)"))
        }
        for m in data.memos.prefix(memoLimit) {
            out.append(.init(label: memoLabel(for: m), value: m.preview))
        }
        return out
    }

    /// Bank-holiday names listed in the red allergen sub-box when present.
    /// The "Blue + Red" combination — trusted info with a safety note.
    private var redDayAllergen: String? {
        let redDays = data.holidays.filter { $0.isBankHoliday }
        guard !redDays.isEmpty else { return nil }
        return redDays.map { $0.name }.joined(separator: ", ").uppercased()
    }

    /// Per-category counts for the nutrition-style table.
    private var nutritionRows: [PackagingNutritionTable.Row] {
        var rows: [PackagingNutritionTable.Row] = []
        if !data.holidays.isEmpty { rows.append(.init(label: "Holidays", value: "\(data.holidays.count)")) }
        if !data.birthdays.isEmpty { rows.append(.init(label: "Birthdays", value: "\(data.birthdays.count)")) }
        if !data.memos.isEmpty { rows.append(.init(label: "Memos", value: "\(data.memos.count)")) }
        rows.append(.init(label: "Week", value: "W\(data.weekNumber)"))
        return rows
    }

    private func memoLabel(for memo: Memo) -> String {
        if memo.hasMoney { return "EXP" }
        if memo.hasPlace { return "TRIP" }
        if memo.hasSchedule { return "EVT" }
        return "NOTE"
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
                .background(data.isToday ? JohoColors.todayOrange.opacity(JohoDimensions.opacitySubtle) : colors.inputBackground)

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
                                    .fill(colors.border.opacity(JohoDimensions.opacityMedium))
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
                                    .fill(colors.border.opacity(JohoDimensions.opacityMedium))
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
                                    .fill(colors.border.opacity(JohoDimensions.opacityMedium))
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
                            .font(JohoFont.displayMedium)
                            .foregroundStyle(colors.secondary.opacity(JohoDimensions.opacityHeavy))

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
        .background(summaryBackgroundColor.opacity(JohoDimensions.opacityMedium))
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
                .font(JohoFont.headlineSmall)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(JohoDimensions.opacityLight))
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
                    .background(badgeColor.opacity(JohoDimensions.opacityLight))
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
                .font(JohoFont.headlineSmall)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(JohoDimensions.opacityLight))
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
