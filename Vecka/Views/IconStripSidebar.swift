//
//  IconStripSidebar.swift
//  Vecka
//
//  Slim vertical icon sidebar (56pt) with 情報デザイン styling
//  Black background, cyan accent, thick borders
//

import SwiftUI

// MARK: - Icon Strip Sidebar

struct IconStripSidebar: View {
    @Binding var selection: SidebarSelection?

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// Action for the + button (context-aware based on current selection)
    var onAdd: (() -> Void)?

    /// Custom accent color for the plus button (defaults to cyan)
    var addButtonColor: Color = JohoColors.cyan

    /// Smart repack button - only shows when widgets need collapsing
    var showRepackButton: Bool = false
    var onRepack: (() -> Void)?

    /// Export button action
    var onExport: (() -> Void)?

    /// Legend popover state
    @State private var showLegend = false

    // MARK: - Layout Constants
    private let sidebarWidth: CGFloat = 56
    private let iconSize: CGFloat = 22
    private let activeBarWidth: CGFloat = 4
    private let itemHeight: CGFloat = 44

    // Main items (everything except settings and calendar - blue icon handles calendar)
    private var mainItems: [SidebarSelection] {
        SidebarSelection.allCases.filter { $0 != .settings && $0 != .calendar }
    }

    var body: some View {
        VStack(spacing: 0) {
            // App logo/icon at top - TAPPABLE, navigates to calendar dashboard
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selection = .calendar
                }
            } label: {
                appIconHeader
            }
            .buttonStyle(.plain)
            .padding(.top, JohoDimensions.spacingSM)
            .padding(.bottom, JohoDimensions.spacingLG)
            .accessibilityLabel("Calendar")

            // Main navigation icons
            VStack(spacing: 4) {
                ForEach(mainItems) { item in
                    IconStripButton(
                        item: item,
                        isSelected: selection == item,
                        activeBarWidth: activeBarWidth,
                        iconSize: iconSize,
                        itemHeight: itemHeight,
                        colors: colors
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = item
                        }
                    }
                }
            }

            Spacer()

            // Smart repack button - only shows when widgets need collapsing
            if showRepackButton, let repackAction = onRepack {
                JohoIconButton(
                    icon: "arrow.up.left.and.arrow.down.right.circle.fill",
                    color: colors.primary,
                    foregroundColor: JohoColors.cyan,
                    borderColor: JohoColors.cyan,
                    size: 44,
                    borderWidth: 2
                ) { repackAction() }
                .accessibilityLabel("Repack widgets")
                .padding(.bottom, JohoDimensions.spacingMD)
                .transition(.scale.combined(with: .opacity))
            }

            // Add button (context-aware action with custom color)
            if let addAction = onAdd {
                JohoIconButton(
                    icon: "plus",
                    color: addButtonColor,
                    size: 44,
                    borderWidth: 2
                ) { addAction() }
                .accessibilityLabel("Add")
                .padding(.bottom, JohoDimensions.spacingLG)
                .transition(.scale.combined(with: .opacity))
            }

            // Export button (above settings)
            if let exportAction = onExport {
                JohoIconButton(
                    icon: "square.and.arrow.up",
                    color: colors.primary,
                    size: 44,
                    borderWidth: 2
                ) { exportAction() }
                .accessibilityLabel("Export")
                .padding(.bottom, JohoDimensions.spacingSM)
            }

            // Legend info button
            JohoIconButton(
                icon: "info.circle",
                color: colors.primary,
                size: 44,
                borderWidth: 2
            ) { showLegend = true }
            .accessibilityLabel("Legend")
            .padding(.bottom, JohoDimensions.spacingSM)
            .popover(isPresented: $showLegend) {
                SidebarLegendView()
            }

            // Divider before settings - 情報デザイン: solid black or subtle white
            Rectangle()
                .fill(colors.surface.opacity(0.3))
                .frame(height: 1.5)
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.vertical, JohoDimensions.spacingSM)

            // Settings at bottom
            IconStripButton(
                item: .settings,
                isSelected: selection == .settings,
                activeBarWidth: activeBarWidth,
                iconSize: iconSize,
                itemHeight: itemHeight,
                colors: colors
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selection = .settings
                }
            }
            .padding(.bottom, JohoDimensions.spacingLG)
        }
        .frame(width: sidebarWidth)
        .background(colors.primary)
    }

    // MARK: - App Icon Header

    private var appIconHeader: some View {
        Image(systemName: "calendar.badge.clock")
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(JohoColors.cyan)
            .frame(width: 40, height: 40)
    }
}

// MARK: - Icon Strip Button

struct IconStripButton: View, Equatable {
    let item: SidebarSelection
    let isSelected: Bool
    let activeBarWidth: CGFloat
    let iconSize: CGFloat
    let itemHeight: CGFloat
    let colors: JohoScheme
    let action: () -> Void

    // Equatable conformance - closures not compared (always redraws on action change)
    static func == (lhs: IconStripButton, rhs: IconStripButton) -> Bool {
        lhs.item == rhs.item &&
        lhs.isSelected == rhs.isSelected &&
        lhs.activeBarWidth == rhs.activeBarWidth &&
        lhs.iconSize == rhs.iconSize &&
        lhs.itemHeight == rhs.itemHeight
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Selection indicator bar (item's accent color when selected)
                Capsule()
                    .fill(isSelected ? item.accentColor : Color.clear)
                    .frame(width: activeBarWidth, height: itemHeight * 0.6)

                Spacer()

                // Icon (uses item's accent color when selected for visual consistency)
                // 情報デザイン: min 0.7 opacity for readability
                Image(systemName: item.icon)
                    .font(.system(size: iconSize, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? item.accentColor : colors.surface.opacity(0.7))
                    .johoTouchTarget()

                Spacer()

                // Balance the layout
                Color.clear
                    .frame(width: activeBarWidth)
            }
            .frame(height: itemHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("Icon Strip Sidebar") {
    struct PreviewWrapper: View {
        @Environment(\.johoColorMode) private var colorMode
        private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

        var body: some View {
            HStack(spacing: 0) {
                IconStripSidebar(selection: .constant(.calendar))

                Rectangle()
                    .fill(colors.canvas)
            }
            .frame(width: 400, height: 600)
        }
    }
    return PreviewWrapper()
}

#Preview("Icon Strip - All States") {
    struct PreviewWrapper: View {
        @Environment(\.johoColorMode) private var colorMode
        private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

        var body: some View {
            HStack(spacing: 20) {
                ForEach([SidebarSelection.calendar, .contacts, .settings], id: \.self) { selected in
                    IconStripSidebar(selection: .constant(selected))
                        .frame(height: 500)
                }
            }
            .padding()
            .background(colors.canvas)
        }
    }
    return PreviewWrapper()
}

// MARK: - Sidebar Legend View

/// 情報デザイン: Compact legend popover showing all entry types
private struct SidebarLegendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let legendItems: [(code: String, label: String, icon: String, color: Color)] = [
        ("HOL", "HOLIDAY", "star.fill", Color(hex: "E53E3E")),
        ("OBS", "OBSERVANCE", "sparkles", Color(hex: "ED8936")),
        ("EVT", "EVENT", "calendar.badge.clock", Color(hex: "805AD5")),
        ("BDY", "BIRTHDAY", "birthday.cake.fill", Color(hex: "78350F")),
        ("NTE", "NOTE", "note.text", Color(hex: "4ADE80")),
        ("TRP", "TRIP", "airplane", Color(hex: "3182CE")),
        ("EXP", "EXPENSE", "dollarsign.circle.fill", Color(hex: "38A169"))
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header - 情報デザイン: Black with white text
            HStack {
                Text("LEGEND")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(colors.surface)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colors.primary)
                    .clipShape(Capsule())

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 24, height: 24)
                        .background(colors.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Legend rows
            VStack(spacing: 0) {
                ForEach(Array(legendItems.enumerated()), id: \.element.code) { index, item in
                    HStack(spacing: JohoDimensions.spacingMD) {
                        // Colored indicator circle with border
                        Circle()
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(colors.border, lineWidth: 1.5))

                        // Icon
                        Image(systemName: item.icon)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(item.color)
                            .frame(width: 20)

                        // Code pill (keep on colored background, so JohoColors.black is correct)
                        Text(item.code)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(item.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(colors.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(item.color, lineWidth: 1))

                        // Label
                        Text(item.label)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)

                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, 10)

                    if index < legendItems.count - 1 {
                        Rectangle()
                            .fill(colors.border.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }
            }
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JohoDimensions.radiusMedium, style: .continuous)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
        .frame(width: 260)
        .padding(JohoDimensions.spacingMD)
    }
}
