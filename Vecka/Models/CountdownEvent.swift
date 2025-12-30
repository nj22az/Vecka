//
//  CountdownEvent.swift
//  Vecka
//
//  Database-driven countdowns.
//  Replaces hardcoded logic in CountdownBanner.
//

import Foundation
import SwiftData

@Model
final class CountdownEvent {
    @Attribute(.unique) var id: String
    
    var title: String
    var targetDate: Date
    var icon: String // SF Symbol
    var colorHex: String // Hex code for color
    var isSystem: Bool // If true, auto-calculated (like "Next Christmas")
    
    init(title: String, targetDate: Date, icon: String = "star.fill", colorHex: String = "#FF0000", isSystem: Bool = false) {
        self.id = UUID().uuidString
        self.title = title
        self.targetDate = targetDate
        self.icon = icon
        self.colorHex = colorHex
        self.isSystem = isSystem
    }
}
