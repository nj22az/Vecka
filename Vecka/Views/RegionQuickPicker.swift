//
//  RegionQuickPicker.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Inline Region Quick Picker
//  Expandable region selector for Star page header
//

import SwiftUI

/// 情報デザイン: Inline expandable region picker for Star page
/// Collapsed: Shows selected region chips
/// Expanded: Full continent sections with region chips
struct RegionQuickPicker: View {
    @Binding var selectedRegions: HolidayRegionSelection
    @State private var isExpanded = false
    @State private var expandedContinents: Set<RegionSelectionView.Continent> = [.nordic]
    @State private var showSelectionLimitAlert = false
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var selectedColor: Color { JohoColors.red }

    private var regionsByContinent: [RegionSelectionView.Continent: [RegionSelectionView.RegionOption]] {
        Dictionary(grouping: RegionSelectionView.allRegions) { $0.continent }
    }

    private var selectedCount: Int {
        let validCodes = Set(RegionSelectionView.allRegions.map { $0.code })
        return selectedRegions.regions.filter { validCodes.contains($0) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header row
            collapsedRow

            // Expanded content
            if isExpanded {
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                expandedContent
            }
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
        .alert("Limit Reached", isPresented: $showSelectionLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can select up to five regions.")
        }
    }

    // MARK: - Collapsed Row

    private var collapsedRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Globe icon
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.7))

                // Selected region pills (up to 3 shown)
                HStack(spacing: 4) {
                    ForEach(Array(selectedRegions.regions.prefix(3)), id: \.self) { code in
                        Text(code)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(JohoColors.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(selectedColor)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(JohoColors.black, lineWidth: 1)
                            )
                    }

                    // Overflow indicator
                    if selectedRegions.regions.count > 3 {
                        Text("+\(selectedRegions.regions.count - 3)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(JohoColors.black.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(JohoColors.black, lineWidth: 1)
                            )
                    }
                }

                Spacer()

                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingMD)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("HOLIDAY REGIONS")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(JohoColors.black)

                Spacer()

                // Done button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = false
                    }
                    HapticManager.selection()
                } label: {
                    Text("Done")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(JohoColors.black)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Continent sections
            VStack(spacing: 0) {
                ForEach(RegionSelectionView.Continent.allCases) { continent in
                    if let regions = regionsByContinent[continent] {
                        continentSection(continent, regions: regions)

                        if continent != RegionSelectionView.Continent.allCases.last {
                            Rectangle()
                                .fill(JohoColors.black.opacity(0.1))
                                .frame(height: 1)
                        }
                    }
                }
            }

            // Footer with count
            HStack {
                Text("\(selectedCount)/5 selected")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.5))

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
    }

    // MARK: - Continent Section

    private func continentSection(_ continent: RegionSelectionView.Continent, regions: [RegionSelectionView.RegionOption]) -> some View {
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
                HStack(spacing: 6) {
                    // Chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(JohoColors.black.opacity(0.4))
                        .frame(width: 10)

                    // Continent icon
                    Image(systemName: continent.symbol)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(JohoColors.white)
                        .frame(width: 16, height: 16)
                        .background(JohoColors.black)
                        .clipShape(Squircle(cornerRadius: 3))

                    // Continent name
                    Text(continent.rawValue.uppercased())
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    // Selected badge
                    if selected > 0 {
                        Text("\(selected)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(selectedColor)
                            .clipShape(Capsule())
                    }

                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                regionChips(regions)
            }
        }
    }

    // MARK: - Region Chips

    private func regionChips(_ regions: [RegionSelectionView.RegionOption]) -> some View {
        FlowLayout(spacing: 4) {
            ForEach(regions) { region in
                regionChip(region)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.bottom, JohoDimensions.spacingSM)
    }

    private func regionChip(_ region: RegionSelectionView.RegionOption) -> some View {
        let isSelected = selectedRegions.regions.contains(region.code)

        return Button {
            toggle(region.code)
        } label: {
            HStack(spacing: 3) {
                Text(region.code)
                    .font(.system(size: 8, weight: .black, design: .rounded))

                Text(region.displayName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? JohoColors.white : JohoColors.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? selectedColor : JohoColors.white)
            .clipShape(Squircle(cornerRadius: 6))
            .overlay(
                Squircle(cornerRadius: 6)
                    .stroke(JohoColors.black, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toggle

    private func toggle(_ code: String) {
        if selectedRegions.regions.contains(code) {
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

    private func selectedCount(for continent: RegionSelectionView.Continent) -> Int {
        let continentCodes = regionsByContinent[continent]?.map { $0.code } ?? []
        return selectedRegions.regions.filter { continentCodes.contains($0) }.count
    }
}

// MARK: - Preview

#Preview {
    VStack {
        RegionQuickPicker(selectedRegions: .constant(HolidayRegionSelection(regions: ["SE", "VN"])))
            .padding()

        Spacer()
    }
    .background(JohoColors.background)
}
