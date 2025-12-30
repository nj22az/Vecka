//
//  SettingsView.swift
//  Vecka
//
//  Created by Claude Code Assistant on 2025-08-17.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    var body: some View {
        List {
            // Preferences Section
            Section {
                // Base Currency Setting
                Picker(selection: $baseCurrency) {
                    ForEach(CurrencyDefinition.defaultCurrencies) { currency in
                        Text("\(currency.code) - \(currency.name)")
                            .tag(currency.code)
                    }
                } label: {
                    Label("Base Currency", systemImage: "dollarsign.circle")
                }
                .pickerStyle(.navigationLink)

            } header: {
                Text("Preferences")
                    .foregroundStyle(AppColors.textSecondary)
            } footer: {
                Text("Base currency is used for expense calculations and reports.")
                    .font(.caption)
                    .foregroundStyle(AppColors.textTertiary)
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

                        Text(Localization.appTagline)
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
                Text(Localization.aboutHeader)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SlateColors.deepSlate)
        .navigationTitle(Localization.settings)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RegionSelectionView: View {
    @Binding var selectedRegions: HolidayRegionSelection
    @State private var showSelectionLimitAlert = false
    
    struct RegionOption: Identifiable, Hashable {
        let code: String
        let titleKey: String
        let symbol: String
        let color: Color

        var id: String { code }
        var displayName: String { NSLocalizedString(titleKey, comment: "Region Name") }
    }

    static let options: [RegionOption] = [
        .init(code: "SE", titleKey: "region.sweden", symbol: "globe.europe.africa", color: .blue),
        .init(code: "US", titleKey: "region.us", symbol: "globe.americas", color: .red),
        .init(code: "VN", titleKey: "region.vietnam", symbol: "globe.asia.australia", color: .green)
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(Self.options) { region in
                    Button {
                        toggle(region.code)
                    } label: {
                        HStack {
                            Image(systemName: region.symbol)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(region.color)
                                .frame(width: 28, alignment: .center)

                            Text(region.displayName)
                                .foregroundStyle(AppColors.textPrimary)

                            Spacer()
                            if selectedRegions.regions.contains(region.code) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.accentBlue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .foregroundStyle(AppColors.textPrimary)
                }
            } header: {
                Text(NSLocalizedString("settings.region", comment: "Region"))
            } footer: {
                Text("Select up to two regions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(NSLocalizedString("settings.region", comment: "Region"))
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColors.background)
        .alert("Limit Reached", isPresented: $showSelectionLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can select up to two regions.")
        }
    }

    private func toggle(_ code: String) {
        if selectedRegions.regions.contains(code) {
            if selectedRegions.removeRegionIfPossible(code, minimumCount: 1) {
                HapticManager.selection()
            }
        } else {
            if selectedRegions.addRegionIfPossible(code, maxCount: 2) {
                HapticManager.selection()
            } else {
                showSelectionLimitAlert = true
                HapticManager.impact(.light)
            }
        }
    }
}

#Preview {
    SettingsView()
}
