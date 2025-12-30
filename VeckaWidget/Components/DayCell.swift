//
//  DayCell.swift
//  VeckaWidget
//
//  Created by Nils Johansson on 2025-09-11.
//

import SwiftUI
import WidgetKit
import EventKit

// MARK: - Day Cell Component
struct DayCell: View {
    let day: Int
    let date: Date
    let isToday: Bool
    let events: [EKEvent]
    let accentColor: Color
    let renderingMode: WidgetRenderingMode
    
    private var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(verbatim: "\(day)")
                .font(.footnote.weight(isToday ? .bold : .regular))
                .foregroundStyle(textColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .widgetAccentable()
                )
                .overlay(
                    Circle()
                        .strokeBorder(borderColor, lineWidth: isToday ? 2 : 0)
                        .widgetAccentable()
                )
            
            // Event indicators
            if !events.isEmpty {
                HStack(spacing: 2) {
                    ForEach(0..<min(events.count, 3), id: \.self) { _ in
                        Circle()
                            .fill(Theme.tertiaryLabel(for: renderingMode))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
    }
    
    private var textColor: Color {
        if isToday {
            return renderingMode == .vibrant ? .black : .white
        } else if isWeekend {
            return Theme.secondaryLabel(for: renderingMode)
        } else {
            return Theme.primaryLabel(for: renderingMode)
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return accentColor
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        isToday ? accentColor.opacity(0.3) : Color.clear
    }
}
