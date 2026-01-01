//
//  DesignSystem.swift
//  Vecka
//
//  Apple HIG + Liquid Glass design system
//  One unified visual language for WeekGrid
//

import SwiftUI
import SwiftData

// MARK: - App Colors
struct AppColors {
    // MARK: - System Semantic Colors (Auto-adapting to Light/Dark Mode)
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let surfaceElevated = Color(.tertiarySystemBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let divider = Color(.separator)
    
    // MARK: - Apple Standard Accent Colors
    static let accentBlue = Color(.systemBlue)
    static let accentTeal = Color(.systemTeal)
    static let accentYellow = Color(.systemOrange)
    static let accentRed = Color(.systemRed)
    static let accentPurple = Color(.systemPurple)
    
    // MARK: - Daily Color Associations (Planetary Colors)
    // Delegated to SharedColors for consistency with widget
    static var mondayMoon: Color { SharedColors.mondayMoon }
    static var tuesdayFire: Color { SharedColors.tuesdayFire }
    static var wednesdayWater: Color { SharedColors.wednesdayWater }
    static var thursdayWood: Color { SharedColors.thursdayWood }
    static var fridayMetal: Color { SharedColors.fridayMetal }
    static var saturdayEarth: Color { SharedColors.saturdayEarth }
    static var sundaySun: Color { SharedColors.sundaySun }
    
    // Dynamic color function for daily color scheme
    // Note: Use colorForDay(date:context:) for database-driven themes
    static func colorForDay(_ date: Date) -> Color {
        let weekday = Calendar.iso8601.component(.weekday, from: date)

        switch weekday {
        case 1: return sundaySun      // Sunday - Sun
        case 2: return mondayMoon     // Monday - Moon
        case 3: return tuesdayFire    // Tuesday - Fire (Mars)
        case 4: return wednesdayWater // Wednesday - Water (Mercury)
        case 5: return thursdayWood   // Thursday - Wood (Jupiter)
        case 6: return fridayMetal    // Friday - Metal (Venus)
        case 7: return saturdayEarth  // Saturday - Earth (Saturn)
        default: return accentBlue
        }
    }

    // Database-driven theme color for day (uses UITheme from database)
    static func colorForDay(_ date: Date, context: ModelContext) -> Color {
        let weekday = Calendar.iso8601.component(.weekday, from: date)
        return ConfigurationManager.shared.getWeekdayColor(for: weekday, context: context)
    }
}

// MARK: - Slate Design Language (Dark Mode Focused)
/// Design tokens for the elegant dark slate UI from mockups
struct SlateColors {
    // MARK: - Backgrounds
    /// Deep slate background - the canvas everything sits on
    static let deepSlate = Color(hex: "1A1A2E")
    /// Medium slate for elevated surfaces like panels
    static let mediumSlate = Color(hex: "2A2A3E")
    /// Light slate for subtle elevation
    static let lightSlate = Color(hex: "3A3A4E")

    // MARK: - Today Indicator
    /// Subtle slate blue for today's cell highlight
    static let todayHighlight = Color(hex: "3D4A5C")
    /// Selected cell highlight (slightly more prominent)
    static let selectionHighlight = Color(hex: "4D5A6C")

    // MARK: - Text Colors
    /// Primary text (white)
    static let primaryText = Color.white
    /// Secondary text (60% white)
    static let secondaryText = Color(white: 0.6)
    /// Tertiary text (40% white)
    static let tertiaryText = Color(white: 0.4)
    /// Muted text for out-of-month days
    static let mutedText = Color(white: 0.25)

    // MARK: - Weekend Colors (Mockup Spec)
    /// Sunday text color - BLUE (not red) - delegated to SharedColors
    static var sundayBlue: Color { SharedColors.sundayBlue }
    /// Saturday text color - same as primary (not special)
    static let saturdayNormal = Color.white

    // MARK: - Accent Colors
    /// Sidebar selection bar (bright blue)
    static let sidebarActiveBar = Color(hex: "3B82F6")
    /// Default icon color (50% white)
    static let iconDefault = Color(white: 0.5)
    /// Active icon color (white)
    static let iconActive = Color.white

    // MARK: - Borders & Dividers
    /// Subtle divider line
    static let divider = Color(white: 0.2)
    /// Selection border
    static let selectionBorder = Color(hex: "3B82F6")

    // MARK: - Convenience Functions

    /// Returns the appropriate text color for a weekday
    /// - Parameters:
    ///   - isSunday: True if the day is Sunday
    ///   - isSaturday: True if the day is Saturday (not used - Saturday is normal)
    ///   - isToday: True if the day is today
    ///   - isInCurrentMonth: True if the day is in the displayed month
    /// - Returns: The appropriate text color
    static func dayTextColor(
        isSunday: Bool,
        isSaturday: Bool = false,
        isToday: Bool = false,
        isInCurrentMonth: Bool = true
    ) -> Color {
        if !isInCurrentMonth {
            return mutedText
        }
        if isSunday {
            return sundayBlue
        }
        // Saturday and all other days use primary text
        return primaryText
    }

    /// Returns the weekday header color
    /// - Parameter index: 0-based index where 0=Monday, 6=Sunday
    /// - Returns: The appropriate header color
    static func weekdayHeaderColor(for index: Int) -> Color {
        if index == 6 { // Sunday
            return sundayBlue
        }
        return secondaryText
    }
}

// MARK: - Thread-Safe Helper Extensions
// NOTE: Color.init(hex:) is now defined in SharedColors.swift

// MARK: - Typography System
/// Apple HIG-compliant typography scale following iOS 17 design guidelines
struct Typography {
    // MARK: - Display Styles (Hero Content)
    static let largeTitle = Font.largeTitle.weight(.bold)  // iOS standard large title
    static let heroDisplay = Font.system(size: 88, weight: .bold, design: .rounded)
    
    // MARK: - Title Styles (Primary Headings)
    static let title1 = Font.title.weight(.bold)          // iOS standard title1
    static let title2 = Font.title2.weight(.bold)         // iOS standard title2  
    static let title3 = Font.title3.weight(.semibold)     // iOS standard title3
    static let titleLarge = Font.system(size: 34, weight: .bold, design: .default)
    static let titleMedium = Font.system(size: 28, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 22, weight: .semibold, design: .default)
    
    // MARK: - Headline (Secondary Headings)
    static let headline = Font.headline.weight(.semibold)  // iOS standard headline
    
    // MARK: - Body Text (Content)
    static let body = Font.body                           // iOS standard body
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: - Callout (Emphasized Content)
    static let callout = Font.callout                     // iOS standard callout
    
    // MARK: - Subheadline (Supporting Text)
    static let subheadline = Font.subheadline            // iOS standard subheadline
    
    // MARK: - Footnote (Small Text)
    static let footnote = Font.footnote                  // iOS standard footnote
    
    // MARK: - Caption (Smallest Text)
    static let caption1 = Font.caption                   // iOS standard caption1 (12pt)
    static let caption2 = Font.caption2                  // iOS standard caption2 (11pt)
    static let captionLarge = Font.caption.weight(.medium)
    static let captionMedium = Font.caption2             // HIG: 11pt minimum, use system style
    static let captionSmall = Font.caption2.weight(.medium) // HIG: 11pt minimum, never below
    
    // MARK: - Label Styles (UI Elements)
    static let labelLarge = Font.body.weight(.semibold)
    static let labelMedium = Font.subheadline.weight(.medium)
    static let labelSmall = Font.footnote.weight(.medium)
    
    // MARK: - Tracking Values (Letter Spacing)
    static let tightTracking: CGFloat = -0.41        // Apple's tight tracking
    static let normalTracking: CGFloat = 0.0         // Default tracking
    static let wideTracking: CGFloat = 0.38          // Apple's wide tracking
    static let extraWideTracking: CGFloat = 1.2      // Extra wide for caps
    
    // MARK: - Line Height Multipliers
    static let tightLineSpacing: CGFloat = 1.1        // Tight line spacing
    static let normalLineSpacing: CGFloat = 1.2       // Normal line spacing
    static let relaxedLineSpacing: CGFloat = 1.4      // Relaxed line spacing
}

// MARK: - Spacing System
/// Consistent spacing scale following 8-point grid system
struct Spacing {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
    static let huge: CGFloat = 48
    static let massive: CGFloat = 64
    
    // Semantic spacing for specific use cases
    static let cardPadding: CGFloat = medium
    static let sectionSpacing: CGFloat = large
    static let componentSpacing: CGFloat = small
    static let elementSpacing: CGFloat = extraSmall
}

// MARK: - 情報デザイン Elevation System
// Replaces glass materials with solid colors + black borders per CLAUDE.md
struct JohoElevation {
    /// Elevation levels for card surfaces (情報デザイン uses solid white + black borders)
    enum Level {
        case low        // Background cards
        case medium     // Interactive elements
        case high       // Important UI
        case floating   // Popover content

        var cornerRadius: CGFloat {
            switch self {
            case .low: return 12
            case .medium: return 16
            case .high: return 20
            case .floating: return 24
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .low: return 1.5
            case .medium: return 2.0
            case .high: return 2.5
            case .floating: return 3.0
            }
        }
    }
}

// MARK: - 情報デザイン Toolbar Button Style
/// Solid white button with black border (no glass materials)
struct JohoToolbarButtonStyle: ButtonStyle {
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(isProminent ? JohoColors.white : JohoColors.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isProminent ? JohoColors.black : JohoColors.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - 情報デザイン Card View Modifier
/// Solid white card with black border (replaces glass materials)
struct JohoCardViewModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var borderWidth: CGFloat = 2.0

    func body(content: Content) -> some View {
        content
            .background(JohoColors.white, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}

extension View {
    /// Applies 情報デザイン card styling with white background and black border
    func johoCard(cornerRadius: CGFloat = 16, borderWidth: CGFloat = 2.0) -> some View {
        modifier(JohoCardViewModifier(cornerRadius: cornerRadius, borderWidth: borderWidth))
    }
}

// (DashboardCard removed; unused after dashboard components cleanup)

// MARK: - Unified Design Tokens
/// Single source of truth for the app's visual identity
struct DesignTokens {
    // MARK: - The One Accent Color
    /// WeekGrid uses a single accent color for all UI chrome.
    /// Planetary colors are reserved for week number display only.
    static let accent = Color.accentColor

    // MARK: - 情報デザイン Colors (solid, no glass materials)
    static let background = JohoColors.background
    static let cardBackground = JohoColors.white
    static let borderColor = JohoColors.black

    // MARK: - Corner Radii (Apple HIG continuous corners)
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXL: CGFloat = 20

    // MARK: - Border Widths (情報デザイン spec)
    static let borderThin: CGFloat = 1.0
    static let borderMedium: CGFloat = 2.0
    static let borderThick: CGFloat = 3.0
}

// NOTE: JohoCard is defined in JohoDesignSystem.swift - use that version

// MARK: - Glass Section Header
/// Consistent section header styling
struct GlassSectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }
}

// MARK: - Glass List Row
/// A standard row for lists with glass styling
struct GlassListRow<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leading: Leading
    let trailing: Trailing
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leading

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                trailing
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Unified View Styling

/// Standard modifiers for consistent app appearance
extension View {
    /// Apply standard dark slate background for library/list views
    func slateBackground() -> some View {
        self
            .background(SlateColors.deepSlate)
            .scrollContentBackground(.hidden)
    }

    /// Apply standard list styling with dark theme
    func standardListStyle() -> some View {
        self
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(SlateColors.deepSlate)
    }

    /// Apply standard navigation bar styling
    func standardNavigation(title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SlateColors.mediumSlate, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Standard Card Styles

/// Semantic card types for consistent 情報デザイン styling
enum CardStyle {
    case primary    // Main content cards - 16pt radius, 3pt border
    case secondary  // Supporting cards - 12pt radius, 2pt border
    case compact    // Dense list items - 10pt radius, 1.5pt border

    var cornerRadius: CGFloat {
        switch self {
        case .primary: return 16
        case .secondary: return 12
        case .compact: return 10
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .primary: return 3.0
        case .secondary: return 2.0
        case .compact: return 1.5
        }
    }
}

extension View {
    /// Apply 情報デザイン card styling (white background + black border)
    func standardCard(_ style: CardStyle = .primary) -> some View {
        self.johoCard(cornerRadius: style.cornerRadius, borderWidth: style.borderWidth)
    }

    /// Apply standard list row background for dark theme
    func standardListRowBackground() -> some View {
        self.listRowBackground(SlateColors.mediumSlate)
    }
}

// MARK: - Standard UI Components

/// Consistent section header with uppercase styling
struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(SlateColors.secondaryText)
            .tracking(0.5)
    }
}

/// Standard list row with consistent styling
struct StandardListRow<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leading: Leading
    let trailing: Trailing
    let showChevron: Bool

    init(
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            leading

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(SlateColors.primaryText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(SlateColors.secondaryText)
                }
            }

            Spacer(minLength: 0)

            trailing

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlateColors.tertiaryText)
            }
        }
        .padding(.vertical, Spacing.medium)
        .contentShape(Rectangle())
    }
}

/// Empty state view with centered icon, title, and message
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionLabel: String?

    init(
        icon: String,
        title: String,
        message: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(SlateColors.tertiaryText)

            VStack(spacing: Spacing.small) {
                Text(title)
                    .font(Typography.title3)
                    .foregroundStyle(SlateColors.primaryText)

                Text(message)
                    .font(Typography.subheadline)
                    .foregroundStyle(SlateColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(Typography.labelMedium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.large)
                        .padding(.vertical, Spacing.medium)
                        .background(AppColors.accentBlue, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.extraLarge)
    }
}

/// Standard stat card for dashboards
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(value)
                .font(Typography.title2)
                .foregroundStyle(SlateColors.primaryText)

            Text(title)
                .font(Typography.caption1)
                .foregroundStyle(SlateColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.medium)
        .background(SlateColors.mediumSlate)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium, style: .continuous))
    }
}

// MARK: - Layout & Animation Constants
// See ViewUtilities.swift for LayoutConstants and AnimationConstants
// (Single source of truth to avoid duplication)

// MARK: - ═══════════════════════════════════════════════════════════════════
// MARK: - JŌHŌ DEZAIN (Japanese Information Design System)
// MARK: - "Friendly Density" - Dense information that remains scannable
// MARK: - ═══════════════════════════════════════════════════════════════════

// MARK: - App Typography (SF Rounded)
/// Japanese-inspired typography using SF Rounded for friendly, approachable text
enum AppTypography {
    // MARK: - Display (Hero Content)
    /// Large commanding headlines - 34pt bold rounded
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    /// Medium display - 28pt bold rounded
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    /// Small display - 22pt bold rounded
    static let displaySmall = Font.system(size: 22, weight: .bold, design: .rounded)

    // MARK: - Section Headers
    /// Section header text - 17pt semibold rounded
    static let sectionHeader = Font.system(size: 17, weight: .semibold, design: .rounded)
    /// Subsection header - 15pt semibold rounded
    static let subsectionHeader = Font.system(size: 15, weight: .semibold, design: .rounded)

    // MARK: - Body Text
    /// Large body - 17pt regular rounded (primary content)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
    /// Medium body - 15pt regular rounded (secondary content)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .rounded)
    /// Small body - 13pt regular rounded (dense content)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .rounded)

    // MARK: - Labels (Badges & Pills)
    /// Large label - 13pt semibold rounded (primary badges)
    static let labelLarge = Font.system(size: 13, weight: .semibold, design: .rounded)
    /// Medium label - 12pt medium rounded (secondary badges)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .rounded)
    /// Small label - 11pt medium rounded (compact badges)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .rounded)

    // MARK: - Caption (Fine Print)
    /// Caption text - 12pt regular rounded
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    /// Small caption - 11pt regular rounded (metadata)
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .rounded)

    // MARK: - Mono (Numbers & Data)
    /// Monospaced digits for data display
    static let monoLarge = Font.system(size: 17, weight: .medium, design: .monospaced)
    static let monoMedium = Font.system(size: 15, weight: .medium, design: .monospaced)
    static let monoSmall = Font.system(size: 13, weight: .medium, design: .monospaced)
}

// MARK: - Color Zones
/// Feature-based color system - each area gets a distinct hue for instant recognition
enum ColorZone: CaseIterable {
    case calendar    // Blue - time & dates
    case notes       // Amber/Yellow - personal thoughts
    case expenses    // Green - money & finances
    case trips       // Orange - travel & journeys
    case holidays    // Red/Pink - celebrations
    case contacts    // Purple - people & connections
    case settings    // Gray - configuration

    /// Primary zone color (full saturation)
    var primary: Color {
        switch self {
        case .calendar:  return Color(hex: "3B82F6")  // Vibrant blue
        case .notes:     return Color(hex: "F59E0B")  // Warm amber
        case .expenses:  return Color(hex: "10B981")  // Fresh green
        case .trips:     return Color(hex: "F97316")  // Energetic orange
        case .holidays:  return Color(hex: "EF4444")  // Festive red
        case .contacts:  return Color(hex: "8B5CF6")  // Friendly purple
        case .settings:  return Color(hex: "6B7280")  // Neutral gray
        }
    }

    /// Background tint (10% opacity for cards/sections)
    var background: Color {
        primary.opacity(0.10)
    }

    /// Badge background (slightly more visible)
    var badge: Color {
        primary.opacity(0.15)
    }

    /// Subtle border color
    var border: Color {
        primary.opacity(0.20)
    }

    /// Icon for the zone
    var icon: String {
        switch self {
        case .calendar:  return "calendar"
        case .notes:     return "note.text"
        case .expenses:  return "creditcard"
        case .trips:     return "airplane"
        case .holidays:  return "gift"
        case .contacts:  return "person.2"
        case .settings:  return "gearshape"
        }
    }

    /// Display name for the zone
    var displayName: String {
        switch self {
        case .calendar:  return "Calendar"
        case .notes:     return "Notes"
        case .expenses:  return "Expenses"
        case .trips:     return "Trips"
        case .holidays:  return "Holidays"
        case .contacts:  return "Contacts"
        case .settings:  return "Settings"
        }
    }
}

// MARK: - Corner Radius System
/// Japanese-inspired rounded corners - very friendly and approachable
enum CornerRadius {
    /// Small elements (badges, small buttons) - 8pt
    static let small: CGFloat = 8
    /// Medium elements (cards, boxes) - 12pt
    static let medium: CGFloat = 12
    /// Large elements (panels, sheets) - 16pt
    static let large: CGFloat = 16
    /// Extra large (modal sheets) - 20pt
    static let extraLarge: CGFloat = 20
    /// Pill/capsule shapes - 100pt (effectively full round)
    static let pill: CGFloat = 100
}

// MARK: - Category Badge Component
/// Pill-shaped label like Japanese packaging tags
struct CategoryBadge: View {
    let text: String
    let color: Color
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small:  return AppTypography.labelSmall
            case .medium: return AppTypography.labelMedium
            case .large:  return AppTypography.labelLarge
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small:  return 8
            case .medium: return 10
            case .large:  return 12
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small:  return 3
            case .medium: return 4
            case .large:  return 5
            }
        }
    }

    var body: some View {
        Text(text.uppercased())
            .font(size.font)
            .fontWeight(.bold)
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(color, in: Capsule())
    }
}

// MARK: - Zone Badge Component
/// Badge that automatically uses the zone's color
struct ZoneBadge: View {
    let zone: ColorZone
    var text: String?
    var size: CategoryBadge.BadgeSize = .medium

    var body: some View {
        CategoryBadge(
            text: text ?? zone.displayName,
            color: zone.primary,
            size: size
        )
    }
}

// MARK: - Info Box Component
/// Compartmentalized section like Japanese packaging info boxes
struct InfoBox<Content: View>: View {
    let title: String
    let color: Color
    let content: Content
    var showBorder: Bool = true

    init(
        title: String,
        color: Color,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.color = color
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(AppTypography.labelLarge)
                .tracking(0.5)
                .foregroundStyle(color)

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(showBorder ? color.opacity(0.2) : .clear, lineWidth: 1)
        )
    }
}

// MARK: - Zone Info Box
/// InfoBox that automatically uses the zone's color
struct ZoneInfoBox<Content: View>: View {
    let zone: ColorZone
    var title: String?
    var showBorder: Bool = true
    let content: Content

    init(
        zone: ColorZone,
        title: String? = nil,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.zone = zone
        self.title = title
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
        InfoBox(
            title: title ?? zone.displayName,
            color: zone.primary,
            showBorder: showBorder
        ) {
            content
        }
    }
}

// MARK: - Zoned Section Header
/// Section header with colored badge - Japanese-style category marker
struct ZonedSectionHeader: View {
    let title: String
    let zone: ColorZone
    var showBadge: Bool = true
    var trailingContent: AnyView?

    init(
        _ title: String,
        zone: ColorZone,
        showBadge: Bool = true,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.zone = zone
        self.showBadge = showBadge
        self.trailingContent = AnyView(trailing())
    }

    var body: some View {
        HStack(spacing: 8) {
            if showBadge {
                ZoneBadge(zone: zone, size: .small)
            }

            Text(title)
                .font(AppTypography.sectionHeader)
                .foregroundStyle(SlateColors.primaryText)

            Spacer()

            trailingContent
        }
    }
}

// MARK: - Zone Card
/// Card with zone-colored accent
struct ZoneCard<Content: View>: View {
    let zone: ColorZone
    var showAccent: Bool = true
    let content: Content

    init(
        zone: ColorZone,
        showAccent: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.zone = zone
        self.showAccent = showAccent
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            if showAccent {
                Rectangle()
                    .fill(zone.primary)
                    .frame(width: 4)
            }

            content
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(SlateColors.mediumSlate)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}

// MARK: - Metric Display
/// Compact metric display like Japanese product specifications
struct MetricDisplay: View {
    let label: String
    let value: String
    var unit: String?
    var color: Color = SlateColors.primaryText

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(AppTypography.captionSmall)
                .tracking(0.5)
                .foregroundStyle(SlateColors.tertiaryText)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTypography.monoLarge)
                    .foregroundStyle(color)

                if let unit = unit {
                    Text(unit)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(SlateColors.secondaryText)
                }
            }
        }
    }
}

// MARK: - Dense Row
/// Compact row for dense information display
struct DenseRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    var trailing: String?
    var iconColor: Color = SlateColors.secondaryText

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(SlateColors.primaryText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(SlateColors.tertiaryText)
                }
            }

            Spacer()

            if let trailing = trailing {
                Text(trailing)
                    .font(AppTypography.monoMedium)
                    .foregroundStyle(SlateColors.secondaryText)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - View Extensions for Zones
extension View {
    /// Apply zone-colored background tint
    func zoneBackground(_ zone: ColorZone) -> some View {
        self.background(zone.background)
    }

    /// Apply zone-colored border
    func zoneBorder(_ zone: ColorZone, width: CGFloat = 1) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(zone.border, lineWidth: width)
        )
    }

    /// Clip with standard corner radius
    func roundedCorners(_ radius: CGFloat = CornerRadius.medium) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

