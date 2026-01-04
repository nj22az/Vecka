//
//  AppSidebar.swift
//  Vecka
//
//  3x3 Icon Grid Sidebar - 情報デザイン Design
//  Solid colors + black borders (NO glass effects)
//

import SwiftUI

// MARK: - Sidebar Selection

enum SidebarSelection: String, Hashable, Identifiable, CaseIterable {
    case landing      // 情報デザイン: Today's Dashboard - summary + navigation hub
    case calendar
    case tools        // 情報デザイン draggable widget workspace
    case contacts
    case specialDays  // Combined Holidays, Observances, Countdowns, Notes, Trips & Expenses
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .landing: return "Today"
        case .calendar: return Localization.calendar
        case .tools: return "Tools"
        case .contacts: return Localization.contacts
        case .specialDays: return "Star"
        case .settings: return Localization.settings
        }
    }

    var icon: String {
        switch self {
        case .landing: return "house.fill"
        case .calendar: return "calendar"
        case .tools: return "wrench.and.screwdriver"
        case .contacts: return "person.2"
        case .specialDays: return "star.fill"
        case .settings: return "gearshape"
        }
    }

    /// The accent color for this item's circle background when selected
    var accentColor: Color {
        switch self {
        case .landing: return Color(hex: "F59E0B")    // Warm Amber (情報デザイン: TODAY/NOW)
        case .calendar: return Color(hex: "E53E3E")   // Red
        case .tools: return Color(hex: "00B4D8")      // Cyan (情報デザイン accent)
        case .contacts: return Color(hex: "718096")   // Slate
        case .specialDays: return Color(hex: "FFD700") // Gold (star = gold)
        case .settings: return Color(hex: "718096")   // Slate
        }
    }

    /// Index for swipe navigation ordering
    /// Landing → Calendar → Tools → Contacts → Star → Settings
    var pageIndex: Int {
        switch self {
        case .landing: return 0
        case .calendar: return 1
        case .tools: return 2
        case .contacts: return 3
        case .specialDays: return 4
        case .settings: return 5
        }
    }

    /// Get selection by page index (for swipe navigation)
    static func fromIndex(_ index: Int) -> SidebarSelection? {
        SidebarSelection.allCases.first { $0.pageIndex == index }
    }
}

// MARK: - App Sidebar (3x3 Icon Grid with Liquid Glass)

struct AppSidebar: View {
    @Binding var selection: SidebarSelection?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header (情報デザイン: Black text on white)
            Text("WeekGrid")
                .font(JohoFont.headline)
                .foregroundStyle(JohoColors.black)
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingMD)

            // 3x3 Icon Grid (情報デザイン: Solid white container, black border)
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(SidebarSelection.allCases) { item in
                    SidebarIconButton(
                        item: item,
                        isSelected: selection == item
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = item
                        }
                    }
                }
            }
            .padding(JohoDimensions.spacingMD)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
            )
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()

            // Footer (情報デザイン: Black text with opacity)
            VStack(spacing: 4) {
                Text("WeekGrid")
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
                Text("© 2025 The Office of Nils Johansson")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, JohoDimensions.spacingMD)
        }
        .background(JohoColors.white)
        .navigationBarHidden(true)
    }
}

// MARK: - Sidebar Icon Button (情報デザイン: Solid colors + borders, NO glass)

struct SidebarIconButton: View {
    let item: SidebarSelection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 情報デザイン: Solid colored circle + black border (NO glassEffect)
                ZStack {
                    Circle()
                        .fill(isSelected ? item.accentColor : JohoColors.inputBackground)
                        .frame(width: 52, height: 52)

                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? .white : JohoColors.black.opacity(0.6))
                        .frame(width: 52, height: 52)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? JohoColors.black : JohoColors.black.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )

                // Label
                Text(item.label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? JohoColors.black : JohoColors.black.opacity(0.6))
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
