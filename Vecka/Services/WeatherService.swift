//
//  WeatherService.swift
//  Vecka
//
//  Weather service using Apple's WeatherKit framework
//  Requires iOS 16.0+ and WeatherKit capability
//

import Foundation
import WeatherKit
import CoreLocation
import SwiftUI

/// Weather Service using Apple's WeatherKit
@MainActor
@Observable
class WeatherService: NSObject {

    // MARK: - Singleton
    static let shared = WeatherService()

    // MARK: - Properties
    private let weatherService = WeatherKit.WeatherService()
    private let locationManager = CLLocationManager()

    var currentLocation: CLLocation?
    var isAuthorized: Bool = false
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var selectedLocation: SavedLocation?

    // Cache for weather data (1 hour expiry)
    private var weatherCache: [String: CachedWeather] = [:]

    // MARK: - Initialization
    override private init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Public API

    /// Check if WeatherKit is available
    static var isAvailable: Bool {
        if #available(iOS 16.0, *) {
            return true
        }
        return false
    }

    /// Request location permission
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Get current weather for current location
    @available(iOS 16.0, *)
    func getCurrentWeather() async throws -> Weather? {
        guard let location = currentLocation else {
            throw WeatherError.noLocation
        }

        do {
            let weather = try await weatherService.weather(for: location)
            return weather
        } catch {
            throw WeatherError.apiError(error)
        }
    }

    /// Get weather forecast for specific date
    @available(iOS 16.0, *)
    func getForecast(for date: Date) async throws -> DayWeather? {
        // Use selected location if available, otherwise use current GPS location
        let location: CLLocation
        if let selectedLocation = selectedLocation {
            location = selectedLocation.location
            Log.i("Using saved location: \(selectedLocation.name)")
        } else if let currentLocation = currentLocation {
            location = currentLocation
            Log.i("Using GPS location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
        } else {
            Log.w("No location available for weather")
            throw WeatherError.noLocation
        }

        // Check cache first
        let cacheKey = makeCacheKey(location: location, date: date)
        if let cached = weatherCache[cacheKey], !cached.isExpired {
            Log.i("Weather cache hit for \(date)")
            return cached.dayWeather
        }

        do {
            Log.i("Fetching weather from WeatherKit for \(date)...")
            let forecast = try await weatherService.weather(
                for: location,
                including: .daily
            )

            Log.i("WeatherKit returned \(forecast.count) days of forecast")

            // Find matching day
            let dayWeather = forecast.first { dayForecast in
                Calendar.iso8601.isDate(dayForecast.date, inSameDayAs: date)
            }

            // Cache result
            if let dayWeather = dayWeather {
                weatherCache[cacheKey] = CachedWeather(dayWeather: dayWeather)
                Log.i("Cached weather for \(date): \(dayWeather.condition.description)")
            } else {
                Log.w("No matching weather found for \(date)")
            }

            return dayWeather
        } catch let error as NSError {
            Log.w("WeatherKit API error: \(error.domain) code \(error.code) - \(error.localizedDescription)")

            // Check for specific WeatherKit errors
            if error.domain == "WeatherDaemonError" {
                if error.code == 1 {
                    Log.w("⚠️ WEATHERKIT NOT ENTITLED - Add WeatherKit to your App ID in developer.apple.com")
                } else if error.code == 2 {
                    Log.w("⚠️ WEATHERKIT API LIMIT REACHED - 500k calls/month limit")
                }
            }

            throw WeatherError.apiError(error)
        }
    }

    /// Get hourly forecast for date range
    @available(iOS 16.0, *)
    func getHourlyForecast(from start: Date, to end: Date) async throws -> [HourWeather] {
        // Use selected location if available, otherwise use current GPS location
        let location: CLLocation
        if let selectedLocation = selectedLocation {
            location = selectedLocation.location
        } else if let currentLocation = currentLocation {
            location = currentLocation
        } else {
            throw WeatherError.noLocation
        }

        do {
            let forecast = try await weatherService.weather(
                for: location,
                including: .hourly
            )

            return forecast.forecast.filter { hourWeather in
                hourWeather.date >= start && hourWeather.date <= end
            }
        } catch {
            throw WeatherError.apiError(error)
        }
    }

    /// Get weather for specific location
    @available(iOS 16.0, *)
    func getWeather(for location: CLLocation, date: Date) async throws -> DayWeather? {
        let cacheKey = makeCacheKey(location: location, date: date)
        if let cached = weatherCache[cacheKey], !cached.isExpired {
            return cached.dayWeather
        }

        do {
            let forecast = try await weatherService.weather(
                for: location,
                including: .daily
            )

            let dayWeather = forecast.first { dayForecast in
                Calendar.iso8601.isDate(dayForecast.date, inSameDayAs: date)
            }

            if let dayWeather = dayWeather {
                weatherCache[cacheKey] = CachedWeather(dayWeather: dayWeather)
            }

            return dayWeather
        } catch {
            throw WeatherError.apiError(error)
        }
    }

    /// Get weather with graceful fallback
    @available(iOS 16.0, *)
    func getWeatherWithFallback(for date: Date) async -> DayWeather? {
        do {
            return try await getForecast(for: date)
        } catch WeatherError.noLocation {
            Log.w("No location available for weather")
            return nil
        } catch WeatherError.notAuthorized {
            Log.w("Weather not authorized")
            return nil
        } catch {
            Log.w("Weather fetch failed: \(error)")
            return nil
        }
    }

    // MARK: - Location Management

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func updateLocation() {
        locationManager.requestLocation()
    }

    // MARK: - Cache Management

    private func makeCacheKey(location: CLLocation, date: Date) -> String {
        let dateString = date.ISO8601Format(.iso8601Date(timeZone: .current))
        return "\(location.coordinate.latitude),\(location.coordinate.longitude)-\(dateString)"
    }

    func clearCache() {
        weatherCache.removeAll()
    }

    // MARK: - Location Helpers

    /// Get the currently active location (selected or current GPS)
    var activeLocation: CLLocation? {
        if let selectedLocation = selectedLocation {
            return selectedLocation.location
        }
        return currentLocation
    }

    /// Get the name of the currently active location
    var activeLocationName: String {
        if let selectedLocation = selectedLocation {
            return selectedLocation.name
        } else if currentLocation != nil {
            return "Current Location"
        } else {
            return "No Location"
        }
    }
}

// MARK: - Location Manager Delegate

extension WeatherService: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                isAuthorized = true
                locationManager.requestLocation()
            case .denied, .restricted:
                isAuthorized = false
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            currentLocation = locations.first
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.w("Location error: \(error.localizedDescription)")
    }
}

// MARK: - Supporting Types

enum WeatherError: LocalizedError {
    case noLocation
    case notAuthorized
    case apiError(Error)

    var errorDescription: String? {
        switch self {
        case .noLocation:
            return "Location not available. Please enable location services."
        case .notAuthorized:
            return "Location permission not granted. Please enable in Settings."
        case .apiError(let error):
            return "Weather service error: \(error.localizedDescription)"
        }
    }
}

struct CachedWeather {
    let dayWeather: DayWeather
    let timestamp: Date = Date()

    var isExpired: Bool {
        // Cache expires after 1 hour
        Date().timeIntervalSince(timestamp) > 3600
    }
}

// MARK: - Weather Data Extensions

@available(iOS 16.0, *)
extension DayWeather {
    /// Get SF Symbol name for weather condition
    var symbolName: String {
        switch condition {
        case .clear, .mostlyClear:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .cloudy, .mostlyCloudy:
            return "cloud.fill"
        case .rain, .drizzle:
            return "cloud.rain.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorms:
            return "cloud.bolt.rain.fill"
        case .foggy, .haze:
            return "cloud.fog.fill"
        case .windy:
            return "wind"
        default:
            return "cloud.fill"
        }
    }

    /// Get color for weather condition
    var conditionColor: Color {
        switch condition {
        case .clear, .mostlyClear:
            return .orange
        case .partlyCloudy, .cloudy, .mostlyCloudy:
            return .gray
        case .rain, .drizzle, .heavyRain:
            return .blue
        case .snow:
            return .cyan
        case .thunderstorms:
            return .purple
        case .foggy, .haze:
            return .secondary
        default:
            return .primary
        }
    }
}

@available(iOS 16.0, *)
extension Weather {
    /// Export to WeatherExportInfo for PDF generation
    var exportInfo: WeatherExportInfo {
        WeatherExportInfo(
            condition: currentWeather.condition.description,
            symbolName: currentWeather.symbolName,
            highTemperature: currentWeather.temperature.formatted(),
            lowTemperature: currentWeather.temperature.formatted(),
            precipitationChance: nil,
            humidity: "\(Int(currentWeather.humidity * 100))%",
            windSpeed: currentWeather.wind.speed.formatted()
        )
    }
}

@available(iOS 16.0, *)
extension CurrentWeather {
    var symbolName: String {
        switch condition {
        case .clear, .mostlyClear:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .cloudy, .mostlyCloudy:
            return "cloud.fill"
        case .rain, .drizzle:
            return "cloud.rain.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorms:
            return "cloud.bolt.rain.fill"
        case .foggy, .haze:
            return "cloud.fog.fill"
        case .windy:
            return "wind"
        default:
            return "cloud.fill"
        }
    }
}
