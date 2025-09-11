//
//  SettingsView.swift
//  Vecka
//
//  Created by Claude Code Assistant on 2025-08-17.
//

import SwiftUI

struct SettingsView: View {
    @Binding var selectedCountdown: CountdownType
    @AppStorage("isMonochromeMode") private var isMonochromeMode: Bool = false
    @AppStorage("isAutoDarkMode") private var isAutoDarkMode: Bool = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingCountdownPicker = false
    @State private var showingCustomCountdownDialog = false
    @State private var customCountdownName = ""
    @State private var customCountdownDate = Date()
    @State private var customCountdownIsAnnual = true
    
    let onCountdownChange: () -> Void
    
    // Direct color evaluation for optimal performance
    
    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                Section {
                    // Dark Mode Toggle
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isMonochromeMode ? AppColors.monoSurfaceElevated : AppColors.accentBlue)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: isMonochromeMode ? "moon.fill" : "moon.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(isMonochromeMode ? AppColors.monoTextPrimary : .white)
                        }
                        
                        Text("Dark Mode")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                        
                        Spacer()
                        
                        Toggle("", isOn: $isMonochromeMode)
                            .tint(isMonochromeMode ? AppColors.monoTextPrimary : AppColors.accentBlue)
                            .accessibilityLabel("Dark Mode")
                            .accessibilityHint("Toggles between color and dark mode display")
                    }
                    .padding(.vertical, 4)
                    
                    // Automatic Mode Toggle
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isAutoDarkMode ? AppColors.accentBlue : Color.secondary.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(isAutoDarkMode ? .white : .secondary)
                        }
                        
                        Text("Automatic")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                        
                        Spacer()
                        
                        Toggle("", isOn: $isAutoDarkMode)
                            .tint(AppColors.accentBlue)
                            .disabled(isMonochromeMode)
                            .accessibilityLabel("Automatic Mode")
                            .accessibilityHint("Automatically follows system light and dark mode settings")
                    }
                    .padding(.vertical, 4)
                    .opacity(isMonochromeMode ? 0.5 : 1.0)
                    
                } header: {
                    Text("Appearance")
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                }
                .listRowBackground(AppColors.adaptiveSurface(isMonochrome: isMonochromeMode))
                
                // Countdown Configuration Section
                Section {
                    Button(action: {
                        showingCountdownPicker = true
                    }) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.accentYellow)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Countdown Event")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                                
                                Text(selectedCountdown.displayName)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.adaptiveTextTertiary(isMonochrome: isMonochromeMode))
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Countdown Event Settings")
                    .accessibilityHint("Tap to change countdown event")
                    
                    // Custom Countdown Button
                    Button(action: {
                        showingCustomCountdownDialog = true
                    }) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.accentBlue)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Create Custom Event")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                                
                                Text("Add your own countdown")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.adaptiveTextTertiary(isMonochrome: isMonochromeMode))
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                } header: {
                    Text("Events")
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                }
                .listRowBackground(AppColors.adaptiveSurface(isMonochrome: isMonochromeMode))
                
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
                                .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                            
                            Text("Professional Week Number Display")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            
                            Text("Version 1.0")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.adaptiveTextTertiary(isMonochrome: isMonochromeMode))
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
                                .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                            
                            Text("All Rights Reserved. Proprietary and Confidential.")
                                .font(.caption2)
                                .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            
                            Text("Licensed exclusively for authorized use only. Unauthorized reproduction, distribution, or modification is strictly prohibited and may result in severe civil and criminal penalties.")
                                .font(.caption2)
                                .foregroundStyle(AppColors.adaptiveTextTertiary(isMonochrome: isMonochromeMode))
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                    
                } header: {
                    Text("About")
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                }
                .listRowBackground(AppColors.adaptiveSurface(isMonochrome: isMonochromeMode))
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .listRowBackground(AppColors.adaptiveSurface(isMonochrome: isMonochromeMode))
            .background(AppColors.adaptiveBackground(isMonochrome: isMonochromeMode, isAutoDarkMode: isAutoDarkMode))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isMonochromeMode ? AppColors.monoTextPrimary : AppColors.accentBlue)
                }
            }
        }
        // Force a refresh of the navigation/list chrome when scheme changes
        .id(schemeRefreshKey)
        // Ensure the sheet's own background updates with scheme changes immediately
        .presentationBackground(AppColors.adaptiveBackground(isMonochrome: isMonochromeMode, isAutoDarkMode: isAutoDarkMode))
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
                }
            )
        }
        .sheet(isPresented: $showingCustomCountdownDialog) {
            CustomCountdownDialog(
                name: $customCountdownName,
                date: $customCountdownDate,
                isAnnual: $customCountdownIsAnnual,
                selectedCountdown: $selectedCountdown,
                onSave: {
                    // Safe countdown preference saving with error handling
                    do {
                        try saveCountdownPreference()
                    } catch {
                        print("Warning: Failed to save countdown preference: \(error.localizedDescription)")
                    }
                }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func saveCountdownPreference() throws {
        // Delegate saving to ContentView via callback to avoid duplicate AppStorage
        onCountdownChange()
    }

    // MARK: - Scheme Refresh Key
    private var schemeRefreshKey: String {
        if isMonochromeMode { return "mono-dark" }
        return isAutoDarkMode ? "auto" : "light"
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
