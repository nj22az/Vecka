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
    case landing      // 情報デザイン: Today's Data Dashboard (merged landing + tools)
    case calendar
    case contacts
    case specialDays  // Combined Holidays, Observances, Countdowns, Notes, Trips & Expenses
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .landing: return "Today"
        case .calendar: return Localization.calendar
        case .contacts: return Localization.contacts
        case .specialDays: return "Star"
        case .settings: return Localization.settings
        }
    }

    var icon: String {
        switch self {
        case .landing: return "house.fill"
        case .calendar: return "calendar"
        case .contacts: return "person.2"
        case .specialDays: return "star.fill"
        case .settings: return "gearshape"
        }
    }

    /// The accent color for this item - uses PageHeaderColor for consistency
    /// 情報デザイン: Each page has its own distinct color
    var accentColor: Color {
        switch self {
        case .landing: return PageHeaderColor.landing.accent       // Warm Amber #F59E0B
        case .calendar: return PageHeaderColor.calendar.accent     // Deep Indigo #4338CA
        case .contacts: return PageHeaderColor.contacts.accent     // Warm Brown #78350F
        case .specialDays: return PageHeaderColor.specialDays.accent  // Rich Amber #D97706
        case .settings: return PageHeaderColor.settings.accent     // Slate Blue #475569
        }
    }

    /// Index for swipe navigation ordering
    /// Landing → Calendar → Contacts → Star → Settings (5 pages)
    var pageIndex: Int {
        switch self {
        case .landing: return 0
        case .calendar: return 1
        case .contacts: return 2
        case .specialDays: return 3
        case .settings: return 4
        }
    }

    /// Get selection by page index (for swipe navigation)
    static func fromIndex(_ index: Int) -> SidebarSelection? {
        SidebarSelection.allCases.first { $0.pageIndex == index }
    }
}

// MARK: - App Sidebar (3x3 Icon Grid with Liquid Glass)

struct AppSidebar: View {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    @Binding var selection: SidebarSelection?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header (情報デザイン: Black text on white)
            Text("Onsen Planner")
                .font(JohoFont.headline)
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

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
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
            )
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()

            // Footer (情報デザイン: Black text with opacity)
            VStack(spacing: 4) {
                Text("Onsen Planner")
                    .font(JohoFont.caption)
                    .foregroundStyle(colors.primary.opacity(0.7))
                Text("© 2025 The Office of Nils Johansson")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(colors.primary.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .navigationBarHidden(true)
    }
}

// MARK: - Sidebar Icon Button (情報デザイン: Solid colors + borders, NO glass)

struct SidebarIconButton: View {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    let item: SidebarSelection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 情報デザイン: Solid colored circle + black border (NO glassEffect)
                ZStack {
                    Circle()
                        .fill(isSelected ? item.accentColor : colors.inputBackground)
                        .johoTouchTarget(52)

                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundStyle(isSelected ? .white : colors.primary.opacity(0.6))
                        .johoTouchTarget(52)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? colors.border : colors.border.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )

                // Label
                Text(item.label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? colors.primary : colors.primary.opacity(0.6))
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
