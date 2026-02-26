//
//  JohoComponents.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Authentic Japanese Packaging Style
//  Inspired by Muhi, Rohto, and classic Japanese OTC medicine packaging
//

import SwiftUI

// MARK: - Bordered Squircle Container
// The CORE component - colored background + thick black border

struct JohoContainer<Content: View>: View {
    let zone: SectionZone?
    let backgroundColor: Color?
    var borderWidth: CGFloat = JohoDimensions.borderMedium
    var cornerRadius: CGFloat = JohoDimensions.radiusLarge
    var padding: CGFloat = JohoDimensions.spacingMD
    @ViewBuilder let content: Content

    init(
        zone: SectionZone? = nil,
        backgroundColor: Color? = nil,
        borderWidth: CGFloat = JohoDimensions.borderMedium,
        cornerRadius: CGFloat = JohoDimensions.radiusLarge,
        padding: CGFloat = JohoDimensions.spacingMD,
        @ViewBuilder content: () -> Content
    ) {
        self.zone = zone
        self.backgroundColor = backgroundColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    @Environment(\.johoColorMode) private var colorMode

    private var fillColor: Color {
        if let bg = backgroundColor { return bg }
        if let z = zone { return z.background(for: colorMode) }
        return JohoScheme.colors(for: colorMode).surface
    }

    var body: some View {
        let colors = JohoScheme.colors(for: colorMode)
        content
            .padding(padding)
            .background(fillColor)
            .johoBordered(cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: colors.border)
    }
}

// MARK: - Pill Label (ラベル)
// Inverted color pills like Japanese packaging badges

struct JohoPill: View {
    let text: String
    var style: PillStyle = .blackOnWhite
    var size: PillSize = .medium
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    enum PillStyle {
        case blackOnWhite   // Surface pill, primary border, primary text
        case whiteOnBlack   // Primary pill, inverted text (most common)
        case colored(Color) // 情報デザイン: Surface pill, colored border, colored text (NOT inverted!)
        case coloredInverted(Color) // Inverted: Colored bg, appropriate text (use sparingly)
        case muted          // Muted background, muted text - for past dates (YESTERDAY, X DAYS AGO)
    }

    enum PillSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small: return JohoFont.labelSmall
            case .medium: return JohoFont.label
            case .large: return JohoFont.subheadline
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 3
            case .medium: return 5
            case .large: return 7
            }
        }
    }

    var body: some View {
        Text(text.uppercased())
            .font(size.font)
            .tracking(0.5)
            .foregroundStyle(textColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(backgroundView)
    }

    private var textColor: Color {
        switch style {
        case .blackOnWhite: return colors.primary
        case .whiteOnBlack: return colors.primaryInverted
        case .colored(let color): return color  // 情報デザイン: Colored text on surface
        case .coloredInverted(let color):
            // 情報デザイン: Black text on light backgrounds (yellow), white on dark
            return color == JohoColors.yellow ? JohoColors.black : JohoColors.white
        case .muted: return colors.primary.opacity(JohoDimensions.opacityStrong)  // Muted text for past dates
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .blackOnWhite:
            Capsule()
                .fill(colors.surface)
                .overlay(Capsule().stroke(colors.border, lineWidth: 2))
        case .whiteOnBlack:
            Capsule()
                .fill(colors.primary)
        case .colored(let color):
            // 情報デザイン: Surface background, COLORED border (not inverted!)
            Capsule()
                .fill(colors.surface)
                .overlay(Capsule().stroke(color, lineWidth: 1.5))
        case .coloredInverted(let color):
            // Inverted style (use sparingly)
            Capsule()
                .fill(color)
                .overlay(Capsule().stroke(colors.border, lineWidth: 1.5))
        case .muted:
            // Muted gray for past dates (YESTERDAY, X DAYS AGO)
            Capsule()
                .fill(colors.primary.opacity(JohoDimensions.opacitySubtle))
                .overlay(Capsule().stroke(colors.border.opacity(JohoDimensions.opacityMedium), lineWidth: 1.5))
        }
    }
}

// MARK: - Indicator Circle (型別指示器)
// 情報デザイン: Type indicator circles ALWAYS have BLACK borders
// Used in: calendar grid, collapsed rows, legend, expanded sections

struct JohoIndicatorCircle: View {
    let color: Color
    var size: JohoIndicatorSize = .medium
    var isFilled: Bool = true  // Filled = primary (●), Outlined = secondary (○)
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    enum JohoIndicatorSize {
        case tiny      // 5pt - calendar grid indicators
        case small     // 7pt - calendar day cells
        case medium    // 10pt - expanded section items
        case large     // 12pt - legend popover
        case xlarge    // 24pt - legend header

        var dimension: CGFloat {
            switch self {
            case .tiny: return 5
            case .small: return 7
            case .medium: return 10
            case .large: return 12
            case .xlarge: return 24
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .tiny: return 0.5
            case .small: return 1
            case .medium: return 1.5
            case .large: return 1.5
            case .xlarge: return 2
            }
        }
    }

    var body: some View {
        Circle()
            .fill(isFilled ? color : Color.clear)
            .frame(width: size.dimension, height: size.dimension)
            .overlay(
                Circle()
                    .stroke(isFilled ? colors.border : color, lineWidth: size.borderWidth)
            )
    }
}

// MARK: - Flow Layout (Wrapping horizontal layout)
// 情報デザイン: Chips wrap to next line instead of scrolling

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Wrap to next line if needed
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return (CGSize(width: totalWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Section Box (区画)
// Colored compartment with title pill and thick border

struct JohoSectionBox<Content: View>: View {
    let title: String
    let zone: SectionZone
    // 情報デザイン: Removed redundant icon parameter
    // The pill label already communicates the section type
    // "Every visual element must serve a clear informational purpose."
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // Header with pill label only (情報デザイン: no redundant icon)
            JohoPill(text: title, style: .whiteOnBlack, size: .medium)

            // Content
            content
                .foregroundStyle(colors.primary)
        }
        .padding(JohoDimensions.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(zone.background(for: colorMode))
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
    }
}

// MARK: - Form Section (情報デザイン: Surface background for entry forms)
// Use for Add Trip, Add Expense, etc. - surface background with border

struct JohoFormSection<Content: View>: View {
    let title: String
    var icon: String? = nil
    var accentColor: Color? = nil
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(spacing: 0) {
            // Header row with pill
            HStack(spacing: JohoDimensions.spacingSM) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(colors.primary)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusXS))

                if let icon {
                    Image(systemName: icon)
                        .font(JohoFont.bodySmallBold)
                        .foregroundStyle(accentColor ?? colors.primary)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(colors.surface)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: JohoDimensions.borderMedium)

            // Content area
            content
                .padding(14)
                .background(colors.surface)
        }
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
    }
}

// MARK: - Form Field (情報デザイン: Individual form row)

struct JohoFormField<Content: View>: View {
    let label: String
    var isOptional: Bool = false
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(isOptional ? colors.primary.opacity(JohoDimensions.opacityHeavy) : colors.primary.opacity(JohoDimensions.opacityBold))

            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(colors.surface)
    }
}

// MARK: - Info Card (Surface card with border)
// For list items, detail cards

struct JohoCard<Content: View>: View {
    var cornerRadius: CGFloat = JohoDimensions.radiusMedium
    var borderWidth: CGFloat = JohoDimensions.borderMedium
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        content
            .padding(JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.surface)
            .johoBordered(cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: colors.border)
    }
}

// MARK: - Day Cell (Calendar grid item)

struct JohoDayCell: View {
    let day: Int
    var isToday: Bool = false
    var isSelected: Bool = false
    var hasEvent: Bool = false
    var eventColor: Color = JohoColors.pink
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .fill(backgroundColor)

            // Border (always present, thicker when selected)
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(
                    colors.border,
                    lineWidth: (isToday || isSelected) ? JohoDimensions.borderThick : JohoDimensions.borderThin
                )

            // Day number
            Text("\(day)")
                .font(JohoFont.headline)
                .foregroundStyle(textColor)

            // Event dot
            if hasEvent {
                VStack {
                    Spacer()
                    Circle()
                        .fill(eventColor)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        .padding(.bottom, 4)
                }
            }
        }
        .frame(width: 44, height: 44)
    }

    private var backgroundColor: Color {
        if isSelected { return colors.primary }
        if isToday { return JohoColors.yellow }
        return colors.surface
    }

    private var textColor: Color {
        if isSelected { return colors.primaryInverted }
        if isToday { return JohoColors.black }  // Yellow always gets black text
        return colors.primary
    }
}

// MARK: - Week Badge (Large week number display)

struct JohoWeekBadge: View {
    let weekNumber: Int
    var size: BadgeSize = .large
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    enum BadgeSize {
        case small, medium, large

        var dimension: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 54
            case .large: return 64
            }
        }

        var numberFont: Font {
            switch self {
            case .small: return JohoFont.headline
            case .medium: return JohoFont.displaySmall
            case .large: return JohoFont.displayMedium
            }
        }

        var labelFont: Font {
            switch self {
            case .small: return Font.system(size: 8, weight: .heavy, design: .rounded)
            case .medium: return JohoFont.labelSmall
            case .large: return JohoFont.labelSmall
            }
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("WEEK")
                .font(size.labelFont)
                .foregroundStyle(colors.primaryInverted.opacity(JohoDimensions.opacityDense))

            Text("\(weekNumber)")
                .font(size.numberFont)
                .foregroundStyle(colors.primaryInverted)
        }
        .frame(width: size.dimension, height: size.dimension)
        .background(colors.primary)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 2, borderColor: colors.primaryInverted)
    }
}

// MARK: - List Row

struct JohoListRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    let zone: SectionZone
    var badge: String? = nil
    var showChevron: Bool = true
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Icon in colored squircle
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(zone.textColor(for: colorMode))
                .frame(width: 40, height: 40)
                .background(zone.background(for: colorMode))
                .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin, borderColor: colors.border)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.body)
                    .foregroundStyle(colors.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                }
            }

            Spacer()

            // Optional badge
            if let badge {
                JohoPill(text: badge, style: .whiteOnBlack, size: .small)
            }

            // Chevron
            if showChevron {
                Image(systemName: IconCatalog.chevronRight)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
    }
}

// MARK: - Stat Box (統計)

struct JohoStatBox: View {
    let value: String
    let label: String
    let zone: SectionZone
    var isActive: Bool = true  // 情報デザイン: Visual feedback for filter state
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingXS) {
            Text(value)
                .font(JohoFont.displaySmall)
                .foregroundStyle(zone.textColor(for: colorMode))

            Text(label.uppercased())
                .font(JohoFont.labelSmall)
                .foregroundStyle(zone.textColor(for: colorMode).opacity(JohoDimensions.opacityBold))
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingMD)
        .background(isActive ? zone.background(for: colorMode) : colors.inputBackground)
        .opacity(isActive ? 1.0 : 0.5)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
    }
}

// MARK: - Page Header
// 情報デザイン: Dynamic colors based on color mode

struct JohoPageHeader: View {
    let title: String
    var badge: String? = nil
    var subtitle: String? = nil
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            if let badge {
                JohoPill(text: badge, style: .whiteOnBlack, size: .large)
            }

            Text(title)
                .font(JohoFont.displayMedium)
                .foregroundStyle(colors.primary)

            if let subtitle {
                Text(subtitle)
                    .font(JohoFont.body)
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
    }
}

// MARK: - Editor Header (情報デザイン: Consistent header for all editor sheets)
// Pattern: [Back] [Icon Zone] Title/Subtitle [Save]
// Matches Star Page month detail view header pattern

struct JohoEditorHeader: View {
    let icon: String              // SF Symbol from SpecialDayType.defaultIcon
    let accentColor: Color        // From SpecialDayType.accentColor
    let lightBackground: Color    // From SpecialDayType.lightBackground (explicit light tint)
    let title: String             // e.g., "NEW EVENT" (UPPERCASE)
    let subtitle: String          // e.g., "Set date & details"
    let canSave: Bool             // Validation state for Save button
    let onBack: () -> Void
    let onSave: () -> Void
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(alignment: .center, spacing: JohoDimensions.spacingMD) {
            // Cancel button (44×44pt) - × (batsu) = Cancel in Japanese UI
            Button(action: onBack) {
                Text(JohoSymbols.batsu)  // ×
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .johoTouchTarget()
                    .background(colors.surface)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin, borderColor: colors.border)
            }

            // Icon zone (52×52pt) - matches January 2026 pattern
            JohoSticker(content: .icon(icon), color: accentColor, size: 52)

            // Title area
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.headline)
                    .foregroundStyle(colors.primary)

                Text(subtitle)
                    .font(JohoFont.caption)
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))
            }

            Spacer()

            // Confirm button (44×44pt) - ○ (maru) = Confirm in Japanese UI
            Button(action: onSave) {
                Text(JohoSymbols.maru)  // ○
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(canSave ? colors.primaryInverted : colors.primary.opacity(JohoDimensions.opacityModerate))
                    .johoTouchTarget()
                    .background(canSave ? accentColor : colors.surface)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
            }
            .disabled(!canSave)
        }
        .padding(JohoDimensions.spacingLG)  // 16pt all sides
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
    }
}

// MARK: - Sheet Header (情報デザイン: Consistent header for detail sheets)
// Pattern: [Title] Spacer [ShareButton] [CloseButton]
// Used by RandomFactDetailSheet and Contact QR sheet

struct JohoSheetHeader<ShareButton: View>: View {
    let title: String
    let shareButton: ShareButton
    let onClose: () -> Void
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(colors.primaryInverted)

            Spacer()

            shareButton

            Button { onClose() } label: {
                ZStack {
                    Circle()
                        .fill(colors.surface)
                        .frame(width: 28, height: 28)
                    Image(systemName: IconCatalog.xmark)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(colors.surfaceInverted)
    }
}

// MARK: - Metric Row (for stats display)

struct JohoMetricRow: View {
    let label: String
    let value: String
    var zone: SectionZone = .calendar
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack {
            Text(label)
                .font(JohoFont.body)
                .foregroundStyle(colors.primary)

            Spacer()

            Text(value)
                .font(JohoFont.monoMedium)
                .foregroundStyle(colors.primary)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(zone.background(for: colorMode).opacity(JohoDimensions.opacityMedium))
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
    }
}

// MARK: - Icon Badge (small icon with zone color)

struct JohoIconBadge: View {
    let icon: String
    let zone: SectionZone
    var size: CGFloat = 32
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        JohoSticker(
            content: .icon(icon),
            color: zone.background(for: colorMode),
            size: size,
            borderWidth: JohoDimensions.borderThin
        )
    }
}

// MARK: - JohoSticker (Universal Avatar/Badge Component)

/// Universal sticker component generalizing the contact-avatar badge pattern.
/// Supports circle or squircle shapes, photo/initials/icon content, optional badge overlay.
struct JohoSticker: View {

    /// Content to display inside the sticker
    enum Content {
        case photo(Data)
        case initials(String)
        case icon(String)
        case empty
    }

    /// Shape of the sticker
    enum StickerShape {
        case circle
        case squircle
    }

    /// Optional badge overlay (bottom-right corner)
    struct Badge {
        let icon: String
        let color: Color
    }

    let content: Content
    let color: Color
    var shape: StickerShape = .squircle
    var badge: Badge? = nil
    var size: CGFloat = 56
    var borderWidth: CGFloat? = nil

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var resolvedBorderWidth: CGFloat {
        borderWidth ?? (size >= 80 ? JohoDimensions.borderThick :
                        size < 32 ? JohoDimensions.borderThin :
                        JohoDimensions.borderMedium)
    }

    private var cornerRadius: CGFloat {
        shape == .circle ? size / 2 : size * 0.2
    }

    private var badgeSize: CGFloat {
        size * 0.35
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            mainContent
                .frame(width: size, height: size)
                .clipShape(stickerShape)
                .overlay(stickerShape.stroke(colors.border, lineWidth: resolvedBorderWidth))

            if let badge {
                badgeView(badge)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch content {
        case .photo(let data):
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackContent
            }
        case .initials(let text):
            ZStack {
                color
                Text(text.prefix(2).uppercased())
                    .font(.system(size: size * 0.35, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        case .icon(let systemName):
            ZStack {
                color
                Image(systemName: systemName)
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
            }
        case .empty:
            fallbackContent
        }
    }

    @ViewBuilder
    private var fallbackContent: some View {
        ZStack {
            color
            Image(systemName: IconCatalog.person)
                .font(.system(size: size * 0.4, design: .rounded))
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
        }
    }

    @ViewBuilder
    private func badgeView(_ badge: Badge) -> some View {
        Image(systemName: badge.icon)
            .font(.system(size: badgeSize * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(badge.color)
            .frame(width: badgeSize, height: badgeSize)
            .background(colors.surface)
            .clipShape(Circle())
            .overlay(Circle().stroke(colors.border, lineWidth: 1))
            .offset(x: 2, y: 2)
    }

    private var stickerShape: some InsettableShape {
        shape == .circle
            ? AnyInsettableShape(Circle())
            : AnyInsettableShape(Squircle(cornerRadius: cornerRadius))
    }

    // MARK: - Size Presets

    /// 24pt — bento card headers, compact inline icons
    static func mini(icon: String, color: Color, shape: StickerShape = .squircle) -> JohoSticker {
        JohoSticker(content: .icon(icon), color: color, shape: shape, size: 24)
    }

    /// 32pt — compact list rows, tile icons
    static func small(icon: String, color: Color, shape: StickerShape = .squircle) -> JohoSticker {
        JohoSticker(content: .icon(icon), color: color, shape: shape, size: 32)
    }

    /// 48pt — prominent card icons, fact tiles, shareable card headers
    static func regular(icon: String, color: Color, shape: StickerShape = .squircle) -> JohoSticker {
        JohoSticker(content: .icon(icon), color: color, shape: shape, size: 48)
    }

    /// 80pt — hero displays, empty states
    static func large(icon: String, color: Color, shape: StickerShape = .squircle) -> JohoSticker {
        JohoSticker(content: .icon(icon), color: color, shape: shape, size: 80)
    }
}

/// Type-erased InsettableShape for JohoSticker shape switching
struct AnyInsettableShape: InsettableShape, @unchecked Sendable {
    private let _path: (CGRect) -> Path
    private let _inset: (CGFloat) -> AnyInsettableShape
    private let _strokePath: (CGRect, StrokeStyle) -> Path

    init<S: InsettableShape>(_ shape: S) {
        _path = { shape.path(in: $0) }
        _inset = { AnyInsettableShape(shape.inset(by: $0)) }
        _strokePath = { rect, style in
            shape.path(in: rect).strokedPath(style)
        }
    }

    func path(in rect: CGRect) -> Path { _path(rect) }
    func inset(by amount: CGFloat) -> AnyInsettableShape { _inset(amount) }
}

// MARK: - Icon Button (Actionable circular button with semantic color)

/// 情報デザイン: Unified circular icon button for actions
/// Use semantic colors: cyan=message, purple=email, green=call, orange=trip
struct JohoIconButton: View {
    let icon: String
    let color: Color
    var foregroundColor: Color? = nil  // nil = auto (black on light, white on dark)
    var borderColor: Color? = nil      // nil = black
    var size: CGFloat = 36
    var borderWidth: CGFloat = 1
    let action: () -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// Auto-detect foreground color based on background brightness
    private var effectiveForeground: Color {
        if let fg = foregroundColor { return fg }
        // Dark backgrounds get white text, light backgrounds get black
        return color == colors.primary ? colors.primaryInverted.opacity(JohoDimensions.opacityBold) : colors.primary
    }

    private var effectiveBorder: Color {
        borderColor ?? colors.border
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(effectiveForeground)
                .frame(width: size, height: size)
                .background(color)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(effectiveBorder, lineWidth: borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tile Card (情報デザイン: Colored banner + content, used by month cards and fact tiles)

struct JohoTileCard<Content: View>: View {
    let label: String
    let icon: String
    let iconColor: Color
    let bannerColor: Color
    @ViewBuilder let content: Content

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(spacing: 0) {
            // Banner: label left + circle sticker right
            HStack {
                Text(label.uppercased())
                    .font(JohoFont.pillLabel)
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                Spacer()

                JohoSticker(content: .icon(icon), color: iconColor, shape: .circle, size: 24)
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(bannerColor)

            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            content
        }
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 1.5)
    }
}

// MARK: - Search Field (情報デザイン styled search input)

/// 情報デザイン: Unified search field with squircle styling
struct JohoSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var zone: SectionZone = .calendar

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: IconCatalog.search)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))

            TextField(placeholder, text: $text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)

            if text.isNotEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: IconCatalog.xmarkCircleFill)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM + 2)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin)
    }
}

// MARK: - Contact Action Buttons (Semantic action buttons for contacts)

/// 情報デザイン: Pre-configured contact action buttons
enum JohoContactAction {
    case message(phone: String)
    case email(address: String)
    case call(phone: String)

    var icon: String {
        switch self {
        case .message: return "message.fill"
        case .email: return "envelope.fill"
        case .call: return "phone.fill"
        }
    }

    var color: Color {
        switch self {
        case .message: return JohoColors.cyan
        case .email: return JohoColors.purple
        case .call: return JohoColors.green
        }
    }

    func execute() {
        let urlString: String
        switch self {
        case .message(let phone):
            urlString = "sms:\(phone)"
        case .email(let address):
            urlString = "mailto:\(address)"
        case .call(let phone):
            urlString = "tel:\(phone)"
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct JohoContactActionButton: View {
    let action: JohoContactAction

    var body: some View {
        JohoIconButton(
            icon: action.icon,
            color: action.color,
            size: 36,
            borderWidth: 1
        ) {
            action.execute()
        }
    }
}

// MARK: - Toggle Row

struct JohoToggleRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    let zone: SectionZone
    @Binding var isOn: Bool
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            JohoIconBadge(icon: icon, zone: zone, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.body)
                    .foregroundStyle(colors.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(zone.background(for: colorMode))
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
    }
}

// MARK: - Divider

struct JohoDivider: View {
    var weight: CGFloat = 2
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        Rectangle()
            .fill(colors.border)
            .frame(height: weight)
    }
}

// MARK: - Country Color Scheme (情報デザイン: National colors as text pills)

struct CountryColorScheme {
    let backgroundColor: Color
    let textColor: Color
    let borderColor: Color
    let code: String  // 3-letter country code

    /// Get color scheme for a region code
    static func scheme(for region: String) -> CountryColorScheme? {
        switch region.uppercased() {
        case "SE": // Sweden: Dark blue pill, yellow text, black border
            return CountryColorScheme(
                backgroundColor: Color(hex: "004B87"),
                textColor: Color(hex: "FECC00"),
                borderColor: JohoColors.black,
                code: "SWE"
            )
        case "NORDIC": // Nordic: Dark blue pill, white text (Nordic Council colors)
            return CountryColorScheme(
                backgroundColor: Color(hex: "003087"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "NORD"
            )
        case "NO": // Norway: Red pill, white text (Norwegian flag)
            return CountryColorScheme(
                backgroundColor: Color(hex: "BA0C2F"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "00205B"),
                code: "NOR"
            )
        case "DK": // Denmark: Red pill, white text (Dannebrog)
            return CountryColorScheme(
                backgroundColor: Color(hex: "C8102E"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "DK"
            )
        case "FI": // Finland: Blue pill, white text (Siniristilippu)
            return CountryColorScheme(
                backgroundColor: Color(hex: "003580"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "FI"
            )
        case "US": // USA: Navy blue pill, white text, black border
            return CountryColorScheme(
                backgroundColor: Color(hex: "3C3B6E"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "USA"
            )
        case "VN": // Vietnam: Red pill, yellow text, black border
            return CountryColorScheme(
                backgroundColor: Color(hex: "DA251D"),
                textColor: Color(hex: "FFCD00"),
                borderColor: JohoColors.black,
                code: "VN"
            )
        case "DE": // Germany: Black pill, yellow text (Schwarz-Rot-Gold)
            return CountryColorScheme(
                backgroundColor: Color(hex: "000000"),
                textColor: Color(hex: "FFCC00"),
                borderColor: Color(hex: "DD0000"),
                code: "DE"
            )
        case "GB": // United Kingdom: Navy blue pill, white text (Union Jack)
            return CountryColorScheme(
                backgroundColor: Color(hex: "012169"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "C8102E"),
                code: "UK"
            )
        case "FR": // France: Blue pill, white text (Tricolore)
            return CountryColorScheme(
                backgroundColor: Color(hex: "002395"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "ED2939"),
                code: "FR"
            )
        case "IT": // Italy: Green pill, white text (Il Tricolore)
            return CountryColorScheme(
                backgroundColor: Color(hex: "008C45"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "CD212A"),
                code: "IT"
            )
        case "NL": // Netherlands: Orange pill, white text (Oranje)
            return CountryColorScheme(
                backgroundColor: Color(hex: "AE1C28"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "21468B"),
                code: "NL"
            )
        case "JP": // Japan: Red pill, white text (Hinomaru)
            return CountryColorScheme(
                backgroundColor: Color(hex: "BC002D"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "JP"
            )
        case "HK": // Hong Kong: Red pill, white text (Bauhinia)
            return CountryColorScheme(
                backgroundColor: Color(hex: "DE2910"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "HK"
            )
        case "CN": // China: Red pill, yellow text (五星红旗)
            return CountryColorScheme(
                backgroundColor: Color(hex: "DE2910"),
                textColor: Color(hex: "FFDE00"),
                borderColor: JohoColors.black,
                code: "CN"
            )
        case "TH": // Thailand: Blue pill, white text (ธงไตรรงค์)
            return CountryColorScheme(
                backgroundColor: Color(hex: "241D4F"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "A51931"),
                code: "TH"
            )
        default:
            return nil
        }
    }
}

/// 情報デザイン country indicator pill with text (replaces emoji flags)
struct CountryPill: View {
    let region: String

    var body: some View {
        if let scheme = CountryColorScheme.scheme(for: region) {
            Text(scheme.code)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(scheme.textColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(scheme.backgroundColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(scheme.borderColor, lineWidth: 1.5))
        }
    }
}

// MARK: - 情報デザイン Toggle

/// Standard 情報デザイン toggle switch with border
struct JohoToggle: View {
    @Binding var isOn: Bool
    var accentColor: Color = JohoColors.cyan
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
            HapticManager.selection()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? accentColor : colors.primary.opacity(JohoDimensions.opacityMild))
                    .frame(width: 50, height: 28)
                    .overlay(
                        Capsule()
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                    )

                Circle()
                    .fill(colors.surface)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Empty State

struct JohoEmptyState: View {
    let title: String
    let message: String
    let icon: String
    let zone: SectionZone
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            JohoSticker.large(icon: icon, color: zone.background(for: colorMode))

            Text(title)
                .font(JohoFont.headline)
                .foregroundStyle(colors.primary)

            Text(message)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))
                .multilineTextAlignment(.center)
        }
        .padding(JohoDimensions.spacingXL)
    }
}

// MARK: - String Extensions (情報デザイン Utilities)

extension String {
    /// Trimmed string with whitespace and newlines removed
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Check if trimmed string is empty
    var isTrimmedEmpty: Bool {
        trimmed.isEmpty
    }
}

// MARK: - Collection Extensions (情報デザイン Utilities)

extension Collection {
    /// More readable alternative to !isEmpty
    var isNotEmpty: Bool { !isEmpty }
}

// MARK: - Preview

#Preview("Joho Components") {
    ScrollView {
        VStack(spacing: JohoDimensions.spacingLG) {
            JohoPageHeader(
                title: "December 2025",
                badge: "WEEK 52",
                subtitle: "Year's end approaching"
            )

            JohoWeekBadge(weekNumber: 52)

            JohoSectionBox(title: "Holidays", zone: .holidays) {
                Text("Christmas Eve")
                    .font(JohoFont.body)
                Text("Boxing Day")
                    .font(JohoFont.body)
            }

            JohoSectionBox(title: "Notes", zone: .notes) {
                Text("Remember to buy gifts")
                    .font(JohoFont.body)
            }

            JohoCard {
                VStack(spacing: JohoDimensions.spacingXS) {
                    JohoPill(text: "Total", style: .whiteOnBlack)
                    Text("$1,234.56")
                        .font(JohoFont.displayLarge)
                        .foregroundStyle(JohoColors.black)
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: JohoDimensions.spacingSM) {
                JohoStatBox(value: "$456", label: "Food", zone: .trips)
                JohoStatBox(value: "$523", label: "Hotel", zone: .contacts)
                JohoStatBox(value: "$255", label: "Transit", zone: .expenses)
            }

            JohoListRow(
                title: "Flight to Tokyo",
                subtitle: "Dec 25 - Jan 2",
                icon: "airplane",
                zone: .trips,
                badge: "8 DAYS"
            )

            JohoListRow(
                title: "Christmas Party",
                subtitle: "December 24, 2025",
                icon: "star.fill",
                zone: .holidays
            )

            HStack(spacing: JohoDimensions.spacingSM) {
                JohoDayCell(day: 24, isToday: true, hasEvent: true)
                JohoDayCell(day: 25, hasEvent: true, eventColor: JohoColors.pink)
                JohoDayCell(day: 26, isSelected: true)
                JohoDayCell(day: 27)
            }
        }
        .padding(JohoDimensions.spacingLG)
    }
    .johoBackground()
}
