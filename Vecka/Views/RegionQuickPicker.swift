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

    private var validCodes: Set<String> {
        Set(RegionSelectionView.allRegions.map { $0.code })
    }

    private var validSelectedRegions: [String] {
        selectedRegions.regions.filter { validCodes.contains($0) }
    }

    private var selectedCount: Int {
        validSelectedRegions.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header row
            collapsedRow

            // Expanded content
            if isExpanded {
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                expandedContent
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
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
                    .foregroundStyle(colors.primary.opacity(0.7))

                // Selected region pills (up to 3 shown, only valid codes)
                HStack(spacing: 4) {
                    ForEach(Array(validSelectedRegions.prefix(3)), id: \.self) { code in
                        Text(code)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primaryInverted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(selectedColor)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(colors.border, lineWidth: 1)
                            )
                    }

                    // Overflow indicator
                    if validSelectedRegions.count > 3 {
                        Text("+\(validSelectedRegions.count - 3)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(colors.primary.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(colors.border, lineWidth: 1)
                            )
                    }
                }

                Spacer()

                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.5))
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
            HStack(spacing: 8) {
                Text("HOLIDAY REGIONS")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(colors.primary)

                Spacer()

                // Clear All button (only when 2+ selected)
                if selectedCount >= 2 {
                    Button {
                        clearAllRegions()
                        HapticManager.impact(.light)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Clear")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(colors.inputBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(colors.border.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Done button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = false
                    }
                    HapticManager.selection()
                } label: {
                    Text("Done")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primaryInverted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colors.primary)
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
                                .fill(colors.border.opacity(0.5))
                                .frame(height: 1)
                        }
                    }
                }
            }

            // Footer with count
            HStack {
                Text("\(selectedCount)/5 selected")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.5))

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
                        .foregroundStyle(colors.primary.opacity(0.4))
                        .frame(width: 10)

                    // Continent icon
                    Image(systemName: continent.symbol)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(colors.primaryInverted)
                        .frame(width: 16, height: 16)
                        .background(colors.primary)
                        .clipShape(Squircle(cornerRadius: 3))

                    // Continent name
                    Text(continent.rawValue.uppercased())
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)

                    // Selected badge
                    if selected > 0 {
                        Text("\(selected)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primaryInverted)
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
            .foregroundStyle(isSelected ? colors.primaryInverted : colors.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? selectedColor : colors.surface)
            .clipShape(Squircle(cornerRadius: 6))
            .overlay(
                Squircle(cornerRadius: 6)
                    .stroke(colors.border, lineWidth: isSelected ? 1.5 : 1)
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

    private func clearAllRegions() {
        // Remove all stored codes (including any invalid/legacy ones like "NORDIC")
        for code in selectedRegions.regions {
            _ = selectedRegions.removeRegionIfPossible(code, minimumCount: 0)
        }
    }

    private func selectedCount(for continent: RegionSelectionView.Continent) -> Int {
        let continentCodes = regionsByContinent[continent]?.map { $0.code } ?? []
        return selectedRegions.regions.filter { continentCodes.contains($0) }.count
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var colorMode: JohoColorMode = .light

    VStack {
        RegionQuickPicker(selectedRegions: .constant(HolidayRegionSelection(regions: ["SE", "VN"])))
            .padding()

        Spacer()
    }
    .johoBackground()
    .environment(\.johoColorMode, colorMode)
}
