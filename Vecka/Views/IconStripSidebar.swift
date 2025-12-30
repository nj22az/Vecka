//
//  IconStripSidebar.swift
//  Vecka
//
//  Slim vertical icon sidebar (56pt) with blue selection bar
//  Replaces the 3x3 grid sidebar for elegant minimal design
//

import SwiftUI

// MARK: - Icon Strip Sidebar

struct IconStripSidebar: View {
    @Binding var selection: SidebarSelection?

    // MARK: - Layout Constants
    private let sidebarWidth: CGFloat = 56
    private let iconSize: CGFloat = 22
    private let activeBarWidth: CGFloat = 4
    private let itemHeight: CGFloat = 44

    // Main items (everything except settings)
    private var mainItems: [SidebarSelection] {
        SidebarSelection.allCases.filter { $0 != .settings }
    }

    var body: some View {
        VStack(spacing: 0) {
            // App logo/icon at top
            appIconHeader
                .padding(.top, Spacing.medium)
                .padding(.bottom, Spacing.large)

            // Main navigation icons
            VStack(spacing: 4) {
                ForEach(mainItems) { item in
                    IconStripButton(
                        item: item,
                        isSelected: selection == item,
                        activeBarWidth: activeBarWidth,
                        iconSize: iconSize,
                        itemHeight: itemHeight
                    ) {
                        withAnimation(AnimationConstants.sidebarSpring) {
                            selection = item
                        }
                    }
                }
            }

            Spacer()

            // Divider before settings
            Rectangle()
                .fill(SlateColors.divider)
                .frame(height: 1)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.small)

            // Settings at bottom
            IconStripButton(
                item: .settings,
                isSelected: selection == .settings,
                activeBarWidth: activeBarWidth,
                iconSize: iconSize,
                itemHeight: itemHeight
            ) {
                withAnimation(AnimationConstants.sidebarSpring) {
                    selection = .settings
                }
            }
            .padding(.bottom, Spacing.large)
        }
        .frame(width: sidebarWidth)
        .background(SlateColors.deepSlate)
    }

    // MARK: - App Icon Header

    private var appIconHeader: some View {
        Image(systemName: "calendar.badge.clock")
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(SlateColors.sidebarActiveBar)
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
                // Selection indicator bar (4pt blue when selected)
                Capsule()
                    .fill(isSelected ? SlateColors.sidebarActiveBar : Color.clear)
                    .frame(width: activeBarWidth, height: itemHeight * 0.6)

                Spacer()

                // Icon
                Image(systemName: item.icon)
                    .font(.system(size: iconSize, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? SlateColors.iconActive : SlateColors.iconDefault)
                    .frame(width: 40, height: 40)

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
    HStack(spacing: 0) {
        IconStripSidebar(selection: .constant(.calendar))

        Rectangle()
            .fill(SlateColors.mediumSlate)
    }
    .frame(width: 400, height: 600)
    .preferredColorScheme(.dark)
}

#Preview("Icon Strip - All States") {
    HStack(spacing: 20) {
        ForEach([SidebarSelection.calendar, .notes, .settings], id: \.self) { selected in
            IconStripSidebar(selection: .constant(selected))
                .frame(height: 500)
        }
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
