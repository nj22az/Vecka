//
//  Haptics.swift
//  Vecka
//
//  Purpose: Centralized, tiny utility for triggering system haptics.
//  Usage: Call HapticManager.impact(.light/.medium/.heavy), .selection(), or
//         .notification(.success/.warning/.error) from UI interactions.
//

import SwiftUI
import UIKit

/// Lightweight wrapper around UIKit haptic generators.
/// Keeps all haptic calls consistent and easy to discover.
struct HapticManager {
    /// One-off impact (e.g., on drag start or key actions)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    /// Subtle tick used for discrete selections (pickers, list selection, etc.)
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    /// Prominent haptic for success/warning/error outcomes
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
