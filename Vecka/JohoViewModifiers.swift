//
//  JohoViewModifiers.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Authentic Japanese Packaging Style
//  Inspired by Muhi, Rohto, and classic Japanese OTC medicine packaging
//

import SwiftUI

// MARK: - 情報デザイン ViewModifier Implementations
// Pattern from Swift Playgrounds "Laying Out Views" ThemeViews.swift

/// Background modifier — always true black (AMOLED optimized)
struct JohoBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(hex: "000000"))
            .scrollContentBackground(.hidden)
    }
}

/// Navigation bar modifier that adapts to color mode
struct JohoNavigationModifier: ViewModifier {
    let title: String
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(colors.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorMode == .dark ? .light : .dark, for: .navigationBar)
    }
}

/// List style modifier that adapts to color mode
struct JohoListStyleModifier: ViewModifier {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(colors.canvas)
    }
}

/// Bento box card modifier - white background with black border
struct JohoBentoModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(colors.surface)
            .johoBordered(
                cornerRadius: cornerRadius,
                borderWidth: borderWidth,
                borderColor: colors.border
            )
    }
}

/// Accented bento box modifier - colored background tint with black border
struct JohoAccentedBentoModifier: ViewModifier {
    let accentColor: Color
    let opacity: Double
    let padding: CGFloat
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(accentColor.opacity(opacity))
            .johoBordered(
                cornerRadius: cornerRadius,
                borderWidth: borderWidth,
                borderColor: colors.border
            )
    }
}

/// Section header modifier - colored background strip
struct JohoSectionHeaderModifier: ViewModifier {
    let accentColor: Color
    let opacity: Double
    let height: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accentColor.opacity(opacity))
    }
}

/// Interactive cell modifier - for tappable items with selection state
struct JohoInteractiveCellModifier: ViewModifier {
    let isSelected: Bool
    let isHighlighted: Bool
    let cornerRadius: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var backgroundColor: Color {
        if isSelected { return colors.primary }
        if isHighlighted { return colors.primary.opacity(JohoDimensions.opacitySubtle) }
        return colors.surface
    }

    private var borderWidth: CGFloat {
        isSelected ? JohoDimensions.borderThick : JohoDimensions.borderMedium
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .johoBordered(
                cornerRadius: cornerRadius,
                borderWidth: borderWidth,
                borderColor: colors.border
            )
    }
}

/// Icon badge modifier - colored icon container
struct JohoIconBadgeModifier: ViewModifier {
    let backgroundColor: Color
    let size: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(colors.primary)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .johoBordered(
                cornerRadius: size * 0.25,
                borderWidth: JohoDimensions.borderThin,
                borderColor: colors.border
            )
    }
}

/// Pill styling modifier - capsule with optional border
struct JohoPillModifier: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color?

    func body(content: Content) -> some View {
        content
            .font(JohoFont.label)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Group {
                    if let border = borderColor {
                        Capsule().stroke(border, lineWidth: 1.5)
                    }
                }
            )
    }
}

// MARK: - Extended Page Header (Dynamic Island integration)

/// Page header modifier that extends behind the Dynamic Island.
/// Uses `.ignoresSafeArea(.container, edges: .top)` on background/overlay only,
/// so content stays in the safe area while the card visually extends upward.
struct JohoExtendedPageHeaderModifier: ViewModifier {
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .background {
                Squircle(cornerRadius: cornerRadius)
                    .fill(colors.surface)
                    .ignoresSafeArea(.container, edges: .top)
            }
            .overlay {
                Squircle(cornerRadius: cornerRadius)
                    .strokeBorder(colors.border, lineWidth: borderWidth)
                    .ignoresSafeArea(.container, edges: .top)
            }
    }
}

// MARK: - View Extensions

/// Environment-aware border modifier — resolves border color from JohoScheme automatically
private struct JohoBorderedModifier: ViewModifier {
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let explicitBorderColor: Color?

    @Environment(\.johoColorMode) private var colorMode

    func body(content: Content) -> some View {
        let resolvedColor = explicitBorderColor ?? JohoScheme.colors(for: colorMode).border
        content
            .clipShape(Squircle(cornerRadius: cornerRadius))
            .overlay(
                Squircle(cornerRadius: cornerRadius)
                    .strokeBorder(resolvedColor, lineWidth: borderWidth)
            )
    }
}

extension View {
    /// 情報デザイン: Apply squircle clip with border in one modifier
    /// Automatically resolves border color from JohoScheme (environment-aware)
    /// Pass explicit borderColor only to override the scheme color
    func johoBordered(
        cornerRadius: CGFloat = JohoDimensions.radiusMedium,
        borderWidth: CGFloat = JohoDimensions.borderMedium,
        borderColor: Color? = nil
    ) -> some View {
        modifier(JohoBorderedModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            explicitBorderColor: borderColor
        ))
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 情報デザイン ViewModifier Pattern Extensions
    // Inspired by Swift Playgrounds ThemeViews.swift ViewModifier pattern
    // ═══════════════════════════════════════════════════════════════════════════

    /// 情報デザイン: Bento box card styling
    /// White background with black border - the core card pattern
    /// Usage: `.johoBento()` or `.johoBento(padding: 16, cornerRadius: 16)`
    func johoBento(
        padding: CGFloat = JohoDimensions.spacingMD,
        cornerRadius: CGFloat = JohoDimensions.radiusMedium,
        borderWidth: CGFloat = JohoDimensions.borderMedium
    ) -> some View {
        modifier(JohoBentoModifier(
            padding: padding,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth
        ))
    }

    /// 情報デザイン: Accented bento box with semantic color
    /// Colored background tint with black border
    /// Usage: `.johoAccentedBento(color: JohoColors.cyan)`
    func johoAccentedBento(
        color: Color,
        opacity: Double = 0.15,
        padding: CGFloat = JohoDimensions.spacingMD,
        cornerRadius: CGFloat = JohoDimensions.radiusMedium,
        borderWidth: CGFloat = JohoDimensions.borderMedium
    ) -> some View {
        modifier(JohoAccentedBentoModifier(
            accentColor: color,
            opacity: opacity,
            padding: padding,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth
        ))
    }

    /// 情報デザイン: Section header styling
    /// Colored background header strip for bento sections
    /// Usage: `.johoSectionHeader(color: JohoColors.cyan)`
    func johoSectionHeader(
        color: Color,
        opacity: Double = 0.3,
        height: CGFloat = 32
    ) -> some View {
        modifier(JohoSectionHeaderModifier(
            accentColor: color,
            opacity: opacity,
            height: height
        ))
    }

    /// 情報デザイン: Interactive cell styling
    /// For tappable list items and buttons with hover/press states
    /// Usage: `.johoInteractiveCell()` or `.johoInteractiveCell(isSelected: true)`
    func johoInteractiveCell(
        isSelected: Bool = false,
        isHighlighted: Bool = false,
        cornerRadius: CGFloat = JohoDimensions.radiusMedium
    ) -> some View {
        modifier(JohoInteractiveCellModifier(
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            cornerRadius: cornerRadius
        ))
    }

    /// 情報デザイン: Icon badge styling
    /// Colored icon container with border
    /// Usage: `.johoIconBadge(color: JohoColors.cyan, size: 40)`
    func johoIconBadge(
        color: Color,
        size: CGFloat = 32
    ) -> some View {
        modifier(JohoIconBadgeModifier(
            backgroundColor: color,
            size: size
        ))
    }

    /// 情報デザイン: Pill/tag styling
    /// Capsule shape with border for labels and tags
    /// Usage: `.johoPillStyle(color: JohoColors.black)`
    func johoPillStyle(
        backgroundColor: Color = JohoColors.black,
        foregroundColor: Color = JohoColors.white,
        borderColor: Color? = nil
    ) -> some View {
        modifier(JohoPillModifier(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            borderColor: borderColor
        ))
    }

    /// 情報デザイン: Page header that extends behind Dynamic Island
    /// Replaces `.background(colors.surface)` + `.johoBordered()` on page headers
    func johoExtendedPageHeader(
        cornerRadius: CGFloat = JohoDimensions.radiusLarge,
        borderWidth: CGFloat = JohoDimensions.borderThick
    ) -> some View {
        modifier(JohoExtendedPageHeaderModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth
        ))
    }

    /// 情報デザイン: Minimum 44×44pt touch target (Apple HIG requirement)
    func johoTouchTarget(_ size: CGFloat = 44) -> some View {
        frame(width: size, height: size)
    }

    /// Apply dark Joho background (respects user's AMOLED preference and color mode)
    func johoBackground() -> some View {
        modifier(JohoBackgroundModifier())
    }

    /// Standard Joho navigation bar styling
    func johoNavigation(title: String = "") -> some View {
        modifier(JohoNavigationModifier(title: title))
    }

    /// Joho List styling
    func johoListStyle() -> some View {
        modifier(JohoListStyleModifier())
    }
}

#Preview("ViewModifier Pattern") {
    ScrollView {
        VStack(spacing: JohoDimensions.spacingLG) {
            // MARK: - johoBento() modifier
            Text("johoBento()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(JohoDimensions.opacityHeavy))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("Basic Bento Card")
                    .font(JohoFont.headline)
                Text("White background with black border")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(JohoDimensions.opacityStrong))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .johoBento()

            // MARK: - johoAccentedBento() modifier
            Text("johoAccentedBento()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(JohoDimensions.opacityHeavy))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: JohoDimensions.spacingSM) {
                VStack {
                    Image(systemName: IconCatalog.calendar)
                    Text("CYAN")
                        .font(JohoFont.labelSmall)
                }
                .frame(maxWidth: .infinity)
                .johoAccentedBento(color: JohoColors.cyan)

                VStack {
                    Image(systemName: IconCatalog.star)
                    Text("PINK")
                        .font(JohoFont.labelSmall)
                }
                .frame(maxWidth: .infinity)
                .johoAccentedBento(color: JohoColors.pink)

                VStack {
                    Image(systemName: IconCatalog.dollarsign)
                    Text("GREEN")
                        .font(JohoFont.labelSmall)
                }
                .frame(maxWidth: .infinity)
                .johoAccentedBento(color: JohoColors.green)
            }

            // MARK: - johoInteractiveCell() modifier
            Text("johoInteractiveCell()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(JohoDimensions.opacityHeavy))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: JohoDimensions.spacingSM) {
                HStack {
                    Text("Normal Cell")
                    Spacer()
                    Image(systemName: IconCatalog.chevronRight)
                }
                .padding(JohoDimensions.spacingMD)
                .johoInteractiveCell()

                HStack {
                    Text("Selected Cell")
                    Spacer()
                    Image(systemName: IconCatalog.checkmark)
                }
                .padding(JohoDimensions.spacingMD)
                .foregroundStyle(JohoColors.white)
                .johoInteractiveCell(isSelected: true)

                HStack {
                    Text("Highlighted Cell")
                    Spacer()
                    Image(systemName: IconCatalog.handTap)
                }
                .padding(JohoDimensions.spacingMD)
                .johoInteractiveCell(isHighlighted: true)
            }

            // MARK: - johoIconBadge() modifier
            Text("johoIconBadge()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(JohoDimensions.opacityHeavy))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: JohoDimensions.spacingMD) {
                Image(systemName: IconCatalog.trip)
                    .johoIconBadge(color: JohoColors.cyan, size: 40)

                Image(systemName: IconCatalog.gift)
                    .johoIconBadge(color: JohoColors.pink, size: 40)

                Image(systemName: IconCatalog.memo)
                    .johoIconBadge(color: JohoColors.yellow, size: 40)

                Image(systemName: IconCatalog.person)
                    .johoIconBadge(color: JohoColors.purple, size: 40)
            }

            // MARK: - johoPillStyle() modifier
            Text("johoPillStyle()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(JohoDimensions.opacityHeavy))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: JohoDimensions.spacingSM) {
                Text("DEFAULT")
                    .johoPillStyle()

                Text("CYAN")
                    .johoPillStyle(
                        backgroundColor: JohoColors.cyan,
                        foregroundColor: JohoColors.black,
                        borderColor: JohoColors.black
                    )

                Text("OUTLINED")
                    .johoPillStyle(
                        backgroundColor: .clear,
                        foregroundColor: JohoColors.black,
                        borderColor: JohoColors.black
                    )
            }
        }
        .padding(JohoDimensions.spacingLG)
    }
    .johoBackground()
}
