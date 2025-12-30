//
//  WeatherIconMapper.swift
//  Vecka
//
//  Maps WeatherKit conditions to SF Symbols and semantic colors
//  Follows Apple HIG for weather visualization
//

import SwiftUI
import WeatherKit

@available(iOS 16.0, *)
enum WeatherIconMapper {

    // MARK: - SF Symbol Mapping

    /// Returns the appropriate SF Symbol for a weather condition
    static func icon(for condition: WeatherCondition) -> String {
        switch condition {
        // Clear conditions
        case .clear:
            return "sun.max.fill"
        case .mostlyClear:
            return "sun.max"

        // Cloudy conditions
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .mostlyCloudy:
            return "cloud.fill"
        case .cloudy:
            return "smoke.fill"

        // Rainy conditions
        case .drizzle:
            return "cloud.drizzle.fill"
        case .rain:
            return "cloud.rain.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .isolatedThunderstorms, .scatteredThunderstorms, .thunderstorms, .strongStorms:
            return "cloud.bolt.rain.fill"

        // Snowy conditions
        case .flurries:
            return "cloud.snow"
        case .snow:
            return "snow"
        case .heavySnow:
            return "cloud.snow.fill"
        case .blizzard:
            return "wind.snow"
        case .blowingSnow:
            return "wind.snow"
        case .freezingDrizzle, .freezingRain, .sleet:
            return "cloud.sleet.fill"
        case .hail:
            return "cloud.hail.fill"
        case .sunFlurries:
            return "cloud.sun.snow.fill"
        case .sunShowers:
            return "cloud.sun.rain.fill"

        // Windy/stormy conditions
        case .windy, .breezy:
            return "wind"
        case .hurricane:
            return "hurricane"
        case .tropicalStorm:
            return "tropicalstorm"

        // Atmospheric conditions
        case .foggy:
            return "cloud.fog.fill"
        case .haze:
            return "sun.haze.fill"
        case .smoky:
            return "smoke.fill"
        case .blowingDust:
            return "sun.dust.fill"
        case .frigid, .hot:
            return "thermometer.medium"

        // Mixed conditions
        case .wintryMix:
            return "cloud.sleet.fill"

        @unknown default:
            return "cloud.fill"
        }
    }

    // MARK: - Color Mapping

    /// Returns semantic color for weather condition (adapts to light/dark mode)
    static func color(for condition: WeatherCondition) -> Color {
        switch condition {
        // Sunny/clear - warm golden
        case .clear, .mostlyClear:
            return .orange

        // Partly cloudy - balanced
        case .partlyCloudy:
            return .yellow

        // Cloudy - neutral gray
        case .mostlyCloudy, .cloudy:
            return .secondary

        // Rainy - blue tones
        case .drizzle, .rain, .heavyRain:
            return .blue

        // Stormy - electric blue/purple
        case .isolatedThunderstorms, .scatteredThunderstorms, .thunderstorms, .strongStorms:
            return .purple

        // Snowy - cool blue-white
        case .flurries, .snow, .heavySnow, .blizzard, .blowingSnow:
            return .cyan

        // Frozen precipitation - icy blue
        case .freezingDrizzle, .freezingRain, .sleet, .wintryMix:
            return .indigo

        // Hail - purple-blue
        case .hail:
            return .indigo

        // Sun with precipitation - warm with blue
        case .sunShowers:
            return .blue
        case .sunFlurries:
            return .cyan

        // Atmospheric - muted
        case .foggy, .haze, .smoky, .blowingDust:
            return .gray

        // Extreme conditions - red
        case .hurricane, .tropicalStorm:
            return .red

        // Temperature extremes
        case .frigid:
            return .cyan
        case .hot:
            return .red

        // Windy - light gray
        case .windy, .breezy:
            return .gray

        @unknown default:
            return .secondary
        }
    }

    // MARK: - Accessibility

    /// Returns localized description for weather condition
    static func accessibilityLabel(for condition: WeatherCondition, temperature: Measurement<UnitTemperature>) -> String {
        let conditionText = WeatherLocalization.conditionName(condition)
        let tempValue = Int(temperature.value)
        let unit = temperature.unit.symbol

        return "\(conditionText), \(tempValue)\(unit)"
    }

    // MARK: - Temperature Formatting

    /// Format temperature for compact display
    static func formatTemperature(_ measurement: Measurement<UnitTemperature>, showUnit: Bool = true) -> String {
        let value = Int(measurement.value)
        if showUnit {
            return "\(value)°"
        } else {
            return "\(value)"
        }
    }

    /// Format temperature range (e.g., "72° / 58°")
    static func formatTemperatureRange(high: Measurement<UnitTemperature>, low: Measurement<UnitTemperature>) -> String {
        let highStr = formatTemperature(high, showUnit: true)
        let lowStr = formatTemperature(low, showUnit: false)
        return "\(highStr) / \(lowStr)°"
    }
}
