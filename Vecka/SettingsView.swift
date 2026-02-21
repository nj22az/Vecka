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

/// Wrapper to make month number (Int) identifiable for sheet binding
private struct IdentifiableMonth: Identifiable {
    let id: Int
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])
    @AppStorage("johoColorMode") private var johoColorMode = "light"
    @AppStorage("showLunarCalendar") private var showLunarCalendar = false  // For Vietnamese holidays
    @AppStorage("customLandingTitle") private var customLandingTitle = ""
    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Database statistics queries
    @Query private var holidayRules: [HolidayRule]
    @Query private var memos: [Memo]
    @Query private var contacts: [Contact]
    @State private var isEditingTitle = false
    @State private var editingTitle = ""

    // Developer tools state
    @State private var showingResetConfirmation = false
    @State private var isGeneratingData = false
    @State private var showThemeConfirmation = false
    @State private var pendingTheme: JohoThemePreset?

    // Category customization state
    @State private var editingCategory: DisplayCategory? = nil

    // Month customization state
    @AppStorage("monthCustomizations") private var monthCustomizationsData: Data = Data()
    @State private var editingMonthID: IdentifiableMonth? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // 情報デザイン: Bento-style page header (Golden Standard Pattern)
                settingsPageHeader
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                // Theme Section (情報デザイン: Unified theming)
                themeSection

                // Categories Section (情報デザイン: Master icon + color per category)
                categoriesSection

                // Months Section (情報デザイン: Month card customization)
                monthsSection

                // Lunar Calendar Section (情報デザイン: VN holidays only)
                if holidayRegions.regions.contains("VN") {
                    lunarCalendarSection
                }

                // Personalization Section (情報デザイン: User customization)
                personalizationSection

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
                    .johoBordered(borderWidth: JohoDimensions.borderThin)

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
                        .strokeBorder(colors.border, lineWidth: JohoDimensions.borderThick)
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
                    Image(systemName: IconCatalog.settings)
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

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick)
    }

    private var selectedColorMode: JohoColorMode {
        JohoColorMode(rawValue: johoColorMode) ?? .light
    }

    // MARK: - Theme Section (情報デザイン: Unified Category Theming)

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "THEME", style: .whiteOnBlack, size: .small)

            // Light/Dark mode toggle
            HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        johoColorMode = "light"
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sun.min")
                            .font(.system(size: 11, weight: .bold))
                        Text("LIGHT")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(selectedColorMode == .light ? colors.primaryInverted : colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedColorMode == .light ? colors.primary : colors.surface)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(colors.border)
                    .frame(width: 1.5)

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
            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)

            // Theme preset cards — horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: JohoDimensions.spacingSM) {
                    ForEach(JohoThemeLoader.loadPresets()) { theme in
                        themePresetCard(theme)
                    }
                }
            }

            // Current colors preview row
            HStack(spacing: JohoDimensions.spacingMD) {
                Image(systemName: "paintpalette.fill")
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
                    Text("Category Colors")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)

                    HStack(spacing: 6) {
                        categoryDot(color: CategoryColorSettings.shared.holidayColor, label: "HOL")
                        categoryDot(color: CategoryColorSettings.shared.observanceColor, label: "OBS")
                        categoryDot(color: CategoryColorSettings.shared.memoColor, label: "MEM")
                    }
                }

                Spacer()

                // Reset button
                if CategoryColorSettings.shared.activeThemeId != nil {
                    Button {
                        CategoryColorSettings.shared.resetToDefaults()
                        UserDefaults.standard.removeObject(forKey: "activeThemeId")
                        HapticManager.selection()
                    } label: {
                        Text("Reset")
                            .font(JohoFont.tag)
                            .foregroundStyle(JohoColors.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(JohoColors.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(JohoDimensions.spacingMD)
            .background(colors.surface)
            .johoBordered()

            // Footer
            Text("Themes transform borders, surfaces, category colors, and UI accent. Month colors (季節の色) stay locked.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick)
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Theme Preset Card

    private func themePresetCard(_ theme: JohoThemePreset) -> some View {
        let isActive = CategoryColorSettings.shared.activeThemeId == theme.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                CategoryColorSettings.shared.applyTheme(theme)
            }
            HapticManager.notification(.success)
            WidgetCenter.shared.reloadTimelines(ofKind: "VeckaWidget")
        } label: {
            VStack(spacing: 6) {
                // Icon in colored circle with checkmark overlay
                Image(systemName: theme.previewIcon)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: theme.holidayColorHex))
                    .frame(width: 48, height: 48)
                    .background(Color(hex: theme.holidayColorHex).opacity(0.2))
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .strokeBorder(isActive ? colors.primary : colors.border, lineWidth: isActive ? 2.5 : 1.5)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(colors.primary)
                                .background(colors.surface)
                                .clipShape(Circle())
                                .offset(x: 4, y: 4)
                        }
                    }

                // Theme name
                Text(theme.name.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(isActive ? colors.primary : colors.secondary)

                // Color dots (category + structural)
                HStack(spacing: 3) {
                    Circle().fill(Color(hex: theme.holidayColorHex)).frame(width: 8, height: 8)
                    Circle().fill(Color(hex: theme.observanceColorHex)).frame(width: 8, height: 8)
                    Circle().fill(Color(hex: theme.memoColorHex)).frame(width: 8, height: 8)
                }

                // Light/dark mode text readability samples
                HStack(spacing: 2) {
                    themeTextSample(
                        surfaceHex: theme.lightSurfaceHex ?? "FFFFFF",
                        borderHex: theme.lightBorderHex ?? "000000"
                    )
                    themeTextSample(
                        surfaceHex: theme.darkSurfaceHex ?? "1C1C1E",
                        borderHex: theme.darkBorderHex ?? "48484A"
                    )
                }
            }
            .frame(width: 72)
            .padding(.vertical, 10)
            .background(isActive ? Color(hex: theme.holidayColorHex).opacity(0.1) : colors.surface)
            .johoBordered(borderWidth: isActive ? 2.5 : 1.5, borderColor: isActive ? colors.primary : nil)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Color Dot

    private func categoryDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
        }
    }

    /// Mini "Aa" text sample showing derived text color on theme surface
    private func themeTextSample(surfaceHex: String, borderHex: String) -> some View {
        let surface = Color(hex: surfaceHex)
        let textColor: Color = surface.relativeLuminance <= 0.5
            ? Color(hex: "F0F0F0")
            : Color(hex: "000000")
        return Text("Aa")
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundStyle(textColor)
            .frame(width: 18, height: 12)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color(hex: borderHex), lineWidth: 1.5)
            )
    }

    // MARK: - Categories Section (情報デザイン: Master icon + color per category)

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "CATEGORIES", style: .whiteOnBlack, size: .small)

            VStack(spacing: 0) {
                ForEach(DisplayCategory.allCases) { category in
                    let categoryColor = CategoryColorSettings.shared.color(for: category)
                    let currentIcon = category.categoryAwareIcon

                    Button {
                        editingCategory = category
                    } label: {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Color swatch
                            Circle()
                                .fill(categoryColor)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1.5))

                            // Category name
                            Text(category.localizedLabel.uppercased())
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(colors.primary)

                            Spacer()

                            // Current icon
                            Image(systemName: currentIcon)
                                .font(JohoFont.headlineSmall)
                                .foregroundStyle(colors.primary)

                            // Chevron
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM + 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // Divider between rows (not after last)
                    if category != DisplayCategory.allCases.last {
                        Rectangle()
                            .fill(colors.border)
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }
            }
            .background(colors.surface)
            .johoBordered()
            .allowsHitTesting(false)
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .sheet(item: $editingCategory) { category in
            SettingsCategoryCustomizationSheet(
                category: category,
                onDone: {
                    editingCategory = nil
                }
            )
            .presentationCornerRadius(20)
        }
    }

    // MARK: - Months Section (情報デザイン: Month card customization)

    /// Month customizations read helper
    private var monthCustomizations: [Int: MonthCustomization] {
        guard !monthCustomizationsData.isEmpty,
              let decoded = try? JSONDecoder().decode([Int: MonthCustomization].self, from: monthCustomizationsData) else {
            return [:]
        }
        // Filter out entries where all fields are nil or empty strings
        return decoded.filter { _, custom in
            custom.icon?.isEmpty == false || custom.iconColorHex?.isEmpty == false || custom.colorHex?.isEmpty == false || custom.message?.isEmpty == false
        }
    }

    private func saveMonthCustomization(_ customization: MonthCustomization?, for month: Int) {
        var customizations = monthCustomizations
        if let customization = customization {
            customizations[month] = customization
        } else {
            customizations.removeValue(forKey: month)
        }
        if let encoded = try? JSONEncoder().encode(customizations) {
            monthCustomizationsData = encoded
        }
        MonthThemeStorage.syncCustomizations(customizations)
        WidgetCenter.shared.reloadTimelines(ofKind: "VeckaWidget")
    }

    private var monthsSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "MONTHS", style: .whiteOnBlack, size: .small)

            VStack(spacing: 0) {
                ForEach(1...12, id: \.self) { month in
                    let theme = MonthTheme.theme(for: month)
                    let custom = monthCustomizations[month]
                    let displayIcon = custom?.icon ?? theme.icon
                    let hasCustomization = custom?.icon?.isEmpty == false || custom?.iconColorHex?.isEmpty == false || custom?.message?.isEmpty == false

                    Button {
                        editingMonthID = IdentifiableMonth(id: month)
                    } label: {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Seasonal icon in squircle
                            Image(systemName: displayIcon)
                                .font(JohoFont.headlineSmall)
                                .foregroundStyle(theme.accentColor)
                                .frame(width: 32, height: 32)
                                .background(theme.lightBackground)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .strokeBorder(colors.border, lineWidth: 1.5)
                                )

                            // Month name
                            Text(theme.name.uppercased())
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(colors.primary)

                            // Customization indicator
                            if hasCustomization {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 6, height: 6)
                            }

                            Spacer()

                            // Chevron
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingSM + 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // Divider between rows (not after last)
                    if month < 12 {
                        Rectangle()
                            .fill(colors.border)
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }
            }
            .background(colors.surface)
            .johoBordered()
            .allowsHitTesting(false)

            // Footer
            Text("Customize month cards with icons, colors, and messages. 季節の色 stay locked.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .sheet(item: $editingMonthID) { item in
            MonthCustomizationSheet(
                month: item.id,
                currentCustomization: monthCustomizations[item.id] ?? MonthCustomization(),
                onSave: { customization in
                    if customization.icon?.isEmpty == false || customization.iconColorHex?.isEmpty == false || customization.message?.isEmpty == false {
                        saveMonthCustomization(customization, for: item.id)
                    } else {
                        saveMonthCustomization(nil, for: item.id)
                    }
                    editingMonthID = nil
                },
                onCancel: {
                    editingMonthID = nil
                },
                onReset: {
                    saveMonthCustomization(nil, for: item.id)
                    editingMonthID = nil
                }
            )
            .presentationDetents([.height(520)])
            .presentationCornerRadius(20)
        }
    }

    // MARK: - Lunar Calendar Section (情報デザイン: VN holidays)

    private var lunarCalendarSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "LUNAR CALENDAR", style: .whiteOnBlack, size: .small)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showLunarCalendar.toggle()
                }
                // Sync to App Group for widget
                UserDefaults(suiteName: "group.Johansson.Vecka")?.set(showLunarCalendar, forKey: "showLunarCalendar")
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
            .johoBordered()

            // Footer
            Text("Display Vietnamese lunar calendar dates (Âm Lịch) alongside Gregorian dates in the calendar.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick)
        .padding(.horizontal, JohoDimensions.spacingLG)
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
                            .font(JohoFont.label)
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
                        .strokeBorder(colors.border, lineWidth: JohoDimensions.borderMedium)
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
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick)
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
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick)
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
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick)
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

// MARK: - Settings Category Customization Sheet (情報デザイン: Icon + color per category)

/// Editor sheet for customizing category card icons AND colors
/// Opened from Settings → CATEGORIES section
struct SettingsCategoryCustomizationSheet: View {
    let category: DisplayCategory
    let onDone: () -> Void

    @State private var selectedIcon: String?
    @State private var showColorPicker = false
    @State private var selectedColorHex: String = ""

    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.dismiss) private var dismiss
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Dynamic category color (reads from CategoryColorSettings)
    private var categoryColor: Color {
        CategoryColorSettings.shared.color(for: category)
    }

    // 情報デザイン: Curated icon set for categories (shapes + conceptual)
    private let iconOptions: [String] = [
        // Shapes (core category icons)
        "circle", "diamond", "note.text", "square", "triangle", "plus",
        // Conceptual
        "star.fill", "heart.fill", "flag.fill", "bell.fill", "gift.fill", "bookmark.fill",
        // Status
        "checkmark.circle", "xmark.circle", "exclamationmark.circle", "questionmark.circle",
        // Nature
        "leaf.fill", "sun.max.fill", "moon.fill", "sparkles"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 情報デザイン: Bento-style header with category color banner
            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                        onDone()
                    } label: {
                        Text("Cancel")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(category.localizedLabel.uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)

                    Spacer()

                    Button {
                        CategoryIconSettings.setIcon(selectedIcon, for: category)
                        dismiss()
                        onDone()
                    } label: {
                        Text("Save")
                            .font(JohoFont.bodySmallBold)
                            .foregroundStyle(colors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(categoryColor)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.vertical, JohoDimensions.spacingMD)
                .background(categoryColor.opacity(0.3))

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)
            }

            // Content - scrollable for smaller screens
            ScrollView {
                VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                    // 情報デザイン: Preview card - bento style
                    HStack {
                        Spacer()
                        categoryPreview
                        Spacer()
                    }

                    // MASTER ICON section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(categoryColor)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))
                            Text("MASTER ICON")
                                .font(JohoFont.pillLabel)
                                .foregroundStyle(colors.primary.opacity(0.6))
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(iconOptions, id: \.self) { icon in
                                iconButton(icon)
                            }
                        }
                    }

                    // COLOR section - opens JohoColorPickerSheet
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(categoryColor)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))
                            Text("COLOR")
                                .font(JohoFont.pillLabel)
                                .foregroundStyle(colors.primary.opacity(0.6))
                        }

                        Button {
                            showColorPicker = true
                        } label: {
                            HStack {
                                RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous)
                                    .fill(categoryColor)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous)
                                            .stroke(colors.border, lineWidth: 1.5)
                                    )

                                Text("Change Color")
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(colors.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(colors.primary.opacity(0.4))
                            }
                            .padding(12)
                            .background(colors.inputBackground)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusCard))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusCard)
                                    .stroke(colors.border, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Reset button - resets both icon and color
                    Button {
                        CategoryColorSettings.shared.resetColor(for: category)
                        CategoryIconSettings.reset(for: category)
                        dismiss()
                        onDone()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(JohoFont.label)
                            Text("Reset All to Defaults")
                                .font(JohoFont.caption)
                        }
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(colors.inputBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusCard))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusCard)
                                .stroke(colors.border, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(JohoDimensions.spacingLG)
            }
        }
        .background(colors.surface)
        .onAppear {
            selectedIcon = CategoryIconSettings.icon(for: category)
            selectedColorHex = CategoryColorSettings.shared.colorHex(for: category)
        }
        .sheet(isPresented: $showColorPicker) {
            JohoColorPickerSheet(
                selectedColorHex: $selectedColorHex,
                title: "\(category.localizedLabel) Color",
                category: category,
                onDone: {
                    CategoryColorSettings.shared.setColorHex(selectedColorHex, for: category)
                }
            )
        }
    }

    // 情報デザイン: Preview card showing current selection (bento style)
    private var categoryPreview: some View {
        let displayIcon = selectedIcon ?? category.outlineIcon

        return VStack(spacing: 0) {
            // TOP: Icon zone with full-width category color
            VStack {
                Image(systemName: displayIcon)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(categoryColor)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // BOTTOM: Category name
            VStack(spacing: 2) {
                Text(category.localizedLabel.uppercased())
                    .font(JohoFont.pillLabel)
                    .foregroundStyle(colors.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(colors.surface)
        }
        .frame(width: 100)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: 1.5)
        )
    }

    private func iconButton(_ icon: String) -> some View {
        let isSelected = selectedIcon == icon
        let isDefault = (selectedIcon == nil && icon == category.outlineIcon)

        return Button {
            HapticManager.selection()
            if icon == category.outlineIcon && selectedIcon == nil {
                // Already at default, do nothing
            } else if selectedIcon == icon {
                selectedIcon = nil  // Clear to default
            } else {
                selectedIcon = icon
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 44, height: 44)
                .background((isSelected || isDefault) ? categoryColor : colors.inputBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusCard))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusCard)
                        .stroke(colors.border, lineWidth: (isSelected || isDefault) ? 2.5 : 1)
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
