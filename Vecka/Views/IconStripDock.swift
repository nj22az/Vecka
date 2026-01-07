//
//  IconStripDock.swift
//  Vecka
//
//  Horizontal bottom dock for iPhone - 5 navigation items only
//  情報デザイン: House, Calendar, Contacts, Star, Cog
//

import SwiftUI

// MARK: - Icon Strip Dock (iPhone Bottom Navigation)

struct IconStripDock: View {
    @Binding var selection: SidebarSelection?

    // MARK: - Layout Constants (情報デザイン: Selected icon is larger)
    private let dockHeight: CGFloat = 56
    private let iconSizeNormal: CGFloat = 20
    private let iconSizeSelected: CGFloat = 24
    private let activeBarHeight: CGFloat = 4

    // Dock items - main navigation sections (情報デザイン: 5 pages only)
    private let dockItems: [SidebarSelection] = [
        .landing, .calendar, .contacts, .specialDays, .settings
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(JohoColors.white.opacity(0.2))
                .frame(height: 1)

            HStack(spacing: 0) {
                // Navigation items only - no extra buttons
                ForEach(dockItems) { item in
                    dockButton(for: item)
                }
            }
            .frame(height: dockHeight)
            .background(JohoColors.black)
        }
    }

    // MARK: - Dock Button

    private func dockButton(for item: SidebarSelection) -> some View {
        let isSelected = selection == item
        let iconSize = isSelected ? iconSizeSelected : iconSizeNormal

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = item
            }
        } label: {
            VStack(spacing: 4) {
                // Selection indicator bar (top)
                Capsule()
                    .fill(isSelected ? item.accentColor : Color.clear)
                    .frame(width: 24, height: activeBarHeight)

                // Icon (情報デザイン: Selected is larger)
                Image(systemName: item.icon)
                    .font(.system(size: iconSize, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? item.accentColor : JohoColors.white.opacity(0.6))
                    .animation(.easeInOut(duration: 0.15), value: isSelected)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: dockHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("Icon Strip Dock") {
    VStack {
        Spacer()
        Text("Content Area")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(JohoColors.background)

        IconStripDock(selection: .constant(.calendar))
    }
    .ignoresSafeArea(edges: .bottom)
}

#Preview("Icon Strip Dock - All States") {
    VStack(spacing: 20) {
        ForEach([SidebarSelection.landing, .calendar, .contacts, .specialDays, .settings], id: \.self) { selected in
            IconStripDock(selection: .constant(selected))
        }
    }
    .background(JohoColors.background)
}
