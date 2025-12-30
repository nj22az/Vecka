//
//  DesignSystem.swift
//  Vecka
//
//  Apple HIG + Liquid Glass design system
//  One unified visual language for WeekGrid
//

import SwiftUI
import SwiftData

// MARK: - App Colors
struct AppColors {
    // MARK: - System Semantic Colors (Auto-adapting to Light/Dark Mode)
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let surfaceElevated = Color(.tertiarySystemBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let divider = Color(.separator)
    
    // MARK: - Apple Standard Accent Colors
    static let accentBlue = Color(.systemBlue)
    static let accentTeal = Color(.systemTeal)
    static let accentYellow = Color(.systemOrange)
    static let accentRed = Color(.systemRed)
    static let accentPurple = Color(.systemPurple)
    
    // MARK: - Daily Color Associations (Planetary Colors)
    // Delegated to SharedColors for consistency with widget
    static var mondayMoon: Color { SharedColors.mondayMoon }
    static var tuesdayFire: Color { SharedColors.tuesdayFire }
    static var wednesdayWater: Color { SharedColors.wednesdayWater }
    static var thursdayWood: Color { SharedColors.thursdayWood }
    static var fridayMetal: Color { SharedColors.fridayMetal }
    static var saturdayEarth: Color { SharedColors.saturdayEarth }
    static var sundaySun: Color { SharedColors.sundaySun }
    
    // Dynamic color function for daily color scheme
    // Note: Use colorForDay(date:context:) for database-driven themes
    static func colorForDay(_ date: Date) -> Color {
        let weekday = Calendar.iso8601.component(.weekday, from: date)

        switch weekday {
        case 1: return sundaySun      // Sunday - Sun
        case 2: return mondayMoon     // Monday - Moon
        case 3: return tuesdayFire    // Tuesday - Fire (Mars)
        case 4: return wednesdayWater // Wednesday - Water (Mercury)
        case 5: return thursdayWood   // Thursday - Wood (Jupiter)
        case 6: return fridayMetal    // Friday - Metal (Venus)
        case 7: return saturdayEarth  // Saturday - Earth (Saturn)
        default: return accentBlue
        }
    }

    // Database-driven theme color for day (uses UITheme from database)
    static func colorForDay(_ date: Date, context: ModelContext) -> Color {
        let weekday = Calendar.iso8601.component(.weekday, from: date)
        return ConfigurationManager.shared.getWeekdayColor(for: weekday, context: context)
    }
}

// MARK: - Slate Design Language (Dark Mode Focused)
/// Design tokens for the elegant dark slate UI from mockups
struct SlateColors {
    // MARK: - Backgrounds
    /// Deep slate background - the canvas everything sits on
    static let deepSlate = Color(hex: "1A1A2E")
    /// Medium slate for elevated surfaces like panels
    static let mediumSlate = Color(hex: "2A2A3E")
    /// Light slate for subtle elevation
    static let lightSlate = Color(hex: "3A3A4E")

    // MARK: - Today Indicator
    /// Subtle slate blue for today's cell highlight
    static let todayHighlight = Color(hex: "3D4A5C")
    /// Selected cell highlight (slightly more prominent)
    static let selectionHighlight = Color(hex: "4D5A6C")

    // MARK: - Text Colors
    /// Primary text (white)
    static let primaryText = Color.white
    /// Secondary text (60% white)
    static let secondaryText = Color(white: 0.6)
    /// Tertiary text (40% white)
    static let tertiaryText = Color(white: 0.4)
    /// Muted text for out-of-month days
    static let mutedText = Color(white: 0.25)

    // MARK: - Weekend Colors (Mockup Spec)
    /// Sunday text color - BLUE (not red) - delegated to SharedColors
    static var sundayBlue: Color { SharedColors.sundayBlue }
    /// Saturday text color - same as primary (not special)
    static let saturdayNormal = Color.white

    // MARK: - Accent Colors
    /// Sidebar selection bar (bright blue)
    static let sidebarActiveBar = Color(hex: "3B82F6")
    /// Default icon color (50% white)
    static let iconDefault = Color(white: 0.5)
    /// Active icon color (white)
    static let iconActive = Color.white

    // MARK: - Borders & Dividers
    /// Subtle divider line
    static let divider = Color(white: 0.2)
    /// Selection border
    static let selectionBorder = Color(hex: "3B82F6")

    // MARK: - Convenience Functions

    /// Returns the appropriate text color for a weekday
    /// - Parameters:
    ///   - isSunday: True if the day is Sunday
    ///   - isSaturday: True if the day is Saturday (not used - Saturday is normal)
    ///   - isToday: True if the day is today
    ///   - isInCurrentMonth: True if the day is in the displayed month
    /// - Returns: The appropriate text color
    static func dayTextColor(
        isSunday: Bool,
        isSaturday: Bool = false,
        isToday: Bool = false,
        isInCurrentMonth: Bool = true
    ) -> Color {
        if !isInCurrentMonth {
            return mutedText
        }
        if isSunday {
            return sundayBlue
        }
        // Saturday and all other days use primary text
        return primaryText
    }

    /// Returns the weekday header color
    /// - Parameter index: 0-based index where 0=Monday, 6=Sunday
    /// - Returns: The appropriate header color
    static func weekdayHeaderColor(for index: Int) -> Color {
        if index == 6 { // Sunday
            return sundayBlue
        }
        return secondaryText
    }
}

// MARK: - Thread-Safe Helper Extensions
// NOTE: Color.init(hex:) is now defined in SharedColors.swift

// MARK: - Typography System
/// Apple HIG-compliant typography scale following iOS 17 design guidelines
struct Typography {
    // MARK: - Display Styles (Hero Content)
    static let largeTitle = Font.largeTitle.weight(.bold)  // iOS standard large title
    static let heroDisplay = Font.system(size: 88, weight: .bold, design: .rounded)
    
    // MARK: - Title Styles (Primary Headings)
    static let title1 = Font.title.weight(.bold)          // iOS standard title1
    static let title2 = Font.title2.weight(.bold)         // iOS standard title2  
    static let title3 = Font.title3.weight(.semibold)     // iOS standard title3
    static let titleLarge = Font.system(size: 34, weight: .bold, design: .default)
    static let titleMedium = Font.system(size: 28, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 22, weight: .semibold, design: .default)
    
    // MARK: - Headline (Secondary Headings)
    static let headline = Font.headline.weight(.semibold)  // iOS standard headline
    
    // MARK: - Body Text (Content)
    static let body = Font.body                           // iOS standard body
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: - Callout (Emphasized Content)
    static let callout = Font.callout                     // iOS standard callout
    
    // MARK: - Subheadline (Supporting Text)
    static let subheadline = Font.subheadline            // iOS standard subheadline
    
    // MARK: - Footnote (Small Text)
    static let footnote = Font.footnote                  // iOS standard footnote
    
    // MARK: - Caption (Smallest Text)
    static let caption1 = Font.caption                   // iOS standard caption1 (12pt)
    static let caption2 = Font.caption2                  // iOS standard caption2 (11pt)
    static let captionLarge = Font.caption.weight(.medium)
    static let captionMedium = Font.caption2             // HIG: 11pt minimum, use system style
    static let captionSmall = Font.caption2.weight(.medium) // HIG: 11pt minimum, never below
    
    // MARK: - Label Styles (UI Elements)
    static let labelLarge = Font.body.weight(.semibold)
    static let labelMedium = Font.subheadline.weight(.medium)
    static let labelSmall = Font.footnote.weight(.medium)
    
    // MARK: - Tracking Values (Letter Spacing)
    static let tightTracking: CGFloat = -0.41        // Apple's tight tracking
    static let normalTracking: CGFloat = 0.0         // Default tracking
    static let wideTracking: CGFloat = 0.38          // Apple's wide tracking
    static let extraWideTracking: CGFloat = 1.2      // Extra wide for caps
    
    // MARK: - Line Height Multipliers
    static let tightLineSpacing: CGFloat = 1.1        // Tight line spacing
    static let normalLineSpacing: CGFloat = 1.2       // Normal line spacing
    static let relaxedLineSpacing: CGFloat = 1.4      // Relaxed line spacing
}

// MARK: - Spacing System
/// Consistent spacing scale following 8-point grid system
struct Spacing {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
    static let huge: CGFloat = 48
    static let massive: CGFloat = 64
    
    // Semantic spacing for specific use cases
    static let cardPadding: CGFloat = medium
    static let sectionSpacing: CGFloat = large
    static let componentSpacing: CGFloat = small
    static let elementSpacing: CGFloat = extraSmall
}

// MARK: - Glass Design System
/// Professional liquid glass design system with authentic Apple materials
struct GlassDesign {
    
    // MARK: - Glass Materials
    /// Elevation levels for different glass surfaces
    enum GlassElevation {
        case low        // Background cards, minimal depth
        case medium     // Interactive elements, moderate depth
        case high       // Important UI, strong emphasis
        case floating   // Popover content, maximum depth
        
        var material: Material {
            switch self {
            case .low:
                return .ultraThinMaterial
            case .medium:
                return .thinMaterial
            case .high:
                return .regularMaterial
            case .floating:
                return .thickMaterial
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .low:
                return 12
            case .medium:
                return 16
            case .high:
                return 20
            case .floating:
                return 24
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .low:
                return 2
            case .medium:
                return 4
            case .high:
                return 8
            case .floating:
                return 12
            }
        }
        
        var shadowOpacity: Double {
            switch self {
            case .low:
                return 0.1
            case .medium:
                return 0.15
            case .high:
                return 0.25
            case .floating:
                return 0.35
            }
        }
    }
    
    // MARK: - Glass Modifiers
    /// Creates a professional glass surface with proper depth and materials
    static func glassCard(elevation: GlassElevation = .medium) -> some ViewModifier {
        GlassCardModifier(elevation: elevation)
    }
    
    /// Creates a subtle glass background for content areas
    static func glassBackground(elevation: GlassElevation = .low) -> some ViewModifier {
        GlassBackgroundModifier(elevation: elevation)
    }
    
    /// Creates tinted glass morphism with subtle color overlay respecting appearance mode
    static func tintedGlass(elevation: GlassElevation = .medium, tint: Color = .clear) -> some ViewModifier {
        TintedGlassModifier(elevation: elevation, tint: tint)
    }
}

// MARK: - Glass View Modifiers
private struct GlassCardModifier: ViewModifier {
    let elevation: GlassDesign.GlassElevation
    
    func body(content: Content) -> some View {
        content
            .background(elevation.material)
            .clipShape(RoundedRectangle(cornerRadius: elevation.cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                x: 0,
                y: elevation.shadowRadius / 2
            )
    }
}

private struct GlassBackgroundModifier: ViewModifier {
    let elevation: GlassDesign.GlassElevation
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: elevation.cornerRadius, style: .continuous)
                    .fill(elevation.material)
                    .shadow(
                        color: Color.black.opacity(elevation.shadowOpacity),
                        radius: elevation.shadowRadius,
                        x: 0,
                        y: elevation.shadowRadius / 2
                    )
            )
    }
}

private struct TintedGlassModifier: ViewModifier {
    let elevation: GlassDesign.GlassElevation
    let tint: Color
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: elevation.cornerRadius, style: .continuous)
                        .fill(elevation.material)
                    
                    if tint != .clear {
                        RoundedRectangle(cornerRadius: elevation.cornerRadius, style: .continuous)
                            .fill(tint.opacity(colorScheme == .dark ? 0.15 : 0.08))
                            .blendMode(.overlay)
                    }
                }
                .shadow(
                    color: Color.black.opacity(elevation.shadowOpacity),
                    radius: elevation.shadowRadius,
                    x: 0,
                    y: elevation.shadowRadius / 2
                )
            )
    }
}

// MARK: - Glass Toolbar Button Style
/// Apple Glass-compliant toolbar button style with capsule background
struct GlassToolbarButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(isProminent ? Color.accentColor : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Glass Card View Modifier
/// Material-based glass card for content containers (replaces solid color backgrounds)
struct GlassCardViewModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var material: Material = .regularMaterial
    
    func body(content: Content) -> some View {
        content
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
            )
    }
}

extension View {
    /// Applies Apple Glass card styling with material background
    func glassCard(cornerRadius: CGFloat = 16, material: Material = .regularMaterial) -> some View {
        modifier(GlassCardViewModifier(cornerRadius: cornerRadius, material: material))
    }
}

// (DashboardCard removed; unused after dashboard components cleanup)

// MARK: - Unified Design Tokens
/// Single source of truth for the app's visual identity
struct DesignTokens {
    // MARK: - The One Accent Color
    /// WeekGrid uses a single accent color for all UI chrome.
    /// Planetary colors are reserved for week number display only.
    static let accent = Color.accentColor

    // MARK: - Glass Materials (Liquid Glass hierarchy)
    static let glassBackground = Material.ultraThinMaterial
    static let glassCard = Material.thinMaterial
    static let glassElevated = Material.regularMaterial
    static let glassFloating = Material.thickMaterial

    // MARK: - Corner Radii (Apple HIG continuous corners)
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXL: CGFloat = 20

    // MARK: - Shadows (subtle depth)
    static func shadow(for elevation: GlassDesign.GlassElevation) -> (color: Color, radius: CGFloat, y: CGFloat) {
        switch elevation {
        case .low:
            return (Color.black.opacity(0.08), 2, 1)
        case .medium:
            return (Color.black.opacity(0.12), 4, 2)
        case .high:
            return (Color.black.opacity(0.16), 8, 4)
        case .floating:
            return (Color.black.opacity(0.20), 12, 6)
        }
    }
}

// MARK: - Glass Card Component (iOS 26 Liquid Glass)
/// A unified glass card using native iOS 26 .glassEffect()
struct GlassCard<Content: View>: View {
    let elevation: GlassDesign.GlassElevation
    let tint: Color?
    let content: Content

    init(
        elevation: GlassDesign.GlassElevation = .medium,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .glassEffect(glassVariant, in: RoundedRectangle(cornerRadius: elevation.cornerRadius, style: .continuous))
    }

    private var glassVariant: Glass {
        if let tint = tint {
            return .regular.tint(tint)
        }
        return .regular
    }
}

// MARK: - Glass Section Header
/// Consistent section header styling
struct GlassSectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }
}

// MARK: - Glass List Row
/// A standard row for lists with glass styling
struct GlassListRow<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leading: Leading
    let trailing: Trailing
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leading

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                trailing
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

