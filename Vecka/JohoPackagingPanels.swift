//
//  JohoPackagingPanels.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) — Japanese packaging information design.
//
//  Reusable SwiftUI components that mirror the 7-compartment back-of-pack
//  information architecture used by Hi-Chew, Marosh, Aroma Foundation
//  pouches and Bandai Gashapon cards. Used by shareable cards, fact panels,
//  day-summary exports and detail sheets.
//
//  Spec:      JDS-MAN-SFW-001 §12 (engineering)
//  Reference: JDS-REF-SFW-001     (design source material; bento + color logic)
//
//  Color meaning (packaging-scoped — does NOT override §2.1 app semantics):
//    Blue   trust, neutrality          → hook headers, body text
//    Red    urgency, danger            → warnings, allergen callouts
//    Yellow attention, friendly notice → best-before, highlights
//    Green  nature, freshness          → healthy claims
//    Teal   refreshing, modern, juicy  → default claim background
//    Pink   sweetness, cuteness        → soft / cute framing
//

import SwiftUI

/// The packaging "trust blue" — `SystemUIAccent.blue` (#3B82F6).
/// Centralised so every panel uses the same Blue without re-deriving it.
private let packagingBlue: Color = SystemUIAccent.blue.color

// MARK: - 1. Hook (Catchy Slogan)

/// **Compartment 1.** Blue header bar + white bold text. The loud
/// opening claim. One line, energetic, slightly exaggerated — the
/// "ONE PIECE AND YOU CAN'T STOP!" of a candy wrapper.
struct PackagingHook: View {
    let headline: String
    let subline: String?

    init(_ headline: String, subline: String? = nil) {
        self.headline = headline
        self.subline = subline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
            Text(headline)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .tracking(0.5)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let subline {
                Text(subline)
                    .font(JohoFont.bodySmall)
                    .opacity(JohoDimensions.opacityHeavy)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // Constant Blue tint → hardcoded WHITE foreground (§10 constant-tint rule).
        .foregroundStyle(JohoColors.white)
        .padding(JohoDimensions.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(packagingBlue)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5, borderColor: JohoColors.black)
    }
}

// MARK: - 2. Claim Pill (Feature / Technology)

/// **Compartment 2.** Teal / Green / light Blue box that highlights a
/// "method" or feature — the "AROMA FOUNDATION METHOD" move.
/// Default tint is teal (`JohoColors.cyan`) per the packaging color logic.
struct PackagingClaimPill: View {
    let title: String
    let subtitle: String?
    let tint: Color

    init(_ title: String, subtitle: String? = nil, tint: Color = JohoColors.cyan) {
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.5)
            if let subtitle {
                Text(subtitle)
                    .font(JohoFont.caption)
                    .opacity(JohoDimensions.opacityHeavy)
            }
        }
        // Constant tint → hardcoded dark foreground (§10 constant-tint rule).
        .foregroundStyle(JohoColors.black)
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint)
        .johoBordered(cornerRadius: JohoDimensions.radiusChip, borderWidth: 1.5, borderColor: JohoColors.black)
    }
}

// MARK: - 3. Ingredients Box (with Allergen Callout)

/// **Compartment 3.** White background, Blue body text, Red allergen
/// sub-box (the "Blue + Red" combination — trusted info with safety
/// warning). Bullet (●) rows mirror the candy ingredients panel.
struct PackagingIngredientsBox: View {
    struct Entry: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    let entries: [Entry]
    let allergens: String?

    init(entries: [Entry], allergens: String? = nil) {
        self.entries = entries
        self.allergens = allergens
    }

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            ForEach(entries) { entry in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("●")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(packagingBlue)
                    Text(entry.label)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(packagingBlue)
                    Text(entry.value)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }

            if let allergens, !allergens.isEmpty {
                // Red sub-box — the safety-warning layer of Blue + Red.
                HStack(spacing: 6) {
                    Text("ALLERGENS")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1)
                    Text(allergens)
                        .font(JohoFont.labelBold)
                }
                // Constant Red tint → hardcoded WHITE foreground (§10).
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(JohoColors.red)
                .johoBordered(cornerRadius: JohoDimensions.radiusXS, borderWidth: 1, borderColor: JohoColors.black)
            }
        }
        .padding(JohoDimensions.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
    }
}

// MARK: - 4. Nutrition Facts Table

/// **Compartment 4.** Clean table with Blue headers and right-aligned
/// monospaced numeric values. Optional "(Estimated values)" footnote.
struct PackagingNutritionTable: View {
    struct Row: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    let title: String
    let rows: [Row]
    let footnote: String?

    init(title: String, rows: [Row], footnote: String? = "Estimated values") {
        self.title = title
        self.rows = rows
        self.footnote = footnote
    }

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Blue header strip (the "Blue header" of the table)
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(packagingBlue)

            Rectangle()
                .fill(colors.border)
                .frame(height: 1)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Text(row.label)
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.primary)
                        Spacer(minLength: 8)
                        Text(row.value)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, 5)

                    if index < rows.count - 1 {
                        Rectangle()
                            .fill(colors.primary.opacity(JohoDimensions.opacityMild))
                            .frame(height: 0.5)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }
            }

            if let footnote, !footnote.isEmpty {
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1)
                Text("(\(footnote))")
                    .font(JohoFont.caption)
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
    }
}

// MARK: - 5. Manufacturer Block (with Optional Date Highlight)

/// **Compartment 5.** White box, Blue text. If `bestBefore` is provided
/// it gets a Yellow highlight (the "Blue + Yellow" combination —
/// trusted info that must be noticed).
struct PackagingManufacturerBlock: View {
    let maker: String
    let address: String?
    let contact: String?
    let bestBefore: String?
    let storage: String?

    init(
        maker: String,
        address: String? = nil,
        contact: String? = nil,
        bestBefore: String? = nil,
        storage: String? = nil
    ) {
        self.maker = maker
        self.address = address
        self.contact = contact
        self.bestBefore = bestBefore
        self.storage = storage
    }

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            line("Source", maker, valueIsBold: true)
            if let address { line("From", address) }
            if let contact { line("Contact", contact) }
            if let bestBefore {
                // Yellow highlight — Blue + Yellow combination
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    label("Best Before")
                    Text(bestBefore)
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(JohoColors.black) // hardcoded on Yellow tint
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(JohoColors.yellow)
                        .johoBordered(cornerRadius: JohoDimensions.radiusXS, borderWidth: 1, borderColor: JohoColors.black)
                    Spacer(minLength: 0)
                }
            }
            if let storage {
                Text(storage)
                    .font(JohoFont.caption)
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                    .padding(.top, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8, weight: .black, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(packagingBlue)
            .frame(width: 72, alignment: .leading)
    }

    private func line(_ labelText: String, _ value: String, valueIsBold: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            label(labelText)
            Text(value)
                .font(valueIsBold ? JohoFont.bodySmallBold : JohoFont.bodySmall)
                .foregroundStyle(colors.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - 6. Warning Box

/// **Compartment 6.** Sharp Red background + white text (the "Sharp Red
/// box" of the packaging template). Prominent, friendly, unambiguous.
struct PackagingWarningBox: View {
    let title: String
    let items: [String]

    init(_ title: String, items: [String]) {
        self.title = title
        self.items = items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1)
            }

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                    Text(item)
                        .font(JohoFont.caption)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        // Constant Red tint → hardcoded WHITE foreground (§10 constant-tint rule).
        .foregroundStyle(JohoColors.white)
        .padding(JohoDimensions.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JohoColors.red)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5, borderColor: JohoColors.black)
    }
}

// MARK: - 7. Code Footer

/// **Compartment 7.** Small, clean, minimal: short item ID, decorative
/// QR-like glyph, optional URL stub. No real barcode/QR rendering —
/// purely a visual reference to the packaging tradition.
struct PackagingCodeFooter: View {
    let identifier: String
    let url: String?

    init(identifier: String, url: String? = nil) {
        self.identifier = identifier
        self.url = url
    }

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: "qrcode")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)

            Text(identifier)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))

            Spacer()

            if let url, !url.isEmpty {
                Text(url)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }
}

// MARK: - Preview

#Preview("Packaging Panels — Light") {
    ScrollView {
        VStack(spacing: JohoDimensions.spacingMD) {
            PackagingHook(
                "ONE PIECE AND YOU CAN'T STOP!",
                subline: "Super chewy with a unique bite."
            )

            PackagingClaimPill(
                "AROMA FOUNDATION METHOD",
                subtitle: "Fluffy fragrant thin-layer coating delivers juicy flavor"
            )

            PackagingIngredientsBox(
                entries: [
                    .init(label: "Name", value: "Gummy Candy"),
                    .init(label: "Net", value: "46 g"),
                    .init(label: "Made in", value: "Japan")
                ],
                allergens: "GELATIN"
            )

            PackagingNutritionTable(
                title: "Nutrition Facts (per 1 piece 3.6 g)",
                rows: [
                    .init(label: "Energy", value: "12.6 kcal"),
                    .init(label: "Protein", value: "0.15 g"),
                    .init(label: "Fat", value: "0 g"),
                    .init(label: "Carbs", value: "2.97 g"),
                    .init(label: "Collagen", value: "132.1 mg")
                ]
            )

            PackagingManufacturerBlock(
                maker: "Kanro Co., Ltd.",
                address: "3-20-2 Nishi-Shinjuku, Shinjuku-ku, Tokyo",
                contact: "0120-88-0422",
                bestBefore: "2026.06",
                storage: "Store in a cool, dry place away from direct sunlight."
            )

            PackagingWarningBox(
                "PLEASE NOTE",
                items: [
                    "Be careful not to choke.",
                    "Made on shared equipment with milk products.",
                    "Gelatin is a form of collagen."
                ]
            )

            PackagingCodeFooter(
                identifier: "4 901351 025918",
                url: "vecka://memo"
            )
        }
        .padding()
    }
    .johoColorMode(.light)
    .johoBackground()
}

#Preview("Packaging Panels — Dark") {
    ScrollView {
        VStack(spacing: JohoDimensions.spacingMD) {
            PackagingHook("CHEWY, JUICY, IRRESISTIBLE!", subline: "Same panels, dark canvas.")
            PackagingClaimPill("AROMA FOUNDATION METHOD")
            PackagingWarningBox("WARNING", items: ["Dark-mode warning sample."])
        }
        .padding()
    }
    .johoColorMode(.dark)
    .johoBackground()
}
