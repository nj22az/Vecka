import SwiftUI
import PhotosUI

// MARK: - 情報デザイン Symbol System
// Japanese information design symbol vocabulary
// Reference: .claude/japanese-symbol-language.md

/// Japanese symbol categories used in 情報デザイン documents and packaging
enum JohoSymbols {

    // MARK: - Maru-Batsu System (○×△)
    // The most fundamental Japanese evaluation system

    /// Circle = Yes, Correct, Good, Included
    static let maru = "○"           // Empty circle
    static let maruFilled = "●"     // Filled circle - emphasis
    static let maruDouble = "◎"     // Double circle - Excellent/Best

    /// Cross = No, Incorrect, Bad, Excluded
    static let batsu = "×"          // X mark
    static let batsuAlt = "✕"       // Alternative X

    /// Triangle = Caution, Maybe, Partial, Warning
    static let sankaku = "△"        // Empty triangle
    static let sankakuFilled = "▲"  // Filled triangle - attention
    static let sankakuDown = "▽"    // Down triangle
    static let sankakuDownFilled = "▼"

    /// Square = Note, Reference, Category
    static let shikaku = "□"        // Empty square
    static let shikakuFilled = "■"  // Filled square

    /// Diamond = Special, Important
    static let hishi = "◇"          // Empty diamond
    static let hishiFilled = "◆"    // Filled diamond

    // MARK: - Numbered Circles (①②③)
    // Used for steps, rankings, references

    static let circledNumbers = ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩"]

    static func circledNumber(_ n: Int) -> String {
        guard n >= 1 && n <= 10 else { return "●" }
        return circledNumbers[n - 1]
    }

    // MARK: - Directional Arrows
    // Clean, bold arrows for flow and navigation

    static let arrowRight = "→"
    static let arrowLeft = "←"
    static let arrowUp = "↑"
    static let arrowDown = "↓"
    static let arrowDiagonalUR = "↗"
    static let arrowDiagonalDR = "↘"

    // Double arrows for emphasis
    static let arrowRightDouble = "⇒"
    static let arrowLeftDouble = "⇐"

    // MARK: - Reference Marks
    // Used in Japanese documents for notes and callouts

    static let reference = "※"       // Kome mark - "Note:" in Japanese
    static let bullet = "・"          // Nakaguro - Japanese bullet point
    static let postal = "〒"          // Postal mark

    // MARK: - SF Symbols for Common Concepts
    // Use these instead of emoji - 情報デザイン compliant

    enum SFIcon: String {
        case person = "person.fill"
        case people = "person.2.fill"
        case telephone = "phone.fill"
        case mail = "envelope.fill"
        case home = "house.fill"
        case work = "briefcase.fill"
        case star = "star.fill"
        case starEmpty = "star"
        case heart = "heart.fill"
        case heartEmpty = "heart"
        case medical = "cross.case.fill"
        case gear = "gearshape.fill"
        case calendar = "calendar"
        case clock = "clock.fill"
        case location = "mappin"
        case warning = "exclamationmark.triangle.fill"
        case info = "info.circle.fill"
        case checkmark = "checkmark"
        case xmark = "xmark"
        case plus = "plus"
        case minus = "minus"
        case edit = "pencil"
        case trash = "trash"
        case photo = "photo"
        case camera = "camera.fill"
    }

    // MARK: - Status Indicators (Unicode)
    // Visual status at a glance

    static let checkmark = "✓"
    static let checkmarkBold = "✔"
    static let prohibited = "⊘"
    static let warning = "⚠"
    static let info = "ℹ"

    // MARK: - Category Symbols (Unicode text only)
    // For categorizing contacts, items, etc.

    static let star = "★"            // Favorite/Important
    static let starEmpty = "☆"       // Not favorite
    static let flowerMark = "✿"      // Decorative flower
    static let sparkle = "✦"         // Sparkle/new
    static let dot = "・"             // Center dot
    static let wave = "〜"            // Wave dash

    // MARK: - Playstation-Style (Gaming UI Influence)
    // These geometric shapes are universal in Japanese UI

    static let circle = "○"          // Confirm (in Japan)
    static let cross = "×"           // Cancel (in Japan)
    static let square = "□"          // Menu/Options
    static let triangle = "△"        // Back/Alternative

    // MARK: - Contact Category Sets

    enum ContactCategory: String, CaseIterable {
        case family = "家"      // Family (kanji)
        case work = "仕"        // Work (kanji for 仕事)
        case friend = "友"      // Friend (kanji)
        case important = "★"    // Important
        case medical = "✚"      // Medical
        case service = "⚙"      // Service provider

        var symbol: String { rawValue }

        var sfSymbol: String {
            switch self {
            case .family: return SFIcon.heart.rawValue
            case .work: return SFIcon.work.rawValue
            case .friend: return SFIcon.people.rawValue
            case .important: return SFIcon.star.rawValue
            case .medical: return SFIcon.medical.rawValue
            case .service: return SFIcon.gear.rawValue
            }
        }

        var color: Color {
            switch self {
            case .family: return JohoColors.pinkLight
            case .work: return JohoColors.cyan
            case .friend: return JohoColors.purple
            case .important: return JohoColors.yellow
            case .medical: return JohoColors.red
            case .service: return JohoColors.green
            }
        }

        var label: String {
            switch self {
            case .family: return "FAMILY"
            case .work: return "WORK"
            case .friend: return "FRIEND"
            case .important: return "IMPORTANT"
            case .medical: return "MEDICAL"
            case .service: return "SERVICE"
            }
        }
    }

    // MARK: - Priority/Status Sets

    enum Priority: String, CaseIterable {
        case highest = "◎"     // Double circle - highest
        case high = "○"        // Circle - high
        case medium = "△"      // Triangle - medium
        case low = "□"         // Square - low
        case none = "−"        // Dash - none

        var symbol: String { rawValue }

        var label: String {
            switch self {
            case .highest: return "HIGHEST"
            case .high: return "HIGH"
            case .medium: return "MEDIUM"
            case .low: return "LOW"
            case .none: return "NONE"
            }
        }
    }

    enum Status: String, CaseIterable {
        case complete = "◎"    // Double circle - complete
        case good = "○"        // Circle - good
        case partial = "△"     // Triangle - partial
        case failed = "×"      // X - failed
        case pending = "□"     // Square - pending

        var symbol: String { rawValue }

        var color: Color {
            switch self {
            case .complete: return JohoColors.green
            case .good: return JohoColors.cyan
            case .partial: return JohoColors.yellow
            case .failed: return JohoColors.red
            case .pending: return JohoColors.white
            }
        }
    }
}

// MARK: - 情報デザイン Photo Container
// Proper image containment with aspect-fit cropping

struct JohoPhotoContainer: View {
    let image: Image?
    let fallbackInitials: String?
    let fallbackSymbol: String?
    let category: JohoSymbols.ContactCategory?
    let size: CGFloat
    let borderWidth: CGFloat

    init(
        image: Image? = nil,
        initials: String? = nil,
        symbol: String? = nil,
        category: JohoSymbols.ContactCategory? = nil,
        size: CGFloat = 64,
        borderWidth: CGFloat = 2
    ) {
        self.image = image
        self.fallbackInitials = initials
        self.fallbackSymbol = symbol
        self.category = category
        self.size = size
        self.borderWidth = borderWidth
    }

    private var backgroundColor: Color {
        category?.color ?? JohoColors.purple
    }

    private var cornerRadius: CGFloat {
        size * 0.2 // Proportional squircle
    }

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: cornerRadius)
                .fill(backgroundColor)

            // Content
            if let image = image {
                // Photo - aspect fill with crop
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size - borderWidth * 2, height: size - borderWidth * 2)
                    .clipShape(Squircle(cornerRadius: cornerRadius - borderWidth))
            } else if let initials = fallbackInitials {
                // Initials fallback
                Text(initials.prefix(2).uppercased())
                    .font(.system(size: size * 0.35, weight: .heavy, design: .rounded))
                    .foregroundStyle(JohoColors.black)
            } else if let symbol = fallbackSymbol {
                // Symbol fallback
                Text(symbol)
                    .font(.system(size: size * 0.4))
            } else if let category = category {
                // Category SF Symbol fallback
                Image(systemName: category.sfSymbol)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(JohoColors.black)
            } else {
                // Default person icon
                Image(systemName: JohoSymbols.SFIcon.person.rawValue)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }

            // Category badge (bottom-right corner)
            if let category = category, image != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: category.sfSymbol)
                            .font(.system(size: size * 0.15, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                            .padding(4)
                            .background(category.color)
                            .clipShape(Squircle(cornerRadius: 4))
                            .overlay(
                                Squircle(cornerRadius: 4)
                                    .stroke(JohoColors.black, lineWidth: 1)
                            )
                            .offset(x: 4, y: 4)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Squircle(cornerRadius: cornerRadius))
        .overlay(
            Squircle(cornerRadius: cornerRadius)
                .stroke(JohoColors.black, lineWidth: borderWidth)
        )
    }
}

// MARK: - 情報デザイン Photo Picker
// Proper picker with crop preview

struct JohoPhotoPicker: View {
    @Binding var selectedImage: Image?
    @Binding var selectedUIImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showingSymbolPicker = false
    @Binding var selectedSymbol: String?

    let size: CGFloat
    let category: JohoSymbols.ContactCategory?
    let initials: String?

    init(
        image: Binding<Image?>,
        uiImage: Binding<UIImage?>,
        symbol: Binding<String?>,
        size: CGFloat = 120,
        category: JohoSymbols.ContactCategory? = nil,
        initials: String? = nil
    ) {
        self._selectedImage = image
        self._selectedUIImage = uiImage
        self._selectedSymbol = symbol
        self.size = size
        self.category = category
        self.initials = initials
    }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingLG) {
            // Preview container
            JohoPhotoContainer(
                image: selectedImage,
                initials: initials,
                symbol: selectedSymbol,
                category: category,
                size: size,
                borderWidth: JohoDimensions.borderThick
            )

            // Action buttons
            HStack(spacing: JohoDimensions.spacingMD) {
                // Photo picker button
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    actionButton(icon: JohoSymbols.SFIcon.photo.rawValue, label: "PHOTO")
                }

                // Symbol picker button
                Button {
                    showingSymbolPicker = true
                } label: {
                    actionButton(icon: "character.ja", label: "SYMBOL")
                }

                // Clear button (if has content)
                if selectedImage != nil || selectedSymbol != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedImage = nil
                            selectedUIImage = nil
                            selectedSymbol = nil
                            photosPickerItem = nil
                        }
                    } label: {
                        actionButton(icon: JohoSymbols.SFIcon.xmark.rawValue, label: "CLEAR", color: JohoColors.red)
                    }
                }
            }
        }
        .onChange(of: photosPickerItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedUIImage = uiImage
                    selectedImage = Image(uiImage: uiImage)
                    selectedSymbol = nil // Clear symbol when photo selected
                }
            }
        }
        .sheet(isPresented: $showingSymbolPicker) {
            JohoSymbolPickerSheet(selectedSymbol: $selectedSymbol) {
                selectedImage = nil
                selectedUIImage = nil
                showingSymbolPicker = false
            }
        }
    }

    private func actionButton(icon: String, label: String, color: Color = JohoColors.black) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color == JohoColors.black ? JohoColors.white : JohoColors.black)
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(color)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - 情報デザイン Symbol Picker Sheet
// Grid picker for Japanese symbols

struct JohoSymbolPickerSheet: View {
    @Binding var selectedSymbol: String?
    let onSelect: () -> Void

    @Environment(\.dismiss) private var dismiss

    // Symbol categories for picker - NO EMOJI, only Unicode geometric and kanji
    private let symbolSections: [(title: String, symbols: [String])] = [
        ("MARU-BATSU", ["○", "●", "◎", "×", "△", "▲", "□", "■", "◇", "◆"]),
        ("NUMBERS", ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩"]),
        ("ARROWS", ["→", "←", "↑", "↓", "↗", "↘", "⇒", "⇐"]),
        ("STATUS", ["✓", "✔", "⊘", "⚠", "ℹ", "※"]),
        ("STARS", ["★", "☆", "✦", "✿", "◉", "•"]),
        ("KANJI", ["家", "仕", "友", "医", "店", "駅", "食", "休", "祝", "振"]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    ForEach(symbolSections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                            // Section header pill
                            JohoPill(text: section.title, style: .whiteOnBlack, size: .small)

                            // Symbol grid
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                ForEach(section.symbols, id: \.self) { symbol in
                                    symbolButton(symbol)
                                }
                            }
                        }
                        .padding(JohoDimensions.spacingLG)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                    }
                }
                .padding(JohoDimensions.spacingLG)
            }
            .johoBackground()
            .navigationTitle("SELECT SYMBOL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(JohoSymbols.batsu)  // × Cancel
                            .font(.system(size: 18, weight: .bold))
                    }
                }
            }
        }
    }

    private func symbolButton(_ symbol: String) -> some View {
        Button {
            selectedSymbol = symbol
            onSelect()
        } label: {
            Text(symbol)
                .font(.system(size: 28))
                .frame(width: 56, height: 56)
                .background(selectedSymbol == symbol ? JohoColors.yellow : JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(JohoColors.black, lineWidth: selectedSymbol == symbol ? 2.5 : 1.5)
                )
        }
    }
}

// MARK: - 情報デザイン Contact Avatar Row
// Complete contact display with photo/symbol

struct JohoContactAvatarRow: View {
    let name: String
    let subtitle: String?
    let image: Image?
    let symbol: String?
    let category: JohoSymbols.ContactCategory?
    let status: JohoSymbols.Status?

    init(
        name: String,
        subtitle: String? = nil,
        image: Image? = nil,
        symbol: String? = nil,
        category: JohoSymbols.ContactCategory? = nil,
        status: JohoSymbols.Status? = nil
    ) {
        self.name = name
        self.subtitle = subtitle
        self.image = image
        self.symbol = symbol
        self.category = category
        self.status = status
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(name.prefix(2))
    }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Avatar
            JohoPhotoContainer(
                image: image,
                initials: initials,
                symbol: symbol,
                category: category,
                size: 48,
                borderWidth: 1.5
            )

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(JohoFont.body.weight(.semibold))
                    .foregroundStyle(JohoColors.black)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }

            Spacer()

            // Status indicator (if present)
            if let status = status {
                Text(status.symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .padding(JohoDimensions.spacingSM)
                    .background(status.color)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: 1.5)
                    )
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(JohoColors.black.opacity(0.5))
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}

// MARK: - Category Filter Bar
// For filtering contacts by category

struct JohoCategoryFilterBar: View {
    @Binding var selectedCategory: JohoSymbols.ContactCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: JohoDimensions.spacingSM) {
                // All button
                categoryButton(nil, label: "ALL", sfSymbol: "circle.grid.2x2.fill")

                // Category buttons
                ForEach(JohoSymbols.ContactCategory.allCases, id: \.self) { category in
                    categoryButton(category, label: category.label, sfSymbol: category.sfSymbol)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
        }
    }

    private func categoryButton(_ category: JohoSymbols.ContactCategory?, label: String, sfSymbol: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: sfSymbol)
                    .font(.system(size: 12, weight: .bold))
                Text(label)
                    .font(JohoFont.labelSmall)
            }
            .foregroundStyle(isSelected(category) ? JohoColors.black : JohoColors.white)
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(isSelected(category) ? (category?.color ?? JohoColors.yellow) : JohoColors.black)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(JohoColors.black, lineWidth: isSelected(category) ? 2 : 1.5)
            )
        }
    }

    private func isSelected(_ category: JohoSymbols.ContactCategory?) -> Bool {
        selectedCategory == category
    }
}

// MARK: - Preview

#Preview("Photo Container Sizes") {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            JohoPhotoContainer(initials: "NJ", category: .work, size: 40)
            JohoPhotoContainer(initials: "AB", category: .family, size: 56)
            JohoPhotoContainer(symbol: "★", category: .important, size: 64)
            JohoPhotoContainer(symbol: "◎", category: .friend, size: 80)
        }
    }
    .padding()
    .johoBackground()
}

#Preview("Contact Rows") {
    VStack(spacing: 12) {
        JohoContactAvatarRow(
            name: "Nils Johansson",
            subtitle: "Field Service Engineer",
            category: .work,
            status: .good
        )

        JohoContactAvatarRow(
            name: "Mai Nguyen",
            subtitle: "Ho Chi Minh City",
            symbol: "♥",
            category: .family,
            status: .complete
        )

        JohoContactAvatarRow(
            name: "Dr. Tanaka",
            subtitle: "Clinic Appointment",
            category: .medical,
            status: .pending
        )
    }
    .padding()
    .johoBackground()
}

#Preview("Symbol Picker") {
    JohoSymbolPickerSheet(selectedSymbol: .constant("○")) {}
}

#Preview("Category Filter") {
    VStack {
        JohoCategoryFilterBar(selectedCategory: .constant(.work))
    }
    .padding(.vertical)
    .johoBackground()
}
