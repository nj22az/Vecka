//
//  ContactDetailView.swift
//  Vecka
//
//  Contact detail and editing view matching iOS Contacts design
//

import SwiftUI
import SwiftData
import PhotosUI

struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let contact: Contact?

    @State private var isEditing: Bool
    @State private var editedContact: Contact

    @State private var showingImagePicker = false
    @State private var showingQRCode = false
    @State private var showingVCardShare = false
    @State private var vcardURL: URL?

    init(contact: Contact?) {
        self.contact = contact
        _isEditing = State(initialValue: contact == nil)

        if let contact = contact {
            _editedContact = State(initialValue: contact)
        } else {
            _editedContact = State(initialValue: Contact())
        }
    }

    var body: some View {
        Form {
            if isEditing {
                editingSections
            } else {
                displaySections
            }
        }
        .navigationTitle(isEditing ? (contact == nil ? "New Contact" : "Edit Contact") : editedContact.displayName)
        .navigationBarTitleDisplayMode(isEditing ? .inline : .large)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if contact == nil {
                            dismiss()
                        } else {
                            isEditing = false
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveContact()
                    }
                }
            } else {
                // Done button to dismiss when viewing (presented in sheet)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ContactImagePicker { imageData in
                if let data = imageData {
                    editedContact.imageData = data
                }
            }
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeView(contact: editedContact)
        }
        .sheet(isPresented: $showingVCardShare) {
            if let url = vcardURL {
                ShareSheet(url: url)
            }
        }
    }

    // MARK: - Display Sections

    @ViewBuilder
    private var displaySections: some View {
        // Header with photo
        Section {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    if let imageData = editedContact.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Text(editedContact.initials)
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                    }

                    Text(editedContact.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let organization = editedContact.organizationName {
                        Text(organization)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.vertical)
        }
        .listRowBackground(Color.clear)

        // Phone numbers
        if !editedContact.phoneNumbers.isEmpty {
            Section("Phone") {
                ForEach(editedContact.phoneNumbers, id: \.id) { phone in
                    HStack {
                        Text(phone.label)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let url = URL(string: "tel:\(phone.value)") {
                            Link(phone.value, destination: url)
                                .foregroundStyle(.blue)
                        } else {
                            Text(phone.value)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }

        // Email addresses
        if !editedContact.emailAddresses.isEmpty {
            Section("Email") {
                ForEach(editedContact.emailAddresses, id: \.id) { email in
                    HStack {
                        Text(email.label)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let url = URL(string: "mailto:\(email.value)") {
                            Link(email.value, destination: url)
                                .foregroundStyle(.blue)
                        } else {
                            Text(email.value)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }

        // Postal addresses
        if !editedContact.postalAddresses.isEmpty {
            Section("Address") {
                ForEach(editedContact.postalAddresses, id: \.id) { address in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(address.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(address.formattedAddress)
                    }
                }
            }
        }

        // Birthday
        if let birthday = editedContact.birthday {
            Section("Birthday") {
                Text(birthday.formatted(date: .long, time: .omitted))
            }
        }

        // Notes
        if let note = editedContact.note, !note.isEmpty {
            Section("Notes") {
                Text(note)
            }
        }

        // Actions
        Section {
            Button {
                showingQRCode = true
            } label: {
                Label("Share as QR Code", systemImage: "qrcode")
            }

            Button {
                generateAndShareVCard()
            } label: {
                Label("Share as vCard", systemImage: "square.and.arrow.up")
            }

            Button {
                exportToIOSContacts()
            } label: {
                Label("Export to iOS Contacts", systemImage: "person.badge.plus")
            }
        }
    }

    // MARK: - Editing Sections

    @ViewBuilder
    private var editingSections: some View {
        // Photo section
        Section {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    if let imageData = editedContact.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Text(editedContact.initials)
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                    }

                    Button("Add Photo") {
                        showingImagePicker = true
                    }
                    .font(.subheadline)
                }
                Spacer()
            }
            .padding(.vertical)
        }
        .listRowBackground(Color.clear)

        // Name section
        Section("Name") {
            TextField("First Name", text: $editedContact.givenName)
            TextField("Last Name", text: $editedContact.familyName)
            TextField("Company", text: Binding(
                get: { editedContact.organizationName ?? "" },
                set: { editedContact.organizationName = $0.isEmpty ? nil : $0 }
            ))
        }

        // Phone numbers
        Section("Phone") {
            ForEach(editedContact.phoneNumbers, id: \.id) { phone in
                HStack {
                    TextField("Label", text: Binding(
                        get: { phone.label },
                        set: { phone.label = $0 }
                    ))
                    .frame(width: 80)

                    TextField("Phone", text: Binding(
                        get: { phone.value },
                        set: { phone.value = $0 }
                    ))
                    .keyboardType(.phonePad)
                }
            }
            .onDelete { indexSet in
                editedContact.phoneNumbers.remove(atOffsets: indexSet)
            }

            Button("Add Phone") {
                editedContact.phoneNumbers.append(ContactPhoneNumber(label: "mobile", value: ""))
            }
        }

        // Email addresses
        Section("Email") {
            ForEach(editedContact.emailAddresses, id: \.id) { email in
                HStack {
                    TextField("Label", text: Binding(
                        get: { email.label },
                        set: { email.label = $0 }
                    ))
                    .frame(width: 80)

                    TextField("Email", text: Binding(
                        get: { email.value },
                        set: { email.value = $0 }
                    ))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                }
            }
            .onDelete { indexSet in
                editedContact.emailAddresses.remove(atOffsets: indexSet)
            }

            Button("Add Email") {
                editedContact.emailAddresses.append(ContactEmailAddress(label: "home", value: ""))
            }
        }

        // Birthday
        Section("Birthday") {
            DatePicker("Birthday", selection: Binding(
                get: { editedContact.birthday ?? Date() },
                set: { editedContact.birthday = $0 }
            ), displayedComponents: .date)
        }

        // Notes
        Section("Notes") {
            TextField("Notes", text: Binding(
                get: { editedContact.note ?? "" },
                set: { editedContact.note = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(5...10)
        }
    }

    // MARK: - Actions

    private func saveContact() {
        editedContact.modifiedAt = Date()

        if contact == nil {
            modelContext.insert(editedContact)
        }

        try? modelContext.save()

        if contact == nil {
            dismiss()
        } else {
            isEditing = false
        }
    }


    private func generateAndShareVCard() {
        let vcard = editedContact.toVCard()
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "\(editedContact.displayName).vcf"
        let url = tempDir.appendingPathComponent(filename)

        do {
            try vcard.write(to: url, atomically: true, encoding: .utf8)
            vcardURL = url
            showingVCardShare = true
        } catch {
            print("Failed to create vCard file: \(error)")
        }
    }

    private func exportToIOSContacts() {
        Task {
            do {
                try ContactsManager.shared.exportToIOSContacts(editedContact)
                // Show success message
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
}
