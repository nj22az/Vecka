//
//  MemoEditorView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Unified Entry Sheet
//  IDENTICAL pattern to Holiday/Observance creator
//  Blue system UI accent for all interactive states
//

import SwiftUI
import SwiftData

// MARK: - Date Type

enum DateType: String, CaseIterable {
    case fullDay = "Full Day"
    case specificTime = "Time"
    case dateRange = "Range"

    var icon: String {
        switch self {
        case .fullDay: return IconCatalog.calendar
        case .specificTime: return "clock"
        case .dateRange: return IconCatalog.event
        }
    }
}

struct MemoEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.dismiss) private var dismiss

    // Input
    let existingMemo: Memo?
    let initialDate: Date

    // Core state
    @State private var text: String = ""
    @State private var date: Date = Date()

    // Date type state
    @State private var dateType: DateType = .fullDay
    @State private var scheduledTime: Date = Date()
    @State private var endDate: Date = Date()

    // Optional details (progressive disclosure)
    @State private var amount: String = ""
    @State private var currency: String = "SEK"
    @State private var place: String = ""

    // Expansion state
    @State private var showAmount = false
    @State private var showPlace = false
    @State private var showContact = false

    // Linked contact
    @State private var linkedContactID: UUID?
    @State private var linkedContactName: String = ""
    @State private var showContactPicker = false

    // Icon
    @State private var selectedSymbol: String = ""
    @State private var showIconPicker = false

    // UI state
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showEndDatePicker = false
    @State private var showDeleteConfirm = false

    // 情報デザイン: Blue system UI accent (unified across all entry sheets)
    @AppStorage("systemUIAccent") private var systemUIAccent = "blue"

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var isEditing: Bool { existingMemo != nil }

    private var accentColor: Color {
        (SystemUIAccent(rawValue: systemUIAccent) ?? .blue).color
    }

    init(date: Date = Date(), existingMemo: Memo? = nil) {
        self.initialDate = date
        self.existingMemo = existingMemo
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerRow

            JohoDivider()

            // Subtitle: Option chips (same position as HOLIDAY/OBSERVANCE pills)
            optionChipsRow

            JohoDivider(weight: 1.5)

            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Text input (required)
                    textRow

                    JohoDivider(weight: 1.5)

                    // Date type selector
                    dateTypeRow

                    JohoDivider(weight: 1.5)

                    // Date row
                    dateRow

                    // Time picker (when Time type selected)
                    if dateType == .specificTime {
                        JohoDivider(weight: 1.5)
                        timeRow
                    }

                    // End date picker (when Range type selected)
                    if dateType == .dateRange {
                        JohoDivider(weight: 1.5)
                        endDateRow
                    }

                    // Expanded detail rows (when chips active)
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
                }
                .background(colors.surface)
                .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: 2)
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingMD)
            }

            Spacer()

            // Save button
            saveButton

            // Delete button (edit mode only)
            if isEditing {
                deleteButton
            }
        }
        .background(colors.canvas)
        .onAppear { loadExisting() }
        .presentationBackground(colors.canvas)
        .presentationDragIndicator(.visible)
        .johoCalendarPicker(
            isPresented: $showDatePicker,
            selectedDate: $date,
            accentColor: accentColor
        )
        .sheet(isPresented: $showTimePicker) {
            JohoTimePicker(
                selectedTime: $scheduledTime,
                accentColor: accentColor
            )
            .presentationBackground(colors.canvas)
            .presentationDetents([.height(320)])
        }
        .johoCalendarPicker(
            isPresented: $showEndDatePicker,
            selectedDate: $endDate,
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
        .sheet(isPresented: $showIconPicker) {
            JohoIconPickerSheet(
                selectedSymbol: $selectedSymbol,
                accentColor: accentColor,
                lightBackground: accentColor.opacity(JohoDimensions.opacityLight)
            )
        }
        .alert("Delete?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteMemo() }
        }
    }

    // MARK: - Header (identical to Holiday/Observance)

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

            Text(isEditing ? "EDIT MEMO" : "NEW MEMO")
                .font(JohoFont.headlineSmall)
                .foregroundStyle(colors.primary)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(colors.surface)
    }

    // MARK: - Option Chips Row (subtitle position - like HOLIDAY/OBSERVANCE pills)

    private var optionChipsRow: some View {
        HStack(spacing: 0) {
            // Icon column
            Image(systemName: IconCatalog.plusCircle)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            // Chips (same style as HOLIDAY/OBSERVANCE pills)
            HStack(spacing: 8) {
                optionChip(icon: "yensign.circle", label: "AMOUNT", isActive: showAmount) {
                    withAnimation(.easeInOut(duration: 0.2)) { showAmount.toggle() }
                }

                optionChip(icon: "mappin", label: "PLACE", isActive: showPlace) {
                    withAnimation(.easeInOut(duration: 0.2)) { showPlace.toggle() }
                }

                optionChip(icon: IconCatalog.person, label: "CONTACT", isActive: showContact) {
                    withAnimation(.easeInOut(duration: 0.2)) { showContact.toggle() }
                }

                optionChip(icon: "face.smiling", label: "ICON", isActive: !selectedSymbol.isEmpty) {
                    showIconPicker = true
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()
        }
        .frame(height: 56)
        .background(accentColor.opacity(JohoDimensions.opacityLight))
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
            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
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

            TextField("Write something...", text: $text, axis: .vertical)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary)
                .lineLimit(1...4)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .frame(maxHeight: .infinity)
        }
        .frame(minHeight: 48)
    }

    // MARK: - Date Type Row

    private var dateTypeRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.event)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48)

            HStack(spacing: 8) {
                ForEach(DateType.allCases, id: \.self) { type in
                    dateTypeChip(type: type)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()
        }
        .frame(height: 48)
    }

    private func dateTypeChip(type: DateType) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                dateType = type
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 10, weight: .bold))
                Text(type.rawValue)
                    .font(JohoFont.labelSmall)
            }
            .foregroundStyle(dateType == type ? .white : colors.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(dateType == type ? accentColor : colors.surface)
            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Row (identical to Holiday/Observance)

    private var dateRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.calendar)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48)

            Button {
                showDatePicker = true
                HapticManager.impact(.light)
            } label: {
                HStack {
                    Text(formattedDate)
                        .font(JohoFont.bodySmallBold)
                        .foregroundStyle(colors.primary)
                        .monospacedDigit()

                    Spacer()

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

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy    MM    dd"
        return formatter.string(from: date)
    }

    // MARK: - Time Row

    private var timeRow: some View {
        HStack(spacing: 0) {
            Image(systemName: "clock")
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48)

            Button {
                showTimePicker = true
                HapticManager.impact(.light)
            } label: {
                HStack {
                    Text(formattedTime)
                        .font(JohoFont.bodySmallBold)
                        .foregroundStyle(colors.primary)
                        .monospacedDigit()

                    Spacer()

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

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: scheduledTime)
    }

    // MARK: - End Date Row

    private var endDateRow: some View {
        HStack(spacing: 0) {
            Image(systemName: IconCatalog.event)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48)

            Button {
                showEndDatePicker = true
                HapticManager.impact(.light)
            } label: {
                HStack {
                    Text(formattedEndDate)
                        .font(JohoFont.bodySmallBold)
                        .foregroundStyle(colors.primary)
                        .monospacedDigit()

                    Spacer()

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

    private var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy    MM    dd"
        return formatter.string(from: endDate)
    }

    // MARK: - Amount Row

    private var amountRow: some View {
        HStack(spacing: 0) {
            Image(systemName: "yensign.circle")
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 48)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48)

            HStack(spacing: 12) {
                TextField("0", text: $amount)
                    .font(JohoFont.headlineSmall)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(colors.primary)

                TextField("SEK", text: $currency)
                    .font(JohoFont.label)
                    .foregroundStyle(colors.primary)
                    .textInputAutocapitalization(.characters)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .background(colors.inputBackground)
                    .johoBordered(cornerRadius: JohoDimensions.radiusChip, borderWidth: 1.5)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
        }
        .frame(height: 48)
    }

    // MARK: - Place Row

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

    // MARK: - Contact Row

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

    // MARK: - Save Button (blue accent - unified)

    private var saveButton: some View {
        Button {
            saveMemo()
        } label: {
            HStack {
                Image(systemName: IconCatalog.checkmark)
                    .font(JohoFont.bodySmallBold)
                Text("SAVE")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(canSave ? .white : colors.primary.opacity(JohoDimensions.opacityModerate))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(canSave ? accentColor : colors.inputBackground)
            .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 2)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
            HapticManager.impact(.medium)
        } label: {
            HStack {
                Image(systemName: IconCatalog.trash)
                Text("Delete")
            }
            .font(JohoFont.bodySmallBold)
            .foregroundStyle(JohoColors.red)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.bottom, JohoDimensions.spacingMD)
    }

    // MARK: - Validation

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Load / Save

    private func loadExisting() {
        guard let memo = existingMemo else {
            date = initialDate
            endDate = initialDate
            scheduledTime = initialDate
            return
        }

        text = memo.text
        date = memo.date

        // Load date type
        if let scheduled = memo.scheduledAt {
            dateType = .specificTime
            scheduledTime = scheduled
        } else if let tripEnd = memo.tripEndDate {
            dateType = .dateRange
            endDate = tripEnd
        } else {
            dateType = .fullDay
        }

        // Initialize endDate to be after date if not set
        if endDate <= date {
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        }

        if let amt = memo.amount {
            amount = String(format: "%.2f", amt)
            showAmount = true
        }
        currency = memo.currency ?? "SEK"

        if let p = memo.place, !p.isEmpty {
            place = p
            showPlace = true
        }

        if let contactID = memo.linkedContactID {
            linkedContactID = contactID
            showContact = true
            loadContactName(for: contactID)
        }

        if let sym = memo.symbolName, !sym.isEmpty {
            selectedSymbol = sym
        }
    }

    private func loadContactName(for contactID: UUID) {
        let descriptor = FetchDescriptor<Contact>(
            predicate: #Predicate<Contact> { $0.id == contactID }
        )
        if let contact = try? modelContext.fetch(descriptor).first {
            linkedContactName = contact.displayName
        }
    }

    private func saveMemo() {
        let memo = existingMemo ?? Memo(text: text, date: date)

        memo.text = text
        memo.date = date

        // Save date type fields
        switch dateType {
        case .fullDay:
            memo.scheduledAt = nil
            memo.tripEndDate = nil
        case .specificTime:
            memo.scheduledAt = scheduledTime
            memo.tripEndDate = nil
        case .dateRange:
            memo.scheduledAt = nil
            memo.tripEndDate = endDate
        }

        memo.amount = showAmount ? Double(amount) : nil
        memo.currency = showAmount ? currency : nil
        memo.place = showPlace && !place.isEmpty ? place : nil
        memo.linkedContactID = showContact ? linkedContactID : nil
        memo.symbolName = selectedSymbol.isEmpty ? nil : selectedSymbol

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

// MARK: - Contact Picker (unified blue accent)

struct MemoContactPicker: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Contact.familyName) private var contacts: [Contact]

    @Binding var selectedContactID: UUID?
    @Binding var selectedContactName: String

    @AppStorage("systemUIAccent") private var systemUIAccent = "blue"

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var accentColor: Color {
        (SystemUIAccent(rawValue: systemUIAccent) ?? .blue).color
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
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

                Text("LINK CONTACT")
                    .font(JohoFont.headlineSmall)
                    .foregroundStyle(colors.primary)

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(colors.surface)

            JohoDivider()

            // Contact list
            ScrollView {
                LazyVStack(spacing: 0) {
                    if contacts.isEmpty {
                        Text("No contacts available")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.secondary)
                            .padding(32)
                    } else {
                        ForEach(contacts) { contact in
                            contactRow(contact)

                            if contact.id != contacts.last?.id {
                                Rectangle().fill(colors.border.opacity(JohoDimensions.opacityHeavy)).frame(height: 1)
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
                .padding(JohoDimensions.spacingMD)
            }
        }
        .background(colors.canvas)
    }

    private func contactRow(_ contact: Contact) -> some View {
        Button {
            selectedContactID = contact.id
            selectedContactName = contact.displayName
            HapticManager.selection()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selectedContactID == contact.id ? accentColor.opacity(JohoDimensions.opacityMild) : colors.primary.opacity(JohoDimensions.opacitySubtle))
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(selectedContactID == contact.id ? accentColor : colors.border, lineWidth: 1.5))

                    Text(contact.initials)
                        .font(JohoFont.bodySmallBold)
                        .foregroundStyle(selectedContactID == contact.id ? accentColor : colors.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(JohoFont.subheadline)
                        .foregroundStyle(colors.primary)

                    if contact.birthday != nil {
                        Text("Has birthday")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                }

                Spacer()

                if selectedContactID == contact.id {
                    Image(systemName: IconCatalog.checkmarkCircleFill)
                        .foregroundStyle(accentColor)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time Picker (情報デザイン compliant)

struct JohoTimePicker: View {
    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedTime: Date
    let accentColor: Color

    @State private var hours: Int = 0
    @State private var minutes: Int = 0

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    init(selectedTime: Binding<Date>, accentColor: Color) {
        self._selectedTime = selectedTime
        self.accentColor = accentColor

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedTime.wrappedValue)
        self._hours = State(initialValue: components.hour ?? 0)
        self._minutes = State(initialValue: components.minute ?? 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
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

                Text("SELECT TIME")
                    .font(JohoFont.headlineSmall)
                    .foregroundStyle(colors.primary)

                Spacer()

                Button {
                    updateTime()
                    dismiss()
                } label: {
                    Image(systemName: IconCatalog.checkmark)
                        .font(JohoFont.bodySmallBold)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(accentColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(colors.surface)

            JohoDivider()

            // Time pickers
            HStack(spacing: 8) {
                // Hours
                VStack(spacing: 4) {
                    Text("HOUR")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(colors.secondary)

                    Picker("Hour", selection: $hours) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d", hour))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Text(":")
                    .font(JohoFont.displaySmall)
                    .foregroundStyle(colors.primary)
                    .padding(.top, 20)

                // Minutes
                VStack(spacing: 4) {
                    Text("MINUTE")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(colors.secondary)

                    Picker("Minute", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
        .background(colors.canvas)
    }

    private func updateTime() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedTime)
        components.hour = hours
        components.minute = minutes
        if let newTime = calendar.date(from: components) {
            selectedTime = newTime
        }
    }
}

#Preview {
    MemoEditorView(date: Date())
        .modelContainer(for: Memo.self, inMemory: true)
}
