//
//  SwipeNavigationContainer.swift
//  Vecka
//
//  情報デザイン: Native TabView paging with smooth animations
//
//  Uses iOS TabView with .page style for reliable paging:
//  - Native page indicator hidden (dock is the indicator)
//  - Smooth 0.25s easeInOut transitions via animation modifier
//  - Light haptic feedback on page change
//  - Coexists with IconStripDock via shared selection binding
//

import SwiftUI

/// 情報デザイン compliant paging container using TabView
/// Provides smooth swipe navigation between pages with carousel wrap-around
struct SwipeNavigationContainer<Content: View>: View {
    @Binding var selection: SidebarSelection?
    @ViewBuilder let content: (SidebarSelection?) -> Content

    /// Track previous selection for haptic feedback
    @State private var previousSelection: SidebarSelection?

    /// Threshold for triggering carousel wrap-around (points)
    private let wrapThreshold: CGFloat = 60

    // All pages in swipe order (5 pages - Landing IS the data dashboard)
    private let orderedPages: [SidebarSelection] = [
        .landing, .calendar, .contacts, .specialDays, .settings
    ]

    /// First and last pages for carousel detection
    private var isOnFirstPage: Bool { selection == .landing }
    private var isOnLastPage: Bool { selection == .settings }

    var body: some View {
        TabView(selection: Binding(
            get: { selection ?? .landing },
            set: { newValue in
                // 情報デザイン: Light haptic on page change
                if newValue != previousSelection {
                    HapticManager.impact(.light)
                    previousSelection = newValue
                }
                selection = newValue
            }
        )) {
            ForEach(orderedPages) { page in
                content(page)
                    .tag(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        // 情報デザイン: Use spring animation for natural, smooth page transitions
        // Native TabView paging + spring gives best feel
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selection)
        .onAppear {
            previousSelection = selection
        }
        // 情報デザイン: Carousel wrap-around using edge overlays
        .overlay(alignment: .leading) {
            // Left edge detector (for Landing → Settings wrap)
            if isOnFirstPage {
                Color.clear
                    .frame(width: 44)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                if value.translation.width > wrapThreshold {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        selection = .settings
                                    }
                                    HapticManager.impact(.medium)
                                }
                            }
                    )
            }
        }
        .overlay(alignment: .trailing) {
            // Right edge detector (for Settings → Landing wrap)
            if isOnLastPage {
                Color.clear
                    .frame(width: 44)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                if value.translation.width < -wrapThreshold {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        selection = .landing
                                    }
                                    HapticManager.impact(.medium)
                                }
                            }
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("Swipe Navigation") {
    struct PreviewWrapper: View {
        @State private var selection: SidebarSelection? = .calendar

        var body: some View {
            VStack(spacing: 0) {
                SwipeNavigationContainer(selection: $selection) { page in
                    VStack {
                        Text("Page: \(page?.label ?? "None")")
                            .font(JohoFont.headline)
                        Text("Swipe left/right")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(JohoColors.white)
                }

                // Mock dock
                HStack {
                    ForEach(SidebarSelection.allCases) { item in
                        Button {
                            selection = item
                        } label: {
                            Image(systemName: item.icon)
                                .foregroundStyle(selection == item ? item.accentColor : JohoColors.black.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(JohoColors.black)
            }
        }
    }

    return PreviewWrapper()
}
