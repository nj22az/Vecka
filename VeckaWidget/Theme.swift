//
//  Theme.swift
//  VeckaWidget
//
//  Unified widget theme aligned with app design system
//  Apple HIG + Liquid Glass compatible
//

import SwiftUI
import WidgetKit

// MARK: - Unified Widget Colors

/// Colors for widget extension
/// NOTE: These mirror Vecka/SharedColors.swift - the single source of truth
/// TODO: Add SharedColors.swift to widget target for proper deduplication
struct WidgetColors {
    // MARK: - Widget-Specific Colors
    /// Apple Calendar-style accent
    static let accent = Color.red
    /// Semantic colors for special days
    static let holiday = Color.red
    static let observance = Color.green

    // MARK: - Weekend Colors (mirrors SharedColors)
    /// Sunday text color - Blue
    static let sundayBlue = Color(red: 91/255, green: 141/255, blue: 239/255)    // #5B8DEF
    static let saturdayNormal = Color.primary

    // Legacy names for backwards compatibility
    static var saturdayBlue: Color { saturdayNormal }
    static var sundayRed: Color { sundayBlue }

    // MARK: - Planetary Colors (mirrors SharedColors)
    /// Monday - Moon (Pale silver) #C0C0C0
    static let mondayMoon = Color(red: 192/255, green: 192/255, blue: 192/255)
    /// Tuesday - Mars (Fire red) #E53E3E
    static let tuesdayFire = Color(red: 229/255, green: 62/255, blue: 62/255)
    /// Wednesday - Mercury (Water blue) #1B6DEF
    static let wednesdayWater = Color(red: 27/255, green: 109/255, blue: 239/255)
    /// Thursday - Jupiter (Wood green) #38A169
    static let thursdayWood = Color(red: 56/255, green: 161/255, blue: 105/255)
    /// Friday - Venus (Metal gold) #B8860B
    static let fridayMetal = Color(red: 184/255, green: 134/255, blue: 11/255)
    /// Saturday - Saturn (Earth brown) #8B4513
    static let saturdayEarth = Color(red: 139/255, green: 69/255, blue: 19/255)
    /// Sunday - Sun (Bright gold) #FFD700
    static let sundaySun = Color(red: 255/255, green: 215/255, blue: 0/255)

    /// Get planetary color for weekday (1=Sunday, 2=Monday, etc.)
    static func colorForWeekday(_ weekday: Int) -> Color {
        switch weekday {
        case 1: return sundaySun
        case 2: return mondayMoon
        case 3: return tuesdayFire
        case 4: return wednesdayWater
        case 5: return thursdayWood
        case 6: return fridayMetal
        case 7: return saturdayEarth
        default: return accent
        }
    }
}

// MARK: - Week Column Icon (Calendar outline for header)
struct WeekColumnIcon: View {
    var body: some View {
        Image(systemName: "calendar")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(WidgetColors.accent)
    }
}

// MARK: - Week Badge (Calendar outline with week number inside)
struct WeekBadge: View {
    let weekNumber: Int
    var size: Size = .medium

    enum Size {
        case compact // For large widget header - matches icon height
        case small   // For small widget
        case medium  // For medium widget headers

        var iconSize: CGFloat {
            switch self {
            case .compact: return 22
            case .small: return 32
            case .medium: return 38
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .compact: return 11
            case .small: return 14
            case .medium: return 17
            }
        }

        var strokeWidth: CGFloat {
            switch self {
            case .compact: return 1.5
            case .small: return 1.5
            case .medium: return 2
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .compact: return 4
            case .small: return 6
            case .medium: return 7
            }
        }

        var topBarHeight: CGFloat {
            switch self {
            case .compact: return 4
            case .small: return 6
            case .medium: return 7
            }
        }
    }

    var body: some View {
        ZStack {
            // Calendar outline shape
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(WidgetColors.accent, lineWidth: size.strokeWidth)
                .frame(width: size.iconSize, height: size.iconSize)

            VStack(spacing: 0) {
                // Top bar (like calendar header)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(WidgetColors.accent)
                    .frame(width: size.iconSize - 4, height: size.topBarHeight)
                    .offset(y: size == .compact ? 0 : (size == .small ? -1 : -1))

                // Week number
                Text("\(weekNumber)")
                    .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .offset(y: size == .compact ? 1 : (size == .small ? 2 : 2))
            }
        }
        .frame(width: size.iconSize, height: size.iconSize)
    }
}

// MARK: - Theme (HIG-Compliant Design System)
struct Theme {
    // Standard widget corner radius per HIG
    static let cornerRadius: CGFloat = 20
    
    // Consistent padding following HIG spacing
    static let padding: CGFloat = 16
    static let compactPadding: CGFloat = 12
    static let itemSpacing: CGFloat = 8
    
    // Helper to adapt colors based on rendering mode
    static func primaryLabel(for mode: WidgetRenderingMode) -> Color {
        switch mode {
        case .vibrant: return .white
        case .accented: return .primary // System handles accenting
        default: return .primary
        }
    }
    
    static func secondaryLabel(for mode: WidgetRenderingMode) -> Color {
        switch mode {
        case .vibrant: return .white.opacity(0.6)
        case .accented: return .secondary // System handles accenting
        default: return .secondary
        }
    }
    
    static func tertiaryLabel(for mode: WidgetRenderingMode) -> Color {
        switch mode {
        case .vibrant: return .white.opacity(0.4)
        case .accented: return .secondary.opacity(0.6) // System handles accenting
        default: return Color(uiColor: .tertiaryLabel)
        }
    }
    
    // Accent colors following system palette
    static func accentColor(for weekday: Int, mode: WidgetRenderingMode) -> Color {
        if mode == .accented {
            return .primary // In accented mode, everything flattens to the tint
        }
        if mode == .vibrant {
            return .white // In vibrant mode, we usually want white or very light
        }

        switch weekday {
        case 1: return WidgetColors.sundayBlue  // Sunday = Blue (matches slate design)
        case 2: return .gray                     // Monday
        case 3: return .orange                   // Tuesday
        case 4: return .blue                     // Wednesday
        case 5: return .green                    // Thursday
        case 6: return .indigo                   // Friday
        case 7: return .primary                  // Saturday = Normal (matches slate design)
        default: return .accentColor
        }
    }
    
    // Gradients for FullColor mode
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let colors: [Color] = colorScheme == .dark ?
            [Color(uiColor: .systemGray6), Color(uiColor: .systemGray5)] :
            [Color(uiColor: .systemBackground), Color(uiColor: .secondarySystemBackground)]
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
