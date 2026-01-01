//
//  LocationManagerView.swift
//  Vecka
//
//  User interface for managing saved locations
//

import SwiftUI
import SwiftData
import CoreLocation

struct LocationManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedLocation.dateCreated) private var locations: [SavedLocation]

    @AppStorage("selectedLocationID") private var selectedLocationID: String = ""
    @State private var showAddLocation = false
    @State private var useCurrentLocation = true

    var body: some View {
        NavigationStack {
            List {
                // Current Location Option
                Section {
                    HStack {
                        Label("Current Location", systemImage: "location.fill")
                            .foregroundStyle(.primary)

                        Spacer()

                        if useCurrentLocation {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .font(.body.weight(.semibold))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectCurrentLocation()
                    }
                    .accessibilityLabel("Use current location\(useCurrentLocation ? ", selected" : "")")
                    .accessibilityAddTraits(.isButton)
                } header: {
                    Text("Auto-Detect")
                } footer: {
                    Text("Use your device's current location")
                }

                // Saved Locations
                if !locations.isEmpty {
                    Section {
                        ForEach(locations) { location in
                            LocationRow(
                                location: location,
                                isSelected: !useCurrentLocation && selectedLocationID == location.id.uuidString
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectLocation(location)
                            }
                            .accessibilityLabel("\(location.name)\(!useCurrentLocation && selectedLocationID == location.id.uuidString ? ", selected" : "")")
                            .accessibilityAddTraits(.isButton)
                        }
                        .onDelete(perform: deleteLocations)
                    } header: {
                        Text("Saved Locations")
                    } footer: {
                        Text("\(locations.count) saved location\(locations.count == 1 ? "" : "s")")
                    }
                }

                // Add Location Button
                Section {
                    Button {
                        showAddLocation = true
                    } label: {
                        Label("Add Location", systemImage: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("Manage Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddLocation) {
                LocationSearchView()
            }
        }
    }

    // MARK: - Helper Methods

    private func selectCurrentLocation() {
        useCurrentLocation = true
        selectedLocationID = ""
    }

    private func selectLocation(_ location: SavedLocation) {
        useCurrentLocation = false
        selectedLocationID = location.id.uuidString
    }

    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            let location = locations[index]

            // If deleting selected location, switch to current location
            if selectedLocationID == location.id.uuidString {
                selectCurrentLocation()
            }

            modelContext.delete(location)
        }

        do {
            try modelContext.save()
        } catch {
            Log.w("Failed to delete location: \(error)")
        }
    }
}

// MARK: - Location Row

struct LocationRow: View {
    let location: SavedLocation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Location Icon
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(isSelected ? .blue : .secondary)

            // Location Info
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)

                Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Selection Indicator
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
                    .font(.body.weight(.semibold))
            }
        }
        .padding(.vertical, Spacing.extraSmall)
    }
}

// MARK: - Preview

#Preview {
    LocationManagerView()
        .modelContainer(for: [SavedLocation.self], inMemory: true)
}
