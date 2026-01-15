//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Small Widget
//  Hokusai Great Wave motif - authentic Japanese aesthetic
//

import SwiftUI
import WidgetKit

struct VeckaSmallWidgetView: View {
    let entry: VeckaWidgetEntry

    // MARK: - Computed Properties

    private var weekNumber: Int { entry.weekNumber }
    private var dayOfMonth: Int { Calendar.current.component(.day, from: entry.date) }

    private var weekdayShort: String {
        entry.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var year: String { String(entry.year) }

    private var borders: JohoWidget.Borders.Weights { JohoWidget.Borders.small }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background: Hokusai wave in bottom-left corner
            VStack {
                Spacer()
                HStack {
                    Image("HokusaiWave")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 110, height: 73)
                        .opacity(0.9)
                    Spacer()
                }
            }

            // Content: Information in upper-right area
            VStack(alignment: .trailing, spacing: 2) {
                // Week number - hero
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("W")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.5))
                    Text("\(weekNumber)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                }

                // Date row
                HStack(spacing: 4) {
                    Text(weekdayShort)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black.opacity(0.6))

                    // Today indicator
                    ZStack {
                        Circle()
                            .fill(Color(red: 1, green: 0.9, blue: 0.4))
                            .frame(width: 28, height: 28)
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                        Text("\(dayOfMonth)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                    }
                }

                // Month + Year
                Text("\(monthShort) \(year)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.black.opacity(0.5))

                Spacer()
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}
