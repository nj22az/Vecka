//
//  WeatherForecastView.swift
//  Vecka
//
//  Full 10-day weather forecast view for Library
//  Apple Weather-inspired design
//

import SwiftUI
import WeatherKit
import CoreLocation

@available(iOS 16.0, *)
struct WeatherForecastView: View {
    @State private var weatherData: [DayWeather] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showLocationManager = false

    private var weatherService: WeatherService { WeatherService.shared }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location Header
                locationHeader

                // Error or Loading State
                if let error = errorMessage {
                    errorView(message: error)
                } else if isLoading {
                    loadingView
                } else if weatherData.isEmpty {
                    emptyStateView
                } else {
                    // 10-Day Forecast
                    forecastList
                }
            }
            .padding()
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Weather Forecast")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showLocationManager = true
                    } label: {
                        Label("Manage Locations", systemImage: "mappin.and.ellipse")
                    }

                    Button {
                        Task { await fetchWeather() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showLocationManager) {
            LocationManagerView()
        }
        .task {
            await fetchWeather()
        }
    }

    // MARK: - Location Header

    private var locationHeader: some View {
        HStack {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(weatherService.activeLocationName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, Spacing.extraSmall)
    }

    // MARK: - Forecast List

    private var forecastList: some View {
        VStack(spacing: 12) {
            ForEach(Array(weatherData.enumerated()), id: \.offset) { index, weather in
                WeatherForecastRow(
                    weather: weather,
                    isToday: index == 0
                )
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.blue)

            Text("Loading forecast...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            Text("No Weather Data")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Enable location services to see the forecast")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await fetchWeather() }
            } label: {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .padding(.horizontal, Spacing.large)
                    .padding(.vertical, Spacing.small)
                    .background(AppColors.accentBlue, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)

            Text("Unable to Load Weather")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                errorMessage = nil
                Task { await fetchWeather() }
            } label: {
                Text("Retry")
                    .fontWeight(.semibold)
                    .padding(.horizontal, Spacing.large)
                    .padding(.vertical, Spacing.small)
                    .background(AppColors.accentBlue, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }

    // MARK: - Data Fetching

    private func fetchWeather() async {
        guard weatherService.isAuthorized else {
            errorMessage = "Location permission required. Please enable in Settings."
            return
        }

        guard let location = weatherService.activeLocation else {
            errorMessage = "No location available. Please update your location."
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            Log.i("Fetching 10-day forecast for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

            let service = WeatherKit.WeatherService()
            let forecast = try await service.weather(
                for: location,
                including: .daily
            )

            await MainActor.run {
                // Take first 10 days
                weatherData = Array(forecast.prefix(10))
                Log.i("Fetched \(weatherData.count) days of weather forecast")
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                Log.w("Weather fetch failed: \(error)")
            }
        }
    }
}

// MARK: - Forecast Row

@available(iOS 16.0, *)
struct WeatherForecastRow: View {
    let weather: DayWeather
    let isToday: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Day Name
            VStack(alignment: .leading, spacing: 2) {
                Text(isToday ? "Today" : dayName)
                    .font(.body.weight(isToday ? .semibold : .regular))
                    .foregroundStyle(.primary)

                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            // Weather Icon
            Image(systemName: WeatherIconMapper.icon(for: weather.condition))
                .font(.title2)
                .foregroundStyle(WeatherIconMapper.color(for: weather.condition))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 40)

            // Precipitation
            if weather.precipitationChance > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                    Text("\(Int(weather.precipitationChance * 100))%")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.blue)
                .frame(width: 50)
            } else {
                Spacer()
                    .frame(width: 50)
            }

            // Temperature Range
            HStack(spacing: 8) {
                Text(WeatherIconMapper.formatTemperature(weather.lowTemperature))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 35, alignment: .trailing)

                // Temperature Bar
                temperatureBar

                Text(WeatherIconMapper.formatTemperature(weather.highTemperature))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 35, alignment: .leading)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var temperatureBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(.secondary.opacity(0.2))
                    .frame(height: 4)

                // Filled portion (proportional to high temp)
                Capsule()
                    .fill(temperatureGradient)
                    .frame(width: geometry.size.width * temperatureFraction, height: 4)
            }
        }
        .frame(width: 60, height: 4)
    }

    private var temperatureFraction: CGFloat {
        // Simple mapping: assume range of -10 to 40°C
        let minTemp = -10.0
        let maxTemp = 40.0
        let high = weather.highTemperature.value
        return CGFloat((high - minTemp) / (maxTemp - minTemp)).clamped(to: 0...1)
    }

    private var temperatureGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .orange, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var dayName: String {
        weather.date.formatted(.dateTime.weekday(.wide))
    }

    private var dateString: String {
        weather.date.formatted(.dateTime.month(.abbreviated).day())
    }
}

// MARK: - Helper Extension

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Preview

#Preview {
    if #available(iOS 16.0, *) {
        NavigationStack {
            WeatherForecastView()
        }
    } else {
        Text("iOS 16+ required")
    }
}
