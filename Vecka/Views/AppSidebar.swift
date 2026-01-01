//
//  AppSidebar.swift
//  Vecka
//
//  3x3 Icon Grid Sidebar - iOS 26 Liquid Glass Design
//  Native .glassEffect() with colored circle backgrounds
//

import SwiftUI

// MARK: - Sidebar Selection

enum SidebarSelection: String, Hashable, Identifiable, CaseIterable {
    case tools       // 情報デザイン draggable widget workspace (renamed from workspace)
    case calendar
    case contacts
    case specialDays  // Combined Holidays, Observances, Countdowns, Notes, Trips & Expenses
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .tools: return "Tools"
        case .calendar: return Localization.calendar
        case .contacts: return Localization.contacts
        case .specialDays: return "Special Days"
        case .settings: return Localization.settings
        }
    }

    var icon: String {
        switch self {
        case .tools: return "wrench.and.screwdriver"
        case .calendar: return "calendar"
        case .contacts: return "person.2"
        case .specialDays: return "star.fill"
        case .settings: return "gearshape"
        }
    }

    /// The accent color for this item's circle background when selected
    var accentColor: Color {
        switch self {
        case .tools: return Color(hex: "00B4D8")       // Cyan (情報デザイン accent)
        case .calendar: return Color(hex: "E53E3E")    // Red
        case .contacts: return Color(hex: "718096")    // Slate
        case .specialDays: return Color(hex: "FFD700") // Gold (star = gold)
        case .settings: return Color(hex: "718096")    // Slate
        }
    }
}

// MARK: - App Sidebar (3x3 Icon Grid with Liquid Glass)

struct AppSidebar: View {
    @Binding var selection: SidebarSelection?
    @Namespace private var sidebarNamespace

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with Liquid Glass
            Text("WeekGrid")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, Spacing.large)
                .padding(.top, Spacing.medium)

            // 3x3 Icon Grid with GlassEffectContainer
            GlassEffectContainer(spacing: 16) {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(SidebarSelection.allCases) { item in
                        SidebarIconButton(
                            item: item,
                            isSelected: selection == item,
                            namespace: sidebarNamespace
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selection = item
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)

            Spacer()

            // Footer
            VStack(spacing: 4) {
                Text("WeekGrid")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("© 2025 The Office of Nils Johansson")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.medium)
        }
        .background(JohoColors.white)
        .navigationBarHidden(true)
    }
}

// MARK: - Sidebar Icon Button with Liquid Glass

struct SidebarIconButton: View {
    let item: SidebarSelection
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon with colored circle background when selected
                ZStack {
                    Circle()
                        .fill(isSelected ? item.accentColor : Color.clear)
                        .frame(width: 52, height: 52)

                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .frame(width: 52, height: 52)
                }
                .if(isSelected) { view in
                    view.glassEffect(.regular.interactive(), in: .circle)
                }
                .glassEffectID(item.id, in: namespace)

                // Label
                Text(item.label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        AppSidebar(selection: .constant(.calendar))
    } detail: {
        Text("Detail View")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }
}
