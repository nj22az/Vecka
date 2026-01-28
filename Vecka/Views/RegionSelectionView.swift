//
//  RegionSelectionView.swift
//  Vecka
//

import SwiftUI

struct RegionSelectionView: View {
    @Binding var selectedRegions: HolidayRegionSelection
    @AppStorage("showHolidays") private var showHolidays = true
    @State private var showSelectionLimitAlert = false
    @State private var expandedContinents: Set<Continent> = [.nordic]
    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.dismiss) private var dismiss

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var selectedColor: Color { JohoColors.red }

    /// Get sorted selected region codes for display
    private var sortedSelectedRegions: [String] {
        let validCodes = Set(Self.allRegions.map { $0.code })
        return selectedRegions.regions.filter { validCodes.contains($0) }.sorted()
    }

    // MARK: - Continent Enum

    enum Continent: String, CaseIterable, Identifiable {
        case nordic = "Nordic"
        case europe = "Europe"
        case asia = "Asia"
        case americas = "Americas"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .nordic: return "snowflake"
            case .europe: return "building.columns"
            case .asia: return "sun.horizon"
            case .americas: return "mountain.2"
            }
        }
    }

    // MARK: - Region Data

    struct RegionOption: Identifiable, Hashable {
        let code: String
        let titleKey: String
        let continent: Continent

        var id: String { code }
        var displayName: String { NSLocalizedString(titleKey, comment: "Region Name") }
    }

    static let allRegions: [RegionOption] = [
        // Nordic
        .init(code: "SE", titleKey: "region.sweden", continent: .nordic),
        .init(code: "NO", titleKey: "region.norway", continent: .nordic),
        .init(code: "DK", titleKey: "region.denmark", continent: .nordic),
        .init(code: "FI", titleKey: "region.finland", continent: .nordic),
        .init(code: "IS", titleKey: "region.iceland", continent: .nordic),
        .init(code: "GL", titleKey: "region.greenland", continent: .nordic),
        .init(code: "FO", titleKey: "region.faroeislands", continent: .nordic),
        // Europe
        .init(code: "DE", titleKey: "region.germany", continent: .europe),
        .init(code: "GB", titleKey: "region.uk", continent: .europe),
        .init(code: "FR", titleKey: "region.france", continent: .europe),
        .init(code: "IT", titleKey: "region.italy", continent: .europe),
        .init(code: "NL", titleKey: "region.netherlands", continent: .europe),
        // Asia
        .init(code: "VN", titleKey: "region.vietnam", continent: .asia),
        .init(code: "JP", titleKey: "region.japan", continent: .asia),
        .init(code: "HK", titleKey: "region.hongkong", continent: .asia),
        .init(code: "CN", titleKey: "region.china", continent: .asia),
        .init(code: "TH", titleKey: "region.thailand", continent: .asia),
        // Americas
        .init(code: "US", titleKey: "region.us", continent: .americas),
    ]

    private var regionsByContinent: [Continent: [RegionOption]] {
        Dictionary(grouping: Self.allRegions) { $0.continent }
    }

    private var selectedCount: Int {
        let validCodes = Set(Self.allRegions.map { $0.code })
        return selectedRegions.regions.filter { validCodes.contains($0) }.count
    }

    private func selectedCount(for continent: Continent) -> Int {
        let continentCodes = regionsByContinent[continent]?.map { $0.code } ?? []
        return selectedRegions.regions.filter { continentCodes.contains($0) }.count
    }

    private var subtitleText: String {
        if !showHolidays {
            return "Hidden from calendar"
        } else if selectedCount == 0 {
            return "No regions selected"
        } else {
            return "\(selectedCount) region\(selectedCount == 1 ? "" : "s") active"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingMD) {
                    // Page Header with inline toggle (情報デザイン: Bento style)
                    HStack(alignment: .top) {
                        JohoPageHeader(
                            title: "Holidays",
                            badge: "\(selectedCount)/5",
                            subtitle: subtitleText
                        )

                        Spacer()

                        // Toggle with border (情報デザイン: Action zone)
                        Toggle("", isOn: $showHolidays)
                            .labelsHidden()
                            .tint(selectedColor)
                            .padding(8)
                            .background(colors.surface)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                            )
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                    // 情報デザイン: Selected regions summary (quick reference chips)
                    if selectedCount > 0 {
                        selectedRegionsSummary
                            .padding(.horizontal, JohoDimensions.spacingLG)
                    }

                    // Regions container (情報デザイン: Collapsible sections)
                    VStack(spacing: 0) {
                        ForEach(Continent.allCases) { continent in
                            if let regions = regionsByContinent[continent] {
                                continentSection(continent, regions: regions)

                                if continent != Continent.allCases.last {
                                    Rectangle()
                                        .fill(colors.border.opacity(0.5))
                                        .frame(height: 1)
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
                .padding(.bottom, JohoDimensions.spacingLG)
            }

            // 情報デザイン: Prominent Done button (sticky footer)
            doneButton
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .alert("Limit Reached", isPresented: $showSelectionLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can select up to five regions.")
        }
    }

    // MARK: - Selected Regions Summary (情報デザイン: Quick reference chips with remove action)

    private var selectedRegionsSummary: some View {
        FlowLayout(spacing: 6) {
            ForEach(sortedSelectedRegions, id: \.self) { code in
                HStack(spacing: 4) {
                    Text(code)
                        .font(.system(size: 11, weight: .bold, design: .rounded))

                    Button {
                        _ = selectedRegions.removeRegionIfPossible(code, minimumCount: 0)
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                    }
                }
                .foregroundStyle(colors.primaryInverted)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(selectedColor)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                )
            }
        }
    }

    // MARK: - Done Button (情報デザイン: Prominent action button with Clear All)

    private var doneButton: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            HStack(spacing: JohoDimensions.spacingMD) {
                // Clear All (secondary action) - only visible when 2+ regions selected
                if selectedCount >= 2 {
                    Button {
                        clearAllRegions()
                        HapticManager.impact(.light)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text("Clear All")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(colors.inputBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(colors.border.opacity(0.5), lineWidth: JohoDimensions.borderMedium)
                        )
                    }
                }

                Spacer()

                // Done (primary action)
                Button {
                    dismiss()
                    HapticManager.impact(.light)
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primaryInverted)
                        .padding(.horizontal, 32)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(selectedCount > 0 ? selectedColor : colors.primary)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
                        )
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(colors.surface)
        }
    }

    // MARK: - Continent Section

    private func continentSection(_ continent: Continent, regions: [RegionOption]) -> some View {
        let isExpanded = expandedContinents.contains(continent)
        let selected = selectedCount(for: continent)

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedContinents.remove(continent)
                    } else {
                        expandedContinents.insert(continent)
                    }
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: 8) {
                    // Chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(colors.primary.opacity(0.4))
                        .frame(width: 12)

                    // Continent icon
                    Image(systemName: continent.symbol)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(colors.primaryInverted)
                        .frame(width: 20, height: 20)
                        .background(colors.primary)
                        .clipShape(Squircle(cornerRadius: 4))

                    // Continent name
                    Text(continent.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(colors.primary)

                    // Selected badge
                    if selected > 0 {
                        Text("\(selected)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primaryInverted)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(selectedColor)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Region count
                    Text("\(regions.count)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.3))
                }
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                regionChips(regions)
            }
        }
    }

    // MARK: - Region Chips

    private func regionChips(_ regions: [RegionOption]) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(regions) { region in
                regionChip(region)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.bottom, JohoDimensions.spacingSM)
    }

    private func regionChip(_ region: RegionOption) -> some View {
        let isSelected = selectedRegions.regions.contains(region.code)

        return Button {
            toggle(region.code)
        } label: {
            HStack(spacing: 4) {
                Text(region.code)
                    .font(.system(size: 10, weight: .black, design: .rounded))

                Text(region.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? colors.primaryInverted : colors.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? selectedColor : colors.surface)
            .clipShape(Squircle(cornerRadius: 8))
            .overlay(
                Squircle(cornerRadius: 8)
                    .stroke(colors.border, lineWidth: isSelected ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toggle

    private func toggle(_ code: String) {
        if selectedRegions.regions.contains(code) {
            // Allow deselecting down to zero
            if selectedRegions.removeRegionIfPossible(code, minimumCount: 0) {
                HapticManager.selection()
            }
        } else {
            if selectedRegions.addRegionIfPossible(code, maxCount: 5) {
                HapticManager.selection()
            } else {
                showSelectionLimitAlert = true
                HapticManager.impact(.light)
            }
        }
    }

    // MARK: - Clear All Regions

    private func clearAllRegions() {
        let validCodes = Set(Self.allRegions.map { $0.code })
        for code in selectedRegions.regions.filter({ validCodes.contains($0) }) {
            _ = selectedRegions.removeRegionIfPossible(code, minimumCount: 0)
        }
    }
}
