//
//  CountdownComponents.swift
//  Vecka
//
//  Master Swift refactoring - Countdown functionality and views
//  Following Apple Human Interface Guidelines and Glass aesthetic
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Countdown Models

/// Custom countdown event with XPC-safe operations
struct CustomCountdown: Codable, Hashable {
    let name: String
    let date: Date
    let isAnnual: Bool
    let iconName: String?
    
    // Cache month and day components to avoid XPC-sensitive operations
    private let cachedMonth: Int?
    private let cachedDay: Int?
    
    // MARK: - Initializers
    
    init(name: String, date: Date, isAnnual: Bool, iconName: String? = nil) {
        self.name = name
        self.date = date
        self.isAnnual = isAnnual
        self.iconName = iconName
        
        // Pre-compute and cache month/day components during initialization
        if isAnnual {
            let calendar = Calendar.iso8601
            let components = calendar.dateComponents([.month, .day], from: date)
            self.cachedMonth = components.month
            self.cachedDay = components.day
        } else {
            self.cachedMonth = nil
            self.cachedDay = nil
        }
    }
    
    // MARK: - Codable Support with Backward Compatibility
    
    private enum CodingKeys: String, CodingKey {
        case name, date, isAnnual, cachedMonth, cachedDay, iconName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(Date.self, forKey: .date)
        isAnnual = try container.decode(Bool.self, forKey: .isAnnual)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        
        // Handle cached components with backward compatibility
        if let month = try container.decodeIfPresent(Int.self, forKey: .cachedMonth),
           let day = try container.decodeIfPresent(Int.self, forKey: .cachedDay) {
            self.cachedMonth = month
            self.cachedDay = day
        } else if isAnnual {
            // Fallback: compute during decoding for backward compatibility
            let calendar = Calendar.iso8601
            let components = calendar.dateComponents([.month, .day], from: date)
            self.cachedMonth = components.month
            self.cachedDay = components.day
        } else {
            self.cachedMonth = nil
            self.cachedDay = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(date, forKey: .date)
        try container.encode(isAnnual, forKey: .isAnnual)
        try container.encodeIfPresent(cachedMonth, forKey: .cachedMonth)
        try container.encodeIfPresent(cachedDay, forKey: .cachedDay)
        try container.encodeIfPresent(iconName, forKey: .iconName)
    }
    
    // MARK: - Target Date Calculation
    
    /// Compute target date for countdown (XPC-safe)
    func computeTargetDate(for currentYear: Int) -> Date? {
        if isAnnual {
            guard let month = cachedMonth, let day = cachedDay else {
                return date // Fallback to original date
            }
            
            let calendar = Calendar.iso8601
            var components = DateComponents()
            components.year = currentYear
            components.month = month
            components.day = day
            
            guard let targetDate = calendar.date(from: components) else {
                return date // Fallback to original date
            }
            
            // If target date has passed this year, use next year
            if targetDate < Date() {
                components.year = currentYear + 1
                return calendar.date(from: components) ?? date
            }
            
            return targetDate
        } else {
            return date
        }
    }
}

/// Predefined countdown types
enum CountdownType: String, CaseIterable, Codable {
    case newYear = "new_year"
    case christmas = "christmas"
    case summer = "summer"
    case valentines = "valentines"
    case halloween = "halloween"
    case midsummer = "midsummer"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .newYear: return "New Year"
        case .christmas: return "Christmas"
        case .summer: return "Summer"
        case .valentines: return "Valentine's Day"
        case .halloween: return "Halloween"
        case .midsummer: return "Midsummer"
        case .custom: return "Custom Event"
        }
    }
    
    var icon: String {
        switch self {
        case .newYear: return "sparkles"
        case .christmas: return "tree.fill"
        case .summer: return "sun.max.fill"
        case .valentines: return "heart.fill"
        case .halloween: return "moon.stars.fill"
        case .midsummer: return "leaf.fill"
        case .custom: return "calendar.badge.plus"
        }
    }
    
    var targetDate: Date {
        // Backward-compat convenience; uses "today" as the base date
        return targetDate(from: Date())
    }

    /// Target date computed using an arbitrary base date (e.g. selectedDate).
    /// This lets the UI show countdown relative to the currently selected day/week.
    func targetDate(from baseDate: Date) -> Date {
        let calendar = Calendar.iso8601
        let baseYear = calendar.component(.year, from: baseDate)

        var components = DateComponents()
        components.year = baseYear

        switch self {
        case .newYear:
            components.month = 1
            components.day = 1
        case .christmas:
            components.month = 12
            components.day = 25
        case .summer:
            components.month = 6
            components.day = 21
        case .valentines:
            components.month = 2
            components.day = 14
        case .halloween:
            components.month = 10
            components.day = 31
        case .midsummer:
            components.month = 6
            components.day = 24
        case .custom:
            return baseDate
        }

        guard let dateThisYear = calendar.date(from: components) else {
            return baseDate
        }

        // If the date has passed relative to the base date's start of day, use next year
        let startOfBase = calendar.startOfDay(for: baseDate)
        if dateThisYear < startOfBase {
            components.year = baseYear + 1
            return calendar.date(from: components) ?? dateThisYear
        }

        return dateThisYear
    }
}

// MARK: - Countdown Card Component
/// Apple HIG-compliant countdown selection card
struct CountdownCard: View {
    let countdownType: CountdownType
    let customCountdown: CustomCountdown?
    let isSelected: Bool
    let action: () -> Void
    var titleOverride: String? = nil
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                countdownIcon
                
                VStack(spacing: 4) {
                    countdownTitle
                    countdownSubtitle
                }
                
                if isSelected {
                    selectedIndicator
                }
            }
            .frame(maxWidth: .infinity)
            .padding(LayoutConstants.cardSpacing)
            .background(cardBackground)
            .overlay(cardBorder)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius))
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: shadowColor, radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(AnimationConstants.quickSpring, value: isSelected)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Icon
    
    private var countdownIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 50, height: 50)
            
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(iconForegroundColor)
        }
    }
    
    private var iconBackgroundColor: Color {
        if isSelected {
            return AppColors.accentBlue.opacity(0.2)
        }
        
        return AppColors.textTertiary.opacity(0.1)
    }
    
    private var iconForegroundColor: Color {
        if isSelected {
            return AppColors.accentBlue
        }
        
        return AppColors.textSecondary
    }
    
    // MARK: - Text Content
    
    private var countdownTitle: some View {
        Text(titleText)
            .font(.system(size: 16, weight: .semibold, design: .default))
            .foregroundStyle(AppColors.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
    }
    
    private var countdownSubtitle: some View {
        Text(subtitleText)
            .font(.system(size: 12, weight: .medium, design: .default))
            .foregroundStyle(AppColors.textSecondary)
            .lineLimit(1)
            .textCase(.uppercase)
            .tracking(0.5)
    }
    
    private var titleText: String {
        if let override = titleOverride { return override }
        if countdownType == .custom, let custom = customCountdown { return custom.name }
        return countdownType.displayName
    }
    
    private var subtitleText: String {
        if countdownType == .custom {
            return "CUSTOM EVENT"
        }
        
        let days = daysUntilCountdown
        if days == 0 {
            return "TODAY"
        } else if days == 1 {
            return "TOMORROW"
        } else {
            return "\(days) DAYS"
        }
    }
    
    // MARK: - Selection Indicator
    
    private var selectedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .bold))
            Text("SELECTED")
                .font(.system(size: 10, weight: .bold, design: .default))
                .tracking(0.5)
        }
        .foregroundStyle(AppColors.accentBlue)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(AppColors.accentBlue.opacity(0.2))
        )
    }
    
    // MARK: - Card Styling
    
    private var cardBackground: some View {
        Rectangle()
            .fill(AnyShapeStyle(Material.thinMaterial))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius)
            .stroke(borderColor, lineWidth: isSelected ? 1.5 : 0.5)
    }
    
    private var borderColor: Color {
        if isSelected {
            return AppColors.accentBlue.opacity(0.6)
        }
        
        return Color.white.opacity(0.2)
    }
    
    private var shadowColor: Color {
        if isSelected {
            return AppColors.accentBlue.opacity(0.3)
        }
        
        return Color.black.opacity(0.1)
    }
    
    // MARK: - Helper Properties
    
    private var daysUntilCountdown: Int {
        let targetDate = countdownType == .custom ? (customCountdown?.date ?? Date()) : countdownType.targetDate
        let cal = Calendar.iso8601
        return cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: targetDate)).day ?? 0
    }
    
    private var accessibilityLabel: String {
        let days = daysUntilCountdown
        let daysText = days == 0 ? "today" : days == 1 ? "tomorrow" : "\(days) days away"
        let selectedText = isSelected ? "selected" : "not selected"
        
        return "\(titleText), \(daysText), \(selectedText)"
    }

    private var iconName: String {
        if countdownType == .custom, let custom = customCountdown, let icon = custom.iconName {
            return icon
        }
        return countdownType.icon
    }
}

// MARK: - Saved Countdown (Favorites)
struct SavedCountdown: Codable, Hashable, Identifiable {
    let type: CountdownType
    let custom: CustomCountdown?
    var id: String { type == .custom ? (custom?.name ?? "custom") + "_" + String(custom?.date.timeIntervalSince1970 ?? 0) : type.rawValue }
    
    var displayName: String {
        if type == .custom { return custom?.name ?? "Custom" }
        return type.displayName
    }
    
    var icon: String {
        if type == .custom { return custom?.iconName ?? CountdownType.custom.icon }
        return type.icon
    }
}

// MARK: - Countdown Picker Sheet
/// Apple HIG-compliant sheet for countdown selection
struct CountdownPickerSheet: View {
    @Binding var selectedCountdown: CountdownType
    @State private var customCountdowns: [CustomCountdown] = []
    @State private var favorites: [SavedCountdown] = []
    @Environment(\.dismiss) private var dismiss
    
    let onSave: () -> Void
    
    // Create Custom flow
    @State private var showingCustomDialog = false
    @State private var newCustomName: String = ""
    @State private var newCustomDate: Date = Date()
    @State private var newCustomAnnual: Bool = true
    // Disclosure state to reduce clutter
    @State private var showPredefined: Bool = false
    @State private var showCustomEvents: Bool = true
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                // Selected summary
                Section(Localization.selectedHeader) {
                    selectedRow
                }

                // Favorites (quick picks)
                if !favorites.isEmpty {
                    Section(footer: Text(String(format: Localization.favoritesCountFormat, favorites.count)).font(.caption).foregroundStyle(.secondary)) {
                        ForEach(favorites) { fav in
                            favoriteRow(fav)
                        }
                        .onDelete(perform: removeFavorites)
                        .onMove(perform: moveFavorites)
                    }
                }

                // Predefined (collapsed by default)
                Section {
                    DisclosureGroup(isExpanded: $showPredefined) {
                        ForEach(CountdownType.allCases.filter { $0 != .custom }, id: \.self) { t in
                            eventRow(type: t, custom: nil)
                        }
                    } label: {
                        Label(Localization.predefined, systemImage: "list.bullet")
                            .font(.body.weight(.semibold))
                    }
                }

                // Custom events (expanded by default)
                Section {
                    DisclosureGroup(isExpanded: $showCustomEvents) {
                        if customCountdowns.isEmpty {
                            Text(Localization.noCustomsHint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(customCountdowns, id: \.self) { custom in
                                eventRow(type: .custom, custom: custom)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteCustom(custom)
                                        } label: { Label(Localization.delete, systemImage: "trash") }
                                    }
                            }
                        }
                        Button(action: { showingCustomDialog = true; HapticManager.selection() }) {
                            Label(Localization.createCustom, systemImage: "plus.circle")
                        }
                    } label: {
                        Label(Localization.customEvents, systemImage: "person.crop.square")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .navigationTitle("Choose Countdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button(Localization.cancel) { dismiss() } }
                ToolbarItem(placement: .navigationBarLeading) { EditButton() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Localization.save) { onSave(); dismiss() }.fontWeight(.semibold)
                }
            }
            .environment(\.editMode, $editMode)
        }
        .onAppear { loadCustomCountdowns(); loadFavorites() }
        .sheet(isPresented: $showingCustomDialog) {
            CustomCountdownDialog(
                name: $newCustomName,
                date: $newCustomDate,
                isAnnual: $newCustomAnnual,
                selectedCountdown: $selectedCountdown,
                onSave: {
                    // After dialog saves to UserDefaults, refresh our list
                    loadCustomCountdowns(); loadFavorites()
                    selectedCountdown = .custom
                }
            )
        }
    }
    
    private func loadCustomCountdowns() {
        // Load custom countdowns from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "customCountdowns"),
           let countdowns = try? JSONDecoder().decode([CustomCountdown].self, from: data) {
            customCountdowns = countdowns
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favoriteCountdowns"),
           let favs = try? JSONDecoder().decode([SavedCountdown].self, from: data) {
            favorites = Array(favs.prefix(4))
        }
    }
    
    private func saveFavorites() {
        let trimmed = Array(favorites.prefix(4))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: "favoriteCountdowns")
        }
    }
    
    private func addFavorite(_ item: SavedCountdown) {
        if favorites.contains(item) { return }
        if favorites.count >= 4 { favorites.removeFirst() }
        favorites.append(item)
        saveFavorites()
    }
    
    private func removeFavorites(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        saveFavorites()
    }
    
    private func moveFavorites(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
        saveFavorites()
    }
    
    @ViewBuilder
    private func eventRow(type: CountdownType, custom: CustomCountdown?) -> some View {
        let isSelectedRow = (type == selectedCountdown)
        let icon = (type == .custom ? (custom?.iconName ?? type.icon) : type.icon)
        let title = (type == .custom ? (custom?.name ?? "Custom") : type.displayName)
        HStack {
            Image(systemName: icon).foregroundStyle(AppColors.textSecondary)
            Text(title)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Button(action: {
                let wasFavorite = favorites.contains(SavedCountdown(type: type, custom: custom))
                toggleFavorite(type: type, custom: custom)
                let announcement = wasFavorite ? Localization.unfavorite : Localization.favorite
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }) {
                Image(systemName: favorites.contains(SavedCountdown(type: type, custom: custom)) ? "star.fill" : "star")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(favorites.contains(SavedCountdown(type: type, custom: custom)) ? Localization.unfavorite : Localization.favorite)
            .accessibilityValue(favorites.contains(SavedCountdown(type: type, custom: custom)) ? "on" : "off")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCountdown = type
            if type == .custom, let custom = custom, let data = try? JSONEncoder().encode(custom) {
                UserDefaults.standard.set(data, forKey: "selectedCustomCountdown")
            }
            HapticManager.selection()
        }
        .accessibilityLabel("\(title)\(isSelectedRow ? ", selected" : "")")
    }
    
    // Minimal row without trailing star to reduce clutter; use swipe to favorite
    @ViewBuilder
    private func slimEventRow(type: CountdownType, custom: CustomCountdown?) -> some View {
        let isSelectedRow = (type == selectedCountdown)
        let icon = (type == .custom ? (custom?.iconName ?? type.icon) : type.icon)
        let title = (type == .custom ? (custom?.name ?? "Custom") : type.displayName)
        HStack {
            Image(systemName: icon).foregroundStyle(AppColors.textSecondary)
            Text(title).foregroundStyle(AppColors.textPrimary)
            Spacer()
            if isSelectedRow { Image(systemName: "checkmark").foregroundStyle(AppColors.accentBlue) }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCountdown = type
            if type == .custom, let custom = custom, let data = try? JSONEncoder().encode(custom) {
                UserDefaults.standard.set(data, forKey: "selectedCustomCountdown")
            }
            HapticManager.selection()
        }
        .swipeActions(edge: .leading) {
            if favorites.contains(SavedCountdown(type: type, custom: custom)) {
                Button(role: .destructive) { toggleFavorite(type: type, custom: custom) } label: { Label("Unfavorite", systemImage: "star.slash") }
            } else {
                Button { toggleFavorite(type: type, custom: custom) } label: { Label("Favorite", systemImage: "star") }
                    .tint(AppColors.accentBlue)
            }
        }
    }
    
    private func toggleFavorite(type: CountdownType, custom: CustomCountdown?) {
        let item = SavedCountdown(type: type, custom: custom)
        if let idx = favorites.firstIndex(of: item) {
            favorites.remove(at: idx)
        } else {
            if favorites.count >= 4 { favorites.removeFirst() }
            favorites.append(item)
        }
        saveFavorites()
    }
    
    private func deleteCustom(_ custom: CustomCountdown) {
        // Remove from saved customs
        customCountdowns.removeAll { $0 == custom }
        if let data = try? JSONEncoder().encode(customCountdowns) {
            UserDefaults.standard.set(data, forKey: "customCountdowns")
        }
        // Remove any favorite referencing it
        favorites.removeAll { $0.type == .custom && $0.custom == custom }
        saveFavorites()
        // If it was selected, fallback to a safe default
        if selectedCountdown == .custom,
           let selData = UserDefaults.standard.data(forKey: "selectedCustomCountdown"),
           let sel = try? JSONDecoder().decode(CustomCountdown.self, from: selData), sel == custom {
            UserDefaults.standard.removeObject(forKey: "selectedCustomCountdown")
            selectedCountdown = .newYear
        }
    }
    
    @ViewBuilder
    private func favoriteRow(_ fav: SavedCountdown) -> some View {
        HStack {
            Image(systemName: fav.icon).foregroundStyle(AppColors.textSecondary)
            Text(fav.displayName)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            if (fav.type == selectedCountdown) { Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColors.accentBlue) }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCountdown = fav.type
            if fav.type == .custom, let custom = fav.custom, let data = try? JSONEncoder().encode(custom) {
                UserDefaults.standard.set(data, forKey: "selectedCustomCountdown")
            }
            HapticManager.selection()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                if let idx = favorites.firstIndex(of: fav) { favorites.remove(at: idx); saveFavorites() }
                UIAccessibility.post(notification: .announcement, argument: Localization.remove)
            } label: { Label(Localization.remove, systemImage: "trash") }
        }
    }

    // MARK: - Selected Summary Row
    private var selectedRow: some View {
        let current: SavedCountdown = {
            if selectedCountdown == .custom,
               let data = UserDefaults.standard.data(forKey: "selectedCustomCountdown"),
               let custom = try? JSONDecoder().decode(CustomCountdown.self, from: data) {
                return SavedCountdown(type: .custom, custom: custom)
            } else {
                return SavedCountdown(type: selectedCountdown, custom: nil)
            }
        }()
        return HStack {
            Image(systemName: current.icon).foregroundStyle(AppColors.textSecondary)
            Text(current.displayName)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColors.accentBlue)
        }
    }
}

// MARK: - Custom Countdown Dialog
/// Apple HIG-compliant dialog for creating custom countdowns
struct CustomCountdownDialog: View {
    @Binding var name: String
    @Binding var date: Date
    @Binding var isAnnual: Bool
    @Binding var selectedCountdown: CountdownType
    @Environment(\.dismiss) private var dismiss
    
    let onSave: () -> Void
    
    // Icon selection
    @State private var iconName: String = LucidIcon.defaultIcon
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Event Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("Event Date", selection: $date, displayedComponents: [.date])
                    
                    Toggle("Repeat Annually", isOn: $isAnnual)
                } header: {
                    Text("Event Details")
                } footer: {
                    Text(footerText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Icon") {
                    IconPickerGrid(selectedIcon: $iconName)
                }
            }
            .navigationTitle("Custom Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCustomCountdown()
                        selectedCountdown = .custom
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private var footerText: String {
        if isAnnual {
            return "This event will repeat every year on the same date."
        } else {
            return "This is a one-time event that won't repeat."
        }
    }
    
    private func saveCustomCountdown() {
        let countdown = CustomCountdown(name: name, date: date, isAnnual: isAnnual, iconName: iconName)
        
        // Save to UserDefaults
        var existingCountdowns: [CustomCountdown] = []
        if let data = UserDefaults.standard.data(forKey: "customCountdowns"),
           let countdowns = try? JSONDecoder().decode([CustomCountdown].self, from: data) {
            existingCountdowns = countdowns
        }
        // Limit to maximum two saved custom events
        if existingCountdowns.count >= 2 { existingCountdowns.removeFirst() }
        existingCountdowns.append(countdown)
        
        if let data = try? JSONEncoder().encode(existingCountdowns) {
            UserDefaults.standard.set(data, forKey: "customCountdowns")
        }

        // Also persist this just-created countdown as the currently selected custom event
        if let selectedData = try? JSONEncoder().encode(countdown) {
            UserDefaults.standard.set(selectedData, forKey: "selectedCustomCountdown")
        }
    }
}

// MARK: - Lucid Flat Icons
enum LucidIcon: String, CaseIterable {
    case sparkles = "sparkles"
    case tree = "tree.fill"
    case sun = "sun.max.fill"
    case heart = "heart.fill"
    case moon = "moon.stars.fill"
    case leaf = "leaf.fill"
    case gift = "gift.fill"
    case calendar = "calendar"
    case party = "party.popper"
    case star = "star.fill"
    
    static var defaultIcon: String { Self.sparkles.rawValue }
    static var allNames: [String] { Self.allCases.map { $0.rawValue } }
}

struct IconPickerGrid: View {
    @Binding var selectedIcon: String
    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(LucidIcon.allNames, id: \.self) { name in
                Button(action: { selectedIcon = name; HapticManager.selection() }) {
                    ZStack {
                        Circle()
                            .fill(selectedIcon == name ? AppColors.accentBlue.opacity(0.22) : AppColors.textTertiary.opacity(0.08))
                            .frame(width: 44, height: 44)
                        Image(systemName: name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(selectedIcon == name ? AppColors.accentBlue : AppColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
