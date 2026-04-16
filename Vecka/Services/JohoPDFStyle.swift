//
//  JohoPDFStyle.swift
//  Vecka
//
//  PDF-only styling namespace. Codifies print-oriented information
//  design rules for the PDF export pipeline ONLY. Not used by the app UI.
//
//  Scope: PDF exports rendered by SimplePDFRenderer.
//  Do NOT import these tokens into on-screen SwiftUI views — the app UI
//  is governed by JohoTokens / JohoFoundations / JohoComponents.
//
//  Influences:
//    - Joho Design System (情報デザイン) — semantic color contract reused
//    - Adapted print-design principles for engineering/technical PDFs:
//      Three-Level Reading (Glance / Scan / Read), 6pt vertical rhythm,
//      five-zone page architecture, max 3 semantic colors per page,
//      WCAG AA body-text contrast, redundant encoding (color + text/icon).
//
//  Naming note: "JDS" in the external repository nj22az/JDS_Documentation
//  refers to the Johansson Documentation System (document governance), not
//  a UI design system. See docs/DESIGN_SYSTEMS.md for the disambiguation.
//

import SwiftUI
import CoreGraphics

// MARK: - JohoPDFStyle

/// Namespace for all PDF-only layout and typography tokens.
enum JohoPDFStyle {

    // MARK: Base Unit

    /// Base unit for vertical rhythm. All PDF spacing should be multiples
    /// of this value (6, 12, 18, 24, 30, 36, 42, 48).
    static let baseUnit: CGFloat = 6

    /// Spacing helpers aligned to the 6pt rhythm.
    enum Spacing {
        static let xs: CGFloat  = baseUnit * 1   // 6
        static let sm: CGFloat  = baseUnit * 2   // 12
        static let md: CGFloat  = baseUnit * 3   // 18
        static let lg: CGFloat  = baseUnit * 4   // 24
        static let xl: CGFloat  = baseUnit * 5   // 30
        static let xxl: CGFloat = baseUnit * 6   // 36
    }

    // MARK: Page Geometry (A4 default)

    enum Page {
        /// Default page size — A4 at 72 DPI (595.2 × 841.8).
        static let sizeA4 = CGSize(width: 595.2, height: 841.8)
        /// US Letter at 72 DPI.
        static let sizeLetter = CGSize(width: 612, height: 792)

        /// Minimum margin per edge (mm converted to pt at 72 DPI).
        /// 20mm ≈ 56.7pt.
        static let marginMinimum: CGFloat = 56.7
        /// Recommended margin (25mm ≈ 70.9pt).
        static let marginRecommended: CGFloat = 70.9
        /// Extra binding edge to add when applicable (10mm ≈ 28.3pt).
        static let bindingEdge: CGFloat = 28.3

        /// Height reserved for the page header zone.
        static let headerHeight: CGFloat = Spacing.lg       // 24
        /// Height reserved for the page footer zone.
        static let footerHeight: CGFloat = Spacing.md       // 18
        /// Stroke width of the thin rules separating page zones.
        static let zoneRuleWidth: CGFloat = 0.25
    }

    // MARK: Typography

    /// PDF-only typography scale. Kept separate from JohoFont because
    /// print requires tighter, static sizes and a different weight ladder.
    enum Font {
        // Document heading hierarchy (max 4 levels).
        static let h1 = SwiftUI.Font.system(size: 20, weight: .bold,     design: .rounded)
        static let h2 = SwiftUI.Font.system(size: 15, weight: .bold,     design: .rounded)
        static let h3 = SwiftUI.Font.system(size: 13, weight: .bold,     design: .rounded)
        static let h4 = SwiftUI.Font.system(size: 12, weight: .semibold, design: .rounded).italic()

        // Body copy — never smaller than 9pt.
        static let body       = SwiftUI.Font.system(size: 11, weight: .regular,  design: .rounded)
        static let bodyBold   = SwiftUI.Font.system(size: 11, weight: .semibold, design: .rounded)
        static let bodySmall  = SwiftUI.Font.system(size: 10, weight: .regular,  design: .rounded)

        // Metadata — header/footer, identity strips, table captions.
        static let metadata      = SwiftUI.Font.system(size: 7,  weight: .medium, design: .rounded)
        static let metadataLabel = SwiftUI.Font.system(size: 8,  weight: .semibold, design: .rounded)

        // Tabular numerics — aligned digits for figures and totals.
        static let tableCell   = SwiftUI.Font.system(size: 10, weight: .regular,  design: .monospaced)
        static let tableHeader = SwiftUI.Font.system(size: 10, weight: .semibold, design: .rounded)
        static let tableTotal  = SwiftUI.Font.system(size: 11, weight: .bold,     design: .monospaced)
    }

    /// Line-height multipliers for body text.
    enum LineHeight {
        static let body: CGFloat = 1.45   // 1.4–1.5× recommended
        static let heading: CGFloat = 1.2
    }

    /// Maximum body-text measure before eye strain kicks in.
    /// Typical target: 75–85 characters per line.
    static let maxBodyLineLength = 85

    // MARK: Color Palette (PDF)

    /// PDF palette. Reuses the semantic Joho contract so that a yellow
    /// cell on screen is a yellow cell in the PDF, but restricted to
    /// ink-friendly values. Rule: maximum 3 of these colors per page
    /// (in addition to black/white/neutrals).
    enum Color {
        static let ink         = SwiftUI.Color(hex: "111111")   // primary body text
        static let inkSoft     = SwiftUI.Color(hex: "333333")   // secondary body
        static let metadata    = SwiftUI.Color(hex: "8C8C8C")   // footer, timestamps
        static let rule        = SwiftUI.Color(hex: "222222")   // zone rules, dividers
        static let paper       = SwiftUI.Color(hex: "FFFFFF")   // background
        static let paperSoft   = SwiftUI.Color(hex: "F7F7F7")   // alternating rows

        // Semantic — aligned with JohoColors. Use sparingly.
        static let now         = JohoColors.yellow      // today, active
        static let scheduled   = JohoColors.cyan        // events, trips
        static let celebration = JohoColors.pink        // holidays, birthdays
        static let money       = JohoColors.green       // expenses
        static let people      = JohoColors.purple      // contacts
        static let alert       = JohoColors.red         // warnings (ink-heavy, use only if critical)
    }

    /// Budget enforced at the page level: pick at most 3.
    static let maxSemanticColorsPerPage = 3

    // MARK: Status Indicators (Redundant Encoding)

    /// Document status dot + word. Use both — never color alone.
    struct StatusIndicator {
        let label: String
        let color: SwiftUI.Color
        let symbolName: String   // SF Symbol; also renders as a dot if the font falls back.

        static let current      = StatusIndicator(label: "CURRENT",    color: JohoColors.green,  symbolName: "circle.fill")
        static let draft        = StatusIndicator(label: "DRAFT",      color: JohoColors.yellow, symbolName: "circle.fill")
        static let inReview     = StatusIndicator(label: "IN REVIEW",  color: JohoColors.cyan,   symbolName: "circle.fill")
        static let superseded   = StatusIndicator(label: "SUPERSEDED", color: Color.metadata,    symbolName: "circle.fill")
        static let overdue      = StatusIndicator(label: "OVERDUE",    color: JohoColors.red,    symbolName: "circle.fill")
        static let archived     = StatusIndicator(label: "ARCHIVED",   color: Color.metadata,    symbolName: "archivebox.fill")
    }
}

// MARK: - Three-Level Reading System

/// Hints authors about the reading level a given element is designed for.
/// Purely documentary — has no runtime effect beyond encouraging the
/// correct typographic scale.
///
/// - glance: must read at 0.5s (doc number, title, status)
/// - scan:   must read in 5s (headings, callouts, key totals)
/// - read:   full body content (tables, paragraphs)
enum JohoPDFReadingLevel {
    case glance, scan, read
}

// MARK: - View Modifiers (PDF-scoped)

/// Renders a page header zone (identity strip + thin rule) for PDF exports.
/// Use at the top of a PDF page view. Height is `JohoPDFStyle.Page.headerHeight`.
struct JohoPDFPageHeader: View {
    let title: String
    let subtitle: String?
    let documentNumber: String?

    init(title: String, subtitle: String? = nil, documentNumber: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.documentNumber = documentNumber
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: JohoPDFStyle.Spacing.sm) {
                if let documentNumber {
                    Text(documentNumber)
                        .font(JohoPDFStyle.Font.metadataLabel)
                        .foregroundStyle(JohoPDFStyle.Color.metadata)
                        .tracking(0.3)
                }
                Text(title)
                    .font(JohoPDFStyle.Font.metadataLabel)
                    .foregroundStyle(JohoPDFStyle.Color.ink)
                Spacer(minLength: 0)
                if let subtitle {
                    Text(subtitle)
                        .font(JohoPDFStyle.Font.metadata)
                        .foregroundStyle(JohoPDFStyle.Color.metadata)
                }
            }
            Rectangle()
                .fill(JohoPDFStyle.Color.rule)
                .frame(height: JohoPDFStyle.Page.zoneRuleWidth)
        }
        .frame(height: JohoPDFStyle.Page.headerHeight, alignment: .bottom)
    }
}

/// Renders the page footer zone (running metadata + thin rule) for PDFs.
/// Height is `JohoPDFStyle.Page.footerHeight`.
struct JohoPDFPageFooter: View {
    let runningTitle: String
    let pageNumber: Int
    let pageCount: Int
    let timestamp: Date?

    init(runningTitle: String, pageNumber: Int, pageCount: Int, timestamp: Date? = nil) {
        self.runningTitle = runningTitle
        self.pageNumber = pageNumber
        self.pageCount = pageCount
        self.timestamp = timestamp
    }

    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(JohoPDFStyle.Color.rule)
                .frame(height: JohoPDFStyle.Page.zoneRuleWidth)
            HStack(spacing: JohoPDFStyle.Spacing.sm) {
                Text(runningTitle)
                    .font(JohoPDFStyle.Font.metadata)
                    .foregroundStyle(JohoPDFStyle.Color.metadata)
                Spacer(minLength: 0)
                if let timestamp {
                    Text(timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(JohoPDFStyle.Font.metadata)
                        .foregroundStyle(JohoPDFStyle.Color.metadata)
                }
                Text("\(pageNumber) / \(pageCount)")
                    .font(JohoPDFStyle.Font.metadata.monospacedDigit())
                    .foregroundStyle(JohoPDFStyle.Color.metadata)
            }
        }
        .frame(height: JohoPDFStyle.Page.footerHeight, alignment: .top)
    }
}

/// Status pill (dot + word) — redundant encoding for PDF.
struct JohoPDFStatusPill: View {
    let indicator: JohoPDFStyle.StatusIndicator

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: indicator.symbolName)
                .font(.system(size: 8))
                .foregroundStyle(indicator.color)
            Text(indicator.label)
                .font(JohoPDFStyle.Font.metadataLabel)
                .foregroundStyle(JohoPDFStyle.Color.ink)
                .tracking(0.5)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(JohoPDFStyle.Color.rule, lineWidth: 0.5)
        )
    }
}

// MARK: - View extensions

extension View {
    /// Applies the PDF body-text baseline (size, color, line spacing).
    /// Intended for use inside PDF page views only.
    func johoPDFBody() -> some View {
        self
            .font(JohoPDFStyle.Font.body)
            .foregroundStyle(JohoPDFStyle.Color.ink)
            .lineSpacing(3)  // ≈1.45× at 11pt body
    }

    /// Applies the PDF metadata style (small, gray, tracked).
    func johoPDFMetadata() -> some View {
        self
            .font(JohoPDFStyle.Font.metadata)
            .foregroundStyle(JohoPDFStyle.Color.metadata)
            .tracking(0.3)
    }

    /// Wraps the content in the 5-zone PDF page architecture
    /// (header rule + body + footer rule) with the recommended margins.
    func johoPDFPage(
        title: String,
        runningTitle: String,
        pageNumber: Int,
        pageCount: Int,
        documentNumber: String? = nil,
        subtitle: String? = nil,
        timestamp: Date? = Date()
    ) -> some View {
        VStack(spacing: JohoPDFStyle.Spacing.md) {
            JohoPDFPageHeader(
                title: title,
                subtitle: subtitle,
                documentNumber: documentNumber
            )
            self
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            JohoPDFPageFooter(
                runningTitle: runningTitle,
                pageNumber: pageNumber,
                pageCount: pageCount,
                timestamp: timestamp
            )
        }
        .padding(.horizontal, JohoPDFStyle.Page.marginRecommended)
        .padding(.top, JohoPDFStyle.Spacing.lg)
        .padding(.bottom, JohoPDFStyle.Spacing.lg)
        .background(JohoPDFStyle.Color.paper)
    }
}

