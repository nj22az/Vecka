//
//  WorkspaceModels.swift
//  Vecka
//
//  SwiftData models for the customizable widget workspace
//  20 情報デザイン widgets with iOS-style jiggle delete mode
//

import SwiftUI
import SwiftData

// MARK: - Widget Type Enum (20 Types)

/// Available widget types for the workspace - 20 unique designs
enum WidgetType: String, Codable, CaseIterable, Identifiable {
    // Date & Time Widgets
    case todayHero          // Large today display with year
    case weekBadge          // Compact week number badge
    case monthCalendar      // Full month calendar grid
    case weekStrip          // Horizontal 7-day strip
    case yearProgress       // Year progress percentage
    case monthProgress      // Month progress percentage
    case quarterView        // Quarter overview
    case clockWidget        // Current time display

    // Live Data Widgets (TimelineView - 情報デザイン)
    case liveSeconds        // T-MINUS seconds countdown (updates every second)
    case worldClock         // World clock with UTC offset badge
    case systemStatus       // SYSTEM_MONITOR // ACTIVE header

    // Event Widgets
    case nextHoliday        // Single next holiday
    case holidaysList       // Multiple holidays list
    case countdownHero      // Large single countdown
    case countdownList      // Multiple countdowns

    // Notes Widgets
    case notesPreview       // Recent notes preview
    case pinnedNote         // Single pinned note

    // Expense Widgets
    case expenseTotal       // Monthly expense total
    case recentExpenses     // Recent expense list

    // Trip Widgets
    case activeTripWidget   // Active trip overview

    var id: String { rawValue }

    /// Display name for the widget type
    var displayName: String {
        switch self {
        case .todayHero: return "Today"
        case .weekBadge: return "Week Badge"
        case .monthCalendar: return "Calendar"
        case .weekStrip: return "Week Strip"
        case .yearProgress: return "Year Progress"
        case .monthProgress: return "Month Progress"
        case .quarterView: return "Quarter"
        case .clockWidget: return "Clock"
        case .liveSeconds: return "T-MINUS"
        case .worldClock: return "World Clock"
        case .systemStatus: return "System"
        case .nextHoliday: return "Next Holiday"
        case .holidaysList: return "Holidays"
        case .countdownHero: return "Countdown"
        case .countdownList: return "Countdowns"
        case .notesPreview: return "Notes"
        case .pinnedNote: return "Pinned Note"
        case .expenseTotal: return "Expenses"
        case .recentExpenses: return "Recent Expenses"
        case .activeTripWidget: return "Trip"
        }
    }

    /// Short description for catalog
    var description: String {
        switch self {
        case .todayHero: return "Date, week, and year"
        case .weekBadge: return "Week number badge"
        case .monthCalendar: return "Full month grid"
        case .weekStrip: return "7-day horizontal view"
        case .yearProgress: return "Year completion %"
        case .monthProgress: return "Month completion %"
        case .quarterView: return "Quarter overview"
        case .clockWidget: return "Current time"
        case .liveSeconds: return "Live seconds countdown"
        case .worldClock: return "Timezone with UTC offset"
        case .systemStatus: return "System monitor header"
        case .nextHoliday: return "Next upcoming holiday"
        case .holidaysList: return "Multiple holidays"
        case .countdownHero: return "Days to event"
        case .countdownList: return "Multiple countdowns"
        case .notesPreview: return "Recent notes"
        case .pinnedNote: return "Important note"
        case .expenseTotal: return "Monthly spending"
        case .recentExpenses: return "Latest expenses"
        case .activeTripWidget: return "Current trip"
        }
    }

    /// SF Symbol icon for the widget type
    var icon: String {
        switch self {
        case .todayHero: return "calendar.day.timeline.left"
        case .weekBadge: return "number.square"
        case .monthCalendar: return "calendar"
        case .weekStrip: return "rectangle.split.3x1"
        case .yearProgress: return "chart.pie"
        case .monthProgress: return "chart.bar"
        case .quarterView: return "square.grid.2x2"
        case .clockWidget: return "clock"
        case .liveSeconds: return "timer"
        case .worldClock: return "globe"
        case .systemStatus: return "cpu"
        case .nextHoliday: return "gift"
        case .holidaysList: return "gift.fill"
        case .countdownHero: return "timer"
        case .countdownList: return "list.number"
        case .notesPreview: return "note.text"
        case .pinnedNote: return "pin.fill"
        case .expenseTotal: return "dollarsign.circle"
        case .recentExpenses: return "list.bullet.rectangle"
        case .activeTripWidget: return "airplane"
        }
    }

    /// Section zone color for the widget type
    var zone: SectionZone {
        switch self {
        case .todayHero, .weekBadge, .monthCalendar, .weekStrip: return .calendar
        case .yearProgress, .monthProgress, .quarterView, .clockWidget: return .calendar
        case .liveSeconds, .worldClock, .systemStatus: return .calendar
        case .nextHoliday, .holidaysList: return .holidays
        case .countdownHero, .countdownList: return .trips
        case .notesPreview, .pinnedNote: return .notes
        case .expenseTotal, .recentExpenses: return .expenses
        case .activeTripWidget: return .trips
        }
    }

    /// Default size for a new widget of this type
    var defaultSize: WidgetSize {
        switch self {
        case .todayHero: return .medium
        case .weekBadge: return .small
        case .monthCalendar: return .large
        case .weekStrip: return .wide
        case .yearProgress: return .small
        case .monthProgress: return .small
        case .quarterView: return .medium
        case .clockWidget: return .medium
        case .liveSeconds: return .small
        case .worldClock: return .medium
        case .systemStatus: return .wide
        case .nextHoliday: return .medium
        case .holidaysList: return .square
        case .countdownHero: return .medium
        case .countdownList: return .square
        case .notesPreview: return .square
        case .pinnedNote: return .medium
        case .expenseTotal: return .small
        case .recentExpenses: return .square
        case .activeTripWidget: return .medium
        }
    }

    /// Supported sizes for this widget type (3 sizes each)
    var supportedSizes: [WidgetSize] {
        switch self {
        // Date & Time Widgets
        case .todayHero:
            return [.small, .medium, .square]       // Compact badge → Standard → Square with more info
        case .weekBadge:
            return [.small, .medium, .square]       // Compact → With day names → Square badge
        case .monthCalendar:
            return [.medium, .wide, .square, .large, .full]  // Week strip → Wide strip → Mini cal → Standard → Full
        case .weekStrip:
            return [.medium, .wide, .large]         // Compact strip → Full strip → With details
        case .yearProgress:
            return [.medium, .square, .large]       // Compact bar → Standard → Full details (no 1x1 - too truncated)
        case .monthProgress:
            return [.medium, .square, .large]       // Compact bar → Standard → Full details (no 1x1 - too truncated)
        case .quarterView:
            return [.small, .medium, .square]       // Badge → Standard → Full quarter grid
        case .clockWidget:
            return [.small, .medium, .square]       // Compact → Standard → With date/weekday

        // Live Data Widgets (情報デザイン)
        case .liveSeconds:
            return [.small, .medium, .square]       // Compact counter → With label → Full display
        case .worldClock:
            return [.small, .medium, .square]       // Time only → With offset → Full details
        case .systemStatus:
            return [.medium, .wide, .large]         // Compact header → Full bar → Dashboard

        // Event Widgets
        case .nextHoliday:
            return [.small, .medium, .square]       // Badge → Standard → With countdown
        case .holidaysList:
            return [.medium, .square, .large]       // Few items → Standard list → Extended list
        case .countdownHero:
            return [.small, .medium, .square]       // Badge → Standard → Large countdown
        case .countdownList:
            return [.medium, .square, .large]       // Few items → Standard list → Extended list

        // Notes Widgets
        case .notesPreview:
            return [.medium, .square, .large]       // Few notes → Standard → Extended
        case .pinnedNote:
            return [.small, .medium, .square]       // Icon only → Preview → Full note

        // Finance Widgets
        case .expenseTotal:
            return [.small, .medium, .square]       // Amount only → With label → With chart
        case .recentExpenses:
            return [.medium, .square, .large]       // Few items → Standard → Extended
        case .activeTripWidget:
            return [.small, .medium, .square]       // Badge → Standard → With details
        }
    }

    /// Category for grouping in catalog
    var category: WidgetCategory {
        switch self {
        case .todayHero, .weekBadge, .monthCalendar, .weekStrip,
             .yearProgress, .monthProgress, .quarterView, .clockWidget,
             .liveSeconds, .worldClock, .systemStatus:
            return .dateTime
        case .nextHoliday, .holidaysList, .countdownHero, .countdownList:
            return .events
        case .notesPreview, .pinnedNote:
            return .notes
        case .expenseTotal, .recentExpenses, .activeTripWidget:
            return .finance
        }
    }
}

// MARK: - Widget Category

enum WidgetCategory: String, CaseIterable, Identifiable {
    case dateTime = "Date & Time"
    case events = "Events"
    case notes = "Notes"
    case finance = "Finance & Travel"

    var id: String { rawValue }

    var types: [WidgetType] {
        WidgetType.allCases.filter { $0.category == self }
    }
}

// MARK: - Widget Size Presets

/// Predefined widget sizes following grid system
enum WidgetSize: String, Codable, CaseIterable {
    case small      // 1x1
    case medium     // 2x1
    case wide       // 4x1
    case square     // 2x2
    case large      // 4x2
    case full       // 4x4

    var columns: Int {
        switch self {
        case .small: return 1
        case .medium: return 2
        case .wide: return 4
        case .square: return 2
        case .large: return 4
        case .full: return 4
        }
    }

    var rows: Int {
        switch self {
        case .small: return 1
        case .medium: return 1
        case .wide: return 1
        case .square: return 2
        case .large: return 2
        case .full: return 4
        }
    }

    var displayName: String {
        switch self {
        case .small: return "Small (1×1)"
        case .medium: return "Medium (2×1)"
        case .wide: return "Wide (4×1)"
        case .square: return "Square (2×2)"
        case .large: return "Large (4×2)"
        case .full: return "Full (4×4)"
        }
    }
}

// MARK: - Workspace Widget Model

/// A widget placed on the workspace
@Model
final class WorkspaceWidget {
    // Identity
    var id: UUID

    // Type
    var typeRawValue: String

    // Position (grid coordinates)
    var gridX: Int
    var gridY: Int

    // Size (grid units)
    var columns: Int
    var rows: Int

    // Layer order for overlapping
    var zIndex: Int

    // Widget-specific configuration (JSON encoded)
    var configurationData: Data?

    // Timestamps
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Computed Properties

    var type: WidgetType {
        get { WidgetType(rawValue: typeRawValue) ?? .todayHero }
        set { typeRawValue = newValue.rawValue }
    }

    var size: WidgetSize {
        get {
            for size in WidgetSize.allCases {
                if size.columns == columns && size.rows == rows {
                    return size
                }
            }
            return .medium
        }
        set {
            columns = newValue.columns
            rows = newValue.rows
        }
    }

    // MARK: - Initialization

    init(
        type: WidgetType,
        gridX: Int = 0,
        gridY: Int = 0,
        size: WidgetSize? = nil,
        zIndex: Int = 0
    ) {
        self.id = UUID()
        self.typeRawValue = type.rawValue
        self.gridX = gridX
        self.gridY = gridY

        let widgetSize = size ?? type.defaultSize
        self.columns = widgetSize.columns
        self.rows = widgetSize.rows

        self.zIndex = zIndex
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    // MARK: - Methods

    func updatePosition(x: Int, y: Int) {
        gridX = x
        gridY = y
        modifiedAt = Date()
    }

    func updateSize(_ newSize: WidgetSize) {
        columns = newSize.columns
        rows = newSize.rows
        modifiedAt = Date()
    }

    func bringToFront(maxZ: Int) {
        zIndex = maxZ + 1
        modifiedAt = Date()
    }

    // MARK: - Configuration Helpers

    /// Get typed configuration for this widget
    func getConfiguration<T: Codable>(_ type: T.Type) -> T? {
        guard let data = configurationData else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// Set typed configuration for this widget
    func setConfiguration<T: Codable>(_ config: T) {
        configurationData = try? JSONEncoder().encode(config)
        modifiedAt = Date()
    }

    /// Get world clock configuration with defaults
    var worldClockConfig: WorldClockConfig {
        getConfiguration(WorldClockConfig.self) ?? WorldClockConfig.default
    }
}

// MARK: - Widget Configuration Types

/// Configuration for World Clock widget
struct WorldClockConfig: Codable {
    var timeZoneID: String
    var displayName: String

    /// Default: Stora Mellösa, Sweden
    static let `default` = WorldClockConfig(
        timeZoneID: "Europe/Stockholm",
        displayName: "STORA MELLÖSA"
    )

    /// Common world cities for quick selection
    static let presets: [WorldClockConfig] = [
        WorldClockConfig(timeZoneID: "Europe/Stockholm", displayName: "STORA MELLÖSA"),
        WorldClockConfig(timeZoneID: "Europe/London", displayName: "LONDON"),
        WorldClockConfig(timeZoneID: "America/New_York", displayName: "NEW YORK"),
        WorldClockConfig(timeZoneID: "America/Los_Angeles", displayName: "LOS ANGELES"),
        WorldClockConfig(timeZoneID: "Asia/Tokyo", displayName: "TOKYO"),
        WorldClockConfig(timeZoneID: "Asia/Shanghai", displayName: "SHANGHAI"),
        WorldClockConfig(timeZoneID: "Asia/Dubai", displayName: "DUBAI"),
        WorldClockConfig(timeZoneID: "Australia/Sydney", displayName: "SYDNEY"),
        WorldClockConfig(timeZoneID: "Europe/Paris", displayName: "PARIS"),
        WorldClockConfig(timeZoneID: "Europe/Berlin", displayName: "BERLIN"),
        WorldClockConfig(timeZoneID: "Asia/Singapore", displayName: "SINGAPORE"),
        WorldClockConfig(timeZoneID: "Asia/Hong_Kong", displayName: "HONG KONG"),
    ]
}

// MARK: - Grid Configuration

/// Responsive grid configuration that adapts to available screen space
struct ResponsiveGrid {
    let availableWidth: CGFloat
    let availableHeight: CGFloat
    let gutter: CGFloat = 12
    let padding: CGFloat = 16

    var columns: Int {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return availableWidth > availableHeight ? 8 : 6
        } else {
            return 4
        }
    }

    var baseUnit: CGFloat {
        let usableWidth = availableWidth - (2 * padding)
        let totalGutters = CGFloat(columns - 1) * gutter
        return (usableWidth - totalGutters) / CGFloat(columns)
    }

    func frame(x: Int, y: Int, widgetColumns: Int, widgetRows: Int) -> CGRect {
        let unit = baseUnit
        let originX = padding + CGFloat(x) * (unit + gutter)
        let originY = padding + CGFloat(y) * (unit + gutter)
        let width = CGFloat(widgetColumns) * unit + CGFloat(max(0, widgetColumns - 1)) * gutter
        let height = CGFloat(widgetRows) * unit + CGFloat(max(0, widgetRows - 1)) * gutter
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    func snapToGrid(point: CGPoint) -> (x: Int, y: Int) {
        let unit = baseUnit + gutter
        let adjustedX = point.x - padding
        let adjustedY = point.y - padding
        let x = max(0, min(columns - 1, Int(round(adjustedX / unit))))
        let y = max(0, Int(round(adjustedY / unit)))
        return (x, y)
    }

    var gridWidth: CGFloat { availableWidth }

    func minHeight(for maxRow: Int) -> CGFloat {
        let unit = baseUnit
        return padding * 2 + CGFloat(maxRow + 1) * unit + CGFloat(maxRow) * gutter
    }
}

// MARK: - Legacy Grid (backward compatibility)

enum WorkspaceGrid {
    static let gutter: CGFloat = 12

    static var baseUnit: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 100 : 80
    }

    static var columns: Int {
        UIDevice.current.userInterfaceIdiom == .pad ? 6 : 4
    }

    static func frame(x: Int, y: Int, columns: Int, rows: Int) -> CGRect {
        let unit = baseUnit
        let originX = CGFloat(x) * (unit + gutter)
        let originY = CGFloat(y) * (unit + gutter)
        let width = CGFloat(columns) * unit + CGFloat(columns - 1) * gutter
        let height = CGFloat(rows) * unit + CGFloat(rows - 1) * gutter
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    static func snapToGrid(point: CGPoint) -> (x: Int, y: Int) {
        let unit = baseUnit + gutter
        let x = max(0, Int(round(point.x / unit)))
        let y = max(0, Int(round(point.y / unit)))
        return (x, y)
    }
}

// MARK: - Default Workspace Configuration

extension WorkspaceWidget {
    /// Create default widgets for first launch - 6 varied widgets showcasing different features
    static func createDefaultWidgets(context: ModelContext) {
        let descriptor = FetchDescriptor<WorkspaceWidget>()
        guard let existing = try? context.fetch(descriptor), existing.isEmpty else {
            return
        }

        let widgets = [
            // Row 0: Today hero (2x1) + Week badge (1x1) + Clock (1x1)
            WorkspaceWidget(type: .todayHero, gridX: 0, gridY: 0, size: .medium, zIndex: 0),
            WorkspaceWidget(type: .weekBadge, gridX: 2, gridY: 0, size: .small, zIndex: 1),
            WorkspaceWidget(type: .clockWidget, gridX: 3, gridY: 0, size: .small, zIndex: 2),

            // Row 1: Week strip (4x1)
            WorkspaceWidget(type: .weekStrip, gridX: 0, gridY: 1, size: .wide, zIndex: 3),

            // Row 2-3: Calendar (4x2)
            WorkspaceWidget(type: .monthCalendar, gridX: 0, gridY: 2, size: .large, zIndex: 4),

            // Row 4: Countdown hero (2x1) + Next holiday (2x1)
            WorkspaceWidget(type: .countdownHero, gridX: 0, gridY: 4, size: .medium, zIndex: 5),
            WorkspaceWidget(type: .nextHoliday, gridX: 2, gridY: 4, size: .medium, zIndex: 6)
        ]

        for widget in widgets {
            context.insert(widget)
        }

        try? context.save()
    }
}
