//
//  SpecialDaysGridView.swift
//  Vecka
//
//  情報デザイン: 4×3 month grid overview for the Star page.
//  Extracted from SpecialDaysListView for focused component architecture.
//
//  Shows a 4-row × 3-column grid of month tile cards.
//  Each card uses JohoTileCard with seasonal theme colors and category dots.
//

import SwiftUI

// MARK: - Special Days Grid View

struct SpecialDaysGridView: View {
    // Data
    let monthCounts: (Int) -> (holidays: Int, observances: Int, birthdays: Int, memos: Int)
    let customIcon: (Int) -> String?
    let customIconColor: (Int) -> String?
    let customMessage: (Int) -> String?

    // Interaction
    let onSelectMonth: (Int) -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        // 情報デザイン: Use Grid (not LazyVGrid) for automatic row height synchronization
        Grid(horizontalSpacing: JohoDimensions.spacingSM, verticalSpacing: JohoDimensions.spacingSM) {
            ForEach(0..<4, id: \.self) { row in
                GridRow {
                    ForEach(1...3, id: \.self) { col in
                        let month = row * 3 + col
                        monthFlipcard(for: month)
                    }
                }
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Month Flipcard

    @ViewBuilder
    private func monthFlipcard(for month: Int) -> some View {
        let theme = MonthTheme.theme(for: month)
        let counts = monthCounts(month)
        let totalCount = counts.holidays + counts.observances + counts.birthdays + counts.memos
        let hasItems = totalCount > 0

        // 情報デザイン: Allow custom icon and icon color (background color locked to seasonal theme)
        let displayIcon = customIcon(month) ?? theme.icon
        let customIconColorHex = customIconColor(month)
        // 情報デザイン: Custom icon color takes priority, then always theme accent (季節の色 defines identity)
        let displayIconColor: Color = {
            if let hex = customIconColorHex {
                return Color(hex: hex)
            } else {
                return theme.accentColor
            }
        }()
        // 情報デザイン: Banner color is LOCKED to seasonal theme (users cannot change it)
        let displayColor: Color = theme.lightBackground
        let message = customMessage(month)

        JohoTileCard(
            label: theme.name,
            icon: displayIcon,
            iconColor: displayIconColor,
            bannerColor: displayColor
        ) {
            // Custom message + category dots
            HStack(spacing: 0) {
                if let message {
                    Text(message)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .overlay(alignment: .bottomTrailing) {
                if hasItems {
                    VStack(spacing: 3) {
                        if counts.holidays > 0 {
                            Circle()
                                .fill(CategoryColorSettings.shared.color(for: .holiday))
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        }
                        if counts.observances > 0 {
                            Circle()
                                .fill(CategoryColorSettings.shared.color(for: .observance))
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        }
                        if (counts.birthdays + counts.memos) > 0 {
                            Circle()
                                .fill(CategoryColorSettings.shared.color(for: .memo))
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        }
                    }
                    .padding(.trailing, 6)
                    .padding(.bottom, 6)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                onSelectMonth(month)
            }
            HapticManager.selection()
        }
    }
}
