//
//  UITestRootView.swift
//  Vecka
//
//  Minimal UI for stable UI tests (no animations or timers).
//

import SwiftUI

struct UITestRootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("UI Test Mode")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Animations and timers disabled.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ui-test-root")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    UITestRootView()
}
