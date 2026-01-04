//
//  SwipeNavigationContainer.swift
//  Vecka
//
//  情報デザイン: Horizontal swipe navigation between pages
//  Coexists with IconStripDock for dual navigation methods
//

import SwiftUI

/// A container view that adds horizontal swipe gestures for page navigation
/// Works alongside the bottom dock - both methods coexist
struct SwipeNavigationContainer<Content: View>: View {
    @Binding var selection: SidebarSelection?
    @ViewBuilder let content: (SidebarSelection?) -> Content

    // Gesture state
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false

    // Configuration
    private let swipeThreshold: CGFloat = 50  // Minimum distance to trigger page change
    private let edgeResistance: CGFloat = 0.3 // Damping when at first/last page

    // All pages in swipe order
    private let orderedPages: [SidebarSelection] = [
        .landing, .calendar, .tools, .contacts, .specialDays, .settings
    ]

    // MARK: - Computed Properties

    private var currentIndex: Int {
        guard let selection = selection else { return 0 }
        return selection.pageIndex
    }

    private var canSwipeLeft: Bool {
        currentIndex < orderedPages.count - 1
    }

    private var canSwipeRight: Bool {
        currentIndex > 0
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            content(selection)
                .offset(x: dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .updating($isDragging) { _, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            handleDragChange(value: value)
                        }
                        .onEnded { value in
                            handleSwipeEnd(translation: value.translation.width)
                        }
                )
                .animation(
                    isDragging ? .interactiveSpring() : .easeInOut(duration: 0.25),
                    value: dragOffset
                )
        }
    }

    // MARK: - Gesture Handling

    private func handleDragChange(value: DragGesture.Value) {
        // Only respond to horizontal drags (ignore vertical scrolling)
        let horizontal = abs(value.translation.width)
        let vertical = abs(value.translation.height)
        guard horizontal > vertical else { return }

        // Apply edge resistance when at boundaries
        var translation = value.translation.width

        // At last page, resist left swipe
        if !canSwipeLeft && translation < 0 {
            translation *= edgeResistance
        }

        // At first page, resist right swipe
        if !canSwipeRight && translation > 0 {
            translation *= edgeResistance
        }

        dragOffset = translation
    }

    private func handleSwipeEnd(translation: CGFloat) {
        withAnimation(.easeInOut(duration: 0.25)) {
            if translation > swipeThreshold && canSwipeRight {
                // Swiped right -> go to previous page
                navigateToPrevious()
            } else if translation < -swipeThreshold && canSwipeLeft {
                // Swiped left -> go to next page
                navigateToNext()
            }
            // Always reset offset
            dragOffset = 0
        }
    }

    // MARK: - Navigation

    private func navigateToPrevious() {
        guard canSwipeRight else { return }
        HapticManager.selection()
        selection = SidebarSelection.fromIndex(currentIndex - 1)
    }

    private func navigateToNext() {
        guard canSwipeLeft else { return }
        HapticManager.selection()
        selection = SidebarSelection.fromIndex(currentIndex + 1)
    }
}

// MARK: - Preview

#Preview("Swipe Navigation") {
    struct PreviewWrapper: View {
        @State private var selection: SidebarSelection? = .calendar

        var body: some View {
            VStack(spacing: 0) {
                SwipeNavigationContainer(selection: $selection) { _ in
                    VStack {
                        Text("Current Page: \(selection?.label ?? "None")")
                            .font(JohoFont.headline)
                        Text("Swipe left/right to navigate")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(.secondary)
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
                                .foregroundStyle(selection == item ? item.accentColor : .gray)
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
