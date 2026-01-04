//
//  SettingsView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Japanese Information Design
//  BLACK text on WHITE backgrounds, ALWAYS
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    @AppStorage("showHolidays") private var showHolidays = true
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])
    @AppStorage("appBackgroundColor") private var appBackgroundColor = "black"

    // Database statistics queries
    @Query private var holidayRules: [HolidayRule]
    @Query private var dailyNotes: [DailyNote]
    @Query private var contacts: [Contact]
    @Query private var countdownEvents: [CountdownEvent]
    @Query private var trips: [TravelTrip]
    @Query private var expenses: [ExpenseItem]

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // 情報デザイン: Bento-style page header (Golden Standard Pattern)
                settingsPageHeader
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

                // Display Section (AMOLED-friendly background options)
                VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                    JohoPill(text: "DISPLAY", style: .whiteOnBlack, size: .small)

                    // Background color picker
                    VStack(spacing: JohoDimensions.spacingSM) {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Icon zone
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 44, height: 44)
                                .background(PageHeaderColor.settings.lightBackground)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Background Color")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(JohoColors.black)

                                Text(selectedBackgroundOption.displayName)
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black.opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding(JohoDimensions.spacingMD)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )

                        // Color options grid
                        HStack(spacing: JohoDimensions.spacingSM) {
                            ForEach(AppBackgroundOption.allCases) { option in
                                backgroundOptionButton(option)
                            }
                        }
                    }

                    // Footer text
                    Text("True Black saves battery on OLED displays by turning off pixels completely.")
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

                // Database Section (情報デザイン: Information visible at a glance)
                databaseSection

                // About Section
                VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                    // Section label
                    JohoPill(text: "ABOUT", style: .whiteOnBlack, size: .small)

                    // App info card
                    HStack(spacing: JohoDimensions.spacingMD) {
                        // Geometric Mascot (情報デザイン compliant)
                        GeometricMascotView(size: 64)

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

    // MARK: - Settings Page Header (情報デザイン: Golden Standard Pattern)

    private var settingsPageHeader: some View {
        VStack(spacing: 0) {
            // MAIN ROW: Icon + Title | WALL | Version
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Icon + Title
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Icon zone with Settings accent color (Slate Blue)
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(PageHeaderColor.settings.accent)
                        .frame(width: 40, height: 40)
                        .background(PageHeaderColor.settings.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: 1.5)
                        )

                    Text("SETTINGS")
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)

                // RIGHT COMPARTMENT: App version
                VStack(spacing: 0) {
                    Text("v1.0")
                        .font(JohoFont.bodySmall.bold())
                        .foregroundStyle(JohoColors.black)
                    Text("WeekGrid")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
            }
            .frame(minHeight: 56)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    // MARK: - Background Color Helpers

    private var selectedBackgroundOption: AppBackgroundOption {
        AppBackgroundOption(rawValue: appBackgroundColor) ?? .trueBlack
    }

    @ViewBuilder
    private func backgroundOptionButton(_ option: AppBackgroundOption) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                appBackgroundColor = option.rawValue
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 4) {
                // Color preview circle
                Circle()
                    .fill(option.color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(
                                selectedBackgroundOption == option ? JohoColors.black : JohoColors.black.opacity(0.3),
                                lineWidth: selectedBackgroundOption == option ? 2.5 : 1.5
                            )
                    )
                    .overlay {
                        if selectedBackgroundOption == option {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(JohoColors.white)
                        }
                    }

                // Label
                Text(option == .trueBlack ? "BLACK" : option == .darkNavy ? "NAVY" : "SOFT")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(selectedBackgroundOption == option ? JohoColors.yellow.opacity(0.3) : JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(
                        selectedBackgroundOption == option ? JohoColors.black : JohoColors.black.opacity(0.3),
                        lineWidth: selectedBackgroundOption == option ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Database Section (情報デザイン: Bento statistics grid)

    private var databaseSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            // Section label
            JohoPill(text: "DATABASE", style: .whiteOnBlack, size: .small)

            // Statistics grid (情報デザイン: Compartmentalized data)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: JohoDimensions.spacingSM),
                GridItem(.flexible(), spacing: JohoDimensions.spacingSM),
                GridItem(.flexible(), spacing: JohoDimensions.spacingSM)
            ], spacing: JohoDimensions.spacingSM) {
                // Custom holidays (user-created)
                databaseStatCard(
                    icon: "star.fill",
                    label: "HOLIDAYS",
                    count: customHolidayCount,
                    color: SpecialDayType.holiday.accentColor
                )

                // Notes
                databaseStatCard(
                    icon: "note.text",
                    label: "NOTES",
                    count: dailyNotes.count,
                    color: SpecialDayType.note.accentColor
                )

                // Contacts
                databaseStatCard(
                    icon: "person.2.fill",
                    label: "CONTACTS",
                    count: contacts.count,
                    color: SpecialDayType.birthday.accentColor
                )

                // Events
                databaseStatCard(
                    icon: "calendar.badge.clock",
                    label: "EVENTS",
                    count: countdownEvents.count,
                    color: SpecialDayType.event.accentColor
                )

                // Trips
                databaseStatCard(
                    icon: "airplane",
                    label: "TRIPS",
                    count: trips.count,
                    color: SpecialDayType.trip.accentColor
                )

                // Expenses
                databaseStatCard(
                    icon: "dollarsign.circle.fill",
                    label: "EXPENSES",
                    count: expenses.count,
                    color: SpecialDayType.expense.accentColor
                )
            }

            // Total entries + status
            HStack(spacing: JohoDimensions.spacingMD) {
                // Status indicator (情報デザイン: ○ = healthy)
                Text("○")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "38A169"))  // Green = healthy

                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL: \(totalEntries) ENTRIES")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Text("Database healthy • Capacity: unlimited")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer()

                // System holidays (read-only indicator)
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(systemHolidayCount) SYS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                }
                .foregroundStyle(JohoColors.black.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(JohoColors.black.opacity(0.05))
                .clipShape(Capsule())
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.top, JohoDimensions.spacingXS)
        }
        .padding(JohoDimensions.spacingLG)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Database Stat Card (情報デザイン: Compartmentalized)

    private func databaseStatCard(icon: String, label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            // Icon zone
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(JohoColors.black)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.3))
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(JohoColors.black, lineWidth: 1)
                )

            // Count
            Text("\(count)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.black)

            // Label
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(JohoColors.inputBackground)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: 1)
        )
    }

    // MARK: - Database Statistics Helpers

    private var customHolidayCount: Int {
        holidayRules.filter { $0.userModifiedAt != nil }.count
    }

    private var systemHolidayCount: Int {
        holidayRules.filter { $0.userModifiedAt == nil }.count
    }

    private var totalEntries: Int {
        let custom = customHolidayCount
        let notes = dailyNotes.count
        let people = contacts.count
        let events = countdownEvents.count
        let travel = trips.count
        let money = expenses.count
        return custom + notes + people + events + travel + money
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
