//
//  ShareableCard.swift
//  Vecka
//
//  情報デザイン: Shared patterns for shareable card components
//  Extracts common patterns from ShareableDaySummary, ShareableContact, ShareableCountdown, ShareableFact
//

import SwiftUI
import UIKit
import CoreTransferable

// MARK: - Card Snapshot Renderer

/// Utility for rendering any View to PNG data
/// Used by all Transferable snapshot types
@available(iOS 16.0, *)
enum CardSnapshotRenderer {
    /// Renders a view to PNG data at 3x scale
    /// - Parameters:
    ///   - view: The SwiftUI view to render
    ///   - size: The target size (width required, height 0 = dynamic)
    ///   - scale: The render scale (default 3.0 for crisp sharing)
    /// - Returns: PNG data or empty Data if rendering fails
    @MainActor
    static func renderToPNG<V: View>(_ view: V, size: CGSize, scale: CGFloat = 3.0) -> Data {
        let content = view
            .frame(width: size.width)
            .fixedSize(horizontal: false, vertical: true)
        
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        renderer.isOpaque = false  // 情報デザイン: Allow transparency for rounded corners
        
        guard let uiImage = renderer.uiImage else {
            return Data()
        }
        
        return uiImage.pngData() ?? Data()
    }
}

// MARK: - Shareable Card Content Protocol

/// Protocol for views that provide content for shareable cards
/// Shareable cards follow a consistent structure:
/// - Header: App branding + icon
/// - Content: Customizable middle section
/// - Footer: Branding labels
protocol ShareableCardContent: View {
    /// Icon displayed in header right compartment
    var headerIcon: String { get }
    
    /// Color for header icon and accents
    var headerIconColor: Color { get }
    
    /// Background color for header bar
    var headerAccentColor: Color { get }
    
    /// Left footer label (e.g. "DAY SUMMARY", "CONTACT CARD")
    var footerLeftLabel: String { get }
    
    /// Right footer label (e.g. "ONSEN PLANNER", "情報")
    var footerRightLabel: String { get }
}

// MARK: - Shareable Card Shell

/// The outer shell for all shareable cards
/// Provides consistent 3-layer structure: background, content, border
/// Content is injected via ViewBuilder closure
struct ShareableCardShell<Content: View>: View {
    let headerIcon: String
    let headerIconColor: Color
    let headerAccentColor: Color
    let footerLeftLabel: String
    let footerRightLabel: String
    @ViewBuilder let content: () -> Content
    
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    
    private let cornerRadius: CGFloat = 16
    
    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
    
    var body: some View {
        // 情報デザイン: 3-layer ZStack pattern
        ZStack {
            // Layer 1: Solid background (fills squircle corners)
            cardShape
                .fill(colors.surface)
            
            // Layer 2: Content compartments
            VStack(spacing: 0) {
                // Header bar
                ShareableCardHeader(
                    icon: headerIcon,
                    iconColor: headerIconColor,
                    accentColor: headerAccentColor
                )
                
                // Content (injected)
                content()
                
                // Footer bar
                ShareableCardFooter(
                    leftLabel: footerLeftLabel,
                    rightLabel: footerRightLabel
                )
            }
            .clipShape(cardShape)
            
            // Layer 3: Border (strokeBorder keeps it inside the shape)
            cardShape
                .strokeBorder(colors.border, lineWidth: 3)
        }
    }
}

// MARK: - Shareable Card Header

/// Standard header bar for shareable cards
/// LEFT: App branding | WALL | RIGHT: Icon
struct ShareableCardHeader: View {
    let icon: String
    let iconColor: Color
    let accentColor: Color
    
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT: App branding
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: IconCatalog.event)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)

                Text("ONSEN PLANNER")
                    .font(JohoFont.label)
                    .foregroundStyle(colors.primary)
            }
            .padding(.leading, JohoDimensions.spacingMD)
            
            Spacer()
            
            // WALL
            Rectangle()
                .fill(colors.border)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)
            
            // RIGHT: Icon
            Image(systemName: icon)
                .font(JohoFont.headline)
                .foregroundStyle(iconColor)
                .frame(width: 48)
                .frame(maxHeight: .infinity)
        }
        .frame(height: 40)
        .background(accentColor.opacity(0.5))
    }
}

// MARK: - Shareable Card Footer

/// Standard footer bar for shareable cards
/// LEFT: Feature label | RIGHT: Branding
struct ShareableCardFooter: View {
    let leftLabel: String
    let rightLabel: String
    
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    
    var body: some View {
        HStack {
            Text(leftLabel)
                .font(JohoFont.labelBold)
                .foregroundStyle(colors.primary.opacity(0.5))
                .tracking(1)
            
            Spacer()
            
            Text(rightLabel)
                .font(JohoFont.labelBold)
                .foregroundStyle(colors.primary.opacity(0.4))
                .tracking(0.5)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .frame(height: 32)
    }
}

// MARK: - Shareable Card Divider

/// Standard divider for shareable cards
/// 2pt thick border color
struct ShareableCardDivider: View {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    
    var body: some View {
        Rectangle()
            .fill(colors.border)
            .frame(height: 2)
    }
}

// MARK: - Joho Share Circle Button

/// Compact 28x28 circle share button pattern
/// Used in sheet toolbars across app
struct JohoShareCircleButton: View {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(colors.surface)
                .frame(width: 28, height: 28)
            Image(systemName: IconCatalog.share)
                .font(JohoFont.headerTag)
                .foregroundStyle(colors.primary)
        }
    }
}

// MARK: - Preview

#Preview("Shareable Card Components") {
    VStack(spacing: 20) {
        // Full card shell example
        ShareableCardShell(
            headerIcon: IconCatalog.holiday,
            headerIconColor: JohoColors.pink,
            headerAccentColor: JohoColors.pink,
            footerLeftLabel: "PREVIEW CARD",
            footerRightLabel: "ONSEN PLANNER"
        ) {
            // Divider after header
            ShareableCardDivider()
            
            // Custom content
            VStack(spacing: JohoDimensions.spacingSM) {
                Text("Example Content")
                    .font(JohoFont.headline)
                Text("This shows the shareable card shell pattern")
                    .font(JohoFont.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(JohoColors.pink.opacity(0.15))
            
            // Divider before footer
            ShareableCardDivider()
        }
        .frame(width: 340)
        
        // Share button example
        JohoShareCircleButton()
    }
    .padding()
    .johoBackground()
}
