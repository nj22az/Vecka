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
        case .europe: return Color(hex: "4A90D9")
        case .asia: return Color(hex: "E17055")
        case .northAmerica: return Color(hex: "00B894")
        case .southAmerica: return Color(hex: "00CEC9")
        case .africa: return Color(hex: "FDCB6E")
        case .oceania: return Color(hex: "D35400")
        case .middleEast: return Color(hex: "6C5CE7")
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
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(JohoColors.black.opacity(0.4))

                        TextField("Type city or country...", text: $searchText)
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primary)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(JohoColors.black.opacity(0.3))
                            }
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)

                    // Search hint
                    if searchText.isEmpty {
                        Text("Type any city name to search 300+ locations worldwide")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, JohoDimensions.spacingLG)
                    }

                    // City list
                    VStack(spacing: 0) {
                        if searchResults.isEmpty {
                            // No results
                            VStack(spacing: JohoDimensions.spacingMD) {
                                Image(systemName: "globe")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundStyle(JohoColors.black.opacity(0.3))
                                Text("No cities found")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(JohoColors.black.opacity(0.5))
                                Text("Try a different spelling")
                                    .font(JohoFont.caption)
                                    .foregroundStyle(JohoColors.black.opacity(0.4))
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
                                            .font(.system(size: 11, weight: .black, design: .rounded))
                                            .foregroundStyle(JohoColors.white)
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
                                                .foregroundStyle(JohoColors.black.opacity(0.6))
                                        }

                                        Spacer()

                                        // Current time preview
                                        Text(currentTime(for: city.timezone))
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(colors.secondary)

                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(regionColor(for: city.worldRegion))
                                    }
                                    .padding(JohoDimensions.spacingMD)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if index < searchResults.count - 1 {
                                    Rectangle()
                                        .fill(JohoColors.black.opacity(0.1))
                                        .frame(height: 1)
                                        .padding(.horizontal, JohoDimensions.spacingMD)
                                }
                            }
                        }
                    }
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
                    )
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
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(JohoColors.red)
                    }
                }
            }
        }
    }

    private func currentTime(for timezoneId: String) -> String {
        guard let tz = TimeZone(identifier: timezoneId) else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}
