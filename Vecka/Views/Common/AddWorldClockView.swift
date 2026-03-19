//
//  AddWorldClockView.swift
//  Vecka
//

import SwiftUI

struct AddWorldClockView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    let onAdd: (String, String) -> Void

    @State private var searchText = ""

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// Intelligent search results using WorldCityDatabase
    private var searchResults: [WorldCity] {
        if searchText.isEmpty {
            // Default: STM first, then popular cities by region
            let defaultCities = [
                "Stora Mellösa",  // STM - Developer's hometown (default)
                "Stockholm", "Tokyo", "New York", "London", "Paris",
                "Sydney", "Singapore", "Berlin", "Dubai", "Los Angeles"
            ]
            return defaultCities.compactMap { name in
                WorldCityDatabase.cities.first { $0.name == name }
            }
        }
        // Intelligent search
        return WorldCityDatabase.search(searchText)
    }

    /// Region color for city
    private func regionColor(for region: WorldRegion) -> Color {
        switch region {
        case .europe: return JohoColors.regionEurope
        case .asia: return JohoColors.regionAsia
        case .northAmerica: return JohoColors.regionAmerica
        case .southAmerica: return JohoColors.regionPacific
        case .africa: return JohoColors.regionAfrica
        case .oceania: return JohoColors.regionAustralia
        case .middleEast: return JohoColors.moonViolet
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Header
                    JohoPageHeader(
                        title: "Add World Clock",
                        badge: "CITY"
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                    // Search bar
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: IconCatalog.search)
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))

                        TextField("Type city or country...", text: $searchText)
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primary)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: IconCatalog.xmarkCircleFill)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityMedium))
                            }
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .johoBordered()
                    .padding(.horizontal, JohoDimensions.spacingLG)

                    // Search hint
                    if searchText.isEmpty {
                        Text("Type any city name to search 300+ locations worldwide")
                            .font(JohoFont.caption)
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, JohoDimensions.spacingLG)
                    }

                    // City list
                    VStack(spacing: 0) {
                        if searchResults.isEmpty {
                            // No results
                            VStack(spacing: JohoDimensions.spacingMD) {
                                Image(systemName: IconCatalog.globe)
                                    .font(.system(size: 32, weight: .light, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityMedium))
                                Text("No cities found")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                                Text("Try a different spelling")
                                    .font(JohoFont.caption)
                                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))
                            }
                            .padding(JohoDimensions.spacingXL)
                        } else {
                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, city in
                                Button {
                                    HapticManager.impact(.light)
                                    onAdd(city.name, city.timezone)
                                    dismiss()
                                } label: {
                                    HStack(spacing: JohoDimensions.spacingMD) {
                                        // City code pill
                                        Text(city.code)
                                            .font(JohoFont.headerTag)
                                            .foregroundStyle(regionColor(for: city.worldRegion).contrastingForeground)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(regionColor(for: city.worldRegion))
                                            .clipShape(Capsule())
                                            .frame(width: 52)

                                        // City info
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(city.name)
                                                .font(JohoFont.headline)
                                                .foregroundStyle(colors.primary)

                                            Text(city.country)
                                                .font(JohoFont.caption)
                                                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                                        }

                                        Spacer()

                                        // Current time preview
                                        Text(currentTime(for: city.timezone))
                                            .font(JohoFont.bodySmallBold)
                                            .foregroundStyle(colors.secondary)

                                        Image(systemName: IconCatalog.plusCircle)
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                            .foregroundStyle(regionColor(for: city.worldRegion))
                                    }
                                    .padding(JohoDimensions.spacingMD)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if index < searchResults.count - 1 {
                                    Rectangle()
                                        .fill(colors.border.opacity(JohoDimensions.opacitySubtle))
                                        .frame(height: 1)
                                        .padding(.horizontal, JohoDimensions.spacingMD)
                                }
                            }
                        }
                    }
                    .background(colors.surface)
                    .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick)
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }
                .padding(.bottom, JohoDimensions.spacingXL)
            }
            .johoBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("×")
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.red)
                    }
                }
            }
        }
    }

    private func currentTime(for timezoneId: String) -> String {
        guard let tz = TimeZone(identifier: timezoneId) else { return "--:--" }
        let formatter = DateFormatterCache.time24h
        formatter.timeZone = tz
        return formatter.string(from: Date())
    }
}
