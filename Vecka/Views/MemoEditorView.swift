//
//  MemoEditorView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Paper Planner Style
//  Write something. Add details if you need them.
//  No categories. No complexity. Just write.
//

import SwiftUI
import SwiftData

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
    @State private var priority: MemoPriority = .normal

    // Optional details (progressive disclosure)
    @State private var amount: String = ""
    @State private var currency: String = "SEK"
    @State private var place: String = ""
    @State private var person: String = ""

    // Expansion state
    @State private var showAmount = false
    @State private var showPlace = false
    @State private var showPerson = false
    @State private var showContactLink = false

    // Linked contact
    @State private var linkedContactID: UUID?
    @State private var linkedContactName: String = ""
    @State private var showContactPicker = false

    // UI state
    @State private var showDatePicker = false
    @State private var showDeleteConfirm = false
    @FocusState private var isTextFocused: Bool

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var isEditing: Bool { existingMemo != nil }

    init(date: Date = Date(), existingMemo: Memo? = nil) {
        self.initialDate = date
        self.existingMemo = existingMemo
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 0) {
                contentCard
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .background(JohoColors.black)
        .onAppear { loadExisting() }
        .presentationBackground(JohoColors.black)
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
                .presentationBackground(JohoColors.black)
                .presentationDetents([.medium])
        }
        .alert("Delete?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteMemo() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .frame(minWidth: 44, minHeight: 44)

            Spacer()

            Text(isEditing ? "Edit" : "Memo")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.white)

            Spacer()

            Button("Save") { saveMemo() }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(canSave ? JohoColors.white : JohoColors.white.opacity(0.4))
                .frame(minWidth: 44, minHeight: 44)
                .disabled(!canSave)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(JohoColors.black)
    }

    // MARK: - Content Card

    private var contentCard: some View {
        VStack(spacing: 0) {
            // Main text field
            textField
                .padding(12)

            divider

            // Date row
            dateRow
                .padding(12)

            divider

            // Priority row
            priorityRow
                .padding(12)

            divider

            // Add details section
            detailChips
                .padding(12)

            // Expanded detail fields
            if showAmount {
                divider
                amountField
                    .padding(12)
            }

            if showPlace {
                divider
                placeField
                    .padding(12)
            }

            if showPerson {
                divider
                personField
                    .padding(12)
            }

            if showContactLink {
                divider
                contactLinkField
                    .padding(12)
            }

            // Delete button
            if isEditing {
                divider
                deleteButton
            }
        }
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colors.border, lineWidth: 2)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(colors.border)
            .frame(height: 1)
    }

    // MARK: - Text Field

    private var textField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MEMO")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            TextField("Write something...", text: $text, axis: .vertical)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
                .lineLimit(3...6)
                .focused($isTextFocused)
        }
    }

    // MARK: - Date Row

    private var dateRow: some View {
        HStack {
            Text("DATE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            Spacer()

            Button {
                showDatePicker = true
                HapticManager.impact(.light)
            } label: {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(JohoColors.black, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Priority Row

    private var priorityRow: some View {
        HStack {
            Text("PRIORITY")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            Spacer()

            HStack(spacing: 0) {
                ForEach(MemoPriority.allCases, id: \.self) { p in
                    Button {
                        priority = p
                        HapticManager.selection()
                    } label: {
                        Text(p.symbol)
                            .font(.system(size: 18))
                            .frame(width: 44, height: 36)
                            .background(priority == p ? JohoColors.yellow : colors.surface)
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Detail Chips (Progressive Disclosure)

    private var detailChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADD DETAILS")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            // First row of chips
            HStack(spacing: 8) {
                detailChip("yensign.circle", "Amount", isActive: showAmount, color: JohoColors.green) {
                    withAnimation(.easeInOut(duration: 0.2)) { showAmount.toggle() }
                }

                detailChip("mappin", "Place", isActive: showPlace, color: JohoColors.cyan) {
                    withAnimation(.easeInOut(duration: 0.2)) { showPlace.toggle() }
                }

                detailChip("person", "Person", isActive: showPerson, color: JohoColors.purple) {
                    withAnimation(.easeInOut(duration: 0.2)) { showPerson.toggle() }
                }
            }

            // Second row: Link Contact chip (情報デザイン: memo-contact linking)
            HStack(spacing: 8) {
                detailChip("person.crop.circle.badge.checkmark", "Link Contact", isActive: showContactLink, color: JohoColors.pink) {
                    withAnimation(.easeInOut(duration: 0.2)) { showContactLink.toggle() }
                }
            }
        }
    }

    private func detailChip(_ icon: String, _ label: String, isActive: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticManager.selection()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isActive ? colors.surfaceInverted : colors.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? color : colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: isActive ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail Fields

    private var amountField: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AMOUNT")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                TextField("0", text: $amount)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .foregroundStyle(colors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENCY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.secondary)
                TextField("SEK", text: $currency)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .textInputAutocapitalization(.characters)
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(JohoColors.black, lineWidth: 1.5)
                    )
            }
        }
        .padding(10)
        .background(JohoColors.greenLight)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }

    private var placeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PLACE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
            TextField("Where...", text: $place)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
        }
        .padding(10)
        .background(JohoColors.cyanLight)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }

    private var personField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PERSON")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
            TextField("Who...", text: $person)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
        }
        .padding(10)
        .background(JohoColors.purpleLight)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }

    // MARK: - Contact Link Field (情報デザイン: memo-contact linking)

    private var contactLinkField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LINKED CONTACT")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)

            Button {
                showContactPicker = true
                HapticManager.impact(.light)
            } label: {
                HStack {
                    if linkedContactID != nil {
                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                            .foregroundStyle(JohoColors.pink)
                        Text(linkedContactName.isEmpty ? "Contact linked" : linkedContactName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary)
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .foregroundStyle(colors.secondary)
                        Text("Select a contact...")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(colors.secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            // Clear button when contact is linked
            if linkedContactID != nil {
                Button {
                    linkedContactID = nil
                    linkedContactName = ""
                    HapticManager.selection()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Remove link")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(JohoColors.pinkLight)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
        .sheet(isPresented: $showContactPicker) {
            MemoContactPicker(
                selectedContactID: $linkedContactID,
                selectedContactName: $linkedContactName
            )
            .presentationBackground(JohoColors.black)
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
            HapticManager.impact(.medium)
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete")
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(JohoColors.red)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { showDatePicker = false }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                Spacer()
                Text("Date")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                Spacer()
                Button("Done") { showDatePicker = false }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.white)
            }
            .padding(16)
            .background(JohoColors.black)

            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(16)
                .background(colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colors.border, lineWidth: 2)
                )
                .padding(8)

            Spacer()
        }
        .background(JohoColors.black)
    }

    // MARK: - Validation

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Load / Save

    private func loadExisting() {
        guard let memo = existingMemo else {
            date = initialDate
            return
        }

        text = memo.text
        date = memo.date
        priority = memo.priority

        // Optional details
        if let amt = memo.amount {
            amount = String(format: "%.2f", amt)
            showAmount = true
        }
        currency = memo.currency ?? "SEK"

        if let p = memo.place, !p.isEmpty {
            place = p
            showPlace = true
        }

        if let per = memo.person, !per.isEmpty {
            person = per
            showPerson = true
        }

        // Linked contact
        if let contactID = memo.linkedContactID {
            linkedContactID = contactID
            showContactLink = true
            // Load contact name from database
            loadContactName(for: contactID)
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
        memo.priority = priority

        // Optional details
        memo.amount = showAmount ? Double(amount) : nil
        memo.currency = showAmount ? currency : nil
        memo.place = showPlace && !place.isEmpty ? place : nil
        memo.person = showPerson && !person.isEmpty ? person : nil

        // Linked contact (情報デザイン: memo-contact linking)
        memo.linkedContactID = showContactLink ? linkedContactID : nil

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

// MARK: - Memo Contact Picker (情報デザイン: memo-contact linking)

struct MemoContactPicker: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Contact.familyName) private var contacts: [Contact]

    @Binding var selectedContactID: UUID?
    @Binding var selectedContactName: String

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                    .frame(minWidth: 44, minHeight: 44)

                Spacer()

                Text("Link Contact")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.white)

                Spacer()

                // Spacer for symmetry
                Color.clear.frame(width: 60, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(JohoColors.black)

            // Contact list
            ScrollView {
                LazyVStack(spacing: 0) {
                    if contacts.isEmpty {
                        Text("No contacts available")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                            .padding(32)
                    } else {
                        ForEach(contacts) { contact in
                            contactRow(contact)
                        }
                    }
                }
                .padding(8)
            }
            .background(colors.surface)
        }
        .background(JohoColors.black)
    }

    private func contactRow(_ contact: Contact) -> some View {
        Button {
            selectedContactID = contact.id
            selectedContactName = contact.displayName
            HapticManager.selection()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(JohoColors.pink.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(contact.initials)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.pink)
                }

                // Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary)

                    if contact.birthday != nil {
                        Text("Has birthday")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                }

                Spacer()

                // Checkmark if selected
                if selectedContactID == contact.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(JohoColors.pink)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(selectedContactID == contact.id ? JohoColors.pink.opacity(0.1) : colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MemoEditorView(date: Date())
        .modelContainer(for: Memo.self, inMemory: true)
}
