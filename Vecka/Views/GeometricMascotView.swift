//
//  GeometricMascotView.swift
//  Vecka
//
//  情報デザイン: Geometric mascot - week number + 7 day squares
//  Pure shapes: squircles, squares, bold black borders
//

import SwiftUI

/// Geometric mascot following 情報デザイン principles
/// - Week number in a squircle
/// - 7 squares representing days of the week
/// - Today highlighted in yellow
struct GeometricMascotView: View {
    /// The week number to display (defaults to current week)
    var weekNumber: Int?

    /// Which day is "today" (1-7, Monday=1, Sunday=7). Nil = no highlight
    var todayIndex: Int?

    /// Size of the entire mascot
    var size: CGFloat = 120

    /// Whether to show the border around the entire mascot
    var showOuterBorder: Bool = true

    // Computed current values
    private var displayWeekNumber: Int {
        weekNumber ?? Calendar.iso8601.component(.weekOfYear, from: Date())
    }

    private var displayTodayIndex: Int? {
        if let todayIndex = todayIndex {
            return todayIndex
        }
        // Get current weekday (1=Sunday in Gregorian, convert to ISO where 1=Monday)
        let weekday = Calendar.iso8601.component(.weekday, from: Date())
        // ISO weekday: 1=Mon, 7=Sun. Calendar.iso8601.component returns same
        return weekday
    }

    // Layout calculations
    private var weekNumberSize: CGFloat { size * 0.45 }
    private var daySquareSize: CGFloat { size * 0.1 }
    private var daySquareSpacing: CGFloat { size * 0.02 }
    private var borderWidth: CGFloat { max(2, size * 0.025) }
    private var innerBorderWidth: CGFloat { max(1.5, size * 0.018) }

    var body: some View {
        VStack(spacing: size * 0.08) {
            // Week number in squircle
            weekNumberBadge

            // 7 day squares
            daySquaresRow
        }
        .padding(size * 0.12)
        .frame(width: size, height: size)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: size * 0.15))
        .overlay(
            Group {
                if showOuterBorder {
                    Squircle(cornerRadius: size * 0.15)
                        .stroke(JohoColors.black, lineWidth: borderWidth)
                }
            }
        )
    }

    // MARK: - Week Number Badge

    private var weekNumberBadge: some View {
        Text("\(displayWeekNumber)")
            .font(.system(size: weekNumberSize * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(JohoColors.black)
            .frame(width: weekNumberSize, height: weekNumberSize)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: weekNumberSize * 0.25))
            .overlay(
                Squircle(cornerRadius: weekNumberSize * 0.25)
                    .stroke(JohoColors.black, lineWidth: innerBorderWidth)
            )
    }

    // MARK: - Day Squares Row

    private var daySquaresRow: some View {
        HStack(spacing: daySquareSpacing) {
            ForEach(1...7, id: \.self) { dayIndex in
                daySquare(for: dayIndex)
            }
        }
    }

    private func daySquare(for dayIndex: Int) -> some View {
        let isToday = dayIndex == displayTodayIndex

        return Rectangle()
            .fill(isToday ? JohoColors.yellow : JohoColors.white)
            .frame(width: daySquareSize, height: daySquareSize)
            .overlay(
                Rectangle()
                    .stroke(JohoColors.black, lineWidth: max(1, innerBorderWidth * 0.7))
            )
    }
}

// MARK: - Static Export Version (for asset generation)

/// A fixed-size version for exporting as PNG asset
struct GeometricMascotExportView: View {
    let size: CGFloat
    let weekNumber: Int
    let todayIndex: Int

    var body: some View {
        GeometricMascotView(
            weekNumber: weekNumber,
            todayIndex: todayIndex,
            size: size,
            showOuterBorder: true
        )
    }
}

// MARK: - Previews

#Preview("Geometric Mascot - Current Week") {
    VStack(spacing: 20) {
        GeometricMascotView()

        Text("Current week, current day highlighted")
            .font(JohoFont.caption)
            .foregroundStyle(JohoColors.black.opacity(0.6))
    }
    .padding()
    .background(JohoColors.background)
}

#Preview("Geometric Mascot - Sizes") {
    HStack(spacing: 20) {
        VStack {
            GeometricMascotView(weekNumber: 52, todayIndex: 4, size: 60)
            Text("60pt")
                .font(JohoFont.labelSmall)
        }

        VStack {
            GeometricMascotView(weekNumber: 52, todayIndex: 4, size: 120)
            Text("120pt")
                .font(JohoFont.labelSmall)
        }

        VStack {
            GeometricMascotView(weekNumber: 52, todayIndex: 4, size: 200)
            Text("200pt")
                .font(JohoFont.labelSmall)
        }
    }
    .padding()
    .background(JohoColors.background)
}

#Preview("Geometric Mascot - Week 1") {
    GeometricMascotView(weekNumber: 1, todayIndex: 1, size: 200)
        .padding()
        .background(JohoColors.background)
}

#Preview("Geometric Mascot - For Export (1024px)") {
    GeometricMascotExportView(size: 1024, weekNumber: 52, todayIndex: 4)
}
