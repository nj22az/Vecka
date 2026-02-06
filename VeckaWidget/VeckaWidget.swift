//
//  VeckaWidget.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Widget
//  Japanese Minimalist: Small (week hero) + Large (month calendar)
//

import WidgetKit
import SwiftUI
import Foundation

// MARK: - Main Widget View
struct VeckaWidgetEntryView: View {
    let entry: VeckaWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            VeckaSmallWidgetView(entry: entry)
        case .systemMedium:
            VeckaMediumWidgetView(entry: entry)
        case .systemLarge:
            VeckaLargeWidgetView(entry: entry)
        default:
            VeckaSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
@main
struct VeckaWidget: Widget {
    let kind: String = "VeckaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VeckaWidgetProvider()) { entry in
            VeckaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Week Number")
        .description("View the current ISO week number and monthly calendar.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
