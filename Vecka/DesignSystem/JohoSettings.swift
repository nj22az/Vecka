//
//  JohoSettings.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Authentic Japanese Packaging Style
//  Inspired by Muhi, Rohto, and classic Japanese OTC medicine packaging
//

import SwiftUI

// MARK: - JohoSFSymbolPickerSheet (情報デザイン: Symbol Selection for Shareable Cards)

/// SF Symbol entry loaded from sf-symbols.json
private struct SFSymbolEntry: Codable {
    let name: String
    let category: String
}

/// Loads and caches SF Symbols from the bundled JSON resource
private enum SFSymbolCatalog {
    static let shared = loadSymbols()

    /// All categories in display order
    static var categories: [String] {
        let order = ["General", "Communication", "Weather", "Nature", "Travel",
                     "Objects", "Sport", "People", "Devices", "Arrows",
                     "Media", "Commerce", "Health", "Home", "Gaming", "Education"]
        let loaded = Set(shared.map(\.category))
        return order.filter { loaded.contains($0) }
    }

    /// Symbols grouped by category
    static func symbols(for category: String) -> [String] {
        shared.filter { $0.category == category }.map(\.name)
    }

    /// Search symbols by name substring
    static func search(_ query: String) -> [String] {
        let q = query.lowercased()
        return shared.filter { $0.name.lowercased().contains(q) }.map(\.name)
    }

    private static func loadSymbols() -> [SFSymbolEntry] {
        guard let url = Bundle.main.url(forResource: "sf-symbols", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([SFSymbolEntry].self, from: data)
        else {
            return fallbackSymbols
        }
        // Filter to only symbols available on this device
        return entries.filter { UIImage(systemName: $0.name) != nil }
    }

    /// Fallback if JSON fails to load (original 56 symbols)
    private static let fallbackSymbols: [SFSymbolEntry] = [
        "star.fill", "sparkles", "party.popper.fill", "birthday.cake.fill", "gift.fill",
        "heart.fill", "bell.fill", "balloon.fill", "calendar", "clock.fill",
        "hourglass", "alarm.fill", "sun.max.fill", "moon.fill", "snowflake",
        "leaf.fill", "flame.fill", "drop.fill", "airplane", "car.fill",
        "tram.fill", "bicycle", "figure.walk", "ferry.fill", "sailboat.fill",
        "mountain.2.fill", "dollarsign.circle.fill", "banknote.fill", "creditcard.fill",
        "cart.fill", "bag.fill", "person.fill", "person.2.fill", "hand.wave.fill",
        "circle.fill", "square.fill", "triangle.fill", "diamond.fill", "hexagon.fill",
    ].map { SFSymbolEntry(name: $0, category: "General") }
}

/// A 情報デザイン compliant SF Symbol picker with search and full catalog
/// Used to select custom icons when sharing memos, holidays, and special days
struct JohoSFSymbolPickerSheet: View {
    @Binding var selectedSymbol: String
    let accentColor: Color
    let lightBackground: Color
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @AppStorage("recentSFSymbols") private var recentSymbolsJSON = "[]"

    private var recentSymbols: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(recentSymbolsJSON.utf8))) ?? []
    }

    private func addToRecent(_ symbol: String) {
        var recents = recentSymbols.filter { $0 != symbol }
        recents.insert(symbol, at: 0)
        if recents.count > 20 { recents = Array(recents.prefix(20)) }
        if let data = try? JSONEncoder().encode(recents), let json = String(data: data, encoding: .utf8) {
            recentSymbolsJSON = json
        }
    }

    private var displaySymbols: [String] {
        if !searchText.isEmpty {
            return SFSymbolCatalog.search(searchText)
        }
        if let cat = selectedCategory {
            if cat == "RECENT" { return recentSymbols }
            return SFSymbolCatalog.symbols(for: cat)
        }
        // Default: show all (capped at 200 for performance)
        return Array(SFSymbolCatalog.shared.prefix(200).map(\.name))
    }

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: JohoDimensions.spacingSM)]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM)
                        .background(colors.surface)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: 1.5)
                        )
                }

                Spacer()

                // Selected symbol preview
                Image(systemName: selectedSymbol)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .frame(width: 44, height: 44)
                    .background(lightBackground)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: 2)
                    )

                Spacer()

                Button {
                    addToRecent(selectedSymbol)
                    onDone()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(JohoFont.body.bold())
                        .foregroundStyle(accentColor.contrastingForeground)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM)
                        .background(accentColor)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.top, JohoDimensions.spacingMD)
            .padding(.bottom, JohoDimensions.spacingSM)

            // Search bar
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: IconCatalog.search)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.secondary)

                TextField("Search symbols...", text: $searchText)
                    .font(JohoFont.body)
                    .foregroundStyle(colors.primary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: IconCatalog.xmarkCircleFill)
                            .font(JohoFont.headlineSmall)
                            .foregroundStyle(colors.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(colors.inputBackground)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(colors.border, lineWidth: 1)
            )
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingSM)

            // Category pills (horizontal scroll)
            if searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        // Recent category
                        if !recentSymbols.isEmpty {
                            categoryPill("RECENT", isSelected: selectedCategory == "RECENT") {
                                selectedCategory = selectedCategory == "RECENT" ? nil : "RECENT"
                            }
                        }

                        ForEach(SFSymbolCatalog.categories, id: \.self) { cat in
                            categoryPill(cat.uppercased(), isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }
                .padding(.bottom, JohoDimensions.spacingSM)
            }

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 2)

            // Symbol grid
            ScrollView {
                if displaySymbols.isEmpty {
                    VStack(spacing: JohoDimensions.spacingMD) {
                        Image(systemName: IconCatalog.search)
                            .font(JohoFont.displayMedium)
                            .foregroundStyle(colors.secondary)
                        Text("No symbols found")
                            .font(JohoFont.body)
                            .foregroundStyle(colors.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: JohoDimensions.spacingSM) {
                        ForEach(displaySymbols, id: \.self) { symbol in
                            Button {
                                selectedSymbol = symbol
                                HapticManager.selection()
                            } label: {
                                let isSelected = selectedSymbol == symbol
                                Image(systemName: symbol)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? accentColor : colors.primary)
                                    .johoTouchTarget(52)
                                    .background(isSelected ? lightBackground : colors.surface)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                            .stroke(colors.border, lineWidth: isSelected ? 2 : 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingMD)
                }
            }
        }
        .background(colors.surface)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(JohoDimensions.radiusLarge)
        .presentationDragIndicator(.visible)
    }

    private func categoryPill(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? accentColor.contrastingForeground : colors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? accentColor : colors.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? accentColor : colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - JohoIconPicker (Convenience wrapper for icon selection)

/// Convenience view modifier that presents a JohoSFSymbolPickerSheet.
/// Use `.johoIconPicker(isPresented:selection:color:)` on any view.
struct JohoIconPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selection: String
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                JohoSFSymbolPickerSheet(
                    selectedSymbol: $selection,
                    accentColor: accentColor,
                    lightBackground: accentColor.opacity(JohoDimensions.opacityLight),
                    onDone: { isPresented = false }
                )
            }
    }
}

extension View {
    /// Present a JohoSFSymbolPickerSheet as a modal sheet.
    func johoIconPicker(isPresented: Binding<Bool>, selection: Binding<String>, accentColor: Color = JohoColors.yellow) -> some View {
        modifier(JohoIconPickerModifier(isPresented: isPresented, selection: selection, accentColor: accentColor))
    }
}

// MARK: - CategoryIconSettings (情報デザイン: Shared Category Icon Storage)

/// Custom icon for category cards (color is managed by CategoryColorSettings)
struct CategoryCustomization: Codable, Equatable {
    var icon: String?  // SF Symbol name (nil = use default category icon)
}

/// Shared helpers for category icon customization stored in @AppStorage("categoryCustomizations")
enum CategoryIconSettings {
    private static let storageKey = "categoryCustomizations"

    static func load() -> [String: CategoryCustomization] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: CategoryCustomization].self, from: data) else {
            return [:]
        }
        return decoded
    }

    static func save(_ customizations: [String: CategoryCustomization]) {
        if let encoded = try? JSONEncoder().encode(customizations) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    static func icon(for category: DisplayCategory) -> String? {
        load()[category.rawValue]?.icon
    }

    static func setIcon(_ icon: String?, for category: DisplayCategory) {
        var customizations = load()
        if let icon = icon {
            customizations[category.rawValue] = CategoryCustomization(icon: icon)
        } else {
            customizations.removeValue(forKey: category.rawValue)
        }
        save(customizations)
    }

    static func reset(for category: DisplayCategory) {
        var customizations = load()
        customizations.removeValue(forKey: category.rawValue)
        save(customizations)
    }
}

// MARK: - CategoryColorSettings (情報デザイン: Dynamic Category Colors)

/// Observable class for customizable category colors
/// Uses @AppStorage for persistence across app launches
/// Note: Uses tracked state properties that sync with UserDefaults for proper SwiftUI observation
@Observable
final class CategoryColorSettings {
    /// Shared singleton instance
    static let shared = CategoryColorSettings()

    // Default hex values from 情報デザイン palette
    static let defaultHolidayHex = "FECDD3"    // Pink
    static let defaultObservanceHex = "A5F3FC" // Cyan
    static let defaultMemoHex = "FFE566"       // Yellow

    // Default foreground hex values (curated for >=4.5:1 contrast)
    static let defaultHolidayForegroundHex = "9F1239"
    static let defaultObservanceForegroundHex = "155E75"
    static let defaultMemoForegroundHex = "854D0E"

    // Default dark mode background hex values
    static let defaultHolidayDarkHex = "881337"
    static let defaultObservanceDarkHex = "164E63"
    static let defaultMemoDarkHex = "854D0E"

    // Default dark mode foreground hex values
    static let defaultHolidayDarkForegroundHex = "FECDD3"
    static let defaultObservanceDarkForegroundHex = "A5F3FC"
    static let defaultMemoDarkForegroundHex = "FFE566"

    // MARK: - Tracked State (triggers SwiftUI updates)

    /// These are the tracked properties that SwiftUI observes
    var holidayColorHex: String {
        didSet { UserDefaults.standard.set(holidayColorHex, forKey: "categoryColor_holiday") }
    }
    var observanceColorHex: String {
        didSet { UserDefaults.standard.set(observanceColorHex, forKey: "categoryColor_observance") }
    }
    var memoColorHex: String {
        didSet { UserDefaults.standard.set(memoColorHex, forKey: "categoryColor_memo") }
    }

    // Foreground hex values
    var holidayForegroundHex: String {
        didSet { UserDefaults.standard.set(holidayForegroundHex, forKey: "categoryForeground_holiday") }
    }
    var observanceForegroundHex: String {
        didSet { UserDefaults.standard.set(observanceForegroundHex, forKey: "categoryForeground_observance") }
    }
    var memoForegroundHex: String {
        didSet { UserDefaults.standard.set(memoForegroundHex, forKey: "categoryForeground_memo") }
    }

    // Dark mode background hex values
    var holidayDarkColorHex: String {
        didSet { UserDefaults.standard.set(holidayDarkColorHex, forKey: "categoryDarkColor_holiday") }
    }
    var observanceDarkColorHex: String {
        didSet { UserDefaults.standard.set(observanceDarkColorHex, forKey: "categoryDarkColor_observance") }
    }
    var memoDarkColorHex: String {
        didSet { UserDefaults.standard.set(memoDarkColorHex, forKey: "categoryDarkColor_memo") }
    }

    // Dark mode foreground hex values
    var holidayDarkForegroundHex: String {
        didSet { UserDefaults.standard.set(holidayDarkForegroundHex, forKey: "categoryDarkForeground_holiday") }
    }
    var observanceDarkForegroundHex: String {
        didSet { UserDefaults.standard.set(observanceDarkForegroundHex, forKey: "categoryDarkForeground_observance") }
    }
    var memoDarkForegroundHex: String {
        didSet { UserDefaults.standard.set(memoDarkForegroundHex, forKey: "categoryDarkForeground_memo") }
    }

    // MARK: - Init (load from UserDefaults)

    private init() {
        self.holidayColorHex = UserDefaults.standard.string(forKey: "categoryColor_holiday") ?? Self.defaultHolidayHex
        self.observanceColorHex = UserDefaults.standard.string(forKey: "categoryColor_observance") ?? Self.defaultObservanceHex
        self.memoColorHex = UserDefaults.standard.string(forKey: "categoryColor_memo") ?? Self.defaultMemoHex

        self.holidayForegroundHex = UserDefaults.standard.string(forKey: "categoryForeground_holiday") ?? Self.defaultHolidayForegroundHex
        self.observanceForegroundHex = UserDefaults.standard.string(forKey: "categoryForeground_observance") ?? Self.defaultObservanceForegroundHex
        self.memoForegroundHex = UserDefaults.standard.string(forKey: "categoryForeground_memo") ?? Self.defaultMemoForegroundHex

        self.holidayDarkColorHex = UserDefaults.standard.string(forKey: "categoryDarkColor_holiday") ?? Self.defaultHolidayDarkHex
        self.observanceDarkColorHex = UserDefaults.standard.string(forKey: "categoryDarkColor_observance") ?? Self.defaultObservanceDarkHex
        self.memoDarkColorHex = UserDefaults.standard.string(forKey: "categoryDarkColor_memo") ?? Self.defaultMemoDarkHex

        self.holidayDarkForegroundHex = UserDefaults.standard.string(forKey: "categoryDarkForeground_holiday") ?? Self.defaultHolidayDarkForegroundHex
        self.observanceDarkForegroundHex = UserDefaults.standard.string(forKey: "categoryDarkForeground_observance") ?? Self.defaultObservanceDarkForegroundHex
        self.memoDarkForegroundHex = UserDefaults.standard.string(forKey: "categoryDarkForeground_memo") ?? Self.defaultMemoDarkForegroundHex
    }

    // MARK: - Computed Color Properties

    var holidayColor: Color { Color(hex: holidayColorHex) }
    var observanceColor: Color { Color(hex: observanceColorHex) }
    var memoColor: Color { Color(hex: memoColorHex) }

    /// Get color for a specific display category
    func color(for category: DisplayCategory) -> Color {
        switch category {
        case .holiday: return holidayColor
        case .observance: return observanceColor
        case .memo: return memoColor
        }
    }

    /// Background color for category, mode-aware
    func color(for category: DisplayCategory, mode: JohoColorMode) -> Color {
        switch mode {
        case .light:
            return color(for: category)
        case .dark:
            switch category {
            case .holiday: return Color(hex: holidayDarkColorHex)
            case .observance: return Color(hex: observanceDarkColorHex)
            case .memo: return Color(hex: memoDarkColorHex)
            }
        }
    }

    /// Foreground (text/icon) color for category, mode-aware
    func foregroundColor(for category: DisplayCategory, mode: JohoColorMode) -> Color {
        switch mode {
        case .light:
            switch category {
            case .holiday: return Color(hex: holidayForegroundHex)
            case .observance: return Color(hex: observanceForegroundHex)
            case .memo: return Color(hex: memoForegroundHex)
            }
        case .dark:
            switch category {
            case .holiday: return Color(hex: holidayDarkForegroundHex)
            case .observance: return Color(hex: observanceDarkForegroundHex)
            case .memo: return Color(hex: memoDarkForegroundHex)
            }
        }
    }

    /// Foreground color for category (light mode — backward compat)
    func foregroundColor(for category: DisplayCategory) -> Color {
        foregroundColor(for: category, mode: .light)
    }

    /// Get the hex value for a specific display category
    func colorHex(for category: DisplayCategory) -> String {
        switch category {
        case .holiday: return holidayColorHex
        case .observance: return observanceColorHex
        case .memo: return memoColorHex
        }
    }

    /// Get foreground hex for a specific display category
    func foregroundHex(for category: DisplayCategory) -> String {
        switch category {
        case .holiday: return holidayForegroundHex
        case .observance: return observanceForegroundHex
        case .memo: return memoForegroundHex
        }
    }

    /// Set foreground hex for a specific display category
    func setForegroundHex(_ hex: String, for category: DisplayCategory) {
        switch category {
        case .holiday:
            holidayForegroundHex = hex
            UserDefaults.standard.set(hex, forKey: "categoryForeground_holiday")
        case .observance:
            observanceForegroundHex = hex
            UserDefaults.standard.set(hex, forKey: "categoryForeground_observance")
        case .memo:
            memoForegroundHex = hex
            UserDefaults.standard.set(hex, forKey: "categoryForeground_memo")
        }
    }

    /// Set dark mode background hex for a specific display category
    func setDarkColorHex(_ hex: String, for category: DisplayCategory) {
        switch category {
        case .holiday:
            holidayDarkColorHex = hex
            UserDefaults.standard.set(hex, forKey: "categoryDarkColor_holiday")
        case .observance:
            observanceDarkColorHex = hex
            UserDefaults.standard.set(hex, forKey: "categoryDarkColor_observance")
        case .memo:
            memoDarkColorHex = hex
            UserDefaults.standard.set(hex, forKey: "categoryDarkColor_memo")
        }
    }

    /// Set dark mode foreground hex for a specific display category
    func setDarkForegroundHex(_ hex: String, for category: DisplayCategory) {
        switch category {
        case .holiday:
            holidayDarkForegroundHex = hex
            UserDefaults.standard.set(hex, forKey: "categoryDarkForeground_holiday")
        case .observance:
            observanceDarkForegroundHex = hex
            UserDefaults.standard.set(hex, forKey: "categoryDarkForeground_observance")
        case .memo:
            memoDarkForegroundHex = hex
            UserDefaults.standard.set(hex, forKey: "categoryDarkForeground_memo")
        }
    }

    /// Set color hex for a specific display category
    func setColorHex(_ hex: String, for category: DisplayCategory) {
        switch category {
        case .holiday: holidayColorHex = hex
        case .observance: observanceColorHex = hex
        case .memo: memoColorHex = hex
        }
        // Sync to widget via App Group
        CategoryColorStorage.save()
    }

    /// Reset a specific category color to default
    func resetColor(for category: DisplayCategory) {
        switch category {
        case .holiday:
            holidayColorHex = Self.defaultHolidayHex
            holidayForegroundHex = Self.defaultHolidayForegroundHex
            holidayDarkColorHex = Self.defaultHolidayDarkHex
            holidayDarkForegroundHex = Self.defaultHolidayDarkForegroundHex
        case .observance:
            observanceColorHex = Self.defaultObservanceHex
            observanceForegroundHex = Self.defaultObservanceForegroundHex
            observanceDarkColorHex = Self.defaultObservanceDarkHex
            observanceDarkForegroundHex = Self.defaultObservanceDarkForegroundHex
        case .memo:
            memoColorHex = Self.defaultMemoHex
            memoForegroundHex = Self.defaultMemoForegroundHex
            memoDarkColorHex = Self.defaultMemoDarkHex
            memoDarkForegroundHex = Self.defaultMemoDarkForegroundHex
        }
        CategoryColorStorage.save()
    }

    /// Reset all colors to defaults
    func resetToDefaults() {
        holidayColorHex = Self.defaultHolidayHex
        observanceColorHex = Self.defaultObservanceHex
        memoColorHex = Self.defaultMemoHex
        holidayForegroundHex = Self.defaultHolidayForegroundHex
        observanceForegroundHex = Self.defaultObservanceForegroundHex
        memoForegroundHex = Self.defaultMemoForegroundHex
        holidayDarkColorHex = Self.defaultHolidayDarkHex
        observanceDarkColorHex = Self.defaultObservanceDarkHex
        memoDarkColorHex = Self.defaultMemoDarkHex
        holidayDarkForegroundHex = Self.defaultHolidayDarkForegroundHex
        observanceDarkForegroundHex = Self.defaultObservanceDarkForegroundHex
        memoDarkForegroundHex = Self.defaultMemoDarkForegroundHex
        JohoThemeCache.invalidate()
        CategoryColorStorage.save()
    }

    /// Check if a category has a custom (non-default) color
    func hasCustomColor(for category: DisplayCategory) -> Bool {
        switch category {
        case .holiday: return holidayColorHex != Self.defaultHolidayHex
        case .observance: return observanceColorHex != Self.defaultObservanceHex
        case .memo: return memoColorHex != Self.defaultMemoHex
        }
    }

    /// Get default hex for a category
    static func defaultHex(for category: DisplayCategory) -> String {
        switch category {
        case .holiday: return defaultHolidayHex
        case .observance: return defaultObservanceHex
        case .memo: return defaultMemoHex
        }
    }

    /// Get the default color for a category
    static func defaultColor(for category: DisplayCategory) -> Color {
        switch category {
        case .holiday: return Color(hex: defaultHolidayHex)
        case .observance: return Color(hex: defaultObservanceHex)
        case .memo: return Color(hex: defaultMemoHex)
        }
    }
}

// MARK: - JohoColorPickerSheet (情報デザイン: Color Selection)

/// Sheet for selecting category colors from a preset palette
/// Matches 情報デザイン aesthetic with black borders and squircle shapes
/// Includes brightness slider for light/dark adjustment
struct JohoColorPickerSheet: View {
    @Binding var selectedColorHex: String
    let title: String
    let category: DisplayCategory
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // State for brightness adjustment (-0.3 darker to +0.3 lighter)
    @State private var brightnessAdjustment: Double = 0.0
    @State private var selectedBaseHex: String = ""

    // 情報デザイン: Preset colors matching the palette
    private let presetColors: [(name: String, hex: String)] = [
        ("Pink", "FECDD3"),
        ("Cyan", "A5F3FC"),
        ("Yellow", "FFE566"),
        ("Green", "BBF7D0"),
        ("Purple", "E9D5FF"),
        ("Orange", "FED7AA"),
        ("Blue", "BFDBFE"),
        ("Rose", "FECACA"),
        ("Teal", "99F6E4"),
        ("Amber", "FDE68A"),
        ("Indigo", "C7D2FE"),
        ("Lime", "D9F99D"),
    ]

    private let columns = [GridItem(.adaptive(minimum: 64), spacing: JohoDimensions.spacingMD)]

    /// Computed adjusted color based on base + brightness
    private var adjustedColorHex: String {
        guard !selectedBaseHex.isEmpty else { return selectedColorHex }
        return adjustBrightness(hex: selectedBaseHex, adjustment: brightnessAdjustment)
    }

    /// Adjust brightness of a hex color (-1.0 to +1.0)
    private func adjustBrightness(hex: String, adjustment: Double) -> String {
        let color = Color(hex: hex)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Adjust brightness (clamp to valid range)
        let newBrightness = min(1.0, max(0.2, brightness + CGFloat(adjustment)))
        // Also slightly adjust saturation for more natural light/dark
        let satAdjust = adjustment < 0 ? 0.1 : (adjustment > 0 ? -0.15 : 0)
        let newSaturation = min(1.0, max(0.1, saturation + CGFloat(satAdjust)))

        let adjustedColor = UIColor(hue: hue, saturation: newSaturation, brightness: newBrightness, alpha: alpha)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        adjustedColor.getRed(&r, green: &g, blue: &b, alpha: &alpha)

        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM)
                        .background(colors.surface)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: 1.5)
                        )
                }

                Spacer()

                Text(title.uppercased())
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary)

                Spacer()

                Button {
                    // Apply adjusted color
                    selectedColorHex = adjustedColorHex
                    onDone()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(JohoFont.body.bold())
                        .foregroundStyle(Color(hex: adjustedColorHex).contrastingForeground)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM)
                        .background(Color(hex: adjustedColorHex))
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.top, JohoDimensions.spacingMD)
            .padding(.bottom, JohoDimensions.spacingSM)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 2)

            // Preview
            VStack(spacing: JohoDimensions.spacingSM) {
                Text("PREVIEW")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))

                HStack(spacing: JohoDimensions.spacingMD) {
                    // Color swatch preview
                    RoundedRectangle(cornerRadius: JohoDimensions.radiusMedium, style: .continuous)
                        .fill(Color(hex: adjustedColorHex))
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: JohoDimensions.radiusMedium, style: .continuous)
                                .stroke(colors.border, lineWidth: 2)
                        )

                    // Category card preview
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: adjustedColorHex))
                            .frame(height: 32)

                        Rectangle()
                            .fill(colors.border)
                            .frame(height: 1.5)

                        Text(category.localizedLabel.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .frame(height: 28)
                    }
                    .frame(width: 80)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
                }
            }
            .padding(.vertical, JohoDimensions.spacingMD)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1)

            // Color grid
            ScrollView {
                VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                    Text("SELECT COLOR")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.top, JohoDimensions.spacingMD)

                    LazyVGrid(columns: columns, spacing: JohoDimensions.spacingMD) {
                        ForEach(presetColors, id: \.hex) { preset in
                            colorSwatch(hex: preset.hex, name: preset.name)
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)

                    // Brightness slider section
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        Text("BRIGHTNESS")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))

                        // Gradient preview bar
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { i in
                                let adj = Double(i - 3) * 0.1 // -0.3 to +0.3
                                let hex = adjustBrightness(hex: selectedBaseHex.isEmpty ? selectedColorHex : selectedBaseHex, adjustment: adj)
                                Rectangle()
                                    .fill(Color(hex: hex))
                                    .frame(height: 24)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous)
                                .stroke(colors.border, lineWidth: 1.5)
                        )

                        // Slider
                        HStack(spacing: JohoDimensions.spacingSM) {
                            Image(systemName: IconCatalog.moonFill)
                                .font(JohoFont.label)
                                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))

                            Slider(value: $brightnessAdjustment, in: -0.3...0.3, step: 0.05)
                                .tint(Color(hex: adjustedColorHex))

                            Image(systemName: IconCatalog.sunFill)
                                .font(JohoFont.bodySmallBold)
                                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))
                        }

                        // Labels
                        HStack {
                            Text("DARKER")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityMedium))
                            Spacer()
                            Text("LIGHTER")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityMedium))
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                    // Reset to default
                    Button {
                        selectedBaseHex = CategoryColorSettings.defaultHex(for: category)
                        brightnessAdjustment = 0.0
                        selectedColorHex = CategoryColorSettings.defaultHex(for: category)
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: IconCatalog.arrowCounterclockwise)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Text("Reset to Default")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(colors.inputBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusCard))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusCard)
                                .stroke(colors.border, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)
                }
                .padding(.bottom, JohoDimensions.spacingLG)
            }
        }
        .background(colors.surface)
        .presentationDetents([.large])
        .presentationCornerRadius(JohoDimensions.radiusLarge)
        .presentationDragIndicator(.visible)
        .onAppear {
            // Initialize base hex from current selection
            selectedBaseHex = selectedColorHex
        }
    }

    @ViewBuilder
    private func colorSwatch(hex: String, name: String) -> some View {
        // Check if this base color is selected (ignoring brightness adjustment)
        let isSelected = selectedBaseHex.uppercased() == hex.uppercased()

        Button {
            // Set base color and reset brightness
            selectedBaseHex = hex
            brightnessAdjustment = 0.0
            HapticManager.selection()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                        .fill(Color(hex: hex))
                        .frame(width: 52, height: 52)

                    if isSelected {
                        Image(systemName: IconCatalog.checkmark)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                        .stroke(colors.border, lineWidth: isSelected ? 2.5 : 1.5)
                )

                Text(name.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - JohoMonthYearPicker (情報デザイン: Month/Year Navigation)

/// A 情報デザイン compliant month/year picker for calendar navigation
/// Matches the JohoCalendarPicker aesthetic but only selects month and year
struct JohoMonthYearPicker: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    let accentColor: Color
    let onDone: () -> Void
    let onCancel: () -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                          "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

    private var years: [Int] {
        let current = Calendar.iso8601.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    private var currentYear: Int {
        Calendar.iso8601.component(.year, from: Date())
    }

    private var currentMonth: Int {
        Calendar.iso8601.component(.month, from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            headerRow

            JohoDivider(weight: 1.5)

            // Year navigation row
            yearNavigationRow

            JohoDivider(weight: 1.5)

            // Month grid (3x4)
            monthGrid
        }
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous)
                .stroke(colors.border, lineWidth: 2)
        )
        .shadow(color: .black.opacity(JohoDimensions.opacityMild), radius: 20, y: 10)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Button {
                onCancel()
                HapticManager.selection()
            } label: {
                Text("CANCEL")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("SELECT MONTH")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            Button {
                onDone()
                HapticManager.notification(.success)
            } label: {
                Text("DONE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor.contrastingForeground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    // MARK: - Year Navigation

    private var yearNavigationRow: some View {
        HStack(spacing: 0) {
            // Previous year button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedYear -= 1
                }
                HapticManager.selection()
            } label: {
                Image(systemName: IconCatalog.chevronLeft)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            // Year display
            Text(String(selectedYear))
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(selectedYear == currentYear ? accentColor : colors.primary)

            Spacer()

            // Next year button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedYear += 1
                }
                HapticManager.selection()
            } label: {
                Image(systemName: IconCatalog.chevronRight)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, JohoDimensions.spacingSM)
        .frame(height: 52)
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 4), spacing: 0) {
            ForEach(1...12, id: \.self) { month in
                monthCell(month)
            }
        }
    }

    private func monthCell(_ month: Int) -> some View {
        let isSelected = month == selectedMonth
        let isCurrentMonth = month == currentMonth && selectedYear == currentYear

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMonth = month
            }
            HapticManager.selection()
        } label: {
            Text(months[month - 1])
                .font(.system(size: 14, weight: isSelected ? .heavy : .bold, design: .rounded))
                .foregroundStyle(isSelected ? accentColor.contrastingForeground : colors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    isSelected ? accentColor :
                    isCurrentMonth ? JohoColors.yellow.opacity(JohoDimensions.opacityMedium) :
                    colors.surface
                )
                .overlay(
                    Rectangle()
                        .stroke(colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - JohoMonthYearPicker Overlay

/// Overlay modifier for presenting JohoMonthYearPicker floating over content
struct JohoMonthYearPickerOverlay: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    JohoMonthYearPicker(
                        selectedMonth: $selectedMonth,
                        selectedYear: $selectedYear,
                        accentColor: accentColor,
                        onDone: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        },
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }
                    )
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    /// Present a floating month/year picker overlay
    func johoYearPicker(
        isPresented: Binding<Bool>,
        selectedMonth: Binding<Int>,
        selectedYear: Binding<Int>,
        accentColor: Color
    ) -> some View {
        modifier(JohoMonthYearPickerOverlay(
            isPresented: isPresented,
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            accentColor: accentColor
        ))
    }
}
