import SwiftUI
import WidgetKit

// MARK: - 情報デザイン Widget Theme
// Japanese Information Design System adapted for iOS widgets
// All sizes: Small, Medium, Large, Extra Large

/// 情報デザイン Widget Design System
/// Pharmaceutical-inspired design with semantic colors and thick borders
enum JohoWidget {

    // MARK: - Semantic Colors
    /// Colors have MEANING - never decorative
    enum Colors {
        // Primary semantic colors
        static let now = Color(hex: "FFE566")           // Yellow - Today/Current
        static let event = Color(hex: "A5F3FC")         // Cyan - Scheduled events
        static let holiday = Color(hex: "FECDD3")       // Pink - Special days
        static let trip = Color(hex: "A5F3FC")          // Cyan - Travel/Movement
        static let expense = Color(hex: "BBF7D0")       // Green - Money
        static let contact = Color(hex: "E9D5FF")       // Purple - People
        static let alert = Color(hex: "E53935")         // Red - Warnings/Sunday
        static let note = Color(hex: "FFE566")          // Yellow - Personal notes

        // Structural colors
        static let border = Color.black                  // Always pure black
        static let content = Color.white                 // Container backgrounds
        static let canvas = Color(hex: "1A1A2E")        // Widget background
        static let text = Color.black                    // Primary text
        static let textSecondary = Color(hex: "6B7280") // 情報デザイン: Gray-500 secondary (no opacity)
        static let textInverted = Color.white           // Text on dark backgrounds

        // Day-specific (for calendar grids)
        static let sunday = Color(hex: "E53935")        // Red - weekend end
        static let saturday = Color(hex: "E9D5FF")      // Purple - weekend start
        static let weekday = Color.white                 // Normal days
    }

    // MARK: - Border Weights by Widget Size
    /// Borders scale with widget size for visual consistency
    enum Borders {

        struct Weights {
            let cell: CGFloat           // Day cells, small items
            let row: CGFloat            // List rows
            let button: CGFloat         // Interactive elements
            let selected: CGFloat       // Today/selected state
            let container: CGFloat      // Main containers
            let widget: CGFloat         // Widget edge
        }

        static let small = Weights(
            cell: 0.5,
            row: 1,
            button: 1,
            selected: 1.5,
            container: 1.5,
            widget: 2
        )

        static let medium = Weights(
            cell: 0.75,
            row: 1,
            button: 1.5,
            selected: 2,
            container: 2,
            widget: 2.5
        )

        static let large = Weights(
            cell: 1,
            row: 1.5,
            button: 2,
            selected: 2.5,
            container: 2.5,
            widget: 3
        )

        static let extraLarge = Weights(
            cell: 1,
            row: 1.5,
            button: 2,
            selected: 2.5,
            container: 3,
            widget: 3
        )

        static func weights(for family: WidgetFamily) -> Weights {
            switch family {
            case .systemSmall:
                return small
            case .systemMedium:
                return medium
            case .systemLarge:
                return large
            case .systemExtraLarge:
                return extraLarge
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                return small  // Accessory widgets use smallest sizing
            @unknown default:
                return medium
            }
        }
    }

    // MARK: - Typography by Widget Size
    /// Font sizes optimized for each widget size
    enum Typography {

        struct Scale {
            let weekNumber: CGFloat     // Hero week number
            let title: CGFloat          // Section titles
            let headline: CGFloat       // Card headers
            let body: CGFloat           // Main content
            let caption: CGFloat        // Secondary info
            let label: CGFloat          // Pills, badges
            let micro: CGFloat          // Timestamps, day initials
        }

        static let small = Scale(
            weekNumber: 48,
            title: 14,
            headline: 12,
            body: 11,
            caption: 10,
            label: 9,
            micro: 8
        )

        static let medium = Scale(
            weekNumber: 56,
            title: 16,
            headline: 14,
            body: 13,
            caption: 11,
            label: 10,
            micro: 9
        )

        static let large = Scale(
            weekNumber: 64,
            title: 18,
            headline: 16,
            body: 14,
            caption: 12,
            label: 11,
            micro: 10
        )

        static let extraLarge = Scale(
            weekNumber: 72,
            title: 20,
            headline: 18,
            body: 16,
            caption: 14,
            label: 12,
            micro: 11
        )

        static func scale(for family: WidgetFamily) -> Scale {
            switch family {
            case .systemSmall:
                return small
            case .systemMedium:
                return medium
            case .systemLarge:
                return large
            case .systemExtraLarge:
                return extraLarge
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                return small  // Accessory widgets use smallest font sizes
            @unknown default:
                return medium
            }
        }

        // Font builder - always rounded, never below medium weight
        static func font(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }
    }

    // MARK: - Spacing by Widget Size
    /// Padding and gaps scaled for each size
    enum Spacing {

        struct Grid {
            let xs: CGFloat     // Micro gaps
            let sm: CGFloat     // Cell gaps
            let md: CGFloat     // Section gaps
            let lg: CGFloat     // Container padding
            let xl: CGFloat     // Screen margins
        }

        // Reduced padding for tighter bento compartments
        static let small = Grid(xs: 1, sm: 2, md: 4, lg: 6, xl: 8)
        static let medium = Grid(xs: 2, sm: 3, md: 6, lg: 8, xl: 10)
        static let large = Grid(xs: 2, sm: 4, md: 6, lg: 8, xl: 10)
        static let extraLarge = Grid(xs: 3, sm: 6, md: 8, lg: 10, xl: 12)

        static func grid(for family: WidgetFamily) -> Grid {
            switch family {
            case .systemSmall:
                return small
            case .systemMedium:
                return medium
            case .systemLarge:
                return large
            case .systemExtraLarge:
                return extraLarge
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                return small  // Accessory widgets use smallest spacing
            @unknown default:
                return medium
            }
        }
    }

    // MARK: - Corner Radius by Widget Size
    /// All corners use continuous curvature (squircle)
    enum Corners {

        struct Radii {
            let pill: CGFloat       // Small badges
            let cell: CGFloat       // Day cells
            let card: CGFloat       // Content cards
            let container: CGFloat  // Main containers
            let widget: CGFloat     // Widget corners
        }

        static let small = Radii(pill: 4, cell: 6, card: 8, container: 10, widget: 16)
        static let medium = Radii(pill: 5, cell: 7, card: 10, container: 12, widget: 18)
        static let large = Radii(pill: 6, cell: 8, card: 12, container: 14, widget: 20)
        static let extraLarge = Radii(pill: 6, cell: 8, card: 12, container: 16, widget: 22)

        static func radii(for family: WidgetFamily) -> Radii {
            switch family {
            case .systemSmall:
                return small
            case .systemMedium:
                return medium
            case .systemLarge:
                return large
            case .systemExtraLarge:
                return extraLarge
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                return small  // Accessory widgets use smallest corner radii
            @unknown default:
                return medium
            }
        }
    }

    // MARK: - Day Cell Dimensions
    /// Optimized cell sizes for calendar grids
    enum CellSize {

        struct Dimensions {
            let width: CGFloat
            let height: CGFloat
            let eventDotSize: CGFloat
        }

        static let small = Dimensions(width: 18, height: 18, eventDotSize: 4)
        static let medium = Dimensions(width: 22, height: 22, eventDotSize: 5)
        static let large = Dimensions(width: 40, height: 44, eventDotSize: 6)
        static let extraLarge = Dimensions(width: 80, height: 56, eventDotSize: 8)

        static func dimensions(for family: WidgetFamily) -> Dimensions {
            switch family {
            case .systemSmall:
                return small
            case .systemMedium:
                return medium
            case .systemLarge:
                return large
            case .systemExtraLarge:
                return extraLarge
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                return small  // Accessory widgets use smallest cell dimensions
            @unknown default:
                return medium
            }
        }
    }
}

// MARK: - Reusable Widget Components

extension JohoWidget {

    // MARK: - Week Number Display
    /// Hero week number with semantic background
    struct WeekNumber: View {
        let number: Int
        let isCurrentWeek: Bool
        let family: WidgetFamily

        var body: some View {
            let typo = Typography.scale(for: family)
            let corners = Corners.radii(for: family)
            let borders = Borders.weights(for: family)

            Text("\(number)")
                .font(Typography.font(typo.weekNumber, weight: .heavy))
                .foregroundStyle(Colors.text)
                .padding(.horizontal, typo.weekNumber * 0.3)
                .padding(.vertical, typo.weekNumber * 0.15)
                .background(isCurrentWeek ? Colors.now : Colors.content)
                .clipShape(RoundedRectangle(cornerRadius: corners.container, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: corners.container, style: .continuous)
                        .stroke(Colors.border, lineWidth: isCurrentWeek ? borders.selected : borders.container)
                )
        }
    }

    // MARK: - Day Cell
    /// Individual day in calendar grid
    struct DayCell: View {
        let day: Int
        let isToday: Bool
        let isHoliday: Bool
        let isSunday: Bool
        let hasEvent: Bool
        let family: WidgetFamily

        var body: some View {
            let typo = Typography.scale(for: family)
            let corners = Corners.radii(for: family)
            let borders = Borders.weights(for: family)
            let cell = CellSize.dimensions(for: family)

            VStack(spacing: 2) {
                Text("\(day)")
                    .font(Typography.font(family == .systemSmall ? typo.micro : typo.caption, weight: isToday ? .bold : .medium))
                    .foregroundStyle(isSunday ? Colors.alert : Colors.text)

                if hasEvent && family != .systemSmall {
                    Circle()
                        .fill(Colors.event)
                        .frame(width: cell.eventDotSize, height: cell.eventDotSize)
                }
            }
            .frame(width: cell.width, height: cell.height)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: corners.cell, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corners.cell, style: .continuous)
                    .stroke(Colors.border, lineWidth: isToday ? borders.selected : borders.cell)
            )
        }

        private var backgroundColor: Color {
            // 情報デザイン: Solid colors only, no opacity
            if isToday { return Colors.now }
            if isHoliday { return Colors.holiday }
            if isSunday { return Colors.saturday } // Light purple for weekends
            return Colors.content
        }
    }

    // MARK: - Info Pill
    /// Small badge for labels and counts
    struct Pill: View {
        let text: String
        let color: Color
        let family: WidgetFamily

        init(_ text: String, color: Color = Colors.border, family: WidgetFamily) {
            self.text = text
            self.color = color
            self.family = family
        }

        var body: some View {
            let typo = Typography.scale(for: family)
            let corners = Corners.radii(for: family)

            Text(text.uppercased())
                .font(Typography.font(typo.label, weight: .bold))
                .foregroundStyle(Colors.textInverted)
                .padding(.horizontal, typo.label * 0.8)
                .padding(.vertical, typo.label * 0.3)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: corners.pill, style: .continuous))
        }
    }

    // MARK: - Holiday Row
    /// Compact holiday display
    struct HolidayRow: View {
        let name: String
        let date: String
        let family: WidgetFamily

        var body: some View {
            let typo = Typography.scale(for: family)
            let corners = Corners.radii(for: family)
            let borders = Borders.weights(for: family)
            let spacing = Spacing.grid(for: family)

            HStack(spacing: spacing.sm) {
                // Semantic color indicator
                RoundedRectangle(cornerRadius: corners.pill, style: .continuous)
                    .fill(Colors.holiday)
                    .frame(width: typo.body * 0.3, height: typo.body * 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: corners.pill, style: .continuous)
                            .stroke(Colors.border, lineWidth: borders.cell)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(Typography.font(typo.caption, weight: .semibold))
                        .foregroundStyle(Colors.text)
                        .lineLimit(1)

                    Text(date)
                        .font(Typography.font(typo.micro, weight: .medium))
                        // 情報デザイン: Use secondary text color, no opacity
                        .foregroundStyle(Colors.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.xs)
            .background(Colors.content)
            .clipShape(RoundedRectangle(cornerRadius: corners.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corners.card, style: .continuous)
                    .stroke(Colors.border, lineWidth: borders.row)
            )
        }
    }

    // MARK: - Event Row
    /// Compact event display
    struct EventRow: View {
        let title: String
        let time: String
        let family: WidgetFamily

        var body: some View {
            let typo = Typography.scale(for: family)
            let corners = Corners.radii(for: family)
            let borders = Borders.weights(for: family)
            let spacing = Spacing.grid(for: family)

            HStack(spacing: spacing.sm) {
                // Semantic color indicator
                RoundedRectangle(cornerRadius: corners.pill, style: .continuous)
                    .fill(Colors.event)
                    .frame(width: typo.body * 0.3, height: typo.body * 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: corners.pill, style: .continuous)
                            .stroke(Colors.border, lineWidth: borders.cell)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Typography.font(typo.caption, weight: .semibold))
                        .foregroundStyle(Colors.text)
                        .lineLimit(1)

                    Text(time)
                        .font(Typography.font(typo.micro, weight: .medium))
                        // 情報デザイン: Use secondary text color, no opacity
                        .foregroundStyle(Colors.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.xs)
            .background(Colors.content)
            .clipShape(RoundedRectangle(cornerRadius: corners.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corners.card, style: .continuous)
                    .stroke(Colors.border, lineWidth: borders.row)
            )
        }
    }

    // MARK: - Countdown Display
    /// Days remaining countdown
    struct Countdown: View {
        let title: String
        let daysRemaining: Int
        let family: WidgetFamily

        var body: some View {
            let typo = Typography.scale(for: family)
            let corners = Corners.radii(for: family)
            let borders = Borders.weights(for: family)
            let spacing = Spacing.grid(for: family)

            HStack(spacing: spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.font(typo.caption, weight: .semibold))
                        .foregroundStyle(Colors.text)
                        .lineLimit(1)

                    Text("\(daysRemaining) DAYS")
                        .font(Typography.font(typo.label, weight: .bold))
                        .foregroundStyle(Colors.text)
                }

                Spacer(minLength: 0)

                // Countdown number badge
                Text("\(daysRemaining)")
                    .font(Typography.font(typo.title, weight: .heavy))
                    .foregroundStyle(Colors.text)
                    .padding(.horizontal, spacing.md)
                    .padding(.vertical, spacing.sm)
                    .background(Colors.now)
                    .clipShape(RoundedRectangle(cornerRadius: corners.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: corners.card, style: .continuous)
                            .stroke(Colors.border, lineWidth: borders.container)
                    )
            }
            .padding(spacing.md)
            .background(Colors.content)
            .clipShape(RoundedRectangle(cornerRadius: corners.container, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corners.container, style: .continuous)
                    .stroke(Colors.border, lineWidth: borders.container)
            )
        }
    }

    // MARK: - Section Container
    /// Bordered container for grouping content
    struct Container<Content: View>: View {
        let family: WidgetFamily
        @ViewBuilder let content: () -> Content

        var body: some View {
            let corners = Corners.radii(for: family)
            let borders = Borders.weights(for: family)
            let spacing = Spacing.grid(for: family)

            content()
                .padding(spacing.md)
                .background(Colors.content)
                .clipShape(RoundedRectangle(cornerRadius: corners.container, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: corners.container, style: .continuous)
                        .stroke(Colors.border, lineWidth: borders.container)
                )
        }
    }

    // MARK: - Widget Background
    /// Standard widget background with border
    struct Background: View {
        let family: WidgetFamily

        var body: some View {
            let corners = Corners.radii(for: family)
            let borders = Borders.weights(for: family)

            RoundedRectangle(cornerRadius: corners.widget, style: .continuous)
                .fill(Colors.canvas)
                .overlay(
                    RoundedRectangle(cornerRadius: corners.widget, style: .continuous)
                        .stroke(Colors.border, lineWidth: borders.widget)
                )
        }
    }

    // MARK: - Week Header
    /// Day-of-week header row
    struct WeekHeader: View {
        let family: WidgetFamily
        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

        var body: some View {
            let typo = Typography.scale(for: family)
            let cell = CellSize.dimensions(for: family)
            let spacing = Spacing.grid(for: family)

            HStack(spacing: spacing.xs) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(Typography.font(typo.micro, weight: .bold))
                        .foregroundStyle(index == 6 ? Colors.alert : Colors.text)
                        .frame(width: cell.width)
                }
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Legacy Support (for backwards compatibility)

// Old naming aliases
enum JohoWidgetColors {
    static let black = JohoWidget.Colors.border
    static let white = JohoWidget.Colors.content
    static let pink = JohoWidget.Colors.holiday
    static let cyan = JohoWidget.Colors.event
    static let sundayBlue = JohoWidget.Colors.sunday
    static let todayRed = JohoWidget.Colors.alert
}

enum JohoWidgetFont {
    static let displayHuge = Font.system(size: 56, weight: .black, design: .rounded)
    static let displayLarge = Font.system(size: 42, weight: .black, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headerLarge = Font.system(size: 18, weight: .heavy, design: .rounded)
    static let headerMedium = Font.system(size: 15, weight: .bold, design: .rounded)
    static let bodyLarge = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 13, weight: .medium, design: .rounded)
    static let labelBold = Font.system(size: 11, weight: .heavy, design: .rounded)
    static let labelSmall = Font.system(size: 10, weight: .bold, design: .rounded)
    static let calendarDay = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let calendarDayBold = Font.system(size: 15, weight: .bold, design: .rounded)
    static let weekNumber = Font.system(size: 10, weight: .heavy, design: .rounded)
}

enum JohoDimensions {
    static let borderBold: CGFloat = 3
    static let borderMedium: CGFloat = 2.5
    static let borderThin: CGFloat = 2
    static let radiusLarge: CGFloat = 16
    static let radiusMedium: CGFloat = 12
    static let radiusSmall: CGFloat = 8
    static let radiusTiny: CGFloat = 6
    static let spacingXL: CGFloat = 16
    static let spacingLG: CGFloat = 12
    static let spacingMD: CGFloat = 8
    static let spacingSM: CGFloat = 6
    static let spacingXS: CGFloat = 4
}

struct WidgetSquircle: Shape {
    let cornerRadius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
    }
}

struct JohoWeekBadge: View {
    let weekNumber: Int
    var size: Size = .medium

    enum Size {
        case small, medium, large
        var fontSize: CGFloat {
            switch self { case .small: return 11; case .medium: return 14; case .large: return 16 }
        }
        var paddingH: CGFloat {
            switch self { case .small: return 8; case .medium: return 10; case .large: return 12 }
        }
        var paddingV: CGFloat {
            switch self { case .small: return 4; case .medium: return 5; case .large: return 6 }
        }
    }

    var body: some View {
        Text("W\(weekNumber)")
            .font(.system(size: size.fontSize, weight: .black, design: .rounded))
            .foregroundStyle(JohoWidgetColors.white)
            .padding(.horizontal, size.paddingH)
            .padding(.vertical, size.paddingV)
            .background(JohoWidgetColors.black)
            .clipShape(WidgetSquircle(cornerRadius: JohoDimensions.radiusTiny))
    }
}

struct JohoDayCell: View {
    let day: Int
    let isToday: Bool
    let isBankHoliday: Bool
    let isSunday: Bool
    var cellSize: CGFloat = 28

    var body: some View {
        ZStack {
            if isToday {
                Circle()
                    .fill(JohoWidgetColors.todayRed)
                    .frame(width: cellSize, height: cellSize)
            }
            Text("\(day)")
                .font(isToday ? JohoWidgetFont.calendarDayBold : JohoWidgetFont.calendarDay)
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var textColor: Color {
        if isToday { return JohoWidgetColors.white }
        if isBankHoliday { return JohoWidgetColors.pink }
        if isSunday { return JohoWidgetColors.sundayBlue }
        return JohoWidgetColors.black
    }
}

struct JohoHolidayPill: View {
    let name: String
    let isBankHoliday: Bool

    var body: some View {
        HStack(spacing: JohoDimensions.spacingXS) {
            Circle()
                .fill(isBankHoliday ? JohoWidgetColors.pink : JohoWidgetColors.cyan)
                .frame(width: 6, height: 6)
            Text(name)
                .font(JohoWidgetFont.labelSmall)
                .foregroundStyle(isBankHoliday ? JohoWidgetColors.pink : JohoWidgetColors.cyan)
                .lineLimit(1)
        }
    }
}

struct WidgetColors {
    static let accent = JohoWidget.Colors.alert
    static let holiday = JohoWidget.Colors.holiday
    static let observance = JohoWidget.Colors.event
    static let sundayBlue = JohoWidget.Colors.sunday
    static let saturdayNormal = Color.primary
}

struct Theme {
    static let cornerRadius: CGFloat = 20
    static let padding: CGFloat = 16
    static let compactPadding: CGFloat = 12
    static let itemSpacing: CGFloat = 8

    static func primaryLabel(for mode: WidgetRenderingMode) -> Color {
        switch mode {
        case .vibrant: return .white
        case .accented: return .primary
        default: return .primary
        }
    }

    static func secondaryLabel(for mode: WidgetRenderingMode) -> Color {
        switch mode {
        case .vibrant: return .white.opacity(0.6)
        case .accented: return .secondary
        default: return .secondary
        }
    }

    static func tertiaryLabel(for mode: WidgetRenderingMode) -> Color {
        switch mode {
        case .vibrant: return .white.opacity(0.4)
        case .accented: return .secondary.opacity(0.6)
        default: return Color(uiColor: .tertiaryLabel)
        }
    }
}

// MARK: - Quick Reference

/*
┌─────────────────────────────────────────────────────────────────┐
│              情報デザイン WIDGET QUICK REFERENCE                 │
├─────────────────────────────────────────────────────────────────┤
│ WIDGET SIZES:                                                   │
│   Small      = 158×158 pts (2×2 grid)                          │
│   Medium     = 338×158 pts (4×2 grid)                          │
│   Large      = 338×354 pts (4×4 grid)                          │
│   Extra Large = 720×354 pts (iPad only)                         │
├─────────────────────────────────────────────────────────────────┤
│ SEMANTIC COLORS:                                                │
│   Yellow #FFE566 = Today/Now (current week highlight)          │
│   Cyan   #A5F3FC = Events (calendar items)                     │
│   Pink   #FECDD3 = Holidays (special days)                     │
│   Orange #FED7AA = Trips (travel)                              │
│   Green  #BBF7D0 = Expenses (money)                            │
│   Purple #E9D5FF = Contacts/Saturday                           │
│   Red    #E53935 = Warnings/Sunday                             │
├─────────────────────────────────────────────────────────────────┤
│ BORDER WEIGHTS BY SIZE:                                         │
│              Small   Medium   Large   XL                        │
│   Cell       0.5     0.75     1       1                         │
│   Row        1       1        1.5     1.5                       │
│   Container  1.5     2        2.5     3                         │
│   Widget     2       2.5      3       3                         │
├─────────────────────────────────────────────────────────────────┤
│ WEEK NUMBER SIZE:                                               │
│   Small = 48pt   Medium = 56pt   Large = 64pt   XL = 72pt      │
├─────────────────────────────────────────────────────────────────┤
│ FORBIDDEN IN WIDGETS:                                           │
│   ✗ Glass/blur materials (.ultraThinMaterial)                  │
│   ✗ Gradients                                                   │
│   ✗ Missing borders                                             │
│   ✗ Non-semantic colors                                         │
│   ✗ Non-continuous corners (.cornerRadius)                      │
│   ✗ Font weights below .medium                                  │
│   ✗ Decorative elements                                         │
├─────────────────────────────────────────────────────────────────┤
│ USAGE:                                                          │
│   JohoWidget.WeekNumber(number: 2, isCurrentWeek: true,        │
│                         family: .systemMedium)                  │
│   JohoWidget.DayCell(day: 15, isToday: true, ...)              │
│   JohoWidget.Container(family: .systemLarge) { content }       │
│   JohoWidget.Pill("HOLIDAY", color: .holiday, family: ...)     │
└─────────────────────────────────────────────────────────────────┘
*/
