//
//  DayDetailSheet.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) day detail sheet
//  Shows all special days for a selected calendar date
//

import SwiftUI

/// 情報デザイン: Day detail sheet shown on long-press
/// Displays all holidays, events, notes, etc. for a specific date
struct DayDetailSheet: View {
    let day: CalendarDay
    let dataCheck: DayDataCheck?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Date header
                dateHeader

                // Content sections
                if hasAnyContent {
                    contentSections
                } else {
                    emptyState
                }

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.top, JohoDimensions.spacingSM)
            .padding(.bottom, JohoDimensions.spacingLG)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.canvas)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Day number in large format
            VStack(spacing: 2) {
                Text(String(day.dayNumber))
                    .font(JohoFont.displayLarge)
                    .foregroundStyle(colors.primary)

                Text(day.date.formatted(.dateTime.weekday(.wide)).uppercased())
                    .font(JohoFont.label)
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
            }
            .frame(width: 80)

            // Vertical divider
            Rectangle()
                .fill(colors.border)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // Month and year
            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                Text(day.date.formatted(.dateTime.month(.wide).year()))
                    .font(JohoFont.headline)
                    .foregroundStyle(colors.primary)

                // Status pills
                // 情報デザイン: Use pre-computed dataCheck to avoid accessing HolidayManager
                HStack(spacing: JohoDimensions.spacingSM) {
                    if day.isToday {
                        JohoPill(text: "TODAY", style: .coloredInverted(JohoColors.todayOrange), size: .small)
                    }
                    if dataCheck?.hasHoliday == true {
                        JohoPill(text: "HOLIDAY", style: .coloredInverted(JohoColors.red), size: .small)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: IconCatalog.xmark)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
                    .frame(width: 32, height: 32)
                    .background(colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
            }
        }
        .padding(JohoDimensions.spacingLG)
        .frame(height: 100)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick)
    }

    // MARK: - Content Sections

    private var hasAnyContent: Bool {
        guard let check = dataCheck else { return false }
        return check.hasHoliday || check.hasObservance || check.hasEvent ||
               check.hasBirthday || check.hasNote || check.hasTrip || check.hasExpense
    }

    @ViewBuilder
    private var contentSections: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            // Holiday from pre-computed dataCheck (avoids accessing HolidayManager during sheet render)
            // 情報デザイン: Holiday info is captured at long-press time for thread safety
            if let check = dataCheck, check.hasHoliday, let holidayName = check.holidayName {
                detailRow(
                    title: holidayName,
                    subtitle: "Public Holiday",
                    color: JohoColors.red,
                    icon: check.holidaySymbolName ?? IconCatalog.holiday,
                    isSystem: true
                )
            }

            // Indicator-based content from DayDataCheck
            if let check = dataCheck {
                // Observances (can have multiple)
                if check.hasObservance {
                    ForEach(check.observanceNames, id: \.self) { observanceName in
                        detailRow(
                            title: observanceName,
                            subtitle: "Observance",
                            color: JohoColors.pink,
                            icon: IconCatalog.observance,
                            isSystem: true
                        )
                    }
                }

                // Events (can have multiple)
                if check.hasEvent {
                    ForEach(check.eventNames, id: \.self) { eventName in
                        detailRow(
                            title: eventName,
                            subtitle: "Event",
                            color: JohoColors.cyan,
                            icon: IconCatalog.event,
                            isSystem: false
                        )
                    }
                }

                // Birthdays (can have multiple)
                if check.hasBirthday {
                    ForEach(check.birthdayNames, id: \.self) { birthdayName in
                        detailRow(
                            title: birthdayName,
                            subtitle: "Birthday",
                            color: JohoColors.pink,
                            icon: IconCatalog.birthday,
                            isSystem: false
                        )
                    }
                }

                // Note (show preview of content)
                if check.hasNote, let noteContent = check.noteContent {
                    detailRow(
                        title: notePreview(noteContent),
                        subtitle: "Note",
                        color: JohoColors.yellow,
                        icon: IconCatalog.memo,
                        isSystem: false
                    )
                }

                // Trip (show destination)
                if check.hasTrip, let destination = check.tripDestination {
                    detailRow(
                        title: destination,
                        subtitle: "Trip",
                        color: JohoColors.cyan,
                        icon: IconCatalog.trip,
                        isSystem: false
                    )
                }

                // Expense (show total amount)
                if check.hasExpense, let amount = check.expenseAmount {
                    detailRow(
                        title: formatCurrency(amount),
                        subtitle: "Expenses",
                        color: JohoColors.green,
                        icon: "dollarsign.circle.fill",
                        isSystem: false
                    )
                }
            }
        }
    }

    // MARK: - Detail Row (Bento Style)
    // 情報デザイン: BLACK text on WHITE backgrounds. ALWAYS.

    @ViewBuilder
    private func detailRow(
        title: String,
        subtitle: String?,
        color: Color,
        icon: String,
        isSystem: Bool
    ) -> some View {
        HStack(spacing: 0) {
            // LEFT: Colored accent strip with type indicator
            ZStack {
                // Colored background for left section
                color

                VStack(spacing: 4) {
                    Circle()
                        .fill(colors.surface)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(colors.border, lineWidth: 1.5))

                    if isSystem {
                        Image(systemName: IconCatalog.lockFill)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))
                    }
                }
            }
            .frame(width: 36)
            .frame(maxHeight: .infinity)

            // WALL
            Rectangle()
                .fill(colors.border)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Title and subtitle (WHITE background, BLACK text)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(JohoFont.caption)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: .infinity)
            .background(colors.surface)

            // WALL
            Rectangle()
                .fill(colors.border)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT: Decoration icon sticker
            JohoSticker(content: .icon(icon), color: color, size: 28)
                .frame(width: 52)
                .frame(maxHeight: .infinity)
                .background(colors.surface)
        }
        .frame(height: 56)
        .background(colors.surface)
        .johoBordered()
    }

    // MARK: - Helper Functions

    /// Returns a preview of note content (first line or first 40 characters)
    private func notePreview(_ content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Note"
        }

        // Get first line
        if let firstLine = trimmed.components(separatedBy: .newlines).first, !firstLine.isEmpty {
            // Limit to 40 characters
            if firstLine.count > 40 {
                return String(firstLine.prefix(40)) + "..."
            }
            return firstLine
        }

        // Fallback to first 40 characters
        if trimmed.count > 40 {
            return String(trimmed.prefix(40)) + "..."
        }
        return trimmed
    }

    /// Formats a Double amount as currency
    private func formatCurrency(_ amount: Double) -> String {
        CurrencyFormatter.formattedLocale(amount)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: IconCatalog.calendarBadgeCheckmark)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityMedium))

            Text("No special days")
                .font(JohoFont.body)
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))

            Text("Long press on any day to see details")
                .font(JohoFont.caption)
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingXL)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: 1.5, borderColor: colors.border.opacity(JohoDimensions.opacityMedium))
    }
}

// MARK: - Preview

#Preview {
    var dataCheck = DayDataCheck()
    dataCheck.hasHoliday = true
    dataCheck.holidayName = "New Year's Day"
    dataCheck.holidaySymbolName = IconCatalog.holiday
    dataCheck.hasEvent = true
    dataCheck.eventNames = ["Team Meeting", "Dentist Appointment"]
    dataCheck.hasBirthday = true
    dataCheck.birthdayNames = ["Anna", "Erik"]
    dataCheck.hasNote = true
    dataCheck.noteContent = "Remember to buy groceries and pick up the dry cleaning"
    dataCheck.hasTrip = true
    dataCheck.tripDestination = "Tokyo"
    dataCheck.hasExpense = true
    dataCheck.expenseAmount = 152.50
    dataCheck.hasObservance = true
    dataCheck.observanceNames = ["Flag Day"]

    return DayDetailSheet(
        day: CalendarDay(
            date: Date(),
            dayNumber: 15,
            isInCurrentMonth: true,
            isToday: true,
            noteColor: nil,
            secondaryDateString: nil
        ),
        dataCheck: dataCheck
    )
}
