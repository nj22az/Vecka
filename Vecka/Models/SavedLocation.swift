//
//  SavedLocation.swift
//  Vecka
//
//  SwiftData model for saved weather locations
//

import Foundation
import SwiftData
import CoreLocation

/// Saved location for weather forecasts
@Model
final class SavedLocation {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var isDefault: Bool
    var dateCreated: Date
    var lastUpdated: Date

    init(
        name: String,
        latitude: Double,
        longitude: Double,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isDefault = isDefault
        self.dateCreated = Date()
        self.lastUpdated = Date()
    }

    // MARK: - Computed Properties

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    // MARK: - Methods

    func updateLocation(_ newLocation: CLLocation) {
        self.latitude = newLocation.coordinate.latitude
        self.longitude = newLocation.coordinate.longitude
        self.lastUpdated = Date()
    }
}

// MARK: - Predefined Locations

extension SavedLocation {
    static var stockholm: SavedLocation {
        SavedLocation(
            name: "Stockholm",
            latitude: 59.3293,
            longitude: 18.0686
        )
    }

    static var gothenburg: SavedLocation {
        SavedLocation(
            name: "Gothenburg",
            latitude: 57.7089,
            longitude: 11.9746
        )
    }

    static var malmo: SavedLocation {
        SavedLocation(
            name: "Malmö",
            latitude: 55.6050,
            longitude: 13.0038
        )
    }
}
