//
//  SettingsView.swift
//  Vecka
//
//  Created by Claude Code Assistant on 2025-08-17.
//

import SwiftUI

struct SettingsView: View {
    @Binding var selectedCountdown: CountdownType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingCountdownPicker = false
    // Favorites (max 4) shown as quick picks in Settings
    @State private var favoriteCountdowns: [SavedCountdown] = []
    // Cache of currently selected custom for quick compare (avoid decoding in views)
    @State private var selectedCustomLocal: CustomCountdown? = nil
    @State private var showFavoritesEditor = false
    
    let onCountdownChange: () -> Void
    
    // Direct color evaluation for optimal performance
    
    var body: some View {
        NavigationView {
            List {
                // Countdown Favorites Section (max 4)
                Section {
                    if favoriteCountdowns.isEmpty {
                        Text(Localization.addFavoritesHint)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.vertical, 4)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(favoriteCountdowns) { fav in
                                CountdownCard(
                                    countdownType: fav.type,
                                    customCountdown: fav.custom,
                                    isSelected: {
                                        if fav.type != .custom { return fav.type == selectedCountdown }
                                        guard fav.type == selectedCountdown, let favCustom = fav.custom else { return false }
                                        return selectedCustomLocal == favCustom
                                    }(),
                                    action: {
                                        selectedCountdown = fav.type
                                        if fav.type == .custom, let custom = fav.custom, let data = try? JSONEncoder().encode(custom) {
                                            UserDefaults.standard.set(data, forKey: "selectedCustomCountdown")
                                            selectedCustomLocal = custom
                                        }
                                        // Save preference up to caller
                                        do { try saveCountdownPreference() } catch {}
                                    }
                                )
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    Button(Localization.manageEvents) { showingCountdownPicker = true }
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.accentBlue)
                        .accessibilityLabel(Localization.manageEvents)
                        .padding(.top, 6)

                    Button(Localization.reorderFavorites) { showFavoritesEditor = true }
                        .font(.callout)
                        .foregroundStyle(AppColors.accentBlue)
                        .padding(.vertical, 2)
                } header: {
                    Text("Events")
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // About Section
                Section {
                    HStack {
                        // Corporate App Icon
                        Image("VeckaAboutIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                            )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Vecka")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Text("Professional Week Number Display")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                            
                            Text("Version 1.0")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    // Corporate Copyright Section
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("© 2025 The Office of Nils Johansson")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Text("All Rights Reserved. Proprietary and Confidential.")
                                .font(.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                            
                            Text("Licensed exclusively for authorized use only. Unauthorized reproduction, distribution, or modification is strictly prohibited and may result in severe civil and criminal penalties.")
                                .font(.caption2)
                                .foregroundStyle(AppColors.textTertiary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                    
                } header: {
                    Text("About")
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .scrollContentBackground(.visible)
            .listStyle(.insetGrouped)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.accentBlue)
                }
            }
        }
        .presentationBackground(AppColors.background)
        .sheet(isPresented: $showingCountdownPicker) {
            CountdownPickerSheet(
                selectedCountdown: $selectedCountdown,
                onSave: {
                    // Safe countdown preference saving with error handling
                    do {
                        try saveCountdownPreference()
                    } catch {
                        print("Warning: Failed to save countdown preference: \(error.localizedDescription)")
                    }
                    loadFavorites()
                    loadSelectedCustom()
                }
            )
        }
        .onAppear { loadFavorites(); loadSelectedCustom() }
        .sheet(isPresented: $showFavoritesEditor) {
            FavoritesEditorView(items: $favoriteCountdowns) {
                saveFavorites()
            }
        }
        // Custom creation is now inside the countdown picker grid
    }
    
    // MARK: - Helper Functions
    
    private func saveCountdownPreference() throws {
        // Delegate saving to ContentView via callback to avoid duplicate AppStorage
        onCountdownChange()
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favoriteCountdowns"),
           let favs = try? JSONDecoder().decode([SavedCountdown].self, from: data) {
            favoriteCountdowns = Array(favs.prefix(4))
        }
    }
    
    private func loadSelectedCustom() {
        if let data = UserDefaults.standard.data(forKey: "selectedCustomCountdown"),
           let custom = try? JSONDecoder().decode(CustomCountdown.self, from: data) {
            selectedCustomLocal = custom
        } else {
            selectedCustomLocal = nil
        }
    }
    
    private func saveFavorites() {
        let trimmed = Array(favoriteCountdowns.prefix(4))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: "favoriteCountdowns")
        }
    }

}

// MARK: - Inline Favorites Editor Sheet
struct FavoritesEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var items: [SavedCountdown]
    var onChanged: () -> Void
    @State private var editMode: EditMode = .active
    
    var body: some View {
        NavigationView {
            List {
                Section(footer: Text(String(format: Localization.favoritesCountFormat, items.count)).font(.caption).foregroundStyle(.secondary)) {
                    ForEach(items) { fav in
                        HStack {
                            Image(systemName: fav.icon).foregroundStyle(AppColors.textSecondary)
                            Text(fav.displayName)
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .onMove { source, dest in
                        items.move(fromOffsets: source, toOffset: dest)
                        items = Array(items.prefix(4))
                    }
                    .onDelete { offsets in
                        items.remove(atOffsets: offsets)
                    }
                }
            }
            .navigationTitle(Localization.reorderFavorites.replacingOccurrences(of: "…", with: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button(Localization.cancel) { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button(Localization.save) { onChanged(); dismiss() }.fontWeight(.semibold) }
                ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
            }
        }
        .environment(\.editMode, $editMode)
    }
}

#Preview("Light Mode") {
    SettingsView(selectedCountdown: .constant(.newYear), onCountdownChange: {})
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    SettingsView(selectedCountdown: .constant(.newYear), onCountdownChange: {})
        .preferredColorScheme(.dark)
}

#Preview("Monochrome Mode") {
    SettingsView(selectedCountdown: .constant(.newYear), onCountdownChange: {})
        .preferredColorScheme(.dark)
}
