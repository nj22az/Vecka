//
//  DesignSystem.swift
//  Vecka
//
//  Japanese web-inspired design system
//

import SwiftUI

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
    static let mondayMoon = Color(hex: "C0C0C0")      // Pale silver for moon
    static let tuesdayFire = Color(hex: "E53E3E")     // Red for fire
    static let wednesdayWater = Color(hex: "1B6DEF")  // Blue for water
    static let thursdayWood = Color(hex: "38A169")    // Green for wood
    static let fridayMetal = Color(hex: "B8860B")     // Dark gold/metallic for metal
    static let saturdayEarth = Color(hex: "8B4513")   // Brown for earth
    static let sundaySun = Color(hex: "FFD700")       // Bright golden for sun
    
    // Dynamic color function for daily color scheme
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
}

// MARK: - Thread-Safe Helper Extensions
extension Color {
    init(hex: String) {
        // Thread-safe hex parsing with proper error handling
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        // Failsafe: Use default color if hex parsing fails
        guard Scanner(string: hex).scanHexInt64(&int) else {
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // Failsafe: Default to black if invalid hex length
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        // Clamp values to prevent invalid color creation
        let clampedR = min(255, max(0, r))
        let clampedG = min(255, max(0, g))
        let clampedB = min(255, max(0, b))
        let clampedA = min(255, max(0, a))
        
        self.init(
            .sRGB,
            red: Double(clampedR) / 255.0,
            green: Double(clampedG) / 255.0,
            blue: Double(clampedB) / 255.0,
            opacity: Double(clampedA) / 255.0
        )
    }
}

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
    static let caption1 = Font.caption                   // iOS standard caption1
    static let caption2 = Font.caption2                  // iOS standard caption2
    static let captionLarge = Font.system(size: 12, weight: .medium, design: .default)
    static let captionMedium = Font.system(size: 11, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 10, weight: .medium, design: .default)
    
    // MARK: - Label Styles (UI Elements)
    static let labelLarge = Font.system(size: 17, weight: .semibold, design: .default)
    static let labelMedium = Font.system(size: 15, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 13, weight: .medium, design: .default)
    
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

// (DashboardCard removed; unused after dashboard components cleanup)
