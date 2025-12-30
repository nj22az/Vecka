//
//  BackgroundPattern.swift
//  VeckaWidget
//
//  Created by Nils Johansson on 2025-09-11.
//

import SwiftUI
import WidgetKit

// MARK: - Background Pattern
struct BackgroundPattern: View {
    let weekNumber: Int
    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if renderingMode == .fullColor {
            GeometryReader { geometry in
                ZStack(alignment: .bottomTrailing) {
                    // Large faint week number
                    Text("\(weekNumber)")
                        .font(.system(size: 180, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(colorScheme == .dark ? 0.03 : 0.05))
                        .offset(x: 40, y: 50)
                        .rotationEffect(.degrees(-10))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
    }
}
