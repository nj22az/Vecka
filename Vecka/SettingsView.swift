//
//  SettingsView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Japanese Information Design
//  BLACK text on WHITE backgrounds, ALWAYS
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    @AppStorage("showHolidays") private var showHolidays = true
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Page Header (情報デザイン: WHITE container)
                JohoPageHeader(
                    title: Localization.settings,
                    badge: "SETTINGS"
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

                // Calendar Section (Show Holidays + Region)
                VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                    JohoPill(text: "CALENDAR", style: .whiteOnBlack, size: .small)

                    // Show Holidays Toggle
                    HStack(spacing: JohoDimensions.spacingMD) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "FFD700"))
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Holidays")
                                .font(JohoFont.headline)
                                .foregroundStyle(JohoColors.black)

                            Text(showHolidays ? "Visible in calendar" : "Hidden")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black.opacity(0.7))
                        }

                        Spacer()

                        Toggle("", isOn: $showHolidays)
                            .labelsHidden()
                            .tint(Color(hex: "E53E3E"))
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )

                    // Region Selection
                    NavigationLink {
                        RegionSelectionView(selectedRegions: $holidayRegions)
                    } label: {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            Image(systemName: regionSymbolName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 44, height: 44)
                                .background(SectionZone.holidays.background)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Holiday Regions")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(JohoColors.black)

                                Text(regionSummary)
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black.opacity(0.7))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                        .padding(JohoDimensions.spacingMD)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Preferences Section
                VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                    // Section label
                    JohoPill(text: "PREFERENCES", style: .whiteOnBlack, size: .small)

                    // Currency picker row
                    NavigationLink {
                        CurrencyPickerView(selectedCurrency: $baseCurrency)
                    } label: {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Icon zone (40pt with color)
                            Image(systemName: "dollarsign.circle")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 44, height: 44)
                                .background(SectionZone.expenses.background)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Base Currency")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(JohoColors.black)

                                Text(currencyDisplayName)
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black.opacity(0.7))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                        .padding(JohoDimensions.spacingMD)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                    }
                    .buttonStyle(.plain)

                    // Footer text
                    Text("Base currency is used for expense calculations and reports.")
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                        .padding(.horizontal, JohoDimensions.spacingSM)
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

                // About Section
                VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                    // Section label
                    JohoPill(text: "ABOUT", style: .whiteOnBlack, size: .small)

                    // App info card
                    HStack(spacing: JohoDimensions.spacingMD) {
                        // App Icon
                        Image("VeckaAboutIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("WeekGrid")
                                .font(JohoFont.displaySmall)
                                .foregroundStyle(JohoColors.black)

                            Text(Localization.appTagline)
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black.opacity(0.7))

                            Text("Version 1.0")
                                .font(JohoFont.caption)
                                .foregroundStyle(JohoColors.black.opacity(0.7))
                        }

                        Spacer()
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(JohoColors.inputBackground)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                    )

                    // Copyright
                    VStack(alignment: .leading, spacing: 6) {
                        Text("© 2025 The Office of Nils Johansson")
                            .font(JohoFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(JohoColors.black)

                        Text("All Rights Reserved. Proprietary and Confidential.")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.7))

                        Text("Licensed exclusively for authorized use only. Unauthorized reproduction, distribution, or modification is strictly prohibited.")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.65))
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var currencyDisplayName: String {
        if let currency = CurrencyDefinition.defaultCurrencies.first(where: { $0.code == baseCurrency }) {
            return "\(currency.code) - \(currency.name)"
        }
        return baseCurrency
    }

    private var regionSummary: String {
        let names = holidayRegions.regions.compactMap { code in
            RegionSelectionView.options.first(where: { $0.code == code })?.displayName
        }
        if names.isEmpty { return "None selected" }
        return names.joined(separator: ", ")
    }

    private var regionSymbolName: String {
        if holidayRegions.regions.count == 1,
           let code = holidayRegions.regions.first,
           let option = RegionSelectionView.options.first(where: { $0.code == code }) {
            return option.symbol
        }
        return "globe"
    }
}

// MARK: - Currency Picker View (情報デザイン)

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header
                JohoPageHeader(
                    title: "Base Currency",
                    badge: "SELECT"
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

                // Currency list
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(CurrencyDefinition.defaultCurrencies) { currency in
                        Button {
                            selectedCurrency = currency.code
                            HapticManager.selection()
                            dismiss()
                        } label: {
                            HStack(spacing: JohoDimensions.spacingMD) {
                                // Currency symbol zone
                                Text(currency.symbol)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(JohoColors.black)
                                    .frame(width: 44, height: 44)
                                    .background(selectedCurrency == currency.code ? SectionZone.expenses.background : JohoColors.inputBackground)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                            .stroke(JohoColors.black, lineWidth: selectedCurrency == currency.code ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currency.code)
                                        .font(JohoFont.headline)
                                        .foregroundStyle(JohoColors.black)

                                    Text(currency.name)
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black.opacity(0.7))
                                }

                                Spacer()

                                if selectedCurrency == currency.code {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(JohoColors.black)
                                }
                            }
                            .padding(JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: selectedCurrency == currency.code ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Region Selection View (情報デザイン)

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
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header
                JohoPageHeader(
                    title: NSLocalizedString("settings.region", comment: "Region"),
                    badge: "SELECT",
                    subtitle: "Select up to two regions"
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

                // Regions list
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(Self.options) { region in
                        Button {
                            toggle(region.code)
                        } label: {
                            HStack(spacing: JohoDimensions.spacingMD) {
                                // Region icon zone
                                Image(systemName: region.symbol)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(region.color)
                                    .frame(width: 44, height: 44)
                                    .background(selectedRegions.regions.contains(region.code) ? SectionZone.holidays.background : JohoColors.inputBackground)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                            .stroke(JohoColors.black, lineWidth: selectedRegions.regions.contains(region.code) ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
                                    )

                                Text(region.displayName)
                                    .font(JohoFont.headline)
                                    .foregroundStyle(JohoColors.black)

                                Spacer()

                                if selectedRegions.regions.contains(region.code) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(JohoColors.black)
                                }
                            }
                            .padding(JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: selectedRegions.regions.contains(region.code) ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
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
    NavigationStack {
        SettingsView()
    }
}
