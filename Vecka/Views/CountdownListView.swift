//
//  CountdownListView.swift
//  Vecka
//
//  Countdown management view with 情報デザイン (Jōhō Dezain) styling
//

import SwiftUI

struct CountdownListView: View {
    @State private var customCountdowns: [CustomCountdown] = []
    @State private var favorites: [SavedCountdown] = []
    @State private var showAddCountdown = false
    @State private var selectedCountdown: CountdownType = .newYear

    // State for new countdown dialog
    @State private var newCountdownName: String = ""
    @State private var newCountdownDate: Date = Date()
    @State private var newCountdownIsAnnual: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Page header with inline actions (情報デザイン)
                HStack(alignment: .top) {
                    JohoPageHeader(
                        title: "Countdowns",
                        badge: "EVENTS",
                        subtitle: "\(totalCountdowns) countdown\(totalCountdowns == 1 ? "" : "s")"
                    )

                    Spacer()

                    Button {
                        showAddCountdown = true
                    } label: {
                        JohoActionButton(icon: "plus")
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingLG)

                // Next Up Section
                if let nextCountdown = nextUpcomingCountdown {
                    nextUpSection(nextCountdown)
                }

                // Favorites Section
                if !favorites.isEmpty {
                    favoritesSection
                }

                // Predefined Events Section
                predefinedSection

                // Custom Events Section
                customEventsSection

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loadCustomCountdowns()
            loadFavorites()
        }
        .sheet(isPresented: $showAddCountdown) {
            NavigationStack {
                CustomCountdownDialog(
                    name: $newCountdownName,
                    date: $newCountdownDate,
                    isAnnual: $newCountdownIsAnnual,
                    selectedCountdown: $selectedCountdown,
                    onSave: {
                        loadCustomCountdowns()
                        loadFavorites()
                        // Reset dialog state for next time
                        newCountdownName = ""
                        newCountdownDate = Date()
                        newCountdownIsAnnual = false
                    }
                )
            }
            .presentationCornerRadius(16)  // 情報デザイン: Standard container radius
        }
    }

    // MARK: - Computed Properties

    private var totalCountdowns: Int {
        CountdownType.allCases.filter { $0 != .custom }.count + customCountdowns.count
    }

    private var nextUpcomingCountdown: (name: String, icon: String, days: Int, date: Date)? {
        var allEvents: [(name: String, icon: String, days: Int, date: Date)] = []

        // Add predefined
        for type in CountdownType.allCases where type != .custom {
            let target = type.targetDate
            let days = daysUntil(target)
            if days >= 0 {
                allEvents.append((type.displayName, type.icon, days, target))
            }
        }

        // Add custom
        let currentYear = Calendar.iso8601.component(.year, from: Date())
        for custom in customCountdowns {
            if let target = custom.computeTargetDate(for: currentYear) {
                let days = daysUntil(target)
                if days >= 0 {
                    allEvents.append((custom.name, custom.iconName ?? "calendar.badge.plus", days, target))
                }
            }
        }

        return allEvents.min(by: { $0.days < $1.days })
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.iso8601
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: date)).day ?? 0
    }

    // MARK: - Next Up Section

    @ViewBuilder
    private func nextUpSection(_ countdown: (name: String, icon: String, days: Int, date: Date)) -> some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            HStack {
                JohoPill(text: "NEXT UP", style: .whiteOnBlack, size: .medium)
                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingLG)

            JohoCard {
                HStack(spacing: JohoDimensions.spacingMD) {
                    // 情報デザイン: Orange for countdowns/timers
                    ZStack {
                        Circle()
                            .fill(JohoColors.orange.opacity(0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: countdown.icon)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.orange)
                    }

                    VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                        Text(countdown.name)
                            .font(JohoFont.headline)
                            .foregroundStyle(JohoColors.black)

                        Text(countdown.date.formatted(.dateTime.month(.wide).day().year()))
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }

                    Spacer()

                    // Days counter
                    VStack(spacing: 2) {
                        Text("\(countdown.days)")
                            .font(JohoFont.displayMedium)
                            .foregroundStyle(JohoColors.black)

                        Text(countdown.days == 1 ? "DAY" : "DAYS")
                            .font(JohoFont.label)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
        }
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            HStack {
                JohoPill(text: "FAVORITES", style: .whiteOnBlack, size: .medium)
                Spacer()
                Text("\(favorites.count) saved")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .padding(.horizontal, JohoDimensions.spacingLG)

            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(favorites) { fav in
                    countdownRow(
                        name: fav.displayName,
                        icon: fav.icon,
                        days: daysUntilFavorite(fav),
                        isFavorite: true,
                        onToggleFavorite: { toggleFavorite(fav) }
                    )
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
        }
    }

    private func daysUntilFavorite(_ fav: SavedCountdown) -> Int {
        if fav.type == .custom, let custom = fav.custom {
            let currentYear = Calendar.iso8601.component(.year, from: Date())
            if let target = custom.computeTargetDate(for: currentYear) {
                return daysUntil(target)
            }
            return 0
        } else {
            return daysUntil(fav.type.targetDate)
        }
    }

    // MARK: - Predefined Section

    private var predefinedSection: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            HStack {
                JohoPill(text: "PREDEFINED", style: .whiteOnBlack, size: .medium)
                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingLG)

            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(CountdownType.allCases.filter { $0 != .custom }, id: \.self) { type in
                    let isFav = favorites.contains(where: { $0.type == type && $0.custom == nil })
                    countdownRow(
                        name: type.displayName,
                        icon: type.icon,
                        days: daysUntil(type.targetDate),
                        isFavorite: isFav,
                        onToggleFavorite: {
                            toggleFavorite(SavedCountdown(type: type, custom: nil))
                        }
                    )
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
        }
    }

    // MARK: - Custom Events Section

    private var customEventsSection: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            HStack {
                JohoPill(text: "CUSTOM EVENTS", style: .whiteOnBlack, size: .medium)
                Spacer()

                Button {
                    showAddCountdown = true
                } label: {
                    HStack(spacing: JohoDimensions.spacingXS) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text("Add")
                            .font(JohoFont.label)
                    }
                    .foregroundStyle(JohoColors.orange)  // 情報デザイン: Orange for countdowns
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)

            if customCountdowns.isEmpty {
                JohoEmptyState(
                    title: "No Custom Events",
                    message: "Create your own countdown events",
                    icon: "calendar.badge.plus",
                    zone: .countdowns
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
            } else {
                VStack(spacing: JohoDimensions.spacingSM) {
                    let currentYear = Calendar.iso8601.component(.year, from: Date())
                    ForEach(customCountdowns, id: \.self) { custom in
                        let target = custom.computeTargetDate(for: currentYear) ?? Date()
                        let days = daysUntil(target)
                        let isFav = favorites.contains(where: { $0.type == .custom && $0.custom == custom })

                        countdownRow(
                            name: custom.name,
                            icon: custom.iconName ?? "calendar.badge.plus",
                            days: days,
                            isFavorite: isFav,
                            isCustom: true,
                            onToggleFavorite: {
                                toggleFavorite(SavedCountdown(type: .custom, custom: custom))
                            },
                            onDelete: {
                                deleteCustom(custom)
                            }
                        )
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
            }
        }
    }

    // MARK: - Countdown Row

    @ViewBuilder
    private func countdownRow(
        name: String,
        icon: String,
        days: Int,
        isFavorite: Bool,
        isCustom: Bool = false,
        onToggleFavorite: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) -> some View {
        JohoCard {
            HStack(spacing: JohoDimensions.spacingMD) {
                // 情報デザイン: Orange icon zone for countdowns
                ZStack {
                    Circle()
                        .fill(JohoColors.orange.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.orange)
                }

                // Name and days
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)

                    Text(daysText(days))
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer()

                // Favorite button - 情報デザイン: Orange when active
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(isFavorite ? JohoColors.orange : JohoColors.black.opacity(0.3))
                        .frame(width: 44, height: 44)  // 情報デザイン: 44pt min touch target
                }
                .buttonStyle(.plain)

                // Delete button for custom events
                if isCustom, let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.red.opacity(0.6))
                            .frame(width: 44, height: 44)  // 情報デザイン: 44pt min touch target
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func daysText(_ days: Int) -> String {
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "\(days) days"
        }
    }

    // MARK: - Data Management

    private func loadCustomCountdowns() {
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

    private func toggleFavorite(_ item: SavedCountdown) {
        if let idx = favorites.firstIndex(of: item) {
            favorites.remove(at: idx)
        } else {
            if favorites.count >= 4 {
                favorites.removeFirst()
            }
            favorites.append(item)
        }
        saveFavorites()
        HapticManager.selection()
    }

    private func deleteCustom(_ custom: CustomCountdown) {
        customCountdowns.removeAll { $0 == custom }
        if let data = try? JSONEncoder().encode(customCountdowns) {
            UserDefaults.standard.set(data, forKey: "customCountdowns")
        }
        // Remove from favorites too
        favorites.removeAll { $0.type == .custom && $0.custom == custom }
        saveFavorites()
        HapticManager.notification(.warning)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CountdownListView()
    }
}
