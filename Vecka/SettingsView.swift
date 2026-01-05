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
    @Environment(\.johoColorMode) private var colorMode
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    @AppStorage("showHolidays") private var showHolidays = true
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])
    @AppStorage("appBackgroundColor") private var appBackgroundColor = "black"
    @AppStorage("johoColorMode") private var johoColorMode = "light"
    @AppStorage("showLunarCalendar") private var showLunarCalendar = false  // For Vietnamese holidays
    @AppStorage("customLandingTitle") private var customLandingTitle = ""

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Database statistics queries
    @Query private var holidayRules: [HolidayRule]
    @Query private var dailyNotes: [DailyNote]
    @Query private var contacts: [Contact]
    @Query private var countdownEvents: [CountdownEvent]
    @Query private var trips: [TravelTrip]
    @Query private var expenses: [ExpenseItem]
    @Query(sort: \WorldClock.sortOrder) private var worldClocks: [WorldClock]

    // World clocks state
    @State private var showAddClockSheet = false
    @State private var isEditingTitle = false
    @State private var editingTitle = ""

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
                            .foregroundStyle(colors.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "FFD700"))
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Holidays")
                                .font(JohoFont.headline)
                                .foregroundStyle(colors.primary)

                            Text(showHolidays ? "Visible in calendar" : "Hidden")
                                .font(JohoFont.body)
                                .foregroundStyle(colors.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $showHolidays)
                            .labelsHidden()
                            .tint(Color(hex: "E53E3E"))
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                    )

                    // Region Selection
                    NavigationLink {
                        RegionSelectionView(selectedRegions: $holidayRegions)
                    } label: {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            Image(systemName: regionSymbolName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(colors.primary)
                                .frame(width: 44, height: 44)
                                .background(SectionZone.holidays.background)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Holiday Regions")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(colors.primary)

                                Text(regionSummary)
                                    .font(JohoFont.body)
                                    .foregroundStyle(colors.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                        .padding(JohoDimensions.spacingMD)
                        .background(colors.surface)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(JohoDimensions.spacingLG)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
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
                                .foregroundStyle(colors.primary)
                                .frame(width: 44, height: 44)
                                .background(SectionZone.expenses.background)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Base Currency")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(colors.primary)

                                Text(currencyDisplayName)
                                    .font(JohoFont.body)
                                    .foregroundStyle(colors.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                        .padding(JohoDimensions.spacingMD)
                        .background(colors.surface)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                        )
                    }
                    .buttonStyle(.plain)

                    // Footer text
                    Text("Base currency is used for expense calculations and reports.")
                        .font(JohoFont.caption)
                        .foregroundStyle(colors.secondary)
                        .padding(.horizontal, JohoDimensions.spacingSM)
                }
                .padding(JohoDimensions.spacingLG)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
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
                                .foregroundStyle(colors.primary)
                                .frame(width: 44, height: 44)
                                .background(PageHeaderColor.settings.lightBackground)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Background Color")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(colors.primary)

                                Text(selectedBackgroundOption.displayName)
                                    .font(JohoFont.body)
                                    .foregroundStyle(colors.secondary)
                            }

                            Spacer()
                        }
                        .padding(JohoDimensions.spacingMD)
                        .background(colors.surface)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
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
                        .foregroundStyle(colors.secondary)
                        .padding(.horizontal, JohoDimensions.spacingSM)

                    // Divider
                    Rectangle()
                        .fill(JohoColors.black.opacity(0.1))
                        .frame(height: 1)
                        .padding(.vertical, JohoDimensions.spacingSM)

                    // 夜間モード (Night Mode) toggle - AMOLED dark mode
                    darkModeToggleRow
                }
                .padding(JohoDimensions.spacingLG)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Lunar Calendar Section (情報デザイン: VN holidays only)
                if holidayRegions.regions.contains("VN") {
                    lunarCalendarSection
                }

                // Personalization Section (情報デザイン: User customization)
                personalizationSection

                // World Clocks Section (Onsen landing page)
                worldClocksSection

                // Unified DATABASE Section (情報デザイン: Legend + Stats in Bento style)
                unifiedDatabaseSection

                // About Section
                VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                    // Section label
                    JohoPill(text: "ABOUT", style: .whiteOnBlack, size: .small)

                    // App info card (情報デザイン: Mascot as app icon)
                    HStack(spacing: JohoDimensions.spacingMD) {
                        // JohoMascot as app icon (情報デザイン: The face of the app)
                        JohoMascot(
                            mood: .happy,
                            size: 64,
                            borderWidth: 2,
                            showBob: false,
                            showBlink: true,
                            autoOnsen: false
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("WeekGrid")
                                .font(JohoFont.displaySmall)
                                .foregroundStyle(colors.primary)

                            Text(Localization.appTagline)
                                .font(JohoFont.body)
                                .foregroundStyle(colors.secondary)

                            Text("Version 1.0")
                                .font(JohoFont.caption)
                                .foregroundStyle(colors.secondary)
                        }

                        Spacer()
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(JohoColors.inputBackground)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )

                    // Copyright
                    VStack(alignment: .leading, spacing: 6) {
                        Text("© 2025 The Office of Nils Johansson")
                            .font(JohoFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(colors.primary)

                        Text("All Rights Reserved. Proprietary and Confidential.")
                            .font(JohoFont.caption)
                            .foregroundStyle(colors.secondary)

                        Text("Licensed exclusively for authorized use only. Unauthorized reproduction, distribution, or modification is strictly prohibited.")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.65))
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                }
                .padding(JohoDimensions.spacingLG)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
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
                                .stroke(colors.border, lineWidth: 1.5)
                        )

                    Text("SETTINGS")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)
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
                        .foregroundStyle(colors.primary)
                    Text("Onsen")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(colors.secondary)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
            }
            .frame(minHeight: 56)

            // HORIZONTAL DIVIDER (情報デザイン: Golden Standard Pattern)
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // STATS ROW: Database health + World clocks count
            HStack(spacing: JohoDimensions.spacingSM) {
                // Database health indicator (情報デザイン: Honest status)
                HStack(spacing: 4) {
                    Text(databaseHealthIndicator)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(databaseHealthColor)

                    Text("\(totalEntries)")
                        .font(JohoFont.labelSmall.bold())
                        .foregroundStyle(colors.primary)

                    Text("/ \(Self.entryLimit)")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                // World clocks count (if any)
                if !worldClocks.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                        Text("\(worldClocks.count)")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(colors.secondary)
                        Text("clocks")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }

    // MARK: - Dark Mode Toggle (夜間モード)

    private var darkModeToggleRow: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            HStack(spacing: JohoDimensions.spacingMD) {
                // Icon zone
                Image(systemName: selectedColorMode == .dark ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(selectedColorMode == .dark ? JohoColors.white : JohoColors.black)
                    .frame(width: 44, height: 44)
                    .background(selectedColorMode == .dark ? JohoColors.black : JohoColors.yellow)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Dark Mode")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)

                    Text(selectedColorMode == .dark ? "AMOLED Dark Mode" : "Light Mode")
                        .font(JohoFont.body)
                        .foregroundStyle(colors.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { selectedColorMode == .dark },
                    set: { johoColorMode = $0 ? "dark" : "light" }
                ))
                .labelsHidden()
                .tint(JohoColors.black)
            }
            .padding(JohoDimensions.spacingMD)
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
            )

            // Footer
            Text("Dark mode inverts colors for AMOLED screens. White text on pure black saves battery.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
    }

    private var selectedColorMode: JohoColorMode {
        JohoColorMode(rawValue: johoColorMode) ?? .light
    }

    // MARK: - Lunar Calendar Section (情報デザイン: VN holidays)

    private var lunarCalendarSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "LUNAR CALENDAR", style: .whiteOnBlack, size: .small)

            HStack(spacing: JohoDimensions.spacingMD) {
                // Moon icon
                Image(systemName: showLunarCalendar ? "moon.stars.fill" : "moon")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(showLunarCalendar ? Color(hex: "FFCD00") : JohoColors.black)
                    .frame(width: 44, height: 44)
                    .background(showLunarCalendar ? Color(hex: "DA251D") : JohoColors.inputBackground)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Show Lunar Dates")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)

                    Text(showLunarCalendar ? "Showing Âm Lịch dates" : "Gregorian only")
                        .font(JohoFont.body)
                        .foregroundStyle(colors.secondary)
                }

                Spacer()

                Toggle("", isOn: $showLunarCalendar)
                    .labelsHidden()
                    .tint(Color(hex: "DA251D"))
            }
            .padding(JohoDimensions.spacingMD)
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
            )

            // Footer
            Text("Display Vietnamese lunar calendar dates (Âm Lịch) alongside Gregorian dates in the calendar.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
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
                    .foregroundStyle(colors.primary)
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

    // MARK: - Personalization Section (情報デザイン: Custom landing page title)

    private var personalizationSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            // Section label
            JohoPill(text: "PERSONALIZATION", style: .whiteOnBlack, size: .small)

            // Custom title row
            VStack(spacing: JohoDimensions.spacingSM) {
                HStack(spacing: JohoDimensions.spacingMD) {
                    // Icon zone
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(PageHeaderColor.landing.accent)
                        .frame(width: 44, height: 44)
                        .background(PageHeaderColor.landing.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Landing Page Title")
                            .font(JohoFont.headline)
                            .foregroundStyle(colors.primary)

                        Text(customLandingTitle.isEmpty ? "ONSEN (default)" : customLandingTitle.uppercased())
                            .font(JohoFont.body)
                            .foregroundStyle(colors.secondary)
                    }

                    Spacer()

                    // Edit button
                    Button {
                        editingTitle = customLandingTitle
                        isEditingTitle = true
                    } label: {
                        Text("Edit")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(JohoColors.black)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(JohoDimensions.spacingMD)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                )

                // Examples hint
                if customLandingTitle.isEmpty {
                    HStack(spacing: JohoDimensions.spacingXS) {
                        Text("Examples:")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.5))

                        Text("Nils Calendar")
                            .font(JohoFont.caption.bold())
                            .foregroundStyle(JohoColors.black.opacity(0.6))

                        Text("•")
                            .foregroundStyle(JohoColors.black.opacity(0.3))

                        Text("My Planner")
                            .font(JohoFont.caption.bold())
                            .foregroundStyle(JohoColors.black.opacity(0.6))

                        Text("•")
                            .foregroundStyle(JohoColors.black.opacity(0.3))

                        Text("Family Hub")
                            .font(JohoFont.caption.bold())
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                }
            }

            // Footer text
            Text("Personalize your landing page with a custom title.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
        .sheet(isPresented: $isEditingTitle) {
            EditLandingTitleView(
                title: $editingTitle,
                onSave: { newTitle in
                    customLandingTitle = newTitle
                    isEditingTitle = false
                },
                onCancel: {
                    isEditingTitle = false
                }
            )
        }
    }

    // MARK: - World Clocks Section (情報デザイン: Onsen landing page clocks)

    private var worldClocksSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            // Section label
            JohoPill(text: "WORLD CLOCKS", style: .whiteOnBlack, size: .small)

            // Current clocks list
            if worldClocks.isEmpty {
                // Empty state
                HStack(spacing: JohoDimensions.spacingMD) {
                    Image(systemName: "globe")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(JohoColors.black.opacity(0.4))
                        .frame(width: 44, height: 44)
                        .background(JohoColors.black.opacity(0.05))
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black.opacity(0.2), lineWidth: JohoDimensions.borderThin)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No World Clocks")
                            .font(JohoFont.headline)
                            .foregroundStyle(colors.primary)

                        Text("Add clocks to see times on your Onsen page")
                            .font(JohoFont.body)
                            .foregroundStyle(colors.secondary)
                    }

                    Spacer()
                }
                .padding(JohoDimensions.spacingMD)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black.opacity(0.2), lineWidth: JohoDimensions.borderMedium)
                )
            } else {
                // Clock list
                VStack(spacing: 0) {
                    ForEach(Array(worldClocks.enumerated()), id: \.element.id) { index, clock in
                        HStack(spacing: JohoDimensions.spacingMD) {
                            // City code pill + City name (情報デザイン: NO emoji)
                            HStack(spacing: 8) {
                                Text(clock.cityCode)
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(JohoColors.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(JohoColors.black)
                                    .clipShape(Capsule())

                                Text(clock.cityName)
                                    .font(JohoFont.headline)
                                    .foregroundStyle(colors.primary)
                            }

                            Spacer()

                            // Current time
                            Text(clock.formattedTime)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(colors.primary)

                            // Offset
                            Text(clock.offsetFromLocal)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(JohoColors.black.opacity(0.05))
                                .clipShape(Capsule())

                            // Delete button
                            Button {
                                deleteClock(clock)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.red)
                                    .frame(width: 28, height: 28)
                                    .background(JohoColors.red.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(JohoDimensions.spacingMD)

                        if index < worldClocks.count - 1 {
                            Rectangle()
                                .fill(JohoColors.black.opacity(0.1))
                                .frame(height: 1)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                        }
                    }
                }
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                )
            }

            // Add clock button (情報デザイン: Max 3 clocks)
            Button {
                if worldClocks.count < 3 {
                    showAddClockSheet = true
                }
            } label: {
                HStack(spacing: JohoDimensions.spacingMD) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(colors.primary)
                        .frame(width: 44, height: 44)
                        .background(JohoColors.cyan)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                        )

                    Text(worldClocks.count >= 3 ? "Maximum 3 Clocks" : "Add World Clock")
                        .font(JohoFont.headline)
                        .foregroundStyle(worldClocks.count >= 3 ? JohoColors.black.opacity(0.4) : JohoColors.black)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
                .padding(JohoDimensions.spacingMD)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                )
            }
            .buttonStyle(.plain)

            // Footer text
            Text("Up to 3 world clocks appear on your Onsen landing page.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
        .sheet(isPresented: $showAddClockSheet) {
            AddWorldClockView { cityName, timezone in
                addClock(cityName: cityName, timezone: timezone)
            }
        }
    }

    // MARK: - World Clock Actions

    private func addClock(cityName: String, timezone: String) {
        let clock = WorldClock(
            cityName: cityName,
            timezoneIdentifier: timezone,
            sortOrder: worldClocks.count
        )
        modelContext.insert(clock)
        try? modelContext.save()
    }

    private func deleteClock(_ clock: WorldClock) {
        modelContext.delete(clock)
        try? modelContext.save()
    }

    // MARK: - Unified DATABASE Section (情報デザイン: Star Page Month Card Style)

    private var unifiedDatabaseSection: some View {
        VStack(spacing: 0) {
            // HEADER ROW: DATABASE pill + total count
            HStack {
                JohoPill(text: "DATABASE", style: .whiteOnBlack, size: .small)

                Spacer()

                // Total count badge
                HStack(spacing: 4) {
                    Text(databaseHealthIndicator)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(databaseHealthColor)
                    Text("\(totalEntries)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // STAR PAGE STYLE GRID: 2 rows × 3 columns (like month cards)
            VStack(spacing: JohoDimensions.spacingSM) {
                // Row 1: Holidays, Notes, Contacts
                HStack(spacing: JohoDimensions.spacingSM) {
                    starStyleCard(
                        icon: "star.fill",
                        label: "HOLIDAYS",
                        count: customHolidayCount,
                        color: SpecialDayType.holiday.accentColor,
                        lightBg: SpecialDayType.holiday.lightBackground
                    )

                    starStyleCard(
                        icon: "note.text",
                        label: "NOTES",
                        count: dailyNotes.count,
                        color: SpecialDayType.note.accentColor,
                        lightBg: SpecialDayType.note.lightBackground
                    )

                    starStyleCard(
                        icon: "person.2.fill",
                        label: "CONTACTS",
                        count: contacts.count,
                        color: SpecialDayType.birthday.accentColor,
                        lightBg: SpecialDayType.birthday.lightBackground
                    )
                }

                // Row 2: Events, Trips, Expenses
                HStack(spacing: JohoDimensions.spacingSM) {
                    starStyleCard(
                        icon: "calendar.badge.clock",
                        label: "EVENTS",
                        count: countdownEvents.count,
                        color: SpecialDayType.event.accentColor,
                        lightBg: SpecialDayType.event.lightBackground
                    )

                    starStyleCard(
                        icon: "airplane",
                        label: "TRIPS",
                        count: trips.count,
                        color: SpecialDayType.trip.accentColor,
                        lightBg: SpecialDayType.trip.lightBackground
                    )

                    starStyleCard(
                        icon: "dollarsign.circle.fill",
                        label: "EXPENSES",
                        count: expenses.count,
                        color: SpecialDayType.expense.accentColor,
                        lightBg: SpecialDayType.expense.lightBackground
                    )
                }
            }
            .padding(JohoDimensions.spacingSM)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // FOOTER ROW: Status + System count
            HStack(spacing: JohoDimensions.spacingMD) {
                // Health status
                Text(databaseStatusText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))

                Spacer()

                // System holidays (read-only)
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
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Star Style Card (情報デザイン: Matches Star page month cards exactly)

    private func starStyleCard(icon: String, label: String, count: Int, color: Color, lightBg: Color) -> some View {
        VStack(spacing: 4) {
            // Large colored icon (like Star page month icons)
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)

            // Label (like month name)
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(colors.primary)

            // Count indicators (like Star page entry dots)
            if count > 0 {
                HStack(spacing: 3) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            } else {
                // Empty state - subtle dash
                Text("—")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(JohoColors.black.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(lightBg)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: 1.5)
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

    // MARK: - Database Health (情報デザイン: Honest limits)

    /// Practical limits for personal planner (not marketing "unlimited")
    private static let entryLimit = 5000
    private static let warningThreshold = 4000

    private var databaseHealthIndicator: String {
        if totalEntries >= Self.entryLimit {
            return "×"  // At limit
        } else if totalEntries >= Self.warningThreshold {
            return "△"  // Warning
        } else {
            return "○"  // Healthy
        }
    }

    private var databaseHealthColor: Color {
        if totalEntries >= Self.entryLimit {
            return JohoColors.red
        } else if totalEntries >= Self.warningThreshold {
            return Color(hex: "D69E2E")  // Warning amber
        } else {
            return Color(hex: "38A169")  // Healthy green
        }
    }

    private var databaseStatusText: String {
        let remaining = Self.entryLimit - totalEntries
        if totalEntries >= Self.entryLimit {
            return "At capacity • Consider archiving old entries"
        } else if totalEntries >= Self.warningThreshold {
            return "\(remaining) entries remaining • Nearing limit"
        } else {
            return "Healthy • \(remaining) entries remaining"
        }
    }
}

// MARK: - Currency Picker View (情報デザイン)

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
                                    .foregroundStyle(colors.primary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedCurrency == currency.code ? SectionZone.expenses.background : JohoColors.inputBackground)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                            .stroke(colors.border, lineWidth: selectedCurrency == currency.code ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currency.code)
                                        .font(JohoFont.headline)
                                        .foregroundStyle(colors.primary)

                                    Text(currency.name)
                                        .font(JohoFont.body)
                                        .foregroundStyle(colors.secondary)
                                }

                                Spacer()

                                if selectedCurrency == currency.code {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(colors.primary)
                                }
                            }
                            .padding(JohoDimensions.spacingMD)
                            .background(colors.surface)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(colors.border, lineWidth: selectedCurrency == currency.code ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
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
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    struct RegionOption: Identifiable, Hashable {
        let code: String
        let titleKey: String
        let symbol: String
        let color: Color

        var id: String { code }
        var displayName: String { NSLocalizedString(titleKey, comment: "Region Name") }
    }

    static let options: [RegionOption] = [
        // Original regions
        .init(code: "SE", titleKey: "region.sweden", symbol: "globe.europe.africa", color: .blue),
        .init(code: "US", titleKey: "region.us", symbol: "globe.americas", color: .red),
        .init(code: "VN", titleKey: "region.vietnam", symbol: "globe.asia.australia", color: .green),
        // European expansion
        .init(code: "DE", titleKey: "region.germany", symbol: "globe.europe.africa", color: Color(hex: "DD0000")),
        .init(code: "GB", titleKey: "region.uk", symbol: "globe.europe.africa", color: Color(hex: "012169")),
        .init(code: "FR", titleKey: "region.france", symbol: "globe.europe.africa", color: Color(hex: "002395")),
        .init(code: "IT", titleKey: "region.italy", symbol: "globe.europe.africa", color: Color(hex: "008C45")),
        .init(code: "NL", titleKey: "region.netherlands", symbol: "globe.europe.africa", color: Color(hex: "AE1C28")),
        // Asian expansion
        .init(code: "JP", titleKey: "region.japan", symbol: "globe.asia.australia", color: Color(hex: "BC002D")),
        .init(code: "HK", titleKey: "region.hongkong", symbol: "globe.asia.australia", color: Color(hex: "DE2910")),
        .init(code: "CN", titleKey: "region.china", symbol: "globe.asia.australia", color: Color(hex: "DE2910")),
        .init(code: "TH", titleKey: "region.thailand", symbol: "globe.asia.australia", color: Color(hex: "241D4F"))
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
                                            .stroke(colors.border, lineWidth: selectedRegions.regions.contains(region.code) ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
                                    )

                                Text(region.displayName)
                                    .font(JohoFont.headline)
                                    .foregroundStyle(colors.primary)

                                Spacer()

                                if selectedRegions.regions.contains(region.code) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(colors.primary)
                                }
                            }
                            .padding(JohoDimensions.spacingMD)
                            .background(colors.surface)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(colors.border, lineWidth: selectedRegions.regions.contains(region.code) ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
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

// MARK: - Add World Clock View (情報デザイン: Intelligent city search)

struct AddWorldClockView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    let onAdd: (String, String) -> Void

    @State private var searchText = ""

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// Intelligent search results using WorldCityDatabase
    /// Shows STM (Stora Mellösa) first when no search, then popular cities
    private var searchResults: [WorldCity] {
        if searchText.isEmpty {
            // Default: STM first, then popular cities by region
            let defaultCities = [
                "Stora Mellösa",  // STM - Developer's hometown (default)
                "Stockholm", "Tokyo", "New York", "London", "Paris",
                "Sydney", "Singapore", "Berlin", "Dubai", "Los Angeles"
            ]
            return defaultCities.compactMap { name in
                WorldCityDatabase.cities.first { $0.name == name }
            }
        }
        // Intelligent search
        return WorldCityDatabase.search(searchText)
    }

    /// Region color for city (情報デザイン: Geographic color coding)
    private func regionColor(for region: WorldRegion) -> Color {
        switch region {
        case .europe: return Color(hex: "4A90D9")      // Blue
        case .asia: return Color(hex: "E17055")        // Coral
        case .northAmerica: return Color(hex: "00B894") // Teal
        case .southAmerica: return Color(hex: "00CEC9") // Cyan
        case .africa: return Color(hex: "FDCB6E")      // Gold
        case .oceania: return Color(hex: "D35400")     // Orange
        case .middleEast: return Color(hex: "6C5CE7")  // Purple
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Header
                    JohoPageHeader(
                        title: "Add World Clock",
                        badge: "CITY"
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                    // Search bar (情報デザイン: Type any city or country)
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(JohoColors.black.opacity(0.4))

                        TextField("Type city or country...", text: $searchText)
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primary)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(JohoColors.black.opacity(0.3))
                            }
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)

                    // Search hint
                    if searchText.isEmpty {
                        Text("Type any city name to search 300+ locations worldwide")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, JohoDimensions.spacingLG)
                    }

                    // City list (情報デザイン: Region-colored badges)
                    VStack(spacing: 0) {
                        if searchResults.isEmpty {
                            // No results
                            VStack(spacing: JohoDimensions.spacingMD) {
                                Image(systemName: "globe")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundStyle(JohoColors.black.opacity(0.3))
                                Text("No cities found")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(JohoColors.black.opacity(0.5))
                                Text("Try a different spelling")
                                    .font(JohoFont.caption)
                                    .foregroundStyle(JohoColors.black.opacity(0.4))
                            }
                            .padding(JohoDimensions.spacingXL)
                        } else {
                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, city in
                                Button {
                                    HapticManager.impact(.light)
                                    onAdd(city.name, city.timezone)
                                    dismiss()
                                } label: {
                                    HStack(spacing: JohoDimensions.spacingMD) {
                                        // City code pill (情報デザイン: Region-colored)
                                        Text(city.code)
                                            .font(.system(size: 11, weight: .black, design: .rounded))
                                            .foregroundStyle(JohoColors.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(regionColor(for: city.region))
                                            .clipShape(Capsule())
                                            .frame(width: 52)

                                        // City info
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(city.name)
                                                .font(JohoFont.headline)
                                                .foregroundStyle(colors.primary)

                                            Text(city.country)
                                                .font(JohoFont.caption)
                                                .foregroundStyle(JohoColors.black.opacity(0.6))
                                        }

                                        Spacer()

                                        // Current time preview
                                        Text(currentTime(for: city.timezone))
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(colors.secondary)

                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(regionColor(for: city.region))
                                    }
                                    .padding(JohoDimensions.spacingMD)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if index < searchResults.count - 1 {
                                    Rectangle()
                                        .fill(JohoColors.black.opacity(0.1))
                                        .frame(height: 1)
                                        .padding(.horizontal, JohoDimensions.spacingMD)
                                }
                            }
                        }
                    }
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }
                .padding(.bottom, JohoDimensions.spacingXL)
            }
            .johoBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("×")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(JohoColors.red)
                    }
                }
            }
        }
    }

    private func currentTime(for timezoneId: String) -> String {
        guard let tz = TimeZone(identifier: timezoneId) else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Edit Landing Title View (情報デザイン)

struct EditLandingTitleView: View {
    @Binding var title: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @Environment(\.johoColorMode) private var colorMode

    @FocusState private var isFocused: Bool

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Header
                    JohoPageHeader(
                        title: "Edit Title",
                        badge: "PERSONALIZE"
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                    // Input card
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                        // Preview
                        VStack(spacing: JohoDimensions.spacingSM) {
                            Text("PREVIEW")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.5))

                            Text(title.isEmpty ? "ONSEN" : title.uppercased())
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(JohoDimensions.spacingMD)
                        .background(PageHeaderColor.landing.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(colors.border, lineWidth: 1.5)
                        )

                        // Text field
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                            Text("Your Title")
                                .font(JohoFont.labelSmall)
                                .foregroundStyle(colors.secondary)

                            TextField("Enter title (e.g., Nils Calendar)", text: $title)
                                .font(JohoFont.body)
                                .foregroundStyle(colors.primary)
                                .padding(JohoDimensions.spacingMD)
                                .background(JohoColors.inputBackground)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                        .stroke(colors.border, lineWidth: 1.5)
                                )
                                .focused($isFocused)
                        }

                        // Clear button (if not empty)
                        if !title.isEmpty {
                            Button {
                                title = ""
                                HapticManager.selection()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Reset to Default (ONSEN)")
                                        .font(JohoFont.bodySmall)
                                }
                                .foregroundStyle(JohoColors.red)
                                .frame(maxWidth: .infinity)
                                .padding(JohoDimensions.spacingSM)
                            }
                            .buttonStyle(.plain)
                        }

                        // Suggestions
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            Text("SUGGESTIONS")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.5))

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: JohoDimensions.spacingSM) {
                                suggestionButton("My Calendar")
                                suggestionButton("Family Hub")
                                suggestionButton("Life Planner")
                                suggestionButton("Daily")
                            }
                        }
                    }
                    .padding(JohoDimensions.spacingLG)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)

                    Spacer(minLength: JohoDimensions.spacingXL)
                }
                .padding(.bottom, JohoDimensions.spacingXL)
            }
            .johoBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onCancel()
                    } label: {
                        Text("×")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(JohoColors.red)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        HapticManager.impact(.light)
                        onSave(title.trimmingCharacters(in: .whitespacesAndNewlines))
                    } label: {
                        Text("○")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color(hex: "38A169"))
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private func suggestionButton(_ text: String) -> some View {
        Button {
            title = text
            HapticManager.selection()
        } label: {
            Text(text)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary)
                .frame(maxWidth: .infinity)
                .padding(JohoDimensions.spacingSM)
                .background(JohoColors.inputBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(JohoColors.black.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
