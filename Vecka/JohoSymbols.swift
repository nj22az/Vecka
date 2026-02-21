import SwiftUI
import PhotosUI

// MARK: - Icon Catalog (Single Source of Truth)
// All SF Symbol references go through IconCatalog — no hardcoded strings in views

/// Canonical SF Symbol names for every concept in the app.
/// Views reference `IconCatalog.*` instead of hardcoded strings.
enum IconCatalog {

    // MARK: - Notes & Memos
    static let memo = "note.text"
    static let memoOutline = "note.text"

    // MARK: - People
    static let person = "person.fill"
    static let people = "person.2.fill"
    static let contacts = "person.2"
    static let peopleGroup = "person.3.fill"
    static let personBadgeKey = "person.badge.key"

    // MARK: - Calendar & Time
    static let calendar = "calendar"
    static let calendarBadgePlus = "calendar.badge.plus"
    static let calendarBadgeCheckmark = "calendar.badge.checkmark"
    static let event = "calendar.badge.clock"
    static let clock = "clock.fill"
    static let clockHistory = "clock.arrow.circlepath"
    static let timer = "timer"
    static let repeatIcon = "repeat"

    // MARK: - Navigation
    static let home = "house.fill"
    static let star = "star.fill"
    static let chevronRight = "chevron.right"
    static let chevronLeft = "chevron.left"
    static let chevronDown = "chevron.down"
    static let chevronUpDown = "chevron.up.chevron.down"
    static let arrowBack = "arrow.uturn.backward"
    static let arrowCounterclockwise = "arrow.counterclockwise"
    static let arrowClockwise = "arrow.clockwise"
    static let arrowDownCircle = "arrow.down.circle"

    // MARK: - Actions
    static let plus = "plus"
    static let plusCircle = "plus.circle"
    static let plusCircleFill = "plus.circle.fill"
    static let xmark = "xmark"
    static let xmarkCircle = "xmark.circle"
    static let xmarkCircleFill = "xmark.circle.fill"
    static let checkmark = "checkmark"
    static let checkmarkCircle = "checkmark.circle"
    static let checkmarkCircleFill = "checkmark.circle.fill"
    static let pencil = "pencil"
    static let trash = "trash"
    static let trashFill = "trash.fill"

    // MARK: - Sharing & Import
    static let share = "square.and.arrow.up"
    static let download = "square.and.arrow.down"

    // MARK: - Search
    static let search = "magnifyingglass"

    // MARK: - Communication
    static let phone = "phone.fill"
    static let envelope = "envelope.fill"
    static let mapFill = "map.fill"

    // MARK: - Location
    static let mappin = "mappin"
    static let locationFill = "location.fill"
    static let globe = "globe"

    // MARK: - Media
    static let photo = "photo"
    static let photoStack = "photo.fill.on.rectangle.fill"
    static let camera = "camera.fill"

    // MARK: - Documents & Lists
    static let bookClosed = "text.book.closed.fill"
    static let booksVertical = "books.vertical.fill"
    static let listBullet = "list.bullet"
    static let checklist = "checklist"

    // MARK: - Alerts & Status
    static let warning = "exclamationmark.triangle.fill"
    static let lockFill = "lock.fill"
    static let chartBar = "chart.bar.xaxis"
    static let tray = "tray"
    static let folder = "folder.fill"
    static let flagFill = "flag.fill"

    // MARK: - Gifts & Social
    static let gift = "gift.fill"

    // MARK: - Buildings & Places
    static let building = "building.2.fill"
    static let storefront = "storefront.fill"
    static let qrcode = "qrcode"

    // MARK: - Grids & Layout
    static let gridAll = "circle.grid.2x2.fill"
    static let characterJa = "character.ja"

    // MARK: - Developer & Tools
    static let hammer = "hammer.fill"
    static let wandAndStars = "wand.and.stars"

    // MARK: - Decorative (KaomojiMascot)
    static let heartFill = "heart.fill"
    static let cloudFill = "cloud.fill"
    static let sparkle = "sparkle"
    static let humidityFill = "humidity.fill"

    // MARK: - Settings & System
    static let settings = "gearshape"

    // MARK: - Type Defaults
    static let birthday = "birthday.cake.fill"
    static let birthdayCake = "birthday.cake"
    static let holiday = "star.fill"
    static let observance = "sparkles"
    static let trip = "airplane"
    static let tripDeparture = "airplane.departure"
    static let countdown = "calendar.badge.clock"

    // MARK: - Display Category Outlines (shape = meaning)
    static let holidayOutline = "circle"
    static let observanceOutline = "diamond"

    // MARK: - Money — locale-aware
    static var expense: String {
        currencyIcon(for: Locale.current)
    }

    /// Currency-specific icon based on locale
    static func currencyIcon(for locale: Locale) -> String {
        switch locale.currency?.identifier {
        case "EUR": return "eurosign.circle.fill"
        case "GBP": return "sterlingsign.circle.fill"
        case "JPY": return "yensign.circle.fill"
        case "SEK", "NOK", "DKK", "ISK": return "swedishkronasign.circle.fill"
        case "CHF": return "francsign.circle.fill"
        case "KRW": return "wonsign.circle.fill"
        case "INR": return "indianrupeesign.circle.fill"
        case "RUB": return "rublesign.circle.fill"
        case "BRL": return "brazilianrealsign.circle.fill"
        case "THB": return "bahtsign.circle.fill"
        case "TRY": return "turkishlirasign.circle.fill"
        case "PLN": return "polishzlotysign.circle.fill"
        case "CNY": return "yensign.circle.fill"
        default: return "dollarsign.circle.fill"
        }
    }

    /// Currency-specific icon based on currency code string
    static func currencyIcon(for currencyCode: String) -> String {
        switch currencyCode.uppercased() {
        case "USD": return "dollarsign.circle.fill"
        case "EUR": return "eurosign.circle.fill"
        case "GBP": return "sterlingsign.circle.fill"
        case "JPY": return "yensign.circle.fill"
        case "CNY", "RMB": return "yensign.circle.fill"
        case "KRW": return "wonsign.circle.fill"
        case "INR": return "indianrupeesign.circle.fill"
        case "RUB": return "rublesign.circle.fill"
        case "BRL": return "brazilianrealsign.circle.fill"
        case "THB": return "bahtsign.circle.fill"
        case "TRY": return "turkishlirasign.circle.fill"
        case "SEK", "NOK", "DKK", "ISK": return "swedishkronasign.circle.fill"
        case "CHF": return "francsign.circle.fill"
        case "PLN": return "polishzlotysign.circle.fill"
        default: return "dollarsign.circle.fill"
        }
    }
}

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
        case gear = "gearshape"
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

    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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

    private var stickerContent: JohoSticker.Content {
        if image != nil {
            // JohoSticker expects Data, but we have Image — keep custom rendering for Image type
            return .empty // Handled by custom overlay below
        } else if let initials = fallbackInitials {
            return .initials(initials)
        } else if let symbol = fallbackSymbol {
            return .icon(symbol) // Unicode symbols rendered as icon
        } else if let category = category {
            return .icon(category.sfSymbol)
        } else {
            return .empty
        }
    }

    private var stickerBadge: JohoSticker.Badge? {
        guard let category = category, image != nil else { return nil }
        return JohoSticker.Badge(icon: category.sfSymbol, color: category.color)
    }

    var body: some View {
        // When we have an Image (not Data), we need custom rendering
        // since JohoSticker.Content.photo expects Data
        if image != nil {
            ZStack(alignment: .bottomTrailing) {
                image!
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Squircle(cornerRadius: cornerRadius))
                    .overlay(
                        Squircle(cornerRadius: cornerRadius)
                            .stroke(colors.border, lineWidth: borderWidth)
                    )

                if let badge = stickerBadge {
                    Image(systemName: badge.icon)
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundStyle(colors.primaryInverted)
                        .padding(4)
                        .background(badge.color)
                        .johoBordered(cornerRadius: 4, borderWidth: 1)
                        .offset(x: 4, y: 4)
                }
            }
            .frame(width: size, height: size)
        } else {
            JohoSticker(
                content: stickerContent,
                color: backgroundColor,
                shape: .squircle,
                badge: stickerBadge,
                size: size,
                borderWidth: borderWidth
            )
        }
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

    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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

    private func actionButton(icon: String, label: String, color: Color? = nil) -> some View {
        let backgroundColor = color ?? colors.primary
        let foregroundColor = color != nil ? colors.primary : colors.primaryInverted

        return VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(JohoFont.labelBold)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(backgroundColor)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall)
    }
}

// MARK: - 情報デザイン Symbol Picker Sheet
// Grid picker for Japanese symbols

struct JohoSymbolPickerSheet: View {
    @Binding var selectedSymbol: String?
    let onSelect: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Symbol categories for picker - loaded from JSON (情報デザイン: database-driven)
    private var symbolSections: [(title: String, symbols: [String])] {
        JohoSymbolsLoader.symbolSections
    }

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
                        .background(colors.surface)
                        .johoBordered()
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
                .background(selectedSymbol == symbol ? JohoColors.yellow : colors.surface)
                .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: selectedSymbol == symbol ? 2.5 : 1.5)
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

    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
                    .foregroundStyle(colors.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(0.6))
                }
            }

            Spacer()

            // Status indicator (if present)
            if let status = status {
                Text(status.symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(colors.primary)
                    .padding(JohoDimensions.spacingSM)
                    .background(status.color)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
            }

            // Chevron
            Image(systemName: IconCatalog.chevronRight)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(colors.primary.opacity(0.5))
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .johoBordered(borderWidth: 1.5)
    }
}

// MARK: - Category Filter Bar
// For filtering contacts by category

struct JohoCategoryFilterBar: View {
    @Binding var selectedCategory: JohoSymbols.ContactCategory?

    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
            .foregroundStyle(isSelected(category) ? colors.primary : colors.primaryInverted)
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(isSelected(category) ? (category?.color ?? JohoColors.yellow) : colors.primary)
            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: isSelected(category) ? 2 : 1.5)
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

// MARK: - JSON Loader (情報デザイン: Database-driven symbols)

enum JohoSymbolsLoader {
    /// Symbol sections loaded from JSON for picker grid
    static let symbolSections: [(title: String, symbols: [String])] = {
        guard let url = Bundle.main.url(forResource: "joho-symbols", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONDecoder().decode(JohoSymbolsJSON.self, from: data) else {
            Log.e("Failed to load joho-symbols.json")
            return defaultSymbolSections
        }
        Log.i("Loaded \(json.symbolSections.count) symbol sections from JSON")
        return json.symbolSections.map { ($0.title, $0.symbols) }
    }()

    /// Fallback if JSON fails to load
    private static let defaultSymbolSections: [(title: String, symbols: [String])] = [
        ("MARU-BATSU", ["○", "●", "◎", "×", "△", "▲", "□", "■", "◇", "◆"]),
        ("NUMBERS", ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩"]),
        ("ARROWS", ["→", "←", "↑", "↓", "↗", "↘", "⇒", "⇐"]),
        ("STATUS", ["✓", "✔", "⊘", "⚠", "ℹ", "※"]),
        ("STARS", ["★", "☆", "✦", "✿", "◉", "•"]),
        ("KANJI", ["家", "仕", "友", "医", "店", "駅", "食", "休", "祝", "振"]),
    ]
}

// MARK: - JSON DTOs

private struct JohoSymbolsJSON: Codable {
    let symbolSections: [SymbolSectionDTO]
    let contactCategories: [ContactCategoryDTO]
    let priorityLevels: [PriorityDTO]
    let statusIndicators: [StatusDTO]
}

private struct SymbolSectionDTO: Codable {
    let id: String
    let title: String
    let symbols: [String]
}

private struct ContactCategoryDTO: Codable {
    let id: String
    let symbol: String
    let sfSymbol: String
    let colorHex: String
    let label: String
}

private struct PriorityDTO: Codable {
    let id: String
    let symbol: String
    let label: String
}

private struct StatusDTO: Codable {
    let id: String
    let symbol: String
    let colorHex: String
    let label: String
}
