//
//  MemoEditorView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) Intelligent Memo Editor
//  Universal Memo container with smart field revelation
//  Type = Flag that determines which fields appear
//  Custom icon and color for personalization
//

import SwiftUI
import SwiftData

// MARK: - Intelligent Memo Editor

struct MemoEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.dismiss) private var dismiss

    // MARK: - Input Properties

    let existingMemo: Memo?
    let date: Date
    let parentMemo: Memo?

    // MARK: - Core State (all memos)

    @State private var memoType: MemoType = .note
    @State private var memoTitle: String = ""
    @State private var memoBody: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()

    // MARK: - Feature Flags State (combinable)

    @State private var activeFeatures: Set<MemoFeature> = [.note]

    // MARK: - Debt Tracking State

    @State private var linkedContact: Contact?
    @State private var debtDirection: DebtDirection = .iOwe
    @State private var isDebtSettled: Bool = false
    @State private var showContactPicker: Bool = false

    // MARK: - Customization State

    @State private var selectedIcon: String = "note.text"
    @State private var selectedColorHex: String = "FFE566"  // Yellow default

    // MARK: - Type-Specific State

    // Money (Expense)
    @State private var amount: String = ""
    @State private var currency: String = "SEK"
    @State private var category: String = ""
    @State private var isReimbursable: Bool = false

    // Travel (Trip)
    @State private var tripType: TripType = .personal
    @State private var destination: String = ""

    // Distance (Mileage)
    @State private var distance: String = ""
    @State private var startLocation: String = ""
    @State private var endLocation: String = ""
    @State private var isRoundTrip: Bool = false

    // Note-specific
    @State private var priority: MemoPriority = .normal

    // Tags (all types)
    @State private var tags: String = ""

    // MARK: - UI State

    @State private var showingDeleteConfirmation = false
    @State private var showIconPicker = false
    @State private var showColorPicker = false
    @FocusState private var focusedField: Field?

    // 情報デザイン: Collapsible section states (ContactListView pattern)
    @State private var isMoneyExpanded = true
    @State private var isDebtExpanded = true
    @State private var isMoreExpanded = false

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var isEditing: Bool { existingMemo != nil }

    enum Field: Hashable {
        case title, body, amount, destination, distance, startLocation, endLocation, category, tags
    }

    // MARK: - Init

    init(date: Date = Date(), existingMemo: Memo? = nil, parentMemo: Memo? = nil) {
        self.date = date
        self.existingMemo = existingMemo
        self.parentMemo = parentMemo
    }

    // MARK: - Body (情報デザイン: Single white container, no scroll, collapsible sections)

    var body: some View {
        NavigationStack {
            // 情報デザイン: Single white container with all content
            VStack(spacing: 0) {
                mainContentCard
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.top, JohoDimensions.spacingSM)
            .frame(maxHeight: .infinity, alignment: .top)
            .johoBackground()
            .navigationTitle(isEditing ? "Edit Memo" : "Add Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JohoColors.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { toolbarContent }
            .onAppear { loadExistingMemo() }
        }
        .alert("Delete Memo?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteMemo() }
        } message: {
            Text("This cannot be undone.")
        }
        .sheet(isPresented: $showIconPicker) {
            iconPickerSheet
        }
        .sheet(isPresented: $showColorPicker) {
            colorPickerSheet
        }
        .sheet(isPresented: $showContactPicker) {
            contactPickerSheet
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(colors.primary)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("Save") { saveMemo() }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(canSave ? colors.primary : colors.secondary.opacity(0.5))
                .disabled(!canSave)
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Main Content Card (情報デザイン: Single white container)
    // ═══════════════════════════════════════════════════════════════════════════

    private var mainContentCard: some View {
        VStack(spacing: 0) {
            // Row 1: Features (always visible)
            collapsibleFeatureRow

            dividerLine

            // Row 2: Core fields (Title + Date - always visible)
            coreFieldsRow

            // Row 3: Money fields (collapsible, if .expense active)
            if showsMoneyFields {
                dividerLine
                collapsibleMoneyRow
            }

            // Row 4: Debt fields (collapsible, if .debt active)
            if showsDebtFields {
                dividerLine
                collapsibleDebtRow
            }

            // Row 5: More options (collapsible - Priority, Icon, Color, Tags)
            dividerLine
            collapsibleMoreRow

            // Delete button (edit mode only)
            if isEditing {
                dividerLine
                deleteRow
            }
        }
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(colors.border)
            .frame(height: 1)
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Collapsible Feature Row
    // ═══════════════════════════════════════════════════════════════════════════

    private var collapsibleFeatureRow: some View {
        VStack(spacing: 0) {
            // Header: FEATURES | count
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("FEATURES")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(0.5)

                Spacer()

                Text("\(activeFeatures.count) ACTIVE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: selectedColorHex))
            }
            .foregroundStyle(colors.primary)
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Feature chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(MemoFeature.allCases) { feature in
                        JohoFeatureChip(
                            feature: feature,
                            isActive: activeFeatures.contains(feature),
                            action: {
                                if activeFeatures.contains(feature) {
                                    activeFeatures.remove(feature)
                                } else {
                                    activeFeatures.insert(feature)
                                }
                                updateTypeFromFeatures(activeFeatures)
                            }
                        )
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.bottom, JohoDimensions.spacingSM)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Core Fields Row (Title + Date - always visible)
    // ═══════════════════════════════════════════════════════════════════════════

    private var coreFieldsRow: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            // Title field
            HStack {
                Text(titleLabel.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                Spacer()
            }

            TextField(titlePlaceholder, text: $memoTitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
                .focused($focusedField, equals: .title)

            // Date row
            HStack {
                Text("DATE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                Spacer()
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color(hex: selectedColorHex))
            }
        }
        .padding(JohoDimensions.spacingMD)
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Collapsible Money Row
    // ═══════════════════════════════════════════════════════════════════════════

    private var collapsibleMoneyRow: some View {
        VStack(spacing: 0) {
            // Header toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMoneyExpanded.toggle()
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "yensign.circle")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text("MONEY")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(0.5)
                    Spacer()
                    Image(systemName: isMoneyExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isMoneyExpanded {
                VStack(spacing: JohoDimensions.spacingSM) {
                    // Amount + Currency row
                    HStack(spacing: JohoDimensions.spacingSM) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AMOUNT")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.secondary)
                            TextField("0.00", text: $amount)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .keyboardType(.decimalPad)
                                .foregroundStyle(colors.primary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENCY")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.secondary)
                            Picker("", selection: $currency) {
                                Text("SEK").tag("SEK")
                                Text("USD").tag("USD")
                                Text("EUR").tag("EUR")
                                Text("JPY").tag("JPY")
                            }
                            .pickerStyle(.menu)
                            .tint(colors.primary)
                        }
                    }

                    // Category
                    HStack {
                        Text("CATEGORY")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)
                        Spacer()
                    }
                    TextField("food, transport...", text: $category)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.bottom, JohoDimensions.spacingSM)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Collapsible Debt Row
    // ═══════════════════════════════════════════════════════════════════════════

    private var collapsibleDebtRow: some View {
        VStack(spacing: 0) {
            // Header toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isDebtExpanded.toggle()
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text("DEBT")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(0.5)
                    if let contact = linkedContact {
                        Text("• \(contact.displayName)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.purple)
                    }
                    Spacer()
                    Image(systemName: isDebtExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isDebtExpanded {
                VStack(spacing: JohoDimensions.spacingSM) {
                    // Contact picker button
                    Button {
                        showContactPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text(linkedContact?.displayName ?? "Select Contact")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.secondary)
                        }
                        .foregroundStyle(colors.primary)
                        .padding(JohoDimensions.spacingSM)
                        .background(colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                                .stroke(colors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    // Direction toggle
                    HStack(spacing: 0) {
                        Button {
                            debtDirection = .iOwe
                            HapticManager.selection()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.right")
                                Text("I OWE")
                            }
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(debtDirection == .iOwe ? colors.surfaceInverted : colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(debtDirection == .iOwe ? colors.primary : colors.surface)
                        }
                        .buttonStyle(.plain)

                        Button {
                            debtDirection = .theyOwe
                            HapticManager.selection()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.left")
                                Text("THEY OWE")
                            }
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(debtDirection == .theyOwe ? colors.surfaceInverted : colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(debtDirection == .theyOwe ? JohoColors.purple : colors.surface)
                        }
                        .buttonStyle(.plain)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                            .stroke(colors.border, lineWidth: 1)
                    )
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.bottom, JohoDimensions.spacingSM)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Collapsible More Row (Priority, Icon, Color, Tags)
    // ═══════════════════════════════════════════════════════════════════════════

    private var collapsibleMoreRow: some View {
        VStack(spacing: 0) {
            // Header toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMoreExpanded.toggle()
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text("MORE")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(0.5)
                    Spacer()
                    Image(systemName: isMoreExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isMoreExpanded {
                VStack(spacing: JohoDimensions.spacingSM) {
                    // Priority (if note feature active)
                    if showsPriority {
                        HStack {
                            Text("PRIORITY")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.secondary)
                            Spacer()
                        }
                        HStack(spacing: JohoDimensions.spacingSM) {
                            ForEach(MemoPriority.allCases, id: \.self) { p in
                                Button {
                                    priority = p
                                    HapticManager.selection()
                                } label: {
                                    Text(p.rawValue.uppercased())
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(priority == p ? colors.surfaceInverted : colors.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(priority == p ? colors.primary : colors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                                                .stroke(colors.border, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Icon + Color row
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Button { showIconPicker = true } label: {
                            VStack(spacing: 4) {
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                Text("ICON")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                                    .stroke(colors.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Button { showColorPicker = true } label: {
                            VStack(spacing: 4) {
                                // 情報デザイン: All circles must have black borders
                        Circle()
                                    .fill(Color(hex: selectedColorHex))
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
                                Text("COLOR")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                                    .stroke(colors.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Tags
                    HStack {
                        Text("TAGS")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)
                        Spacer()
                    }
                    TextField("work, important...", text: $tags)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.bottom, JohoDimensions.spacingSM)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Delete Row
    // ═══════════════════════════════════════════════════════════════════════════

    private var deleteRow: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("DELETE MEMO")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundStyle(JohoColors.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingSM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Feature Chip Selector (Combinable Features) - LEGACY
    // ═══════════════════════════════════════════════════════════════════════════

    private var typeFlagSelector: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // Label row
            HStack {
                Text("FEATURES")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(colors.secondary)
                    .tracking(1)

                Spacer()

                // Active features count
                // 情報デザイン: Use squircle, not Capsule
                Text("\(activeFeatures.count) ACTIVE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(colors.border, lineWidth: 1)
                    )
            }

            // Feature chips (horizontal scroll, multi-select)
            JohoFeatureChipRow(activeFeatures: $activeFeatures)
                .onChange(of: activeFeatures) { _, newFeatures in
                    updateTypeFromFeatures(newFeatures)
                }
        }
    }

    /// Update memoType based on primary feature
    private func updateTypeFromFeatures(_ features: Set<MemoFeature>) {
        // Get primary feature (highest priority)
        if let primary = features.min(by: { $0.priority < $1.priority }) {
            // 情報デザイン: Use easeInOut, never bouncy springs
            withAnimation(.easeInOut(duration: 0.2)) {
                memoType = primary.toType
                selectedIcon = primary.icon
                selectedColorHex = primary.colorHex
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Core Fields Section
    // ═══════════════════════════════════════════════════════════════════════════

    private var coreFieldsSection: some View {
        VStack(spacing: 0) {
            // Header
            sectionHeader(title: "MEMO", icon: "doc.text", color: Color(hex: selectedColorHex))

            Rectangle().fill(colors.border).frame(height: 1.5)

            VStack(spacing: JohoDimensions.spacingMD) {
                // Title (contextual placeholder based on type)
                johoTextField(
                    label: titleLabel,
                    text: $memoTitle,
                    placeholder: titlePlaceholder,
                    field: .title
                )

                // Body (contextual)
                if showsBodyField {
                    johoTextEditor(
                        label: bodyLabel,
                        text: $memoBody,
                        placeholder: bodyPlaceholder,
                        minHeight: memoType == .note ? 120 : 80
                    )
                }

                // Date
                johoDatePicker(label: "DATE", date: $startDate)

                // End date (for multi-day types)
                if showsEndDate {
                    johoDatePicker(label: "END DATE", date: $endDate)
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // Contextual labels and placeholders
    private var titleLabel: String {
        switch memoType {
        case .note: return "TITLE (OPTIONAL)"
        case .trip: return "TRIP NAME"
        case .expense: return "DESCRIPTION"
        case .mileage: return "TRIP PURPOSE"
        case .event: return "EVENT TITLE"
        case .countdown: return "COUNTDOWN TITLE"
        }
    }

    private var titlePlaceholder: String {
        switch memoType {
        case .note: return "Quick headline..."
        case .trip: return "Tokyo Adventure"
        case .expense: return "What was this for?"
        case .mileage: return "Client meeting"
        case .event: return "Team standup"
        case .countdown: return "Summer vacation!"
        }
    }

    private var bodyLabel: String {
        switch memoType {
        case .note: return "NOTE"
        case .trip, .event, .countdown, .mileage: return "NOTES (OPTIONAL)"
        case .expense: return "DETAILS (OPTIONAL)"
        }
    }

    private var bodyPlaceholder: String {
        switch memoType {
        case .note: return "Write your thoughts..."
        case .trip: return "Trip details, itinerary..."
        case .expense: return "Receipt details, vendor..."
        case .mileage: return "Purpose of trip..."
        case .event: return "Event details..."
        case .countdown: return "What are you counting down to?"
        }
    }

    private var showsBodyField: Bool {
        // All types show body, but it's more prominent for notes
        true
    }

    private var showsEndDate: Bool {
        memoType == .trip || memoType == .event
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Smart Fields Section (Type-Specific)
    // ═══════════════════════════════════════════════════════════════════════════

    @ViewBuilder
    private var smartFieldsSection: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            // Money fields (Expense)
            if showsMoneyFields {
                moneyFieldsCard
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }

            // Location fields (Mileage)
            if showsLocationFields {
                locationFieldsCard
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }

            // Travel fields (Trip)
            if showsTravelFields {
                travelFieldsCard
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }

            // Priority (Note)
            if showsPriority {
                priorityCard
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }

            // Debt tracking (links expense to contact)
            if showsDebtFields {
                debtCard
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }
        }
        // 情報デザイン: Use easeInOut for smooth transitions (no bouncy springs)
        .animation(.easeInOut(duration: 0.2), value: activeFeatures)
    }

    // Field visibility rules (based on active features, not exclusive type)
    private var showsMoneyFields: Bool { activeFeatures.contains(.expense) }
    private var showsLocationFields: Bool { activeFeatures.contains(.mileage) }
    private var showsTravelFields: Bool { activeFeatures.contains(.trip) }
    private var showsPriority: Bool { activeFeatures.contains(.note) }
    private var showsDebtFields: Bool { activeFeatures.contains(.debt) }

    // MARK: - Money Fields Card (Expense)

    private var moneyFieldsCard: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "MONEY", icon: "yensign.circle", color: JohoColors.green)

            Rectangle().fill(colors.border).frame(height: 1.5)

            VStack(spacing: JohoDimensions.spacingMD) {
                // Amount + Currency
                HStack(spacing: JohoDimensions.spacingSM) {
                    johoTextField(
                        label: "AMOUNT",
                        text: $amount,
                        placeholder: "0.00",
                        field: .amount,
                        keyboardType: .decimalPad
                    )

                    currencySelector
                        .frame(width: 100)
                }

                // Category
                johoTextField(
                    label: "CATEGORY",
                    text: $category,
                    placeholder: "food, transport, hotel...",
                    field: .category
                )

                // Reimbursable toggle
                toggleRow(
                    title: "REIMBURSABLE",
                    subtitle: "Can be reimbursed?",
                    isOn: $isReimbursable,
                    color: JohoColors.green
                )
            }
            .padding(JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.green.opacity(0.5), lineWidth: JohoDimensions.borderMedium)
        )
    }

    private var currencySelector: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            Text("CURRENCY")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(colors.secondary)
                .tracking(1)

            Menu {
                ForEach(["SEK", "USD", "EUR", "GBP", "JPY", "NOK", "DKK", "CHF"], id: \.self) { curr in
                    Button(curr) { currency = curr }
                }
            } label: {
                HStack {
                    Text(currency)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(colors.secondary)
                }
                .padding(JohoDimensions.spacingSM)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(colors.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Location Fields Card (Mileage)

    private var locationFieldsCard: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "DISTANCE", icon: "car", color: JohoColors.green)

            Rectangle().fill(colors.border).frame(height: 1.5)

            VStack(spacing: JohoDimensions.spacingMD) {
                // From/To
                johoTextField(
                    label: "FROM",
                    text: $startLocation,
                    placeholder: "Starting address...",
                    field: .startLocation
                )

                johoTextField(
                    label: "TO",
                    text: $endLocation,
                    placeholder: "Destination...",
                    field: .endLocation
                )

                // Distance + Round trip
                HStack(spacing: JohoDimensions.spacingSM) {
                    johoTextField(
                        label: "DISTANCE (KM)",
                        text: $distance,
                        placeholder: "0",
                        field: .distance,
                        keyboardType: .decimalPad
                    )

                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        Text("ROUND TRIP")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.secondary)
                            .tracking(1)

                        Toggle("", isOn: $isRoundTrip)
                            .labelsHidden()
                            .tint(JohoColors.green)
                    }
                    .frame(width: 100)
                }

                // Total display
                if let dist = Double(distance), dist > 0 {
                    HStack {
                        Text("TOTAL:")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.secondary)
                        Spacer()
                        Text("\(String(format: "%.1f", isRoundTrip ? dist * 2 : dist)) km")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.green)
                    }
                    .padding(JohoDimensions.spacingSM)
                    .background(JohoColors.green.opacity(0.1))
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.green.opacity(0.5), lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Travel Fields Card (Trip)

    private var travelFieldsCard: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "TRAVEL", icon: "airplane", color: JohoColors.cyan)

            Rectangle().fill(colors.border).frame(height: 1.5)

            VStack(spacing: JohoDimensions.spacingMD) {
                // Destination
                johoTextField(
                    label: "DESTINATION",
                    text: $destination,
                    placeholder: "Tokyo, Japan",
                    field: .destination
                )

                // Trip type
                tripTypeSelector
            }
            .padding(JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.cyan.opacity(0.5), lineWidth: JohoDimensions.borderMedium)
        )
    }

    private var tripTypeSelector: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            Text("TRIP TYPE")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(colors.secondary)
                .tracking(1)

            HStack(spacing: 0) {
                ForEach(TripType.allCases, id: \.self) { type in
                    Button {
                        tripType = type
                        HapticManager.impact(.light)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tripTypeIcon(type))
                                .font(.system(size: 16, weight: .bold))
                            Text(type.rawValue.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(tripType == type ? colors.surface : colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, JohoDimensions.spacingSM)
                        .background(tripType == type ? JohoColors.cyan : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if type != TripType.allCases.last {
                        Rectangle().fill(colors.border).frame(width: 1)
                    }
                }
            }
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(colors.border, lineWidth: 1)
            )
        }
    }

    private func tripTypeIcon(_ type: TripType) -> String {
        switch type {
        case .business: return "briefcase"
        case .personal: return "house"
        case .mixed: return "arrow.triangle.branch"
        }
    }

    // MARK: - Priority Card (Note)

    private var priorityCard: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "PRIORITY", icon: "flag", color: JohoColors.yellow)

            Rectangle().fill(colors.border).frame(height: 1.5)

            HStack(spacing: 0) {
                ForEach(MemoPriority.allCases, id: \.self) { p in
                    Button {
                        priority = p
                        HapticManager.impact(.light)
                    } label: {
                        VStack(spacing: 4) {
                            Text(p.symbol)
                                .font(.system(size: 22))
                            Text(p.displayName.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(priority == p ? colors.surface : colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(priority == p ? JohoColors.yellow : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if p != MemoPriority.allCases.last {
                        Rectangle().fill(colors.border).frame(width: 1)
                    }
                }
            }
            .padding(JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.yellow.opacity(0.5), lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Debt Card (Contact Link + Direction)

    private var debtCard: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "DEBT", icon: "person.2.circle", color: JohoColors.purple)

            Rectangle().fill(colors.border).frame(height: 1.5)

            VStack(spacing: JohoDimensions.spacingMD) {
                // Linked contact picker
                VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                    Text("LINKED CONTACT")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(colors.secondary)
                        .tracking(1)

                    Button {
                        showContactPicker = true
                        HapticManager.impact(.light)
                    } label: {
                        HStack {
                            if let contact = linkedContact {
                                // 情報デザイン: Contact avatar with black border
                                ZStack {
                                    Circle()
                                        .fill(JohoColors.purple.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                                    Text(contact.initials)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(colors.primary)
                                }

                                Text(contact.displayName)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(colors.primary)
                            } else {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(colors.secondary)

                                Text("Select Contact")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(colors.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(colors.secondary)
                        }
                        .padding(JohoDimensions.spacingSM)
                        .background(colors.surface)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(linkedContact != nil ? JohoColors.purple : colors.border, lineWidth: linkedContact != nil ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Direction toggle
                VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                    Text("DIRECTION")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(colors.secondary)
                        .tracking(1)

                    HStack(spacing: 0) {
                        ForEach(DebtDirection.allCases, id: \.self) { direction in
                            Button {
                                debtDirection = direction
                                HapticManager.impact(.light)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: direction.icon)
                                        .font(.system(size: 14, weight: .bold))
                                    Text(direction.displayName.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(debtDirection == direction ? colors.surface : colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, JohoDimensions.spacingSM)
                                .background(debtDirection == direction ? JohoColors.purple : Color.clear)
                            }
                            .buttonStyle(.plain)

                            if direction != DebtDirection.allCases.last {
                                Rectangle().fill(colors.border).frame(width: 1)
                            }
                        }
                    }
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: 1)
                    )
                }

                // Settlement toggle (only for editing existing debt)
                if isEditing && existingMemo?.hasFeature(.debt) == true {
                    toggleRow(
                        title: "SETTLED",
                        subtitle: isDebtSettled ? "Debt has been paid" : "Mark as paid",
                        isOn: $isDebtSettled,
                        color: JohoColors.green
                    )
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.purple.opacity(0.5), lineWidth: JohoDimensions.borderMedium)
        )
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Customization Section (Icon + Color)
    // ═══════════════════════════════════════════════════════════════════════════

    private var customizationSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "CUSTOMIZE", icon: "paintpalette", color: Color(hex: selectedColorHex))

            Rectangle().fill(colors.border).frame(height: 1.5)

            HStack(spacing: JohoDimensions.spacingMD) {
                // 情報デザイン: Icon picker button (44pt+ touch target)
                Button {
                    showIconPicker = true
                    HapticManager.impact(.light)
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColorHex).opacity(0.2))
                                .frame(width: 50, height: 50)
                            // 情報デザイン: Black border on circles
                            Circle()
                                .stroke(JohoColors.black, lineWidth: 1.5)
                                .frame(width: 50, height: 50)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color(hex: selectedColorHex))
                        }

                        Text("ICON")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44) // 情報デザイン: 44pt touch target
                    .padding(.vertical, JohoDimensions.spacingMD)
                }
                .buttonStyle(.plain)

                Rectangle().fill(colors.border).frame(width: 1.5)

                // 情報デザイン: Color picker button (44pt+ touch target)
                Button {
                    showColorPicker = true
                    HapticManager.impact(.light)
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColorHex))
                                .frame(width: 50, height: 50)
                            // 情報デザイン: Black border on circles
                            Circle()
                                .stroke(JohoColors.black, lineWidth: 1.5)
                                .frame(width: 50, height: 50)
                        }

                        Text("COLOR")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44) // 情報デザイン: 44pt touch target
                    .padding(.vertical, JohoDimensions.spacingMD)
                }
                .buttonStyle(.plain)
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Icon Picker Sheet

    private var iconPickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: JohoDimensions.spacingMD) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            showIconPicker = false
                            HapticManager.impact(.light)
                        } label: {
                            ZStack {
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .fill(selectedIcon == icon ? Color(hex: selectedColorHex) : colors.surface)
                                    .frame(width: 56, height: 56)
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(selectedIcon == icon ? Color(hex: selectedColorHex) : colors.border, lineWidth: selectedIcon == icon ? 2 : 1)
                                    .frame(width: 56, height: 56)
                                Image(systemName: icon)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(selectedIcon == icon ? colors.surface : colors.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(JohoDimensions.spacingLG)
            }
            .johoBackground()
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showIconPicker = false }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var availableIcons: [String] {
        [
            // Notes & Writing
            "note.text", "doc.text", "pencil", "highlighter", "bookmark.fill",
            // Calendar & Time
            "calendar", "clock", "timer", "alarm", "hourglass",
            // Travel
            "airplane", "car", "bus", "tram", "ferry", "figure.walk",
            // Money
            "yensign.circle", "dollarsign.circle", "creditcard", "banknote", "cart",
            // People
            "person", "person.2", "figure.2.arms.open", "heart", "gift",
            // Places
            "house", "building.2", "mappin", "globe", "mountain.2",
            // Activities
            "sportscourt", "dumbbell", "fork.knife", "cup.and.saucer", "bed.double",
            // Objects
            "briefcase", "folder", "archivebox", "shippingbox", "key",
            // Nature
            "sun.max", "moon", "cloud", "snowflake", "leaf",
            // Symbols
            "star.fill", "heart.fill", "flag.fill", "bell.fill", "bolt.fill",
            // Tech
            "laptopcomputer", "iphone", "headphones", "camera", "gamecontroller"
        ]
    }

    // MARK: - Color Picker Sheet

    private var colorPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Semantic colors (recommended)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        Text("SEMANTIC COLORS")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.secondary)
                            .tracking(1)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: JohoDimensions.spacingSM) {
                            ForEach(semanticColors, id: \.hex) { item in
                                colorButton(hex: item.hex, name: item.name)
                            }
                        }
                    }

                    // Extended palette
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        Text("MORE COLORS")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.secondary)
                            .tracking(1)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: JohoDimensions.spacingSM) {
                            ForEach(extendedColors, id: \.self) { hex in
                                colorButton(hex: hex, name: nil)
                            }
                        }
                    }
                }
                .padding(JohoDimensions.spacingLG)
            }
            .johoBackground()
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showColorPicker = false }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // 情報デザイン: Color button with proper black borders
    private func colorButton(hex: String, name: String?) -> some View {
        Button {
            selectedColorHex = hex
            showColorPicker = false
            HapticManager.impact(.light)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: name != nil ? 44 : 40, height: name != nil ? 44 : 40)
                    // 情報デザイン: Black border, thicker when selected
                    Circle()
                        .stroke(JohoColors.black, lineWidth: selectedColorHex == hex ? 2.5 : 1.5)
                        .frame(width: name != nil ? 44 : 40, height: name != nil ? 44 : 40)
                }

                if let name = name {
                    Text(name.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }
            }
            .frame(minWidth: 44, minHeight: 44) // 情報デザイン: Touch target
        }
        .buttonStyle(.plain)
    }

    private var semanticColors: [(hex: String, name: String)] {
        [
            (MemoType.note.colorHex, "Now"),
            (MemoType.trip.colorHex, "Plan"),
            (MemoType.expense.colorHex, "Money"),
            (MemoType.countdown.colorHex, "Event"),
            ("E9D5FF", "People"),
            ("FCA5A5", "Alert")
        ]
    }

    private var extendedColors: [String] {
        [
            "FF6B6B", "FF8E72", "FFA94D", "FFD43B", "A9E34B",
            "69DB7C", "38D9A9", "3BC9DB", "4DABF7", "748FFC",
            "9775FA", "DA77F2", "F783AC", "868E96", "495057"
        ]
    }

    // MARK: - Contact Picker Sheet

    private var contactPickerSheet: some View {
        NavigationStack {
            ContactPickerList(selectedContact: $linkedContact) {
                showContactPicker = false
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showContactPicker = false }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        linkedContact = nil
                        showContactPicker = false
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Tags Section
    // ═══════════════════════════════════════════════════════════════════════════

    private var tagsSection: some View {
        johoTextField(
            label: "TAGS (COMMA SEPARATED)",
            text: $tags,
            placeholder: "work, important, follow-up",
            field: .tags
        )
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Delete Section
    // ═══════════════════════════════════════════════════════════════════════════

    private var deleteSection: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .bold))
                Text("Delete Memo")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(JohoColors.red)
            .frame(maxWidth: .infinity)
            .padding(JohoDimensions.spacingMD)
            .background(JohoColors.red.opacity(0.1))
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.red.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Reusable Components
    // ═══════════════════════════════════════════════════════════════════════════

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(colors.primary)
                .tracking(1)

            Spacer()
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(color.opacity(0.1))
    }

    private func johoTextField(
        label: String,
        text: Binding<String>,
        placeholder: String,
        field: Field,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(colors.secondary)
                .tracking(1)

            TextField(placeholder, text: text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
                .keyboardType(keyboardType)
                .focused($focusedField, equals: field)
                .padding(JohoDimensions.spacingSM)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(focusedField == field ? Color(hex: selectedColorHex) : colors.border, lineWidth: focusedField == field ? 2 : 1)
                )
        }
    }

    private func johoTextEditor(
        label: String,
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat = 120
    ) -> some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(colors.secondary)
                .tracking(1)

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.secondary.opacity(0.5))
                        .padding(JohoDimensions.spacingSM)
                }

                TextEditor(text: text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .scrollContentBackground(.hidden)
                    .padding(JohoDimensions.spacingSM - 4)
            }
            .frame(minHeight: minHeight)
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(colors.border, lineWidth: 1)
            )
        }
    }

    private func johoDatePicker(label: String, date: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(colors.secondary)
                .tracking(1)

            Spacer()

            DatePicker("", selection: date, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
        }
        .padding(JohoDimensions.spacingSM)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(colors.border, lineWidth: 1)
        )
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(colors.secondary)
                    .tracking(1)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(JohoDimensions.spacingSM)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(colors.border, lineWidth: 1)
        )
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Validation
    // ═══════════════════════════════════════════════════════════════════════════

    private var canSave: Bool {
        // Check validation based on active features
        var isValid = true

        // Note: needs title or body
        if activeFeatures.contains(.note) || activeFeatures == [] {
            isValid = isValid && (!memoBody.isEmpty || !memoTitle.isEmpty)
        }

        // Trip: needs title and destination
        if activeFeatures.contains(.trip) {
            isValid = isValid && !memoTitle.isEmpty && !destination.isEmpty
        }

        // Expense: needs valid amount
        if activeFeatures.contains(.expense) {
            isValid = isValid && !amount.isEmpty && Double(amount) != nil
        }

        // Mileage: needs locations and distance
        if activeFeatures.contains(.mileage) {
            isValid = isValid && !startLocation.isEmpty && !endLocation.isEmpty && !distance.isEmpty
        }

        // Event/Countdown: needs title
        if activeFeatures.contains(.event) || activeFeatures.contains(.countdown) {
            isValid = isValid && !memoTitle.isEmpty
        }

        // Debt: needs linked contact (optional but recommended)
        // We don't require it, but the UI should indicate it's incomplete
        // if activeFeatures.contains(.debt) && linkedContact == nil {
        //     isValid = false
        // }

        return isValid
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Load / Save
    // ═══════════════════════════════════════════════════════════════════════════

    private func loadExistingMemo() {
        guard let memo = existingMemo else {
            startDate = date
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
            // Default to note feature
            activeFeatures = [.note]
            return
        }

        memoType = memo.type
        memoTitle = memo.title ?? ""
        memoBody = memo.body
        startDate = memo.startDate
        endDate = memo.endDate ?? memo.startDate
        tags = memo.tags?.joined(separator: ", ") ?? ""

        // Load features (migrate from type if empty)
        if memo.features.isEmpty {
            activeFeatures = [memo.type.toFeature]
        } else {
            activeFeatures = memo.features
        }

        // Custom icon and color
        selectedIcon = memo.icon ?? memo.type.icon
        selectedColorHex = memo.colorHex ?? memo.type.colorHex

        // Type-specific
        if let amt = memo.amount {
            amount = String(format: "%.2f", amt)
        }
        currency = memo.currency ?? "SEK"
        category = memo.category ?? ""
        isReimbursable = memo.isReimbursable ?? false
        tripType = memo.tripType ?? .personal
        destination = memo.destination ?? ""
        if let dist = memo.distance {
            distance = String(format: "%.1f", dist)
        }
        startLocation = memo.startLocation ?? ""
        endLocation = memo.endLocation ?? ""
        isRoundTrip = memo.isRoundTrip ?? false
        priority = memo.priority ?? .normal

        // Debt tracking
        linkedContact = memo.linkedContact
        debtDirection = memo.debtDirection ?? .iOwe
        isDebtSettled = memo.isDebtSettled
    }

    private func saveMemo() {
        let memo = existingMemo ?? Memo(type: memoType, startDate: startDate, features: activeFeatures)

        memo.type = memoType
        memo.title = memoTitle.isEmpty ? nil : memoTitle
        memo.body = memoBody
        memo.startDate = startDate
        memo.endDate = showsEndDate ? endDate : nil
        memo.tags = tags.isEmpty ? nil : tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        memo.modifiedAt = Date()

        // Save features
        memo.features = activeFeatures

        // Custom icon and color (only if different from default)
        memo.icon = selectedIcon != memoType.icon ? selectedIcon : nil
        memo.colorHex = selectedColorHex != memoType.colorHex ? selectedColorHex : nil

        // Feature-specific fields (check features, not exclusive type)
        if activeFeatures.contains(.note) {
            memo.priority = priority
        }

        if activeFeatures.contains(.trip) {
            memo.tripType = tripType
            memo.destination = destination
        }

        if activeFeatures.contains(.expense) {
            memo.amount = Double(amount)
            memo.currency = currency
            memo.category = category.isEmpty ? nil : category
            memo.isReimbursable = isReimbursable
            memo.parent = parentMemo
        }

        if activeFeatures.contains(.mileage) {
            memo.distance = Double(distance)
            memo.startLocation = startLocation
            memo.endLocation = endLocation
            memo.isRoundTrip = isRoundTrip
            memo.parent = parentMemo
        }

        // Debt tracking
        if activeFeatures.contains(.debt) {
            memo.linkedContact = linkedContact
            memo.debtDirection = debtDirection
            if isDebtSettled && !memo.isDebtSettled {
                memo.debtSettledAt = Date()
            }
            memo.isDebtSettled = isDebtSettled
        } else {
            // Clear debt fields if debt feature is removed
            memo.linkedContact = nil
            memo.debtDirection = nil
            memo.isDebtSettled = false
            memo.debtSettledAt = nil
        }

        // Validate features (ensures dependencies like debt→expense)
        memo.validateFeatures()

        if existingMemo == nil {
            modelContext.insert(memo)
        }

        try? modelContext.save()
        HapticManager.notification(.success)
        dismiss()
    }

    private func deleteMemo() {
        guard let memo = existingMemo else { return }
        modelContext.delete(memo)
        try? modelContext.save()
        HapticManager.notification(.warning)
        dismiss()
    }
}

// MARK: - Contact Picker List (Helper View)

struct ContactPickerList: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    @Binding var selectedContact: Contact?
    let onSelect: () -> Void

    @Query(sort: \Contact.givenName) private var contacts: [Contact]
    @State private var searchText = ""

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            contact.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredContacts) { contact in
                Button {
                    selectedContact = contact
                    HapticManager.impact(.light)
                    onSelect()
                } label: {
                    HStack(spacing: JohoDimensions.spacingSM) {
                        // 情報デザイン: Avatar with black border
                        ZStack {
                            Circle()
                                .fill(Color(hex: contact.group.color).opacity(0.3))
                                .frame(width: 40, height: 40)
                            // 情報デザイン: Always black borders on circles
                            Circle()
                                .stroke(JohoColors.black, lineWidth: 1.5)
                                .frame(width: 40, height: 40)

                            if let imageData = contact.imageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 38, height: 38)
                                    .clipShape(Circle())
                            } else {
                                Text(contact.initials)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary)
                            }
                        }

                        // Name
                        VStack(alignment: .leading, spacing: 2) {
                            Text(contact.displayName)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)

                            if contact.hasOutstandingDebts {
                                Text("\(contact.outstandingDebts.count) outstanding")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(JohoColors.purple)
                            }
                        }

                        Spacer()

                        // Selection indicator
                        if selectedContact?.id == contact.id {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(JohoColors.purple)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search contacts")
    }
}

// MARK: - Preview

#Preview("New Memo") {
    MemoEditorView(date: Date())
        .modelContainer(for: Memo.self, inMemory: true)
}

#Preview("Edit Expense") {
    let memo = Memo.expense(
        description: "Lunch at restaurant",
        amount: 150,
        currency: "SEK",
        category: "food"
    )
    return MemoEditorView(date: Date(), existingMemo: memo)
        .modelContainer(for: Memo.self, inMemory: true)
}
