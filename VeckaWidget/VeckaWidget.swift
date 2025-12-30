//
//  VeckaWidget.swift
//  VeckaWidget
//
//  iOS 26 Liquid Glass widget implementation
//  Supports all widget sizes: small, medium, large, extra large
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
        case .systemExtraLarge:
            VeckaExtraLargeWidgetView(entry: entry)
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
        .description("View the current ISO week number, upcoming events, and monthly calendar.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}
