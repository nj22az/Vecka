//
//  CountdownViews.swift
//  Vecka
//
//  Extracted views for countdown functionality
//

import SwiftUI

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
            return JohoColors.cyan.opacity(0.2)
        }
        
        return JohoColors.black.opacity(0.5).opacity(0.1)
    }
    
    private var iconForegroundColor: Color {
        if isSelected {
            return JohoColors.cyan
        }
        
        return JohoColors.black.opacity(0.7)
    }
    
    // MARK: - Text Content
    
    private var countdownTitle: some View {
        Text(titleText)
            .font(Typography.labelLarge)
            .foregroundStyle(JohoColors.black)
            .lineLimit(2)
            .multilineTextAlignment(.center)
    }

    private var countdownSubtitle: some View {
        Text(subtitleText)
            .font(Typography.caption1.weight(.medium))
            .foregroundStyle(JohoColors.black.opacity(0.7))
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
            return NSLocalizedString("countdown.custom_event", comment: "Custom Event")
        }
        
        let days = daysUntilCountdown
        if days == 0 {
            return NSLocalizedString("countdown.today", comment: "Today")
        } else if days == 1 {
            return NSLocalizedString("countdown.tomorrow", comment: "Tomorrow")
        } else {
            let suffix = NSLocalizedString("countdown.days_suffix", comment: "DAYS")
            return "\(days) \(suffix)"
        }
    }
    
    // MARK: - Selection Indicator
    
    private var selectedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.caption1.weight(.bold))
            Text(NSLocalizedString("picker.selected", comment: "Selected").uppercased())
                .font(Typography.caption2.weight(.bold))
                .tracking(0.5)
        }
        .foregroundStyle(JohoColors.cyan)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(JohoColors.cyan.opacity(0.2))
        )
    }
    
    // MARK: - Card Styling
    
    private var cardBackground: some View {
        Squircle(cornerRadius: LayoutConstants.cornerRadius)
            .fill(JohoColors.white)
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius)
            .stroke(borderColor, lineWidth: isSelected ? 1.5 : 0.5)
    }
    
    private var borderColor: Color {
        if isSelected {
            return JohoColors.cyan.opacity(0.6)
        }
        
        return Color.white.opacity(0.2)
    }
    
    private var shadowColor: Color {
        if isSelected {
            return JohoColors.cyan.opacity(0.3)
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
        let daysText: String
        if days == 0 {
            daysText = NSLocalizedString("countdown.today", comment: "today")
        } else if days == 1 {
            daysText = NSLocalizedString("countdown.tomorrow", comment: "tomorrow")
        } else {
             let suffix = NSLocalizedString("countdown.days_suffix", comment: "days")
             daysText = "\(days) \(suffix)"
        }
        
        let selectedText = isSelected ? NSLocalizedString("accessibility.selected", comment: "selected") : ""
        
        return "\(titleText), \(daysText), \(selectedText)"
    }

    private var iconName: String {
        if countdownType == .custom, let custom = customCountdown, let icon = custom.iconName {
            return icon
        }
        return countdownType.icon
    }
}

// MARK: - Countdown Picker Sheet
/// Apple HIG-compliant sheet for countdown selection
struct CountdownPickerSheet: View {
    @Binding var selectedCountdown: CountdownType
    @State private var customCountdowns: [CustomCountdown] = []
    @State private var favorites: [SavedCountdown] = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onSave: () -> Void
    
    // Create Custom flow
    @State private var showingCustomDialog = false
    @State private var newCustomName: String = ""
    @State private var newCustomDate: Date = Date()
    @State private var newCustomAnnual: Bool = false
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
        let maxFavorites = ConfigurationManager.shared.getInt("max_favorites", context: modelContext, default: 4)
        if favorites.count >= maxFavorites { favorites.removeFirst() }
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
            Image(systemName: icon).foregroundStyle(JohoColors.black.opacity(0.7))
            Text(title)
                .foregroundStyle(JohoColors.black)
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
            Image(systemName: icon).foregroundStyle(JohoColors.black.opacity(0.7))
            Text(title).foregroundStyle(JohoColors.black)
            Spacer()
            if isSelectedRow { Image(systemName: "checkmark").foregroundStyle(JohoColors.cyan) }
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
        .accessibilityAddTraits(.isButton)
        .swipeActions(edge: .leading) {
            if favorites.contains(SavedCountdown(type: type, custom: custom)) {
                Button(role: .destructive) { toggleFavorite(type: type, custom: custom) } label: { Label("Unfavorite", systemImage: "star.slash") }
            } else {
                Button { toggleFavorite(type: type, custom: custom) } label: { Label("Favorite", systemImage: "star") }
                    .tint(JohoColors.cyan)
            }
        }
    }
    
    private func toggleFavorite(type: CountdownType, custom: CustomCountdown?) {
        let item = SavedCountdown(type: type, custom: custom)
        if let idx = favorites.firstIndex(of: item) {
            favorites.remove(at: idx)
        } else {
            let maxFavorites = ConfigurationManager.shared.getInt("max_favorites", context: modelContext, default: 4)
            if favorites.count >= maxFavorites { favorites.removeFirst() }
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
            Image(systemName: fav.icon).foregroundStyle(JohoColors.black.opacity(0.7))
            Text(fav.displayName)
                .foregroundStyle(JohoColors.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            if (fav.type == selectedCountdown) { Image(systemName: "checkmark.circle.fill").foregroundStyle(JohoColors.cyan) }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCountdown = fav.type
            if fav.type == .custom, let custom = fav.custom, let data = try? JSONEncoder().encode(custom) {
                UserDefaults.standard.set(data, forKey: "selectedCustomCountdown")
            }
            HapticManager.selection()
        }
        .accessibilityLabel("\(fav.displayName)\(fav.type == selectedCountdown ? ", selected" : "")")
        .accessibilityAddTraits(.isButton)
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
            Image(systemName: current.icon).foregroundStyle(JohoColors.black.opacity(0.7))
            Text(current.displayName)
                .foregroundStyle(JohoColors.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundStyle(JohoColors.cyan)
        }
    }
}

// MARK: - Custom Countdown Dialog
/// 情報デザイン compliant dialog for creating custom events (matches Holiday/Observance editor)
struct CustomCountdownDialog: View {
    @Binding var name: String
    @Binding var date: Date
    @Binding var isAnnual: Bool
    @Binding var selectedCountdown: CountdownType
    @Environment(\.dismiss) private var dismiss

    let onSave: () -> Void

    // Icon selection
    @State private var iconName: String = "calendar.badge.clock"
    @State private var showingIconPicker = false

    // Event type color (purple for events)
    private let eventColor = SpecialDayType.event.accentColor

    // Color palette for icon backgrounds
    private let iconColorPalette: [(name: String, hex: String)] = [
        ("Purple", "E9D5FF"),
        ("Cyan", "A5F3FC"),
        ("Pink", "FECDD3"),
        ("Yellow", "FFE566"),
        ("Green", "BBF7D0"),
        ("Orange", "FED7AA")
    ]
    @State private var selectedIconColor: String? = "E9D5FF"

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var iconBackgroundColor: Color {
        if let hex = selectedIconColor {
            return Color(hex: hex)
        }
        return eventColor.opacity(0.2)
    }

    // Date components
    private var selectedYear: Int {
        Calendar.current.component(.year, from: date)
    }

    private var selectedMonth: Int {
        Calendar.current.component(.month, from: date)
    }

    private var selectedDay: Int {
        Calendar.current.component(.day, from: date)
    }

    private var yearRange: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header with Cancel/Save buttons
                HStack {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    Spacer()

                    Button {
                        saveCustomCountdown()
                        selectedCountdown = .custom
                        onSave()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(JohoFont.body.bold())
                            .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                            .padding(.horizontal, JohoDimensions.spacingLG)
                            .padding(.vertical, JohoDimensions.spacingMD)
                            .background(canSave ? eventColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }
                    .disabled(!canSave)
                }
                .padding(.top, JohoDimensions.spacingLG)

                // Main content card
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Title with type indicator - 情報デザイン: Filled circle with BLACK border
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Circle()
                            .fill(eventColor)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
                        Text("New Event")
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Icon & Color row
                    HStack(spacing: JohoDimensions.spacingMD) {
                        // Icon selector
                        Button { showingIconPicker = true } label: {
                            Image(systemName: iconName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 56, height: 56)
                                .background(iconBackgroundColor)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                                )
                        }

                        // Color picker (compact)
                        HStack(spacing: 8) {
                            ForEach(iconColorPalette, id: \.hex) { color in
                                Button {
                                    selectedIconColor = color.hex
                                    HapticManager.selection()
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color.hex))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(JohoColors.black, lineWidth: selectedIconColor == color.hex ? 3 : 1)
                                        )
                                }
                            }
                        }
                    }

                    // Name field
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "NAME", style: .whiteOnBlack, size: .small)

                        TextField("e.g., Anniversary", text: $name)
                            .font(JohoFont.headline)
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Date picker (情報デザイン: Year, Month, Day)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "DATE", style: .whiteOnBlack, size: .small)

                        HStack(spacing: JohoDimensions.spacingSM) {
                            // Year picker
                            VStack(alignment: .leading, spacing: 4) {
                                Text("YEAR")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(yearRange, id: \.self) { year in
                                        Button {
                                            updateDate(year: year, month: selectedMonth, day: selectedDay)
                                        } label: {
                                            Text(String(year))
                                        }
                                    }
                                } label: {
                                    Text(String(selectedYear))
                                        .font(JohoFont.body)
                                        .monospacedDigit()
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(width: 70)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }

                            // Month picker
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MONTH")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(1...12, id: \.self) { month in
                                        Button {
                                            updateDate(year: selectedYear, month: month, day: selectedDay)
                                        } label: {
                                            Text(monthName(month))
                                        }
                                    }
                                } label: {
                                    Text(monthName(selectedMonth))
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }

                            // Day picker
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DAY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                                        Button {
                                            updateDate(year: selectedYear, month: selectedMonth, day: day)
                                        } label: {
                                            Text("\(day)")
                                        }
                                    }
                                } label: {
                                    Text("\(selectedDay)")
                                        .font(JohoFont.body)
                                        .monospacedDigit()
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(width: 50)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }
                        }
                    }

                    // Repeat annually toggle
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "REPEAT", style: .whiteOnBlack, size: .small)

                        HStack {
                            Text("Repeat annually")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)

                            Spacer()

                            // 情報デザイン toggle
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    isAnnual.toggle()
                                }
                                HapticManager.selection()
                            } label: {
                                ZStack(alignment: isAnnual ? .trailing : .leading) {
                                    Capsule()
                                        .fill(isAnnual ? eventColor : JohoColors.black.opacity(0.2))
                                        .frame(width: 50, height: 28)
                                        .overlay(
                                            Capsule()
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )

                                    Circle()
                                        .fill(JohoColors.white)
                                        .frame(width: 22, height: 22)
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
                                        .padding(3)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(JohoDimensions.spacingMD)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                    }
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .navigationBarHidden(true)
        .sheet(isPresented: $showingIconPicker) {
            JohoIconPickerSheet(selectedSymbol: $iconName)
        }
    }

    // MARK: - Helper Functions

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: 2024, month: month, day: 1)
        let tempDate = calendar.date(from: dateComponents) ?? Date()
        return formatter.string(from: tempDate)
    }

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        guard let tempDate = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: tempDate) else {
            return 31
        }
        return range.count
    }

    private func updateDate(year: Int, month: Int, day: Int) {
        let calendar = Calendar.current
        let maxDay = daysInMonth(month, year: year)
        let validDay = min(day, maxDay)
        if let newDate = calendar.date(from: DateComponents(year: year, month: month, day: validDay)) {
            date = newDate
        }
    }

    @Environment(\.modelContext) private var modelContext

    private func saveCustomCountdown() {
        // Save to SwiftData as CountdownEvent (the source of truth for event display)
        let event = CountdownEvent(
            title: name,
            targetDate: date,
            icon: iconName,
            colorHex: selectedIconColor.map { "#\($0)" } ?? "#805AD5",
            isSystem: false
        )
        modelContext.insert(event)
        do {
            try modelContext.save()
        } catch {
            Log.w("Failed to save event: \(error.localizedDescription)")
        }

        // Also save to UserDefaults for legacy countdown banner compatibility
        let countdown = CustomCountdown(name: name, date: date, isAnnual: isAnnual, iconName: iconName)
        var existingCountdowns: [CustomCountdown] = []
        if let data = UserDefaults.standard.data(forKey: "customCountdowns"),
           let countdowns = try? JSONDecoder().decode([CustomCountdown].self, from: data) {
            existingCountdowns = countdowns
        }
        if existingCountdowns.count >= 2 { existingCountdowns.removeFirst() }
        existingCountdowns.append(countdown)

        if let data = try? JSONEncoder().encode(existingCountdowns) {
            UserDefaults.standard.set(data, forKey: "customCountdowns")
        }

        if let selectedData = try? JSONEncoder().encode(countdown) {
            UserDefaults.standard.set(selectedData, forKey: "selectedCustomCountdown")
        }
    }
}

// MARK: - 情報デザイン Icon Picker Grid
private struct JohoIconPickerGrid: View {
    @Binding var selectedIcon: String
    private let columns = [GridItem(.adaptive(minimum: 50), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(LucidIcon.allNames, id: \.self) { name in
                Button {
                    selectedIcon = name
                    HapticManager.selection()
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedIcon == name ? SpecialDayType.event.accentColor : JohoColors.white)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(JohoColors.black, lineWidth: selectedIcon == name ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
                            )

                        Image(systemName: name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(selectedIcon == name ? JohoColors.white : JohoColors.black)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 情報デザイン Icon Picker Sheet
private struct JohoIconPickerSheet: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) private var dismiss

    private let symbolCategories: [(name: String, symbols: [String])] = [
        ("MARU-BATSU", ["circle", "circle.fill", "xmark", "xmark.circle.fill", "triangle", "triangle.fill", "square", "square.fill", "diamond", "diamond.fill"]),
        ("EVENTS", ["star.fill", "sparkles", "gift.fill", "birthday.cake.fill", "party.popper.fill", "balloon.fill", "heart.fill", "bell.fill", "calendar.badge.clock"]),
        ("NATURE", ["leaf.fill", "flower.fill", "sun.max.fill", "moon.fill", "snowflake", "cloud.sun.fill", "flame.fill", "drop.fill"]),
        ("PEOPLE", ["person.fill", "person.2.fill", "figure.stand", "heart.circle.fill", "hand.raised.fill"]),
        ("TIME", ["calendar", "clock.fill", "hourglass", "timer", "sunrise.fill", "sunset.fill"]),
    ]

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: JohoDimensions.spacingSM)]

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header
                VStack(spacing: JohoDimensions.spacingSM) {
                    HStack {
                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingSM)
                                .background(JohoColors.white)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                )
                        }
                        Spacer()
                    }

                    Text("Choose Icon")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(JohoColors.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingLG)

                // Categories
                ForEach(symbolCategories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: category.name, style: .whiteOnBlack, size: .small)

                        LazyVGrid(columns: columns, spacing: JohoDimensions.spacingSM) {
                            ForEach(category.symbols, id: \.self) { symbol in
                                Button {
                                    selectedSymbol = symbol
                                    HapticManager.selection()
                                    dismiss()
                                } label: {
                                    Image(systemName: symbol)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(selectedSymbol == symbol ? JohoColors.white : JohoColors.black)
                                        .frame(width: 52, height: 52)
                                        .background(selectedSymbol == symbol ? SpecialDayType.event.accentColor : JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                                        )
                                }
                            }
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                Spacer(minLength: JohoDimensions.spacingXL)
            }
        }
        .johoBackground()
        .presentationCornerRadius(20)
        .presentationDetents([.large])
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
                            .fill(selectedIcon == name ? JohoColors.cyan.opacity(0.22) : JohoColors.black.opacity(0.5).opacity(0.08))
                            .frame(width: 44, height: 44)
                        Image(systemName: name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(selectedIcon == name ? JohoColors.cyan : JohoColors.black.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
