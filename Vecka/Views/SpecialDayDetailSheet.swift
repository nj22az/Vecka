//
//  SpecialDayDetailSheet.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Special Day Detail Sheet
//  Half-sheet modal for viewing holiday/memo details
//

import SwiftUI

/// 情報デザイン: Special day detail sheet shown on tap
/// Displays details for a single SpecialDayRow
struct SpecialDayDetailSheet: View {
    let item: SpecialDayRow
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header bar with type code
            header

            // Content
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Icon zone
                    iconZone

                    // Divider
                    Rectangle()
                        .fill(colors.border)
                        .frame(height: 2)
                        .padding(.horizontal, JohoDimensions.spacingLG)

                    // Title
                    Text(item.title)
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, JohoDimensions.spacingLG)

                    // Details section
                    detailsSection

                    Spacer(minLength: JohoDimensions.spacingXL)
                }
                .padding(.top, JohoDimensions.spacingMD)
                .padding(.bottom, JohoDimensions.spacingLG)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.surface)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Type code pill
            Text(item.type.code)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(colors.primaryInverted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(colors.primary)
                .clipShape(Capsule())

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
                    .frame(width: 32, height: 32)
                    .background(colors.primary.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(colors.primary)
    }

    // MARK: - Icon Zone

    private var iconZone: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: item.symbolName ?? item.type.defaultIcon)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(item.type.accentColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(item.type.lightBackground)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(spacing: 0) {
            // Date row
            detailRow(
                label: "DATE",
                value: dateFormatter.string(from: item.date)
            )

            // Divider
            Rectangle()
                .fill(colors.primary.opacity(0.15))
                .frame(height: 1)

            // Region row (if present)
            if item.hasCountryPill {
                HStack(spacing: JohoDimensions.spacingSM) {
                    Text("REGION")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .frame(width: 60, alignment: .leading)

                    CountryPill(region: item.region)

                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)

                // Divider
                Rectangle()
                    .fill(colors.primary.opacity(0.15))
                    .frame(height: 1)
            }

            // Birthday age (if applicable)
            if item.type == .birthday, let age = item.turningAge {
                detailRow(
                    label: "AGE",
                    value: birthdayDisplayText(age: age, date: item.date)
                )

                // Divider
                Rectangle()
                    .fill(colors.primary.opacity(0.15))
                    .frame(height: 1)
            }

            // Notes row (if present)
            if let notes = item.notes, !notes.isEmpty, notes != item.title {
                VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                    Text("NOTES")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))

                    Text(notes)
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
            }

            // Days until/ago
            let daysText = daysUntilText
            if !daysText.isEmpty {
                detailRow(label: "STATUS", value: daysText)
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.5))
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(JohoFont.body)
                .foregroundStyle(colors.primary)

            Spacer()
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    private var daysUntilText: String {
        let days = item.daysUntil
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days == -1 {
            return "Yesterday"
        } else if days > 0 {
            return "In \(days) days"
        } else {
            return "\(abs(days)) days ago"
        }
    }
}

// MARK: - Preview

#Preview {
    SpecialDayDetailSheet(
        item: SpecialDayRow(
            id: "preview-1",
            ruleID: "preview-rule",
            region: "SE",
            date: Date(),
            title: "New Year's Day",
            type: .holiday,
            symbolName: "star.fill",
            iconColor: nil,
            notes: "Public holiday in Sweden. Offices and shops are closed.",
            isCustom: false,
            isMemo: false,
            originalBirthday: nil,
            turningAge: nil
        )
    )
}
