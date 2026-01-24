//
//  RegionSelectionView.swift
//  Vecka
//

import SwiftUI

struct RegionSelectionView: View {
    @Binding var selectedRegions: HolidayRegionSelection
    @State private var showSelectionLimitAlert = false
    @State private var expandedContinents: Set<Continent> = [.nordic] // Nordic expanded by default
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var accentColor: Color { JohoColors.pink }

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

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingMD) {
                // Header with selection count
                JohoPageHeader(
                    title: NSLocalizedString("settings.region", comment: "Region"),
                    badge: "\(selectedCount)/5",
                    subtitle: "Tap headers to expand"
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

                // All regions in one container
                VStack(spacing: 0) {
                    ForEach(Continent.allCases) { continent in
                        if let regions = regionsByContinent[continent] {
                            // Collapsible continent section
                            continentSection(continent, regions: regions)

                            // Divider (except after last)
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
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .alert("Limit Reached", isPresented: $showSelectionLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can select up to five regions.")
        }
    }

    // MARK: - Continent Section (Collapsible)

    private func continentSection(_ continent: Continent, regions: [RegionOption]) -> some View {
        let isExpanded = expandedContinents.contains(continent)
        let selected = selectedCount(for: continent)

        return VStack(spacing: 0) {
            // Tappable header
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
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .frame(width: 16)

                    // Continent icon
                    Image(systemName: continent.symbol)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(colors.primaryInverted)
                        .frame(width: 24, height: 24)
                        .background(colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                    // Continent name
                    Text(continent.rawValue.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(colors.primary)

                    // Selected badge
                    if selected > 0 {
                        Text("\(selected)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primaryInverted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Region count
                    Text("\(regions.count)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.4))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                regionChips(regions)
            }
        }
    }

    // MARK: - Region Chips (Horizontal Flow)

    private func regionChips(_ regions: [RegionOption]) -> some View {
        FlowLayout(spacing: JohoDimensions.spacingSM) {
            ForEach(regions) { region in
                regionChip(region)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.bottom, JohoDimensions.spacingMD)
    }

    private func regionChip(_ region: RegionOption) -> some View {
        let isSelected = selectedRegions.regions.contains(region.code)

        return Button {
            toggle(region.code)
        } label: {
            HStack(spacing: 6) {
                Text(region.code)
                    .font(.system(size: 11, weight: .black, design: .rounded))

                Text(region.displayName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? colors.primaryInverted : colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? accentColor : colors.surface)
            .clipShape(Squircle(cornerRadius: 10))
            .overlay(
                Squircle(cornerRadius: 10)
                    .stroke(isSelected ? accentColor : colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toggle

    private func toggle(_ code: String) {
        if selectedRegions.regions.contains(code) {
            if selectedRegions.removeRegionIfPossible(code, minimumCount: 1) {
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
}
