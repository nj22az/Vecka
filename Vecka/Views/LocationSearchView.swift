//
//  LocationSearchView.swift
//  Vecka
//
//  User interface for searching and adding new weather locations
//

import SwiftUI
import SwiftData
import MapKit

struct LocationSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var showManualEntry = false
    @State private var errorMessage: String?

    // Manual entry fields
    @State private var manualName = ""
    @State private var manualLatitude = ""
    @State private var manualLongitude = ""

    var body: some View {
        NavigationStack {
            List {
                if !showManualEntry {
                    // City Search Section
                    Section {
                        if isSearching {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, Spacing.small)
                                Text(NSLocalizedString("location.searching", value: "Searching...", comment: "Searching indicator"))
                                    .foregroundStyle(.secondary)
                            }
                        } else if searchResults.isEmpty && !searchText.isEmpty {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                Text(NSLocalizedString("location.no_locations_found", value: "No locations found", comment: "No locations found message"))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(searchResults) { result in
                                Button {
                                    saveLocation(result)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.name)
                                            .font(.body)
                                            .foregroundStyle(.primary)

                                        Text("\(result.latitude, specifier: "%.4f"), \(result.longitude, specifier: "%.4f")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, Spacing.extraSmall)
                                }
                            }
                        }
                    } header: {
                        Text(NSLocalizedString("location.search_results", value: "Search Results", comment: "Search results header"))
                    }

                    // Quick Locations
                    Section {
                        ForEach(quickLocations) { location in
                            Button {
                                saveLocation(location)
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text(location.name)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    } header: {
                        Text(NSLocalizedString("location.quick_add", value: "Quick Add", comment: "Quick add header"))
                    }

                    // Manual Entry Toggle
                    Section {
                        Button {
                            showManualEntry = true
                        } label: {
                            Label("Enter Coordinates Manually", systemImage: "location.circle")
                        }
                    }
                } else {
                    // Manual Coordinate Entry
                    Section {
                        TextField("Location Name", text: $manualName)

                        TextField("Latitude", text: $manualLatitude)
                            .keyboardType(.decimalPad)

                        TextField("Longitude", text: $manualLongitude)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text(NSLocalizedString("location.manual_entry", value: "Manual Entry", comment: "Manual entry header"))
                    } footer: {
                        Text(NSLocalizedString("location.manual_entry_hint", value: "Enter coordinates in decimal degrees (e.g., 59.3293, 18.0686)", comment: "Manual entry hint"))
                    }

                    Section {
                        Button {
                            saveManualLocation()
                        } label: {
                            Label("Save Location", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .disabled(!isValidManualEntry)

                        Button(role: .cancel) {
                            showManualEntry = false
                            clearManualEntry()
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                        }
                    }
                }

                // Error Display
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search for a city")
            .onChange(of: searchText) { _, newValue in
                performSearch(query: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Search Logic

    private func performSearch(query: String) {
        guard !query.isEmpty, query.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true
        errorMessage = nil

        Task {
            do {
                let results = try await searchLocations(query: query)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                    errorMessage = "Search failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func searchLocations(query: String) async throws -> [SearchResult] {
        // iOS 26: Use MKLocalSearch with new location/address APIs
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.resultTypes = .address

        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()

        return response.mapItems.compactMap { item -> SearchResult? in
            // iOS 26: location is now non-optional
            let location = item.location
            let fullName = item.name ?? "Unknown Location"

            return SearchResult(
                name: fullName,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    // MARK: - Save Logic

    private func saveLocation(_ result: SearchResult) {
        let location = SavedLocation(
            name: result.name,
            latitude: result.latitude,
            longitude: result.longitude
        )

        modelContext.insert(location)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save location: \(error.localizedDescription)"
            Log.w("Failed to save location: \(error)")
        }
    }

    private func saveManualLocation() {
        guard let lat = Double(manualLatitude),
              let lon = Double(manualLongitude),
              !manualName.isEmpty else {
            errorMessage = "Invalid coordinates"
            return
        }

        // Validate latitude using database rules
        let (isValidLat, latError) = ConfigurationManager.shared.validate(
            field: "latitude",
            value: lat,
            context: modelContext
        )
        guard isValidLat else {
            errorMessage = latError ?? "Invalid latitude"
            return
        }

        // Validate longitude using database rules
        let (isValidLon, lonError) = ConfigurationManager.shared.validate(
            field: "longitude",
            value: lon,
            context: modelContext
        )
        guard isValidLon else {
            errorMessage = lonError ?? "Invalid longitude"
            return
        }

        let location = SavedLocation(
            name: manualName,
            latitude: lat,
            longitude: lon
        )

        modelContext.insert(location)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save location: \(error.localizedDescription)"
            Log.w("Failed to save location: \(error)")
        }
    }

    // MARK: - Helper Methods

    private var isValidManualEntry: Bool {
        guard !manualName.isEmpty,
              let lat = Double(manualLatitude),
              let lon = Double(manualLongitude) else {
            return false
        }

        // Validate using database rules
        let (isValidLat, _) = ConfigurationManager.shared.validate(
            field: "latitude",
            value: lat,
            context: modelContext
        )
        let (isValidLon, _) = ConfigurationManager.shared.validate(
            field: "longitude",
            value: lon,
            context: modelContext
        )

        return isValidLat && isValidLon
    }

    private func clearManualEntry() {
        manualName = ""
        manualLatitude = ""
        manualLongitude = ""
    }

    // MARK: - Quick Locations

    private var quickLocations: [SearchResult] {
        [
            SearchResult(name: "Stockholm, Sweden", latitude: 59.3293, longitude: 18.0686),
            SearchResult(name: "Gothenburg, Sweden", latitude: 57.7089, longitude: 11.9746),
            SearchResult(name: "Malmö, Sweden", latitude: 55.6050, longitude: 13.0038),
            SearchResult(name: "London, UK", latitude: 51.5074, longitude: -0.1278),
            SearchResult(name: "New York, USA", latitude: 40.7128, longitude: -74.0060),
            SearchResult(name: "Tokyo, Japan", latitude: 35.6762, longitude: 139.6503)
        ]
    }
}

// MARK: - Search Result Model

struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Preview

#Preview {
    LocationSearchView()
        .modelContainer(for: [SavedLocation.self], inMemory: true)
}
