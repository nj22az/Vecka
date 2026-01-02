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

    var body: some View {
        NavigationStack {
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
            }
            .johoBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(16)
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Day number in large format
            VStack(spacing: 2) {
                Text("\(day.dayNumber)")
                    .font(JohoFont.displayLarge)
                    .foregroundStyle(JohoColors.black)

                Text(day.date.formatted(.dateTime.weekday(.wide)).uppercased())
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .frame(width: 80)

            // Vertical divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // Month and year
            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                Text(day.date.formatted(.dateTime.month(.wide).year()))
                    .font(JohoFont.headline)
                    .foregroundStyle(JohoColors.black)

                // Status pills
                HStack(spacing: JohoDimensions.spacingSM) {
                    if day.isToday {
                        JohoPill(text: "TODAY", style: .coloredInverted(JohoColors.yellow), size: .small)
                    }
                    if day.isHoliday {
                        JohoPill(text: "HOLIDAY", style: .coloredInverted(JohoColors.red), size: .small)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 32, height: 32)
                    .background(JohoColors.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
            }
        }
        .padding(JohoDimensions.spacingLG)
        .frame(height: 100)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    // MARK: - Content Sections

    private var hasAnyContent: Bool {
        guard let check = dataCheck else { return day.holidayName != nil }
        return check.hasHoliday || check.hasObservance || check.hasEvent ||
               check.hasBirthday || check.hasNote || check.hasTrip || check.hasExpense ||
               day.holidayName != nil
    }

    @ViewBuilder
    private var contentSections: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            // Holiday from CalendarDay (system holiday)
            if let holidayName = day.holidayName {
                detailRow(
                    title: holidayName,
                    subtitle: "Public Holiday",
                    color: JohoColors.red,
                    icon: day.holidaySymbolName ?? "star.fill",
                    isSystem: true
                )
            }

            // Indicator-based content from DayDataCheck
            if let check = dataCheck {
                if check.hasObservance && day.holidayName == nil {
                    detailRow(
                        title: "Observance",
                        subtitle: "Flag day / Memorial",
                        color: JohoColors.orange,
                        icon: "flag.fill",
                        isSystem: true
                    )
                }
                if check.hasEvent {
                    detailRow(
                        title: "Event",
                        subtitle: "Custom event",
                        color: JohoColors.eventPurple,
                        icon: "calendar.badge.clock",
                        isSystem: false
                    )
                }
                if check.hasBirthday {
                    detailRow(
                        title: "Birthday",
                        subtitle: "Contact birthday",
                        color: JohoColors.pink,
                        icon: "gift.fill",
                        isSystem: false
                    )
                }
                if check.hasNote {
                    detailRow(
                        title: "Note",
                        subtitle: "Personal note",
                        color: JohoColors.yellow,
                        icon: "note.text",
                        isSystem: false
                    )
                }
                if check.hasTrip {
                    detailRow(
                        title: "Trip",
                        subtitle: "Travel / Trip",
                        color: JohoColors.tripBlue,
                        icon: "airplane",
                        isSystem: false
                    )
                }
                if check.hasExpense {
                    detailRow(
                        title: "Expense",
                        subtitle: "Recorded expense",
                        color: JohoColors.green,
                        icon: "dollarsign.circle.fill",
                        isSystem: false
                    )
                }
            }
        }
    }

    // MARK: - Detail Row (Bento Style)

    @ViewBuilder
    private func detailRow(
        title: String,
        subtitle: String?,
        color: Color,
        icon: String,
        isSystem: Bool
    ) -> some View {
        HStack(spacing: 0) {
            // LEFT: Type indicator + lock
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))

                if isSystem {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(JohoColors.black.opacity(0.4))
                }
            }
            .frame(width: 32)
            .frame(maxHeight: .infinity)

            // WALL
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: .infinity)

            // WALL
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT: Decoration icon
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.15))
                .clipShape(Squircle(cornerRadius: 6))
                .overlay(Squircle(cornerRadius: 6).stroke(JohoColors.black, lineWidth: 1))
                .frame(width: 48)
                .frame(maxHeight: .infinity)
        }
        .frame(height: 52)
        .background(color.opacity(0.15))
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(JohoColors.black.opacity(0.3))

            Text("No special days")
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black.opacity(0.6))

            Text("Long press on any day to see details")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.black.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingXL)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: - Preview

#Preview {
    DayDetailSheet(
        day: CalendarDay(
            date: Date(),
            dayNumber: 15,
            isInCurrentMonth: true,
            isToday: true,
            noteColor: nil,
            secondaryDateString: nil
        ),
        dataCheck: DayDataCheck(
            hasHoliday: true,
            hasObservance: false,
            hasEvent: true,
            hasBirthday: true,
            hasNote: false,
            hasTrip: false,
            hasExpense: false
        )
    )
}
