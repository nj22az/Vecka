//
//  WeatherLocalization.swift
//  Vecka
//
//  Localized weather strings with English fallback
//  Supports: EN, SV, JA, KO, VI, TH, DE, ZH-HANS, ZH-HANT
//

import Foundation
import WeatherKit

@available(iOS 16.0, *)
enum WeatherLocalization {

    // MARK: - Weather Condition Names

    static func conditionName(_ condition: WeatherCondition) -> String {
        let key = "weather.condition.\(conditionKey(condition))"
        let localized = NSLocalizedString(key, comment: "Weather condition")

        // If localization fails, return English
        return localized != key ? localized : englishConditionName(condition)
    }

    private static func conditionKey(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "clear"
        case .mostlyClear: return "mostly_clear"
        case .partlyCloudy: return "partly_cloudy"
        case .mostlyCloudy: return "mostly_cloudy"
        case .cloudy: return "cloudy"
        case .drizzle: return "drizzle"
        case .rain: return "rain"
        case .heavyRain: return "heavy_rain"
        case .snow: return "snow"
        case .heavySnow: return "heavy_snow"
        case .flurries: return "flurries"
        case .blizzard: return "blizzard"
        case .sleet: return "sleet"
        case .freezingRain: return "freezing_rain"
        case .freezingDrizzle: return "freezing_drizzle"
        case .wintryMix: return "wintry_mix"
        case .blowingSnow: return "blowing_snow"
        case .isolatedThunderstorms: return "isolated_thunderstorms"
        case .scatteredThunderstorms: return "scattered_thunderstorms"
        case .thunderstorms: return "thunderstorms"
        case .strongStorms: return "strong_storms"
        case .tropicalStorm: return "tropical_storm"
        case .hurricane: return "hurricane"
        case .foggy: return "foggy"
        case .haze: return "haze"
        case .smoky: return "smoky"
        case .windy: return "windy"
        case .breezy: return "breezy"
        case .hot: return "hot"
        case .frigid: return "frigid"
        case .hail: return "hail"
        case .sunFlurries: return "sun_flurries"
        case .sunShowers: return "sun_showers"
        case .blowingDust: return "blowing_dust"
        @unknown default: return "unknown"
        }
    }

    private static func englishConditionName(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "Clear"
        case .mostlyClear: return "Mostly Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .mostlyCloudy: return "Mostly Cloudy"
        case .cloudy: return "Cloudy"
        case .drizzle: return "Drizzle"
        case .rain: return "Rain"
        case .heavyRain: return "Heavy Rain"
        case .snow: return "Snow"
        case .heavySnow: return "Heavy Snow"
        case .flurries: return "Flurries"
        case .blizzard: return "Blizzard"
        case .sleet: return "Sleet"
        case .freezingRain: return "Freezing Rain"
        case .freezingDrizzle: return "Freezing Drizzle"
        case .wintryMix: return "Wintry Mix"
        case .blowingSnow: return "Blowing Snow"
        case .isolatedThunderstorms: return "Isolated Thunderstorms"
        case .scatteredThunderstorms: return "Scattered Thunderstorms"
        case .thunderstorms: return "Thunderstorms"
        case .strongStorms: return "Strong Storms"
        case .tropicalStorm: return "Tropical Storm"
        case .hurricane: return "Hurricane"
        case .foggy: return "Foggy"
        case .haze: return "Haze"
        case .smoky: return "Smoky"
        case .windy: return "Windy"
        case .breezy: return "Breezy"
        case .hot: return "Hot"
        case .frigid: return "Frigid"
        case .hail: return "Hail"
        case .sunFlurries: return "Sun Flurries"
        case .sunShowers: return "Sun Showers"
        case .blowingDust: return "Blowing Dust"
        @unknown default: return "Conditions Vary"
        }
    }

    // MARK: - UI Labels

    static var high: String {
        NSLocalizedString("weather.high", value: "High", comment: "High temperature label")
    }

    static var low: String {
        NSLocalizedString("weather.low", value: "Low", comment: "Low temperature label")
    }

    static var precipitation: String {
        NSLocalizedString("weather.precipitation", value: "Precipitation", comment: "Precipitation label")
    }

    static var uvIndex: String {
        NSLocalizedString("weather.uv_index", value: "UV Index", comment: "UV index label")
    }

    static var wind: String {
        NSLocalizedString("weather.wind", value: "Wind", comment: "Wind label")
    }

    // MARK: - Error Messages

    static var noLocation: String {
        NSLocalizedString("weather.error.no_location", value: "Location not available", comment: "No location error")
    }

    static var permissionDenied: String {
        NSLocalizedString("weather.error.permission_denied", value: "Location permission required", comment: "Permission denied error")
    }

    static var fetchFailed: String {
        NSLocalizedString("weather.error.fetch_failed", value: "Unable to fetch weather", comment: "Fetch failed error")
    }

    static var tapToRetry: String {
        NSLocalizedString("weather.tap_to_retry", value: "Tap to retry", comment: "Retry prompt")
    }

    static var loading: String {
        NSLocalizedString("weather.loading", value: "Loading weather...", comment: "Loading state")
    }

    // MARK: - Permission Prompts

    static var enableLocation: String {
        NSLocalizedString("weather.enable_location", value: "Enable Location", comment: "Enable location button")
    }

    static var locationRequired: String {
        NSLocalizedString("weather.location_required", value: "Weather requires location access to show forecasts for your area.", comment: "Location required explanation")
    }

    static var openSettings: String {
        NSLocalizedString("weather.open_settings", value: "Open Settings", comment: "Open settings button")
    }
}
