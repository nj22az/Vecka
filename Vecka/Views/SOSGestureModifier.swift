//
//  SOSGestureModifier.swift
//  Vecka
//
//  情報デザイン: Hidden gesture recognizer for developer access
//  Recognizes SOS morse code: ...---... (tap tap tap, hold hold hold, tap tap tap)
//

import SwiftUI

/// SOS Morse Code Gesture Recognizer
/// Pattern: . . . - - - . . . (3 short, 3 long, 3 short)
/// Short tap: < 0.3 seconds
/// Long press: >= 0.3 seconds
struct SOSGestureModifier: ViewModifier {
    let onSOSDetected: () -> Void

    @State private var touchStart: Date?
    @State private var pattern: [Bool] = []  // true = long, false = short
    @State private var lastEventTime: Date = Date()

    /// Threshold for short vs long tap (seconds)
    private let longPressThreshold: TimeInterval = 0.3
    /// Maximum time between events before pattern resets (seconds)
    private let patternTimeout: TimeInterval = 2.0
    /// Expected SOS pattern: short short short long long long short short short
    private let sosPattern: [Bool] = [false, false, false, true, true, true, false, false, false]

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if touchStart == nil {
                            touchStart = Date()
                        }
                    }
                    .onEnded { _ in
                        handleTouchEnd()
                    }
            )
    }

    private func handleTouchEnd() {
        guard let start = touchStart else { return }
        let duration = Date().timeIntervalSince(start)
        touchStart = nil

        // Check if pattern should reset due to timeout
        if Date().timeIntervalSince(lastEventTime) > patternTimeout && !pattern.isEmpty {
            pattern.removeAll()
        }

        lastEventTime = Date()

        // Determine if this was a short or long press
        let isLongPress = duration >= longPressThreshold
        pattern.append(isLongPress)

        // Provide haptic feedback
        if isLongPress {
            HapticManager.impact(.heavy)
        } else {
            HapticManager.impact(.light)
        }

        // Check for complete SOS pattern
        if pattern.count >= 9 {
            // Check the last 9 elements
            let recentPattern = Array(pattern.suffix(9))
            if recentPattern == sosPattern {
                // SOS detected!
                HapticManager.notification(.success)
                onSOSDetected()
                pattern.removeAll()
            } else if pattern.count > 12 {
                // Too many events without match, keep only recent
                pattern = Array(pattern.suffix(9))
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds SOS morse code gesture recognition to a view
    /// Triggers callback when ...---... pattern is detected
    func onSOSGesture(perform action: @escaping () -> Void) -> some View {
        modifier(SOSGestureModifier(onSOSDetected: action))
    }
}
