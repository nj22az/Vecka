//
//  SharedColors.swift
//  Vecka
//
//  Shared color definitions between app and widget extension
//  IMPORTANT: Add to both Vecka and VeckaWidgetExtension targets
//

import SwiftUI

// MARK: - Thread-Safe Hex Color Extension
extension Color {
    /// Thread-safe hex color initialization with proper error handling
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

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
            (a, r, g, b) = (255, 0, 0, 0)
        }

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

// MARK: - Shared Colors
/// Colors shared between main app and widget extension
/// Single source of truth for planetary and weekend colors
struct SharedColors {
    // MARK: - Planetary Colors (Daily Associations)
    /// Monday - Moon (Pale silver)
    static let mondayMoon = Color(hex: "C0C0C0")
    /// Tuesday - Mars (Fire red)
    static let tuesdayFire = Color(hex: "E53E3E")
    /// Wednesday - Mercury (Water blue)
    static let wednesdayWater = Color(hex: "1B6DEF")
    /// Thursday - Jupiter (Wood green)
    static let thursdayWood = Color(hex: "38A169")
    /// Friday - Venus (Metal gold)
    static let fridayMetal = Color(hex: "B8860B")
    /// Saturday - Saturn (Earth brown)
    static let saturdayEarth = Color(hex: "8B4513")
    /// Sunday - Sun (Bright gold)
    static let sundaySun = Color(hex: "FFD700")

    // MARK: - Weekend Colors (Slate Design)
    /// Sunday text color - Blue (matches calendar UI)
    static let sundayBlue = Color(hex: "5B8DEF")

    // MARK: - Helpers

    /// Get planetary color for weekday (1=Sunday, 2=Monday, etc.)
    static func planetaryColorForWeekday(_ weekday: Int) -> Color {
        switch weekday {
        case 1: return sundaySun      // Sunday
        case 2: return mondayMoon     // Monday
        case 3: return tuesdayFire    // Tuesday
        case 4: return wednesdayWater // Wednesday
        case 5: return thursdayWood   // Thursday
        case 6: return fridayMetal    // Friday
        case 7: return saturdayEarth  // Saturday
        default: return Color.accentColor
        }
    }
}
