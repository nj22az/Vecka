//
//  SettingsView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Japanese Information Design
//  BLACK text on WHITE backgrounds, ALWAYS
//

import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])
    @AppStorage("appBackgroundColor") private var appBackgroundColor = "black"
    @AppStorage("johoColorMode") private var johoColorMode = "light"
    @AppStorage("showLunarCalendar") private var showLunarCalendar = false  // For Vietnamese holidays
    @AppStorage("customLandingTitle") private var customLandingTitle = ""
    @AppStorage("eventTextColor") private var eventTextColor = "black"  // 情報デザイン: Japanese planner text color
    @AppStorage("systemUIAccent") private var systemUIAccent = "blue"  // 情報デザイン: System UI accent color
    // PDF Export settings (情報デザイン: User-configurable branding)
    @AppStorage("pdfExportTitle") private var pdfExportTitle = "Contact Directory"
    @AppStorage("pdfExportFooter") private var pdfExportFooter = ""  // Empty = page number only
    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Database statistics queries
    @Query private var holidayRules: [HolidayRule]
    @Query private var memos: [Memo]
    @Query private var contacts: [Contact]
    @Query(sort: \WorldClock.sortOrder) private var worldClocks: [WorldClock]

    // World clocks state
    @State private var showAddClockSheet = false
    @State private var isEditingTitle = false
    @State private var editingTitle = ""

    // Developer tools state
    @State private var showingResetConfirmation = false
    @State private var isGeneratingData = false

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // 情報デザイン: Bento-style page header (Golden Standard Pattern)
                settingsPageHeader
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                // Calendar Section (Event Text Color)
                VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                    JohoPill(text: "CALENDAR", style: .whiteOnBlack, size: .small)

                    // 情報デザイン: Event text color picker (Japanese planner style)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            Image(systemName: "textformat")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(colors.primary)
                                .johoTouchTarget()
                                .background(colors.surface)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                                )

                            Text("Event Text Color")
                                .font(JohoFont.headline)
                                .foregroundStyle(colors.primary)

                            Spacer()
                        }

                        // Color options
                        HStack(spacing: JohoDimensions.spacingSM) {
                            ForEach(EventTextColor.allCases, id: \.rawValue) { color in
                                Button {
                                    eventTextColor = color.rawValue
                                    HapticManager.selection()
                                } label: {
                                    Text(color.displayName)
                                        .font(JohoFont.body)
                                        .foregroundStyle(color.color)
                                        .padding(.horizontal, JohoDimensions.spacingMD)
                                        .padding(.vertical, JohoDimensions.spacingSM)
                                        .frame(maxWidth: .infinity)
                                        .background(eventTextColor == color.rawValue ? color.color.opacity(0.15) : colors.surface)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(eventTextColor == color.rawValue ? color.color : colors.border, lineWidth: eventTextColor == color.rawValue ? 2 : 1)
                                        )
                                }
                                .buttonStyle(.plain)
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
                                .johoTouchTarget()
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
                        .fill(colors.border.opacity(0.1))
                        .frame(height: 1)
                        .padding(.vertical, JohoDimensions.spacingSM)

                    // 夜間モード (Night Mode) toggle - AMOLED dark mode
                    darkModeToggleRow

                    // Divider
                    Rectangle()
                        .fill(colors.border.opacity(0.1))
                        .frame(height: 1)
                        .padding(.vertical, JohoDimensions.spacingSM)

                    // System UI Accent (情報デザイン: Navigation element color)
                    systemUIAccentSection
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

                // Export Section (情報デザイン: PDF branding options)
                exportSettingsSection

                // World Clocks Section (Onsen landing page)
                worldClocksSection

                // Developer Tools Section (情報デザイン: Test data for development)
                developerToolsSection

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
                            Text("Onsen Planner")
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
                    .background(colors.inputBackground)
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
                            .foregroundStyle(colors.secondary.opacity(0.85))
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
                    .fill(colors.border)
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
                .fill(colors.border)
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
                        .foregroundStyle(colors.secondary)
                }

                // World clocks count (if any)
                if !worldClocks.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(colors.secondary)
                        Text("\(worldClocks.count)")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(colors.secondary)
                        Text("clocks")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(colors.secondary)
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

    // MARK: - Dark Mode Picker (情報デザイン: Segmented control)

    private var darkModeToggleRow: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            VStack(spacing: JohoDimensions.spacingMD) {
                // Header row
                HStack(spacing: JohoDimensions.spacingMD) {
                    // Icon zone
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(colors.primary)
                        .johoTouchTarget()
                        .background(colors.inputBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appearance")
                            .font(JohoFont.headline)
                            .foregroundStyle(colors.primary)

                        Text(selectedColorMode == .dark ? "Dark mode active" : "Light mode active")
                            .font(JohoFont.body)
                            .foregroundStyle(colors.secondary)
                    }

                    Spacer()
                }

                // Segmented control (情報デザイン: Two-button picker)
                HStack(spacing: 0) {
                    // LIGHT button
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            johoColorMode = "light"
                        }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sun.max")
                                .font(.system(size: 12, weight: .bold))
                            Text("LIGHT")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(selectedColorMode == .light ? colors.primaryInverted : colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedColorMode == .light ? colors.primary : colors.surface)
                    }
                    .buttonStyle(.plain)

                    // Vertical divider
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)

                    // DARK button
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            johoColorMode = "dark"
                        }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "moon")
                                .font(.system(size: 12, weight: .bold))
                            Text("DARK")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(selectedColorMode == .dark ? colors.primaryInverted : colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedColorMode == .dark ? colors.primary : colors.surface)
                    }
                    .buttonStyle(.plain)
                }
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(colors.border, lineWidth: 1.5)
                )
            }
            .padding(JohoDimensions.spacingMD)
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
            )

            // Footer
            Text("Dark mode uses white text on black. Saves battery on OLED screens.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
    }

    private var selectedColorMode: JohoColorMode {
        JohoColorMode(rawValue: johoColorMode) ?? .light
    }

    // MARK: - System UI Accent Section (情報デザイン: Navigation elements)

    private var systemUIAccentSection: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            // Header row
            HStack(spacing: JohoDimensions.spacingMD) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(colors.primary)
                    .johoTouchTarget()
                    .background(colors.inputBackground)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("UI Accent")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)

                    Text((SystemUIAccent(rawValue: systemUIAccent) ?? .indigo).description)
                        .font(JohoFont.body)
                        .foregroundStyle(colors.secondary)
                }

                Spacer()
            }

            // Color option buttons (horizontal scroll for 5 options)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(SystemUIAccent.allCases) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                systemUIAccent = option.rawValue
                            }
                            HapticManager.selection()
                        } label: {
                            VStack(spacing: 4) {
                                // Color circle preview
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(systemUIAccent == option.rawValue ? colors.primary : colors.border, lineWidth: systemUIAccent == option.rawValue ? 2.5 : 1)
                                    )

                                // Label
                                Text(option.displayName)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary)

                                // Japanese name
                                Text(option.japaneseName)
                                    .font(.system(size: 8, weight: .medium, design: .rounded))
                                    .foregroundStyle(colors.secondary)
                            }
                            .frame(width: 60)
                            .padding(.vertical, 8)
                            .background(systemUIAccent == option.rawValue ? option.color.opacity(0.15) : colors.surface)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(systemUIAccent == option.rawValue ? option.color : colors.border, lineWidth: systemUIAccent == option.rawValue ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Footer
            Text("Color for pickers, navigation buttons, and system UI elements.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Lunar Calendar Section (情報デザイン: VN holidays)

    private var lunarCalendarSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "LUNAR CALENDAR", style: .whiteOnBlack, size: .small)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showLunarCalendar.toggle()
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: JohoDimensions.spacingMD) {
                    // Moon icon (EXCEPTION: Keep JohoColors.black on bright Vietnamese flag background)
                    Image(systemName: showLunarCalendar ? "moon.stars.fill" : "moon")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(showLunarCalendar ? Color(hex: "FFCD00") : colors.primary)
                        .johoTouchTarget()
                        .background(showLunarCalendar ? Color(hex: "DA251D") : colors.inputBackground)
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

                    // Visual toggle indicator (情報デザイン: Maru circle)
                    Circle()
                        .fill(showLunarCalendar ? Color(hex: "DA251D") : colors.inputBackground)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().stroke(colors.border, lineWidth: 1.5)
                        )
                        .overlay(
                            showLunarCalendar ?
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            : nil
                        )
                }
            }
            .buttonStyle(.plain)
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
                                selectedBackgroundOption == option ? colors.border : colors.border.opacity(0.3),
                                lineWidth: selectedBackgroundOption == option ? 2.5 : 1.5
                            )
                    )
                    .overlay {
                        if selectedBackgroundOption == option {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(colors.primaryInverted)
                        }
                    }

                // Label
                Text(option == .trueBlack ? "BLACK" : option == .darkNavy ? "NAVY" : "SOFT")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(selectedBackgroundOption == option ? JohoColors.yellow.opacity(0.3) : colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(
                        selectedBackgroundOption == option ? colors.border : colors.border.opacity(0.3),
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
                        .johoTouchTarget()
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
                            .foregroundStyle(colors.primaryInverted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(colors.primary)
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
                            .foregroundStyle(colors.secondary.opacity(0.8))

                        Text("Nils Calendar")
                            .font(JohoFont.caption.bold())
                            .foregroundStyle(colors.secondary)

                        Text("•")
                            .foregroundStyle(colors.secondary.opacity(0.5))

                        Text("My Planner")
                            .font(JohoFont.caption.bold())
                            .foregroundStyle(colors.secondary)

                        Text("•")
                            .foregroundStyle(colors.secondary.opacity(0.5))

                        Text("Family Hub")
                            .font(JohoFont.caption.bold())
                            .foregroundStyle(colors.secondary)
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

    // MARK: - Export Settings Section (情報デザイン: PDF branding)

    private var exportSettingsSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            // Section label
            JohoPill(text: "EXPORT", style: .whiteOnBlack, size: .small)

            // PDF Title setting (EXCEPTION: Keep JohoColors.black on purple background)
            HStack(spacing: JohoDimensions.spacingMD) {
                // Icon zone
                Image(systemName: "doc.text")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .johoTouchTarget()
                    .background(JohoColors.purple.opacity(0.3))
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("PDF Title")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)

                    TextField("Contact Directory", text: $pdfExportTitle)
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

            // PDF Footer setting (EXCEPTION: Keep JohoColors.black on purple background)
            HStack(spacing: JohoDimensions.spacingMD) {
                // Icon zone
                Image(systemName: "text.alignleft")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .johoTouchTarget()
                    .background(JohoColors.purple.opacity(0.2))
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("PDF Footer")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)

                    TextField("Page number only", text: $pdfExportFooter)
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

            // Footer hint
            Text("Leave footer empty to show page numbers only.")
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
                        .foregroundStyle(colors.secondary)
                        .johoTouchTarget()
                        .background(colors.border.opacity(0.05))
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border.opacity(0.2), lineWidth: JohoDimensions.borderThin)
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
                        .stroke(colors.border.opacity(0.2), lineWidth: JohoDimensions.borderMedium)
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
                                    .foregroundStyle(colors.primaryInverted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(colors.primary)
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
                                .foregroundStyle(colors.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(colors.border.opacity(0.05))
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
                                .fill(colors.border.opacity(0.1))
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

            // Add clock button (情報デザイン: Max 3 clocks) - EXCEPTION: Keep JohoColors.black on cyan background
            Button {
                if worldClocks.count < 3 {
                    showAddClockSheet = true
                }
            } label: {
                HStack(spacing: JohoDimensions.spacingMD) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                        .johoTouchTarget()
                        .background(JohoColors.cyan)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                        )

                    Text(worldClocks.count >= 3 ? "Maximum 3 Clocks" : "Add World Clock")
                        .font(JohoFont.headline)
                        .foregroundStyle(worldClocks.count >= 3 ? colors.secondary : colors.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(colors.secondary)
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
        syncWorldClocksToWidget()
    }

    private func deleteClock(_ clock: WorldClock) {
        modelContext.delete(clock)
        try? modelContext.save()
        syncWorldClocksToWidget()
    }

    /// Sync world clocks to App Group for widget access
    private func syncWorldClocksToWidget() {
        // Convert SwiftData WorldClock to shared Codable format
        let sharedClocks = worldClocks.prefix(3).enumerated().map { index, clock in
            SharedWorldClock(
                id: clock.id,
                cityName: clock.cityName,
                timezoneIdentifier: clock.timezoneIdentifier,
                sortOrder: index
            )
        }
        WorldClockStorage.save(Array(sharedClocks))

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "VeckaWidget")
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
                .fill(colors.border)
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
                        label: "MEMOS",
                        count: memos.count,
                        color: JohoColors.yellow,
                        lightBg: JohoColors.yellow.opacity(0.3)
                    )

                    starStyleCard(
                        icon: "person.2.fill",
                        label: "CONTACTS",
                        count: contacts.count,
                        color: JohoColors.purple,
                        lightBg: JohoColors.purple.opacity(0.3)
                    )
                }
            }
            .padding(JohoDimensions.spacingSM)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // FOOTER ROW: Status + System count
            HStack(spacing: JohoDimensions.spacingMD) {
                // Health status
                Text(databaseStatusText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.secondary)

                Spacer()

                // System holidays (read-only)
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(systemHolidayCount) SYS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                }
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colors.border.opacity(0.05))
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
                        .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            } else {
                // Empty state - subtle dash
                Text("—")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(colors.secondary.opacity(0.5))
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
        customHolidayCount + memos.count + contacts.count
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

    // MARK: - Developer Tools Section (情報デザイン: Inline test data generation)

    private var developerToolsSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "DEVELOPER", style: .whiteOnBlack, size: .small)

            // Test data buttons grid (情報デザイン: Compact 3-column layout)
            VStack(spacing: JohoDimensions.spacingSM) {
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Memos (Green)
                    devToolButton(
                        icon: "note.text",
                        label: "Memos",
                        color: JohoColors.green
                    ) {
                        generateDummyMemos()
                    }

                    // Holidays (Pink)
                    devToolButton(
                        icon: "star.fill",
                        label: "Holidays",
                        color: CategoryColorSettings.shared.color(for: .holiday)
                    ) {
                        generateDummyHolidays()
                    }

                    // Observances (Cyan)
                    devToolButton(
                        icon: "calendar",
                        label: "Observ.",
                        color: CategoryColorSettings.shared.color(for: .observance)
                    ) {
                        generateDummyObservances()
                    }
                }

                HStack(spacing: JohoDimensions.spacingSM) {
                    // Contacts (Purple)
                    devToolButton(
                        icon: "person.2.fill",
                        label: "Contacts",
                        color: JohoColors.purple
                    ) {
                        generateDummyContacts()
                    }

                    // Trips (Cyan)
                    devToolButton(
                        icon: "airplane",
                        label: "Trips",
                        color: JohoColors.cyan
                    ) {
                        generateDummyTrips()
                    }

                    // Reset (Red)
                    devToolButton(
                        icon: "trash.fill",
                        label: "Reset",
                        color: JohoColors.red
                    ) {
                        showingResetConfirmation = true
                    }
                }
            }

            // Footer
            Text("Generate test data for development. Reset clears all user data.")
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
        .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete ALL user data including contacts, memos, and custom holidays. This cannot be undone.")
        }
    }

    private func devToolButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(color.opacity(0.1))
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isGeneratingData)
    }

    // MARK: - Test Data Generation Functions

    private func generateDummyMemos() {
        let noteContents = [
            "Morning standup - design team",
            "Code review: SwiftUI performance",
            "Call dentist for appointment",
            "Shopping: milk, bread, eggs, coffee",
            "Prepare presentation for Friday",
            "Update project documentation",
            "Book flight tickets for vacation",
            "Research new Swift 6 features",
            "Fix bug in calendar view",
            "Plan birthday surprise for Lisa"
        ]

        let calendar = Calendar.current
        for content in noteContents {
            let daysAgo = Int.random(in: 0...30)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            let memo = Memo.quick(content, date: date)
            modelContext.insert(memo)
        }

        try? modelContext.save()
        HapticManager.notification(.success)
    }

    private func generateDummyHolidays() {
        let holidays = [
            ("Company Retreat", 3, 15),
            ("Team Building Day", 5, 20),
            ("Hackathon", 6, 10)
        ]

        for (name, month, day) in holidays {
            let rule = HolidayRule(
                name: name,
                region: "CUSTOM",
                isBankHoliday: true,
                symbolName: "building.2.fill",
                type: .fixed,
                month: month,
                day: day,
                isSystemDefault: false,
                isEnabled: true
            )
            modelContext.insert(rule)
        }

        try? modelContext.save()
        HapticManager.notification(.success)
    }

    private func generateDummyObservances() {
        let observances = [
            ("Pizza Friday", 1, 26),
            ("Office Yoga Day", 2, 14),
            ("Book Club Meeting", 4, 5)
        ]

        for (name, month, day) in observances {
            let rule = HolidayRule(
                name: name,
                region: "CUSTOM",
                isBankHoliday: false,  // Not a bank holiday = observance
                symbolName: "sparkles",
                type: .fixed,
                month: month,
                day: day,
                isSystemDefault: false,
                isEnabled: true
            )
            modelContext.insert(rule)
        }

        try? modelContext.save()
        HapticManager.notification(.success)
    }

    private func generateDummyContacts() {
        let firstNames = ["Emma", "Liam", "Olivia", "Noah", "Ava", "Ethan", "Sophia", "Mason", "Isabella", "James"]
        let lastNames = ["Andersson", "Johansson", "Karlsson", "Nilsson", "Eriksson", "Larsson", "Olsson", "Persson", "Svensson", "Gustafsson"]
        let companies = ["Spotify", "IKEA", "Volvo", "Ericsson", "H&M", "Klarna", "King", "Mojang", "Electrolux", "Scania"]

        for _ in 0..<10 {
            let firstName = firstNames.randomElement() ?? "Test"
            let lastName = lastNames.randomElement() ?? "User"
            let company = companies.randomElement()

            let phone = ContactPhoneNumber(
                label: ["mobile", "work", "home"].randomElement() ?? "mobile",
                value: "+46 70 \(Int.random(in: 100...999)) \(Int.random(in: 10...99)) \(Int.random(in: 10...99))"
            )

            let email = ContactEmailAddress(
                label: "work",
                value: "\(firstName.lowercased()).\(lastName.lowercased())@\(company?.lowercased() ?? "test").se"
            )

            let contact = Contact(
                givenName: firstName,
                familyName: lastName,
                organizationName: Bool.random() ? company : nil,
                phoneNumbers: [phone],
                emailAddresses: [email],
                birthday: Bool.random() ? Calendar.current.date(byAdding: .year, value: -Int.random(in: 20...60), to: Date()) : nil,
                group: [ContactGroup.family, .friends, .work, .other].randomElement() ?? .other
            )

            modelContext.insert(contact)
        }

        try? modelContext.save()
        HapticManager.notification(.success)
    }

    private func generateDummyTrips() {
        let trips: [(city: String, country: String, duration: Int)] = [
            ("Tokyo", "Japan", 10),
            ("Paris", "France", 5),
            ("New York", "USA", 7),
            ("London", "UK", 3),
            ("Barcelona", "Spain", 4)
        ]

        let calendar = Calendar.current
        for trip in trips {
            let startOffset = Int.random(in: -30...90)
            let startDate = calendar.date(byAdding: .day, value: startOffset, to: Date()) ?? Date()
            let endDate = calendar.date(byAdding: .day, value: trip.duration, to: startDate) ?? startDate

            let memo = Memo.trip(
                "\(trip.city) trip",
                startDate: startDate,
                endDate: endDate,
                destination: "\(trip.city), \(trip.country)",
                purpose: "vacation"
            )
            modelContext.insert(memo)
        }

        try? modelContext.save()
        HapticManager.notification(.success)
    }

    private func resetAllData() {
        do {
            try modelContext.delete(model: Contact.self)
            try modelContext.delete(model: Memo.self)
            try modelContext.delete(model: HolidayRule.self, where: #Predicate { $0.region == "CUSTOM" })
            try modelContext.save()
            HapticManager.notification(.warning)
        } catch {
            Log.e("Failed to reset data: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
