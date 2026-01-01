//
//  WorkspaceView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) Widget Workspace
//  Responsive, auto-flowing grid with full canvas usage
//

import SwiftUI
import SwiftData

// MARK: - Notification Names

extension Notification.Name {
    /// Posted by sidebar when user taps add widget button
    static let addWidgetRequested = Notification.Name("addWidgetRequested")
    /// Posted by sidebar when user taps repack button
    static let repackWidgetsRequested = Notification.Name("repackWidgetsRequested")
}

// MARK: - Workspace View

/// Main workspace container with responsive auto-flowing grid
struct WorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkspaceWidget.zIndex) private var widgets: [WorkspaceWidget]

    // Edit mode state - per-widget jiggle (only the touched widget jiggles)
    @State private var jigglingWidgetID: UUID?  // Only this widget is jiggling/editable
    @State private var showWidgetCatalog = false

    // Drag tracking
    @State private var draggingWidgetID: UUID?
    @State private var dragOffset: CGSize = .zero

    // Real-time reflow preview positions during drag
    @State private var previewPositions: [UUID: CGPoint] = [:]
    @State private var dropTargetPosition: (x: Int, y: Int)?

    var body: some View {
        GeometryReader { geometry in
            let grid = ResponsiveGrid(
                availableWidth: geometry.size.width,
                availableHeight: geometry.size.height
            )

            VStack(spacing: 0) {
                // 情報デザイン Header - Matches other pages
                toolsHeader

                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Tap background to exit jiggle mode
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if jigglingWidgetID != nil {
                                    withAnimation(.spring(response: 0.3)) {
                                        jigglingWidgetID = nil
                                    }
                                }
                            }
                            .accessibilityLabel("Dismiss edit mode")
                            .accessibilityAddTraits(.isButton)

                        // Drop target indicator
                        if let target = dropTargetPosition, let dragID = draggingWidgetID,
                           let dragWidget = widgets.first(where: { $0.id == dragID }) {
                            let targetFrame = grid.frame(
                                x: target.x,
                                y: target.y,
                                widgetColumns: dragWidget.columns,
                                widgetRows: dragWidget.rows
                            )
                            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                                .stroke(JohoColors.cyan.opacity(0.6), lineWidth: 2)
                                .background(
                                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                                        .fill(JohoColors.cyan.opacity(0.1))
                                )
                                .frame(width: targetFrame.width, height: targetFrame.height)
                                .position(
                                    x: targetFrame.origin.x + targetFrame.width / 2,
                                    y: targetFrame.origin.y + targetFrame.height / 2
                                )
                        }

                        // Widget cards
                        ForEach(widgets) { widget in
                            ResponsiveWidgetCard(
                                widget: widget,
                                grid: grid,
                                isJiggling: jigglingWidgetID == widget.id,
                                draggingWidgetID: $draggingWidgetID,
                                previewOffset: previewPositions[widget.id] ?? .zero,
                                onDragMove: { point in
                                    updateReflowPreview(draggedWidget: widget, at: point, grid: grid)
                                },
                                onDragEnd: { point in
                                    handleDragEnd(widget: widget, at: point, grid: grid)
                                    clearReflowPreview()
                                },
                                onResize: { size in
                                    resizeWidget(widget, to: size, grid: grid)
                                },
                                onDelete: {
                                    deleteWidget(widget)
                                },
                                onLongPress: {
                                    withAnimation(.spring(response: 0.3)) {
                                        jigglingWidgetID = widget.id
                                    }
                                }
                            ) {
                                widgetContent(for: widget)
                            }
                        }
                    }
                    .frame(
                        minWidth: geometry.size.width,
                        minHeight: calculateMinHeight(grid: grid, containerHeight: geometry.size.height)
                    )
                }
            }
            .johoBackground()
            // Listen for add widget notification from sidebar
            .onReceive(NotificationCenter.default.publisher(for: .addWidgetRequested)) { _ in
                showWidgetCatalog = true
            }
            // Listen for repack notification from sidebar
            .onReceive(NotificationCenter.default.publisher(for: .repackWidgetsRequested)) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    autoPackWidgets(grid: grid)
                }
            }
            .sheet(isPresented: $showWidgetCatalog) {
                WidgetCatalogSheet(
                    onAddWidget: { type, config in addWidget(type, config: config, grid: grid) },
                    existingWidgetTypes: Set(widgets.map { $0.type })
                )
            }
            .onAppear {
                seedDefaultWidgetsIfNeeded()
            }
        }
    }

    // MARK: - 情報デザイン Header

    private var toolsHeader: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Icon - Wrench
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(JohoColors.cyan)
                .frame(width: 52, height: 52)
                .background(JohoColors.cyan.opacity(0.15))
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("TOOLS")
                    .font(JohoFont.displaySmall)
                    .foregroundStyle(JohoColors.black)

                Text("\(widgets.count) widgets")
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
            }

            Spacer()
        }
        .padding(JohoDimensions.spacingLG)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.top, JohoDimensions.spacingSM)
        .padding(.bottom, JohoDimensions.spacingSM)
    }

    // MARK: - Widget Content Router

    @ViewBuilder
    private func widgetContent(for widget: WorkspaceWidget) -> some View {
        switch widget.type {
        // Date & Time Widgets
        case .todayHero:
            TodayHeroWidgetContent()
        case .weekBadge:
            WeekBadgeWidgetContent()
        case .monthCalendar:
            MonthCalendarWidgetContent()
        case .weekStrip:
            WeekStripWidgetContent()
        case .yearProgress:
            YearProgressWidgetContent()
        case .monthProgress:
            MonthProgressWidgetContent()
        case .quarterView:
            QuarterViewWidgetContent()
        case .clockWidget:
            ClockWidgetContent()

        // Live Data Tools (情報デザイン)
        case .liveSeconds:
            LiveSecondsWidgetContent()
        case .worldClock:
            WorldClockWidgetContent(config: widget.worldClockConfig)
        case .systemStatus:
            SystemStatusWidgetContent()

        // Event Widgets
        case .nextHoliday:
            NextHolidayWidgetContent()
        case .holidaysList:
            HolidaysListWidgetContent()
        case .countdownHero:
            CountdownHeroWidgetContent()
        case .countdownList:
            CountdownListWidgetContent()

        // Notes Widgets
        case .notesPreview:
            NotesPreviewWidgetContent()
        case .pinnedNote:
            PinnedNoteWidgetContent()

        // Finance Widgets
        case .expenseTotal:
            ExpenseTotalWidgetContent()
        case .recentExpenses:
            RecentExpensesWidgetContent()
        case .activeTripWidget:
            ActiveTripWidgetContent()
        }
    }

    // MARK: - Actions

    private func seedDefaultWidgetsIfNeeded() {
        if widgets.isEmpty {
            WorkspaceWidget.createDefaultWidgets(context: modelContext)
        }
    }

    private func addWidget(_ type: WidgetType, config: WorldClockConfig? = nil, grid: ResponsiveGrid) {
        let position = findAvailablePosition(for: type.defaultSize, grid: grid)

        let widget = WorkspaceWidget(
            type: type,
            gridX: position.x,
            gridY: position.y,
            size: type.defaultSize,
            zIndex: (widgets.map { $0.zIndex }.max() ?? 0) + 1
        )

        // Set configuration for world clock
        if let config = config, type == .worldClock {
            widget.setConfiguration(config)
        }

        modelContext.insert(widget)
        try? modelContext.save()

        // Auto-pack after adding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            autoPackWidgets(grid: grid)
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func deleteWidget(_ widget: WorkspaceWidget) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            modelContext.delete(widget)
            try? modelContext.save()
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    private func resizeWidget(_ widget: WorkspaceWidget, to size: WidgetSize, grid: ResponsiveGrid) {
        let maxCols = grid.columns

        // Check if widget fits at current position with new size
        var targetX = widget.gridX
        let targetY = widget.gridY

        // If new size doesn't fit at current X, try to shift left
        if targetX + size.columns > maxCols {
            targetX = max(0, maxCols - size.columns)
        }

        // Update widget size and position
        widget.columns = size.columns
        widget.rows = size.rows
        widget.gridX = targetX
        widget.gridY = targetY
        widget.modifiedAt = Date()

        try? modelContext.save()

        // Smart repack: keep resized widget in place, push others down/aside (iOS-like)
        smartRepackAfterResize(resizedWidget: widget, grid: grid)

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Smart repack that keeps the resized widget in place and moves others around it
    private func smartRepackAfterResize(resizedWidget: WorkspaceWidget, grid: ResponsiveGrid) {
        // Track occupied cells - start by marking the resized widget's position
        var occupiedGrid: [[Bool]] = Array(
            repeating: Array(repeating: false, count: grid.columns),
            count: 100
        )

        // First, mark the resized widget's position as occupied (it stays in place)
        for row in resizedWidget.gridY..<(resizedWidget.gridY + resizedWidget.rows) {
            for col in resizedWidget.gridX..<(resizedWidget.gridX + resizedWidget.columns) {
                if row < occupiedGrid.count && col < grid.columns {
                    occupiedGrid[row][col] = true
                }
            }
        }

        // Sort other widgets by position
        let otherWidgets = widgets
            .filter { $0.id != resizedWidget.id }
            .sorted { w1, w2 in
                if w1.gridY != w2.gridY { return w1.gridY < w2.gridY }
                return w1.gridX < w2.gridX
            }

        // Repack other widgets around the resized one
        for widget in otherWidgets {
            // Try to keep widget in its current position if possible
            if canPlace(at: widget.gridX, y: widget.gridY, columns: widget.columns, rows: widget.rows, in: occupiedGrid, maxColumns: grid.columns) {
                // Can stay in place, just mark as occupied
                for row in widget.gridY..<(widget.gridY + widget.rows) {
                    for col in widget.gridX..<(widget.gridX + widget.columns) {
                        if row < occupiedGrid.count && col < grid.columns {
                            occupiedGrid[row][col] = true
                        }
                    }
                }
            } else {
                // Need to find new position
                let (newX, newY) = findFirstFit(
                    columns: widget.columns,
                    rows: widget.rows,
                    in: &occupiedGrid,
                    maxColumns: grid.columns
                )

                widget.gridX = newX
                widget.gridY = newY
                widget.modifiedAt = Date()

                // Mark new position as occupied
                for row in newY..<(newY + widget.rows) {
                    for col in newX..<(newX + widget.columns) {
                        if row < occupiedGrid.count && col < grid.columns {
                            occupiedGrid[row][col] = true
                        }
                    }
                }
            }
        }

        try? modelContext.save()
    }

    private func handleDragEnd(widget: WorkspaceWidget, at point: CGPoint, grid: ResponsiveGrid) {
        let gridPos = grid.snapToGrid(point: point)

        // Validate position
        let maxX = grid.columns - widget.columns
        let validX = max(0, min(gridPos.x, maxX))
        let validY = max(0, gridPos.y)

        // Move widget to new position
        widget.updatePosition(x: validX, y: validY)
        widget.bringToFront(maxZ: widgets.map { $0.zIndex }.max() ?? 0)

        // Auto-pack all widgets to resolve collisions
        autoPackWidgets(grid: grid)

        try? modelContext.save()
    }

    // MARK: - Real-Time Reflow Preview

    /// Calculate preview positions for all widgets during drag
    private func updateReflowPreview(draggedWidget: WorkspaceWidget, at point: CGPoint, grid: ResponsiveGrid) {
        let gridPos = grid.snapToGrid(point: point)

        // Validate target position
        let maxX = grid.columns - draggedWidget.columns
        let targetX = max(0, min(gridPos.x, maxX))
        let targetY = max(0, gridPos.y)

        // Update drop target indicator
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            dropTargetPosition = (x: targetX, y: targetY)
        }

        // Calculate where other widgets would move if we dropped here
        var newPositions: [UUID: CGPoint] = [:]

        // Create a virtual grid with the dragged widget at its new position
        var occupiedGrid: [[Bool]] = Array(
            repeating: Array(repeating: false, count: grid.columns),
            count: 100
        )

        // First, mark the dragged widget's target position as occupied
        for row in targetY..<(targetY + draggedWidget.rows) {
            for col in targetX..<(targetX + draggedWidget.columns) {
                if row < occupiedGrid.count && col < grid.columns {
                    occupiedGrid[row][col] = true
                }
            }
        }

        // Sort other widgets and find their new positions
        let otherWidgets = widgets
            .filter { $0.id != draggedWidget.id }
            .sorted { w1, w2 in
                if w1.gridY != w2.gridY { return w1.gridY < w2.gridY }
                return w1.gridX < w2.gridX
            }

        for widget in otherWidgets {
            let (newX, newY) = findFirstFit(
                columns: widget.columns,
                rows: widget.rows,
                in: &occupiedGrid,
                maxColumns: grid.columns
            )

            // Mark this widget's new position as occupied
            for row in newY..<(newY + widget.rows) {
                for col in newX..<(newX + widget.columns) {
                    if row < occupiedGrid.count && col < grid.columns {
                        occupiedGrid[row][col] = true
                    }
                }
            }

            // Calculate offset from current position to preview position
            let currentFrame = grid.frame(x: widget.gridX, y: widget.gridY, widgetColumns: widget.columns, widgetRows: widget.rows)
            let newFrame = grid.frame(x: newX, y: newY, widgetColumns: widget.columns, widgetRows: widget.rows)

            let offsetX = newFrame.origin.x - currentFrame.origin.x
            let offsetY = newFrame.origin.y - currentFrame.origin.y

            if abs(offsetX) > 1 || abs(offsetY) > 1 {
                newPositions[widget.id] = CGPoint(x: offsetX, y: offsetY)
            }
        }

        // Animate to preview positions
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            previewPositions = newPositions
        }
    }

    /// Clear all preview states
    private func clearReflowPreview() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            previewPositions = [:]
            dropTargetPosition = nil
        }
    }

    // MARK: - Auto-Pack Algorithm (Squishy Grid)

    /// Packs widgets top-left, resolving collisions by pushing down
    private func autoPackWidgets(grid: ResponsiveGrid) {
        // Sort by position (top-to-bottom, left-to-right)
        let sortedWidgets = widgets.sorted { w1, w2 in
            if w1.gridY != w2.gridY { return w1.gridY < w2.gridY }
            return w1.gridX < w2.gridX
        }

        // Track occupied cells
        var occupiedGrid: [[Bool]] = Array(
            repeating: Array(repeating: false, count: grid.columns),
            count: 100 // Max rows
        )

        for widget in sortedWidgets {
            // Find first available position that fits this widget
            let (newX, newY) = findFirstFit(
                columns: widget.columns,
                rows: widget.rows,
                in: &occupiedGrid,
                maxColumns: grid.columns
            )

            // Update widget position
            if newX != widget.gridX || newY != widget.gridY {
                widget.gridX = newX
                widget.gridY = newY
                widget.modifiedAt = Date()
            }

            // Mark cells as occupied
            for row in newY..<(newY + widget.rows) {
                for col in newX..<(newX + widget.columns) {
                    if row < occupiedGrid.count && col < grid.columns {
                        occupiedGrid[row][col] = true
                    }
                }
            }
        }

        try? modelContext.save()

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Find first position where widget fits (top-left packing)
    private func findFirstFit(
        columns: Int,
        rows: Int,
        in occupiedGrid: inout [[Bool]],
        maxColumns: Int
    ) -> (x: Int, y: Int) {
        for y in 0..<occupiedGrid.count {
            for x in 0...(maxColumns - columns) {
                if canPlace(at: x, y: y, columns: columns, rows: rows, in: occupiedGrid, maxColumns: maxColumns) {
                    return (x, y)
                }
            }
        }
        return (0, occupiedGrid.count) // Fallback: place at bottom
    }

    private func canPlace(
        at x: Int,
        y: Int,
        columns: Int,
        rows: Int,
        in occupiedGrid: [[Bool]],
        maxColumns: Int
    ) -> Bool {
        // Check bounds
        if x + columns > maxColumns { return false }
        if y + rows > occupiedGrid.count { return false }

        // Check all cells are free
        for row in y..<(y + rows) {
            for col in x..<(x + columns) {
                if occupiedGrid[row][col] { return false }
            }
        }
        return true
    }

    private func findAvailablePosition(for size: WidgetSize, grid: ResponsiveGrid) -> (x: Int, y: Int) {
        var occupiedGrid: [[Bool]] = Array(
            repeating: Array(repeating: false, count: grid.columns),
            count: 100
        )

        // Mark existing widgets
        for widget in widgets {
            for row in widget.gridY..<(widget.gridY + widget.rows) {
                for col in widget.gridX..<(widget.gridX + widget.columns) {
                    if row < occupiedGrid.count && col < grid.columns {
                        occupiedGrid[row][col] = true
                    }
                }
            }
        }

        return findFirstFit(
            columns: size.columns,
            rows: size.rows,
            in: &occupiedGrid,
            maxColumns: grid.columns
        )
    }

    private func calculateMinHeight(grid: ResponsiveGrid, containerHeight: CGFloat) -> CGFloat {
        let maxBottom = widgets.map { $0.gridY + $0.rows }.max() ?? 4
        let calculatedHeight = grid.minHeight(for: maxBottom) + 100 // Extra padding
        return max(calculatedHeight, containerHeight)
    }
}

// MARK: - Responsive Widget Card

/// Widget card that adapts to responsive grid - only the touched widget jiggles
struct ResponsiveWidgetCard<Content: View>: View {
    let widget: WorkspaceWidget
    let grid: ResponsiveGrid
    let isJiggling: Bool  // Whether THIS widget is jiggling (not a binding - computed per widget)
    @Binding var draggingWidgetID: UUID?
    var previewOffset: CGPoint = .zero  // Offset for reflow preview animation
    let onDragMove: (CGPoint) -> Void   // Real-time position updates during drag
    let onDragEnd: (CGPoint) -> Void
    let onResize: (WidgetSize) -> Void
    let onDelete: () -> Void
    let onLongPress: () -> Void
    @ViewBuilder let content: Content

    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 4
    @State private var jiggleRotation: Double = 0
    @State private var showDeleteConfirm = false

    // Resize drag state
    @State private var isResizing = false
    @State private var previewSize: WidgetSize?
    @State private var resizeDragOffset: CGSize = .zero

    private var cardFrame: CGRect {
        grid.frame(x: widget.gridX, y: widget.gridY, widgetColumns: widget.columns, widgetRows: widget.rows)
    }

    /// Whether this widget should have a transparent background
    private var isTransparentWidget: Bool {
        false  // No transparent widgets currently
    }

    /// Whether this widget has interactive content that needs tap passthrough
    private var isInteractiveWidget: Bool {
        false  // All widgets use standard interaction
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main card content with gesture overlay
            content
                .frame(width: cardFrame.width, height: cardFrame.height)
                .background(isTransparentWidget ? Color.clear : JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(
                            isDragging ? JohoColors.cyan : (isTransparentWidget ? Color.clear : JohoColors.black),
                            lineWidth: isDragging ? JohoDimensions.borderThick + 1 : JohoDimensions.borderThick
                        )
                )
                .shadow(
                    color: isTransparentWidget ? Color.clear : JohoColors.black.opacity(isDragging ? 0.3 : 0.1),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowRadius / 2
                )
                .overlay {
                    // Gesture capture overlay - handles different gestures based on jiggle state
                    if isJiggling {
                        // In jiggle mode: always allow drag
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(immediateDragGesture)
                    } else if !isInteractiveWidget {
                        // Not jiggling, non-interactive widget: long press to enter jiggle mode
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(longPressToJiggle)
                    } else {
                        // Interactive widget when not jiggling: transparent overlay with simultaneous long press
                        // This allows button taps while still detecting long press for edit mode
                        Color.clear
                            .contentShape(Rectangle())
                            .allowsHitTesting(false)  // Let taps pass through to buttons
                    }
                }
                // For interactive widgets, use simultaneous gesture so buttons work AND long press detected
                .gesture(isInteractiveWidget && !isJiggling ? longPressToJiggle : nil)

            // Jiggle mode controls (delete and resize)
            if isJiggling {
                // Delete button (iOS-style, top-left corner)
                Button(action: { showDeleteConfirm = true }) {
                    ZStack {
                        Circle()
                            .fill(JohoColors.black)
                            .frame(width: 24, height: 24)

                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(JohoColors.white)
                    }
                }
                .offset(x: -8, y: -8)
                .zIndex(10)

                // Resize handle (bottom-right corner) - draggable for Apple Pencil/touch
                ZStack {
                    Circle()
                        .fill(isResizing ? JohoColors.cyan.opacity(0.8) : JohoColors.cyan)
                        .frame(width: 28, height: 28)
                        .shadow(color: JohoColors.black.opacity(0.2), radius: isResizing ? 4 : 2)

                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(JohoColors.white)
                }
                .scaleEffect(isResizing ? 1.2 : 1.0)
                .offset(x: cardFrame.width - 14 + resizeDragOffset.width,
                        y: cardFrame.height - 14 + resizeDragOffset.height)
                .gesture(cornerResizeGesture)
                .zIndex(10)
                .animation(.spring(response: 0.2), value: isResizing)
            }
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(isJiggling && !isDragging ? jiggleRotation : 0))
        .offset(dragOffset)
        .offset(x: isDragging ? 0 : previewOffset.x, y: isDragging ? 0 : previewOffset.y)  // Preview reflow offset
        .position(
            x: cardFrame.origin.x + cardFrame.width / 2,
            y: cardFrame.origin.y + cardFrame.height / 2
        )
        .zIndex(isDragging ? 1000 : Double(widget.zIndex))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: scale)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: shadowRadius)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: previewOffset)
        .onChange(of: isDragging) { _, newValue in
            withAnimation {
                scale = newValue ? 1.05 : 1.0
                shadowRadius = newValue ? 16 : 4
            }
            if newValue {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
        .onChange(of: isJiggling) { _, newValue in
            if newValue {
                startJiggling()
            } else {
                jiggleRotation = 0
            }
        }
        .onAppear {
            if isJiggling {
                startJiggling()
            }
        }
        .confirmationDialog("Remove Widget", isPresented: $showDeleteConfirm) {
            Button("Remove", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove this \(widget.type.displayName) widget from your workspace?")
        }
    }

    private func startJiggling() {
        // Randomize starting direction for natural iOS-like feel
        let startAngle = Double.random(in: -2.5...2.5)  // ±2.5 degrees like iOS
        jiggleRotation = startAngle

        // Continuous jiggle animation - slightly slower for smoother feel
        withAnimation(
            Animation
                .easeInOut(duration: 0.12)  // 0.12s matches iOS home screen
                .repeatForever(autoreverses: true)
        ) {
            jiggleRotation = -startAngle
        }
    }

    // MARK: - Gesture Handling

    /// Long press gesture to enter jiggle mode for THIS widget only
    private var longPressToJiggle: some Gesture {
        LongPressGesture(minimumDuration: 0.5)  // iOS standard: 0.5 second hold
            .onEnded { _ in
                if !isJiggling {
                    let generator = UIImpactFeedbackGenerator(style: .light)  // Light haptic like iOS
                    generator.impactOccurred()
                    onLongPress()
                }
            }
    }

    /// Immediate drag gesture (used when already in jiggle mode)
    private var immediateDragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { drag in
                if !isDragging {
                    isDragging = true
                    draggingWidgetID = widget.id
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
                dragOffset = drag.translation

                // Calculate current drag position for real-time reflow preview
                let currentPoint = CGPoint(
                    x: cardFrame.origin.x + cardFrame.width / 2 + drag.translation.width,
                    y: cardFrame.origin.y + cardFrame.height / 2 + drag.translation.height
                )
                onDragMove(currentPoint)
            }
            .onEnded { _ in
                if isDragging {
                    let finalPoint = CGPoint(
                        x: cardFrame.origin.x + cardFrame.width / 2 + dragOffset.width,
                        y: cardFrame.origin.y + cardFrame.height / 2 + dragOffset.height
                    )
                    onDragEnd(finalPoint)

                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                isDragging = false
                dragOffset = .zero
                draggingWidgetID = nil
            }
    }

    /// Corner drag gesture for resizing widget
    private var cornerResizeGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if !isResizing {
                    isResizing = true
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                resizeDragOffset = drag.translation

                // Calculate and preview nearest supported size
                let newSize = calculateNearestSize(
                    deltaWidth: drag.translation.width,
                    deltaHeight: drag.translation.height
                )
                if newSize != previewSize {
                    previewSize = newSize
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                }
            }
            .onEnded { _ in
                if let newSize = previewSize, newSize != widget.size {
                    onResize(newSize)
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
                isResizing = false
                previewSize = nil
                resizeDragOffset = .zero
            }
    }

    /// Calculate nearest supported size based on drag delta
    private func calculateNearestSize(deltaWidth: CGFloat, deltaHeight: CGFloat) -> WidgetSize {
        let supportedSizes = widget.type.supportedSizes
        let unit = grid.baseUnit + grid.gutter

        // Determine target dimensions based on drag
        let colDelta = Int(round(deltaWidth / unit))
        let rowDelta = Int(round(deltaHeight / unit))

        let targetCols = max(1, widget.columns + colDelta)
        let targetRows = max(1, widget.rows + rowDelta)

        // Find closest supported size
        return supportedSizes.min(by: { size1, size2 in
            let diff1 = abs(size1.columns - targetCols) + abs(size1.rows - targetRows)
            let diff2 = abs(size2.columns - targetCols) + abs(size2.rows - targetRows)
            return diff1 < diff2
        }) ?? widget.size
    }

    /// Combined gesture: in jiggle mode, allow immediate drag; otherwise, long press to enter jiggle mode
    @ViewBuilder
    private var activeGestureContent: some View {
        if isJiggling {
            // In jiggle mode: immediate drag
            Color.clear
                .contentShape(Rectangle())
                .gesture(immediateDragGesture)
        } else {
            // Not jiggling: long press to enter jiggle mode
            Color.clear
                .contentShape(Rectangle())
                .gesture(longPressToJiggle)
        }
    }
}

// MARK: - Responsive Grid Overlay

/// Visual grid that adapts to available space
struct ResponsiveGridOverlay: View {
    let grid: ResponsiveGrid
    let maxRows: Int = 8

    var body: some View {
        VStack(spacing: grid.gutter) {
            ForEach(0..<maxRows, id: \.self) { _ in
                HStack(spacing: grid.gutter) {
                    ForEach(0..<grid.columns, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                            .strokeBorder(JohoColors.white.opacity(0.3), lineWidth: 1)
                            .frame(width: grid.baseUnit, height: grid.baseUnit)
                    }
                }
            }
        }
        .padding(grid.padding)
    }
}

// MARK: - Widget Catalog Sheet

/// Sheet for adding new widgets
struct WidgetCatalogSheet: View {
    let onAddWidget: (WidgetType, WorldClockConfig?) -> Void
    let existingWidgetTypes: Set<WidgetType>

    @Environment(\.dismiss) private var dismiss
    @State private var showCityPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: JohoDimensions.spacingMD)], spacing: JohoDimensions.spacingMD) {
                    ForEach(WidgetType.allCases) { type in
                        WidgetCatalogItem(
                            type: type,
                            isAdded: existingWidgetTypes.contains(type),
                            onAdd: {
                                if type == .worldClock {
                                    // Show city picker for world clocks
                                    showCityPicker = true
                                } else {
                                    onAddWidget(type, nil)
                                    dismiss()
                                }
                            }
                        )
                    }
                }
                .padding(JohoDimensions.spacingLG)
            }
            .johoBackground()
            .navigationTitle("Add Tool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCityPicker) {
                JohoCityPickerSheet { config in
                    onAddWidget(.worldClock, config)
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - City Picker Sheet (情報デザイン)

/// 情報デザイン city picker for world clock configuration
struct JohoCityPickerSheet: View {
    let onSelect: (WorldClockConfig) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var customName = ""
    @State private var selectedPreset: WorldClockConfig?

    private let presets = WorldClockConfig.presets

    var body: some View {
        VStack(spacing: 0) {
            // Header (情報デザイン)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Category badge
                    Text("TIMEZONE")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(JohoColors.cyan)

                    Text("SELECT CITY")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundStyle(JohoColors.black)
                }

                Spacer()

                // Close button - 情報デザイン squircle
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 36, height: 36)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: 8))
                        .overlay(
                            Squircle(cornerRadius: 8)
                                .stroke(JohoColors.black, lineWidth: 3)
                        )
                }
            }
            .padding(JohoDimensions.spacingLG)
            .background(JohoColors.white)

            // Column header - 情報デザイン table header
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 32, alignment: .center)
                Text("CITY")
                    .frame(width: 100, alignment: .leading)
                Text("UTC")
                    .frame(width: 50, alignment: .center)
                Text("ZONE_ID")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .foregroundStyle(JohoColors.white)
            .padding(.vertical, 8)
            .padding(.horizontal, JohoDimensions.spacingMD)
            .background(JohoColors.black)

            // City list (情報デザイン table)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(presets.enumerated()), id: \.element.timeZoneID) { index, preset in
                        Button {
                            HapticManager.selection()
                            selectedPreset = preset
                            customName = preset.displayName
                        } label: {
                            JohoCityRow(
                                index: index,
                                config: preset,
                                isSelected: selectedPreset?.timeZoneID == preset.timeZoneID
                            )
                        }
                        .buttonStyle(.plain)

                        if index < presets.count - 1 {
                            Rectangle().fill(JohoColors.black.opacity(0.1)).frame(height: 1)
                        }
                    }
                }
            }

            // Thick separator
            Rectangle().fill(JohoColors.black).frame(height: 3)

            // Custom name field (情報デザイン)
            VStack(alignment: .leading, spacing: 8) {
                Text("DISPLAY_NAME")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(JohoColors.black.opacity(0.5))

                TextField("STORA MELLÖSA", text: $customName)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(JohoColors.black)
                    .textInputAutocapitalization(.characters)
                    .padding(12)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: 8))
                    .overlay(
                        Squircle(cornerRadius: 8)
                            .stroke(JohoColors.black, lineWidth: 2)
                    )
            }
            .padding(JohoDimensions.spacingLG)
            .background(JohoColors.white)

            // Confirm button (情報デザイン)
            Button {
                if let preset = selectedPreset {
                    let config = WorldClockConfig(
                        timeZoneID: preset.timeZoneID,
                        displayName: customName.isEmpty ? preset.displayName : customName.uppercased()
                    )
                    onSelect(config)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("CONFIRM")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                }
                .foregroundStyle(JohoColors.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selectedPreset != nil ? JohoColors.black : JohoColors.black.opacity(0.3))
                .clipShape(Squircle(cornerRadius: 8))
            }
            .disabled(selectedPreset == nil)
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingLG)
        }
        .background(JohoColors.white)
        .presentationCornerRadius(0)
        .presentationDetents([.large])
    }
}

/// City row for picker (情報デザイン)
private struct JohoCityRow: View {
    let index: Int
    let config: WorldClockConfig
    let isSelected: Bool

    private var utcOffset: String {
        let tz = TimeZone(identifier: config.timeZoneID) ?? TimeZone.current
        let seconds = tz.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs((seconds % 3600) / 60)
        let sign = hours >= 0 ? "+" : ""
        if minutes > 0 {
            return String(format: "%@%d:%02d", sign, hours, minutes)
        }
        return "\(sign)\(hours)"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Index badge (情報デザイン)
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(isSelected ? JohoColors.white : JohoColors.black)
                .frame(width: 24, height: 24)
                .background(isSelected ? JohoColors.cyan : JohoColors.black.opacity(0.1))
                .clipShape(Squircle(cornerRadius: 6))
                .overlay(
                    Squircle(cornerRadius: 6)
                        .stroke(isSelected ? JohoColors.cyan : JohoColors.black.opacity(0.2), lineWidth: 1)
                )
                .frame(width: 32)

            // City name
            Text(config.displayName)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(JohoColors.black)
                .frame(width: 100, alignment: .leading)

            // UTC offset
            Text(utcOffset)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(JohoColors.cyan)
                .frame(width: 50, alignment: .center)

            // Timezone ID
            Text(config.timeZoneID.replacingOccurrences(of: "_", with: " "))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(JohoColors.black.opacity(0.6))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(JohoColors.cyan)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, JohoDimensions.spacingMD)
        .background(isSelected ? JohoColors.cyan.opacity(0.08) : JohoColors.white)
    }
}

// MARK: - Widget Catalog Item

/// Individual widget type in the catalog
struct WidgetCatalogItem: View {
    let type: WidgetType
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: JohoDimensions.spacingSM) {
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 64, height: 64)
                    .background(type.zone.background)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )

                // Name
                Text(type.displayName)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)

                // Size indicator
                Text(type.defaultSize.displayName)
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.6))

                // Added indicator
                if isAdded {
                    JohoPill(text: "Added", style: .whiteOnBlack, size: .small)
                }
            }
            .padding(JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
            )
            .opacity(isAdded ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isAdded)
    }
}

// MARK: - Preview

#Preview("Workspace View") {
    WorkspaceView()
        .modelContainer(for: WorkspaceWidget.self, inMemory: true)
}
