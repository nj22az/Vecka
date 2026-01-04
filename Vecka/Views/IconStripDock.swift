//
//  IconStripDock.swift
//  Vecka
//
//  Horizontal bottom dock for iPhone - adapts iPad's IconStripSidebar
//  Black background, semantic accent colors, thick borders
//

import SwiftUI

// MARK: - Icon Strip Dock (iPhone Bottom Navigation)

struct IconStripDock: View {
    @Binding var selection: SidebarSelection?

    /// Action for the + button (context-aware based on current selection)
    var onAdd: (() -> Void)?

    /// Custom accent color for the plus button
    var addButtonColor: Color = JohoColors.cyan

    // MARK: - Layout Constants
    private let dockHeight: CGFloat = 56
    private let iconSize: CGFloat = 22
    private let activeBarHeight: CGFloat = 4

    // Dock items - main navigation sections (情報デザイン: 5 pages)
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
                // Navigation items
                ForEach(dockItems) { item in
                    dockButton(for: item)
                }

                // Add button (if action provided)
                if let addAction = onAdd {
                    addButton(action: addAction)
                }
            }
            .frame(height: dockHeight)
            .background(JohoColors.black)
        }
    }

    // MARK: - Dock Button

    private func dockButton(for item: SidebarSelection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = item
            }
        } label: {
            VStack(spacing: 4) {
                // Selection indicator bar (top)
                Capsule()
                    .fill(selection == item ? item.accentColor : Color.clear)
                    .frame(width: 24, height: activeBarHeight)

                // Icon
                Image(systemName: item.icon)
                    .font(.system(size: iconSize, weight: selection == item ? .bold : .medium, design: .rounded))
                    .foregroundStyle(selection == item ? item.accentColor : JohoColors.white.opacity(0.6))

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: dockHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(selection == item ? .isSelected : [])
    }

    // MARK: - Add Button

    private func addButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Spacer to align with other icons
                Color.clear
                    .frame(height: activeBarHeight)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: iconSize, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 36, height: 36)
                    .background(addButtonColor)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))

                Spacer()
            }
            .frame(width: 56)
            .frame(height: dockHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}

// MARK: - Preview

#Preview("Icon Strip Dock") {
    VStack {
        Spacer()
        Text("Content Area")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(JohoColors.background)

        IconStripDock(
            selection: .constant(.calendar),
            onAdd: { print("Add tapped") },
            addButtonColor: JohoColors.yellow
        )
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
