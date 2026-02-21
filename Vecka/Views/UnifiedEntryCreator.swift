//
//  UnifiedEntryCreator.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Say More With Less
//  One unified entry creator that adapts to context:
//  - Star page (month view): Holiday, Observance
//  - Calendar page: Memo only
//

import SwiftUI
import SwiftData
import PhotosUI

/// Currency options with SF Symbol icons
enum CurrencyOption: String, CaseIterable, Identifiable {
    case dollar, euro, pound, yen, krona, franc, bitcoin

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dollar: return "dollarsign.circle"
        case .euro: return "eurosign.circle"
        case .pound: return "sterlingsign.circle"
        case .yen: return "yensign.circle"
        case .krona: return "k.circle"  // No krona symbol, use K
        case .franc: return "francsign.circle"
        case .bitcoin: return "bitcoinsign.circle"
        }
    }

    /// Get default currency based on device locale
    static var fromLocale: CurrencyOption {
        guard let currencyCode = Locale.current.currency?.identifier else { return .dollar }
        switch currencyCode {
        case "USD": return .dollar
        case "EUR": return .euro
        case "GBP": return .pound
        case "JPY", "CNY": return .yen
        case "SEK", "NOK", "DKK", "ISK": return .krona
        case "CHF": return .franc
        default: return .dollar
        }
    }

    var code: String {
        switch self {
        case .dollar: return "USD"
        case .euro: return "EUR"
        case .pound: return "GBP"
        case .yen: return "JPY"
        case .krona: return "SEK"
        case .franc: return "CHF"
        case .bitcoin: return "BTC"
        }
    }
}

/// Entry types available in the unified creator
enum UnifiedEntryType: String, CaseIterable, Identifiable {
    case holiday
    case observance
    case memo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .holiday: return "HOLIDAY"
        case .observance: return "OBS"
        case .memo: return "MEMO"
        }
    }

    var displayCategory: DisplayCategory {
        switch self {
        case .holiday: return .holiday
        case .observance: return .observance
        case .memo: return .memo
        }
    }
}

/// Unified entry creator configuration
/// Icons resolve via DisplayCategory.categoryAwareIcon (no icon pass-through needed)
struct UnifiedEntryConfig {
    let availableTypes: Set<UnifiedEntryType>
    let initialDate: Date
    let enabledRegions: [String]

    /// Calendar context: Only memo
    static func calendarContext(date: Date) -> UnifiedEntryConfig {
        UnifiedEntryConfig(
            availableTypes: [.memo],
            initialDate: date,
            enabledRegions: []
        )
    }

    /// Star page context: Holiday + Observance
    static func starPageContext(
        date: Date,
        enabledRegions: [String]
    ) -> UnifiedEntryConfig {
        UnifiedEntryConfig(
            availableTypes: [.holiday, .observance],
            initialDate: date,
            enabledRegions: enabledRegions
        )
    }

    /// Full context: All three types (Holiday, Observance, Memo)
    static func fullContext(
        date: Date,
        enabledRegions: [String] = []
    ) -> UnifiedEntryConfig {
        UnifiedEntryConfig(
            availableTypes: [.holiday, .observance, .memo],
            initialDate: date,
            enabledRegions: enabledRegions
        )
    }
}

// MARK: - Unified Entry Creator View

struct UnifiedEntryCreator: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    let config: UnifiedEntryConfig
    let onSaveHoliday: ((SpecialDayType, String, String?, String, Int, Int, Int) -> Void)?
    let onSaveMemo: ((String, Date, Double?, String?, String?, UUID?, Data?) -> Void)?

    // Form state
    @State private var selectedType: UnifiedEntryType
    @State private var text: String = ""
    @State private var date: Date

    // Holiday/Observance specific
    @State private var selectedRegion: String = "PERSONAL"
    @State private var about: String = ""

    // Memo specific
    @State private var amount: String = ""
    @State private var selectedCurrency: CurrencyOption = .fromLocale
    @State private var place: String = ""
    @State private var showAmount = false
    @State private var showPlace = false
    @State private var showContact = false
    @State private var linkedContactID: UUID?
    @State private var linkedContactName: String = ""
    @State private var showContactPicker = false
    @State private var showPhoto = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?

    // UI state
    @State private var showDatePicker = false

    // System UI accent
    @AppStorage("systemUIAccent") private var systemUIAccent = "blue"
    @AppStorage("customHolidayRegions") private var customRegionsData: Data = Data()

    private var accentColor: Color {
        (SystemUIAccent(rawValue: systemUIAccent) ?? .blue).color
    }

    private var customRegions: [String] {
        guard !customRegionsData.isEmpty,
              let decoded = try? JSONDecoder().decode([String].self, from: customRegionsData) else {
            return []
        }
        return decoded
    }

    // Computed properties
    private var isHolidayMode: Bool { selectedType == .holiday || selectedType == .observance }
    private var isMemoMode: Bool { selectedType == .memo }
    private var showTypeSelector: Bool { true }

    private var headerTitle: String {
        if config.availableTypes.count == 1, let firstType = config.availableTypes.first {
            return "NEW \(firstType.label)"
        }
        return "NEW ENTRY"
    }

    private var typeIcon: String {
        selectedType.displayCategory.categoryAwareIcon
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(
        config: UnifiedEntryConfig,
        onSaveHoliday: ((SpecialDayType, String, String?, String, Int, Int, Int) -> Void)? = nil,
        onSaveMemo: ((String, Date, Double?, String?, String?, UUID?, Data?) -> Void)? = nil
    ) {
        self.config = config
        self.onSaveHoliday = onSaveHoliday
        self.onSaveMemo = onSaveMemo

        // Initialize with first available type
        let initialType: UnifiedEntryType = config.availableTypes.contains(.memo) ? .memo :
                         config.availableTypes.contains(.holiday) ? .holiday : .observance
        _selectedType = State(initialValue: initialType)
        _date = State(initialValue: config.initialDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerRow

            JohoDivider()

            // Type selector (only if multiple types available)
            if showTypeSelector {
                typeRow
                JohoDivider(weight: 1.5)
            }

            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Text input
                    textRow

                    JohoDivider(weight: 1.5)

                    // Date row
                    dateRow

                    // Holiday/Observance specific rows
                    if isHolidayMode {
                        JohoDivider(weight: 1.5)
                        aboutRow

                        JohoDivider(weight: 1.5)
                        regionRow
                    }

                    // Memo specific rows
                    if isMemoMode {
                        JohoDivider(weight: 1.5)
                        memoOptionsRow

                        if showAmount {
                            JohoDivider(weight: 1.5)
                            amountRow
                        }

                        if showPlace {
                            JohoDivider(weight: 1.5)
                            placeRow
                        }

                        if showContact {
                            JohoDivider(weight: 1.5)
                            contactRow
                        }

                        if showPhoto {
                            JohoDivider(weight: 1.5)
                            photoRow
                        }
                    }
                }
                .background(colors.surface)
                .johoBordered(cornerRadius: 16, borderWidth: 2)
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingMD)
            }

            Spacer()

            // Save button
            saveButton
        }
        .background(colors.canvas)
        .presentationBackground(colors.canvas)
        .presentationDragIndicator(.visible)
        .johoCalendarPicker(
            isPresented: $showDatePicker,
            selectedDate: $date,
            accentColor: accentColor
        )
        .sheet(isPresented: $showContactPicker) {
            MemoContactPicker(
                selectedContactID: $linkedContactID,
                selectedContactName: $linkedContactName
            )
            .presentationBackground(colors.canvas)
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: IconCatalog.xmark)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
                    .frame(width: 32, height: 32)
                    .background(colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
            }

            Spacer()

            Text(headerTitle)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(colors.surface)
    }

    // MARK: - Type Selector (Holiday/Observance only)

    private var typeRow: some View {
        HStack(spacing: 0) {
            Image(systemName: typeIcon)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48).frame(maxHeight: .infinity)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            HStack(spacing: JohoDimensions.spacingSM) {
                ForEach(Array(config.availableTypes).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                    typePill(type)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 56)
        .background(accentColor.opacity(0.15))
    }

    private func typePill(_ type: UnifiedEntryType) -> some View {
        let isSelected = selectedType == type
        let icon = type.displayCategory.categoryAwareIcon

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedType = type
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(JohoFont.label)
                Text(type.label)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : colors.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? accentColor : colors.surface)
            .johoBordered(cornerRadius: 10, borderWidth: isSelected ? 2 : 1.5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Text Row

    private var textRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.pencil)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48).frame(maxHeight: .infinity)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            TextField(isMemoMode ? "Write something..." : "Name (e.g., Earth Day)", text: $text, axis: .vertical)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary)
                .lineLimit(1...4)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .frame(maxHeight: .infinity)
        }
        .frame(minHeight: 48)
    }

    // MARK: - Date Row

    private var dateRow: some View {
        Button {
            showDatePicker = true
            HapticManager.impact(.light)
        } label: {
            HStack(spacing: 0) {
                Image(systemName: IconCatalog.calendar)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
                    .frame(width: 48)

                Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48)

                Text(formattedDate)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
                    .monospacedDigit()
                    .padding(.horizontal, JohoDimensions.spacingMD)

                Spacer()

                Image(systemName: IconCatalog.chevronRight)
                    .font(JohoFont.label)
                    .foregroundStyle(colors.secondary)
                    .padding(.trailing, JohoDimensions.spacingMD)
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy    MM    dd"
        return formatter.string(from: date)
    }

    // MARK: - Holiday/Observance: About Row

    private var aboutRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.memo)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48).frame(maxHeight: .infinity)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            TextField("About / Purpose (optional)", text: $about)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .frame(maxHeight: .infinity)
        }
        .frame(height: 48)
    }

    // MARK: - Holiday/Observance: Region Row

    private var regionRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.globe)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48).frame(maxHeight: .infinity)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            Menu {
                Button {
                    selectedRegion = "PERSONAL"
                    HapticManager.selection()
                } label: {
                    Label("Personal", systemImage: IconCatalog.person)
                }

                Divider()

                ForEach(config.enabledRegions, id: \.self) { region in
                    Button {
                        selectedRegion = region
                        HapticManager.selection()
                    } label: {
                        Label(region, systemImage: "flag.fill")
                    }
                }

                if !customRegions.isEmpty {
                    Divider()
                    ForEach(customRegions, id: \.self) { region in
                        Button {
                            selectedRegion = region
                            HapticManager.selection()
                        } label: {
                            Label(region, systemImage: "tag.fill")
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedRegion == "PERSONAL" ? IconCatalog.person : "flag.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(selectedRegion == "PERSONAL" ? "Personal" : selectedRegion)
                        .font(JohoFont.bodySmall)

                    Spacer()

                    Image(systemName: IconCatalog.chevronUpDown)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(colors.secondary)
                }
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingMD)
            }
        }
        .frame(height: 48)
    }

    // MARK: - Memo: Options Row

    private var memoOptionsRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.plusCircle)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            HStack(spacing: 8) {
                iconChip(icon: selectedCurrency.icon, isActive: showAmount) {
                    withAnimation(.easeInOut(duration: 0.2)) { showAmount.toggle() }
                }

                iconChip(icon: IconCatalog.mappin, isActive: showPlace) {
                    withAnimation(.easeInOut(duration: 0.2)) { showPlace.toggle() }
                }

                iconChip(icon: "person", isActive: showContact) {
                    withAnimation(.easeInOut(duration: 0.2)) { showContact.toggle() }
                }

                iconChip(icon: IconCatalog.photo, isActive: showPhoto) {
                    withAnimation(.easeInOut(duration: 0.2)) { showPhoto.toggle() }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()
        }
        .frame(height: 56)
    }

    private func optionChip(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.selection()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(JohoFont.labelSmall)
            }
            .foregroundStyle(isActive ? .white : colors.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? accentColor : colors.surface)
            .johoBordered(cornerRadius: 8, borderWidth: 1.5)
        }
        .buttonStyle(.plain)
    }

    /// Icon-only chip (no label)
    private func iconChip(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.selection()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isActive ? .white : colors.primary)
                .frame(width: 36, height: 36)
                .background(isActive ? accentColor : colors.surface)
                .johoBordered(cornerRadius: 8, borderWidth: 1.5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Memo: Amount Row

    private var amountRow: some View {
        HStack(spacing: 0) {
            // Currency icon picker (tap to change)
            Menu {
                ForEach(CurrencyOption.allCases) { currency in
                    Button {
                        selectedCurrency = currency
                        HapticManager.selection()
                    } label: {
                        Label(currency.code, systemImage: currency.icon)
                    }
                }
            } label: {
                Image(systemName: selectedCurrency.icon)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48)

            HStack(spacing: 12) {
                TextField("0", text: $amount)
                    .font(JohoFont.headlineSmall)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(colors.primary)

                // Currency code badge (read-only, shows selected)
                Text(selectedCurrency.code)
                    .font(JohoFont.label)
                    .foregroundStyle(colors.primary)
                    .frame(width: 44)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .background(colors.inputBackground)
                    .johoBordered(cornerRadius: 6, borderWidth: 1.5)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
        }
        .frame(height: 48)
    }

    // MARK: - Memo: Place Row

    private var placeRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.mappin)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48)

            TextField("Where...", text: $place)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingMD)
        }
        .frame(height: 48)
    }

    // MARK: - Memo: Contact Row

    private var contactRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.person)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48)

            Button {
                showContactPicker = true
                HapticManager.impact(.light)
            } label: {
                HStack {
                    if linkedContactID != nil {
                        Image(systemName: IconCatalog.checkmarkCircleFill)
                            .foregroundStyle(accentColor)
                        Text(linkedContactName.isEmpty ? "Linked" : linkedContactName)
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.primary)
                    } else {
                        Text("Select contact...")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.secondary)
                    }

                    Spacer()

                    if linkedContactID != nil {
                        Button {
                            linkedContactID = nil
                            linkedContactName = ""
                            HapticManager.selection()
                        } label: {
                            Image(systemName: IconCatalog.xmarkCircleFill)
                                .foregroundStyle(colors.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Image(systemName: IconCatalog.chevronRight)
                        .font(JohoFont.label)
                        .foregroundStyle(colors.secondary)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 48)
    }

    // MARK: - Memo: Photo Row

    private var photoRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.photo)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 80)

            HStack(spacing: JohoDimensions.spacingMD) {
                // Photo preview or picker
                if let data = photoData, let uiImage = UIImage(data: data) {
                    // Show thumbnail
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Squircle(cornerRadius: 8))
                        .overlay(Squircle(cornerRadius: 8).stroke(colors.border, lineWidth: 1.5))

                    // Remove button
                    Button {
                        photoData = nil
                        selectedPhotoItem = nil
                        HapticManager.selection()
                    } label: {
                        Image(systemName: IconCatalog.xmarkCircleFill)
                            .font(.system(size: 20))
                            .foregroundStyle(colors.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Photo picker button
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: IconCatalog.plus)
                                .font(.system(size: 12, weight: .bold))
                            Text("Add Photo")
                                .font(JohoFont.bodySmall)
                        }
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(colors.inputBackground)
                        .johoBordered(cornerRadius: 8, borderWidth: 1.5)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
        }
        .frame(height: 80)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    // Compress to JPEG
                    if let uiImage = UIImage(data: data),
                       let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                        photoData = compressed
                    }
                }
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack {
                Image(systemName: IconCatalog.checkmark)
                    .font(JohoFont.bodySmallBold)
                Text("SAVE")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(canSave ? .white : colors.primary.opacity(0.4))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(canSave ? accentColor : colors.inputBackground)
            .johoBordered(cornerRadius: 12, borderWidth: 2)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
    }

    // MARK: - Save Action

    private func save() {
        let calendar = Calendar.current

        switch selectedType {
        case .holiday, .observance:
            let type: SpecialDayType = selectedType == .holiday ? .holiday : .observance
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            onSaveHoliday?(type, text, about.isEmpty ? nil : about, selectedRegion, year, month, day)

        case .memo:
            let amountValue = showAmount ? Double(amount) : nil
            let placeValue = showPlace && !place.isEmpty ? place : nil
            let currencyValue = showAmount ? selectedCurrency.code : nil
            let photoValue = showPhoto ? photoData : nil
            onSaveMemo?(text, date, amountValue, currencyValue, placeValue, showContact ? linkedContactID : nil, photoValue)
        }

        HapticManager.notification(.success)
        dismiss()
    }
}

#Preview {
    UnifiedEntryCreator(
        config: .calendarContext(date: Date()),
        onSaveMemo: { _, _, _, _, _, _, _ in }
    )
}
